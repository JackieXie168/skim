$! Compile and link latex2rtf under OpenVMS
$!
$! In case of problems with the install you might contact me at
$! zinser@zinser.no-ip.info (preferred) or zinser@sysdev.deutsche-boerse.de
$!
$!------------------------------------------------------------------------------
$!
$! Define some general constants
$!
$ true        = 1
$ false       = 0
$ tmpnam      = "temp_" + f$getjpi("","pid")
$ tc          = tmpnam + ".c"
$ prognam     = "Latex2rtf"
$ its_decc    = false
$ its_vaxc    = false
$ its_gnuc    = false
$ ccopt       = ""
$ lopts       = ""
$ allcdef     = ""
$ linkonly    = false
$ its_vax     = f$getsyi("cpu") .lt. 128
$ need_x11vms = false
$!
$ gosub check_opts
$!
$ open/write optf 'prognam'.opt
$ open/write topt tmp.opt
$ gosub check_compiler
$ close topt
$!
$ if its_decc .and. its_vax then ccopt = "/DECC" + ccopt
$
$ cdef = "NEED_SNPRINTF"
$ gosub check_cc_def
$ if (need_x11vms)
$ then
$   gosub check_create_vmslib
$   i = 0
$LDEFLOOP:
$   lldef = f$element(i,"\",libdefs)
$   if lldef .nes. "\"
$   then
$     allcdef = allcdef + lldef
$     i = i + 1
$     goto ldefloop
$   endif
$   ccopt = ccopt + "/define=(''allcdef')"
$ endif
$FLOOP:
$ CSRC = f$search("*.c")
$ if csrc .nes. ""
$ then
$   fname = f$parse(csrc,,,"name")
$   write optf fname, ".obj"
$   if linkonly then goto floop
$   cfname = f$parse(csrc,,,"name") + f$parse(csrc,,,"type")
$   write sys$output "Compiling ", cfname
$   cc 'ccopt' 'cfname'
$   goto floop
$ endif
$ close optf
$ write sys$output "Linking ''prognam'..."
$ if f$search("lib.opt").nes. "" then copy 'prognam'.opt,lib.opt 'prognam'.opt
$ link/exe='prognam'.exe 'lopts' 'prognam'.opt/opt
$ exit
$CC_ERR:
$ write sys$output "C compiler required to build ''prognam'"
$ goto err_exit
$ERR_EXIT:
$ set message/facil/ident/sever/text
$ close/nolog optf
$ close/nolog aconf_in
$ close/nolog aconf
$ close/nolog tmpc
$ write sys$output "Exiting..."
$ exit 2
$!------------------------------------------------------------------------------
$!
$! Look for the compiler used
$!
$CHECK_COMPILER:
$ if (.not. (its_decc .or. its_vaxc .or. its_gnuc))
$ then
$   its_decc = (f$search("SYS$SYSTEM:DECC$COMPILER.EXE") .nes. "")
$   its_vaxc = .not. its_decc .and. (F$Search("SYS$System:VAXC.Exe") .nes. "")
$   its_gnuc = .not. (its_decc .or. its_vaxc) .and. (f$trnlnm("gnu_cc") .nes. "")
$ endif
$!
$! Exit if no compiler available
$!
$ if (.not. (its_decc .or. its_vaxc .or. its_gnuc))
$ then goto CC_ERR
$ else
$   if its_decc
$   then
$     write sys$output "CC compiler check ... Compaq C"
$   else
$     if its_vaxc then write sys$output "CC compiler check ... VAX C"
$     if its_gnuc then write sys$output "CC compiler check ... GNU C"
$     if f$trnlnm(topt) then write topt "sys$share:vaxcrtl.exe/share"
$     if f$trnlnm(optf) then write optf "sys$share:vaxcrtl.exe/share"
$   endif
$ endif
$ return
$!------------------------------------------------------------------------------
$!
$! Check command line options and set symbols accordingly
$!
$ CHECK_OPTS:
$ i = 1
$ OPT_LOOP:
$ if i .lt. 9
$ then
$   cparm = f$edit(p'i',"upcase")
$   if cparm .eqs. "DEBUG"
$   then
$     ccopt = ccopt + "/noopt/deb"
$     lopts = lopts + "/deb"
$   endif
$   if f$locate("CCOPT=",cparm) .lt. f$length(cparm)
$   then
$     start = f$locate("=",cparm) + 1
$     len   = f$length(cparm) - start
$     ccopt = ccopt + f$extract(start,len,cparm)
$   endif
$   if cparm .eqs. "LINK" then linkonly = true
$   if f$locate("LOPTS=",cparm) .lt. f$length(cparm)
$   then
$     start = f$locate("=",cparm) + 1
$     len   = f$length(cparm) - start
$     lopts = lopts + f$extract(start,len,cparm)
$   endif
$   if f$locate("CC=",cparm) .lt. f$length(cparm)
$   then
$     start  = f$locate("=",cparm) + 1
$     len    = f$length(cparm) - start
$     cc_com = f$extract(start,len,cparm)
      if (cc_com .nes. "DECC") .and. -
         (cc_com .nes. "VAXC") .and. -
        (cc_com .nes. "GNUC")
$     then
$       write sys$output "Unsupported compiler choice ''cc_com' ignored"
$       write sys$output "Use DECC, VAXC, or GNUC instead"
$     else
$       if cc_com .eqs. "DECC" then its_decc = true
$       if cc_com .eqs. "VAXC" then its_vaxc = true
$       if cc_com .eqs. "GNUC" then its_gnuc = true
$     endif
$   endif
$   i = i + 1
$   goto opt_loop
$ endif
$ return
$!------------------------------------------------------------------------------
$!
$! Check if this is a define relating to the properties of the C/C++
$! compiler
$!
$CHECK_CC_DEF:
$ if (cdef .eqs. "NEED_SNPRINTF")
$ then
$   copy sys$input: 'tc
$   deck
#include <stdio.h>
int main(){
  char test[10];
  snprintf(test,6,"%s","hello");
}
$   eod
$   test_inv = false
$   gosub cc_prop_check
$   return
$ endif
$ return
$!------------------------------------------------------------------------------
$!
$! Check for properties of C/C++ compiler
$!
$! Version history
$! 0.01 20031020 First version to receive a number
$! 0.02 20031022 Added logic for defines with value
$CC_PROP_CHECK:
$ cc_prop = true
$ is_need = false
$ is_need = (f$extract(0,4,cdef) .eqs. "NEED") .or. (test_inv .eq. true)
$ set message/nofac/noident/nosever/notext
$ on error then continue
$ cc 'tmpnam'
$ if .not. ($status)  then cc_prop = false
$ on error then continue
$! The headers might lie about the capabilities of the RTL
$ link 'tmpnam',tmp.opt/opt
$ if .not. ($status)  then cc_prop = false
$ set message/fac/ident/sever/text
$ on error then goto err_exit
$ delete/nolog 'tmpnam'.*;*
$ if (cc_prop .and. .not. is_need) .or. -
     (.not. cc_prop .and. is_need)
$ then
$   write sys$output "Checking for ''cdef'... yes"
$   allcdef = allcdef + cdef + ","
$   need_x11vms = true
$ else
$   write sys$output "Checking for ''cdef'... no"
$ endif
$ return
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
!   Xvmsutils: http://www.no-ip.info/vms/sw/xvmsutils.htmlx
!
!X11VMS   # pubbin:x11vmsshr.exe # x11vms: # vmsutil.h    # HAVE_X11VMS
$   write sys$output "New driver file vmslib.dat created."
$   write sys$output "Please customize libary locations for your site"
$   write sys$output "and afterwards re-execute vms_make.com"
$   write sys$output "Exiting..."
$   close/nolog optf
$   exit
$ endif
$!
$! Init symbols used to hold CPP definitons and include path
$!
$ libdefs = ""
$ libincs = ""
$!
$! Open data file with location of libraries
$!
$ open/write lopt lib.opt
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
$ if (cppdef .nes. "") then libdefs = libdefs +  cppdef + "\"
$ libincs = libincs + "," + libsrc
$ lqual = "/lib"
$ libtype = f$edit(f$parse(libloc,,,"TYPE"),"UPCASE")
$ if f$locate("EXE",libtype) .lt. f$length(libtype) then lqual = "/share"
$ write lopt libloc , lqual
$ if (f$trnlnm("topt") .nes. "") then write topt libloc , lqual
$ goto LIB_LOOP
$END_LIB:
$ close libdata
$ close lopt
$ return