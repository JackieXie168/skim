$!========================================================================
$!
$! Main Xpdf compile script for VMS.
$!
$! Written by Patrick Moreau, Martin P.J. Zinser.
$!
$! Copyright 1996-2002 Glyph & Cog, LLC
$!
$!========================================================================
$!
$! This procedure takes up to three (optional) parameters:
$!
$! 1.) Configuration settings:
$!
$!     a4             - Use european A4 as the default paper size.
$!
$!     no_text_select - Disable text selection in Xpdf
$!
$!     opi_support    - Compile Xpdf with support for the Open Prepress 
$!                      Interface (OPI)
$!
$! 2.) Compiler detection:
$!
$!     In case you want to override the automatic compiler detection
$!     specify either DECC or GCC as the second paramter,
$!     e.g. @vms_make "" GCC 
$!
$! 3.) System Xpdf resource file
$!
$!     The default for this is decw$system_defaults:xpdfrc.dat, since this
$!     is the standard place for systemwide Xdefaults files on OpenVMS. You
$!     may provide a different file in p3.
$!
$! External libraries (like T1lib, Freetype, and XPM) are supported via the 
$! config file VMSLIB.DAT. Please check the sample file, which will be created
$! by this procedure upon first invocation, for the information you need to 
$! provide 
$!
$! Sample invocation of the script:
$!                 @vms_make a4,opi_support "" 
$!
$! In case of problems with the compile you may contact me at 
$! zinser@decus.de (preferred) or zinser@sysdev.deutsche-boerse.com (work). 
$!
$!========================================================================
$!
$ on error then goto err_exit
$!
$!
$! Just some general constants...
$!
$ true  = 1
$ false = 0
$ xpdf_link :== link
$ tmpnam = "temp_" + f$getjpi("","pid")
$ tc = tmpnam + ".c"
$!
$! Setup variables holding "config" information
$!
$ aconf_in_file = "aconf_h.in#aconf.h_in#aconf.h.in"
$ mydefs        = "#"
$ cxxdefs       = ""
$ libdefs       = "\"
$ libincs       = ""
$ float         = ""
$ compress_def  = false
$ p2 = f$edit(p2,"upcase,trim")
$ if f$edit(p3,"trim") .eqs. "" 
$ then 
$   resfil = "decw$system_defaults:xpdfrc.dat"
$ else
$   resfil = "'p3'"
$ endif
$!
$ gosub proc_config
$!
$! Start building the option file
$!
$ open/write optf xpdf.opt
$ write optf "Identification=""xpdf 1.00"""
$ gosub check_create_vmslib
$ write optf "SYS$SHARE:DECW$XLIBSHR.EXE/SHARE"
$!
$ if (f$getsyi("HW_MODEL").ge.1024) .and. - 
     (f$locate("T1LIB",f$edit(libdefs,"UPCASE")) .lt. f$length(libdefs)) -
     then float  = "/float=ieee_float"
$ incs = "sys$library:,[-],[],[-.goo]''libincs'"     
$!
$ gosub check_compiler
$ close optf
$!
$! Check that X11VMS is defined as a libary, since this is not an add-on but
$! a pre-requisite to build Xpdf
$!
$ if (f$locate("X11VMS",f$edit(libdefs,"UPCASE")) .eq. f$length(libdefs)) - 
    then goto x11vms_err
