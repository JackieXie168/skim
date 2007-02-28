
/* graphics.c - routines that handle LaTeX graphics commands

Copyright (C) 2001-2002 The Free Software Foundation

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

This file is available from http://sourceforge.net/projects/latex2rtf/
 
Authors:
    2001-2002 Scott Prahl
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <limits.h>
#ifdef UNIX
#include <unistd.h>
#endif
#include "cfg.h"
#include "main.h"
#include "graphics.h"
#include "parser.h"
#include "util.h"
#include "commands.h"
#include "convert.h"
#include "equation.h"
#include "funct1.h"

#define POINTS_PER_M 2834.65

/* Little endian macros to convert to and from host format to network byte ordering */
#define LETONS(A) ((((A) & 0xFF00) >> 8) | (((A) & 0x00FF) << 8))
#define LETONL(A) ((((A) & 0xFF000000) >> 24) | (((A) & 0x00FF0000) >>  8) | \
                  (((A) & 0x0000FF00) <<  8) | (((A) & 0x000000FF) << 24) )

/*
Version 1.6 RTF files can include pictures as follows

<pict> 			'{' \pict (<brdr>? & <shading>? & <picttype> & <pictsize> & <metafileinfo>?) <data> '}'
<picttype>		\emfblip | \pngblip | \jpegblip | \macpict | \pmmetafile | \wmetafile 
			 	         | \dibitmap <bitmapinfo> | \wbitmap <bitmapinfo>
<bitmapinfo> 	\wbmbitspixel & \wbmplanes & \wbmwidthbytes
<pictsize> 		(\picw & \pich) \picwgoal? & \pichgoal? \picscalex? & \picscaley? & \picscaled? & \piccropt? & \piccropb? & \piccropr? & \piccropl?
<metafileinfo> 	\picbmp & \picbpp
<data> 			(\bin #BDATA) | #SDATA

\emfblip 				Source of the picture is an EMF (enhanced metafile).
\pngblip 				Source of the picture is a PNG.
\jpegblip 				Source of the picture is a JPEG.
\shppict 				Specifies a Word 97-2000 picture. This is a destination control word.
\nonshppict 			Specifies that Word 97-2000 has written a {\pict destination that it 
						will not read on input. This keyword is for compatibility with other readers.
\macpict                Source of the picture is PICT file (Quickdraw)
\pmmetafileN            Source of the picture is an OS/2 metafile
\wmetafileN             Source of the picture is a Windows metafile
\dibitmapN              Source of the picture is a Windows device-independent bitmap
\wbitmapN               Source of the picture is a Windows device-dependent bitmap
*/

typedef struct _WindowsMetaHeader {
    unsigned short FileType;    /* Type of metafile (0=memory, 1=disk) */
    unsigned short HeaderSize;  /* Size of header in WORDS (always 9) */
    unsigned short Version;     /* Version of Microsoft Windows used */
    unsigned long FileSize;     /* Total size of the metafile in WORDs */
    unsigned short NumOfObjects;    /* Number of objects in the file */
    unsigned long MaxRecordSize;    /* The size of largest record in WORDs */
    unsigned short NumOfParams; /* Not Used (always 0) */
} WMFHEAD;

typedef struct _PlaceableMetaHeader {
    unsigned long Key;          /* Magic number (always 0x9AC6CDD7) */
    unsigned short Handle;      /* Metafile HANDLE number (always 0) */
    short Left;                 /* Left coordinate in twips */
    short Top;                  /* Top coordinate in twips */
    short Right;                /* Right coordinate in twips */
    short Bottom;               /* Bottom coordinate in twips */
    unsigned short Inch;        /* Scaling factor, 1440 => 1:1, 360 => 4:1, 2880 => 1:2 (half size) */
    unsigned long Reserved;     /* Reserved (always 0) */
    unsigned short Checksum;    /* Checksum value for previous 10 WORDs */
} PLACEABLEMETAHEADER;

typedef struct _EnhancedMetaHeader {
    unsigned long RecordType;   /* Record type (always 0x00000001) */
    unsigned long RecordSize;   /* Size of the record in bytes */
    long BoundsLeft;            /* Left inclusive bounds */
    long BoundsTop;             /* Top inclusive bounds */
    long BoundsRight;           /* Right inclusive bounds */
    long BoundsBottom;          /* Bottom inclusive bounds */
    long FrameLeft;             /* Left side of inclusive picture frame */
    long FrameTop;              /* Top side of inclusive picture frame */
    long FrameRight;            /* Right side of inclusive picture frame */
    long FrameBottom;           /* Bottom side of inclusive picture frame */
    unsigned long Signature;    /* Signature ID (always 0x464D4520) */
    unsigned long Version;      /* Version of the metafile */
    unsigned long Size;         /* Size of the metafile in bytes */
    unsigned long NumOfRecords; /* Number of records in the metafile */
    unsigned short NumOfHandles;    /* Number of handles in the handle table */
    unsigned short Reserved;    /* Not used (always 0) */
    unsigned long SizeOfDescrip;    /* Size of description string in WORDs */
    unsigned long OffsOfDescrip;    /* Offset of description string in metafile */
    unsigned long NumPalEntries;    /* Number of color palette entries */
    long WidthDevPixels;        /* Width of reference device in pixels */
    long HeightDevPixels;       /* Height of reference device in pixels */
    long WidthDevMM;            /* Width of reference device in millimeters */
    long HeightDevMM;           /* Height of reference device in millimeters */
} ENHANCEDMETAHEADER;

typedef struct _EmrFormat {
    unsigned long Signature;    /* 0x46535045 for EPS, 0x464D4520 for EMF */
    unsigned long Version;      /* EPS version number or 0x00000001 for EMF */
    unsigned long Data;         /* Size of data in bytes */
    unsigned long OffsetToData; /* Offset to data */
} EMRFORMAT;

