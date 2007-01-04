/* $Id: cql.y,v 1.13 2006/12/14 09:05:18 adam Exp $
   Copyright (C) 2002-2006
   Index Data ApS

This file is part of the YAZ toolkit.

See the file LICENSE.

 bison parser for CQL grammar.
*/
%{
/** 
 * \file cql.c
 * \brief Implements CQL parser.
 *
 * This is a YACC parser, but since it must be reentrant, Bison is required.
 * The original source file is cql.y.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <yaz/xmalloc.h>
#include <yaz/nmem.h>
#include <yaz/cql.h>

    /** Node in the LALR parse tree. */
    typedef struct {
	/** Inhereted attribute: relation */
        struct cql_node *rel;
	/** Synthesized attribute: CQL node */
        struct cql_node *cql;
	/** string buffer with token */
        char *buf;
	/** length of token */
        size_t len;
	/** size of buffer (len <= size) */
        size_t size;
    } token;        

    struct cql_parser {
        int (*getbyte)(void *client_data);
        void (*ungetbyte)(int b, void *client_data);
        void *client_data;
        int last_error;
        int last_pos;
        struct cql_node *top;
        NMEM nmem;
    };

#define YYSTYPE token
    
#define YYPARSE_PARAM parm
#define YYLEX_PARAM parm
    
    int yylex(YYSTYPE *lval, void *vp);
    int yyerror(char *s);
%}

%pure_parser
%token TERM AND OR NOT PROX GE LE NE
%expect 9

%%

top: { 
    $$.rel = cql_node_mk_sc(((CQL_parser) parm)->nmem,
			    "cql.serverChoice", "scr", 0);
    ((CQL_parser) parm)->top = 0;
} cqlQuery1 {
    cql_node_destroy($$.rel);
    ((CQL_parser) parm)->top = $2.cql; 
}
;

cqlQuery1: cqlQuery
| cqlQuery error {
    cql_node_destroy($1.cql);
    $$.cql = 0;
}
;

cqlQuery: 
  searchClause
|
  cqlQuery boolean modifiers { 
      $$.rel = $0.rel;
  } searchClause {
      struct cql_node *cn = cql_node_mk_boolean(((CQL_parser) parm)->nmem,
						$2.buf);
      
      cn->u.boolean.modifiers = $3.cql;
      cn->u.boolean.left = $1.cql;
      cn->u.boolean.right = $5.cql;

      $$.cql = cn;
  }
;

searchClause: 
  '(' { 
      $$.rel = $0.rel;
      
  } cqlQuery ')' {
      $$.cql = $3.cql;
  }
|
  searchTerm {
      struct cql_node *st = cql_node_dup (((CQL_parser) parm)->nmem, $0.rel);
      st->u.st.term = nmem_strdup(((CQL_parser)parm)->nmem, $1.buf);
      $$.cql = st;
  }
| 
  index relation modifiers {
      $$.rel = cql_node_mk_sc(((CQL_parser) parm)->nmem, $1.buf, $2.buf, 0);
      $$.rel->u.st.modifiers = $3.cql;
  } searchClause {
      $$.cql = $5.cql;
      cql_node_destroy($4.rel);
  }
| '>' searchTerm '=' searchTerm {
      $$.rel = $0.rel;
  } cqlQuery {
    $$.cql = cql_apply_prefix(((CQL_parser) parm)->nmem,
			      $6.cql, $2.buf, $4.buf);
  }
| '>' searchTerm {
      $$.rel = $0.rel;
  } cqlQuery {
    $$.cql = cql_apply_prefix(((CQL_parser) parm)->nmem, 
			      $4.cql, 0, $2.buf);
   }
;

/* unary NOT search TERM here .. */

boolean: 
  AND | OR | NOT | PROX ;

modifiers: modifiers '/' searchTerm
{ 
    struct cql_node *mod = cql_node_mk_sc(((CQL_parser)parm)->nmem,
					  $3.buf, "=", 0);

    mod->u.st.modifiers = $1.cql;
    $$.cql = mod;
}
|
modifiers '/' searchTerm mrelation searchTerm
{
    struct cql_node *mod = cql_node_mk_sc(((CQL_parser)parm)->nmem,
					  $3.buf, $4.buf, $5.buf);

    mod->u.st.modifiers = $1.cql;
    $$.cql = mod;
}
|
{ 
    $$.cql = 0;
}
;

mrelation:
  '=' 
| '>' 
| '<'
| GE
| LE
| NE
;

relation: 
  '=' 
