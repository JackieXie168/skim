//  BibAuthor.m

//  Created by Michael McCracken on Wed Dec 19 2001.
/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

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