typedef struct _GdiCommentMultiFormats {
    unsigned long Identifier;   /* Comment ID (0x43494447) */
    unsigned long Comment;      /* Multiformats ID (0x40000004) */
    long BoundsLeft;            /* Left side of bounding rectangle */
    long BoundsRight;           /* Right side of bounding rectangle */
    long BoundsTop;             /* Top side of bounding rectangle */
    long BoundsBottom;          /* Bottom side of bounding rectangle */
    unsigned long NumFormats;   /* Number of formats in comment */
    EMRFORMAT *Data;            /* Array of comment data */
} GDICOMMENTMULTIFORMATS;

static void my_unlink(char *filename)

/******************************************************************************
     purpose : portable routine to delete filename
 ******************************************************************************/
{
#ifdef UNIX
    unlink(filename);
#endif
}

static
void PicComment(short label, short size, FILE * fp)
{
    short long_comment = 0x00A1;
    short short_comment = 0x00A0;
    short tag;

    tag = (size) ? long_comment : short_comment;

    if (g_little_endian) {
        tag = LETONS(tag);
        label = LETONS(label);
        size = LETONS(size);
    }

    if (fwrite(&tag, 2, 1, fp) != 2)
        return;
    if (fwrite(&label, 2, 1, fp) != 2)
        return;
    if (size) {
        if (fwrite(&size, 2, 1, fp) != 2)
            return;
    }
}

static char *strdup_new_extension(char *s, char *old_ext, char *new_ext)
{
    char *new_name, *p;

    p = strstr(s, old_ext);
    if (p == NULL)
        return NULL;

    new_name = strdup_together(s, new_ext);
    p = strstr(new_name, old_ext);
    strcpy(p, new_ext);
    return new_name;
}

static char *strdup_absolute_path(char *s)

/******************************************************************************
     purpose : return a string containing an absolute path
 ******************************************************************************/
{
    char c = PATHSEP;
    char *abs_path = NULL;

    if (s) {
        if (*s == c || g_home_dir == NULL)
            abs_path = strdup(s);
        else
            abs_path = strdup_together(g_home_dir, s);
    }

    return abs_path;
}


static char *strdup_tmp_path(char *s)

/******************************************************************************
     purpose : create a tmp file name using only the end of the filename
 ******************************************************************************/
{
    char *tmp, *p, *fullname, c;

    if (s == NULL)
        return NULL;

    tmp = getTmpPath();

    c = PATHSEP;
    p = strrchr(s, c);

    if (!p)
        fullname = strdup_together(tmp, s);
    else
        fullname = strdup_together(tmp, p + 1);

    free(tmp);
    return fullname;
}


static char *eps_to_pict(char *s)

/******************************************************************************
     purpose : create a pict file from an EPS file and return file name for
               the pict file.  Ideally this file will contain both the bitmap
               and the original EPS embedded in the PICT file as comments.  If a
               bitmap cannot be created, then the EPS is still embedded in the PICT
               file so that at least the printed version will be good.
 ******************************************************************************/
{
    char *cmd, *p, buffer[560];
    size_t cmd_len;
    long ii, pict_bitmap_size, eps_size;
    short err, handle_size;
    unsigned char byte;
    short PostScriptBegin = 190;
    short PostScriptEnd = 191;
    short PostScriptHandle = 192;
    char *pict_bitmap = NULL;
    char *pict_eps = NULL;
    char *eps = NULL;
    char *return_value = NULL;
    FILE *fp_eps = NULL;
    FILE *fp_pict_bitmap = NULL;
    FILE *fp_pict_eps = NULL;

    diagnostics(2, "eps_to_pict filename = <%s>", s);

    /* Create filename for bitmap */
    p = strdup_new_extension(s, ".eps", "a.pict");
    if (p == NULL) {
        p = strdup_new_extension(s, ".EPS", "a.pict");
        if (p == NULL)
            goto Exit;
    }
    pict_bitmap = strdup_tmp_path(p);
    free(p);

    /* Create filename for eps file */
    p = strdup_new_extension(s, ".eps", ".pict");
    if (p == NULL) {
        p = strdup_new_extension(s, ".EPS", ".pict");
        if (p == NULL)
            goto Exit;
    }
    pict_eps = strdup_tmp_path(p);
    free(p);

    eps = strdup_together(g_home_dir, s);

    /* create a bitmap version of the eps file */
    cmd_len = strlen(eps) + strlen(pict_bitmap) + strlen("convert -crop 0x0 -density ") + 40;
    cmd = (char *) malloc(cmd_len);
    snprintf(cmd, cmd_len, "convert -crop 0x0 -density %d %s %s", g_dots_per_inch, eps, pict_bitmap);
    diagnostics(2, "system graphics command = [%s]", cmd);
    err = system(cmd);
    free(cmd);

    if (err != 0)
        diagnostics(WARNING, "problem creating bitmap from %s", eps);
    else
        return_value = pict_bitmap;

    /* open the eps file and make sure that it is less than 32k */
    fp_eps = fopen(eps, "rb");
    if (fp_eps == NULL)
        goto Exit;
    fseek(fp_eps, 0, SEEK_END);
    eps_size = ftell(fp_eps);
    if (eps_size > 32000) {
        diagnostics(WARNING, "EPS file >32K ... using bitmap only");
        goto Exit;
    }
    rewind(fp_eps);
    diagnostics(WARNING, "eps size is 0x%X bytes", eps_size);

    /* open bitmap pict file and get file size */
    fp_pict_bitmap = fopen(pict_bitmap, "rb");
    if (fp_pict_bitmap == NULL)
        goto Exit;
    fseek(fp_pict_bitmap, 0, SEEK_END);
    pict_bitmap_size = ftell(fp_pict_bitmap);
    rewind(fp_pict_bitmap);

    /* open new pict file */
    fp_pict_eps = fopen(pict_eps, "w");
    if (fp_pict_eps == NULL)
        goto Exit;

    /* copy header 512 buffer + 40 byte header */
    if (fread(&buffer, 1, 512 + 40, fp_pict_bitmap) != 512 + 40)
        goto Exit;
    if (fwrite(&buffer, 1, 512 + 40, fp_pict_eps) != 512 + 40)
        goto Exit;

    /* insert comment that allows embedding postscript */
    PicComment(PostScriptBegin, 0, fp_pict_eps);

    /* copy bitmap 512+40 bytes of header + 2 bytes at end */
    for (ii = 512 + 40 + 2; ii < pict_bitmap_size; ii++) {
        if (fread(&byte, 1, 1, fp_pict_bitmap) != 1)
            goto Exit;
        if (fwrite(&byte, 1, 1, fp_pict_eps) != 1)
            goto Exit;
    }

    /* copy eps graphic (write an even number of bytes) */
    handle_size = eps_size;
    if (odd(eps_size))
        handle_size++;

    PicComment(PostScriptHandle, handle_size, fp_pict_eps);
    for (ii = 0; ii < eps_size; ii++) {
        if (fread(&byte, 1, 1, fp_eps) != 1)
            goto Exit;
        if (fwrite(&byte, 1, 1, fp_pict_eps) != 1)
            goto Exit;
    }
    if (odd(eps_size)) {
        byte = ' ';
        if (fwrite(&byte, 1, 1, fp_pict_eps) != 1)
            goto Exit;
    }

    /* close file */
    PicComment(PostScriptEnd, 0, fp_pict_eps);
    byte = 0x00;
    if (fwrite(&byte, 1, 1, fp_pict_eps) != 1)
        goto Exit;
    byte = 0xFF;
    if (fwrite(&byte, 1, 1, fp_pict_eps) != 1)
        goto Exit;

    return_value = pict_eps;

  Exit:
    if (eps)
        free(eps);
    if (pict_eps)
        free(pict_eps);
    if (pict_bitmap)
        free(pict_bitmap);

    if (fp_eps)
        fclose(fp_eps);
    if (fp_pict_eps)
        fclose(fp_pict_eps);
    if (fp_pict_bitmap)
        fclose(fp_pict_bitmap);
    return return_value;
}

