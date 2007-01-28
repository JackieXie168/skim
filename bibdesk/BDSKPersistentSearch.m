//
//  BDSKPersistentSearch.m
//  Bibdesk
//
//  Created by Adam Maxwell on 03/17/06.
/*
 This software is Copyright (c) 2006,2007
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BDSKPersistentSearch.h"

static id sharedSearch = nil;
static void *nullQueryMarker = @"Null MDQuery Marker"; /* any CFTypeRef would work here */

@implementation BDSKPersistentSearch

+ (id)sharedSearch;
{
    if(sharedSearch == nil)
        sharedSearch = [[BDSKPersistentSearch alloc] init];
    return sharedSearch;
}

- (id)init
{    
    if(self = [super init])
        queries = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    return self;
}

- (void)dealloc
{
    CFRelease(queries);
    [super dealloc];
}

- (BOOL)hasQuery:(NSString *)queryString;
{ 
    NSParameterAssert(queryString != nil);
    return CFDictionaryContainsKey(queries, (CFStringRef)queryString);
}

- (BOOL)addQuery:(NSString *)queryString scopes:(NSArray *)searchScopes;
{
    NSParameterAssert(queryString != nil);
    BOOL success = YES;
    MDQueryRef mdQuery = NULL;
    
    if (CFDictionaryGetValueIfPresent(queries, (CFStringRef)queryString, (const void **)&mdQuery)) {
        
        // already present in the dictionary, so just modify the scope
        if (CFEqual(nullQueryMarker, mdQuery) == FALSE)
            MDQuerySetSearchScope(mdQuery, (CFArrayRef)searchScopes, 0);

    } else {
    
        mdQuery = MDQueryCreate(CFAllocatorGetDefault(), (CFStringRef)queryString, NULL, NULL);
    
        // mdQuery is NULL on failure
        if(mdQuery != NULL){
            MDQuerySetSearchScope(mdQuery, (CFArrayRef)searchScopes, 0);
        
            // create and execute an asynchronous query that will watch the file system for us
            // we currently ignore notifications; callers just take what they can get from resultsForQuery:attribute:
            if(MDQueryExecute(mdQuery, kMDQueryWantsUpdates))
                CFDictionaryAddValue(queries, (const void *)queryString, mdQuery);
            else
                success = NO;
            
            CFRelease(mdQuery);
        } else {
            success = NO;
            // add the bogus query, so we don't keep trying; a user reported beachballs when creating the query with a bad spotlight cache, so we'll just log a message and leave out this functionality
            CFDictionaryAddValue(queries, (const void *)queryString, nullQueryMarker);
#if OMNI_FORCE_ASSERTIONS
            // warning for developers, in case of using an incorrect query string
            NSRunAlertPanel([NSString stringWithFormat:@"Sorry, %@, I'm afraid I can't do that", NSUserName()], @"Either the query \"%@\" was not valid, or your Spotlight cache requires repair.", @"Doh!", nil, nil, [queryString safeFormatString]);
#else
            // log message for users,
            NSLog(@"Unable to execute Spotlight query \"%@\" with search scopes %@", [queryString safeFormatString], searchScopes);
#endif
        }
    }
    
    return success;
}

- (NSArray *)resultsForQuery:(NSString *)queryString attribute:(NSString *)attribute;
{
    MDQueryRef mdQuery = (MDQueryRef)CFDictionaryGetValue(queries, (CFStringRef)queryString);
    NSMutableArray *results = nil;
    
    if(mdQuery != NULL && CFEqual(nullQueryMarker, mdQuery) == FALSE){
        
        // supposed to disable updates before iterating results
        MDQueryDisableUpdates(mdQuery);
        CFIndex idx = MDQueryGetResultCount(mdQuery);
        results = [NSMutableArray arrayWithCapacity:idx];

        MDItemRef mdItem;
        CFTypeRef value;
        
        while(idx--){
            mdItem = (MDItemRef)MDQueryGetResultAtIndex(mdQuery, idx);
            value = MDItemCopyAttribute(mdItem, (CFStringRef)attribute);
            if(value){
                [results addObject:(id)value];
                CFRelease(value);
            }
        }
        MDQueryEnableUpdates(mdQuery);
    }
    
    return results;
}

@end
