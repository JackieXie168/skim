This file is part of the SyncTeX package.

The Synchronization TeXnology named SyncTeX is a new feature
of recent TeX engines designed by Jérôme Laurens.
It allows to synchronize between input and output, which means to
navigate from the source document to the typeset material and vice versa.
More informations on http://itexmac2.sourceforge.net/SyncTeX.html

This package is mainly for developers, it contains the following files:

synctex_parser_readme.txt
synctex_parser_version.txt
synctex_parser_local.h
synctex_parser.h
synctex_parser.c

This file contains more informations about the SyncTeX parser history.

In order to support SyncTeX in a viewer, it is sufficient to include
in the source the files synctex_parser.h and synctex_parser.c.
The synctex parser usage is described in synctex_parser.h header file.

Version:
--------
This is version 1, which refers to the synctex output file format.
The files are identified by a build number.
In order to help developers to automatically manage the version and build numbers
and download the parser only when necessary, the synctex_parser.version
is an ASCII text file just containing the current version and build numbers.

History:
--------
1.1: Thu Jul 17 09:28:13 UTC 2008
- First official version available in TeXLive 2008 DVD.
  Unfortunately, the backwards synchronization is not working properly mainly for ConTeXt users, see below.
1.2: Tue Sep  2 10:28:32 UTC 2008
- Correction for ConTeXt support in the edit query.
  Thefile://localhost/Volumes/HD1/Users/coder/dev/texlive/source/texk/web2c/synctexdir/synctex_parser.version previous method was assuming that TeX boxes do not overlap,
  which is reasonable for LaTeX but not for ConTeXt.
  This assumption is no longer considered.
1.3: Thu Sep  4 11:30:29 UTC 2008
- Local variable "read" renamed to "already_read" to avoid conflicts.
- "inline" compiler directive renamed to "SYNCTEX_INLINE" for code support and maintenance

Acknowledgments:
----------------
The author received useful remarks from the pdfTeX developers, especially Hahn The Thanh,
and significant help from XeTeX developer Jonathan Kew

Nota Bene:
----------
If you include or use a significant part of the synctex package into a software,
I would appreciate to be listed as contributor and see "SyncTeX" highlighted.

Copyright (c) 2008 jerome DOT laurens AT u-bourgogne DOT fr