static char *eps_to_png(char *eps)

/******************************************************************************
     purpose : create a png file from an EPS or PS file and return file name
 ******************************************************************************/
{
    char *cmd, *s1, *p, *png;
    size_t cmd_len;

    diagnostics(1, "filename = <%s>", eps);

    s1 = strdup(eps);
    if ((p = strstr(s1, ".eps")) == NULL && (p = strstr(s1, ".EPS")) == NULL &&
      (p = strstr(s1, ".ps")) == NULL && (p = strstr(s1, ".PS")) == NULL) {
        diagnostics(1, "<%s> is not an EPS or PS file", eps);
        free(s1);
        return NULL;
    }

    strcpy(p, ".png");
    png = strdup_tmp_path(s1);
    cmd_len = strlen(eps) + strlen(png) + 40;
    cmd = (char *) malloc(cmd_len);
    snprintf(cmd, cmd_len, "convert -density %d %s %s", g_dots_per_inch, eps, png);
    diagnostics(2, "system graphics command = [%s]", cmd);
    system(cmd);

    free(cmd);
    free(s1);
    return png;
}

static char *pdf_to_png(char *pdf)

/******************************************************************************
     purpose : create a png file from an PDF file and return file name
 ******************************************************************************/
{
    char *cmd, *s1, *p, *png;
    size_t cmd_len;

    diagnostics(1, "filename = <%s>", pdf);

    s1 = strdup(pdf);
    if ((p = strstr(s1, ".pdf")) == NULL && (p = strstr(s1, ".PDF")) == NULL) {
        diagnostics(1, "<%s> is not a PDF file", pdf);
        free(s1);
        return NULL;
    }

    strcpy(p, ".png");
    png = strdup_tmp_path(s1);
    cmd_len = strlen(pdf) + strlen(png) + 40;
    cmd = (char *) malloc(cmd_len);
    snprintf(cmd, cmd_len, "convert -density %d %s %s", g_dots_per_inch, pdf, png);
    diagnostics(2, "system graphics command = [%s]", cmd);
    system(cmd);

    free(cmd);
    free(s1);
    return png;
}

static char *eps_to_emf(char *eps)

/******************************************************************************
     purpose : create a wmf file from an EPS file and return file name
 ******************************************************************************/
{
    FILE *fp;
    char *cmd, *s1, *p, *emf;
    size_t cmd_len;

    char ans[50];
    long width, height;

    diagnostics(1, "filename = <%s>", eps);

    s1 = strdup(eps);
    if ((p = strstr(s1, ".eps")) == NULL && (p = strstr(s1, ".EPS")) == NULL) {
        diagnostics(1, "<%s> is not an EPS file", eps);
        free(s1);
        return NULL;
    }

    strcpy(p, ".wmf");
    emf = strdup_tmp_path(s1);

    /* Determine bounding box for EPS file */
    cmd_len = strlen(eps) + strlen("identify -format \"%w %h\" ") + 1;
    cmd = (char *) malloc(cmd_len);
    snprintf(cmd, cmd_len, "identify -format \"%%w %%h\" %s", eps);
    fp = popen(cmd, "r");
    if (fgets(ans, 50, fp) != NULL)
        sscanf(ans, "%ld %ld", &width, &height);
    pclose(fp);
    free(cmd);

    fp = fopen(emf, "wb");

    /* write ENHANCEDMETAHEADER */

    /* write GDICOMMENTMULTIFORMATS */

    /* write EMRFORMAT containing EPS */

    free(s1);
    fclose(fp);
    return emf;
}


static void PutHexFile(FILE * fp)

/******************************************************************************
     purpose : write entire file to RTF as hex
 ******************************************************************************/
{
    int i, c;

    i = 0;
    while ((c = fgetc(fp)) != EOF) {
        fprintRTF("%.2x", c);
        if (++i > 126) {        /* keep lines 254 chars long */
            i = 0;
            fprintRTF("\n");
        }
    }
}

static void PutPictFile(char *s, double scale, double baseline, int full_path)

