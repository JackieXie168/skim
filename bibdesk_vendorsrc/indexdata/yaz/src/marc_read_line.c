/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: marc_read_line.c,v 1.3 2007/01/03 08:42:15 adam Exp $
 */

/**
 * \file marc_read_line.c
 * \brief Implements reading of MARC in line format
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#ifdef WIN32
#include <windows.h>
#endif

#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include <yaz/marcdisp.h>
#include <yaz/wrbuf.h>
#include <yaz/yaz-util.h>

int yaz_gets(int (*getbyte)(void *client_data),
             void (*ungetbyte)(int b, void *client_data),
             void *client_data,
             char *buf, size_t len)
{
    size_t sz = 0;
    int ch = getbyte(client_data);
    while (ch != '\0' && ch != '\r' && ch != '\n')
    {
        if (sz < len-1)
            buf[sz++] = ch;
        ch = getbyte(client_data);
    }
    if (ch == '\r')
    {
        ch = getbyte(client_data);
        if (ch != '\n' && ch != '\0')
            ungetbyte(ch, client_data);
    }
    else if (ch == '\n')
    {
        ch = getbyte(client_data);
        if (ch != '\r' && ch != '\0')
            ungetbyte(ch, client_data);
    }
    buf[sz] = '\0';
    if (sz)
        return 1;
    return 0;
}
    
int yaz_marc_read_line(yaz_marc_t mt,
                       int (*getbyte)(void *client_data),
                       void (*ungetbyte)(int b, void *client_data),
                       void *client_data)
{
    int indicator_length;
    int identifier_length;
    int base_address;
    int length_data_entry;
    int length_starting;
    int length_implementation;
    int marker_ch = 0;
    int marker_skip = 0;
    int header_created = 0;
    char line[4096];

    yaz_marc_reset(mt);

    while (yaz_gets(getbyte, ungetbyte, client_data, line, sizeof(line)))
    {
        int val;
        size_t line_len = strlen(line);
        /* see if have leader lines of the form:
           00366nam  22001698a 4500
        */
        if (line_len == 0)       /* empty line indicates end of record */
        {
            if (header_created)
                break;
        }
        else if (line[0] == '$') /* indicates beginning/end of record */
        {
            if (header_created)
                break;
        }
        else if (line[0] == '(') /* annotation, skip it */
            ;
        else if (line_len == 24 && atoi_n_check(line, 5, &val) && val >= 24)
        {
            if (header_created)
                break;
            yaz_marc_set_leader(mt, line,
                                &indicator_length,
                                &identifier_length,
                                &base_address,
                                &length_data_entry,
                                &length_starting,
                                &length_implementation);
            header_created = 1;
        }
        else if (line_len > 5 && memcmp(line, "    ", 4) == 0)
        {  /* continuation line */
            ;
        }
        else if (line_len > 5 && line[3] == ' ')
        {
            char tag[4];
            char *datafield_start = line+6;
            marker_ch = 0;
            marker_skip = 0;

            memcpy(tag, line, 3);
            tag[3] = '\0';
            if (line_len >= 8) /* control - or datafield ? */
            {
                if (*datafield_start == ' ')
                    datafield_start++;  /* skip blank after indicator */

                if (strchr("$_*", *datafield_start))
                {
                    marker_ch = *datafield_start;
                    if (datafield_start[2] == ' ')
                        marker_skip = 1; /* subfields has blank before data */
                }
            }
            if (!header_created)
            {
                const char *leader = "01000cam  2200265 i 4500";

                yaz_marc_set_leader(mt, leader,
                                    &indicator_length,
                                    &identifier_length,
                                    &base_address,
                                    &length_data_entry,
                                    &length_starting,
                                    &length_implementation);
                header_created = 1;
            }

            if (marker_ch == 0)
            {   /* control field */
                yaz_marc_add_controlfield(mt, tag, line+4, strlen(line+4));
            }
            else
            {   /* data field */
                const char *indicator = line+4;
                int indicator_len = 2;
                char *cp = datafield_start;

                yaz_marc_add_datafield(mt, tag, indicator, indicator_len);
                for (;;)
                {
                    char *next;
                    size_t len;
                    
                    assert(cp[0] == marker_ch);
                    cp++;
                    next = cp;
                    while ((next = strchr(next, marker_ch)))
                    {
                        if ((next[1] >= 'A' && next[1] <= 'Z')
                            ||(next[1] >= 'a' && next[1] <= 'z'))
                        {
                            if (!marker_skip)
                                break;
                            else if (next[2] == ' ')
                                break;
                        }
                        next++;
                    }
                    len = strlen(cp);
                    if (next)
                        len = next - cp - marker_skip;

                    if (marker_skip)
                    {
                        /* remove ' ' after subfield marker */
                        char *cp_blank = strchr(cp, ' ');
                        if (cp_blank)
                        {
                            len--;
                            while (cp_blank != cp)
                            {
                                cp_blank[0] = cp_blank[-1];
                                cp_blank--;
                            }
                            cp++;
                        }
                    }
                    assert(len >= 0);
                    assert(len < 399);
                    yaz_marc_add_subfield(mt, cp, len);
                    if (!next)
                        break;
                    cp = next;
                }
            }
        }
    }
    if (!header_created)
        return -1;
    return 0;
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

