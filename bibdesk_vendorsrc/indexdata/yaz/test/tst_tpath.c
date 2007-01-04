/*
 * Copyright (C) 2005-2006, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: tst_tpath.c,v 1.2 2006/10/11 08:43:22 adam Exp $
 *
 */
#include <yaz/tpath.h>
#include <yaz/test.h>
#include <string.h>
#include <yaz/log.h>

#if HAVE_CONFIG_H
#include <config.h>
#endif


static void tst_tpath(void)
{
    char fullpath[FILENAME_MAX];

    YAZ_CHECK(!yaz_filepath_resolve("etc", 0, 0, fullpath));
    YAZ_CHECK(!yaz_filepath_resolve("etc", "", 0, fullpath)); /* bug #606 */
    YAZ_CHECK(!yaz_filepath_resolve("etc", ".", 0, fullpath));
    YAZ_CHECK(!yaz_filepath_resolve("does_not_exist", "", 0, fullpath));
    YAZ_CHECK(!yaz_filepath_resolve("does_not_exist", ".", 0, fullpath));
    YAZ_CHECK(yaz_filepath_resolve("tst_tpath", 0, 0, fullpath));

    YAZ_CHECK(!yaz_filepath_resolve("tst_tpath", "", 0, fullpath));
    YAZ_CHECK(yaz_filepath_resolve("tst_tpath", ".", 0, fullpath));

    YAZ_CHECK(!yaz_filepath_resolve("tst_tpath", "unknown_dir", 0, fullpath));
    YAZ_CHECK(yaz_filepath_resolve("tst_tpath", "unknown_dir:.", 0, fullpath));
    YAZ_CHECK(!yaz_filepath_resolve("tst_tpath", "unknown_dir:", 0, fullpath));
    YAZ_CHECK(!yaz_filepath_resolve("tst_tpath", "unknown_dir:c:", 0, fullpath));
    YAZ_CHECK(!yaz_filepath_resolve("tst_tpath", "unknown_dir:c:\\other", 0, fullpath));

}

int main(int argc, char **argv)
{
    YAZ_CHECK_INIT(argc, argv);
    tst_tpath();
    YAZ_CHECK_TERM;
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

