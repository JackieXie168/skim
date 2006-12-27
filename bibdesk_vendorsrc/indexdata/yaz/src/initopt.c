/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: initopt.c,v 1.6 2005/06/25 15:46:04 adam Exp $
 */

/**
 * \file initopt.c
 * \brief Implements Z39.50 Init Options Utility
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include "proto.h"

static struct {
    char *name;
    int opt;
} opt_array[] = {
    {"search", Z_Options_search},
    {"present", Z_Options_present},
    {"delSet", Z_Options_delSet},
    {"resourceReport", Z_Options_resourceReport},
    {"triggerResourceCtrl", Z_Options_triggerResourceCtrl},
    {"resourceCtrl", Z_Options_resourceCtrl},
    {"accessCtrl", Z_Options_accessCtrl},
    {"scan", Z_Options_scan},
    {"sort", Z_Options_sort},
    {"extendedServices", Z_Options_extendedServices},
    {"level_1Segmentation", Z_Options_level_1Segmentation},
    {"level_2Segmentation", Z_Options_level_2Segmentation},
    {"concurrentOperations", Z_Options_concurrentOperations},
    {"namedResultSets", Z_Options_namedResultSets},
    {"encapsulation", Z_Options_encapsulation},
    {"resultCount", Z_Options_resultCount},
    {"negotiationModel", Z_Options_negotiationModel},
    {"duplicationDetection", Z_Options_duplicateDetection},
    {"queryType104", Z_Options_queryType104},
    {"pQESCorrection", Z_Options_pQESCorrection},
    {"stringSchema", Z_Options_stringSchema},
    {0, 0}
};

int yaz_init_opt_encode(Z_Options *opt, const char *opt_str, int *error_pos)
{
    const char *cp = opt_str;
    
    ODR_MASK_ZERO(opt);
    while (*cp)
    {
        char this_opt[42];
        int i, j;
        if (*cp == ' ' || *cp == ',')
        {
            cp++;
            continue;
        }
        for (i = 0; i < (sizeof(this_opt)-1) &&
                 cp[i] && cp[i] != ' ' && cp[i] != ','; i++)
            this_opt[i] = cp[i];
        this_opt[i] = 0;
        for (j = 0; opt_array[j].name; j++)
        {
            if (yaz_matchstr(this_opt, opt_array[j].name) == 0)
            {
                ODR_MASK_SET(opt, opt_array[j].opt);
                break;
            }
        }
        if (!opt_array[j].name)
        {
            if (error_pos)
            {
                *error_pos = cp - opt_str;
                return -1;
            }
        }
        cp += i;
    }
    return 0;
}

void yaz_init_opt_decode(Z_Options *opt, void (*pr)(const char *name,
                                                    void *clientData),
                         void *clientData)
{
    int i;
    for (i = 0; opt_array[i].name; i++)
        if (ODR_MASK_GET(opt, opt_array[i].opt))
            (*pr)(opt_array[i].name, clientData);
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

