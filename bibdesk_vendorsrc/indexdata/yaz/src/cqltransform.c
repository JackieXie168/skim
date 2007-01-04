/* $Id: cqltransform.c,v 1.25 2006/10/25 09:58:19 adam Exp $
   Copyright (C) 1995-2005, Index Data ApS
   Index Data Aps

This file is part of the YAZ toolkit.

See the file LICENSE.
*/

/**
 * \file cqltransform.c
 * \brief Implements CQL transform (CQL to RPN conversion).
 *
 * Evaluation order of rules:
 *
 * always
 * relation
 * structure
 * position
 * truncation
 * index
 * relationModifier
 */

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <yaz/cql.h>
#include <yaz/xmalloc.h>
#include <yaz/diagsrw.h>

struct cql_prop_entry {
    char *pattern;
    char *value;
    struct cql_prop_entry *next;
};

struct cql_transform_t_ {
    struct cql_prop_entry *entry;
    int error;
    char *addinfo;
};

cql_transform_t cql_transform_open_FILE(FILE *f)
{
    char line[1024];
    cql_transform_t ct = (cql_transform_t) xmalloc (sizeof(*ct));
    struct cql_prop_entry **pp = &ct->entry;

    ct->error = 0;
    ct->addinfo = 0;
    while (fgets(line, sizeof(line)-1, f))
    {
        const char *cp_value_start;
        const char *cp_value_end;
        const char *cp_pattern_start;
        const char *cp_pattern_end;
        const char *cp = line;

        while (*cp && strchr(" \t", *cp))
            cp++;
        cp_pattern_start = cp;
        
        while (*cp && !strchr(" \t\r\n=#", *cp))
            cp++;
        cp_pattern_end = cp;
        if (cp == cp_pattern_start)
            continue;
        while (*cp && strchr(" \t", *cp))
            cp++;
        if (*cp != '=')
        {
            *pp = 0;
            cql_transform_close(ct);
            return 0;
        }
        cp++;
        while (*cp && strchr(" \t\r\n", *cp))
            cp++;
        cp_value_start = cp;
        cp_value_end = strchr(cp, '#');
        if (!cp_value_end)
            cp_value_end = strlen(line) + line;

        if (cp_value_end != cp_value_start &&
            strchr(" \t\r\n", cp_value_end[-1]))
            cp_value_end--;
        *pp = (struct cql_prop_entry *) xmalloc (sizeof(**pp));
        (*pp)->pattern = (char *) xmalloc(cp_pattern_end-cp_pattern_start + 1);
        memcpy ((*pp)->pattern, cp_pattern_start,
                cp_pattern_end-cp_pattern_start);
        (*pp)->pattern[cp_pattern_end-cp_pattern_start] = '\0';

        (*pp)->value = (char *) xmalloc (cp_value_end-cp_value_start + 1);
        if (cp_value_start != cp_value_end)
            memcpy ((*pp)->value, cp_value_start, cp_value_end-cp_value_start);
        (*pp)->value[cp_value_end - cp_value_start] = '\0';
        pp = &(*pp)->next;
    }
    *pp = 0;
    return ct;
}

void cql_transform_close(cql_transform_t ct)
{
    struct cql_prop_entry *pe;
    if (!ct)
        return;
    pe = ct->entry;
    while (pe)
    {
        struct cql_prop_entry *pe_next = pe->next;
        xfree (pe->pattern);
        xfree (pe->value);
        xfree (pe);
        pe = pe_next;
    }
    if (ct->addinfo)
        xfree (ct->addinfo);
    xfree (ct);
}

cql_transform_t cql_transform_open_fname(const char *fname)
{
    cql_transform_t ct;
    FILE *f = fopen(fname, "r");
    if (!f)
        return 0;
    ct = cql_transform_open_FILE(f);
    fclose(f);
    return ct;
}

