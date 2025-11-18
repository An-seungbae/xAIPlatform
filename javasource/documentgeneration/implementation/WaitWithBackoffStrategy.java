package documentgeneration.implementation;

import java.util.concurrent.TimeUnit;
import documentgeneration.proxies.constants.Constants;

public class WaitWithBackoffStrategy implements IWaitStrategy {
	private final long startTime;
	private final long maxDuration;
	
	public WaitWithBackoffStrategy() {
		startTime = System.currentTimeMillis();
		maxDuration = TimeUnit.MILLISECONDS.convert(Constants.getSyncTimeoutInSeconds(), TimeUnit.SECONDS);
	}

	@Override
	public String getName() {
		return this.getClass().getSimpleName();
	}
	
	@Override
	public boolean canContinue() {
		return System.currentTimeMillis() - startTime < maxDuration;
	}

	@Override
	public int getWaitTime(int attempt) {
		int index = attempt < waitSequence.length ? attempt : waitSequence.length - 1;
        return waitSequence[index] * 1000;
	}
	
    private static final int[] waitSequence = new int[]{1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 5, 5, 5, 8};
}
