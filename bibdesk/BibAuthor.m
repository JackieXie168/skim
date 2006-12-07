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

+ (BibAuthor *)authorWithName:(NSString *)newName andPub:(BibItem *)aPub{
    return [[[BibAuthor alloc] initWithName:newName andPub:aPub] autorelease];
}

- (id)initWithName:(NSString *)aName andPub:(BibItem *)aPub{
    [self setName:aName];
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

- (BOOL)isEqual:(BibAuthor *)otherAuth{
    return [name isEqualToString:[otherAuth name]];
}

- (unsigned)hash{
    return [name hash];
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
    return [NSString stringWithFormat:@"[%@_%@_%@_%@]", _firstName,_vonPart,_lastName,_jrPart];
}

- (NSString *)name{
    return name;
}

- (NSString *)firstName{
    return _firstName;
}

- (NSString *)vonPart{
    return _vonPart;
}

- (NSString *)lastName{
    return _lastName;
}

- (NSString *)jrPart{
    return _jrPart;
}

// bt_namepart: BTN_FIRST, BTN_VON, BTN_LAST, BTN_JR, BTN_NONE

- (void)setName:(NSString *)newName{
    bt_name *theName;
    int i = 0;
    NSMutableString *tmpStr = nil;
    
	if(newName != name){
		[name release];
		name = [newName copy];
    }
	
	unichar *nameCharacters = (unichar *)malloc([name length] * sizeof(unichar));
	[name getCharacters:nameCharacters];
    	
	theName = bt_split_name(nameCharacters,"",0,0);
    
    // get tokens from first part
    tmpStr = [NSMutableString string];
    for (i = 0; i < theName->part_len[BTN_FIRST]; i++)
    {
        [tmpStr appendString:[NSString stringWithCString:theName->parts[BTN_FIRST][i]]];
        if(i >= 0 && i < theName->part_len[BTN_FIRST]-1)
            [tmpStr appendString:@" "];
    }
    _firstName = [tmpStr retain];
    
    // get tokens from von part
    tmpStr = [NSMutableString string];
    for (i = 0; i < theName->part_len[BTN_VON]; i++)
    {
        [tmpStr appendString:[NSString stringWithCString:theName->parts[BTN_VON][i]]];
        if(i >= 0 && i < theName->part_len[BTN_VON]-1)
            [tmpStr appendString:@" "];

    }
    _vonPart = [tmpStr retain];
    
    // get tokens from last part
    tmpStr = [NSMutableString string];
    for (i = 0; i < theName->part_len[BTN_LAST]; i++)
    {
        [tmpStr appendString:[NSString stringWithCString:theName->parts[BTN_LAST][i]]];
        if(i >= 0 && i < theName->part_len[BTN_LAST]-1)
            [tmpStr appendString:@" "];
    }
    _lastName = [tmpStr retain];
    
    // get tokens from jr part
    tmpStr = [NSMutableString string];    
    for (i = 0; i < theName->part_len[BTN_JR]; i++)
    {
        [tmpStr appendString:[NSString stringWithCString:theName->parts[BTN_JR][i]]];
        if(i >= 0 && i < theName->part_len[BTN_JR]-1)
            [tmpStr appendString:@" "];
    }
    _jrPart = [tmpStr retain];
    
	bt_free_name(theName);
	free(nameCharacters);
}

- (BibItem *)pubAtIndex:(int)index{
    return [pubs objectAtIndex: index];
}
- (void)addPub:(BibItem *)pub{
    if(![pubs containsObject:pub]){
        [pubs addObject: pub];
    }
}
- (void)removePubFromAuthorList:(BibItem *)pub{
    [pubs removeObjectIdenticalTo:pub];
}
@end