/******************************************************************************
     purpose : Include .pict file in RTF
 ******************************************************************************/
{
    FILE *fp;
    char *pict;
    short buffer[5];
    short top, left, bottom, right;
    int width, height;

    if (full_path)
        pict = strdup(s);
    else
        pict = strdup_together(g_home_dir, s);
    diagnostics(1, "PutPictFile <%s>", pict);

    fp = fopen(pict, "rb");
    free(pict);
    if (fp == NULL)
        return;

    if (fseek(fp, 514L, SEEK_SET) || fread(buffer, 2, 4, fp) != 4) {
        diagnostics(WARNING, "Cannot read graphics file <%s>", s);
        fclose(fp);
        return;
    }

    top = buffer[0];
    left = buffer[1];
    bottom = buffer[2];
    right = buffer[3];

    width = right - left;
    height = bottom - top;

    if (g_little_endian) {
        top = LETONS(top);
        bottom = LETONS(bottom);
        left = LETONS(left);
        right = LETONS(right);
    }

    diagnostics(4, "top = %d, bottom = %d", top, bottom);
    diagnostics(4, "left = %d, right = %d", left, right);
    diagnostics(4, "width = %d, height = %d", width, height);
    fprintRTF("\n{\\pict\\macpict\\picw%d\\pich%d\n", width, height);
    if (scale != 1.0) {
        int iscale = (int) (scale * 100);

        fprintRTF("\\picscalex%d\\picscaley%d", iscale, iscale);
    }

    fseek(fp, -10L, SEEK_CUR);
    PutHexFile(fp);
    fprintRTF("}\n");
    fclose(fp);
}

static void GetPngSize(char *s, unsigned long *w, unsigned long *h)

/******************************************************************************
     purpose : determine height and width of file
 ******************************************************************************/
{
    FILE *fp;
    unsigned char buffer[16];
    unsigned long width, height;
    char reftag[9] = "\211PNG\r\n\032\n";
    char refchunk[5] = "IHDR";

    *w = 0;
    *h = 0;
    fp = fopen(s, "rb");
    if (fp == NULL)
        return;

    if (fread(buffer, 1, 16, fp) < 16) {
        diagnostics(WARNING, "Cannot read graphics file <%s>", s);
        fclose(fp);
        return;
    }

    if (memcmp(buffer, reftag, 8) != 0 || memcmp(buffer + 12, refchunk, 4) != 0) {
        diagnostics(WARNING, "Graphics file <%s> is not a PNG file!", s);
        fclose(fp);
        return;
    }

    if (fread(&width, 4, 1, fp) != 1 || fread(&height, 4, 1, fp) != 1) {
        diagnostics(WARNING, "Cannot read graphics file <%s>", s);
        fclose(fp);
        return;
    }

    if (g_little_endian) {
        width = LETONL(width);
        height = LETONL(height);
    }

    *w = width;
    *h = height;
    fclose(fp);
}

void PutPngFile(char *s, double scale, double baseline, int full_path)

/******************************************************************************
     purpose : Include .png file in RTF
 ******************************************************************************/
{
    FILE *fp;
    char *png;
    unsigned long width, height, w, h, b;
    int iscale;

    if (full_path)
        png = strdup(s);
    else
        png = strdup_together(g_home_dir, s);
    diagnostics(2, "PutPngFile <%s>", png);

    GetPngSize(png, &width, &height);

    diagnostics(4, "width = %ld, height = %ld, baseline = %g", width, height, baseline);

    if (width == 0 || height == 0)
        return;

    fp = fopen(png, "rb");
    free(png);
    if (fp == NULL)
        return;

    w = (unsigned long) (100000.0 * width) / (20 * POINTS_PER_M);
    h = (unsigned long) (100000.0 * height) / (20 * POINTS_PER_M);
    b = (unsigned long) (100000.0 * baseline * scale) / (20 * POINTS_PER_M);

    diagnostics(4, "width = %ld, height = %ld, baseline = %ld", w, h, b);

    fprintRTF("\n{");
    if (b)
        fprintRTF("\\dn%ld", b);
    fprintRTF("\\pict\\pngblip\\picw%ld\\pich%ld", w, h);
    fprintRTF("\\picwgoal%ld\\pichgoal%ld", width * 20, height * 20);
    if (scale != 1.0) {
        iscale = (int) (scale * 100);
        fprintRTF("\\picscalex%d\\picscaley%d", iscale, iscale);
    }
    fprintRTF("\n");
    rewind(fp);
    PutHexFile(fp);
    fprintRTF("}\n");
    fclose(fp);
}

static void PutJpegFile(char *s, double scale, double baseline, int full_path)

/******************************************************************************
     purpose : Include .jpeg file in RTF
 ******************************************************************************/
{
    FILE *fp;
    char *jpg;
    unsigned short buffer[2];
    int m, c;
    unsigned short width, height;
    unsigned long w, h;

    jpg = strdup_together(g_home_dir, s);
    fp = fopen(jpg, "rb");
    free(jpg);
    if (fp == NULL)
        return;

    if ((c = fgetc(fp)) != 0xFF && (c = fgetc(fp)) != 0xD8) {
        fclose(fp);
        diagnostics(WARNING, "<%s> is not really a JPEG file --- skipping");
        return;
    }

    do {                        /* Look for SOFn tag */

        while (!feof(fp) && fgetc(fp) != 0xFF) {
        }                       /* Find 0xFF byte */

        while (!feof(fp) && (m = fgetc(fp)) == 0xFF) {
        }                       /* Skip multiple 0xFFs */

    } while (!feof(fp) && m != 0xC0 && m != 0xC1 && m != 0xC2 && m != 0xC3 && m != 0xC5 && m != 0xC6 && m != 0xC7 &&
      m != 0xC9 && m != 0xCA && m != 0xCB && m != 0xCD && m != 0xCE && m != 0xCF);

    if (fseek(fp, 3, SEEK_CUR) || fread(buffer, 2, 2, fp) != 2) {
        diagnostics(WARNING, "Cannot read graphics file <%s>", s);
        fclose(fp);
        return;
    }

    width = buffer[1];
    height = buffer[0];

    if (g_little_endian) {
        width = (unsigned short) LETONS(width);
        height = (unsigned short) LETONS(height);
    }

    diagnostics(4, "width = %d, height = %d", width, height);

    w = (unsigned long) (100000.0 * width) / (20 * POINTS_PER_M);
    h = (unsigned long) (100000.0 * height) / (20 * POINTS_PER_M);
    fprintRTF("\n{\\pict\\jpegblip\\picw%ld\\pich%ld", w, h);
    fprintRTF("\\picwgoal%ld\\pichgoal%ld\n", width * 20, height * 20);
    if (scale != 1.0) {
        int iscale = (int) (scale * 100);

        fprintRTF("\\picscalex%d\\picscaley%d", iscale, iscale);
    }

    rewind(fp);
    PutHexFile(fp);
    fprintRTF("}\n");
    fclose(fp);
}

