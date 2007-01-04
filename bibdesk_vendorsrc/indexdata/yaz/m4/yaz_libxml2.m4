AC_DEFUN([YAZ_LIBXML2],[
AC_PATH_PROG(pkgconfigpath, pkg-config, NONE)
xml2dir=default
XML2_VER=""
AC_ARG_WITH(xml2,[[  --with-xml2[=PREFIX]    use libxml2 in PREFIX]],xml2dir=$withval)
dnl -- if no PREFIX or not specified we just search in default locations
dnl -- try pkg-config. If not found, use xml2-config
if test "$xml2dir" = "yes" -o "$xml2dir" = "default"; then
    if test "$pkgconfigpath" != "NONE"; then
	if $pkgconfigpath --exists libxml-2.0; then
	    pkgmodule="libxml-2.0"
	fi
    fi
    if test -z "$pkgmodule"; then
	for d in /usr /usr/local; do
	    if test -x $d/bin/xml2-config; then
		xml2dir=$d
	    fi
	done
    fi
fi
dnl --- do the real check (pkg-config, xml2-config, not-found)
if test "$xml2dir" != "no"; then
    AC_MSG_CHECKING(for libXML2)
    if test "$pkgmodule"; then
	XML2_LIBS=`$pkgconfigpath --libs $pkgmodule`
	XML2_CFLAGS=`$pkgconfigpath --cflags $pkgmodule`
	XML2_VER=`$pkgconfigpath --modversion $pkgmodule`
	AC_MSG_RESULT($XML2_VER)
	m4_default([$1],[AC_DEFINE(HAVE_XML2)])
    elif test -x $xml2dir/bin/xml2-config; then
	XML2_LIBS=`$xml2dir/bin/xml2-config --libs`
	XML2_CFLAGS=`$xml2dir/bin/xml2-config --cflags`
	XML2_VER=`$xml2dir/bin/xml2-config --version`
	AC_MSG_RESULT($XML2_VER)
	m4_default([$1],[AC_DEFINE(HAVE_XML2)])
    else
	AC_MSG_RESULT(Not found)
	if test "$xml2dir" = "default"; then
	    AC_MSG_WARN([libxml2 development libraries not found.])
	    AC_MSG_WARN([There will be no support for SRU.])
	else
	    AC_MSG_ERROR([libxml2 development libraries not found.])
	fi
    fi
fi
])

AC_DEFUN([YAZ_LIBXSLT],[
	xsltdir=default
pkgmodule=""
XSLT_VER=""
AC_ARG_WITH(xslt,[[  --with-xslt[=PREFIX]    use libXSLT in PREFIX]],xsltdir=$withval)

dnl -- if no PREFIX or not specified we just search in default locations
dnl -- try pkg-config. If not found, use xslt-config
if test "$xsltdir" = "yes" -o "$xsltdir" = "default"; then
    if test "$pkgconfigpath" != "NONE"; then
	        # pkg-config on woody reports bad CFLAGS which does 
		# not include libxml2 CFLAGS, so avoid it..
	if $pkgconfigpath --atleast-version 1.1.0 libxslt; then
	    pkgmodule="libxslt"
	fi
    fi
    if test -z "$pkgmodule"; then
	for d in /usr /usr/local; do
	    if test -x $d/bin/xslt-config; then
		xsltdir=$d
	    fi
	done
    fi
fi
dnl --- do the real check (pkg-config, xslt-config, not-found)
if test "$xsltdir" != "no"; then
    AC_MSG_CHECKING(for libXSLT)
    if test "$pkgmodule"; then
	XML2_LIBS=`$pkgconfigpath --libs $pkgmodule`
	XML2_CFLAGS=`$pkgconfigpath --cflags $pkgmodule`
	XSLT_VER=`$pkgconfigpath --modversion $pkgmodule`
	AC_MSG_RESULT($XSLT_VER)
	m4_default([$1],[AC_DEFINE(HAVE_XSLT)])
    elif test -x $xsltdir/bin/xslt-config; then
	XML2_LIBS=`$xsltdir/bin/xslt-config --libs`
	XML2_CFLAGS=`$xsltdir/bin/xslt-config --cflags`
	XSLT_VER=`$xsltdir/bin/xslt-config --version`
	AC_MSG_RESULT($XSLT_VER)
	m4_default([$1],[AC_DEFINE(HAVE_XSLT)])
    else
	AC_MSG_RESULT(Not found)
	
	if test "$xsltdir" = "default"; then
	    AC_MSG_WARN([libXSLT development libraries not found.])
	else
	    AC_MSG_ERROR([libXSLT development libraries not found.])
	fi
    fi
fi
])

dnl -- get libEXSLT. xslt-config is no good. So use pkg-config only
AC_DEFUN([YAZ_LIBEXSLT],[
exsltdir=default
pkgmodule=""
EXSLT_VER=""
AC_ARG_WITH(exslt,[[  --with-exslt[=PREFIX]   use libEXSLT in PREFIX]],exsltdir=$withval)
if test "$exsltdir" = "yes" -o "$exsltdir" = "default"; then
    if test "$pkgconfigpath" != "NONE"; then
	if $pkgconfigpath --exists libexslt; then
	    pkgmodule="libexslt"
	fi
    fi
fi
if test "$exsltdir" != "no"; then
    AC_MSG_CHECKING(for libEXSLT)
    if test "$pkgmodule"; then
	XML2_LIBS=`$pkgconfigpath --libs $pkgmodule`
	XML2_CFLAGS=`$pkgconfigpath --cflags $pkgmodule`
	EXSLT_VER=`$pkgconfigpath --modversion $pkgmodule`
	AC_MSG_RESULT($EXSLT_VER)
	m4_default([$1],[AC_DEFINE(HAVE_EXSLT)])
    else
	AC_MSG_RESULT(Not found)
	
	if test "$pkgconfigpath" = "NONE"; then
	    extra="libEXSLT not enabled. pkg-config not found."
	else
	    extra="libEXSLT development libraries not found."
	fi
	
	if test "$exsltdir" = "default"; then
	    AC_MSG_WARN([$extra])
	else
	    AC_MSG_ERROR([$extra])
	fi
    fi
fi
OLIBS=$LIBS
LIBS="$LIBS $XML2_LIBS"
AC_CHECK_FUNCS([xsltSaveResultToString])
LIBS=$OLIBS
])
dnl Local Variables:
dnl mode:shell-script
dnl sh-indentation: 2
dnl sh-basic-offset: 4
dnl End:
