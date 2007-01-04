/**
 * \file odr-priv.h
 * \brief Internal ODR definitions
 */

#ifndef ODR_PRIV_H

#define ODR_PRIV_H

#include <yaz/odr.h>
#include <yaz/yaz-util.h>

/** \brief Utility structure used by ber_tag */
struct Odr_ber_tag {
    int lclass;
    int ltag;
    int br;
    int lcons;
};

#define odr_max(o) ((o)->size - ((o)->bp - (o)->buf))
#define odr_offset(o) ((o)->bp - (o)->buf)

/**
 * \brief stack for BER constructed items
 *
 * data structure for con stack.. a little peculiar. Since we can't
 * deallocate memory we reuse stack items (popped items gets reused)
 *
 *\verbatim
 *       +---+     +---+     +---+     +---+
 * NULL -|p n|-----|p n|-----|p n|-----|p n|-- NULL
 *       +---+     +---+     +---+     +---+
 *         |                   |
 *     stack_first         stack_top   reused item
 *\endverbatim
 */
struct odr_constack
{
    const unsigned char *base;   /** starting point of data */
    int base_offset;
    int len;                     /** length of data, if known, else -1
                                        (decoding only) */
    const unsigned char *lenb;   /** where to encode length */
    int len_offset;
    int lenlen;                  /** length of length-field */
    const char *name;            /** name of stack entry */

    struct odr_constack *prev;   /** pointer back in stack */
    struct odr_constack *next;   /** pointer forward */
};

#define ODR_MAX_STACK 2000

/**
 * \brief ODR private data
 */
struct Odr_private {
    /* stack for constructed types (we above) */
    struct odr_constack *stack_first; /** first member of allocated stack */
    struct odr_constack *stack_top;   /** top of stack */


    const char **tmp_names_buf;   /** array returned by odr_get_element_path */
    int tmp_names_sz;                 /** size of tmp_names_buf */

    struct Odr_ber_tag odr_ber_tag;   /** used by ber_tag */

    yaz_iconv_t iconv_handle;
    int error_id;
    char element[80];
    void (*stream_write)(ODR o, void *handle, int type,
                         const char *buf, int len);
    void (*stream_close)(void *handle);
};

#define ODR_STACK_POP(x) (x)->op->stack_top = (x)->op->stack_top->prev
#define ODR_STACK_EMPTY(x) (!(x)->op->stack_top)
#define ODR_STACK_NOT_EMPTY(x) ((x)->op->stack_top)

/* Private macro.
 * write a single character at the current position - grow buffer if
 * necessary.
 * (no, we're not usually this anal about our macros, but this baby is
 *  next to unreadable without some indentation  :)
 */
#define odr_putc(o, c) \
( \
    ( \
        (o)->pos < (o)->size ? \
        ( \
            (o)->buf[(o)->pos++] = (c), \
            0 \
        ) : \
        ( \
            odr_grow_block((o), 1) == 0 ? \
            ( \
                (o)->buf[(o)->pos++] = (c), \
                0 \
            ) : \
            ( \
                (o)->error = OSPACE, \
                -1 \
            ) \
        ) \
    ) == 0 ? \
    ( \
        (o)->pos > (o)->top ? \
        ( \
            (o)->top = (o)->pos, \
            0 \
        ) : \
        0 \
    ) : \
        -1 \
)

#endif
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

