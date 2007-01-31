//
//  BDSKSearchGroup.m
//  Bibdesk
//
//  Created by Adam Maxwell on 12/23/06.
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
 
 - Neither the name of Christiaan Hofman nor the names of any
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

#import "BDSKSearchGroup.h"
#import "BDSKEntrezGroupServer.h"
#import "BDSKZoomGroupServer.h"
#import "BDSKOAIGroupServer.h"
#import "BDSKMacroResolver.h"
#import "NSImage+Toolbox.h"
#import "BDSKPublicationsArray.h"
#import "BDSKServerInfo.h"
#import <OmniFoundation/NSArray-OFExtensions.h>

NSString *BDSKSearchGroupEntrez = @"entrez";
NSString *BDSKSearchGroupZoom = @"zoom";
NSString *BDSKSearchGroupOAI = @"oai";

@implementation BDSKSearchGroup

- (id)initWithName:(NSString *)aName;
{
    return [self initWithType:BDSKSearchGroupEntrez serverInfo:[NSDictionary dictionaryWithObject:aName forKey:@"database"] searchTerm:nil];
}

- (id)initWithType:(NSString *)aType serverInfo:(BDSKServerInfo *)info searchTerm:(NSString *)string;
{
    NSString *aName = [info name];
    if (aName == nil)
        aName = [info database];
    if (aName == nil)
        aName = string;
    if (aName == nil)
        aName = NSLocalizedString(@"Empty", @"Name for empty search group");
    if (self = [super initWithName:aName count:0]) {
        type = [aType copy];
        searchTerm = [string copy];
        history = nil;
        publications = nil;
        macroResolver = [[BDSKMacroResolver alloc] initWithOwner:self];
        [self resetServerWithInfo:info];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)groupDict {
    NSString *aType = [groupDict objectForKey:@"type"];
    NSString *aSearchTerm = [groupDict objectForKey:@"search term"];
    NSArray *aHistory = [groupDict objectForKey:@"history"];
    BDSKServerInfo *serverInfo = [[BDSKServerInfo alloc] initWithType:aType dictionary:groupDict];
    
    if (self = [self initWithType:aType serverInfo:serverInfo searchTerm:aSearchTerm]) {
        [self setHistory:aHistory];
    }
    [serverInfo release];

    NSAssert2([groupDict objectForKey:@"class"] == nil || [NSClassFromString([groupDict objectForKey:@"class"]) isSubclassOfClass:[self class]], @"attempt to instantiate %@ instead of %@", [self class], [groupDict objectForKey:@"class"]);
    return self;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *groupDict = [[[self serverInfo] dictionaryValue] mutableCopy];
    
    [groupDict setValue:[self type] forKey:@"type"];
    [groupDict setValue:[self searchTerm] forKey:@"search term"];
    [groupDict setValue:[self history] forKey:@"history"];
    [groupDict setValue:NSStringFromClass([self class]) forKey:@"class"];
    
    return [groupDict autorelease];
}

- (id)initWithCoder:(NSCoder *)aCoder
{
    [NSException raise:BDSKUnimplementedException format:@"Instances of %@ do not conform to NSCoding", [self class]];
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [NSException raise:BDSKUnimplementedException format:@"Instances of %@ do not conform to NSCoding", [self class]];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [publications makeObjectsPerformSelector:@selector(setOwner:) withObject:nil];
    [publications release]; 
    [server terminate];
    [server release];
    [type release];
    [searchTerm release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other { return self == other; }

- (unsigned int)hash {
    return( ((unsigned int) self >> 4) | (unsigned int) self << (32 - 4));
}

// Logging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@ %p>: {\n\tis downloading: %@\n\tname: %@\ntype: %@\nserverInfo: %@\n }", [self class], self, ([self isRetrieving] ? @"yes" : @"no"), [self name], [self type], [self serverInfo]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification{
    [server terminate];
    [server release];
    server = nil;
}

#pragma mark BDSKGroup overrides

// note that pointer equality is used for these groups, so names can overlap, and users can have duplicate searches

- (NSImage *)icon { return [NSImage smallImageNamed:@"searchFolderIcon"]; }

- (NSString *)name {
    return [NSString isEmptyString:[self searchTerm]] ? NSLocalizedString(@"Empty", @"Name for empty search group") : [self searchTerm];
}

- (NSString *)toolTip {
    return [NSString stringWithFormat:@"%@: %@", [[self serverInfo] name] ? [[self serverInfo] name] : @"", [self name]];
}

- (BOOL)isSearch { return YES; }

- (BOOL)isExternal { return YES; }

- (BOOL)isEditable { return YES; }

- (BOOL)hasEditableName { return NO; }

- (BOOL)isRetrieving { return [server isRetrieving]; }

- (BOOL)failedDownload { return [server failedDownload]; }

- (BOOL)containsItem:(BibItem *)item {
    return [publications containsObject:item];
}

#pragma mark BDSKOwner protocol

- (BDSKPublicationsArray *)publications;
{
    if([self isRetrieving] == NO && publications == nil && [NSString isEmptyString:[self searchTerm]] == NO){
        // get initial batch of publications
        [server retrievePublications];
        
        // use this to notify the tableview to start the progress indicators
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"succeeded"];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKSearchGroupUpdatedNotification object:self userInfo:userInfo];
    }
    // this posts a notification that the publications of the group changed, forcing a redisplay of the table cell
    return publications;
}

