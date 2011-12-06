/**
 * SUGARSYNC LINUX CLIENT
 * https://github.com/jbuchbinder/sugarsync-linux
 *
 * vim: tabstop=4:softtabstop=4:shiftwidth=4:expandtab
 */

using GLib;
using Posix;
using Soup;

namespace Sugarsync.Api {

    public static const string API_ACCESS_KEY = "MTkzMTEzMDEzMTk4MDQ4OTExMDc";
    public static const string API_PRIVATE_KEY = "NmZiMTc5NTQ5YjM4NDU5ODk2ODQ4Yjc3ZTY4ZGU1YjA";

    public static const string AUTHORIZATION_URL = "https://api.sugarsync.com/authorization";

    public static const string FOLDER_REPRESENTATION_URL = "https://api.sugarsync.com/folder/myfolder";
    public static const string FOLDER_CREATE_URL = "https://api.sugarsync.com/folder/myfolder";

    public static const string USER_URL = "https://api.sugarsync.com/user";

    public class FolderRepresentation : GLib.Object {
        public string timeCreated { get; set construct; }
        public string parent { get; set construct; }
        public string collections { get; set construct; }
        public string files { get; set construct; }
        public string contents { get; set construct; }
    } // end class FolderRepresentation

    public class Workspace : GLib.Object {
        public string displayName { get; set construct; }
        public string refValue { get; set construct; }
        public string iconId { get; set construct; }
        public string contents { get; set construct; }

        public string to_string () {
            return "Sugarsync.Api.Workspace[" +
                "displayName=" + ( displayName != null ? displayName : "null" ) + "," +
                "ref=" + ( refValue != null ? refValue : "null" ) + "," +
                "iconId=" + ( iconId != null ? iconId : "null" ) + "," +
                "contents=" + ( contents != null ? contents : "null" ) + "]";
        }

    } // end class Workspace

    public class UserInfo : GLib.Object {
        public string username { get; set construct; }
        public string nickname { get; set construct; }
        public string workspaces { get; set construct; }
        public string syncfolders { get; set construct; }
        public string albums { get; set construct; }

        public string to_string () {
            return "Sugarsync.Api.UserInfo[" +
                "username=" + ( username != null ? username : "null" ) + "," +
                "nickname=" + ( nickname != null ? nickname : "null" ) + "," +
                "workspaces=" + ( workspaces != null ? workspaces : "null" ) + "," +
                "syncfolders=" + ( syncfolders != null ? syncfolders : "null" ) + "," +
                "albums=" + ( albums != null ? albums : "null" ) + "]";
        }

    } // end class UserInfo

