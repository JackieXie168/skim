//
//  BDSKPreviewItem.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 5/9/06.
/*
 This software is Copyright (c) 2006,2007
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BDSKPreviewItem.h"
#import "BibPrefController.h"
#import "BibAppController.h"
#import "BibAuthor.h"
#import "BDSKFormatParser.h"
#import "BibTypeManager.h"
#import "NSString_BDSKExtensions.h"
#import "NSArray_BDSKExtensions.h"
#import <OmniFoundation/NSString-OFExtensions.h>
#import <OmniFoundation/NSArray-OFExtensions.h>


@implementation BDSKPreviewItem

+ (BDSKPreviewItem *)sharedItem {
    id sharedItem = nil;
    if (sharedItem == nil)
        sharedItem = [[self alloc] init];
    return sharedItem;
}

- (id)init {
    if (self = [super init]) {
        pubFields = [[NSDictionary alloc] initWithObjectsAndKeys:
			NSLocalizedString(@"BibDesk, a great application to manage your bibliographies", @"Title for preview item in preferences"), BDSKTitleString, 
			@"McCracken, M. and Maxwell, A. and Hofman, C. M. and Porst, S. S. and Howison, J. and Routley, M. and Spiegel, S.", BDSKAuthorString, 
			@"2004", BDSKYearString, @"11", BDSKMonthString, 
			@"Source Forge", BDSKJournalString, @"1", BDSKVolumeString, @"96", BDSKPagesString, 
			NSLocalizedString(@"Keyword1,Keyword2", @"Keywords for preview item in preferences"), BDSKKeywordsString, 
			NSLocalizedString(@"Local File Name.pdf", @"Local-Url for preview item in preferences"), BDSKLocalUrlString, nil];
        pubAuthors = [[NSArray alloc] initWithObjects:
            [BibAuthor authorWithName:@"McCracken, M." andPub:nil], 
            [BibAuthor authorWithName:@"Maxwell, A." andPub:nil], 
            [BibAuthor authorWithName:@"Hofman, C. M." andPub:nil], 
            [BibAuthor authorWithName:@"Porst, S. S." andPub:nil], 
            [BibAuthor authorWithName:@"Howison, J." andPub:nil], 
            [BibAuthor authorWithName:@"Routley, M." andPub:nil], 
            [BibAuthor authorWithName:@"Spiegel, S." andPub:nil], nil];
    }
    return self;
}

- (void)dealloc {
    [pubFields release];
    [pubAuthors release];
    [super dealloc];
}

#pragma mark BibItem simulation

- (NSString *)fileType { return BDSKBibtexString; }

- (NSString *)pubType { return BDSKArticleString; }

- (NSString *)citeKey { return @"citeKey"; }

- (NSString *)title { return [pubFields objectForKey:BDSKTitleString]; }

- (NSString *)container { return [pubFields objectForKey:BDSKJournalString]; }

- (NSString *)stringValueOfField:(NSString *)field { 
    NSString *value = [pubFields objectForKey:field];
    return (value != nil) ? value : field;
}

- (int)intValueOfField:(NSString *)field { 
    if ([field isBooleanField] || [field isRatingField])
        return 0;
    else if ([field isTriStateField])
        return -1;
    else if ([pubFields objectForKey:field] != nil)
        return 1;
    else 
        return 0;
}

- (NSString *)localFilePathForField:(NSString *)field { return [pubFields objectForKey:field]; }

- (NSArray *)peopleArrayForField:(NSString *)field { 
    return ([field isEqualToString:BDSKAuthorString]) ? pubAuthors : [NSArray array];
}

- (NSString *)documentFileName { return NSLocalizedString(@"Document File Name", @"Document filename for preview item in preferences"); }

- (NSString *)documentInfoForKey:(NSString *)key { return key; }

- (BOOL)isValidCiteKey:(NSString *)key { return YES; }

- (BOOL)isValidLocalUrlPath:(NSString *)path { return YES; }

- (NSString *)suggestedLocalUrl {
    OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
	NSString *localUrlFormat = [pw objectForKey:BDSKLocalUrlFormatKey];
	NSString *papersFolderPath = [[NSApp delegate] folderPathForFilingPapersFromDocument:nil];
	NSString *relativeFile = [BDSKFormatParser parseFormat:localUrlFormat forField:BDSKLocalUrlString ofItem:self];
	if ([pw boolForKey:BDSKLocalUrlLowercaseKey])
		relativeFile = [relativeFile lowercaseString];
	if ([pw boolForKey:BDSKAutoFileUsesRelativePathKey])
        return relativeFile;
    return [[papersFolderPath stringByAppendingPathComponent:relativeFile] stringByAbbreviatingWithTildeInPath];
}

- (NSString *)suggestedCiteKey {
    OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
	NSString *citeKeyFormat = [pw objectForKey:BDSKCiteKeyFormatKey];
	NSString *ck = [BDSKFormatParser parseFormat:citeKeyFormat forField:BDSKCiteKeyString ofItem:self];
	if ([pw boolForKey:BDSKCiteKeyLowercaseKey])
		ck = [ck lowercaseString];
	return ck;
}

- (NSString *)displayText {
    NSMutableArray *authors = [NSMutableArray arrayWithCapacity:[pubAuthors count]];
    NSMutableString *string = [NSMutableString string];
    [authors addObjectsByMakingObjectsFromArray:pubAuthors performSelector:@selector(abbreviatedName)];
    
    [string appendStrings:[authors componentsJoinedByCommaAndAnd], @",\n", 
                          [pubFields objectForKey:BDSKTitleString], @",\n", 
                          [pubFields objectForKey:BDSKJournalString], @", ", 
                          [pubFields objectForKey:BDSKPagesString], @":", 
                          [pubFields objectForKey:BDSKVolumeString], @", ", 
                          [pubFields objectForKey:BDSKMonthString], @", ", 
                          [pubFields objectForKey:BDSKYearString], @".", nil];
    return string;
}

@end