static const char *cql_lookup_property(cql_transform_t ct,
                                       const char *pat1, const char *pat2,
                                       const char *pat3)
{
    char pattern[120];
    struct cql_prop_entry *e;

    if (pat1 && pat2 && pat3)
        sprintf (pattern, "%.39s.%.39s.%.39s", pat1, pat2, pat3);
    else if (pat1 && pat2)
        sprintf (pattern, "%.39s.%.39s", pat1, pat2);
    else if (pat1 && pat3)
        sprintf (pattern, "%.39s.%.39s", pat1, pat3);
    else if (pat1)
        sprintf (pattern, "%.39s", pat1);
    else
        return 0;
    
    for (e = ct->entry; e; e = e->next)
    {
        if (!cql_strcmp(e->pattern, pattern))
            return e->value;
    }
    return 0;
}

int cql_pr_attr_uri(cql_transform_t ct, const char *category,
                   const char *uri, const char *val, const char *default_val,
                   void (*pr)(const char *buf, void *client_data),
                   void *client_data,
                   int errcode)
{
    const char *res = 0;
    const char *eval = val ? val : default_val;
    const char *prefix = 0;
    
    if (uri)
    {
        struct cql_prop_entry *e;
        
        for (e = ct->entry; e; e = e->next)
            if (!memcmp(e->pattern, "set.", 4) && e->value &&
                !strcmp(e->value, uri))
            {
                prefix = e->pattern+4;
                break;
            }
        /* must have a prefix now - if not it's an error */
    }

    if (!uri || prefix)
    {
        if (!res)
            res = cql_lookup_property(ct, category, prefix, eval);
        if (!res)
            res = cql_lookup_property(ct, category, prefix, "*");
    }
    if (res)
    {
        char buf[64];

        const char *cp0 = res, *cp1;
        while ((cp1 = strchr(cp0, '=')))
        {
            while (*cp1 && *cp1 != ' ')
                cp1++;
            if (cp1 - cp0 >= sizeof(buf))
                break;
            memcpy (buf, cp0, cp1 - cp0);
            buf[cp1-cp0] = 0;
            (*pr)("@attr ", client_data);
            (*pr)(buf, client_data);
            (*pr)(" ", client_data);
            cp0 = cp1;
            while (*cp0 == ' ')
                cp0++;
        }
        return 1;
    }
    /* error ... */
    if (errcode && !ct->error)
    {
        ct->error = errcode;
        if (val)
            ct->addinfo = xstrdup(val);
        else
            ct->addinfo = 0;
    }
    return 0;
}

int cql_pr_attr(cql_transform_t ct, const char *category,
                const char *val, const char *default_val,
                void (*pr)(const char *buf, void *client_data),
                void *client_data,
                int errcode)
{
    return cql_pr_attr_uri(ct, category, 0 /* uri */,
                           val, default_val, pr, client_data, errcode);
}


static void cql_pr_int (int val,
                        void (*pr)(const char *buf, void *client_data),
                        void *client_data)
{
    char buf[21];              /* enough characters to 2^64 */
    sprintf(buf, "%d", val);
    (*pr)(buf, client_data);
    (*pr)(" ", client_data);
}


