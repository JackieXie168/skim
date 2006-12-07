//
//  BDSKPublication.m
//  bd2xtest
//
//  Created by Michael McCracken on 7/17/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKPublication.h"
#import "BDSKDataModelNames.h"


@implementation BDSKPublication

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"title", nil]
        triggerChangeNotificationsForDependentKey:@"name"];
}

- (id)initWithEntity:(NSEntityDescription*)entity insertIntoManagedObjectContext:(NSManagedObjectContext*)context{
	if (self = [super initWithEntity:entity insertIntoManagedObjectContext:context]) {
		[self addObserver:self forKeyPath:@"contributorRelationships" options:0 context:NULL];
	}
	return self;
}

- (void)dealloc{
	[self removeObserver:self forKeyPath:@"contributorRelationships"];
	[super dealloc];
}

#pragma mark Accessors

- (NSString *)name {
    return [self valueForKey:@"title"];
}

- (void)setName:(NSString *)value {
    [self setValue:value forKey:@"title"];
}

- (NSSet *)authors {
    return [self contributorsOfType:@"author"];
}

- (NSSet *)editors {
    return [self contributorsOfType:@"editor"];
}

- (NSSet *)institutions {
    static NSPredicate *institutionPredicate = nil;
    if (institutionPredicate == nil) {
        institutionPredicate = [[NSPredicate predicateWithFormat:@"contributor.entity.name == %@", InstitutionEntityName] retain];
    }
    NSSet *relationships = [self valueForKey:@"contributorRelationships"];
    NSMutableSet *institutions = [[NSMutableSet alloc] initWithCapacity:[relationships count]];
    NSEnumerator *relationshipEnum = [relationships objectEnumerator];
    id relationship;
    
    while (relationship = [relationshipEnum nextObject]) {
        if ([institutionPredicate evaluateWithObject:relationship] == YES) 
            [institutions addObject:[relationship valueForKey:@"contributor"]];
    }
    return [institutions autorelease];
}

- (NSSet *)contributorsOfType:(NSString *)type {
    static NSMutableDictionary *contributorPredicates = nil;
    if (contributorPredicates == nil) {
        contributorPredicates = [[NSMutableDictionary alloc] initWithCapacity:1];
    }
    NSPredicate *predicate = [contributorPredicates objectForKey:type];
    if (predicate == nil) {
        predicate = [NSPredicate predicateWithFormat:@"relationshipType like[c] %@", type];
        [contributorPredicates setObject:predicate forKey:type];
    }
    NSSet *relationships = [self valueForKey:@"contributorRelationships"];
    NSMutableSet *contributors = [[NSMutableSet alloc] initWithCapacity:[relationships count]];
    NSEnumerator *relationshipEnum = [relationships objectEnumerator];
    id relationship;
    
    while (relationship = [relationshipEnum nextObject]) {
        if ([predicate evaluateWithObject:relationship] == YES) 
            [contributors addObject:[relationship valueForKey:@"contributor"]];
    }
    return [contributors autorelease];
}

- (id)valueForUndefinedKey:(NSString *)key {
    if ([key hasPrefix:@"contributors/"]) {
        return [self contributorsOfType:[key substringFromIndex:13]];
    } else {
        NSEnumerator *pairEnum = [[self valueForKey:@"keyValuePairs"] objectEnumerator];
        id pair;
        
        while (pair = [pairEnum nextObject]) {
            if ([[pair valueForKey:@"key"] caseInsensitiveCompare:key] == NSOrderedSame)
                return [pair valueForKey:@"value"];
        }
    }
    return nil;
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqual:@"contributorRelationships"]) {
		switch ([[change objectForKey:NSKeyValueChangeKindKey] intValue]) {
			case NSKeyValueChangeSetting:
				// This should be handled when the value is set
				break;
			case NSKeyValueChangeInsertion:
				// this should be handled when the insertion is done
                /*
				do {
					NSSet *relationships = [self valueForKey:@"contributorRelationships"];
					unsigned i = [[[relationships allObjects] valueForKeyPath:@"@distinctUnionOfObjects.index"] count];
					if (i < [relationships count]) {
						NSEnumerator *relationshipE = [relationships objectEnumerator];
						NSManagedObject *relationship;
						NSNumber *number;
						while (relationship = [relationshipE nextObject]) {
							if ([relationship valueForKeyPath:@"index"] == nil) {
								number = [[NSNumber alloc] initWithInt:i++];
								[relationship setValue:number forKey:@"index"];
								[number release];
							}
						}
					}
				} while (0);
				*/
				break;
			case NSKeyValueChangeRemoval:
				do {
					NSMutableArray *relationships = [[[self valueForKey:@"contributorRelationships"] allObjects] mutableCopy];
					NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES];
					[relationships sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
					[sortDescriptor release];
					unsigned i, count = [relationships count];
					NSNumber *number;
					for (i = 0; i < count; i++) {
						number = [[NSNumber alloc] initWithInt:i];
						[[relationships objectAtIndex:i] setValue:number forKey:@"index"];
						[number release];
					}
					[relationships release];
				} while (0);
				break;
			case NSKeyValueChangeReplacement:
				// This should be handled when the items are replaced
				break;
		}
    }
}

@end
