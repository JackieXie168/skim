/*
 * Copyright (C) 1995-2006, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: marc_read_iso2709.c,v 1.1 2006/12/15 12:37:18 adam Exp $
 */

/**
 * \file marc_read_iso2709.c
 * \brief Implements reading of MARC as ISO2709
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#ifdef WIN32
#include <windows.h>
#endif

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <yaz/marcdisp.h>
#include <yaz/wrbuf.h>
#include <yaz/yaz-util.h>

int yaz_marc_read_iso2709(yaz_marc_t mt, const char *buf, int bsize)
{
    int entry_p;
    int record_length;
    int indicator_length;
    int identifier_length;
    int end_of_directory;
    int base_address;
    int length_data_entry;
    int length_starting;
    int length_implementation;

    yaz_marc_reset(mt);

    record_length = atoi_n (buf, 5);
    if (record_length < 25)
    {
        yaz_marc_cprintf(mt, "Record length %d < 24", record_length);
        return -1;
    }
    /* ballout if bsize is known and record_length is less than that */
    if (bsize != -1 && record_length > bsize)
    {
        yaz_marc_cprintf(mt, "Record appears to be larger than buffer %d < %d",
                         record_length, bsize);
        return -1;
    }
    if (yaz_marc_get_debug(mt))
        yaz_marc_cprintf(mt, "Record length         %5d", record_length);

    yaz_marc_set_leader(mt, buf,
                        &indicator_length,
                        &identifier_length,
                        &base_address,
                        &length_data_entry,
                        &length_starting,
                        &length_implementation);

    /* First pass. determine length of directory & base of data */
    for (entry_p = 24; buf[entry_p] != ISO2709_FS; )
    {
        /* length of directory entry */
        int l = 3 + length_data_entry + length_starting;
        if (entry_p + l >= record_length)
        {
            yaz_marc_cprintf(mt, "Directory offset %d: end of record."
                             " Missing FS char", entry_p);
            return -1;
        }
        if (yaz_marc_get_debug(mt))
        {
            yaz_marc_cprintf(mt, "Directory offset %d: Tag %.3s",
                             entry_p, buf+entry_p);
        }
        /* Check for digits in length info */
        while (--l >= 3)
            if (!isdigit(*(const unsigned char *) (buf + entry_p+l)))
                break;
        if (l >= 3)
        {
            /* Not all digits, so stop directory scan */
            yaz_marc_cprintf(mt, "Directory offset %d: Bad value for data"
                             " length and/or length starting", entry_p);
            break;
        }
        entry_p += 3 + length_data_entry + length_starting;
    }
    end_of_directory = entry_p;
    if (base_address != entry_p+1)
    {
        yaz_marc_cprintf(mt, "Base address not at end of directory,"
                         " base %d, end %d", base_address, entry_p+1);
    }

    /* Second pass. parse control - and datafields */
    for (entry_p = 24; entry_p != end_of_directory; )
    {
        int data_length;
        int data_offset;
        int end_offset;
        int i;
        char tag[4];
        int identifier_flag = 0;
        int entry_p0 = entry_p;

        memcpy (tag, buf+entry_p, 3);
        entry_p += 3;
        tag[3] = '\0';
        data_length = atoi_n(buf+entry_p, length_data_entry);
        entry_p += length_data_entry;
        data_offset = atoi_n(buf+entry_p, length_starting);
        entry_p += length_starting;
        i = data_offset + base_address;
        end_offset = i+data_length-1;

        if (data_length <= 0 || data_offset < 0)
            break;
        
        if (yaz_marc_get_debug(mt))
        {
            yaz_marc_cprintf(mt, "Tag: %s. Directory offset %d: data-length %d,"
                             " data-offset %d",
                             tag, entry_p0, data_length, data_offset);
        }
        if (end_offset >= record_length)
        {
            yaz_marc_cprintf(mt, "Directory offset %d: Data out of bounds %d >= %d",
                             entry_p0, end_offset, record_length);
            break;
        }
        
        if (memcmp (tag, "00", 2))
            identifier_flag = 1;  /* if not 00X assume subfields */
        else if (indicator_length < 4 && indicator_length > 0)
        {
            /* Danmarc 00X have subfields */
            if (buf[i + indicator_length] == ISO2709_IDFS)
                identifier_flag = 1;
            else if (buf[i + indicator_length + 1] == ISO2709_IDFS)
                identifier_flag = 2;
        }

        if (identifier_flag)
        {
            /* datafield */
            i += identifier_flag-1;
            yaz_marc_add_datafield(mt, tag, buf+i, indicator_length);
            i += indicator_length;

            while (i < end_offset &&
                    buf[i] != ISO2709_RS && buf[i] != ISO2709_FS)
            {
                int code_offset = i+1;

                i ++;
                while (i < end_offset &&
                        buf[i] != ISO2709_RS && buf[i] != ISO2709_IDFS &&
                       buf[i] != ISO2709_FS)
                    i++;
                yaz_marc_add_subfield(mt, buf+code_offset, i - code_offset);
            }
        }
        else
        {
            /* controlfield */
            int i0 = i;
            while (i < end_offset && 
                buf[i] != ISO2709_RS && buf[i] != ISO2709_FS)
                i++;
            yaz_marc_add_controlfield(mt, tag, buf+i0, i-i0);
        }
        if (i < end_offset)
        {
            yaz_marc_cprintf(mt, "Separator but not at end of field length=%d",
                    data_length);
        }
        if (buf[i] != ISO2709_RS && buf[i] != ISO2709_FS)
        {
            yaz_marc_cprintf(mt, "No separator at end of field length=%d",
                    data_length);
        }
    }
    return record_length;
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

