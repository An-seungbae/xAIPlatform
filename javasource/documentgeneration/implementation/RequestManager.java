package documentgeneration.implementation;

import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import com.mendix.core.Core;
import com.mendix.core.CoreException;
import com.mendix.logging.ILogNode;
import com.mendix.systemwideinterfaces.core.IContext;
import com.mendix.systemwideinterfaces.core.IMendixObject;

import documentgeneration.implementation.exceptions.DocGenPollingException;
import documentgeneration.proxies.DocumentRequest;
import documentgeneration.proxies.Enum_DocumentRequest_Status;
import system.proxies.FileDocument;

public class RequestManager {
	private static final ConcurrentMap<String, CountDownLatch> pendingWaits = new ConcurrentHashMap<>();

	public static IMendixObject waitForResult(IWaitStrategy waitStrategy, String requestId) {
		CountDownLatch latch = new CountDownLatch(1);
		pendingWaits.put(requestId, latch);

		for (int i = 0; waitStrategy.canContinue(); i++) {
			Optional<DocumentRequest> documentRequest = loadFinalizedDocumentRequest(requestId);
			if (documentRequest.isPresent()) {
				return processResult(documentRequest.get());
			}

			logging.trace("Document result is not yet available, continue polling");

			if (awaitLatchUsingStrategy(latch, waitStrategy, i)) {
				logging.trace("Interrupted polling for request " + requestId);
			}
		}

		logging.trace("Document result has not appeared, stopping polling");

		pendingWaits.remove(requestId);
		failDocumentRequest(requestId);

		throw new DocGenPollingException("Timeout while waiting for document result for request " + requestId);
	}

	public static boolean awaitLatchUsingStrategy(CountDownLatch latch, IWaitStrategy waitStrategy, int attempt) {
		int waitTime = waitStrategy.getWaitTime(attempt);
		logging.trace("Wait using " + waitStrategy.getName() + ": " + waitTime + "ms");

		try {
			return latch.await(waitTime, TimeUnit.MILLISECONDS);
		} catch (InterruptedException e) {
			return true;
		}
	}

	public static void interruptPendingRequest(String requestId) {
		CountDownLatch latch = pendingWaits.get(requestId);
		if (latch != null) {
			latch.countDown();
		}
	}

	private static Optional<DocumentRequest> loadFinalizedDocumentRequest(String requestId) {
		String query = "//DocumentGeneration.DocumentRequest[RequestId=$RequestId][Status = 'Completed' or Status = 'Failed']";
		IContext systemContext = Core.createSystemContext();

		return Core.createXPathQuery(query).setVariable("RequestId", requestId).execute(systemContext).stream()
				.map(obj -> DocumentRequest.initialize(systemContext, obj)).findAny();
	}

	private static IMendixObject processResult(DocumentRequest documentRequest) {
		logging.trace("Processing result for document request " + documentRequest.getRequestId());

		if (documentRequest.getStatus().equals(Enum_DocumentRequest_Status.Completed)) {
			FileDocument fileDocument = DocumentRequestManager.getFileDocument(documentRequest);
			if (fileDocument == null)
				throw new RuntimeException("File document not found");

			return fileDocument.getMendixObject();
		} else if (documentRequest.getStatus().equals(Enum_DocumentRequest_Status.Failed)) {
			if (documentRequest.getErrorCode() != null)
				throw DocumentRequestErrorManager.createException(documentRequest);

			throw new RuntimeException("Failed to generate document");
		} else {
			throw new RuntimeException("Invalid document request status");
		}
	}

	private static void failDocumentRequest(String requestId) {
		DocumentRequest documentRequest = DocumentRequestManager.loadDocumentRequest(requestId,
				Core.createSystemContext());
		try {
			DocumentRequestManager.failDocumentRequest(documentRequest);
		} catch (CoreException e) {
			logging.error("Could not update status for request " + requestId);
		}
	}

	private static final ILogNode logging = Logging.logNode;
}