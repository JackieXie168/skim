set CC=cl
set CFLAGS=/DWIN32 /I.. /I..\goo /O2 /nologo
set CXX=cl
set CXXFLAGS=%CFLAGS% /TP
set LIBPROG=lib

copy aconf-win32.h aconf.h

cd goo
%CXX% %CXXFLAGS% /c GHash.cc
%CXX% %CXXFLAGS% /c GList.cc
%CXX% %CXXFLAGS% /c GString.cc
%CXX% %CXXFLAGS% /c gmempp.cc
%CXX% %CXXFLAGS% /c gfile.cc
%CC% %CFLAGS% /c gmem.c
%CC% %CFLAGS% /c parseargs.c
%LIBPROG% /nologo /out:libGoo.lib GHash.obj GList.obj GString.obj gmempp.obj gfile.obj gmem.obj parseargs.obj

cd ..\xpdf
%CXX% %CXXFLAGS% /c Annot.cc
%CXX% %CXXFLAGS% /c Array.cc
%CXX% %CXXFLAGS% /c BuiltinFont.cc
%CXX% %CXXFLAGS% /c BuiltinFontTables.cc
%CXX% %CXXFLAGS% /c CMap.cc
%CXX% %CXXFLAGS% /c Catalog.cc
%CXX% %CXXFLAGS% /c CharCodeToUnicode.cc
%CXX% %CXXFLAGS% /c Decrypt.cc
%CXX% %CXXFLAGS% /c Dict.cc
%CXX% %CXXFLAGS% /c Error.cc
%CXX% %CXXFLAGS% /c FontEncodingTables.cc
%CXX% %CXXFLAGS% /c FontFile.cc
%CXX% %CXXFLAGS% /c Function.cc
%CXX% %CXXFLAGS% /c Gfx.cc
%CXX% %CXXFLAGS% /c GfxFont.cc
%CXX% %CXXFLAGS% /c GfxState.cc
%CXX% %CXXFLAGS% /c GlobalParams.cc
%CXX% %CXXFLAGS% /c ImageOutputDev.cc
%CXX% %CXXFLAGS% /c JBIG2Stream.cc
%CXX% %CXXFLAGS% /c Lexer.cc
%CXX% %CXXFLAGS% /c Link.cc
%CXX% %CXXFLAGS% /c NameToCharCode.cc
%CXX% %CXXFLAGS% /c Object.cc
%CXX% %CXXFLAGS% /c Outline.cc
%CXX% %CXXFLAGS% /c OutputDev.cc
%CXX% %CXXFLAGS% /c PDFDoc.cc
%CXX% %CXXFLAGS% /c PDFDocEncoding.cc
%CXX% %CXXFLAGS% /c PSOutputDev.cc
%CXX% %CXXFLAGS% /c PSTokenizer.cc
%CXX% %CXXFLAGS% /c Page.cc
%CXX% %CXXFLAGS% /c Parser.cc
%CXX% %CXXFLAGS% /c Stream.cc
%CXX% %CXXFLAGS% /c TextOutputDev.cc
%CXX% %CXXFLAGS% /c UnicodeMap.cc
%CXX% %CXXFLAGS% /c XRef.cc
%CXX% %CXXFLAGS% /c pdftops.cc
%CXX% %CXXFLAGS% /c pdftotext.cc
%CXX% %CXXFLAGS% /c pdfinfo.cc
%CXX% %CXXFLAGS% /c pdffonts.cc
%CXX% %CXXFLAGS% /c pdfimages.cc

%CXX% /nologo /Fepdftops.exe Annot.obj Array.obj BuiltinFont.obj BuiltinFontTables.obj Catalog.obj CharCodeToUnicode.obj CMap.obj Decrypt.obj Dict.obj Error.obj FontEncodingTables.obj FontFile.obj Function.obj Gfx.obj GfxFont.obj GfxState.obj GlobalParams.obj JBIG2Stream.obj Lexer.obj Link.obj NameToCharCode.obj Object.obj Outline.obj OutputDev.obj Page.obj Parser.obj PDFDoc.obj PDFDocEncoding.obj PSOutputDev.obj PSTokenizer.obj Stream.obj UnicodeMap.obj XRef.obj pdftops.obj ..\goo\libGoo.lib

%CXX% /nologo /Fepdftotext.exe Annot.obj Array.obj BuiltinFont.obj BuiltinFontTables.obj Catalog.obj CharCodeToUnicode.obj CMap.obj Decrypt.obj Dict.obj Error.obj FontEncodingTables.obj FontFile.obj Function.obj Gfx.obj GfxFont.obj GfxState.obj GlobalParams.obj JBIG2Stream.obj Lexer.obj Link.obj NameToCharCode.obj Object.obj Outline.obj OutputDev.obj Page.obj Parser.obj PDFDoc.obj PDFDocEncoding.obj PSTokenizer.obj Stream.obj TextOutputDev.obj UnicodeMap.obj XRef.obj pdftotext.obj ..\goo\libGoo.lib

%CXX% /nologo /Fepdfinfo.exe Annot.obj Array.obj BuiltinFont.obj BuiltinFontTables.obj Catalog.obj CharCodeToUnicode.obj CMap.obj Decrypt.obj Dict.obj Error.obj FontEncodingTables.obj FontFile.obj Function.obj Gfx.obj GfxFont.obj GfxState.obj GlobalParams.obj JBIG2Stream.obj Lexer.obj Link.obj NameToCharCode.obj Object.obj Outline.obj OutputDev.obj Page.obj Parser.obj PDFDoc.obj PDFDocEncoding.obj PSTokenizer.obj Stream.obj UnicodeMap.obj XRef.obj pdfinfo.obj ..\goo\libGoo.lib

%CXX% /nologo /Fepdffonts.exe Annot.obj Array.obj BuiltinFont.obj BuiltinFontTables.obj Catalog.obj CharCodeToUnicode.obj CMap.obj Decrypt.obj Dict.obj Error.obj FontEncodingTables.obj FontFile.obj Function.obj Gfx.obj GfxFont.obj GfxState.obj GlobalParams.obj JBIG2Stream.obj Lexer.obj Link.obj NameToCharCode.obj Object.obj Outline.obj OutputDev.obj Page.obj Parser.obj PDFDoc.obj PDFDocEncoding.obj PSTokenizer.obj Stream.obj UnicodeMap.obj XRef.obj pdffonts.obj ..\goo\libGoo.lib

%CXX% /nologo /Fepdfimages.exe Annot.obj Array.obj BuiltinFont.obj BuiltinFontTables.obj Catalog.obj CharCodeToUnicode.obj CMap.obj Decrypt.obj Dict.obj Error.obj FontEncodingTables.obj FontFile.obj Function.obj Gfx.obj GfxFont.obj GfxState.obj GlobalParams.obj ImageOutputDev.obj JBIG2Stream.obj Lexer.obj Link.obj NameToCharCode.obj Object.obj Outline.obj OutputDev.obj Page.obj Parser.obj PDFDoc.obj PDFDocEncoding.obj PSTokenizer.obj Stream.obj UnicodeMap.obj XRef.obj pdfimages.obj ..\goo\libGoo.lib

cd ..