| '>' 
| '<'
| GE
| LE
| NE
| TERM
;

index: 
  searchTerm;

searchTerm:
  TERM
| AND
| OR
| NOT
| PROX
;

%%

int yyerror(char *s)
{
    return 0;
}

/**
 * putb is a utility that puts one character to the string
 * in current lexical token. This routine deallocates as
 * necessary using NMEM.
 */

static void putb(YYSTYPE *lval, CQL_parser cp, int c)
{
    if (lval->len+1 >= lval->size)
    {
        char *nb = (char *)
	    nmem_malloc(cp->nmem, (lval->size = lval->len * 2 + 20));
        memcpy (nb, lval->buf, lval->len);
        lval->buf = nb;
    }
    if (c)
        lval->buf[lval->len++] = c;
    lval->buf[lval->len] = '\0';
}


/**
 * yylex returns next token for Bison to be read. In this
 * case one of the CQL terminals are returned.
 */
int yylex(YYSTYPE *lval, void *vp)
{
    CQL_parser cp = (CQL_parser) vp;
    int c;
    lval->cql = 0;
    lval->rel = 0;
    lval->len = 0;
    lval->size = 10;
    lval->buf = (char *) nmem_malloc(cp->nmem, lval->size);
    lval->buf[0] = '\0';
    do
    {
        c = cp->getbyte(cp->client_data);
        if (c == 0)
            return 0;
        if (c == '\n')
            return 0;
    } while (isspace(c));
    if (strchr("()=></", c))
    {
        int c1;
        putb(lval, cp, c);
        if (c == '>')
        {
            c1 = cp->getbyte(cp->client_data);
            if (c1 == '=')
            {
                putb(lval, cp, c1);
                return GE;
            }
            else
                cp->ungetbyte(c1, cp->client_data);
        }
        else if (c == '<')
        {
            c1 = cp->getbyte(cp->client_data);
            if (c1 == '=')
            {
                putb(lval, cp, c1);
                return LE;
            }
            else if (c1 == '>')
            {
                putb(lval, cp, c1);
                return NE;
            }
            else
                cp->ungetbyte(c1, cp->client_data);
        }
        return c;
    }
    if (c == '"')
    {
        while ((c = cp->getbyte(cp->client_data)) != 0 && c != '"')
        {
            if (c == '\\')
                c = cp->getbyte(cp->client_data);
            putb(lval, cp, c);
        }
        putb(lval, cp, 0);
    }
    else
    {
        while (c != 0 && !strchr(" \n()=<>/", c))
        {
            if (c == '\\')
                c = cp->getbyte(cp->client_data);
            putb(lval, cp, c);
	    c = cp->getbyte(cp->client_data);
        }
#if YYDEBUG
        printf ("got %s\n", lval->buf);
#endif
        if (c != 0)
            cp->ungetbyte(c, cp->client_data);
        if (!cql_strcmp(lval->buf, "and"))
	{
	    lval->buf = "and";
            return AND;
	}
        if (!cql_strcmp(lval->buf, "or"))
	{
	    lval->buf = "or";
            return OR;
	}
        if (!cql_strcmp(lval->buf, "not"))
	{
	    lval->buf = "not";
            return NOT;
	}
        if (!cql_strcmp(lval->buf, "prox"))
	{
	    lval->buf = "prox";
            return PROX;
	}
    }
    return TERM;
}


int cql_parser_stream(CQL_parser cp,
                      int (*getbyte)(void *client_data),
                      void (*ungetbyte)(int b, void *client_data),
                      void *client_data)
{
    nmem_reset(cp->nmem);
    cp->getbyte = getbyte;
    cp->ungetbyte = ungetbyte;
    cp->client_data = client_data;
    if (cp->top)
        cql_node_destroy(cp->top);
    cql_parse(cp);
    if (cp->top)
        return 0;
    return -1;
}

CQL_parser cql_parser_create(void)
{
    CQL_parser cp = (CQL_parser) xmalloc (sizeof(*cp));

    cp->top = 0;
    cp->getbyte = 0;
    cp->ungetbyte = 0;
    cp->client_data = 0;
    cp->last_error = 0;
    cp->last_pos = 0;
    cp->nmem = nmem_create();
    return cp;
}

void cql_parser_destroy(CQL_parser cp)
{
    cql_node_destroy(cp->top);
    nmem_destroy(cp->nmem);
    xfree (cp);
}

struct cql_node *cql_parser_result(CQL_parser cp)
{
    return cp->top;
}
