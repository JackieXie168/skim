/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: tabcomplete.c,v 1.17 2007/01/03 08:42:13 adam Exp $
 */

#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include <yaz/oid.h>
#include "tabcomplete.h"

/* ***************************************************************************
 *
 * generic completer 
 * 
 * ***************************************************************************/

char *complete_from_list(char* completions[], const char *text, int state)
{       
#if HAVE_READLINE_READLINE_H
    static int idx;
    
    if(!completions) return NULL;
    if(state==0) {
        idx = 0;
    }
    for(; completions[idx]; ++ idx) {
        if(!
#ifdef WIN32
           _strnicmp
#else
           strncasecmp
#endif              
           (completions[idx],text,strlen(text))) {
            ++idx; /* skip this entry on the next run */ 
            return (char*)strdup(completions[idx-1]);
        };
    };
#endif
    return NULL;
}


/* ***************************************************************************
 * 
 * code for getting a list of valid strings from the oid subsystem
 * 
 * ***************************************************************************/
   

typedef struct {
    oid_class oclass;
    char** values;
    size_t index;
    size_t max;
} oid_callback_t;

/*!
  This is the call back function given to oid_trav... it updates the list
  of pointers into the oid owned data 
*/

void oid_loader(struct oident* oid, void* data_)
{
    oid_callback_t* data=(oid_callback_t*) data_;
    
    
    if((oid->oclass == CLASS_GENERAL) || (oid->oclass == data->oclass)) {
        if(data->index==data->max) {
                        data->values=(char**)realloc(data->values,((data->max+1)*2)*sizeof(char*));
                        data->max=(data->max+1)*2 - 1;
        };
        data->values[data->index]=oid->desc;
        ++data->index;          
    }
}

char** build_list_for_oclass(oid_class oclass)
{ 
    oid_callback_t data;        
    data.values = (char **) calloc(10,sizeof(char*));
    data.index = 0;
    data.max = 9;
    data.oclass = oclass;
    
    oid_trav(oid_loader, &data);
    
    data.values[data.index]=0;
    return data.values;    
}

/* ***************************************************************************
 * 
 * the completer functions 
 * 
 * ***************************************************************************/

char* complete_querytype(const char *text, int state)
{
    char* querytypes[] = {"ccl2rpn","prefix","cclrpn","ccl","cql", 0};
    return complete_from_list(querytypes,text,state);  
}

char* complete_auto_reconnect(const char *text, int state)
{
    char* querytypes[] = {"on","off",0};
    return complete_from_list(querytypes,text,state);  
}


char* complete_format(const char* text, int state)
{
    char** list=build_list_for_oclass(CLASS_RECSYN);
    char* res=complete_from_list(list,text,state);  
    
    free(list); 
    return res;
}

char* complete_schema(const char* text, int state)
{
    char** list = build_list_for_oclass(CLASS_SCHEMA);
    char* res = complete_from_list(list,text,state);  
    
    free(list); 
    return res;
}


char* complete_attributeset(const char* text, int state)
{
    char** list = build_list_for_oclass(CLASS_ATTSET);
    char* res = complete_from_list(list,text,state);  
    
    free(list); 
    return res;
}


/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

