//
//  BibItemClassDescription.h
//  BibDesk
//
//  Created by Sven-S. Porst on Sat Jul 10 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BibItem.h"
#import "BibField.h"

#define BibItemBasicObjects @"citeKey", @"pubDate", @"title", @"type", @"date", @"pubFields", @"bibTeXStrings", @"RTFValue", @"RSSValue"

@interface BibItem (Scripting) 

- (BibField *)valueInBibFieldsWithName:(NSString *)name;
- (NSArray *)bibFields;

- (BibAuthor*)valueInAuthorsWithName:(NSString*)name;

- (NSMutableDictionary *)fields;

- (void) setBibTeXString:(NSString*) btString;

// wrapping original methods 
- (NSDate*) ASDateCreated;
- (NSDate*) ASDateModified;

// more (pseudo) accessors for key-value coding
- (NSString*) remoteURL;
- (void) setRemoteURL:(NSString*) newURL;

- (NSString*) localURL;
- (void) setLocalURL:(NSString*) newURL;

- (NSString*) abstract;
- (void) setAbstract:(NSString*) newAbstract;

- (NSString*) annotation;
- (void) setAnnotation:(NSString*) newAnnotation;

- (NSString*) RSSDescription;
- (void) setRSSDescription:(NSString*) newDesc; 

- (NSString *)keywords;
- (void)setKeywords:(NSString *)keywords;

- (NSScriptObjectSpecifier *) objectSpecifier;


@end




