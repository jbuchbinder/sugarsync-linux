### Sugarsync Linux Client
# vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab

PKGS= \
	--pkg gee-1.0 \
	--pkg gio-2.0 \
	--pkg posix \
	--pkg libsoup-2.4 \
	--pkg sqlite3 \
	--pkg libxml-2.0

TEST_SOURCES= \
	../sugarsync-api.vala \
	../sugarsync-db.vala

all: clean sugarsync-test

clean:
	rm -f sugarsync-test

sugarsync-test:
	@echo "Building $@ ... "
	@valac $(PKGS) -o $@ $(TEST_SOURCES) sugarsync-test.vala


