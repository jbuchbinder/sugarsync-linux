/**
 * SUGARSYNC LINUX CLIENT
 * https://github.com/jbuchbinder/sugarsync-linux
 *
 * vim: tabstop=4:softtabstop=4:shiftwidth=4:expandtab
 */

using GLib;
using Posix;
using Sqlite;

namespace Sugarsync.Db {

    public errordomain DbException {
        FILE_ERROR,
        SQL_ERROR,
        UNKNOWN_ERROR
    }

    public static Database db = null;

    public static File DB_FILE = null;

    public static void close_db ( ) throws DbException {
        if (db != null) {
        }
    } // end close_db

    public static void init_db ( ) throws DbException {
        syslog(LOG_INFO, "Sugarsync.Db.init_db() called");
        int rc = Database.open_v2 (DB_FILE.get_path(), out db, OPEN_CREATE | OPEN_READWRITE);
        if (rc != Sqlite.OK) { 
            syslog(LOG_ERR, "SQL error: %d, %s\n", rc, db.errmsg());
            throw new DbException.FILE_ERROR(db.errmsg());
        }

        // Initialize initial schema
        string createQuery = "" +
            "CREATE TABLE schema_version ( v INT );\n" +
            "INSERT INTO schema_version VALUES ( 1 );\n" +
            "CREATE TABLE config (k TEXT, v TEXT)\n";
        rc = db.exec(createQuery, null, null);
        if (rc != Sqlite.OK) { 
            syslog(LOG_ERR, "SQL error: %d, %s\n", rc, db.errmsg());
            throw new DbException.SQL_ERROR(db.errmsg());
        }

        syslog(LOG_INFO, "Db %s successfully created", DB_FILE.get_path());
    } // end init_db

    public static void open_db ( ) throws DbException {
        // Initialize db location if not set
        if (DB_FILE == null) {
            DB_FILE = File.new_for_commandline_arg( GLib.Environment.get_user_data_dir() + "/applications/sugarsync/db" );
        }
        if (db != null ) { return; }
        try {
            GLib.File parent = File.new_for_path(DB_FILE.get_parent().get_path());
            if (!parent.query_exists(null)) {
                parent.make_directory_with_parents(null);
            }
        } catch (GLib.Error ex) {
            syslog(LOG_ERR, "GLib.error: %s", ex.message);
            throw new DbException.FILE_ERROR(ex.message);
        }
        if (!DB_FILE.query_exists(null)) {
            init_db();
            return; // init_db should leave the db open, skip rest
        }

        // If we're all good, open up
        int rc = Database.open (DB_FILE.get_path(), out db);
        if (rc != Sqlite.OK) { 
            syslog(LOG_ERR, "SQL error: %d, %s\n", rc, db.errmsg());
            throw new DbException.FILE_ERROR(db.errmsg());
        }
    } // end open_db

} // end namespace Sugarsync.Db

