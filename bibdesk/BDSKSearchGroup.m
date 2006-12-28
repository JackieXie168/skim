//
//  BDSKSearchGroup.m
//  Bibdesk
//
//  Created by Adam Maxwell on 12/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BDSKSearchGroup.h"
#import "BDSKEntrezGroupServer.h"
#import "BDSKZoomGroupServer.h"
#import "BDSKMacroResolver.h"
#import "NSImage+Toolbox.h"
#import "BDSKPublicationsArray.h"


@implementation BDSKSearchGroup

- (id)initWithName:(NSString *)aName;
{
    return [self initWithType:BDSKSearchGroupEntrez serverInfo:[NSDictionary dictionaryWithObject:aName forKey:@"database"] searchTerm:nil];
}

- (id)initWithType:(int)aType serverInfo:(NSDictionary *)info searchTerm:(NSString *)string;
{
    NSString *aName = [info objectForKey:@"database"];
    if (aName == nil)
        aName = string;
    if (aName == nil)
        aName = NSLocalizedString(@"Empty", @"Name for empty search group");
    if (self = [super initWithName:aName count:0]) {
        type = aType;
        searchTerm = [string copy];
        publications = nil;
        macroResolver = [[BDSKMacroResolver alloc] initWithOwner:self];
        [self resetServerWithInfo:info];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)groupDict {
    NSEnumerator *keyEnum = [groupDict keyEnumerator];
    NSString *key;
    id value;
    NSMutableDictionary *info = [groupDict mutableCopy];
    
    while (key = [keyEnum nextObject]) {
        value = [groupDict objectForKey:key];
        if ([value respondsToSelector:@selector(stringByUnescapingGroupPlistEntities)])
            [info setObject:[value stringByUnescapingGroupPlistEntities] forKey:key];
    }
    
    int aType = [[info objectForKey:@"type"] intValue];
    NSString *aSearchTerm = [info objectForKey:@"searchTerm"];
    [info removeObjectForKey:@"type"];
    [info removeObjectForKey:@"search term"];
    
    self = [self initWithType:aType serverInfo:info searchTerm:aSearchTerm];
    [info release];
    return self;
}

- (NSDictionary *)dictionaryValue {
    NSDictionary *info = [server serverInfo];
    NSEnumerator *keyEnum = [info keyEnumerator];
    NSString *key;
    id value;
    NSMutableDictionary *groupDict = [info mutableCopy];
    
    while (key = [keyEnum nextObject]) {
        value = [info objectForKey:key];
        if ([value respondsToSelector:@selector(stringByEscapingGroupPlistEntities)])
            [groupDict setObject:[value stringByEscapingGroupPlistEntities] forKey:key];
    }
    
    [groupDict setObject:[NSNumber numberWithInt:[self type]] forKey:@"type"];
    [groupDict setObject:[self searchTerm] forKey:@"search term"];
    
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
    [publications makeObjectsPerformSelector:@selector(setOwner:) withObject:nil];
    [server terminate];
    [server release];
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
    return [NSString stringWithFormat:@"<%@ %p>: {\n\tis downloading: %@\n\tname: %@\ntype: %i\nserverInfo: %@\n }", [self class], self, ([self isRetrieving] ? @"yes" : @"no"), [self name], [self type], [self serverInfo]];
}

#pragma mark BDSKGroup overrides

// note that pointer equality is used for these groups, so names can overlap, and users can have duplicate searches

- (NSImage *)icon { return [NSImage smallImageNamed:@"searchFolderIcon"]; }

- (NSString *)name { return [NSString isEmptyString:[self searchTerm]] ? NSLocalizedString(@"Empty", @"Name for empty search group") : [self searchTerm]; }

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

- (void)resetServerWithInfo:(NSDictionary *)info {
    [server terminate];
    [server release];
    if (type == BDSKSearchGroupEntrez)
        server = [[BDSKEntrezGroupServer alloc] initWithGroup:self serverInfo:info];
    else if (type == BDSKSearchGroupZoom)
        server = [[BDSKZoomGroupServer alloc] initWithGroup:self serverInfo:info];
    else
        OBASSERT_NOT_REACHED("unknown search group type");
}

- (void)search;
{
    if ([self isRetrieving])
        [server terminate];
    
    [server setNumberOfAvailableResults:0];
    [server setNumberOfFetchedResults:0];
    [server setNeedsReset:YES];
    
    if ([NSString isEmptyString:[self searchTerm]]) {
        [self setPublications:[NSArray array]];
    } else {
        [self setPublications:nil];
        [server retrievePublications];
        
        // use this to notify the tableview to start the progress indicators and disable the button
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"succeeded"];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKSearchGroupUpdatedNotification object:self userInfo:userInfo];
    }
}

- (void)searchNext;
{
    if ([self isRetrieving])
        return;
    
    if ([NSString isEmptyString:[self searchTerm]]) {
        [server setNumberOfAvailableResults:0];
        [server setNumberOfFetchedResults:0];
        [self setPublications:[NSArray array]];
    } else {
        [server retrievePublications];
        
        // use this to notify the tableview to start the progress indicators and disable the button
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"succeeded"];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKSearchGroupUpdatedNotification object:self userInfo:userInfo];
    }
}

#pragma mark Accessors

- (int)type { return type; }

- (NSDictionary *)serverInfo { return [server serverInfo]; }

- (void)setServerInfo:(NSDictionary *)info;
{
    int newType = [[info objectForKey:@"type"] intValue];
    if(newType != type){
        type = newType;
        [self resetServerWithInfo:info];
    } else
        [server setServerInfo:info];
}

- (void)setSearchTerm:(NSString *)aTerm;
{
    if ([aTerm isEqualToString:searchTerm] == NO) {
        [searchTerm autorelease];
        searchTerm = [aTerm copy];
        
        [self search];
    }
}

- (NSString *)searchTerm { return searchTerm; }

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