static void PutEmfFile(char *s, double scale, double baseline, int full_path)
{
    FILE *fp;
    char *emf;
    unsigned long RecordType;   /* Record type (always 0x00000001) */
    unsigned long RecordSize;   /* Size of the record in bytes */
    long BoundsLeft;            /* Left inclusive bounds */
    long BoundsRight;           /* Right inclusive bounds */
    long BoundsTop;             /* Top inclusive bounds */
    long BoundsBottom;          /* Bottom inclusive bounds */
    long FrameLeft;             /* Left side of inclusive picture frame */
    long FrameRight;            /* Right side of inclusive picture frame */
    long FrameTop;              /* Top side of inclusive picture frame */
    long FrameBottom;           /* Bottom side of inclusive picture frame */
    unsigned long Signature;    /* Signature ID (always 0x464D4520) */
    unsigned long w, h, width, height;

    if (full_path)
        emf = strdup(s);
    else
        emf = strdup_together(g_home_dir, s);
    diagnostics(1, "PutEmfFile <%s>", emf);
    fp = fopen(emf, "rb");
    free(emf);
    if (fp == NULL)
        return;

/* extract size information*/
    if (fread(&RecordType, 4, 1, fp) != 1)
        goto out;
    if (fread(&RecordSize, 4, 1, fp) != 1)
        goto out;
    if (fread(&BoundsLeft, 4, 1, fp) != 1)
        goto out;
    if (fread(&BoundsTop, 4, 1, fp) != 1)
        goto out;
    if (fread(&BoundsRight, 4, 1, fp) != 1)
        goto out;
    if (fread(&BoundsBottom, 4, 1, fp) != 1)
        goto out;
    if (fread(&FrameLeft, 4, 1, fp) != 1)
        goto out;
    if (fread(&FrameRight, 4, 1, fp) != 1)
        goto out;
    if (fread(&FrameTop, 4, 1, fp) != 1)
        goto out;
    if (fread(&FrameBottom, 4, 1, fp) != 1)
        goto out;
    if (fread(&Signature, 4, 1, fp) != 1)
        goto out;

    if (!g_little_endian) {
        RecordType = LETONL(RecordType);
        RecordSize = LETONL(RecordSize);
        BoundsLeft = LETONL(BoundsLeft);
        BoundsTop = LETONL(BoundsTop);
        BoundsRight = LETONL(BoundsRight);
        BoundsBottom = LETONL(BoundsBottom);
        FrameLeft = LETONL(FrameLeft);
        FrameRight = LETONL(FrameRight);
        FrameTop = LETONL(FrameTop);
        FrameBottom = LETONL(FrameBottom);
        Signature = LETONL(Signature);
    }

    if (RecordType != 1 || Signature != 0x464D4520)
        goto out;
    height = (unsigned long) (BoundsBottom - BoundsTop);
    width = (unsigned long) (BoundsRight - BoundsLeft);

    w = (unsigned long) ((100000.0 * width) / (20 * POINTS_PER_M));
    h = (unsigned long) ((100000.0 * height) / (20 * POINTS_PER_M));
    diagnostics(4, "width = %ld, height = %ld", width, height);
    fprintRTF("\n{\\pict\\emfblip\\picw%ld\\pich%ld", w, h);
    fprintRTF("\\picwgoal%ld\\pichgoal%ld\n", width * 20, height * 20);
    if (scale != 1.0) {
        int iscale = (int) (scale * 100);

        fprintRTF("\\picscalex%d\\picscaley%d", iscale, iscale);
    }

/* write file */
    rewind(fp);
    PutHexFile(fp);
    fprintRTF("}\n");
    fclose(fp);
    return;

  out:
    diagnostics(WARNING, "Problem with file %s --- not included", s);
    fclose(fp);
}

static void PutWmfFile(char *s, double scale, double baseline, int full_path)

/******************************************************************************
 purpose   : Insert WMF file (from g_home_dir) into RTF file
 ******************************************************************************/
{
    FILE *fp;
    char *wmf;
    unsigned long Key;          /* Magic number (always 0x9AC6CDD7) */
    unsigned short FileType;    /* Type of metafile (0=memory, 1=disk) */
    unsigned short HeaderSize;  /* Size of header in WORDS (always 9) */
    unsigned short Handle;      /* Metafile HANDLE number (always 0) */
    short Left;                 /* Left coordinate in twips */
    short Top;                  /* Top coordinate in twips */
    short Right;                /* Right coordinate in twips */
    short Bottom;               /* Bottom coordinate in twips */
    int width, height;
    unsigned long int magic_number = (unsigned long int) 0x9AC6CDD7;

    /* open the proper file */
    wmf = strdup_together(g_home_dir, s);
    diagnostics(1, "PutWmfFile <%s>", wmf);
    fp = fopen(wmf, "rb");
    free(wmf);
    if (fp == NULL)
        return;

    /* verify file is actually WMF and get size */
    if (fread(&Key, 4, 1, fp) != 1)
        goto out;
    if (!g_little_endian)
        Key = LETONL(Key);

    if (Key == magic_number) {  /* file is placeable metafile */
        if (fread(&Handle, 2, 1, fp) != 1)
            goto out;
        if (fread(&Left, 2, 1, fp) != 1)
            goto out;
        if (fread(&Top, 2, 1, fp) != 1)
            goto out;
        if (fread(&Right, 2, 1, fp) != 1)
            goto out;
        if (fread(&Bottom, 2, 1, fp) != 1)
            goto out;

        if (!g_little_endian) {
            Left = LETONS(Left);
            Top = LETONS(Top);
            Right = LETONS(Right);
            Bottom = LETONS(Bottom);
        }

        width = abs(Right - Left);
        height = abs(Top - Bottom);

    } else {                    /* file may be old wmf file with no size */

        rewind(fp);
        if (fread(&FileType, 2, 1, fp) != 1)
            goto out;
        if (fread(&HeaderSize, 2, 1, fp) != 1)
            goto out;

        if (!g_little_endian) {
            FileType = (unsigned short) LETONS(FileType);
            HeaderSize = (unsigned short) LETONS(HeaderSize);
        }

        if (FileType != 0 && FileType != 1)
            goto out;
        if (HeaderSize != 9)
            goto out;

        /* real wmf file ... just assume size */
        width = 200;
        height = 200;
    }

    diagnostics(4, "width = %d, height = %d", width, height);
    fprintRTF("\n{\\pict\\wmetafile1\\picw%d\\pich%d\n", width, height);
    if (scale != 1.0) {
        int iscale = (int) (scale * 100);

        fprintRTF("\\picscalex%d\\picscaley%d", iscale, iscale);
    }

    rewind(fp);
    PutHexFile(fp);
    fprintRTF("}\n");
    fclose(fp);
    return;

  out:
    diagnostics(WARNING, "Problem with file %s --- not included", s);
    fclose(fp);
}

