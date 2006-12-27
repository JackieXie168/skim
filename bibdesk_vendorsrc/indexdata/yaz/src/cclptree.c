/*
 * Copyright (c) 1995, the EUROPAGATE consortium (see below).
 *
 * The EUROPAGATE consortium members are:
 *
 *    University College Dublin
 *    Danmarks Teknologiske Videnscenter
 *    An Chomhairle Leabharlanna
 *    Consejo Superior de Investigaciones Cientificas
 *
 * Permission to use, copy, modify, distribute, and sell this software and
 * its documentation, in whole or in part, for any purpose, is hereby granted,
 * provided that:
 *
 * 1. This copyright and permission notice appear in all copies of the
 * software and its documentation. Notices of copyright or attribution
 * which appear at the beginning of any file must remain unchanged.
 *
 * 2. The names of EUROPAGATE or the project partners may not be used to
 * endorse or promote products derived from this software without specific
 * prior written permission.
 *
 * 3. Users of this software (implementors and gateway operators) agree to
 * inform the EUROPAGATE consortium of their use of the software. This
 * information will be used to evaluate the EUROPAGATE project and the
 * software, and to plan further developments. The consortium may use
 * the information in later publications.
 * 
 * 4. Users of this software agree to make their best efforts, when
 * documenting their use of the software, to acknowledge the EUROPAGATE
 * consortium, and the role played by the software in their work.
 *
 * THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS, IMPLIED, OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY
 * WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
 * IN NO EVENT SHALL THE EUROPAGATE CONSORTIUM OR ITS MEMBERS BE LIABLE
 * FOR ANY SPECIAL, INCIDENTAL, INDIRECT OR CONSEQUENTIAL DAMAGES OF
 * ANY KIND, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA
 * OR PROFITS, WHETHER OR NOT ADVISED OF THE POSSIBILITY OF DAMAGE, AND
 * ON ANY THEORY OF LIABILITY, ARISING OUT OF OR IN CONNECTION WITH THE
 * USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

/** 
 * \file cclptree.c
 * \brief Implements CCL parse tree printing
 *
 * This source file implements functions to parse and print
 * a CCL node tree (as a result of parsing).
 */

/* CCL print rpn tree - infix notation
 * Europagate, 1995
 *
 * $Id: cclptree.c,v 1.6 2005/06/25 15:46:03 adam Exp $
 *
 * Old Europagate Log:
 *
 * Revision 1.6  1995/05/16  09:39:26  adam
 * LICENSE.
 *
 * Revision 1.5  1995/02/23  08:31:59  adam
 * Changed header.
 *
 * Revision 1.3  1995/02/15  17:42:16  adam
 * Minor changes of the api of this module. FILE* argument added
 * to ccl_pr_tree.
 *
 * Revision 1.2  1995/02/14  19:55:11  adam
 * Header files ccl.h/cclp.h are gone! They have been merged an
 * moved to ../include/ccl.h.
 * Node kind(s) in ccl_rpn_node have changed names.
 *
 * Revision 1.1  1995/02/14  10:25:56  adam
 * The constructions 'qualifier rel term ...' implemented.
 *
 */

#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include "ccl.h"

void fprintSpaces(int indent,FILE * fd_out) 
{
    char buf[100];
    sprintf(buf,"%%%d.s",indent);
    fprintf(fd_out,buf," ");
}

void ccl_pr_tree_as_qrpn(struct ccl_rpn_node *rpn, FILE *fd_out, int indent)
{
    if(indent>0)
        fprintSpaces(indent,fd_out);
    switch (rpn->kind)
    {
    case CCL_RPN_TERM:
        if (rpn->u.t.attr_list)
        {
            struct ccl_rpn_attr *attr;
            for (attr = rpn->u.t.attr_list; attr; attr = attr->next)
            {
                if (attr->set)
                    fprintf(fd_out, "@attr %s ", attr->set);
                else
                    fprintf(fd_out, "@attr ");
                switch(attr->kind)
                {
                case CCL_RPN_ATTR_NUMERIC:
                    fprintf (fd_out, "%d=%d ", attr->type,
                             attr->value.numeric);
                    break;
                case CCL_RPN_ATTR_STRING:
                    fprintf (fd_out, "%d=%s ", attr->type,
                             attr->value.str);
                }
            }
        }
        fprintf (fd_out, "\"%s\"\n", rpn->u.t.term);
        break;
    case CCL_RPN_AND:
        fprintf (fd_out, "@and \n");
        ccl_pr_tree_as_qrpn (rpn->u.p[0], fd_out,indent+2);
        ccl_pr_tree_as_qrpn (rpn->u.p[1], fd_out,indent+2);
        break;
    case CCL_RPN_OR:
        fprintf (fd_out, "@or \n");
        ccl_pr_tree_as_qrpn (rpn->u.p[0], fd_out,indent+2);
        ccl_pr_tree_as_qrpn (rpn->u.p[1], fd_out,indent+2);
        break;
    case CCL_RPN_NOT:
        fprintf (fd_out, "@not ");
        ccl_pr_tree_as_qrpn (rpn->u.p[0], fd_out,indent+2);
        ccl_pr_tree_as_qrpn (rpn->u.p[1], fd_out,indent+2);
        break;
    case CCL_RPN_SET:
        fprintf (fd_out, "set=%s ", rpn->u.setname);
        break;
    case CCL_RPN_PROX:
        if (rpn->u.p[2] && rpn->u.p[2]->kind == CCL_RPN_TERM)
        {
            const char *cp = rpn->u.p[2]->u.t.term;
            /* exlusion distance ordered relation which-code unit-code */
            if (*cp == '!')
            {   
                /* word order specified */
                if (isdigit(((const unsigned char *) cp)[1]))
                    fprintf(fd_out, "@prox 0 %s 1 2 known 2", cp+1);
                else
                    fprintf(fd_out, "@prox 0 1 1 2 known 2");
            } 
            else if (*cp == '%')
            {
                /* word order not specified */
                if (isdigit(((const unsigned char *) cp)[1]))
                    fprintf(fd_out, "@prox 0 %s 0 2 known 2", cp+1);
                else
                    fprintf(fd_out, "@prox 0 1 0 2 known 2");
            }
        }
        ccl_pr_tree_as_qrpn (rpn->u.p[0], fd_out,indent+2);
        ccl_pr_tree_as_qrpn (rpn->u.p[1], fd_out,indent+2);
        break;
    default:
        fprintf(stderr,"Internal Error Unknown ccl_rpn node type %d\n",rpn->kind);
    }
}


