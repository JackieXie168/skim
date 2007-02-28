/* 
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: bertorture.c,v 1.5 2007/01/03 08:42:13 adam Exp $
 */

#include <signal.h>
#if HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#if HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif
#include <fcntl.h>
#if HAVE_UNISTD_H
#include <unistd.h>
#endif

#include <stdlib.h>
#include <stdio.h>

#include <yaz/yaz-util.h>
#include <yaz/proto.h>
#include <yaz/comstack.h>

#define PACKET_SIZE 64

static int stop = 0;

static int send_packet(const char *host)
{
    char buf[PACKET_SIZE];
    int i;

    void *add;

    COMSTACK cs = cs_create_host(host, 1, &add);

    if (!cs)
        return -1;

    if (cs_connect(cs, add) < 0)
        return -1;

    for (i = 0; i<sizeof(buf); i++)
        buf[i] = 233;
#if 0
        buf[i] = rand() & 0xff;
#endif
    cs_put(cs, buf, sizeof(buf));

    cs_close(cs);
    return 0;
}

static void test_file(const char *fname)
{
    Z_GDU *req;
    ODR odr = odr_createmem(ODR_DECODE);
    char buf[PACKET_SIZE];
    int off = 0;
    int fd =open(fname, O_RDONLY, 0666);
    if (fd == -1)
    {
        yaz_log(LOG_ERRNO|LOG_FATAL, "open %s", fname);
        exit (1);
    }
    while (off < sizeof(buf))
    {
        ssize_t rd;
        rd = read(fd, buf+off, sizeof(buf)-off);
        if (rd == -1) {
            yaz_log(LOG_ERRNO|LOG_FATAL, "read %s", fname);
            exit (1);
        }
        if (rd == 0)
            break;
        off += rd;
    }
    if (close(fd) == -1)
    {
        yaz_log(LOG_ERRNO|LOG_FATAL, "close %s", fname);
        exit (1);
    }
    odr_setbuf(odr, buf, off, 0);
    z_GDU(odr, &req, 0, 0);

    odr_destroy(odr);
}

static void test_random(int run, const char *fname, const char *fname2,
                        int *estat)
{
    FILE *dumpfile = 0;
    char buf[PACKET_SIZE];
    int i, j;

    if (fname2)
    {
        if (!strcmp(fname2, "-"))
            dumpfile = stdout;
        else
            dumpfile = fopen(fname2, "w");
    }

    for (i = 0; i<sizeof(buf); i++)
        buf[i] = rand() & 0xff;

    for (j = 0; j<sizeof(buf)-1; j++)
    {
        Z_GDU *req;
        char *mbuf;
        ODR odr;

        nmem_init();
        odr = odr_createmem(ODR_DECODE);
        if (fname)
        {
            int off = 0;
            int fd =open(fname, O_TRUNC|O_CREAT|O_WRONLY, 0666);
            if (fd == -1)
            {
                yaz_log(LOG_ERRNO|LOG_FATAL, "open %s", fname);
                exit (1);
            }
            while (sizeof(buf)-j-off > 0)
            {
                ssize_t wrote;
                wrote = write(fd, buf+off+j, sizeof(buf)-j-off);
                if (wrote <= 0) {
                    yaz_log(LOG_ERRNO|LOG_FATAL, "write %s", fname);
                    exit (1);
                }
                off += wrote;
            }
            if (close(fd) == -1)
            {
                yaz_log(LOG_ERRNO|LOG_FATAL, "close %s", fname);
                exit (1);
            }
        }
        mbuf = malloc(sizeof(buf)-j);
        memcpy(mbuf, buf+j, sizeof(buf)-j);
        odr_setbuf(odr, mbuf, sizeof(buf)-j, 0);
        if (z_GDU(odr, &req, 0, 0))
            estat[99]++;
        else
        {
            int ex;
            odr_geterrorx(odr, &ex);
            estat[ex]++;
        }
        if (dumpfile)
            odr_dumpBER(dumpfile, buf+j, sizeof(buf)-j);
        free(mbuf);
        odr_reset(odr);
        odr_destroy(odr);
        nmem_exit();
    }
    if (dumpfile && dumpfile != stdout)
        fclose(dumpfile);
}

void sigint_handler(int x)
{
    stop = 1;
}

int main(int argc, char **argv)
{
    int start = 0, end = 10000000, ret, i, estat[100];
    char *arg;
    char *ber_fname = 0;
    char *packet_fname = 0;

    signal(SIGINT, sigint_handler);
    signal(SIGTERM, sigint_handler);
    for (i = 0; i<sizeof(estat)/sizeof(*estat); i++)
        estat[i] = 0;

    while ((ret = options("s:e:b:p:", argv, argc, &arg)) != -2)
    {
        switch (ret)
        {
        case 's':
            start = atoi(arg);
            break;
        case 'e':
            end = atoi(arg);
            break;
        case 'b':
            ber_fname = arg;
            break;
        case 'p':
            packet_fname = arg;
            break;
        case 0:
            if (!strcmp(arg, "random"))
            {
                i = start;
                while(!stop && (end == 0 || i < end))
                {
                    srand(i*5111+1);
                    if ((i % 50) == 0)
                        printf ("\r[%d]", i); fflush(stdout);
                    test_random(i, packet_fname, ber_fname, estat);
                    i++;
                }
            }
            break;
        default:
            fprintf (stderr, "usage\n");
            fprintf (stderr, " [-s start] [-e end] [-b berdump] [-p packetdump] random\n");
            exit(1);
        }
    }
    printf ("\n");
    for (i = 0; i < sizeof(estat)/sizeof(*estat); i++)
        if (estat[i])
            printf ("%3d %9d\n", i, estat[i]);
    exit(0);
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