static void PutPdfFile(char *s, double scale, double baseline, int full_path)
{
    char *png;

    diagnostics(2, "PutPdfFile filename = <%s>", s);

    png = pdf_to_png(s);
    scale *= 72.0 / g_dots_per_inch;
    if (png) {
        PutPngFile(png, scale, baseline, TRUE);
        my_unlink(png);
        free(png);
    }
}

static void PutEpsFile(char *s, double scale, double baseline, int full_path)
{
    char *png, *emf, *pict;

    diagnostics(2, "PutEpsFile filename = <%s>", s);

    if (1) {
        png = eps_to_png(s);
        scale *= 72.0 / g_dots_per_inch;
        if (png) {
            PutPngFile(png, scale, baseline, TRUE);
            my_unlink(png);
            free(png);
        }
    }

    if (0) {
        pict = eps_to_pict(s);
        if (pict) {
            PutPictFile(pict, scale, baseline, TRUE);
            my_unlink(pict);
            free(pict);
        }
    }

    if (0) {
        emf = eps_to_emf(s);
        if (emf) {
            PutEmfFile(emf, scale, baseline, TRUE);
            my_unlink(emf);
            free(emf);
        }
    }
}

static void PutTiffFile(char *s, double scale, double baseline, int full_path)

/******************************************************************************
 purpose   : Insert TIFF file (from g_home_dir) into RTF file as a PNG image
 ******************************************************************************/
{
    char *cmd, *tiff, *png, *tmp_png;
    size_t cmd_len;

    diagnostics(1, "filename = <%s>", s);
    png = strdup_new_extension(s, ".tiff", ".png");
    if (png == NULL) {
        png = strdup_new_extension(s, ".TIFF", ".png");
        if (png == NULL)
            return;
    }

    tmp_png = strdup_tmp_path(png);
    tiff = strdup_together(g_home_dir, s);

    cmd_len = strlen(tiff) + strlen(tmp_png) + 10;
    cmd = (char *) malloc(cmd_len);
    snprintf(cmd, cmd_len, "convert %s %s", tiff, tmp_png);
    diagnostics(2, "system graphics command = [%s]", cmd);
    system(cmd);

    PutPngFile(tmp_png, scale, baseline, TRUE);
    my_unlink(tmp_png);

    free(tmp_png);
    free(cmd);
    free(tiff);
    free(png);
}

static void PutGifFile(char *s, double scale, double baseline, int full_path)

/******************************************************************************
 purpose   : Insert GIF file (from g_home_dir) into RTF file as a PNG image
 ******************************************************************************/
{
    char *cmd, *gif, *png, *tmp_png;
    size_t cmd_len;

    diagnostics(1, "filename = <%s>", s);
    png = strdup_new_extension(s, ".gif", ".png");
    if (png == NULL) {
        png = strdup_new_extension(s, ".GIF", ".png");
        if (png == NULL)
            return;
    }

    tmp_png = strdup_tmp_path(png);
    gif = strdup_together(g_home_dir, s);

    cmd_len = strlen(gif) + strlen(tmp_png) + 10;
    cmd = (char *) malloc(cmd_len);
    snprintf(cmd, cmd_len, "convert %s %s", gif, tmp_png);
    diagnostics(2, "system graphics command = [%s]", cmd);
    system(cmd);

    PutPngFile(tmp_png, scale, baseline, TRUE);
    my_unlink(tmp_png);

    free(tmp_png);
    free(cmd);
    free(gif);
    free(png);
}

static int ReadLine(FILE * fp)

/****************************************************************************
purpose: reads up to and and including a line ending (CR, CRLF, or LF)
 ****************************************************************************/
{
    int thechar;

    while (1) {
        thechar = getc(fp);
        if (thechar == EOF) {
            fclose(fp);
            return 0;
        }
        if (thechar == 0x0a)
            return 1;           /* LF */
        if (thechar == 0x0d) {
            thechar = getc(fp);
            if (thechar == EOF) {
                fclose(fp);
                return 0;
            }
            if (thechar == 0x0d)
                return 1;       /* CR LF */
            ungetc(thechar, fp);    /* CR */
            return 1;
        }
    }
}

long GetBaseline(char *s, char *pre)

