### Sugarsync Linux Client
# vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab

PKGS= \
	--pkg gio-2.0 \
	--pkg posix \
	--pkg libsoup-2.4 \
	--pkg sqlite3

DAEMON_SOURCES= \
	sugarsync-api.vala \
	sugarsync-db.vala \
	sugarsync-daemon.vala

all: clean sugarsync-daemon

clean:
	rm -f sugarsync-daemon

sugarsync-daemon:
	@echo "Building $@ ... "
	@valac $(PKGS) -o $@ $(DAEMON_SOURCES)

