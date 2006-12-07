
/* cfg.c - Read config files and provide lookup routines

Copyright (C) 1995-2002 The Free Software Foundation

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
    1995-1997 Ralf Schlatterbeck
    1998-2000 Georg Lehner
    2001-2002 Scott Prahl

 * LEG200698 I would have prefered to make the reading of the language file
 * separate, since the language is known some steps after reading the
 * configuration files. Since the search functions rely on the index into
 * configinfo this is not trivial. So I reread the language file to the array
 * at the moment the name is known.

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <ctype.h>

#include "main.h"
#include "convert.h"
#include "funct1.h"
#include "cfg.h"
#include "util.h"

typedef struct ConfigInfoT {
    char *filename;
    ConfigEntryT **config_info;
    size_t config_info_size;
    bool remove_leading_backslash;
} ConfigInfoT;

static ConfigInfoT configinfo[] = {
    {"direct.cfg", NULL, 0, FALSE},
    {"fonts.cfg", NULL, 0, FALSE},
    {"ignore.cfg", NULL, 0, FALSE},
    {"style.cfg", NULL, 0, FALSE},
    {"english.cfg", NULL, 0, FALSE},
};

#define CONFIG_SIZE (sizeof(configinfo) / sizeof(ConfigInfoT))
#define BUFFER_INCREMENT 1024

char *ReadUptoMatch(FILE * infile, const char *scanchars);

static int cfg_compare(ConfigEntryT ** el1, ConfigEntryT ** el2)

/****************************************************************************
 * purpose:  compare-function for bsearch
 * params:   el1, el2: Config Entries to be compared
 ****************************************************************************/
{
    return strcmp((*el1)->TexCommand, (*el2)->TexCommand);
}

static FILE *try_path(const char *path, const char *file)

/****************************************************************************
 * purpose:  append path to .cfg file name and open
             return NULL upon failure,
             return filepointer otherwise
 ****************************************************************************/
{
    char *both;
    FILE *fp = NULL;
    size_t lastchar;

    if (path == NULL || file == NULL)
        return NULL;

    diagnostics(4, "trying path=<%s> file=<%s>", path, file);

    lastchar = strlen(path);

    both = malloc(strlen(path) + strlen(file) + 2);
    if (both == NULL)
        diagnostics(ERROR, "Could not allocate memory for both strings.");

    strcpy(both, path);

    /* fix path ending if needed */
    if (both[lastchar] != PATHSEP) {
        both[lastchar] = PATHSEP;
        both[lastchar + 1] = '\0';
    }

    strcat(both, file);
    fp = fopen(both, "r");
    free(both);
    return fp;
}

void *open_cfg(const char *name, int quit_on_error)

/****************************************************************************
purpose: open config by trying multiple paths
 ****************************************************************************/
{
    char *env_path, *p, *p1;
    char *lib_path;
    FILE *fp;

    diagnostics(3, "Open file in cfg directories <%s>", name);

/* try path specified on the line */
    fp = try_path(g_config_path, name);
    if (fp)
        return fp;

/* try the environment variable RTFPATH */
    p = getenv("RTFPATH");
    if (p) {
        env_path = strdup(p);   /* create a copy to work with */
        p = env_path;
        while (p) {
            p1 = strchr(p, ENVSEP);
            if (p1)
                *p1 = '\0';

            fp = try_path(p, name);
            if (fp) {
                free(env_path);
                return fp;
            }

            p = (p1) ? p1 + 1 : NULL;
        }
        free(env_path);
    }

/* last resort.  try CFGDIR */
    lib_path = strdup(CFGDIR);
    if (lib_path) {
        p = lib_path;
        while (p) {
            p1 = strchr(p, ENVSEP);
            if (p1)
                *p1 = '\0';

            fp = try_path(p, name);
            if (fp) {
                free(lib_path);
                return fp;
            }

            p = (p1) ? p1 + 1 : NULL;
        }
        free(lib_path);
    }

/* failed ... give some feedback */
    if (quit_on_error) {
        diagnostics(WARNING, "Cannot open the latex2rtf .cfg files");
        diagnostics(WARNING, "Locate the directory containing the .cfg files and");
        diagnostics(WARNING, "   (1) define the environment variable RTFPATH, *or*");
        diagnostics(WARNING, "   (2) use command line path option \"-P /path/to/cfg/file\", *or*");
        diagnostics(WARNING, "   (3) recompile latex2rtf with CFGDIR defined properly");
        diagnostics(WARNING, "Current RTFPATH: %s", getenv("RTFPATH"));
        diagnostics(WARNING, "Current  CFGDIR: %s", CFGDIR);
        diagnostics(ERROR, " Giving up.  Please don't hate me.");
    }
    return NULL;
}

