#!/bin/sh
# $Id: buildconf.sh,v 1.45 2007/01/03 13:55:49 mike Exp $

automake=automake
aclocal=aclocal
autoconf=autoconf
libtoolize=libtoolize

if [ "`uname -s`" = FreeBSD ]; then
    # FreeBSD intalls the various auto* tools with version numbers
    echo "Using special configuation for FreeBSD ..."
    automake=automake19
    aclocal="aclocal19 -I /usr/local/share/aclocal"
    autoconf=autoconf259
    libtoolize=libtoolize15
fi

if $automake --version|head -1 |grep '1\.[4-7]'; then
    echo "automake 1.4-1.7 is active. You should use automake 1.8 or later"
    if test -f /etc/debian_version; then
        echo " sudo apt-get install automake1.9"
        echo " sudo update-alternatives --config automake"
    fi
    exit 1
fi

set -x
# I am tired of underquoted warnings for Tcl macros
$aclocal -I m4
$libtoolize --automake --force 
$automake --add-missing 
$autoconf
set -
if [ -f config.cache ]; then
	rm config.cache
fi

enable_configure=false
enable_help=true
sh_flags=""
conf_flags=""
case $1 in
    -d)
	#sh_flags="-g -Wall -Wdeclaration-after-statement -Werror -Wstrict-prototypes"
	sh_flags="-g -Wall -Wdeclaration-after-statement -Wstrict-prototypes"
	enable_configure=true
	enable_help=false
	shift
	;;
    -c)
	sh_flags=""
	enable_configure=true
	enable_help=false
	shift
	;;
esac

if $enable_configure; then
    if test -n "$sh_flags"; then
	CFLAGS="$sh_flags" ./configure --disable-shared --enable-static $*
    else
	./configure $*
    fi
fi
if $enable_help; then
    cat <<EOF

Build the Makefiles with the configure command.
  ./configure [--someoption=somevalue ...]

For help on options or configuring run
  ./configure --help

Build and install binaries with the usual
  make
  make check
  make install

Build distribution tarball with
  make dist

Verify distribution tarball with
  make distcheck

EOF
    if [ -f /etc/debian_version ]; then
        cat <<EOF
Or just build the Debian packages without configuring
  dpkg-buildpackage -rfakeroot

When building from a CVS checkout, you need these Debian packages:
  autoconf, automake, libtool, gcc, bison, any tcl,
  xsltproc, docbook, docbook-xml, docbook-xsl,
  libxslt1-dev, libssl-dev, libreadline5-dev, libwrap0-dev,
  libpcap0.8-dev
EOF
    fi
    if [ "`uname -s`" = FreeBSD ]; then
        cat <<EOF
When building from a CVS checkout, you need these FreeBSD Ports:
  autoconf259, automake19, libtool15, bison, tcl84,
  docbook-xsl, libxml2, libxslt, g++-4.0, make
EOF
    fi
fi
