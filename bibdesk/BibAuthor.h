//  BibAuthor.h

//  Created by Michael McCracken on Wed Dec 19 2001.
//  Copyright (c) 2001 Michael McCracken. All rights reserved.
/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/*! @header BibAuthor.h
    @discussion declares an interface to author model objects
*/
#import <Cocoa/Cocoa.h>
@class BibItem;

/*!
    @class BibAuthor
    @abstract Modeling authors as objects that can have interesting relationships
    @discussion This isn't really used, but I think it has a lot of potential once I get the outlineview going on.
*/
@interface BibAuthor : NSObject {
    NSMutableArray *pubs;
    NSString *name;
}

// maybe this should be 'and pubs'
- (id)initWithName:(NSString *)aName andPub:(BibItem *)aPub;
- (void)dealloc;
- (void)setPubs:(NSArray *)newPubs;

- (int)numberOfChildren;
- (NSArray *)children;

- (NSString *)description;
- (NSString *)name;
- (void)setName:(NSString *)newName;

- (BibItem *)pubAtIndex:(int)index;
- (void)addPub:(BibItem *)pub;
- (void)removePubFromAuthorList:(BibItem *)pub;
@end
