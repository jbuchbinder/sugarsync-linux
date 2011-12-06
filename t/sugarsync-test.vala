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
using Sqlite;
using Sugarsync.Api;
using Sugarsync.Db;

namespace Sugarsync.Test {

    public static void main ( string[] args ) {
        if (args.length != 3) {
            print("Requires username and password\n");
            return;
        }
        Posix.openlog( "SugarSyncTest", LOG_CONS | LOG_PID, LOG_LOCAL0 ); 
        try {
            Sugarsync.Db.open_db();
        } catch (DbException ex) {
            print (ex.message + "\n");
            return;
        }

        string auth = Sugarsync.Api.get_auth_token(args[1], args[2]);
        print("auth = %s\n", auth);

        print("Api.user_info\n");
        Sugarsync.Api.UserInfo user = Sugarsync.Api.user_info( auth );
        print("user info = %s\n", user.to_string());
        print("Api.workspace_list\n");
        ArrayList<Sugarsync.Api.Collection> w = Sugarsync.Api.workspace_list( auth, user );
        print("length = %d\n", w.size);
        int count = 0;
        foreach ( Sugarsync.Api.Collection this_ws in w) {
            print("Workspace [ %d ] = %s\n", count, this_ws.to_string());
            ArrayList<Sugarsync.Api.Collection> fl = Sugarsync.Api.collections_list( auth, this_ws.contents );
            foreach ( Sugarsync.Api.Collection f in fl) {
                print(f.to_string());
            }
            count ++;
        }
    }

} // end namespace Sugarsync.Test

