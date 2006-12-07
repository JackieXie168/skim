/*
 *  html2tex.h
 *  BibDesk
 *
 *
 */
// ARM:  this code was taken directly from HTML2LaTeX.  I modified it to return
// an NSString object, since working with FILE* streams led to really nasty problems
// with NSPipe needing asynchronous reads to avoid blocking.
// The following copyright notice was taken verbatim from the HTML2LaTeX code:

/* HTML2LaTeX -- Converting HTML files to LaTeX
Copyright (C) 1995-2003 Frans Faase

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

GNU General Public License:
http://home.planet.nl/~faase009/GNU.txt
*/

/************** ASCII-8 *****************/

#define HIGHASCII 126

/************** prototypes ***************/

NSString* TeXStringWithHTMLString(const char *str, FILE *freport, char *html_fn, int ln,
              BOOL in_math, BOOL in_verb, BOOL in_alltt);

/******* Translating special characters to LaTeX characters ******/

// Number of entries in the character table
#define NR_CH_TABLE 170
// ARM:  Not sure what NR_CH_M is for
#define NR_CH_M     159  

struct {
  char *html_ch;
  char *tex_ch;
  char ch;
} ch_table[NR_CH_TABLE] =
{
  /*160*/ { NULL,     "~",        '\0' },
  /*161*/ { NULL,     "!`",       '\0' },
  /*162*/ { NULL,     NULL,       '\0' },  /* "$\\cents" */
  /*163*/ { NULL,     "\\pounds", '\0' },
  /*164*/ { NULL,     NULL,       '\0' },  
  /*165*/ { NULL,     NULL,       '\0' },  /* Yen */
  /*166*/ { NULL,     "{\\tt |}", '\0' },
  /*167*/ { "sect",   "{\\S}",      '\0' },
  /*168*/ { NULL,     "{\\tt{}\"{}}", '\0' },
  /*169*/ { "c",      "\\copyright ", 'c' },
  /*170*/ { NULL,     NULL,       '\0' },
  /*171*/ { NULL,     "$\\ll",    '\0' },
  /*172*/ { NULL,     "$\\neg",   '\0' },
  /*173*/ { NULL,     "\\-",      '\0' },
  /*174*/ { NULL,     "{{\\ooalign{\\hfil\\raise.07ex\\hbox{R}\\hfil\\crcr\\mathhexbox20D}}}", '\0' },
  /*175*/ { NULL,     NULL,       '\0' },  /* "\\B " */
  /*176*/ { NULL,     "${}^\\circ", '\0' },
  /*177*/ { NULL,     "$\\pm",    '\0' },
  /*178*/ { NULL,     "${}^2",    '\0' },
  /*179*/ { NULL,     "${}^3",    '\0' },
  /*180*/ { NULL,     "\\'{}",    '\0' },
  /*181*/ { NULL,     "$\\mu",    '\0' },
  /*182*/ { NULL,     "{\\P}",    '\0' }, 
  /*183*/ { NULL,     NULL,       '\0' },    /* "\\D " */
  /*184*/ { NULL,     "\\c{}",     '\0' },
  /*185*/ { NULL,     "${}^1",    '\0' },
  /*186*/ { NULL,     NULL,       '\0' },      /* ^\underbar{o} */
  /*187*/ { NULL,     "$\\gg",    '\0' },
  /*188*/ { NULL,     "$\\frac14", '\0' },
  /*189*/ { NULL,     "$\\frac12", '\0' },
  /*190*/ { NULL,     "$\\frac34", '\0' },
  /*191*/ { "iquest", "?`",       '\0' },
  /*192*/ { "Agrave", "\\`A",     'A' },
  /*193*/ { "Aacute", "\\'A",     'A' },
  /*194*/ { "Acirc",  "\\^A" ,    'A' },
  /*195*/ { "Atilde", "\\~A",     'A' },
  /*196*/ { "Auml",   "\\\"A",    'A' },
  /*197*/ { "Aring",  "{\\AA}",   'A' },
  /*198*/ { "AElig",  "{\\AE}",   'A' },
  /*199*/ { "Ccedil", "\\c C",    'C' },
  /*200*/ { "Egrave", "\\`E",     'E' },
  /*201*/ { "Eacute", "\\'E",     'E' },
  /*202*/ { "Ecirc",  "\\^E",     'E' },
  /*203*/ { "Euml",   "\\\"E",    'E' },
  /*204*/ { "Igrave", "\\`I",     'I' },
  /*205*/ { "Iacute", "\\'I",     'I' },
  /*206*/ { "Icirc",  "\\^I",     'I' },
  /*207*/ { "Iuml",   "\\\"I",    'I' },
  /*208*/ { "ETH",     NULL,       'D' },   /* -D */
  /*209*/ { "Ntilde", "\\~N",     'N' },
  /*210*/ { "Ograve", "\\`O",     'O' },
  /*211*/ { "Oacute", "\\'O",     'O' },
  /*212*/ { "Ocirc",  "\\^O",     'O' },
  /*213*/ { "Otilde", "\\~O",     'O' },
  /*214*/ { "Ouml",   "\\\"O",    'O' },
  /*215*/ { NULL,     "$\\times", 'x' },
  /*216*/ { "Oslash", "{\\O}",    'O' },
  /*217*/ { "Ugrave", "\\`U",     'U' },
  /*218*/ { "Uacute", "\\'U",     'U' },
  /*219*/ { "Ucirc",  "\\^U",     'U' },
  /*220*/ { "Uuml",   "\\\"U",    'U' },
  /*221*/ { "Yacute", "\\'Y",     'Y' },
  /*222*/ { "THORN",  NULL,       'P' },   /* p thorn */
  /*223*/ { "szlig",  "{\\ss}",   's' },
  /*224*/ { "agrave", "\\`a",     'a' },
  /*225*/ { "aacute", "\\'a",     'a' },
  /*226*/ { "acirc",  "\\^a",     'a' },
  /*227*/ { "atilde", "\\~a",     'a' },
  /*228*/ { "auml",   "\\\"a",    'a' },
  /*229*/ { "aring",  "{\\aa}",   'a' },
  /*230*/ { "aelig",  "{\\ae}",   'a' },
  /*231*/ { "ccedil", "\\c c",    'c' },
  /*232*/ { "egrave", "\\`e",     'e' },
  /*233*/ { "eacute", "\\'e",     'e' },
  /*234*/ { "ecirc",  "\\^e",     'e' },
  /*235*/ { "euml",   "\\\"e",    'e' },
  /*236*/ { "igrave", "\\`{\\i}", 'i' },
  /*237*/ { "iacute", "\\'{\\i}", 'i' },
  /*238*/ { "icirc",  "\\^{\\i}", 'i' },
  /*239*/ { "iuml",   "\\\"{\\i}", 'i' },
  /*240*/ { "eth",    "\\v o",    'e' },
  /*241*/ { "ntilde", "\\~n",     'n' },
  /*242*/ { "ograve", "\\`o",     'o' },
  /*243*/ { "oacute", "\\'o",     'o' },
  /*244*/ { "ocirc",  "\\^o",     'o' },
  /*245*/ { "otilde", "\\~o",     'o' },
  /*246*/ { "ouml",   "\\\"o",    'o' },
  /*247*/ { NULL,     "$\\div",   '\0' },
  /*248*/ { "oslash", "{\\o}",    'o' },
  /*249*/ { "ugrave", "\\`u",     'u' },
  /*250*/ { "uacute", "\\'u",     'u' },
  /*251*/ { "ucirc",  "\\^u",     'u' },
  /*252*/ { "uuml",   "\\\"u",    'u' },
  /*253*/ { "yacute", "\\'y",     'y' },
  /*254*/ { "thorn",  "p",        'p' },  /* p thorn */
  /*255*/ { "yuml", "\\'y",       'y' },
		  { "aring",  "{\\aa}",   'a' },
		  { "Eth",    "\\v O",    'E' },
		  { "icirc",  "\\^{\\i}", 'i' },
		  { "Thorn",  "P",        'P' },
		  { "Yuml",   "\\\"Y",    'Y' },

		  { "nbsp",   "~",        ' ' },
		  { "emsp",   "\\quad{}", ' ' },
		  { "ensp",   "\\enskip{}",' ' },
		  { "shy",    "",         0   },
		  { "pd",     "",         0   },
		  { "emdash", "---",      '-' },
		  { "endash", "--",       '-' },
		  { "copy",   "\\copyright ", 'c' },
		  { "reg",    "",         0   },
		  { "trade",  "",         0   },

		  { "alpha",  "$\\alpha", 0   },
		  { "beta",   "$\\beta",  0   },
		  { "gamma",  "$\\gamma", 0   },
		  { "delta",  "$\\delta", 0   },
		  { "epsi",   "$\\epsilon",0   },
		  { "zeta",   "$\\zeta",  0   },
		  { "eta",    "$\\eta",   0   },
		  { "theta",  "$\\theta", 0   },
		  { "thetav", "$\\vartheta",0   },
		  { "iota",   "$\\iota",  0   },
		  { "kappa",  "$\\kappa", 0   },
		  { "lambda", "$\\lambda",0   },
		  { "mu",     "$\\mu",    0   },
		  { "nu",     "$\\nu",    0   },
		  { "xi",     "$\\xi",    0   },
		  { "omicron","o",        0   },
		  { "pi",     "$\\pi",    0   },
		  { "rho",    "$\\rho",   0   },
		  { "sigma",  "$\\sigma", 0   },
		  { "tau",    "$\\tau",   0   },
		  { "upsi",   "$\\upsilon",0   },
		  { "phi",    "$\\phi",   0   },
		  { "chi",    "$\\chi",   0   },
		  { "psi",    "$\\psi",   0   },
		  { "omega",  "$\\omega", 0   },

		  { "Alpha",  "A",        'A' },
		  { "Beta",   "B",        'B' },
		  { "Gamma",  "$\\Gamma", 0   },
		  { "Delta",  "$\\Delta", 0   },
		  { "Epsi",   "E",        'E' },
		  { "Zeta",   "Z",        'Z' },
		  { "Eta",    "H",        'H' },
		  { "Theta",  "$\\Theta", 0   },
		  { "Iota",   "I",        'I' },
		  { "Kappa",  "K",        'K' },
		  { "Lambda", "$\\Lambda",0   },
		  { "Mu",     "M",        'M' },
		  { "Nu",     "N",        'N' },
		  { "Xi",     "$\\Xi",    0   },
		  { "Pi",     "$\\Pi",    0   },
		  { "Rho",    "R",        'R' },
		  { "Sigma",  "$\\Sigma", 0   },
		  { "Tau",    "T",        'T' },
		  { "Upsi",   "$\\Upsilon",0   },
		  { "Phi",    "$\\Phi",   0   },
		  { "Chi",    "X",        'X' },
		  { "Psi",    "$\\Psi",   0   },
		  { "Omega",  "$\\Omega", 0   },

		  { "amp",    "\\&",      '&' },
		  { "gt",     "$>",       '>' },
		  { "lt",     "$<",       '<' },
		  { "quot",   "\\\"{}",   '"' },
// BibDesk additions
          { "plusmn", "$\\pm",   '\0' },
          { "times",  "$\\times",   'x' },
          { "deg",    "\\ensuremath{^{\\raise1pt\\hbox{$\\scriptstyle\\circ$}}}",   'o'},
          { "frac",   "/",    '/' },
		  { "Omicron","O",        0   },
		  { "epsilon","$\\epsilon",0  },
          { "middot", "$\\cdot",  0   },


};


