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
#import "NSString+XMLUtils.h"
#import "BibPrefController.h"
@class BibPersonController;
@class BibItem;


/*!
    @class BibAuthor
    @abstract Modeling authors as objects that can have interesting relationships
    @discussion none.
*/
@interface BibAuthor : NSObject <NSCopying, NSCoding> {
    NSString *name;
    NSString *firstName;
    NSString *vonPart;
    NSString *lastName;
    NSString *jrPart;
    NSString *normalizedName;
    NSString *sortableName;
    BibPersonController *personController; // unretained
    BibItem *publication;
}

+ (BibAuthor *)authorWithName:(NSString *)name andPub:(BibItem *)aPub;

// maybe this should be 'and pubs'
- (id)initWithName:(NSString *)aName andPub:(BibItem *)aPub;
- (void)dealloc;

- (NSComparisonResult)compare:(BibAuthor *)otherAuth;
- (NSComparisonResult)fuzzyCompare:(BibAuthor *)otherAuth;

/*!
    @method     sortCompare:
    @abstract   Used for comparing authors based on "Lastname Firstname" with no comma separator, von part, or jr part.  From user feedback, it appears that
                "de Wit" should be sorted with "Witten", not with "Dewar."  Used for tableview sorting.
    @discussion (comprehensive description)
    @param      otherAuth (description)
    @result     (description)
*/
- (NSComparisonResult)sortCompare:(BibAuthor *)otherAuth;

- (NSString *)description;
- (NSString *)normalizedName;
- (void)refreshNormalizedName;
- (NSString *)sortableName;
- (void)refreshSortableName;
- (NSString *)name;
- (NSString *)firstName;
- (NSString *)vonPart;
- (NSString *)lastName;
- (NSString *)jrPart;

- (NSString *)MODSStringWithRole:(NSString *)rel;

- (BibItem *)publication;
- (void)setPublication:(BibItem *)newPub;

- (BibPersonController *)personController;
- (void)setPersonController:(BibPersonController *)newPersonController;

- (void)setName:(NSString *)newName;

@end
