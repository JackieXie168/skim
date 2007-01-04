/* $Id: cqlstrer.c,v 1.6 2006/03/10 10:43:32 mike Exp $
   Copyright (C) 1995-2005, Index Data ApS
   Index Data Aps

This file is part of the YAZ toolkit.

See the file LICENSE details.
*/

/**
 * \file cqlstrer.c
 * \brief Implements CQL error code map to description string.
 */

#include <yaz/cql.h>

/*
 * The error-messages associated with these codes are taken from
 * the SRW diagnostic specifications at
 *      http://www.loc.gov/standards/sru/diagnostics-list.html
 */
const char *cql_strerror(int code) {
    static char buf[80];
    switch (code) {
    case 10: return "Illegal query";
    case 11: return "Unsupported query type (XCQL vs CQL)";
    case 12: return "Too many characters in query";
    case 13: return "Unbalanced or illegal use of parentheses";
    case 14: return "Unbalanced or illegal use of quotes";
    case 15: return "Illegal or unsupported context set";
    case 16: return "Illegal or unsupported index";
    case 17: return "Illegal or unsupported combination of index and context set";
    case 18: return "Illegal or unsupported combination of indexes";
    case 19: return "Illegal or unsupported relation";
    case 20: return "Illegal or unsupported relation modifier";
    case 21: return "Illegal or unsupported combination of relation modifers";
    case 22: return "Illegal or unsupported combination of relation and index";
    case 23: return "Too many characters in term";
    case 24: return "Illegal combination of relation and term";
    case 25: return "Special characters not quoted in term";
    case 26: return "Non special character escaped in term";
    case 27: return "Empty term unsupported";
    case 28: return "Masking character not supported";
    case 29: return "Masked words too short";
    case 30: return "Too many masking characters in term";
    case 31: return "Anchoring character not supported";
    case 32: return "Anchoring character in illegal or unsupported position";
    case 33: return "Combination of proximity/adjacency and masking characters not supported";
    case 34: return "Combination of proximity/adjacency and anchoring characters not supported";
    case 35: return "Terms only exclusion (stop) words";
    case 36: return "Term in invalid format for index or relation";
    case 37: return "Illegal or unsupported boolean operator";
    case 38: return "Too many boolean operators in query";
    case 39: return "Proximity not supported";
    case 40: return "Illegal or unsupported proximity relation";
    case 41: return "Illegal or unsupported proximity distance";
    case 42: return "Illegal or unsupported proximity unit";
    case 43: return "Illegal or unsupported proximity ordering";
    case 44: return "Illegal or unsupported combination of proximity modifiers";
    case 45: return "Context set name (prefix) assigned to multiple identifiers";
    default: break;
    }

    sprintf(buf, "Unknown CQL error #%d", code);
    return buf;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

