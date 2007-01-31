//
//  BDSKWebGroup.m
//  Bibdesk
//
//  Created by Michael McCracken on 1/25/07.

//

#import "BDSKWebGroup.h"
#import "BibPrefController.h"
#import "BDSKPublicationsArray.h"
#import "BDSKMacroResolver.h"
#import "NSImage+Toolbox.h"

@implementation BDSKWebGroup
- (id)initWithName:(NSString *)aName{
    
    NSAssert(aName != nil, @"BDSKWebGroup requires a name");

    if (self = [super initWithName:aName count:0]) {
        publications = nil;
        macroResolver = [[BDSKMacroResolver alloc] initWithOwner:self];

    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aCoder{
    [NSException raise:BDSKUnimplementedException format:@"Instances of %@ do not conform to NSCoding", [self class]];
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [NSException raise:BDSKUnimplementedException format:@"Instances of %@ do not conform to NSCoding", [self class]];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [publications makeObjectsPerformSelector:@selector(setOwner:) withObject:nil];
    [publications release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other { return self == other; }

- (unsigned int)hash {
    return( ((unsigned int) self >> 4) | (unsigned int) self << (32 - 4));
}

#pragma mark BDSKGroup overrides

// note that pointer equality is used for these groups, so names can overlap, and users can have duplicate searches

//TODO: need better image
- (NSImage *)icon { return [NSImage smallImageNamed:@"urlFolderIcon"]; }

- (NSString *)toolTip {
    return NSLocalizedString(@"Web", @"Web");
}

- (BOOL)isSearch { return NO; }

- (BOOL)isExternal { return YES; }

- (BOOL)isEditable { return NO; } 

- (BOOL)hasEditableName { return NO; }

- (BOOL)isRetrieving { return NO;}

- (BOOL)failedDownload { return NO;}

- (BOOL)containsItem:(BibItem *)item {
    return [publications containsObject:item];
}

#pragma mark BDSKOwner protocol

- (BDSKPublicationsArray *)publications{
    
    if([self isRetrieving] == NO && publications == nil){
        // get initial batch of publications
     //   [server retrievePublications];
        
        // use this to notify the tableview to start the progress indicators
   //     NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"succeeded"];
     //   [[NSNotificationCenter defaultCenter] postNotificationName:BDSKSearchGroupUpdatedNotification object:self userInfo:userInfo];
    }
    // this posts a notification that the publications of the group changed, forcing a redisplay of the table cell
    return publications;
}

- (void)setPublications:(NSArray *)newPublications{
    
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
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKWebGroupUpdatedNotification object:self userInfo:userInfo];
}

- (void)addPublications:(NSArray *)newPublications{    
    
    if(newPublications != publications && newPublications != nil){
        
        if (publications == nil)
            publications = [[BDSKPublicationsArray alloc] initWithArray:newPublications];
        else 
            [publications addObjectsFromArray:newPublications];
        [newPublications makeObjectsPerformSelector:@selector(setOwner:) withObject:self];
    }
    
    [self setCount:[publications count]];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:(newPublications != nil)] forKey:@"succeeded"];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKWebGroupUpdatedNotification object:self userInfo:userInfo];
}

- (BDSKMacroResolver *)macroResolver{
    return macroResolver;
}

- (NSUndoManager *)undoManager { return nil; }

- (NSURL *)fileURL { return nil; }

- (NSString *)documentInfoForKey:(NSString *)key { return nil; }

- (BOOL)isDocument { return NO; }

@end
