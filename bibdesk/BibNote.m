//
//  BibNote.m
//  Bibdesk
//
//  Created by Michael McCracken on 2/11/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BibNote.h"


@implementation BibNote


// init
- (id)init {
    if (self = [super init]) {
		title = [[NSString alloc] initWithString:NSLocalizedString(@"New Note", @"New Note")];
        string = [[NSAttributedString alloc] initWithString:@""];
        keywords = [[NSArray alloc] init];
        url = nil;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[self title] forKey:@"title"];
    [coder encodeObject:[self string] forKey:@"string"];
    [coder encodeObject:[self keywords] forKey:@"keywords"];
    [coder encodeObject:[self url] forKey:@"url"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        [self setTitle:[coder decodeObjectForKey:@"title"]];
        [self setString:[coder decodeObjectForKey:@"string"]];
        [self setKeywords:[coder decodeObjectForKey:@"keywords"]];
        [self setUrl:[coder decodeObjectForKey:@"url"]];
    }
    return self;
}

- (NSString *)title { return [[title retain] autorelease]; }

- (void)setTitle:(NSString *)aTitle {
    //NSLog(@"in -setTitle:, old value of title: %@, changed to: %@", title, aTitle);
	
    [title release];
    title = [aTitle copy];
}

- (NSAttributedString *)string { return [[string retain] autorelease]; }

- (void)setString:(NSAttributedString *)aString {
    //NSLog(@"in -setString:, old value of string: %@, changed to: %@", string, aString);
	
    [string release];
    string = [aString copy];
}

- (NSArray *)keywords { return [[keywords retain] autorelease]; }

- (void)setKeywords:(NSArray *)aKeywords {
    //NSLog(@"in -setKeywords:, old value of keywords: %@, changed to: %@", keywords, aKeywords);
	
    [keywords release];
    keywords = [aKeywords copy];
}

- (NSURL *)url { return [[url retain] autorelease]; }

- (void)setUrl:(NSURL *)anUrl {
    //NSLog(@"in -setUrl:, old value of url: %@, changed to: %@", url, anUrl);
	
    [url release];
    url = [anUrl copy];
}


- (void)dealloc {
    [title release];
    [string release];
    [keywords release];
    [url release];
    [super dealloc];
}


@end
