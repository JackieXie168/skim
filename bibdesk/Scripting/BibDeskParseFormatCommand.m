//
//  BibDeskParseFormatCommand.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 18/10/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BibDeskParseFormatCommand.h"
#import "BDSKFormatParser.h"
#import "BibField.h"
#import "BibItem.h"
#import "BibPrefController.h"
#import "BibAppController.h"

@implementation BibDeskParseFormatCommand

- (id)performDefaultImplementation {
	// the direct object is the format string
	NSString *formatString = [self directParameter];
	// the other parameters are either a field or a field name and a publication
	NSDictionary *params = [self evaluatedArguments];
	
	if (!formatString || !params) {
		[self setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
		return nil;
	}
	if (![formatString isKindOfClass:[NSString class]]) {
		[self setScriptErrorNumber:NSArgumentsWrongScriptError]; 
		return nil;
	}
	
	id field = [params objectForKey:@"for"];
	BibItem *pub = [params objectForKey:@"from"];
	
	if (!field) {
		[self setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
		return nil;
	}
	if ([field isKindOfClass:[BibField class]]) {
		if (!pub) {
			pub = [(BibField *)field publication];
		}
		field = [field name];
	} else if (![field isKindOfClass:[NSString class]]) {
		[self setScriptErrorNumber:NSArgumentsWrongScriptError]; 
		return nil;
	}
	
	if (!pub) {
		[self setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
		return nil;
	}
	if (![pub isKindOfClass:[BibItem class]]) {
		[self setScriptErrorNumber:NSArgumentsWrongScriptError]; 
		return nil;
	}
	
	NSString *error = nil;
	
	if (![BDSKFormatParser validateFormat:&formatString forField:field inFileType:BDSKBibtexString error:&error]) {
		[self setScriptErrorNumber:NSArgumentsWrongScriptError]; 
		[self setScriptErrorString:[NSString stringWithFormat:@"Invalid format string: %@", error]]; 
		return nil;
	}
	
	NSString *string = [BDSKFormatParser parseFormat:formatString forField:field ofItem:pub];
	
	if ([[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKLocalFileFieldsKey] containsObject:field]) {
		NSString *papersFolderPath = [[NSApp delegate] folderPathForFilingPapersFromDocument:[pub document]];
		return [[NSURL fileURLWithPath:[papersFolderPath stringByAppendingPathComponent:string]] absoluteString];
	} 
	
	return string;
}

@end
