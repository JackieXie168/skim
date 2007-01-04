/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: admin.h,v 1.9 2005/06/25 15:46:01 adam Exp $
 */

int cmd_adm_reindex(const char* arg);
int cmd_adm_truncate(const char* arg);
int cmd_adm_create(const char* arg);
int cmd_adm_drop(const char* arg);
int cmd_adm_import(const char* arg);
int cmd_adm_refresh(const char* arg);
int cmd_adm_commit(const char* arg);
int cmd_adm_shutdown(const char* arg);
int cmd_adm_startup(const char* arg);

int send_apdu(Z_APDU *a);
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