- (void)setPublications:(NSArray *)newPublications;
{
    if(newPublications != publications){
        [publications makeObjectsPerformSelector:@selector(setOwner:) withObject:nil];
        [publications release];
        publications = newPublications == nil ? nil : [[BDSKPublicationsArray alloc] initWithArray:newPublications];
        [publications makeObjectsPerformSelector:@selector(setOwner:) withObject:self];
        
        if (publications == nil)
            [macroResolver removeAllMacros];
    }
    
    [self setCount:[publications count]];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:(publications != nil)] forKey:@"succeeded"];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKSearchGroupUpdatedNotification object:self userInfo:userInfo];
}

- (void)addPublications:(NSArray *)newPublications;
{    
    if(newPublications != publications && newPublications != nil){
        
        if (publications == nil)
            publications = [[BDSKPublicationsArray alloc] initWithArray:newPublications];
        else 
            [publications addObjectsFromArray:newPublications];
        [newPublications makeObjectsPerformSelector:@selector(setOwner:) withObject:self];
    }
    
    [self setCount:[publications count]];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:(newPublications != nil)] forKey:@"succeeded"];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKSearchGroupUpdatedNotification object:self userInfo:userInfo];
}

- (BDSKMacroResolver *)macroResolver;
{
    return macroResolver;
}

- (NSUndoManager *)undoManager { return nil; }

- (NSURL *)fileURL { return nil; }

- (NSString *)documentInfoForKey:(NSString *)key { return nil; }

- (BOOL)isDocument { return NO; }

#pragma mark Searching

- (void)resetServerWithInfo:(BDSKServerInfo *)info {
    [server terminate];
    [server release];
    if ([type isEqualToString:BDSKSearchGroupEntrez])
        server = [[BDSKEntrezGroupServer alloc] initWithGroup:self serverInfo:info];
    else if ([type isEqualToString:BDSKSearchGroupZoom])
        server = [[BDSKZoomGroupServer alloc] initWithGroup:self serverInfo:info];
    else if ([type isEqualToString:BDSKSearchGroupOAI])
        server = [[BDSKOAIGroupServer alloc] initWithGroup:self serverInfo:info];
    else
        OBASSERT_NOT_REACHED("unknown search group type");
}

- (void)search;
{
    if ([self isRetrieving])
        return;
    
    // call this also for empty searchTerm, so the server can reset itself
    [server retrievePublications];
    
    // use this to notify the tableview to start the progress indicators and disable the button
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"succeeded"];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKSearchGroupUpdatedNotification object:self userInfo:userInfo];
}

- (void)reset;
{
    if ([self isRetrieving])
        [server stop];
    
    [server setNumberOfAvailableResults:0];
    [server setNumberOfFetchedResults:0];
    [self setPublications:[NSArray array]];
}

- (NSFormatter *)searchStringFormatter { return [server searchStringFormatter]; }

#pragma mark Accessors

- (NSString *)type { return type; }

- (BDSKServerInfo *)serverInfo { return [server serverInfo]; }

- (void)setServerInfo:(BDSKServerInfo *)info;
{
    NSString *newType = [info type];
    if([newType isEqualToString:type] == NO){
        [type release];
        type = [newType copy];
        [self resetServerWithInfo:info];
    } else
        [server setServerInfo:info];
    [self reset];
}

- (void)setSearchTerm:(NSString *)aTerm;
{
    // should this be undoable?
    
    if ([aTerm isEqualToString:searchTerm] == NO) {
        [searchTerm autorelease];
        searchTerm = [aTerm copy];
        
        [self reset];
        [self search];
    }
}

- (NSString *)searchTerm { return searchTerm; }

- (void)setHistory:(NSArray *)newHistory;
{
    if (history != newHistory) {
        [history release];
        history = [newHistory copy];
    }
}

- (NSArray *)history {return history; }

- (void)setNumberOfAvailableResults:(int)value;
{
    [server setNumberOfAvailableResults:value];
}

- (int)numberOfAvailableResults { return [server numberOfAvailableResults]; }

- (BOOL)hasMoreResults;
{
    return [server numberOfAvailableResults] > [server numberOfFetchedResults];
}

@end