$!
$! aconf.h.in might be mapped in different ways, so go figure
$!
$ i = 0
$FIND_ACONF:
$ fname = f$element(i,"#",aconf_in_file)
$ if fname .eqs. "#" then goto AMISS_ERR
$ if f$search(fname) .eqs. ""
$ then 
$   i = i + 1
$   goto find_aconf
$ endif
$ open/read/err=aconf_err aconf_in 'fname'
$ open/write aconf aconf.h
$ACONF_LOOP:
$ read/end_of_file=aconf_exit aconf_in line
$ work = f$edit(line, "compress,trim")
$ if f$extract(0,6,work) .nes. "#undef"
$ then
$   write aconf line
$ else
$   def = f$element(1," ",work)
$   if ((f$locate("\''def'\",f$edit(libdefs,"UPCASE")) .lt. f$length(libdefs)) -
        .or. (f$locate("#''def'#",f$edit(mydefs,"UPCASE")) .lt. f$length(mydefs))) 
$   then
$     write aconf "#define ", def, " 1"
$   else
$     gosub check_config
$   endif
$ endif
$!
$! Make sure old-style VMS is defined along with __VMS
$!
$ if f$locate("define ACONF_H",line) .lt. f$length(line) then -
    write aconf "#define VMS 1"
$ goto aconf_loop
$ACONF_EXIT:
$ close aconf_in
$ close aconf
$ write sys$output "Compiling in [.GOO]"
$ set default [.goo]
$ @vms_make
$ write sys$output "Compiling in [.XPDF]"
$ set default [-.xpdf]
$ @vms_make
$ set default [-]
$ gosub reset_env
$ exit
$ACONF_ERR:
$ write sys$output "Input file ''fname' could not be opened"
$ goto err_exit
$AMISS_ERR:
$ write sys$output "No source for aconf.h found."
$ write sys$output "Tried any of ''aconf_in_file'"
$CXX_ERR:
$ write sys$output "C++ compiler required to build Xpdf"
$ goto err_exit
$FT2_ERR:
$ write sys$output "Can not find [.internal] sub-dir in Freetype 2 tree"
$ goto err_exit
$X11VMS_ERR:
$ write sys$output "X11VMS must be listed in vmslib.dat"
$ goto err_exit
$ERR_EXIT:
$ set message/facil/ident/sever/text
$ gosub reset_env
$ close/nolog aconf_in
$ close/nolog aconf
$ close/nolog optf
$ close/nolog tmpc
$ write sys$output "Exiting..."  
$ exit 2
$!------------------------------------------------------------------------------
$!
$! Take care of driver file with information about external libraries
$!
$CHECK_CREATE_VMSLIB:
$!
$ if f$search("VMSLIB.DAT") .eqs. ""
$ then
$   type/out=vmslib.dat sys$input
!
! This is a simple driver file with information used by vms_make.com to
! check if external libraries (like t1lib and freetype) are available on
! the system.
!
! Layout of the file:
!
!    - Lines starting with ! are treated as comments
!    - Elements in a data line are separated by # signs
!    - The elements need to be listed in the following order
!      1.) Name of the Library (only used for informative messages 
!                               from vms_make.com)
!      2.) Location where the object library can be found
!      3.) Location where the include files for the library can be found
!      4.) Include file used to verify library location
!      5.) CPP define to pass to the build to indicate availability of 
!          the library
!
! Example: The following  lines show how definitions  
!          might look like. They are site specific and the locations of the 
!          library and include files need almost certainly to be changed.
! 
! Location: All of the libaries can be found at the following addresses
!
!   T1LIB:     http://www.decus.de:8080/www/vms/sw/t1lib.htmlx
!   FREETYPE:  http://www.decus.de:8080/www/vms/sw/freetype2.htmlx
!   XPM:       http://www.decus.de:8080/www/vms/sw/xpm.htmlx
!   X11VMS:    http://www.decus.de:8080/www/vms/sw/xvmsutils.htmlx
!   LIBPAPER:  http://www.decus.de:8080/www/vms/sw/libpaper.htmlx
!
!T1LIB    # pubbin:t1.olb        # public$root:[xtools.libs.t1lib.lib.t1lib] # t1lib.h    # HAVE_T1LIB_H
!FREETYPE # pubbin:freetype.olb  # public$root:[xtools.libs.ft2.include.freetype],public$root:[xtools.libs.ft2.include] # freetype.h # HAVE_FREETYPE_H\FREETYPE2
!XPM      # pubbin:libxpm.olb    # X11:                                      # xpm.h      # HAVE_X11_XPM_H
!X11VMS   # pubbin:xvmsutils.olb # x11vms:                                   # vmsutil.h  # HAVE_X11VMS   
!LIBPAPER # pubbin:libpaper.olb  # public$root:[util.libs.paper.lib]         # paper.h    # HAVE_PAPER_H
$   write sys$output "New driver file vmslib.dat created."
$   write sys$output "Please customize libary locations for your site"
$   write sys$output "and afterwards re-execute vms_make.com"
$   write sys$output "Exiting..."
$   close/nolog optf
$   exit
$ endif
$!
$! Open data file with location of libraries
$!
$ open/read/end=end_lib/err=err_lib libdata VMSLIB.DAT
$LIB_LOOP:
$ read/end=end_lib libdata libline
$ libline = f$edit(libline, "UNCOMMENT,COLLAPSE")
$ if libline .eqs. "" then goto LIB_LOOP ! Comment line
$ libname = f$edit(f$element(0,"#",libline),"UPCASE")
$ write sys$output "Processing ''libname' setup ..."
$ libloc  = f$element(1,"#",libline)
$ libsrc  = f$element(2,"#",libline)
$ testinc = f$element(3,"#",libline)
$ cppdef  = f$element(4,"#",libline)
$ old_cpp = f$locate("=1",cppdef)
$ if old_cpp.lt.f$length(cppdef) then cppdef = f$extract(0,old_cpp,cppdef)
$ if f$search("''libloc'").eqs. ""
$ then
$   write sys$output "Can not find library ''libloc' - Skipping ''libname'"
$   goto LIB_LOOP
$ endif
$ libsrc_elem = 0
$ libsrc_found = false
$LIBSRC_LOOP:
$ libsrcdir = f$element(libsrc_elem,",",libsrc)
$ if (libsrcdir .eqs. ",") then goto END_LIBSRC
$ if f$search("''libsrcdir'''testinc'") .nes. "" then libsrc_found = true
$ libsrc_elem = libsrc_elem + 1
$ goto LIBSRC_LOOP
$END_LIBSRC:
$ if .not. libsrc_found
$ then
$   write sys$output "Can not find includes at ''libsrc' - Skipping ''libname'"
$   goto LIB_LOOP
$ endif
$ libdefs = libdefs +  cppdef + "\"
$ libincs = libincs + "," + libsrc
$ write optf libloc , "/lib"
$!
$! Nasty hack to get the freetype includes to work
$!
$ if ((libname .eqs. "FREETYPE") .and. -
      (f$locate("FREETYPE2",cppdef) .lt. f$length(cppdef)))
