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

    public class SyncObject : Object {

        public virtual string to_string () { return "Sugarsync.Api.SyncObject[]"; }

    } // end class SyncObject

    public class File : SyncObject {
        public string displayName { get; set construct; }
        public long size { get; set construct; }
        public string lastModified { get; set construct; }
        public string timeCreated { get; set construct; }
        public string mediaType { get; set construct; }
        public bool presentOnServer { get; set construct; }
        public string parent { get; set construct; }
        public string publicLink { get; set construct; }

        delegate void NodeParser (Xml.Node *node, NodeParser parser);

        public static Sugarsync.Api.File new_from_xml(Xml.Node *fnode) { 
            Sugarsync.Api.File curItem = new Sugarsync.Api.File();

            NodeParser parse = (node, passed_parser) => {
            for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
                // Space == node, discard
                if (iter->type != ElementType.ELEMENT_NODE)
                    continue;
                string node_name = iter->name;
                string node_content = iter->get_content ();

                switch (node_name) {
                    case "displayName":
                        curItem.displayName = node_content;
                        break;
                    case "size":
                        curItem.size = long.parse(node_content);
                        break;
                    case "lastModified":
                        curItem.lastModified = node_content;
                        break;
                    case "timeCreated":
                        curItem.timeCreated = node_content;
                        break;
                    case "mediaType":
                        curItem.mediaType = node_content;
                        break;
                    case "presentOnServer":
                        curItem.presentOnServer = node_content == "true" ? true : false;
                        break;
                    case "parent":
                        curItem.parent = node_content;
                        break;
                    case "publicLink":
                        curItem.publicLink = node_content;
                        break;
                    default:
                        syslog(LOG_DEBUG, "file element %s not handled\n", node_name);
                        print("file element %s not handled\n", node_name);
                        break;
                }

                // Followed by its children nodes
                passed_parser(iter, passed_parser);
            }
            };

            parse(fnode, parse);

            return curItem;
        } // end parse_node

        public override string to_string () {
            return "Sugarsync.Api.File[" +
                "displayName=" + ( displayName != null ? displayName : "null" ) + "," +
                "size=" + size.to_string() + "," +
                "lastModified=" + ( lastModified != null ? lastModified : "null" ) + "," +
                "timeCreated=" + ( timeCreated != null ? timeCreated : "null" ) + "," +
                "mediaType=" + ( mediaType != null ? mediaType : "null" ) + "," +
                "presentOnServer=" + ( presentOnServer ? "true" : "false" ) + "," +
                "parent=" + ( parent != null ? parent : "null" ) + "]";
        } // end to_string

    } // end class File

    public class Collection : SyncObject {
        public enum CollectionType {
              UNKNOWN
            , SYNC_FOLDER
            , WORKSPACE
        }

        public CollectionType contentType { get; set construct; }
        public string displayName { get; set construct; }
        public string refValue { get; set construct; }
        public string iconId { get; set construct; }
        public string contents { get; set construct; }

        delegate void NodeParser (Xml.Node *node, NodeParser parser);

        public static Sugarsync.Api.Collection new_from_xml(Xml.Node *fnode) { 
            Sugarsync.Api.Collection curItem = new Sugarsync.Api.Collection();

            NodeParser parse = (node, passed_parser) => {
                for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
                    // Space == node, discard
                    if (iter->type != ElementType.ELEMENT_NODE)
                        continue;
                    string node_name = iter->name;
                    string node_content = iter->get_content ();
    
                    if (curItem == null) {
                        curItem = new Collection();
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
                            syslog(LOG_DEBUG, "collection element %s not handled\n", node_name);
                            print("collection element %s not handled\n", node_name);
                            break;
                    }


                    // Followed by its children nodes
                    passed_parser(iter, passed_parser);
                }

                for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
                    string attr_name = prop->name;
                    string attr_content = prop->children->content;
                    if (attr_name == "type") {
                        switch (attr_content) {
                            case "syncFolder":
                                curItem.contentType = CollectionType.SYNC_FOLDER;
                                break;
                            case "workspace":
                                curItem.contentType = CollectionType.WORKSPACE;
                                break;
                            default:
                                curItem.contentType = CollectionType.UNKNOWN;
                                break;
                        }
                    }
                }
            };

            parse(fnode, parse);

            return curItem;
        } // end parse_node

        public override string to_string () {
            return "Sugarsync.Api.Collection[" +
                "contentType=" + contentType.to_string() + "," +
                "displayName=" + ( displayName != null ? displayName : "null" ) + "," +
                "ref=" + ( refValue != null ? refValue : "null" ) + "," +
                "iconId=" + ( iconId != null ? iconId : "null" ) + "," +
                "contents=" + ( contents != null ? contents : "null" ) + "]";
        } // end to_string

    } // end class Collection

    public class CollectionContent : Object {
        public ArrayList<Sugarsync.Api.SyncObject> collection { get; set construct; }
        public int start { get; set construct; }
        public bool hasMore { get; set construct; }
        public int end { get; set construct; }

        protected static ArrayList<SyncObject> items = new ArrayList<SyncObject>();
        protected static SyncObject curItem = null;

        public static ArrayList<SyncObject> list_from_xml(string xml) { 
            print("Parse: %s\n", xml);
            Xml.Doc* xml_doc = Parser.parse_memory(xml, xml.length);
            if (xml_doc == null) {
                print("Could not parse\n");
                return (ArrayList<Collection>) null;
            }
 
            // Get the root node. notice the dereferencing operator -> instead of .
            Xml.Node* root_node = xml_doc->get_root_element ();
            if (root_node == null) {
                // Free the document manually before throwing because the garbage collector can't work on pointers
                delete xml_doc;
                print("Could not parse, empty\n");
                return (ArrayList<SyncObject>) null;
            }
            items = new ArrayList<SyncObject>();

            for (Xml.Node* iter = root_node->children; iter != null; iter = iter->next) {
                if (iter->type != ElementType.ELEMENT_NODE)
                    continue;
                SyncObject o = null;
                string node_name = iter->name;
                switch (node_name) {
                    case "file":
                        o = Sugarsync.Api.File.new_from_xml( iter );
                        break;
                    case "collection":
                        o = Sugarsync.Api.Collection.new_from_xml( iter );
                        break;
                    default:
                        print("Unable to parse node %s\n", node_name);
                        break;
                }
                if (o != null) {
                    items.add(o);
                }
            }
            delete xml_doc;

            return items;
        } // end list_from_xml

    } // end class CollectionContent

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

    public static ArrayList<Sugarsync.Api.SyncObject>? collections_list ( string auth_token, string url ) {
        string xml = api_request ( auth_token, "GET", url, null );
        if (xml == null) { return null; }
        ArrayList<Sugarsync.Api.SyncObject> l = Sugarsync.Api.CollectionContent.list_from_xml(xml);
        return l;
    } // end collections_list

    public static ArrayList<Sugarsync.Api.SyncObject>? workspace_list ( string auth_token, UserInfo user_info ) {
        return collections_list( auth_token, user_info.workspaces );
    } // end workspace_list

    public static bool download_file ( string auth_token, string url, string destination ) {
        try {
            var session = new Soup.SessionAsync ();
            var message = new Soup.Message ( "GET", url );
            message.request_headers.append( "Authorization", auth_token );
            session.send_message( message );
            GLib.File file = GLib.File.new_for_path( destination );
            var file_stream = file.create( FileCreateFlags.NONE );
            var data_stream = new DataOutputStream( file_stream );
            data_stream.put_string( (string) message.response_body.data );
            return true;
        } catch (GLib.Error e) {
            return false;
        }
    } // end download_file

    public static bool upload_file ( string auth_token, string folder_url, string file_name, GLib.File file ) {
        try {
            var session = new Soup.SessionAsync ();
            var message = new Soup.Message ( "PUT", folder_url + "/" + file_name );
            message.request_headers.append( "Authorization", auth_token );
            DataInputStream dis = new DataInputStream( file.read() );
            uint8[] data = { };
            string line;
            while ( (line = dis.read_line(null)) != null ) {
                foreach ( uint8 ch in line.data ) {
                    data += ch;
                }
            }
            message.request_body.append(Soup.MemoryUse.TEMPORARY, data);
            session.send_message( message );
        } catch (GLib.Error e) {
            return false;
        }
        return true;
    } // end upload_file

} // end namespace Sugarsync.Api

