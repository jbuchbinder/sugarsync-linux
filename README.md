SUGARSYNC LINUX CLIENT
======================

https://github.com/jbuchbinder/sugarsync-linux
Twitter: @jbuchbinder

OVERVIEW
--------

This is a native Linux client for the Sugarsync filesharing/sync/backup
service. The company has not expressed interest in supporting an
"official" Linux port, so this has been written to bridge the gap. It
is written in Vala, which is compiled to native C code.

COMPILING
---------

`make`: it's about as easy as it gets. ;)

It needs a recent copy of Vala with a few extra bindings.  If you're
using Debian/Ubuntu or a derivative, it's as easy as
`sudo apt-get install valac-0.14 libgee-dev libsoup2.4-dev libxml2-dev libsqlite3-dev`.
There aren't a lot of crazy external dependencies at the moment.

