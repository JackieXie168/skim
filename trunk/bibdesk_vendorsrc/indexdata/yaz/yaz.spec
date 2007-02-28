Summary: Z39.50 Programs
Name: yaz
Version: 2.1.49
Release: 1
Requires: libxslt openssl readline libyaz = %{version}
License: BSD
Group: Applications/Internet
Vendor: Index Data ApS <info@indexdata.dk>
Source: yaz-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-root
BuildRequires: libxml2-devel libxslt-devel tcp_wrappers openssl-devel readline-devel libpcap
Packager: Adam Dickmeiss <adam@indexdata.dk>
URL: http://www.indexdata.dk/yaz/

%description
This package contains both a test-server and clients (normal & ssl)
for the ANSI/NISO Z39.50 protocol for Information Retrieval.

%package -n lib%{name}
Summary: Z39.50 Library
Group: Libraries
Requires: libxslt openssl

%description -n lib%{name}
YAZ is a library for the ANSI/NISO Z39.50 protocol for Information
Retrieval.

%package -n lib%{name}-devel
Summary: Z39.50 Library - development package
Group: Development/Libraries
Requires: libyaz = %{version} libxml2-devel libxslt-devel

%description -n lib%{name}-devel
Development libraries and includes for the libyaz package.

%package -n yaz-ziffy
Summary:  ziffy: the promiscuous Z39.50 APDU sniffer
Group: Applications/Communication
Requires: libxslt openssl libpcap libyaz = %{version}

%description -n yaz-ziffy
ziffy is a promiscuous Z39.50 APDU sniffer, like the popular tcpdump.
ziffy can capture and show all Z39.50 traffic on your LAN segment.
This packages is a special port of ziffy ported to YAZ. Note that ziffy
is licensed under the GPL and was is by Rocco Carbone <rocco@ntop.org>.

%prep
%setup

%build

CFLAGS="$RPM_OPT_FLAGS" \
 ./configure --prefix=/usr --enable-shared --enable-tcpd --with-xslt --with-openssl
make CFLAGS="$RPM_OPT_FLAGS"

%install
rm -fr ${RPM_BUILD_ROOT}
make prefix=${RPM_BUILD_ROOT}/usr mandir=${RPM_BUILD_ROOT}/usr/share/man install

%clean
rm -fr ${RPM_BUILD_ROOT}

%files
%defattr(-,root,root)
%doc README LICENSE NEWS TODO
/usr/bin/yaz-client
/usr/bin/yaz-ztest
/usr/bin/zoomsh*
/usr/bin/yaz-marcdump
/usr/bin/yaz-iconv
/usr/share/man/man1/yaz-client.*
/usr/share/man/man8/yaz-ztest.*
/usr/share/man/man1/zoomsh.*
/usr/share/man/man1/yaz-marcdump.*
/usr/share/man/man1/yaz-iconv.*
/usr/share/man/man7/yaz-log.*

%files -n lib%{name}
/usr/lib/*.so.*

%files -n lib%{name}-devel
/usr/bin/yaz-config
/usr/bin/yaz-asncomp
/usr/include/yaz
/usr/lib/pkgconfig/yaz.pc
/usr/lib/*.so
/usr/lib/*.a
/usr/lib/*.la
/usr/share/aclocal/yaz.m4
/usr/share/man/man1/yaz-asncomp.*
/usr/share/man/man7/yaz.*
/usr/share/man/man8/yaz-config.*
/usr/share/doc/yaz
/usr/share/yaz

%files -n yaz-ziffy
/usr/bin/ziffy
/usr/share/man/man1/ziffy.*