static int cql_pr_prox(cql_transform_t ct, struct cql_node *mods,
                       void (*pr)(const char *buf, void *client_data),
                       void *client_data)
{
    int exclusion = 0;
    int distance;               /* to be filled in later depending on unit */
    int distance_defined = 0;
    int ordered = 0;
    int proxrel = 2;            /* less than or equal */
    int unit = 2;               /* word */

    while (mods != 0) {
        char *name = mods->u.st.index;
        char *term = mods->u.st.term;
        char *relation = mods->u.st.relation;

        if (!strcmp(name, "distance")) {
            distance = strtol(term, (char**) 0, 0);
            distance_defined = 1;
            if (!strcmp(relation, "=")) {
                proxrel = 3;
            } else if (!strcmp(relation, ">")) {
                proxrel = 5;
            } else if (!strcmp(relation, "<")) {
                proxrel = 1;
            } else if (!strcmp(relation, ">=")) {
                proxrel = 4;
            } else if (!strcmp(relation, "<=")) {
                proxrel = 2;
            } else if (!strcmp(relation, "<>")) {
                proxrel = 6;
            } else {
                ct->error = 40; /* Unsupported proximity relation */
                ct->addinfo = xstrdup(relation);
                return 0;
            }
        } else if (!strcmp(name, "ordered")) {
            ordered = 1;
        } else if (!strcmp(name, "unordered")) {
            ordered = 0;
        } else if (!strcmp(name, "unit")) {
            if (!strcmp(term, "word")) {
                unit = 2;
            } else if (!strcmp(term, "sentence")) {
                unit = 3;
            } else if (!strcmp(term, "paragraph")) {
                unit = 4;
            } else if (!strcmp(term, "element")) {
                unit = 8;
            } else {
                ct->error = 42; /* Unsupported proximity unit */
                ct->addinfo = xstrdup(term);
                return 0;
            }
        } else {
            ct->error = 46;     /* Unsupported boolean modifier */
            ct->addinfo = xstrdup(name);
            return 0;
        }

        mods = mods->u.st.modifiers;
    }

    if (!distance_defined)
        distance = (unit == 2) ? 1 : 0;

    cql_pr_int(exclusion, pr, client_data);
    cql_pr_int(distance, pr, client_data);
    cql_pr_int(ordered, pr, client_data);
    cql_pr_int(proxrel, pr, client_data);
    (*pr)("k ", client_data);
    cql_pr_int(unit, pr, client_data);

    return 1;
}

/* Returns location of first wildcard character in the `length'
 * characters starting at `term', or a null pointer of there are
 * none -- like memchr().
 */
static const char *wcchar(const char *term, int length)
{
    const char *best = 0;
    const char *current;
    char *whichp;

    for (whichp = "*?"; *whichp != '\0'; whichp++) {
        current = (const char *) memchr(term, *whichp, length);
        if (current != 0 && (best == 0 || current < best))
            best = current;
    }

    return best;
}


void emit_term(cql_transform_t ct,
               struct cql_node *cn,
               const char *term, int length,
               void (*pr)(const char *buf, void *client_data),
               void *client_data)
{
    int i;
    const char *ns = cn->u.st.index_uri;

    assert(cn->which == CQL_NODE_ST);

    if (length > 0)
    {
        if (length > 1 && term[0] == '^' && term[length-1] == '^')
        {
            cql_pr_attr(ct, "position", "firstAndLast", 0,
                        pr, client_data, 32);
            term++;
            length -= 2;
        }
        else if (term[0] == '^')
        {
            cql_pr_attr(ct, "position", "first", 0,
                        pr, client_data, 32);
            term++;
            length--;
        }
        else if (term[length-1] == '^')
        {
            cql_pr_attr(ct, "position", "last", 0,
                        pr, client_data, 32);
            length--;
        }
        else
        {
            cql_pr_attr(ct, "position", "any", 0,
                        pr, client_data, 32);
        }
    }

    if (length > 0)
    {
        /* Check for well-known globbing patterns that represent
         * simple truncation attributes as expected by, for example,
         * Bath-compliant server.  If we find such a pattern but
         * there's no mapping for it, that's fine: we just use a
         * general pattern-matching attribute.
         */
        if (length > 1 && term[0] == '*' && term[length-1] == '*' &&
            wcchar(term+1, length-2) == 0 &&
            cql_pr_attr(ct, "truncation", "both", 0,
                        pr, client_data, 0)) {
            term++;
            length -= 2;
        }
        else if (term[0] == '*' &&
                 wcchar(term+1, length-1) == 0 &&
                 cql_pr_attr(ct, "truncation", "left", 0,
                             pr, client_data, 0)) {
            term++;
            length--;
        }
        else if (term[length-1] == '*' &&
                 wcchar(term, length-1) == 0 &&
                 cql_pr_attr(ct, "truncation", "right", 0,
                             pr, client_data, 0)) {
            length--;
        }
        else if (wcchar(term, length))
        {
            /* We have one or more wildcard characters, but not in a
             * way that can be dealt with using only the standard
             * left-, right- and both-truncation attributes.  We need
             * to translate the pattern into a Z39.58-type pattern,
             * which has been supported in BIB-1 since 1996.  If
             * there's no configuration element for "truncation.z3958"
             * we indicate this as error 28 "Masking character not
             * supported".
             */
            int i;
            char *mem;
            cql_pr_attr(ct, "truncation", "z3958", 0,
                        pr, client_data, 28);
            mem = (char *) xmalloc(length+1);
            for (i = 0; i < length; i++) {
                if (term[i] == '*')      mem[i] = '?';
                else if (term[i] == '?') mem[i] = '#';
                else                     mem[i] = term[i];
            }
            mem[length] = '\0';
            term = mem;
        }
        else {
            /* No masking characters.  Use "truncation.none" if given. */
            cql_pr_attr(ct, "truncation", "none", 0,
                        pr, client_data, 0);
        }
    }
    if (ns) {
        cql_pr_attr_uri(ct, "index", ns,
                        cn->u.st.index, "serverChoice",
                        pr, client_data, 16);
    }
    if (cn->u.st.modifiers)
    {
        struct cql_node *mod = cn->u.st.modifiers;
        for (; mod; mod = mod->u.st.modifiers)
        {
            cql_pr_attr(ct, "relationModifier", mod->u.st.index, 0,
                        pr, client_data, 20);
        }
    }

    (*pr)("\"", client_data);
    for (i = 0; i<length; i++)
    {
        /* pr(int) each character */
        char buf[3];
        const char *cp;

        buf[1] = term[i];
        buf[2] = 0;
        /* do we have to escape this char? */
        if (buf[1] == '"')
        {
            buf[0] = '\\';
            cp = buf;
        }
        else
            cp = buf+1;
        (*pr)(cp, client_data);
    }
    (*pr)("\" ", client_data);
}

