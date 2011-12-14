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
    
    private string auth;
    delegate void CommandDelegate (string[] args);
    
    private class Command {
        public string name { get; set; }
        public string syntax { get; set; }
        public int param_count { get; set; }
        public CommandDelegate method { get; set; }
        
        public Command(string name, string syntax, CommandDelegate method, int param_count = 0) {
            this.name = name;
            this.syntax = syntax;
            this.method = method;
            this.param_count = param_count;
        }
    }
    
    public static void main ( string[] args ) {
        if ((args.length < 4 && args.length != 2) || (args.length == 2 && args[1] != "--help")) {
            printf("Invalid command, use --help to see the options.\n");
            return;
        }
        
        // holds all the commands and delegates to thier methods
        var commands = new HashMap<string, Command> ();
        // prints all available information out
        commands["info"] = new Command("info", "info", info, 0);
        // testing the testing!
        commands["test"] = new Command("test", "test <text>", test, 1);
        // an other example:
        // commands["createfolder"] = new Command("createfolder", "createfolder <name>", create_folder_test, 1);
        
        if(args[1] == "--help")
        {
            print("sugarsync-linux test programm.\n");
            print("Available commands:\n");
            foreach(var cmd in commands.values)
                printf("\t%s <username> <password> %s\n", args[0], cmd.syntax );
            return;
        }
        
        Posix.openlog( "SugarSyncTest", LOG_CONS | LOG_PID, LOG_LOCAL0 ); 
        try {
            Sugarsync.Db.open_db();
        } catch (DbException ex) {
            print (ex.message + "\n");
            return;
        }
        
        auth = Sugarsync.Api.get_auth_token(args[1], args[2]);
        
        Command cmd = commands[args[3]];
        
        if(cmd != null) {
            if(cmd.param_count == args.length - 4) {
                cmd.method(args[4:args.length - 1]);
            } else {
                printf("%s: Invalid syntax! use: %s <username> <password> %s\n", cmd.name, args[0], cmd.syntax );
            }
        }
    } // end main
    
    private void info(string[] args) {
        print("auth = %s\n", auth);
        print("Api.user_info\n");
        Sugarsync.Api.UserInfo user = Sugarsync.Api.user_info( auth );
        print("user info = %s\n", user.to_string());
        print("Api.workspace_list\n");
        ArrayList<Sugarsync.Api.SyncObject> w = Sugarsync.Api.workspace_list( auth, user );
        print("length = %d\n", w.size);
        int count = 0;
        foreach ( Sugarsync.Api.SyncObject this_ws in w) {
            print("Workspace [ %d ] = %s\n", count, this_ws.to_string());
            if (this_ws is Sugarsync.Api.Collection) {
                ArrayList<Sugarsync.Api.SyncObject> fl = Sugarsync.Api.collections_list( auth, (this_ws as Sugarsync.Api.Collection).contents );
                foreach ( Sugarsync.Api.SyncObject f in fl ) {
                    print(f.to_string());
                    if (fl is Sugarsync.Api.Collection) {
                        ArrayList<Sugarsync.Api.SyncObject> fl2 = Sugarsync.Api.collections_list( auth, (f as Sugarsync.Api.Collection).contents );
                        foreach ( Sugarsync.Api.SyncObject f2 in fl2 ) {
                            print(f2.to_string());
                        }
                    }
                    print("\n\n");
                }
                count ++;
            }
        }
    }
    
    private void test(string[] args) {
        print(args[0] + "\n");
    }
} // end namespace Sugarsync.Test

