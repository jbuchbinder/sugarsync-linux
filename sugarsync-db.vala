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
        string createQuery = ""
            + "CREATE TABLE schema_version ( v INT );\n"
            + "INSERT INTO schema_version VALUES ( 1 );\n"
            + "CREATE TABLE config (k TEXT, v TEXT);\n"
            + "CREATE TABLE files (name TEXT, s_id TEXT, folder_id TEXT, last_modified TIMESTAMP);\n"
            + "CREATE TABLE folders (name TEXT, s_id INT, parent INT);\n"
            ;
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

    public static void file_add ( string s_id, string name, string folder_id ) throws DbException {
        int rc;
        Sqlite.Statement stmt;

        string query = "INSERT INTO files SET s_id = ?, name = ?, folder_id = ?, last_update = NOW();";
        _build_query(out stmt, query, s_id, name, folder_id);

        if ((rc=stmt.step()) != Sqlite.DONE)
            throw new DbException.SQL_ERROR("SQL (%d): %s", rc, db.errmsg());
    } // end file_add

    public static void file_set_last_update ( string s_id ) throws DbException {
        int rc;
        Sqlite.Statement stmt;

        string query = "UPDATE files SET last_update = NOW() WHERE s_id = ?;";
        _build_query(out stmt, query, s_id);

        if ((rc=stmt.step()) != Sqlite.DONE)
            throw new DbException.SQL_ERROR("SQL (%d): %s", rc, db.errmsg());
    } // end file_set_last_update

    public static void _build_query(out Sqlite.Statement stmt, string query, ...) throws DbException {
        var l = va_list();
        int rc = 0;
        if ((rc=db.prepare_v2(query, -1, out stmt, null)) != Sqlite.OK)
            throw new DbException.SQL_ERROR(db.errmsg());
        int i = 1;
        while (true) {
            GLib.Value? v = l.arg();
            if (v == null)
                break;  // end of the list
            switch (v.type_name()) {
                case "string":
                case "gchararray":
                    if ((rc=stmt.bind_text(i, (string) v)) != Sqlite.OK)
                        throw new DbException.SQL_ERROR(db.errmsg());
                    break;
                case "int":
                case "gint":
                case "guint":
                case "gshort":
                case "gushort":
                    if ((rc=stmt.bind_int(i, (int) v)) != Sqlite.OK)
                        throw new DbException.SQL_ERROR(db.errmsg());
                    break;
                case "int64":
                case "gint64":
                case "long":
                case "glong":
                case "gulong":
                    if ((rc=stmt.bind_int64(i, (int64) v)) != Sqlite.OK)
                        throw new DbException.SQL_ERROR(db.errmsg());
                    break;
                default:
                    throw new DbException.SQL_ERROR("SQL: bad type passed to prepare_query: %s", v.type_name());
            }
            i++;
        }
    } // end _build_query

} // end namespace Sugarsync.Db

