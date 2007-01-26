/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: diag-entry.h,v 1.4 2007/01/03 08:42:15 adam Exp $
 */

/**
 * \file diag-entry.h
 * \brief Diagnostic table lookup header
 */

struct yaz_diag_entry {
    int code;
    char *msg;
};

const char *yaz_diag_to_str(struct yaz_diag_entry *tab, int code);
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

