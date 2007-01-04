/* $Id: zoom-bug-641.c,v 1.1 2006/09/19 21:15:01 adam Exp $  */

/** \file zoom-bug641.c
    \brief Program to illustrate bug 641
*/

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <yaz/zoom.h>
#include <yaz/xmalloc.h>

#ifdef WIN32
#error Unix only
#endif

int main(int argc, char **argv)
{
    ZOOM_connection z;
    int i, error;
    const char *errmsg, *addinfo;

    if (argc < 3) {
        fprintf(stderr, "Usage:\n%s <target> <file> [<file> ...]\n", argv[0]);
        fprintf(stderr, " eg.  bagel.indexdata.dk/gils foo.xml bar.xml\n");
        return 1;
    }

    z = ZOOM_connection_create(0);

    for (i = 2; i < argc; i++) {
        char *buf, *fn = argv[i];
        struct stat statbuf;
        size_t size, offset = 0;
        int fd, n;

        ZOOM_connection_connect(z, argv[1], 0);
        if ((error = ZOOM_connection_error(z, &errmsg, &addinfo))) {
            fprintf(stderr, "Error: %s (%d) %s\n", errmsg, error, addinfo);
            return 2;
        }

        if (stat(fn, &statbuf) < 0 ||
            (fd = open(fn, O_RDONLY)) < 0) {
            perror(fn);
            return 3;
        }
        size = statbuf.st_size;
        printf("size=%lu\n", (unsigned long) size);
        buf = xmalloc(size+1);
        while ((n = read(fd, &buf[offset], size)) < size) {
            if (n < 0) {
                perror("read");
                return 4;
            }
            size -= n;
            offset += n;
        }
        close(fd);
        buf[size] = 0;

        {
            ZOOM_package pkg = ZOOM_connection_package(z, 0);
            ZOOM_package_option_set(pkg, "action", "specialUpdate");
            ZOOM_package_option_set(pkg, "record", buf);
            ZOOM_package_send(pkg, "update");
            if ((error = ZOOM_connection_error(z, &errmsg, &addinfo))) {
                printf("file '%s': error %d (%s) %s\n",
                       fn, error, errmsg, addinfo);
            } else {
                printf("file '%s': ok\n", fn);
            }
        }

        xfree(buf);
        if (i < argc-1) sleep(2);
    }

    ZOOM_connection_destroy(z);
    return 0;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */
