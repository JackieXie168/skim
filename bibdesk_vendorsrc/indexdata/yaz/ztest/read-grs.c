/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: read-grs.c,v 1.13 2005/06/25 15:46:09 adam Exp $
 */

/*
 * Little toy-thing to read a GRS-1 records from a file.
 */

#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>

#include <yaz/proto.h>
#include <yaz/log.h>

#define GRS_MAX_FIELDS 50

static Z_GenericRecord *read_grs1(FILE *f, ODR o)
{
    char line[512], *buf;
    int type, ivalue;
    char value[512];
    Z_GenericRecord *r = 0;

    for (;;)
    {
        Z_TaggedElement *t;
        Z_ElementData *c;

        while (fgets(buf = line, 512, f))
        {
            while (*buf && isspace(*(unsigned char *) buf))
                buf++;
            if (!*buf || *buf == '#')
                continue;
            break;
        }
        if (*buf == '}')
            return r;
        if (sscanf(buf, "(%d,%[^)])", &type, value) != 2)
        {
            yaz_log(YLOG_WARN, "Bad data in '%s'", buf);
            return 0;
        }
        if (!type && *value == '0')
            return r;
        if (!(buf = strchr(buf, ')')))
            return 0;
        buf++;
        while (*buf && isspace(*(unsigned char *) buf))
            buf++;
        if (!*buf)
            return 0;
        if (!r)
        {
            r = (Z_GenericRecord *)odr_malloc(o, sizeof(*r));
            r->elements = (Z_TaggedElement **)
                odr_malloc(o, sizeof(Z_TaggedElement*) * GRS_MAX_FIELDS);
            r->num_elements = 0;
        }
        r->elements[r->num_elements] = t = (Z_TaggedElement *)
            odr_malloc(o, sizeof(Z_TaggedElement));
        t->tagType = odr_intdup(o, type);
        t->tagValue = (Z_StringOrNumeric *)
            odr_malloc(o, sizeof(Z_StringOrNumeric));
        if ((ivalue = atoi(value)))
        {
            t->tagValue->which = Z_StringOrNumeric_numeric;
            t->tagValue->u.numeric = odr_intdup(o, ivalue);
        }
        else
        {
            t->tagValue->which = Z_StringOrNumeric_string;
            t->tagValue->u.string = (char *)odr_malloc(o, strlen(value)+1);
            strcpy(t->tagValue->u.string, value);
        }
        t->tagOccurrence = 0;
        t->metaData = 0;
        t->appliedVariant = 0;
        t->content = c = (Z_ElementData *)odr_malloc(o, sizeof(Z_ElementData));
        if (*buf == '{')
        {
            c->which = Z_ElementData_subtree;
            c->u.subtree = read_grs1(f, o);
        }
        else
        {
            c->which = Z_ElementData_string;
            buf[strlen(buf)-1] = '\0';
            c->u.string = odr_strdup(o, buf);
        }
        r->num_elements++;
    }
}

Z_GenericRecord *dummy_grs_record (int num, ODR o)
{
    FILE *f = fopen("dummy-grs", "r");
    char line[512];
    Z_GenericRecord *r = 0;
    int n;

    if (!f)
        return 0;
    while (fgets(line, 512, f))
        if (*line == '#' && sscanf(line, "#%d", &n) == 1 && n == num)
        {
            r = read_grs1(f, o);
            break;
        }
    fclose(f);
    return r;
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

