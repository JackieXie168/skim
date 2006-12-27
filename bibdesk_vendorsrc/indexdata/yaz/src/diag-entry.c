/*
 * Copyright (C) 1995-2006, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: diag-entry.c,v 1.3 2006/04/19 23:15:39 adam Exp $
 */

/**
 * \file diag-entry.c
 * \brief Diagnostic table lookup
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include "diag-entry.h"

const char *yaz_diag_to_str(struct yaz_diag_entry *tab, int code)
{
    int i;
    for (i=0; tab[i].msg; i++)
        if (tab[i].code == code)
            return tab[i].msg;
    return "Unknown error";
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