    public static string get_auth_token_request ( string username, string password ) {
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
    public static string? api_request ( string auth_token, string request_type, string url, string? body ) {
        var session = new Soup.SessionAsync ();
        var message = new Soup.Message ( request_type, url );
        message.request_headers.append( "Authorization", auth_token );
        if (body != null) {
            message.set_request( "application/xml", MemoryUse.COPY, body.data );
        }
        session.send_message( message );
        return (string) message.response_body.data;
    } // end api_request

    public static string? get_xml_element_string ( string xml, string element ) {
        bool isElement = false;
        string found = null;
        MarkupParser markupParser = { 
            (context, element_name, attribute_names, attribute_values) => {
                print("element_name = %s\n", element_name);
                if (element_name == element) {
                    isElement = true;
                }
                print("end element name find\n");
            }, 
            (con, el) => {
                print("end element el = %s\n", el);
                isElement = false;
            }, 
            (con, text, text_len ) => {
                print("text = %s\n", text);
                if (isElement) {
                    found = text;
                }
            }, null // call on non-interpresed text, like comments
            , null // call on errors
        };
        MarkupParseContext parser = new MarkupParseContext 
                              (markupParser, MarkupParseFlags.TREAT_CDATA_AS_TEXT, null, null);
        try {
            parser.parse( xml, xml.length );
            parser.end_parse();
        } catch (MarkupError ex) {
            syslog(LOG_ERR, "Error: %s\n", ex.message);
        }
        return found;
    } // end get_xml_element_string

    public void create_folder ( string auth_token, string display_name ) {
        string request = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
            "<folder>" +
                "<displayName>" + display_name + "</displayName>" +
            "</folder>";
        string response = api_request ( auth_token, "POST", FOLDER_CREATE_URL, request );
        Posix.syslog(LOG_DEBUG, response);
    } // end create_folder

    public static UserInfo? user_info ( string auth_token ) {
        string xml = api_request ( auth_token, "GET", USER_URL, null );
        if (xml == null) { return null; }
        UserInfo r = new UserInfo();
        int currentElement = 0;
        MarkupParser markupParser = { 
            (context, element_name, attribute_names, attribute_values) => {
                switch (element_name) {
                    case "username":
                        print("username found\n");
                        currentElement = 1;
                        break;
                    case "nickname":
                        print("nickname found\n");
                        currentElement = 2;
                        break;
                    case "workspaces":
                        print("workspaces found\n");
                        currentElement = 3;
                        break;
                    case "syncfolders":
                        print("syncfolders found\n");
                        currentElement = 4;
                        break;
                    case "albums":
                        print("albums found\n");
                        currentElement = 5;
                        break;
                    default:
                        print("element %s not found\n", element_name);
                        currentElement = 0;
                        break;
                }
            }, 
            (con, el) => {
                print ("end()\n");
                currentElement = 0;
            }, 
            (con, text, text_len) => {
                print ("text(%s)\n", text);
                switch (currentElement) {
                    case 1:
                        r.username = text;
                        break;
                    case 2:
                        r.nickname = text;
                        break;
                    case 3:
                        r.workspaces = text;
                        break;
                    case 4:
                        r.syncfolders = text;
                        break;
                    case 5:
                        r.albums = text;
                        break;
                    case 0:
                    default:
                        break;
                }
            }, null // call on non-interpresed text, like comments
            , null // call on errors
        };
        MarkupParseContext parser = new MarkupParseContext 
                              (markupParser,  MarkupParseFlags.TREAT_CDATA_AS_TEXT, r, null);
        try {
            parser.parse( xml, xml.length );
            parser.end_parse();
        } catch (MarkupError ex) {
            syslog(LOG_ERR, "Error: %s\n", ex.message);
        }

        return r;
    } // end user_info

    public static Workspace[]? workspace_list ( string auth_token, UserInfo user_info ) {
        var workspace_url = user_info.workspaces;
        string xml = api_request ( auth_token, "GET", workspace_url, null );
        if (xml == null) { return null; }
        Workspace[] wl = {};

        int iter = 0;
        int currentElement = 0;
        MarkupParser markupParser = { 
            (context, element_name, attribute_names, attribute_values) => {
                switch (element_name) {
                    case "displayName":
                        currentElement = 1;
                        break;
                    case "ref":
                        currentElement = 2;
                        break;
                    case "iconId":
                        currentElement = 3;
                        break;
                    case "contents":
                        currentElement = 4;
                        break;
                    default:
                        currentElement = 0;
                        break;
                }
            }, 
            (con, el) => {
                if (el == "workspace") {
                    iter++;
                }
                currentElement = 0;
            }, 
            (con, text, text_len ) => {
                switch (currentElement) {
                    case 1:
                        wl[iter].displayName = text;
                        break;
                    case 2:
                        wl[iter].refValue = text;
                        break;
                    case 3:
                        wl[iter].iconId = text;
                        break;
                    case 4:
                        wl[iter].contents = text;
                        break;
                    default:
                        break;
                }
            }, null // call on non-interpresed text, like comments
            , null // call on errors
        };
        MarkupParseContext parser = new MarkupParseContext 
                              (markupParser, MarkupParseFlags.TREAT_CDATA_AS_TEXT, null, null);
        try {
            parser.parse( xml, xml.length );
            parser.end_parse();
        } catch (MarkupError ex) {
            syslog(LOG_ERR, "Error: %s\n", ex.message);
        }

        return wl;
    } // end workspace_list

} // end namespace Sugarsync.Api

