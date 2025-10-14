package forgotpassword.implementation.handlers;

import com.mendix.core.Core;
import com.mendix.externalinterface.connector.RequestHandler;
import com.mendix.m2ee.api.IMxRuntimeRequest;
import com.mendix.m2ee.api.IMxRuntimeResponse;
import com.mendix.systemwideinterfaces.core.IContext;
import com.mendix.systemwideinterfaces.core.IMendixObject;
import com.mendix.systemwideinterfaces.core.ISession;
import com.mendix.systemwideinterfaces.core.IUser;
import java.util.Calendar;
import java.util.List;

public class SignInHandler extends RequestHandler {

    private final IContext context;
    protected static String appLocation = Core.getConfiguration().getApplicationRootUrl();

    public IContext getContext() {
        return context;
    }

    public SignInHandler(IContext context) {
        this.context = context;
    }

    @Override
    protected void processRequest(IMxRuntimeRequest request, IMxRuntimeResponse response, String arg2) throws Exception {
        String uuid = request.getParameter("uuid");

        if( uuid != null ) {
            forgotpassword.proxies.AuthResetTemp signIn = getSignInByUUID(getContext(), uuid);

            if (signIn != null) {
                String userName = signIn.getUsername();
                IUser user = Core.getUser(getContext(), userName);
                if( user != null && user.isActive() && !user.isAnonymous() && !user.isBlocked() && signIn.getExpiryDate().after(Calendar.getInstance().getTime())) {
                    ISession session = Core.initializeSession(user, (this.getSessionFromRequest(request) != null ? this.getSessionFromRequest(request).getId().toString() : null));
                    Core.addMendixCookies(request,response,session,false);
                } else {
                    Core.getLogger("ForgotPassword").info("Invalid user " + userName);
                }
                Core.delete(getContext(), signIn.getMendixObject());
            }
            else
                Core.getLogger("ForgotPassword").info("Unable to find UUID " + uuid);
        }
        else
            Core.getLogger("ForgotPassword").info("No UUID provided");


        response.setStatus(IMxRuntimeResponse.SEE_OTHER);
        response.addHeader("location", appLocation);
    }

    private forgotpassword.proxies.AuthResetTemp getSignInByUUID(IContext context, String uuid)  {

        String xpathQuery = String.format("//%s[%s = $uuid]", forgotpassword.proxies.AuthResetTemp.entityName, forgotpassword.proxies.AuthResetTemp.MemberNames.UUID);
        List<IMendixObject> signIns = Core.createXPathQuery(xpathQuery)
                .setVariable("uuid", uuid)
                .execute(context);
        if (!signIns.isEmpty()) {
            return forgotpassword.proxies.AuthResetTemp.initialize(context, signIns.get(0));
        }
        return null;
    }
}