/****************************************************************************
purpose: reads a .pbm file to determine the baseline for an equation
		 the .pbm file should have dimensions of 1xheight
 ****************************************************************************/
{
    FILE *fp;
    int thechar;
    char *pbm;
    char magic[250];
    long baseline, width, height, items, top, bottom;

    /* baseline=0 if not an inline image */
    if ((strcmp(pre, "$") != 0) && (strcmp(pre, "\\begin{math}") != 0) && (strcmp(pre, "\\(") != 0))
        return 0;

    pbm = strdup_together(s, ".pbm");
    baseline = 4;

    diagnostics(4, "GetBaseline opening=<%s>", pbm);

    fp = fopen(pbm, "rb");
    if (fp == NULL) {
        free(pbm);
        return baseline;
    }

    items = fscanf(fp, "%2s", magic);   /* ensure that file begins with "P4" */
    if ((items != 1) || (strcmp(magic, "P4") != 0))
        goto Exit;

    items = fscanf(fp, " %s", magic);
    while ((items == 1) && (magic[0] == '#')) { /* skip any comment lines in pbm file */
        if (!ReadLine(fp))
            goto Exit;
        items = fscanf(fp, "%s", magic);
    }

    items = sscanf(magic, "%ld", &width);   /* make sure image width is 1 */
    if ((items != 1) || (width != 1))
        goto Exit;

    items = fscanf(fp, " %ld", &height);    /* read height */
    if (items != 1)
        goto Exit;

    diagnostics(4, "width=%ld height=%ld", width, height);

    if (!ReadLine(fp))
        goto Exit;              /* pixel map should start on next line */

    for (top = height; top > 0; top--) {    /* seek first black pixel (0x00) */
        thechar = getc(fp);
        if (thechar == EOF)
            goto Exit;
        if (thechar != 0)
            break;
    }

    for (bottom = top - 1; bottom > 0; bottom--) {  /* seek first black pixel (0x00) */
        thechar = getc(fp);
        if (thechar == EOF)
            goto Exit;
        if (thechar == 0)
            break;
    }

    baseline = (bottom + top) / 2;

    diagnostics(4, "top=%ld bottom=%ld baseline=%ld", top, bottom, baseline);

  Exit:
    free(pbm);
    fclose(fp);
    return baseline;
}

static char *get_latex2png_name()
{
#ifdef MSDOS
    return strdup("command.com /e:2048 /c latex2pn");
#else
    return strdup_together(g_script_path, "latex2png");
#endif
}

void PutLatexFile(char *s, double scale, char *pre)

/******************************************************************************
 purpose   : Convert LaTeX to Bitmap and insert in RTF file
 ******************************************************************************/
{
    char *png, *cmd, *l2p;
    int err, baseline, second_pass;
    size_t cmd_len;
    unsigned long width, height, rw, rh;
    unsigned long maxsize = (unsigned long) (32767.0 / 20.0);
    int resolution = g_dots_per_inch;   /* points per inch */

    diagnostics(4, "Entering PutLatexFile");

    png = strdup_together(s, ".png");
    l2p = get_latex2png_name();

    cmd_len = strlen(l2p) + strlen(s) + 25;
    if (g_home_dir)
        cmd_len += strlen(g_home_dir);

    cmd = (char *) malloc(cmd_len);

    do {
        second_pass = FALSE;    /* only needed if png is too large for Word */
        if (g_home_dir == NULL)
            snprintf(cmd, cmd_len, "%s -d %d %s", l2p, resolution, s);
        else
            snprintf(cmd, cmd_len, "%s -d %d -H \"%s\" %s", l2p, resolution, g_home_dir, s);

        diagnostics(2, "system graphics command = [%s]", cmd);
        err = system(cmd);
        if (err)
            break;

        GetPngSize(png, &width, &height);
        baseline = GetBaseline(s, pre);
        diagnostics(4, "png size height=%d baseline=%d width=%d", height, baseline, width);

        if ((width > maxsize && height != 0) || (height > maxsize && width != 0)) {
            second_pass = TRUE;
            rw = (unsigned long) ((resolution * maxsize) / width);
            rh = (unsigned long) ((resolution * maxsize) / height);
            resolution = rw < rh ? (int) rw : (int) rh;
        }
    } while (resolution > 10 && ((width > maxsize) || (height > maxsize)));

    if (err == 0)
        PutPngFile(png, scale * 72.0 / resolution, (double) baseline, TRUE);

    free(l2p);
    free(png);
    free(cmd);
}

char *upper_case_string(char *s)
{
    char *t, *x;

    if (!s)
        return NULL;

    t = strdup(s);
    x = t;

    while (*x) {
        if (islower(*x))
            *x = toupper(*x);
        x++;
    }

    return t;
}

char *exists_with_extension(char *s, char *ext)

/******************************************************************************
 purpose   : return s.ext or s.EXT if it exists otherwise return NULL
 ******************************************************************************/
{
    char *t, *x;
    FILE *fp;

    t = strdup_together(s, ext);
    fp = fopen(t, "r");
    diagnostics(4, "trying to open %s, result = %0x", t, fp);
    if (fp) {
        fclose(fp);
        return t;
    }
    free(t);

/* now try upper case version of ext */
    x = upper_case_string(ext);
    t = strdup_together(s, x);
    free(x);

    fp = fopen(t, "r");
    diagnostics(4, "trying to open %s, result = %0x", t, fp);
    if (fp) {
        fclose(fp);
        return t;
    }
    free(t);
    return NULL;
}

int has_extension(char *s, char *ext)

/******************************************************************************
 purpose   : return true if ext is at end of s (case insensitively)
 ******************************************************************************/
{
    char *t;

    t = s + strlen(s) - strlen(ext);

    if (strcasecmp(t, ext) == 0)
        return TRUE;

    return FALSE;
}