void ccl_pr_tree (struct ccl_rpn_node *rpn, FILE *fd_out)
{
    ccl_pr_tree_as_qrpn(rpn,fd_out,0);
}


static void ccl_pquery_complex (WRBUF w, struct ccl_rpn_node *p)
{
    switch (p->kind)
    {
    case CCL_RPN_AND:
        wrbuf_puts(w, "@and ");
        break;
    case CCL_RPN_OR:
        wrbuf_puts(w, "@or ");
        break;
    case CCL_RPN_NOT:
        wrbuf_puts(w, "@not ");
        break;
    case CCL_RPN_PROX:
        if (p->u.p[2] && p->u.p[2]->kind == CCL_RPN_TERM)
        {
            const char *cp = p->u.p[2]->u.t.term;
            /* exlusion distance ordered relation which-code unit-code */
            if (*cp == '!')
            {   
                /* word order specified */
                if (isdigit(((const unsigned char *) cp)[1]))
                    wrbuf_printf(w, "@prox 0 %s 1 2 k 2 ", cp+1);
                else
                    wrbuf_printf(w, "@prox 0 1 1 2 k 2 ");
            } 
            else if (*cp == '%')
            {
                /* word order not specified */
                if (isdigit(((const unsigned char *) cp)[1]))
                    wrbuf_printf(w, "@prox 0 %s 0 2 k 2 ", cp+1);
                else
                    wrbuf_printf(w, "@prox 0 1 0 2 k 2 ");
            }
        }
        else
            wrbuf_puts(w, "@prox 0 2 0 1 k 2 ");
        break;
    default:
        wrbuf_puts(w, "@ bad op (unknown) ");
    }
    ccl_pquery(w, p->u.p[0]);
    ccl_pquery(w, p->u.p[1]);
}

void ccl_pquery (WRBUF w, struct ccl_rpn_node *p)
{
    struct ccl_rpn_attr *att;
    const char *cp;
        
    switch (p->kind)
    {
    case CCL_RPN_AND:
    case CCL_RPN_OR:
    case CCL_RPN_NOT:
    case CCL_RPN_PROX:
        ccl_pquery_complex (w, p);
        break;
    case CCL_RPN_SET:
        wrbuf_puts (w, "@set ");
        wrbuf_puts (w, p->u.setname);
        wrbuf_puts (w, " ");
        break;
    case CCL_RPN_TERM:
        for (att = p->u.t.attr_list; att; att = att->next)
        {
            char tmpattr[128];
            wrbuf_puts (w, "@attr ");
            if (att->set)
            {
                wrbuf_puts (w, att->set);
                wrbuf_puts (w, " ");
            }
            switch(att->kind)
            {
            case CCL_RPN_ATTR_NUMERIC:
                sprintf(tmpattr, "%d=%d ", att->type, att->value.numeric);
                wrbuf_puts (w, tmpattr);
                break;
            case CCL_RPN_ATTR_STRING:
                sprintf(tmpattr, "%d=", att->type);
                wrbuf_puts (w, tmpattr);
                wrbuf_puts(w, att->value.str);
                wrbuf_puts (w, " ");
                break;
            }
        }
        for (cp = p->u.t.term; *cp; cp++)
        {
            if (*cp == ' ' || *cp == '\\')
                wrbuf_putc (w, '\\');
            wrbuf_putc (w, *cp);
        }
        wrbuf_puts (w, " ");
        break;
    }
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