static size_t read_cfg(FILE * cfgfile, ConfigEntryT *** pointer_array, bool do_remove_backslash)

/****************************************************************************
 * purpose: Read config file and provide sorted lookup table
 ****************************************************************************/
{
    size_t bufindex = 0, bufsize = 0;
    char *line, *cmdend;

    if (*pointer_array == NULL) {
        *pointer_array = malloc(BUFFER_INCREMENT * sizeof(char *));
        bufsize = BUFFER_INCREMENT;
        if (*pointer_array == NULL)
            diagnostics(ERROR, "Cannot allocate memory for pointer list");
    }

    while ((line = ReadUptoMatch(cfgfile, "\n")) != NULL) {

        /* skip newline */
        getc(cfgfile);

        /* Skip leading white space */
        while (isspace((unsigned char) *line))
            line++;

        /* Skip comment line */
        if (*line == '#')
            continue;

        /* Skip blank line */
        if (*line == '\0')
            continue;

        /* Find period that terminates command */
        cmdend = strrchr(line, '.');
        if (cmdend == NULL)
            diagnostics(ERROR, "Bad config file, missing final period\nBad line is \"%s\"", line);

        /* Replace period with NULL */
        *cmdend = '\0';

        /* Skip backslash if specified */
        if (do_remove_backslash) {
            if (*line != '\\')
                diagnostics(ERROR, "Bad config file, missing initial'\\'\nBad line is\"%s\"", line);
            else
                line++;
        }

        /* resize buffer if needed */
        if (bufindex >= bufsize) {
            bufsize += BUFFER_INCREMENT;
            *pointer_array = realloc(*pointer_array, bufsize * sizeof(char *));
            if (*pointer_array == NULL)
                diagnostics(ERROR, "Cannot allocate memory for pointer list");
        }

        /* find start of definition */
        line = strdup(line);
        cmdend = strchr(line, ',');
        if (cmdend == NULL)
            diagnostics(ERROR, "Bad config file, missing ',' between elements\nBad line is\"%s\"", line);

        /* terminate command */
        *cmdend = '\0';

        (*pointer_array)[bufindex] = malloc(sizeof(ConfigEntryT));

        if ((*pointer_array)[bufindex] == NULL)
            diagnostics(ERROR, "Cannot allocate memory for config entry");

        (*pointer_array)[bufindex]->TexCommand = line;
        (*pointer_array)[bufindex]->RtfCommand = cmdend + 1;
        bufindex++;
    }

    qsort(*pointer_array, bufindex, sizeof(**pointer_array)
      , (fptr) cfg_compare);

    return bufindex;
}

void ReadCfg(void)

/****************************************************************************
 * purpose: opens config-files & reads them
 * globals: Direct-, Font- IgnoreArray[Size/Root]
 ****************************************************************************/
{
    size_t i;
    FILE *fp;
    char *fname;

    for (i = 0; i < CONFIG_SIZE; i++) {
        fname = configinfo[i].filename;
        fp = (FILE *) open_cfg(fname, TRUE);
        diagnostics(4, "reading config file %s", fname);

        configinfo[i].config_info_size = read_cfg(fp, &(configinfo[i].config_info)
          , configinfo[i].remove_leading_backslash);
        (void) fclose(fp);
    }
}

static ConfigEntryT **search_rtf(const char *theTexCommand, int WhichCfg)

/****************************************************************************
 * purpose:  search theTexCommand in specified config data and return
 *           pointer to the data
 ****************************************************************************/
{
    ConfigEntryT compare_item;
    ConfigEntryT *compare_ptr;

    compare_item.TexCommand = theTexCommand;
    compare_item.RtfCommand = "";
    compare_ptr = &compare_item;

    assert(WhichCfg >= 0 && (size_t) WhichCfg < CONFIG_SIZE);
    assert(configinfo[WhichCfg].config_info != NULL);

    return (ConfigEntryT **) bsearch
      (&compare_ptr, configinfo[WhichCfg].config_info, configinfo[WhichCfg].config_info_size, sizeof(compare_ptr)
      , (fptr) cfg_compare);
}