void emit_wordlist(cql_transform_t ct,
                   struct cql_node *cn,
                   void (*pr)(const char *buf, void *client_data),
                   void *client_data,
                   const char *op)
{
    const char *cp0 = cn->u.st.term;
    const char *cp1;
    const char *last_term = 0;
    int last_length = 0;
    while(cp0)
    {
        while (*cp0 == ' ')
            cp0++;
        cp1 = strchr(cp0, ' ');
        if (last_term)
        {
            (*pr)("@", client_data);
            (*pr)(op, client_data);
            (*pr)(" ", client_data);
            emit_term(ct, cn, last_term, last_length, pr, client_data);
        }
        last_term = cp0;
        if (cp1)
            last_length = cp1 - cp0;
        else
            last_length = strlen(cp0);
        cp0 = cp1;
    }
    if (last_term)
        emit_term(ct, cn, last_term, last_length, pr, client_data);
}

void cql_transform_r(cql_transform_t ct,
                     struct cql_node *cn,
                     void (*pr)(const char *buf, void *client_data),
                     void *client_data)
{
    const char *ns;
    struct cql_node *mods;

    if (!cn)
        return;
    switch (cn->which)
    {
    case CQL_NODE_ST:
        ns = cn->u.st.index_uri;
        if (ns)
        {
            if (!strcmp(ns, cql_uri())
                && cn->u.st.index && !cql_strcmp(cn->u.st.index, "resultSet"))
            {
                (*pr)("@set \"", client_data);
                (*pr)(cn->u.st.term, client_data);
                (*pr)("\" ", client_data);
                return ;
            }
        }
        else
        {
            if (!ct->error)
            {
                ct->error = 15;
                ct->addinfo = 0;
            }
        }
        cql_pr_attr(ct, "always", 0, 0, pr, client_data, 0);
        if (cn->u.st.relation && !cql_strcmp(cn->u.st.relation, "="))
            cql_pr_attr(ct, "relation", "eq", "scr",
                        pr, client_data, 19);
        else if (cn->u.st.relation && !cql_strcmp(cn->u.st.relation, "<="))
            cql_pr_attr(ct, "relation", "le", "scr",
                        pr, client_data, 19);
        else if (cn->u.st.relation && !cql_strcmp(cn->u.st.relation, ">="))
            cql_pr_attr(ct, "relation", "ge", "scr",
                        pr, client_data, 19);
        else
            cql_pr_attr(ct, "relation", cn->u.st.relation, "eq",
                        pr, client_data, 19);
        cql_pr_attr(ct, "structure", cn->u.st.relation, 0,
                    pr, client_data, 24);
        if (cn->u.st.relation && !cql_strcmp(cn->u.st.relation, "all"))
        {
            emit_wordlist(ct, cn, pr, client_data, "and");
        }
        else if (cn->u.st.relation && !cql_strcmp(cn->u.st.relation, "any"))
        {
            emit_wordlist(ct, cn, pr, client_data, "or");
        }
        else
        {
            emit_term(ct, cn, cn->u.st.term, strlen(cn->u.st.term),
                      pr, client_data);
        }
        break;
    case CQL_NODE_BOOL:
        (*pr)("@", client_data);
        (*pr)(cn->u.boolean.value, client_data);
        (*pr)(" ", client_data);
        mods = cn->u.boolean.modifiers;
        if (!strcmp(cn->u.boolean.value, "prox")) {
            if (!cql_pr_prox(ct, mods, pr, client_data))
                return;
        } else if (mods) {
            /* Boolean modifiers other than on proximity not supported */
            ct->error = 46; /* SRW diag: "Unsupported boolean modifier" */
            ct->addinfo = xstrdup(mods->u.st.index);
            return;
        }

        cql_transform_r(ct, cn->u.boolean.left, pr, client_data);
        cql_transform_r(ct, cn->u.boolean.right, pr, client_data);
        break;

    default:
        fprintf(stderr, "Fatal: impossible CQL node-type %d\n", cn->which);
        abort();
    }
}