char *append_graphic_extension(char *s)
{
    char *t;

    if (has_extension(s, ".pict") ||
      has_extension(s, ".png") ||
      has_extension(s, ".gif") ||
      has_extension(s, ".emf") ||
      has_extension(s, ".wmf") ||
      has_extension(s, ".eps") ||
      has_extension(s, ".pdf") ||
      has_extension(s, ".ps") ||
      has_extension(s, ".tiff") || has_extension(s, ".tif") || has_extension(s, ".jpg") || has_extension(s, ".jpeg"))
        return strdup(s);

    t = exists_with_extension(s, ".png");
    if (t)
        return t;

    t = exists_with_extension(s, ".jpg");
    if (t)
        return t;

    t = exists_with_extension(s, ".jpeg");
    if (t)
        return t;

    t = exists_with_extension(s, ".tif");
    if (t)
        return t;

    t = exists_with_extension(s, ".tiff");
    if (t)
        return t;

    t = exists_with_extension(s, ".gif");
    if (t)
        return t;

    t = exists_with_extension(s, ".eps");
    if (t)
        return t;

    t = exists_with_extension(s, ".pdf");
    if (t)
        return t;

    t = exists_with_extension(s, ".ps");
    if (t)
        return t;

    t = exists_with_extension(s, ".pict");
    if (t)
        return t;

    t = exists_with_extension(s, ".emf");
    if (t)
        return t;

    t = exists_with_extension(s, ".wmf");
    if (t)
        return t;

    /* failed to find any file */
    return strdup(s);

}

void CmdGraphics(int code)

/*
\includegraphics[parameters]{filename}

where parameters is a comma-separated list of any of the following: 
bb=llx lly urx ury (bounding box),
width=h_length,
height=v_length,
angle=angle,
scale=factor,
clip=true/false,
draft=true/false.

code=0 => includegraphics
code=1 => epsffile
code=2 => epsfbox
code=3 => \BoxedSPSF
code=4 => psfig
*/
{
    char *options, *options2;
    char *filename, *fullpathname, *fullname;
    double scale = 1.0;
    double baseline = 0.0;
    double x;
    char *p;

    if (code == 0) {            /* could be \includegraphics*[0,0][5,5]{file.pict} */
        options = getBracketParam();
        options2 = getBracketParam();
        if (options2)
            free(options2);

        if (options) {          /* \includegraphics[scale=0.5]{file.png} */
            p = strstr(options, "scale");
            if (p) {
                p = strchr(p, '=');
                if (p && (sscanf(p + 1, "%lf", &x) == 1))
                    scale = x;
            }
            free(options);
        }
        filename = getBraceParam();
        diagnostics(1, "image scale = %g", scale);
    }

    if (code == 1) {            /* \epsffile{filename.eps} */
        filename = getBraceParam();
    }

    if (code == 2) {            /* \epsfbox[0 0 30 50]{filename.ps} */
        options = getBracketParam();
        if (options)
            free(options);
        filename = getBraceParam();
    }

    if (code == 3) {            /* \BoxedEPSF{filename [scaled nnn]} */
        char *s;

        filename = getBraceParam();
        s = strchr(filename, ' ');
        if (s)
            *s = '\0';
    }

    if (code == 4) {            /* \psfig{figure=filename,height=hhh,width=www} */
        char *s, *t;

        filename = getBraceParam();
        s = strstr(filename, "figure=");
        if (!s)
            return;
        s += strlen("figure=");
        t = strchr(s, ',');
        if (t)
            *t = '\0';
        t = strdup(s);
        free(filename);
        filename = t;
    }

    SetTexMode(MODE_HORIZONTAL);

    fullname = strdup_absolute_path(filename);
    fullpathname = append_graphic_extension(fullname);
    free(fullname);

    if (has_extension(fullpathname, ".pict"))
        PutPictFile(fullpathname, scale, baseline, TRUE);

    else if (has_extension(fullpathname, ".png"))
        PutPngFile(fullpathname, scale, baseline, TRUE);

    else if (has_extension(fullpathname, ".gif"))
        PutGifFile(fullpathname, scale, baseline, TRUE);

    else if (has_extension(fullpathname, ".emf"))
        PutEmfFile(fullpathname, scale, baseline, TRUE);

    else if (has_extension(fullpathname, ".wmf"))
        PutWmfFile(fullpathname, scale, baseline, TRUE);

    else if (has_extension(fullpathname, ".eps"))
        PutEpsFile(fullpathname, scale, baseline, TRUE);

    else if (has_extension(fullpathname, ".pdf"))
        PutPdfFile(fullpathname, scale, baseline, TRUE);

    else if (has_extension(fullpathname, ".ps"))
        PutEpsFile(fullpathname, scale, baseline, TRUE);

    else if (has_extension(fullpathname, ".tiff"))
        PutTiffFile(fullpathname, scale, baseline, TRUE);

    else if (has_extension(fullpathname, ".tif"))
        PutTiffFile(fullpathname, scale, baseline, TRUE);

    else if (has_extension(fullpathname, ".jpg"))
        PutJpegFile(fullpathname, scale, baseline, TRUE);

    else if (has_extension(fullpathname, ".jpeg"))
        PutJpegFile(fullpathname, scale, baseline, TRUE);

    else
        diagnostics(WARNING, "Conversion of '%s' not supported", filename);

    free(filename);
    free(fullpathname);
}

void CmdPicture(int code)

/******************************************************************************
  purpose: handle \begin{picture} ... \end{picture}
           by converting to png image and inserting
 ******************************************************************************/
{
    char *pre, *post, *picture;

    if (code & ON) {
        pre = strdup("\\begin{picture}");
        post = strdup("\\end{picture}");
        picture = getTexUntil(post, 0);
        WriteLatexAsBitmap(pre, picture, post);
        ConvertString(post);    /* to balance the \begin{picture} */
        free(pre);
        free(post);
        free(picture);
    }
}

void CmdMusic(int code)

/******************************************************************************
  purpose: Process \begin{music} ... \end{music} environment
 ******************************************************************************/
{
    char *contents;
    char endmusic[] = "\\end{music}";

    if (!(code & ON)) {
        diagnostics(4, "exiting CmdMusic");
        return;
    }

    diagnostics(4, "entering CmdMusic");
    contents = getTexUntil(endmusic, TRUE);
    CmdEndParagraph(0);
    CmdVspace(VSPACE_SMALL_SKIP);
    CmdIndent(INDENT_NONE);
    CmdStartParagraph(FIRST_PAR);
    WriteLatexAsBitmap("\\begin{music}", contents, endmusic);
    ConvertString(endmusic);
    CmdEndParagraph(0);
    CmdVspace(VSPACE_SMALL_SKIP);
    CmdIndent(INDENT_INHIBIT);
    free(contents);
}
