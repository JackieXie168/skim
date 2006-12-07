/*
 * Simple symbol table manager using coalesced chaining to resolve collisions
 *
 * Doubly-linked lists are used for fast removal of entries.
 *
 * 'sym.h' must have a definition for typedef "Sym".  Sym must include at
 * minimum the following fields:
 *
 *      ...
 *      char *symbol;
 *      struct ... *next, *prev, **head, *scope;
 *      unsigned int hash;
 *      ...
 *
 * 'template.h' can be used as a template to create a 'sym.h'.
 *
 * 'head' is &(table[hash(itself)]).
 * The hash table is not resizable at run-time.
 * The scope field is used to link all symbols of a current scope together.
 * Scope() sets the current scope (linked list) to add symbols to.
 * Any number of scopes can be handled.  The user passes the address of
 * a pointer to a symbol table
 * entry (INITIALIZED TO NULL first time).
 *
 * Available Functions:
 *
 *  zzs_init(s1,s2) --  Create hash table with size s1, string table size s2.
 *  zzs_done()      --  Free hash and string table created with zzs_init().
 *  zzs_add(key,rec)--  Add 'rec' with key 'key' to the symbol table.
 *  zzs_newadd(key) --  create entry; add using 'key' to the symbol table.
 *  zzs_get(key)    --  Return pointer to last record entered under 'key'
 *                      Else return NULL
 *  zzs_del(p)      --  Unlink the entry associated with p.  This does
 *                      NOT free 'p' and DOES NOT remove it from a scope
 *                      list.  If it was a part of your intermediate code
 *                      tree or another structure.  It will still be there.
 *                      It is only removed from further consideration
 *                      by the symbol table.
 *  zzs_keydel(s)   --  Unlink the entry associated with key s.
 *                      Calls zzs_del(p) to unlink.
 *  zzs_scope(sc)   --  Specifies that everything added to the symbol
 *                      table with zzs_add() is added to the list (scope)
 *                      'sc'.  'sc' is of 'Sym **sc' type and must be
 *                      initialized to NULL before trying to add anything
 *                      to it (passing it to zzs_scope()).  Scopes can be
 *                      switched at any time and merely links a set of
 *                      symbol table entries.  If a NULL pointer is
 *                      passed, the current scope is returned.
 *  zzs_rmscope(sc) --  Remove (zzs_del()) all elements of scope 'sc'
 *                      from the symbol table.  The entries are NOT
 *                      free()'d.  A pointer to the first
 *                      element in the "scope" is returned.  The user
 *                      can then manipulate the list as he/she chooses
 *                      (such as freeing them all). NOTE that this
 *                      function sets your scope pointer to NULL,
 *                      but returns a pointer to the list for you to use.
 *  zzs_stat()      --  Print out the symbol table and some relevant stats.
 *  zzs_new(key)    --  Create a new record with calloc() of type Sym.
 *                      Add 'key' to the string table and make the new
 *                      records 'symbol' pointer point to it.
 *  zzs_strdup(s)   --  Add s to the string table and return a pointer
 *                      to it.  Very fast allocation routine
 *                      and does not require strlen() nor calloc().
 *
 * Example:
 *
 *  #include <stdio.h>
 *  #include "sym.h"
 *
 *  main()
 *  {
 *      Sym *scope1=NULL, *scope2=NULL, *a, *p;
 *  
 *      zzs_init(101, 100);
 *  
 *      a = zzs_new("Apple");   zzs_add(a->symbol, a);  -- No scope
 *      zzs_scope( &scope1 );   -- enter scope 1
 *      a = zzs_new("Plum");    zzs_add(a->symbol, a);
 *      zzs_scope( &scope2 );   -- enter scope 2
 *      a = zzs_new("Truck");   zzs_add(a->symbol, a);
 *  
 *      p = zzs_get("Plum");
 *      if ( p == NULL ) fprintf(stderr, "Hmmm...Can't find 'Plum'\n");
 *  
 *      p = zzs_rmscope(&scope1)
 *      for (; p!=NULL; p=p->scope) {printf("Scope1:  %s\n", p->symbol);}
 *      p = zzs_rmscope(&scope2)
 *      for (; p!=NULL; p=p->scope) {printf("Scope2:  %s\n", p->symbol);}
 * }
 *
 * Terence Parr
 * Purdue University
 * February 1990
 *
 * CHANGES
 *
 *  Terence Parr
 *  May 1991
 *      Renamed functions to be consistent with ANTLR
 *      Made HASH macro
 *      Added zzs_keydel()
 *      Added zzs_newadd()
 *      Fixed up zzs_stat()
 *
 *  July 1991
 *      Made symbol table entry save its hash code for fast comparison
 *          during searching etc...
 */

#include "bt_config.h"
#include <stdio.h>
#if __STDC__ == 1
#include <string.h>
#include <stdlib.h>
#else
#include "malloc.h"
#endif
#ifdef MEMCHK
#include "trax.h"
#endif
#include "sym.h"
#include "my_dmalloc.h"

#define StrSame     0

static Sym **CurScope = NULL;
static unsigned size = 0;
static Sym **table=NULL;
static char *strings;
static char *strp;
static int strsize = 0;

void
zzs_init(int sz, int strs)
{
    if ( sz <= 0 || strs <= 0 ) return;
    table = (Sym **) calloc(sz, sizeof(Sym *));
    if ( table == NULL )
    {
        fprintf(stderr, "Cannot allocate table of size %d\n", sz);
        exit(1);
    }
    strings = (char *) calloc(strs, sizeof(char));
    if ( strings == NULL )
    {
        fprintf(stderr, "Cannot allocate string table of size %d\n", strs);
        exit(1);
    }
    size = sz;
    strsize = strs;
    strp = strings;
}