$ then
$   if ((f$search("freetype:freetype.h") .nes. "") .and. -
        (f$search("freetype:[internal]ftobjs.h") .nes. ""))
$   then
$     write sys$output "Will use local definition of freetype logical"
$     ft2def = 0
$   else
$     ft2elem = 0 
$FT2_LOOP:
$     ft2srcdir = f$element(ft2elem,",",libsrc)
$     if f$search("''ft2srcdir'''testinc'") .nes. ""
$     then
$        if f$search("''ft2srcdir'internal.dir") .nes. ""
$        then
$          ft2dev  = f$parse("''ft2srcdir'",,,"device","no_conceal")
$          ft2dir  = f$parse("''ft2srcdir'",,,"directory","no_conceal")
$          ft2conc = f$locate("][",ft2dir)
$          ft2len  = f$length(ft2dir)
$          if ft2conc .lt. ft2len
$          then
$             ft2dir = f$extract(0,ft2conc,ft2dir) + -
                       f$extract(ft2conc+2,ft2len-2,ft2dir)
$          endif
$          ft2dir = ft2dir - "]" + ".]"
$          define freetype 'ft2dev''ft2dir','ft2srcdir'
$          ft2def = 1
$        else
$          goto ft2_err
$        endif
$     else
$       ft2elem = ft2elem + 1
$       goto ft2_loop
$     endif
$   endif	 
$ endif 
$ goto LIB_LOOP
$END_LIB:
$ close libdata
$ return
$!------------------------------------------------------------------------------
$!
$! Take care of driver file with information about external libraries
$!
$CHECK_CONFIG:
$!
$ if (def .eqs. "SYSTEM_XPDFRC")
$ then
$   write aconf "#define SYSTEM_XPDFRC """, resfil, """" 
$ else
$   gosub check_cc_def
$ endif
$ return
$!------------------------------------------------------------------------------
$!
$! Check if this is a define relating to the properties of the C/C++
$! compiler
$!
$CHECK_CC_DEF:
$ if (def .eqs. "HAVE_DIRENT_H")
$ then
$   open/write tmpc 'tc 
$   write tmpc "#include <dirent.h>"
$   close tmpc
$   gosub cc_prop_check
$ else
$   write aconf "/* ", line, " */" 
$ endif
$ return
$!------------------------------------------------------------------------------
$!
$! Process config settings passed from the command line
$! (analog to Unix --enable-xxx)
$!
$PROC_CONFIG: 
$ if (p1.nes."")
$ then
$   i = 0
$   qual_list = f$edit(p1,"upcase")
$DEF_LOOP:
$   qual = f$element(i,",",qual_list)
$   if qual .eqs. "," then goto FINISH_DEF
$   i = i + 1
$   if (qual .eqs. "A4")
$   then 
$     mydefs = mydefs + "A4_PAPER#"
$     goto def_loop
$   endif
$   if (qual .eqs. "NO_TEXT_SELECT")
$   then
$     mydefs = mydefs + "NO_TEXT_SELECT#" 
$     goto def_loop
$   endif
$   if (qual .eqs. "OPI_SUPPORT")
$   then
$     mydefs = mydefs + "OPI_SUPPORT#" 
$     goto def_loop
$   endif
$   if (qual .eqs. "COMPRESS")
$   then
$     compress_def = true 
$     goto def_loop
$   endif
$   write sys$output "Qualifier ''qual' not recognized, will be ignored"
$   goto def_loop
$ endif
$FINISH_DEF:
$ return
$!
$!------------------------------------------------------------------------------
$!
$! Look for the compiler used 
$!
$CHECK_COMPILER:
$ its_decc = (f$search("SYS$SYSTEM:CXX$COMPILER.EXE") .nes. "")
$ its_gnuc = .not. its_decc .and. (f$trnlnm("gnu_cc") .nes. "")
$!
$! Exit if no compiler available
$!
$ if (.not. (its_decc .or. its_gnuc)) then goto CXX_ERR
$!
$! Override if requested from the commandline
$!
$ if (p2 .eqs. "DECC")
$ then
$   its_decc = true
$   its_gnuc = false 
$ endif
$ if (p1 .eqs. "GNUC")
$ then
$   its_decc = false
$   its_gnuc = true
$ endif
$!
$ if its_decc
$ then
$   ccomp :== "cc/decc/prefix=all ''float'"
$!
$! Take care of includes
$!
$   cc_user    = f$trnlnm("DECC$USER_INCLUDE")
$   cc_system  = f$trnlnm("DECC$SYSTEM_INCLUDE")
$   cxx_user   = f$trnlnm("CXX$USER_INCLUDE")
$   cxx_system = f$trnlnm("CXX$SYSTEM_INCLUDE")
$   define decc$system_include  'incs'
$   define decc$user_include    'incs'
$   define cxx$user_include     'incs'
$   define cxx$system_include   'incs'
$!
$! Check version of the C++ compiler
$! 
$   create vms_xpdf_cc_test.cc
$   cxx/lis=vms_xpdf_cc_test.lis/show=all vms_xpdf_cc_test.cc
$   open list vms_xpdf_cc_test.lis
$CXX_LIST:
$   read/end=close_cxx list line
$   start = f$locate("__DECCXX_VER",line)
$   if start .ne. f$length(line)
$   then
$     cxx_ver = f$extract(start+13,8,line)
$     if cxx_ver .gt. 60000000
$     then 
$       cxxdefs = "/warn=(disable=nosimpint)"
$       xpdf_link :== cxxlink
$     endif
$     goto close_cxx
$   endif
$   goto cxx_list
$CLOSE_CXX:
$   close list
$   delete/noconfirm vms_xpdf_cc_test.*;*
$   cxxcomp :== "cxx/prefix=all ''cxxdefs' ''float' /include=cxx$user_include/lis/show=all"
$ endif
$!
$ if its_gnuc
$ then
$   ccomp   :== "gcc/nocase/include=(''incs')"
$   cxxcomp :== "gcc/plusplus/nocase/include=(''incs')"
$   write optf "gnu_cc:[000000]gcclib.olb/lib"
$   write optf "sys$share:vaxcrtl.exe/share"
$ endif
$ return
$RESET_ENV:
$ delete/sym/glob cxxcomp
$ delete/sym/glob ccomp
$ delete/sym/glob xpdf_link
$ if (ft2def) then deassign freetype
$ if its_decc
$ then
$  if cc_user .eqs. ""
$  then
$    deass decc$user_include
$  else
$    define decc$user_include 'cc_user'
$  endif
$  if cc_system .eqs. ""
$  then
$    deass decc$system_include
$  else
$    define decc$system_include 'cc_system'
$  endif
$  if cxx_user .eqs. ""
$  then
$    deass cxx$user_include
$  else
$    define cxx$user_include 'cxx_user'
$  endif
$  if cxx_system .eqs. ""
$  then
$    deass cxx$system_include
$  else
$    define cxx$system_include 'cxx_system'
$  endif
$ endif
$ return
$!
$!------------------------------------------------------------------------------
$!
$! Check for properties of C/C++ compiler
$!
$CC_PROP_CHECK:
$ cc_prop = false
$ set message/nofac/noident/nosever/notext
$ cc 'tmpnam'
$ if $status then cc_prop = true
$ set message/fac/ident/sever/text
$ delete/nolog 'tmpnam'.*;*
$ if cc_prop 
$ then
$   write aconf "#define ''def' 1"
$ else 
$   write aconf line
$ endif
$ return
