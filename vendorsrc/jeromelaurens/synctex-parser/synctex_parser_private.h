/*
 Copyright (c) 2017 jerome DOT laurens AT u-bourgogne DOT fr
 
 This file is part of the SyncTeX package.
 
 Latest Revision: Tue Jun 14 08:23:30 UTC 2011
 
 Version: 1.19
 
 See synctex_parser_readme.txt for more details
 
 License:
 --------
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE
 
 Except as contained in this notice, the name of the copyright holder
 shall not be used in advertising or otherwise to promote the sale,
 use or other dealings in this Software without prior written
 authorization from the copyright holder.
 */

#include "synctex_parser.h"
#include "synctex_parser_utils.h"

#ifndef __SYNCTEX_PARSER_PRIVATE__
#   define __SYNCTEX_PARSER_PRIVATE__

#ifdef __cplusplus
extern "C" {
#endif
    /*  Each node of the tree, except the scanner itself belongs to a class.
     *  The class object is just a struct declaring the owning scanner
     *  This is a pointer to the scanner as root of the tree.
     *  The type is used to identify the kind of node.
     *  The class declares pointers to a creator and a destructor method.
     *  The log and display fields are used to log and display the node.
     *  display will also display the child, sibling and parent sibling.
     *  parent, child and sibling are used to navigate the tree,
     *  from TeX box hierarchy point of view.
     *  The friend field points to a method which allows to navigate from friend to friend.
     *  A friend is a node with very close tag and line numbers.
     *  Finally, the info field point to a method giving the private node info offset.
     */
    
    /**
     *  These are the masks for the synctex node types.
     *  int's are 32 bits at leats.
     */
    enum {
        synctex_shift_root,
        synctex_shift_no_root,
        synctex_shift_void,
        synctex_shift_no_void,
        synctex_shift_box,
        synctex_shift_no_box,
        synctex_shift_proxy,
        synctex_shift_no_proxy,
        synctex_shift_h,
        synctex_shift_v
    };
    enum {
        synctex_mask_root      = 1,
        synctex_mask_no_root   = synctex_mask_root<<1,
        synctex_mask_void      = synctex_mask_no_root<<1,
        synctex_mask_no_void   = synctex_mask_void<<1,
        synctex_mask_box       = synctex_mask_no_void<<1,
        synctex_mask_no_box    = synctex_mask_box<<1,
        synctex_mask_proxy     = synctex_mask_no_box<<1,
        synctex_mask_no_proxy  = synctex_mask_proxy<<1,
        synctex_mask_h         = synctex_mask_no_proxy<<1,
        synctex_mask_v         = synctex_mask_h<<1,
    };
    enum {
        synctex_mask_non_void_hbox = synctex_mask_no_void
        | synctex_mask_box
        | synctex_mask_h,
        synctex_mask_non_void_vbox = synctex_mask_no_void
        | synctex_mask_box
        | synctex_mask_v
    };
    typedef enum {
        synctex_node_mask_sf =
        synctex_mask_root
        |synctex_mask_no_void
        |synctex_mask_no_box
        |synctex_mask_no_proxy,
        synctex_node_mask_vbox =
        synctex_mask_no_root
        |synctex_mask_no_void
        |synctex_mask_box
        |synctex_mask_no_proxy
        |synctex_mask_v,
        synctex_node_mask_hbox =
        synctex_mask_no_root
        |synctex_mask_no_void
        |synctex_mask_box
        |synctex_mask_no_proxy
        |synctex_mask_h,
        synctex_node_mask_void_vbox =
        synctex_mask_no_root
        |synctex_mask_void
        |synctex_mask_box
        |synctex_mask_no_proxy
        |synctex_mask_v,
        synctex_node_mask_void_hbox =
        synctex_mask_no_root
        |synctex_mask_void
        |synctex_mask_box
        |synctex_mask_no_proxy
        |synctex_mask_h,
        synctex_node_mask_vbox_proxy =
        synctex_mask_no_root
        |synctex_mask_no_void
        |synctex_mask_box
        |synctex_mask_proxy
        |synctex_mask_v,
        synctex_node_mask_hbox_proxy =
        synctex_mask_no_root
        |synctex_mask_no_void
        |synctex_mask_box
        |synctex_mask_proxy
        |synctex_mask_h,
        synctex_node_mask_nvnn =
        synctex_mask_no_root
        |synctex_mask_void
        |synctex_mask_no_box
        |synctex_mask_no_proxy,
        synctex_node_mask_input =
        synctex_mask_root
        |synctex_mask_void
        |synctex_mask_no_box
        |synctex_mask_no_proxy,
        synctex_node_mask_proxy =
        synctex_mask_no_root
        |synctex_mask_void
        |synctex_mask_no_box
        |synctex_mask_proxy
    } synctex_node_mask_t;

    enum {
        /* input */
        synctex_tree_sibling_idx        =  0,
        synctex_tree_s_input_max        =  1,
        /* All */
        synctex_tree_s_parent_idx       =  1,
        synctex_tree_sp_child_idx       =  2,
        synctex_tree_spc_target_idx     =  3,
        synctex_tree_spc_friend_idx     =  3,
        synctex_tree_spcf_last_idx      =  4,
        synctex_tree_spcfl_vbox_max     =  5,
        /* hbox supplement */
        synctex_tree_spcfl_next_hbox_idx    =  5,
        synctex_tree_spcfln_hbox_max        =  6,
        /* hbox proxy supplement */
        synctex_tree_spcfln_target_idx          =  6,
        synctex_tree_spcflnt_hbox_proxy_max     =  7,
        /* vbox proxy supplement */
        synctex_tree_spcfl_target_idx       =  5,
        synctex_tree_spcflt_vbox_proxy_max  =  6,
        /*  spf supplement*/
        synctex_tree_sp_friend_idx      =  2,
        synctex_tree_spf_max            =  3,
        /*  box boundary supplement */
        synctex_tree_spf_arg_sibling_idx    =  3,
        synctex_tree_spfa_max               =  4,
        /*  proxy supplement */
        synctex_tree_spf_target_idx     =  4,
        synctex_tree_spft_proxy_max     =  5,
        /*  last proxy supplement */
        synctex_tree_spfa_target_idx        =  4,
        synctex_tree_spfat_last_proxy_max   =  5,
        /* sheet supplement */
        synctex_tree_s_child_idx        =  1,
        synctex_tree_sc_next_hbox_idx   =  2,
        synctex_tree_scn_sheet_max      =  3,
        /* form supplement */
        synctex_tree_sc_target_idx      =  2,
        synctex_tree_sct_form_max       =  3,
        /* spct */
        synctex_tree_spct_result_max    =  4,
    };
    
    enum {
        /* input */
        synctex_data_input_tag_idx  =  0,
        synctex_data_input_line_idx =  1,
        synctex_data_input_name_idx =  2,
        synctex_data_input_tln_max  =  3,
        /* sheet */
        synctex_data_sheet_page_idx =  0,
        synctex_data_p_sheet_max    =  1,
        /* form */
        synctex_data_form_tag_idx   =  0,
        synctex_data_t_form_max     =  1,
        /* tlchv */
        synctex_data_tag_idx        =  0,
        synctex_data_line_idx       =  1,
        synctex_data_column_idx     =  2,
        synctex_data_h_idx          =  3,
        synctex_data_v_idx          =  4,
        synctex_data_tlchv_max      =  5,
        /* tlchvw */
        synctex_data_width_idx      =  5,
        synctex_data_tlchvw_max     =  6,
        /* box */
        synctex_data_height_idx     =  6,
        synctex_data_depth_idx      =  7,
        synctex_data_box_max        =  8,
        /* hbox supplement */
        synctex_data_mean_line_idx  =  8,
        synctex_data_weight_idx     =  9,
        synctex_data_h_V_idx        = 10,
        synctex_data_v_V_idx        = 11,
        synctex_data_width_V_idx    = 12,
        synctex_data_height_V_idx   = 13,
        synctex_data_depth_V_idx    = 14,
        synctex_data_hbox_max       = 15,
        /* ref */
        synctex_data_ref_tag_idx    =  0,
        synctex_data_ref_h_idx      =  1,
        synctex_data_ref_v_idx      =  2,
        synctex_data_ref_thv_max    =  3,
        /* proxy */
        synctex_data_proxy_h_idx    =  0,
        synctex_data_proxy_v_idx    =  1,
        synctex_data_proxy_hv_max   =  2,
    };

    /*  each synctex node has a class */
    typedef struct synctex_class_t synctex_class_s;
    typedef synctex_class_s * synctex_class_p;
    
    
    /*  synctex_node_p is a pointer to a node
     *  synctex_node_s is the target of the synctex_node_p pointer
     *  It is a pseudo object oriented program.
     *  class is a pointer to the class object the node belongs to.
     *  implementation is meant to contain the private data of the node
     *  basically, there are 2 kinds of information: navigation information and
     *  synctex information. Both will depend on the type of the node,
     *  thus different nodes will have different private data.
     *  There is no inheritancy overhead.
     */
    typedef union {
        synctex_node_p as_node;
        int    as_integer;
        char * as_string;
        void * as_pointer;
    } synctex_data_u;
    typedef synctex_data_u * synctex_data_p;
    
#   if defined(SYNCTEX_USE_CHARINDEX)
    typedef unsigned int synctex_charindex_t;
    synctex_charindex_t synctex_node_charindex(synctex_node_p node);
    typedef synctex_charindex_t synctex_lineindex_t;
    synctex_lineindex_t synctex_node_lineindex(synctex_node_p node);
#       define SYNCTEX_DECLARE_CHARINDEX \
synctex_charindex_t char_index;\
synctex_lineindex_t line_index;
#       define SYNCTEX_CHARINDEX(NODE) (NODE->char_index)
#       define SYNCTEX_LINEINDEX(NODE) (NODE->line_index)
#       define SYNCTEX_PRINT_CHARINDEX_FMT "#%i"
#       define SYNCTEX_PRINT_CHARINDEX_WHAT ,SYNCTEX_CHARINDEX(node)
#       define SYNCTEX_PRINT_CHARINDEX\
            printf(SYNCTEX_PRINT_CHARINDEX_FMT SYNCTEX_PRINT_CHARINDEX_WHAT)
#       define SYNCTEX_PRINT_LINEINDEX_FMT "L#%i"
#       define SYNCTEX_PRINT_LINEINDEX_WHAT ,SYNCTEX_LINEINDEX(node)
#       define SYNCTEX_PRINT_LINEINDEX\
            printf(SYNCTEX_PRINT_LINEINDEX_FMT SYNCTEX_PRINT_LINEINDEX_WHAT)
#       define SYNCTEX_PRINT_CHARINDEX_NL\
            printf(SYNCTEX_PRINT_CHARINDEX_FMT "\n" SYNCTEX_PRINT_CHARINDEX_WHAT)
#       define SYNCTEX_PRINT_LINEINDEX_NL\
            printf(SYNCTEX_PRINT_CHARINDEX_FMT "\n"SYNCTEX_PRINT_LINEINDEX_WHAT)
#       define SYNCTEX_DECLARE_CHAR_OFFSET synctex_charindex_t charindex_offset
#       define SYNCTEX_IMPLEMENT_CHARINDEX(NODE,CORRECTION)\
NODE->char_index = (synctex_charindex_t)(scanner->charindex_offset+SYNCTEX_CUR-SYNCTEX_START+(CORRECTION)); \
NODE->line_index = scanner->line_number
#   else
#       define SYNCTEX_DECLARE_CHARINDEX
#       define SYNCTEX_CHARINDEX(NODE) 0
#       define SYNCTEX_LINEINDEX(NODE) 0
#       define SYNCTEX_PRINT_CHARINDEX_FMT
#       define SYNCTEX_PRINT_CHARINDEX_WHAT
#       define SYNCTEX_PRINT_CHARINDEX
#       define SYNCTEX_PRINT_CHARINDEX
#       define SYNCTEX_PRINT_LINEINDEX_FMT
#       define SYNCTEX_PRINT_LINEINDEX_WHAT
#       define SYNCTEX_PRINT_LINEINDEX
#       define SYNCTEX_PRINT_CHARINDEX_NL printf("\n")
#       define SYNCTEX_PRINT_LINEINDEX_NL printf("\n")
#       define SYNCTEX_DECLARE_CHAR_OFFSET
#       define SYNCTEX_IMPLEMENT_CHARINDEX(NODE,CORRECTION)
#   endif
    struct synctex_node_t {
        SYNCTEX_DECLARE_CHARINDEX
        synctex_class_p class;
#ifdef DEBUG
        synctex_data_u data[22];
#else
        synctex_data_u data[1];
#endif
    };
    
    typedef synctex_node_p * synctex_node_r;
    
    typedef struct {
        int h;
        int v;
    } synctex_point_s;
    
    typedef synctex_point_s * synctex_point_p;
    
    typedef struct {
        synctex_point_s min;   /* top left */
        synctex_point_s max;   /* bottom right */
    } synctex_box_s;
    
    typedef synctex_box_s * synctex_box_p;

    synctex_node_type_t synctex_node_type(synctex_node_p node);
    const char * synctex_node_isa(synctex_node_p node);
    
    void synctex_node_log(synctex_node_p node);
    void synctex_node_display(synctex_node_p node);
    
    /*  Given a node, access to the location in the synctex file where it is defined.
     */

    int synctex_node_tag(synctex_node_p node);
    int synctex_node_line(synctex_node_p node);
    int synctex_node_column(synctex_node_p node);
    int synctex_node_form_tag(synctex_node_p node);
    
    int synctex_node_mean_line(synctex_node_p node);
    int synctex_node_weight(synctex_node_p node);
    int synctex_node_child_count(synctex_node_p node);
    int synctex_node_sheet_page(synctex_node_p node);

    int synctex_node_h(synctex_node_p node);
    int synctex_node_v(synctex_node_p node);
    int synctex_node_width(synctex_node_p node);
    
    int synctex_node_box_h(synctex_node_p node);
    int synctex_node_box_v(synctex_node_p node);
    int synctex_node_box_width(synctex_node_p node);
    int synctex_node_box_height(synctex_node_p node);
    int synctex_node_box_depth(synctex_node_p node);
    
    int synctex_node_hbox_h(synctex_node_p node);
    int synctex_node_hbox_v(synctex_node_p node);
    int synctex_node_hbox_width(synctex_node_p node);
    int synctex_node_hbox_height(synctex_node_p node);
    int synctex_node_hbox_depth(synctex_node_p node);
    
    synctex_scanner_p synctex_scanner_new();
    synctex_node_p synctex_node_new(synctex_scanner_p scanner,synctex_node_type_t type);

    typedef struct synctex_iterator_t synctex_iterator_s;
    typedef synctex_iterator_s * synctex_iterator_p;
    synctex_iterator_p synctex_iterator_new_display(synctex_scanner_p scanner,const char *  name,int line,int column, int page_hint);
    synctex_iterator_p synctex_iterator_new_edit(synctex_scanner_p scanner,int page,float h,float v);
    void synctex_iterator_free(synctex_iterator_p iterator);
    synctex_bool_t synctex_iterator_has_next(synctex_iterator_p iterator);
    synctex_node_p synctex_iterator_next(synctex_iterator_p iterator);
    int synctex_iterator_reset(synctex_iterator_p iterator);
    int synctex_iterator_count(synctex_iterator_p iterator);

#if defined(SYNCTEX_DEBUG)
#   include "assert.h"
#   define SYNCTEX_ASSERT assert
#else
#   define SYNCTEX_ASSERT(UNUSED)
#endif

#if defined(SYNCTEX_TESTING)
#warning TESTING IS PROHIBITED
#if __clang__
#define __PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wformat-extra-args\"")
    
#define __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS _Pragma("clang diagnostic pop")
#else
#define __PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS
#define __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS
#endif
    
#   define SYNCTEX_TEST_BODY(condition, desc, ...) \
    do {				\
        __PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
        if (!(condition)) {		\
            printf("**** Test failed: %s\nfile %s\nfunction %s\nline %i\n",#condition,__FILE__,__FUNCTION__,__LINE__); \
            printf((desc), ##__VA_ARGS__); \
        }				\
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS \
    } while(0)
        
#   define SYNCTEX_TEST_PARAMETER(condition) SYNCTEX_TEST_BODY((condition), "Invalid parameter not satisfying: %s", #condition)
    
    int synctex_test_input(synctex_scanner_p scanner);
    int synctex_test_proxy(synctex_scanner_p scanner);
    int synctex_test_tree(synctex_scanner_p scanner);
    int synctex_test_page(synctex_scanner_p scanner);
    int synctex_test_result(synctex_scanner_p scanner);
    int synctex_test_display_query(synctex_scanner_p scanner);
#endif

#ifdef __cplusplus
}
#endif

#endif
