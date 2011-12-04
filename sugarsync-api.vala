/**
 * SUGARSYNC LINUX CLIENT
 * https://github.com/jbuchbinder/sugarsync-linux
 *
 * vim: tabstop=4:softtabstop=4:shiftwidth=4:expandtab
 */

using GLib;
using Posix;
using Soup;

class SugarsyncApi {

    public static const string API_ACCESS_KEY = "MTkzMTEzMDEzMTk4MDQ4OTExMDc";
    public static const string API_PRIVATE_KEY = "NmZiMTc5NTQ5YjM4NDU5ODk2ODQ4Yjc3ZTY4ZGU1YjA";

    public static const string AUTHORIZATION_URL = "https://api.sugarsync.com/authorization";

    public static const string FOLDER_REPRESENTATION_URL = "https://api.sugarsync.com/folder/myfolder";
    public static const string FOLDER_CREATE_URL = "https://api.sugarsync.com/folder/myfolder";

    class FolderRepresentation {
        public string timeCreated { get; set construct; }
        public string parent { get; set construct; }
        public string collections { get; set construct; }
        public string files { get; set construct; }
        public string contents { get; set construct; }
    } // end class FolderRepresentation

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

    /**
     * Make an API request. Does no pre or post processing, and should
     * not be used externally -- merely a convenience method.
     */
    protected static string? api_request ( string auth_token, string request_type, string url, string body ) {
        var session = new Soup.SessionAsync ();
        var message = new Soup.Message ( request_type, url );
        message.request_headers.append( "Authorization", auth_token );
        message.set_request( "application/xml", MemoryUse.COPY, body.data );
        session.send_message( message );
        return message.response_body.data;
    } // end api_request

    public void create_folder ( string auth_token, string display_name ) {
        string request = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
            "<folder>" +
                "<displayName>" + display_name + "</displayName>" +
            "</folder>";
        string response = api_request ( auth_token, "POST", FOLDER_CREATE_URL, request );
        Posix.syslog(LOG_DEBUG, response);
    } // end create_folder

} // end class SugarsyncApi

