/**
 * SUGARSYNC LINUX CLIENT
 * https://github.com/jbuchbinder/sugarsync-linux
 *
 * vim: tabstop=4:softtabstop=4:shiftwidth=4:expandtab
 */

using GLib;
using Posix;
using Soup;
using Sqlite;

class SugarsyncDaemon {

    /**
     * Object to hold monitor actions to be pushed onto the work
     * queue.
     */
    class MonitorAction : GLib.Object {
        public GLib.File base { get; set construct; }
        public GLib.File file { get; set construct; }
        public GLib.FileMonitorEvent event_type { get; set construct; }
    } // end class MonitorAction

    // Global variables
    protected GLib.FileMonitor[] monitors = {};
    protected int mIter = 0;
    protected Soup.Server rest_server;

    public static void main (string[] args) {
        // Initialize syslog
        Posix.openlog( "SugarSyncDaemon", LOG_CONS | LOG_PID, LOG_LOCAL0 ); 

        SugarsyncDaemon c = new SugarsyncDaemon();
        c.init(args);
    } // end main

    SugarsyncDaemon() { }

    ~SugarsyncDaemon() {
        // Handle gracefully shutting down the REST server.
        if (rest_server != null) {
            rest_server.quit();
        }
    } // end destructor

    public void init (string[] args) {
        // Initialize globals, no monitors to begin with.
        monitors = {};

        // TODO: Initialize from configuration, rather than static init
        GLib.File[] monitorPaths = {
              File.new_for_path( "/usr/share/applications")
            , File.new_for_commandline_arg( GLib.Environment.get_user_data_dir() + "/applications" )
        };

        // TODO: Initialize sqlite interface thread so that only one
        // thing is writing/reading to/from the database at one time.

        // Initialize REST server thread to deal with inbound
        // requests from other parts of the system.
        init_rest_server();

        // TODO: Initialize consumption thread to deal with IO to and
        // from Sugarsync.

        GLib.File mp;
        for (int i=0; i<monitorPaths.length; i++) {
            mp = monitorPaths[i];
            try {
                monitors[mIter] = mp.monitor_directory(
                    GLib.FileMonitorFlags.NONE
                );
                monitors[mIter].changed.connect((file, other_file, event_type) => {
                    GLib.File monitoredPath = mp;
                    switch (event_type) {
                        case GLib.FileMonitorEvent.ATTRIBUTE_CHANGED:
                            syslog(LOG_INFO, "ATTRIBUTE_CHANGED: %s in %s\n", file.get_path(), monitoredPath.get_path());
                            break;
                        case GLib.FileMonitorEvent.CHANGED:
                            syslog(LOG_INFO, "CHANGED: %s in %s\n", file.get_path(), monitoredPath.get_path());
                            break;
                        case GLib.FileMonitorEvent.DELETED:
                            syslog(LOG_INFO, "DELETED: %s in %s\n", file.get_path(), monitoredPath.get_path());
                            break;
                        case GLib.FileMonitorEvent.MOVED:
                            syslog(LOG_INFO, "MOVED: %s in %s\n", file.get_path(), monitoredPath.get_path());
                            break;
                    }

                    // Create monitor action element to push
                    MonitorAction m = new MonitorAction();
                    m.base = monitoredPath;
                    m.file = file;
                    m.event_type = event_type;

                    // TODO: Insert into global stack of actions to be
                    // processed by another thread to keep the actual
                    // upload process synchronized.

                });

                syslog(LOG_INFO, "Monitoring: "+mp.get_path()+"\n");
                mIter ++;
            } catch (GLib.Error e) {
                syslog(LOG_ERR, "Error: "+e.message+"\n");
            }
        } // end init

        GLib.MainLoop loop = new GLib.MainLoop();
        loop.run();
    }

    public void rest_callback (Soup.Server server, Soup.Message msg,
            string path, GLib.HashTable<string,string>? query,
            Soup.ClientContext client) {
        if (path == "/") {
            // Root path, show some informational page or send 404
            print("root path requested!\n");
        } else {

        }
    } // end rest_callback

    public void init_rest_server() {
        rest_server = new Soup.Server("port", 27962);
        //rest_server.port = 27962;
        rest_server.add_handler("/", rest_callback);
        rest_server.run_async();
    } // end init_rest_server

} // end class SugarsyncDaemon

