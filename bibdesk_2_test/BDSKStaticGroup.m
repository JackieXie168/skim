//
//  BDSKStaticGroup.m
//  bd2xtest
//
//  Created by Christiaan Hofman on 2/15/06.
//  Copyright 2006. All rights reserved.
//

#import "BDSKStaticGroup.h"
#import "BDSKDataModelNames.h"


@implementation BDSKStaticGroup 

+ (void)initialize {
    // we need to call super's implementation, even though the docs say not to, because otherwise we loose dependent keys
    [super initialize]; 
    [self setKeys:[NSArray arrayWithObjects:@"children", nil]
        triggerChangeNotificationsForDependentKey:@"isLeaf"];
}

#pragma mark Accessors

- (NSString *)groupImageName {
    return @"GroupIcon";
}

- (BOOL)isLeaf { return ([[self valueForKey:@"children"] count] == 0); }

- (BOOL)isStatic { return YES; }

- (BOOL)canAddItems { return YES; }

@end


@implementation BDSKFolderGroup 

+ (void)initialize {
    // we need to call super's implementation, even though the docs say not to, because otherwise we loose dependent keys
    [super initialize]; 
    [self setKeys:[NSArray arrayWithObjects:@"children", nil]
        triggerChangeNotificationsForDependentKey:@"isLeaf"];
    [self setKeys:[NSArray arrayWithObjects:@"children", nil]
        triggerChangeNotificationsForDependentKey:@"items"];
}

- (void)commonAwake {
    [self willAccessValueForKey:@"priority"];
    [self setValue:[NSNumber numberWithInt:2] forKeyPath:@"priority"];
    [self didAccessValueForKey:@"priority"];
}

- (void)awakeFromInsert  {
    [super awakeFromInsert];
    [self commonAwake];
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
    [self commonAwake];
}

#pragma mark Accessors

- (NSString *)groupImageName {
    return @"FolderGroupIcon";
}

- (BOOL)isLeaf { return ([[self valueForKey:@"children"] count] == 0); }

- (BOOL)isFolder { return YES; }

- (BOOL)canAddChildren { return YES; }

- (NSSet *)items {
    NSMutableSet *myPubs = [NSMutableSet setWithCapacity:10];
    NSSet *children = [self valueForKey:@"children"];
    NSEnumerator *childE = [children objectEnumerator];
    id child = nil;
    while (child = [childE nextObject]) {
        [myPubs unionSet:[child valueForKey:@"items"]];
    }
    return myPubs;
}

- (void)setItems:(NSSet *)newItems  { /* no-op */ }

@end
