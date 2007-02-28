/*
 * Copyright (c) 1995-2007, Index Data
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Index Data nor the names of its contributors
 *       may be used to endorse or promote products derived from this
 *       software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/* $Id: cql.h,v 1.17 2007/01/03 08:42:14 adam Exp $ */

/** \file cql.h
    \brief Header with public definitions about CQL.
*/

#ifndef CQL_H_INCLUDED
#define CQL_H_INCLUDED
#include <stdio.h>
#include <yaz/nmem.h>

YAZ_BEGIN_CDECL

/** CQL parser handle */
typedef struct cql_parser *CQL_parser;

/**
 * Creates a CQL parser.
 * Returns CQL parser handle or NULL if parser could not be created.
 */
YAZ_EXPORT 
CQL_parser cql_parser_create(void);

/**
 * Destroys a CQL parser.
 *
 * This function does nothing if NULL if received.
 */
YAZ_EXPORT 
void cql_parser_destroy(CQL_parser cp);

/**
 * Parses a CQL string query.
 *
 * Returns 0 if on success; non-zero (error code) on failure.
 */
YAZ_EXPORT 
int cql_parser_string(CQL_parser cp, const char *str);

/**
 * Parses a CQL query - streamed query.
 *
 * This function is similar to cql_parser_string but takes a
 * functions to read each query character from a stream.
 *
 * The functions pointers getbytes, ungetbyte are similar to
 * that known from stdios getc, ungetc.
 *
 * Returns 0 if on success; non-zero (error code) on failure.
 */
YAZ_EXPORT 
int cql_parser_stream(CQL_parser cp,
                      int (*getbyte)(void *client_data),
                      void (*ungetbyte)(int b, void *client_data),
                      void *client_data);

/**
 * Parses a CQL query from a FILE handle.
 *
 * This function is similar to cql_parser_string but reads from 
 * stdio FILE handle instead.
 *
 * Returns 0 if on success; non-zero (error code) on failure.
 */
YAZ_EXPORT
int cql_parser_stdio(CQL_parser cp, FILE *f);

/**
 * The node in a CQL parse tree. 
 */
#define CQL_NODE_ST 1
#define CQL_NODE_BOOL 2
struct cql_node {
    /** node type */
    int which;
    union {
        /** which == CQL_NODE_ST */
        struct {
            /** CQL index */
            char *index;
            /** CQL index URI or NULL if no URI */
            char *index_uri;
            /** Search term */
            char *term;
            /** relation */
            char *relation;
            /** relation URL or NULL if no relation URI) */
            char *relation_uri;
            /** relation modifiers */
            struct cql_node *modifiers;
        } st;
        /** which == CQL_NODE_BOOL */
        struct {
            /** operator name "and", "or", ... */
            char *value;
            /** left operand */
            struct cql_node *left;
            /** right operand */ 
            struct cql_node *right;
            /** modifiers (NULL for no list) */
            struct cql_node *modifiers;
        } boolean;
    } u;
};

/**
 * Private structure that describes the CQL properties (profile)
 */
struct cql_properties;

/**
 * Structure used by cql_buf_write_handlre
 */
struct cql_buf_write_info {
    int max;
    int off;
    char *buf;
};

/**
 * Handler for cql_buf_write_info *
 */
YAZ_EXPORT
void cql_buf_write_handler (const char *b, void *client_data);

/**
 * Prints a CQL node and all sub nodes. Hence this function
 * prints the parse tree which is as returned by cql_parser_result.
 */
YAZ_EXPORT
void cql_node_print(struct cql_node *cn);

/**
 * This function creates a search clause node (st).
 */
YAZ_EXPORT
struct cql_node *cql_node_mk_sc(NMEM nmem, const char *index,
                                const char *relation, const char *term);

/**
 * This function applies a prefix+uri to "unresolved" index and relation
 * URIs.
 *
 * "unresolved" URIs are those nodes where member index_uri / relation_uri
 * is NULL.
 */
YAZ_EXPORT
struct cql_node *cql_apply_prefix(NMEM nmem, struct cql_node *cn,
                                  const char *prefix, const char *uri);

/**
 * This function creates a boolean node.
 */
