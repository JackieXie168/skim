// 
//  BDSKGroup.m
//  bd2xtest
//
//  Created by Christiaan Hofman on 2/4/06.
//  Copyright 2006. All rights reserved.
//

#import "BDSKGroup.h"


@implementation BDSKGroup 

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"name", @"groupImageName", nil] 
        triggerChangeNotificationsForDependentKey:@"nameAndIcon"];
    [self setKeys:[NSArray arrayWithObjects:@"groupImageName", nil] 
        triggerChangeNotificationsForDependentKey:@"icon"];
    [self setKeys:[NSArray arrayWithObjects:@"parent", nil] 
        triggerChangeNotificationsForDependentKey:@"isRoot"];
}

- (NSString *)itemEntityName {
    NSString *entityName = nil;
    [self willAccessValueForKey:@"itemEntityName"];
    entityName = [self primitiveValueForKey:@"itemEntityName"];
    [self didAccessValueForKey:@"itemEntityName"];
    return entityName;
}

- (void)setItemEntityName:(NSString *)entityName {
    [self willChangeValueForKey: @"itemEntityName"];
    [self setPrimitiveValue:entityName forKey:@"itemEntityName"];
    [self didChangeValueForKey:@"itemEntityName"];
}

- (NSString *)groupImageName {
    return @"GroupIcon";
}

- (NSImage *)icon{
    if (cachedIcon == nil && [self groupImageName] != nil) {
        cachedIcon = [[NSImage imageNamed:[self groupImageName]] copy];
        [cachedIcon setScalesWhenResized:YES];
        [cachedIcon setSize:NSMakeSize(16, 16)];
    }
    return cachedIcon;
}

- (NSDictionary *)nameAndIcon{
    return [NSDictionary dictionaryWithObjectsAndKeys:[self valueForKey:@"name"], @"name", [self valueForKey:@"icon"], @"icon", nil];
}

- (void)setNameAndIcon:(NSString *)name{
    [self setValue:name forKey:@"name"];
}

- (BOOL)isRoot { return ([self valueForKey:@"parent"] == nil); }

- (BOOL)isLeaf { return NO; }

- (BOOL)isSmart { return NO; }

- (BOOL)isStatic { return NO; }

- (BOOL)isCategory { return NO; }

- (BOOL)isLibrary { return NO; }

- (BOOL)isFolder { return NO; }

- (BOOL)canAddChildren { return NO; }

- (BOOL)canAddItems { return NO; }

- (BOOL)canEdit { return NO; }

- (BOOL)canEditName { return YES; }

@end
