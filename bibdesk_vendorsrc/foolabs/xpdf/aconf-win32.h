/*
 * aconf-win32.h
 *
 * Copyright 2002 Glyph & Cog, LLC
 */

#ifndef ACONF_H
#define ACONF_H

/*
 * Use A4 paper size instead of Letter for PostScript output.
 */
#undef A4_PAPER

/*
 * Do not allow text selection.
 */
#undef NO_TEXT_SELECT

/*
 * Include support for OPI comments.
 */
#undef OPI_SUPPORT

/*
 * Enable multithreading support.
 */
#define MULTITHREADED 1

/*
 * Directory with the Xpdf app-defaults file.
 */
#undef APPDEFDIR

/*
 * Full path for the system-wide xpdfrc file.
 */
#undef SYSTEM_XPDFRC

/*
 * Various include files and functions.
 */
#undef HAVE_DIRENT_H
#undef HAVE_SYS_NDIR_H
#undef HAVE_SYS_DIR_H
#undef HAVE_NDIR_H
#undef HAVE_SYS_SELECT_H
#undef HAVE_SYS_BSDTYPES_H
#undef HAVE_STRINGS_H
#undef HAVE_BSTRING_H
#undef HAVE_POPEN
#undef HAVE_MKSTEMP
#undef SELECT_TAKES_INT
#undef HAVE_FSEEK64

/*
 * This is defined if using libXpm.
 */
#undef HAVE_X11_XPM_H

/*
 * This is defined if using t1lib.
 */
#undef HAVE_T1LIB_H

/*
 * One of these is defined if using FreeType (version 1 or 2).
 */
#undef HAVE_FREETYPE_H
#undef HAVE_FREETYPE_FREETYPE_H

/*
 * This is defined if using FreeType version 2.
 */
#undef FREETYPE2

/*
 * This is defined if using libpaper.
 */
#undef HAVE_PAPER_H

#endif