void
zzs_free(void)
{
    unsigned i;
    Sym  *cur, *next;

    for (i = 0; i < size; i++)
    {
        cur = table[i];
        while (cur != NULL)
        {
            next = cur->next;
            free (cur);
            cur = next;
        }
    }
}


void
zzs_done(void)
{
    if ( table != NULL ) free( table );
    if ( strings != NULL ) free( strings );
}

void
zzs_add(char *key, register Sym *rec)
{
    register unsigned int h=0;
    register char *p=key;
    
    HASH_FUN(p, h);
    rec->hash = h;                  /* save hash code for fast comp later */
    h %= size;
    
    if ( CurScope != NULL ) {rec->scope = *CurScope; *CurScope = rec;}
    rec->next = table[h];           /* Add to doubly-linked list */
    rec->prev = NULL;
    if ( rec->next != NULL ) (rec->next)->prev = rec;
    table[h] = rec;
    rec->head = &(table[h]);
}

Sym *
zzs_get(char *key)
{
    register unsigned int h=0;
    register char *p=key;
    register Sym *q;
    
    HASH_FUN(p, h);
    
    for (q = table[h%size]; q != NULL; q = q->next)
    {
        if ( q->hash == h )     /* do we even have a chance of matching? */
            if ( strcasecmp(key, q->symbol) == StrSame ) return( q );
    }
    return( NULL );
}

/*
 * Unlink p from the symbol table.  Hopefully, it's actually in the
 * symbol table.
 *
 * If p is not part of a bucket chain of the symbol table, bad things
 * will happen.
 *
 * Will do nothing if all list pointers are NULL
 */
void
zzs_del(register Sym *p)
{
    if ( p == NULL ) {fprintf(stderr, "zzs_del(NULL)\n"); exit(1);}
    if ( p->prev == NULL )  /* Head of list */
    {
        register Sym **t = p->head;
        
        if ( t == NULL ) return;    /* not part of symbol table */
        (*t) = p->next;
        if ( (*t) != NULL ) (*t)->prev = NULL;
    }
    else
    {
        (p->prev)->next = p->next;
        if ( p->next != NULL ) (p->next)->prev = p->prev;
    }
    p->next = p->prev = NULL;   /* not part of symbol table anymore */
    p->head = NULL;
}

void
zzs_keydel(char *key)
{
    Sym *p = zzs_get(key);

    if ( p != NULL ) zzs_del( p );
}

/* S c o p e  S t u f f */

/* Set current scope to 'scope'; return current scope if 'scope' == NULL */
Sym **
zzs_scope(Sym **scope)
{
    if ( scope == NULL ) return( CurScope );
    CurScope = scope;
    return( scope );
}

/* Remove a scope described by 'scope'.  Return pointer to 1st element in scope */
Sym *
zzs_rmscope(register Sym **scope)
{
    register Sym *p;
    Sym *start;

    if ( scope == NULL ) return(NULL);
    start = p = *scope;
    for (; p != NULL; p=p->scope) { zzs_del( p ); }
    *scope = NULL;
    return( start );
}

void
zzs_stat(void)
{
    static unsigned short count[20];
    unsigned int i,n=0,low=0, hi=0;
    register Sym **p;
    float avg=0.0;
    
    for (i=0; i<20; i++) count[i] = 0;
    for (p=table; p<&(table[size]); p++)
    {
        register Sym *q = *p;
        unsigned int len;
        
        if ( q != NULL && low==0 ) low = p-table;
        len = 0;
        if ( q != NULL ) printf("[%d]", p-table);
        while ( q != NULL )
        {
            len++;
            n++;
            printf(" %s", q->symbol);
            q = q->next;
            if ( q == NULL ) printf("\n");
        }
        if ( len>=20 ) printf("zzs_stat: count table too small\n");
        else count[len]++;
        if ( *p != NULL ) hi = p-table;
    }

    printf("Storing %d recs used %d hash positions out of %d\n",
            n, size-count[0], size);
    printf("%f %% utilization\n",
            ((float)(size-count[0]))/((float)size));
    for (i=0; i<20; i++)
    {
        if ( count[i] != 0 )
        {
            avg += (((float)(i*count[i]))/((float)n)) * i;
            printf("Buckets of len %d == %d (%f %% of recs)\n",
                    i, count[i], 100.0*((float)(i*count[i]))/((float)n));
        }
    }
    printf("Avg bucket length %f\n", avg);
    printf("Range of hash function: %d..%d\n", low, hi);
}

/*
 * Given a string, this function allocates and returns a pointer to a
 * symbol table record whose "symbol" pointer is reset to a position
 * in the string table.
 */
Sym *
zzs_new(char *text)
{
    Sym *p;
    char *zzs_strdup(register char *s);
    
    if ( (p = (Sym *) calloc(1,sizeof(Sym))) == 0 )
    {
        fprintf(stderr,"Out of memory\n");
        exit(1);
    }
    p->symbol = zzs_strdup(text);
    
    return p;
}

/* create a new symbol table entry and add it to the symbol table */
Sym *
zzs_newadd(char *text)
{
    Sym *p = zzs_new(text);
    if ( p != NULL ) zzs_add(text, p);
    return p;
}

/* Add a string to the string table and return a pointer to it.
 * Bump the pointer into the string table to next avail position.
 */
char *
zzs_strdup(register char *s)
{
    register char *start=strp;

    while ( *s != '\0' )
    {
        if ( strp >= &(strings[strsize-2]) )
        {
            fprintf(stderr, "sym: string table overflow (%d chars)\n", strsize);
            exit(-1);
        }
        *strp++ = *s++;
    }
    *strp++ = '\0';

    return( start );
}
