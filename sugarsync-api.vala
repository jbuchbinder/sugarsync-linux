/**
 * SUGARSYNC LINUX CLIENT
 * https://github.com/jbuchbinder/sugarsync-linux
 *
 * vim: tabstop=4:softtabstop=4:shiftwidth=4:expandtab
 */

using Gee;
using GLib;
using Posix;
using Soup;
using Xml;

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

    public class Collection : Object {

    } // end class Collection

    public class ContentCollection : Object {
        public ArrayList<Sugarsync.Api.Collection> collection { get; set construct; }
        public int start { get; set construct; }
        public bool hasMore { get; set construct; }
        public int end { get; set construct; }
        public string contentType { get; set construct; }
    } // end class ContentCollection

    public class Workspace : Object {
        public string displayName { get; set construct; }
        public string refValue { get; set construct; }
        public string iconId { get; set construct; }
        public string contents { get; set construct; }

        public static int currentWorkspaceItem = 0;
        public static ArrayList<Workspace> workspaceItems = new ArrayList<Workspace>();
        public static Workspace curItem = null;

        public Workspace() { }

        public static ArrayList<Workspace> list_from_xml(string xml) { 
            print("Parse: %s\n", xml);
            Xml.Doc* xml_doc = Parser.parse_memory(xml, xml.length);
            if (xml_doc == null) {
                print("Could not parse\n");
                return (ArrayList<Workspace>) null;
            }
 
            // Get the root node. notice the dereferencing operator -> instead of .
            Xml.Node* root_node = xml_doc->get_root_element ();
            if (root_node == null) {
                // Free the document manually before throwing because the garbage collector can't work on pointers
                delete xml_doc;
                print("Could not parse, empty\n");
                return (ArrayList<Workspace>) null;
            }
            currentWorkspaceItem = 0;
            workspaceItems = new ArrayList<Workspace>();
            parse_node(root_node);
            delete xml_doc;

            return workspaceItems;
        }

        protected static void parse_node (Xml.Node* node) {
            for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
                // Space == node, discard
                if (iter->type != ElementType.ELEMENT_NODE)
                    continue;
                string node_name = iter->name;
                string node_content = iter->get_content ();

                if (curItem == null) {
                    curItem = new Workspace();
                }

                switch (node_name) {
                    case "displayName":
                        curItem.displayName = node_content;
                        break;
                    case "ref":
                        curItem.refValue = node_content;
                        break;
                    case "iconId":
                        curItem.iconId = node_content;
                        break;
                    case "contents":
                        curItem.contents = node_content;
                        break;
                    default:
                        syslog(LOG_DEBUG, "element %s not handled\n", node_name);
                        break;
                }

                // Followed by its children nodes
                parse_node(iter);

                if (node_name == "collection") {
                    workspaceItems.add(curItem);
                    curItem = null;
                }
            }
        }

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
        public string publicLinks { get; set construct; }
        public string mobilePhotos { get; set construct; }

        public UserInfo.from_xml(string xml) { 
            Xml.Doc* xml_doc = Parser.parse_memory(xml, xml.length);
            if (xml_doc == null) {
                print("Could not parse\n");
                return;
            }
 
            // Get the root node. notice the dereferencing operator -> instead of .
            Xml.Node* root_node = xml_doc->get_root_element ();
            if (root_node == null) {
                // Free the document manually before throwing because the garbage collector can't work on pointers
                delete xml_doc;
                print("Could not parse, empty\n");
                return;
            }
            parse_node(root_node);
            delete xml_doc;
        }

        protected void parse_node (Xml.Node* node) {
            for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
                // Space == node, discard
                if (iter->type != ElementType.ELEMENT_NODE)
                    continue;
                string node_name = iter->name;
                string node_content = iter->get_content ();

                switch (node_name) {
                    case "username":
                        this.username = node_content;
                        break;
                    case "nickname":
                        this.nickname = node_content;
                        break;
                    case "workspaces":
                        this.workspaces = node_content;
                        break;
                    case "syncfolders":
                        this.syncfolders = node_content;
                        break;
                    case "albums":
                        this.albums = node_content;
                        break;
                    case "publicLinks":
                        this.publicLinks = node_content;
                        break;
                    case "mobilePhotos":
                        this.mobilePhotos = node_content;
                        break;
                    default:
                        syslog(LOG_DEBUG, "element %s not handled\n", node_name);
                        break;
                }

                // Followed by its children nodes
                parse_node(iter);
            }
        }

        public string to_string () {
            return "Sugarsync.Api.UserInfo[" +
                "username=" + ( username != null ? username : "null" ) +
                ",nickname=" + ( nickname != null ? nickname : "null" ) +
                ",workspaces=" + ( workspaces != null ? workspaces : "null" ) +
                ",syncfolders=" + ( syncfolders != null ? syncfolders : "null" ) +
                ",albums=" + ( albums != null ? albums : "null" ) +
                ",publicLinks=" + ( publicLinks != null ? publicLinks : "null" ) +
                ",mobilePhotos=" + ( mobilePhotos != null ? mobilePhotos : "null" ) +
                "]";
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
        UserInfo r = new UserInfo.from_xml(xml);
        return r;
    } // end user_info

    public static ArrayList<Workspace>? workspace_list ( string auth_token, UserInfo user_info ) {
        var workspace_url = user_info.workspaces;
        string xml = api_request ( auth_token, "GET", workspace_url, null );
        if (xml == null) { return null; }
        ArrayList<Workspace> wl = Workspace.list_from_xml(xml);
        return wl;
    } // end workspace_list

} // end namespace Sugarsync.Api

