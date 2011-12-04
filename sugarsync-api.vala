/**
 * SUGARSYNC LINUX CLIENT
 * https://github.com/jbuchbinder/sugarsync-linux
 *
 * vim: tabstop=4:softtabstop=4:shiftwidth=4:expandtab
 */

using GLib;
using Soup;

class SugarsyncApi {

    public static const string API_ACCESS_KEY = "MTkzMTEzMDEzMTk4MDQ4OTExMDc";
    public static const string API_PRIVATE_KEY = "NmZiMTc5NTQ5YjM4NDU5ODk2ODQ4Yjc3ZTY4ZGU1YjA";

    public static const string AUTHORIZATION_URL = "https://api.sugarsync.com/authorization";

    protected static string get_auth_token_request ( string username, string password ) {
        return "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>" +
            "<authRequest>" +
            "<username>" + username + "</username>" +
            "<password>" + password + "</password>" +
            "<accessKeyId>" + API_ACCESS_KEY + "</accessKeyId>" +
            "<privateAccessKey>" + API_PRIVATE_KEY + "</privateAccessKey>" +
            "</authRequest>";
    } // end get_auth_token_request

    /**
     * Attempt to get a Sugarsync API authorization token. Should return
     * null if this fails.
     */
    public static string? get_auth_token ( string username, string password ) {
        var session = new Soup.SessionAsync ();
        var message = new Soup.Message ( "POST", AUTHORIZATION_URL );
        var content = get_auth_token_request( username, password );
        message.set_request( "application/xml",
              MemoryUse.COPY, content.data );
        session.send_message( message );
        return message.response_headers.get("Location");
    } // end get_auth_token

} // end class SugarsyncApi

