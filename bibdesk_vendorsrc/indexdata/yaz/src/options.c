/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: options.c,v 1.4 2005/06/25 15:46:04 adam Exp $
 */
/**
 * \file options.c
 * \brief Implements command line options parsing
 */
#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdlib.h>

#include <yaz/options.h>

static int arg_no = 1;
static int arg_off = 0;

int options (const char *desc, char **argv, int argc, char **arg)
{
    int ch, i = 0;
    
    if (arg_no >= argc)
        return -2;
    if (arg_off == 0)
    {
        while (argv[arg_no][0] == '\0')
        {
            arg_no++;
            if (arg_no >= argc)
                return -2;
        }
        if (argv[arg_no][0] != '-' || argv[arg_no][1] == '\0')
        {
            *arg = argv[arg_no++];
            return 0;
        }
        arg_off++;
    }
    ch = argv[arg_no][arg_off++];
    while (desc[i])
    {
        int desc_char = desc[i++];
        int type = 0;
        if (desc[i] == ':')
        {       /* string argument */
            type = desc[i++];
        }
        if (desc_char == ch)
        { /* option with argument */
            if (type)
            {
                if (argv[arg_no][arg_off])
                {
                    *arg = argv[arg_no]+arg_off;
                    arg_no++;
                    arg_off =  0;
                }
                else
                {
                    arg_no++;
                    arg_off = 0;
                    if (arg_no < argc)
                        *arg = argv[arg_no++];
                    else
                        *arg = "";
                }
            }
            else /* option with no argument */
            {
                if (argv[arg_no][arg_off])
                    arg_off++;
                else
                {
                    arg_off = 0;
                    arg_no++;
                }
            }
            return ch;
        }               
    }
    *arg = argv[arg_no]+arg_off-1;
    arg_no = arg_no + 1;
    arg_off = 0;
    return -1;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

