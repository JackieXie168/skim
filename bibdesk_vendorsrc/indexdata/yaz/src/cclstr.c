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
 * \file cclstr.c
 * \brief Implements CCL string compare utilities
 */
/* CCL string compare utilities
 * Europagate, 1995
 *
 * $Id: cclstr.c,v 1.3 2005/06/25 15:46:03 adam Exp $
 *
 * Old Europagate Log:
 *
 * Revision 1.3  1996/01/24  10:11:19  adam
 * Added include of stdlib.h.
 *
 * Revision 1.2  1995/05/16  09:39:27  adam
 * LICENSE.
 *
 * Revision 1.1  1995/05/11  14:03:57  adam
 * Changes in the reading of qualifier(s). New function: ccl_qual_fitem.
 * New variable ccl_case_sensitive, which controls whether reserved
 * words and field names are case sensitive or not.
 *
 */
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

#include "ccl.h"

static int ccli_toupper (int c)
{
    return toupper (c);
}

int (*ccl_toupper)(int c) = NULL;

int ccl_stricmp (const char *s1, const char *s2)
{
    if (!ccl_toupper)
        ccl_toupper = ccli_toupper;
    while (*s1 && *s2)
    {
        int c1, c2;
        c1 = (*ccl_toupper)(*s1);
        c2 = (*ccl_toupper)(*s2);
        if (c1 != c2)
            return c1 - c2;
        s1++;
        s2++;
    }
    return (*ccl_toupper)(*s1) - (*ccl_toupper)(*s2);
}

int ccl_memicmp (const char *s1, const char *s2, size_t n)
{
    if (!ccl_toupper)
        ccl_toupper = ccli_toupper;
    while (1)
    {
        int c1, c2;

        c1 = (*ccl_toupper)(*s1);
        c2 = (*ccl_toupper)(*s2);
        if (n <= 1 || c1 != c2)
            return c1 - c2;
        s1++;
        s2++;
        --n;
    }
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