YAZ_EXPORT
struct cql_node *cql_node_mk_boolean(NMEM nmem, const char *op);

/**
 * Destroys a node and its children.
 */
YAZ_EXPORT
void cql_node_destroy(struct cql_node *cn);

/**
 * Duplicate a node (returns a copy of supplied node) .
 */
YAZ_EXPORT
struct cql_node *cql_node_dup (NMEM nmem, struct cql_node *cp);

/**
 * This function returns the parse tree of the most recently parsed
 * CQL query.
 *
 * The function returns NULL if most recently parse failed.
 */
YAZ_EXPORT
struct cql_node *cql_parser_result(CQL_parser cp);

/**
 * This function converts a CQL node tree to XCQL and writes the
 * resulting XCQL to a user-defined output stream.
 */
YAZ_EXPORT
void cql_to_xml(struct cql_node *cn, 
                void (*pr)(const char *buf, void *client_data),
                void *client_data);
/**
 * This function converts a CQL node tree to XCQL and writes the
 * resulting XCQL to a FILE handle (stdio) 
 */
YAZ_EXPORT
void cql_to_xml_stdio(struct cql_node *cn, FILE *f);

/**
 * This function converts a CQL node tree to XCQL and writes
 * the resulting XCQL to a buffer 
 */
YAZ_EXPORT
int cql_to_xml_buf(struct cql_node *cn, char *out, int max);

/**
 * Utility function that prints to a FILE.
 */
YAZ_EXPORT
void cql_fputs(const char *buf, void *client_data);

/**
 * The CQL transform handle. The transform describes how to
 * convert from CQL to PQF (Type-1 AKA RPN).
 */
typedef struct cql_transform_t_ *cql_transform_t;

/**
 * Creates a CQL transform handle. The transformation spec is read from
 * a FILE handle (which is assumed opened in read mode).
 */
YAZ_EXPORT
cql_transform_t cql_transform_open_FILE (FILE *f);

/**
 * Creates a CQL transform handle. The transformation spec is read from
 * a file with the filename given.
 */
YAZ_EXPORT
cql_transform_t cql_transform_open_fname(const char *fname);

/**
 * Destroys a CQL transform handle.
 */
YAZ_EXPORT
void cql_transform_close(cql_transform_t ct);

/**
 * Performs a CQL transform to PQF given a CQL node tree and a CQL
 * transformation handle. The result is written to a user-defined stream.
 */
YAZ_EXPORT
void cql_transform_pr(cql_transform_t ct,
                      struct cql_node *cn,
                      void (*pr)(const char *buf, void *client_data),
                      void *client_data);

/**
 * Performs a CQL transform to PQF given a CQL node tree and a CQL
 * transformation handle. The result is written to a file specified by
 * FILE handle (which must be opened for writing).
 */
YAZ_EXPORT
int cql_transform_FILE(cql_transform_t ct,
                       struct cql_node *cn, FILE *f);

/**
 * Performs a CQL transform to PQF given a CQL node tree and a CQL
 * transformation handle. The result is written to a buffer. 
 */
YAZ_EXPORT
int cql_transform_buf(cql_transform_t ct,
                      struct cql_node *cn, char *out, int max);
/**
 * Returns error code and additional information from last transformation.
 * Performs a CQL transform given a CQL node tree and a CQL transformation.
 */
YAZ_EXPORT
int cql_transform_error(cql_transform_t ct, const char **addinfo);

/**
 * Returns the CQL message corresponding to a given error code.
 */
YAZ_EXPORT
const char *cql_strerror(int code);

/**
 * Returns the standard CQL context set URI.
 */
YAZ_EXPORT
const char *cql_uri(void);

/**
 * Compares two CQL strings (for relations, operators, etc)
 * (unfortunately defined as case-insensitive unlike XML etc)
 */
YAZ_EXPORT
int cql_strcmp(const char *s1, const char *s2);

/**
 * Compares two CQL strings at most n bytes
 * (unfortunately defined as case-insensitive unlike XML etc)
 */
YAZ_EXPORT
int cql_strncmp(const char *s1, const char *s2, size_t n);

YAZ_END_CDECL

#endif
/* CQL_H_INCLUDED */
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