int cql_transform(cql_transform_t ct,
                  struct cql_node *cn,
                  void (*pr)(const char *buf, void *client_data),
                  void *client_data)
{
    struct cql_prop_entry *e;
    NMEM nmem = nmem_create();

    ct->error = 0;
    if (ct->addinfo)
        xfree (ct->addinfo);
    ct->addinfo = 0;

    for (e = ct->entry; e ; e = e->next)
    {
        if (!cql_strncmp(e->pattern, "set.", 4))
            cql_apply_prefix(nmem, cn, e->pattern+4, e->value);
        else if (!cql_strcmp(e->pattern, "set"))
            cql_apply_prefix(nmem, cn, 0, e->value);
    }
    cql_transform_r (ct, cn, pr, client_data);
    nmem_destroy(nmem);
    return ct->error;
}


int cql_transform_FILE(cql_transform_t ct, struct cql_node *cn, FILE *f)
{
    return cql_transform(ct, cn, cql_fputs, f);
}

int cql_transform_buf(cql_transform_t ct, struct cql_node *cn,
                      char *out, int max)
{
    struct cql_buf_write_info info;
    int r;

    info.off = 0;
    info.max = max;
    info.buf = out;
    r = cql_transform(ct, cn, cql_buf_write_handler, &info);
    if (info.off < 0) {
        /* Attempt to write past end of buffer.  For some reason, this
           SRW diagnostic is deprecated, but it's so perfect for our
           purposes that it would be stupid not to use it. */
        char numbuf[30];
        ct->error = YAZ_SRW_TOO_MANY_CHARS_IN_QUERY;
        sprintf(numbuf, "%ld", (long) info.max);
        ct->addinfo = xstrdup(numbuf);
        return -1;
    }
    if (info.off >= 0)
        info.buf[info.off] = '\0';
    return r;
}

int cql_transform_error(cql_transform_t ct, const char **addinfo)
{
    *addinfo = ct->addinfo;
    return ct->error;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