int SearchRtfIndex(const char *theTexCommand, int WhichCfg)

/****************************************************************************
 * purpose:  search theTexCommand in a specified config data and return
 *           index
 ****************************************************************************/
{
    ConfigEntryT **help = search_rtf(theTexCommand, WhichCfg);

    if (help == NULL) {
        return 0;
    }
    /* LEG210698*** subtraction of two ConfigEntryT pointers */
    return help - configinfo[WhichCfg].config_info;
}

char *SearchRtfCmd(const char *theTexCommand, int WhichCfg)

/****************************************************************************
 * purpose:  search theTexCommand in a specified config data and return
 *           pointer to the data
 ****************************************************************************/
{
    ConfigEntryT **help;

    help = search_rtf(theTexCommand, WhichCfg);

    if (help == NULL)
        return NULL;
    else
        return (char *) (*help)->RtfCommand;
}

ConfigEntryT **CfgStartIterate(int WhichCfg)

/****************************************************************************
 * purpose:  Start iterating of configuration data
 ****************************************************************************/
{
    return NULL;
}

ConfigEntryT **CfgNext(int WhichCfg, ConfigEntryT ** last)

/****************************************************************************
 * purpose:  Get the next entry from specified configuration data
 ****************************************************************************/
{
    if (last == NULL) {
        return (ConfigEntryT **) configinfo[WhichCfg].config_info;
    }
    last++;
    if (last > (ConfigEntryT **) configinfo[WhichCfg].config_info + configinfo[WhichCfg].config_info_size - 1) {
        return NULL;
    }
    return last;
}

/****************************************************************************
 * opens and reads the language configuration file named in lang

Opens language file & builds a search tree for the translation of
"Hardcoded" latex headings like "Part", "References", ...
The file format is:
LATEXTOKEN,Translation.

 ****************************************************************************/
void ReadLanguage(char *lang)
{
    FILE *fp;
    char *langfn;

    langfn = malloc(strlen(lang) + strlen(".cfg") + 1);
    if (langfn == NULL)
        diagnostics(ERROR, "Could not allocate memory for language filename.");

    strcpy(langfn, lang);
    strcat(langfn, ".cfg");

    fp = (FILE *) open_cfg(langfn, TRUE);
    free(langfn);

    configinfo[LANGUAGE_A].config_info_size
      = read_cfg(fp, &(configinfo[LANGUAGE_A].config_info), configinfo[LANGUAGE_A].remove_leading_backslash);

    (void) fclose(fp);
}

/****************************************************************************
 purpose : returns a pointer to the Printout name of a Heading, since
           this is read from a language file it provides translation
           capability.
 params  : name, name of heading.
 ****************************************************************************/
void ConvertBabelName(char *name)
{
    char *s = SearchRtfCmd(name, LANGUAGE_A);

    if (s != NULL)
        ConvertString(s);
}

static char *buffer = NULL;
static size_t bufsize = 0;

#define CR (char) 0x0d
#define LF (char) 0x0a

/*
 * This function assumes there are no '\0' characters in the input.
 * if there are any, they are ignored.
 */
char *ReadUptoMatch(FILE * infile, const char *scanchars)
{
    size_t bufindex = 0;
    int c;

    if (feof(infile) != 0)
        return NULL;

    if (buffer == NULL) {
        buffer = malloc(BUFFER_INCREMENT * sizeof(char));
        if (buffer == NULL)
            diagnostics(ERROR, "Cannot allocate memory for input buffer");
        bufsize = BUFFER_INCREMENT;
    }

    while ((c = getc(infile)) != EOF) {

        if (c == CR || c == LF)
            c = '\n';

        if (strchr(scanchars, c))
            break;

        if (c == (int) '\0')
            continue;

        buffer[bufindex++] = (char) c;
        if (bufindex >= bufsize) {
            bufsize += BUFFER_INCREMENT;
            buffer = realloc(buffer, bufsize);
            if (buffer == NULL)
                diagnostics(ERROR, "Cannot allocate memory for input buffer");
        }
    }
    buffer[bufindex] = '\0';
    if (c != EOF)
        ungetc(c, infile);

    return buffer;
}
