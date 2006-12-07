//
//  BibAuthor.m
//  Bibdesk
//
//  Created by Michael McCracken on Wed Dec 19 2001.
//  Copyright (c) 2001 Michael McCracken. All rights reserved.
//

#import "BibAuthor.h"
#import "BibItem.h"

@implementation BibAuthor

- (id)initWithName:(NSString *)aName andPub:(BibItem *)aPub{
    name = [[NSString stringWithString:aName] retain];
    if(aPub)
        pubs = [[NSMutableArray arrayWithObject:aPub] retain];
    else
        pubs = [[NSMutableArray alloc] init];
    // NSLog(@"bibauthor init: %@", aName);
    return self;
}

- (void)dealloc{
    [name release];
    [pubs release];
    // NSLog(@"bibauthor dealloc");
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone{
    BibAuthor *copy = [[[self class] allocWithZone: zone] initWithName:[self name]
                                                                andPub:nil];
    [copy setPubs:pubs];
    return copy;
}

- (void)setPubs:(NSArray *)newPubs{
    [pubs autorelease];
    pubs = [newPubs mutableCopy];
}

- (int)numberOfChildren{
    return [pubs count];
}

- (NSArray *)children{
    return pubs;
}

- (NSString *)description{
    return [self name];
}

- (NSString *)name{
    return name;
}
- (void)setName:(NSString *)newName{
    [name autorelease];
    name = [newName copy];
}

- (BibItem *)pubAtIndex:(int)index{
    return [pubs objectAtIndex: index];
}
- (void)addPub:(BibItem *)pub{
    [pubs addObject: pub];
}
- (void)removePubFromAuthorList:(BibItem *)pub{
    [pubs removeObjectIdenticalTo:pub];
}
@end
