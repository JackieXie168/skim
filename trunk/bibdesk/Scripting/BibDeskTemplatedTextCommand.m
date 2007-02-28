//
//  BibDeskTemplatedTextCommand.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 8/18/06.
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

#import "BibDeskTemplatedTextCommand.h"
#import "BibDocument.h"
#import "BDSKTemplate.h"
#import "BDSKTemplateObjectProxy.h"
#import "BDSKPublicationsArray.h"
#import "NSArray_BDSKExtensions.h"
#import "BibItem.h"

@implementation BibDeskTemplatedTextCommand

- (id)performDefaultImplementation {

	// figure out parameters first
	NSDictionary *params = [self evaluatedArguments];
	if (!params) {
		[self setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
			return @"";
	}
	
	BibDocument *document = nil;
	id receiver = [self evaluatedReceivers];
    NSScriptObjectSpecifier *dP = [self directParameter];
	id dPO = [dP objectsByEvaluatingSpecifier];

	if ([receiver isKindOfClass:[BibDocument class]]) {
        document = receiver;
    } else if ([dPO isKindOfClass:[BibDocument class]]) {
        document = dPO;
    } else {
		// give up
		[self setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
		[self setScriptErrorString:NSLocalizedString(@"The templated text command can only be sent to the documents.", @"Error description")];
		return @"";
	}
	
	// the 'using' parameters gives the template name to use
	NSString *templateStyle = [params objectForKey:@"using"];
	// make sure we get something
	if (!templateStyle) {
		[self setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
		return [NSArray array];
	}
	// make sure we get the right thing
	if (![templateStyle isKindOfClass:[NSString class]] ) {
		[self setScriptErrorNumber:NSArgumentsWrongScriptError]; 
			return @"";
	}
	
	// the 'for' parameter can select the items to template
	NSArray *publications = [document publications];
    id obj = [params objectForKey:@"for"];
    NSArray *items = nil;
	if (obj) {
		// the parameter is present
		if ([obj isKindOfClass:[BibItem class]]) {
            items = [NSArray arrayWithObject:obj];
		} else if ([obj isKindOfClass:[NSArray class]]) {
            items = [publications objectsAtIndexSpecifiers:(NSArray *)obj];
        } else {
			// wrong kind of argument
			[self setScriptErrorNumber:NSArgumentsWrongScriptError];
			[self setScriptErrorString:NSLocalizedString(@"The 'for' option needs to be a publication or a list of publications.",@"Error description")];
			return @"";
		}
		
	} else {
        items = publications;
    }
    
    BDSKTemplate *template = [BDSKTemplate templateForStyle:templateStyle];
    NSString *templatedText = nil;
    
    if ([template templateFormat] & BDSKRichTextTemplateFormat) {
        templatedText = [[BDSKTemplateObjectProxy attributedStringByParsingTemplate:template withObject:document publications:items documentAttributes:NULL] string];
    } else {
        templatedText = [BDSKTemplateObjectProxy stringByParsingTemplate:template withObject:document publications:items];
    }
	
	return templatedText;
}

@end


@implementation BibDeskTemplatedRichTextCommand

- (id)performDefaultImplementation {

	// figure out parameters first
	NSDictionary *params = [self evaluatedArguments];
	if (!params) {
		[self setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
			return [[[NSTextStorage alloc] init] autorelease];;
	}
	
	BibDocument *document = nil;
	id receiver = [self evaluatedReceivers];
    NSScriptObjectSpecifier *dP = [self directParameter];
	id dPO = [dP objectsByEvaluatingSpecifier];

	if ([receiver isKindOfClass:[BibDocument class]]) {
        document = receiver;
    } else if ([dPO isKindOfClass:[BibDocument class]]) {
        document = dPO;
    } else {
		// give up
		[self setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
		[self setScriptErrorString:NSLocalizedString(@"The templated text command can only be sent to the documents.", @"Error description")];
			return [[[NSTextStorage alloc] init] autorelease];;
	}
	
	// the 'using' parameters gives the template name to use
	NSString *templateStyle = [params objectForKey:@"using"];
	// make sure we get something
	if (!templateStyle) {
		[self setScriptErrorNumber:NSRequiredArgumentsMissingScriptError]; 
		return [NSArray array];
	}
	// make sure we get the right thing
	if (![templateStyle isKindOfClass:[NSString class]] ) {
		[self setScriptErrorNumber:NSArgumentsWrongScriptError]; 
			return [[[NSTextStorage alloc] init] autorelease];;
	}
	
	// the 'for' parameter can select the items to template
	NSArray *publications = [document publications];
    id obj = [params objectForKey:@"for"];
    NSArray *items = nil;
	if (obj) {
		// the parameter is present
		if ([obj isKindOfClass:[BibItem class]]) {
            items = [NSArray arrayWithObject:obj];
		} else if ([obj isKindOfClass:[NSArray class]]) {
            items = [publications objectsAtIndexSpecifiers:(NSArray *)obj];
        } else {
			// wrong kind of argument
			[self setScriptErrorNumber:NSArgumentsWrongScriptError];
			[self setScriptErrorString:NSLocalizedString(@"The 'for' option needs to be a publication or a list of publications.",@"Error description")];
			return [[[NSTextStorage alloc] init] autorelease];;
		}
		
	} else {
        items = publications;
    }
    
    BDSKTemplate *template = [BDSKTemplate templateForStyle:templateStyle];
    
    if ([template templateFormat] & BDSKRichTextTemplateFormat) {
        NSAttributedString *templatedRichText = [BDSKTemplateObjectProxy attributedStringByParsingTemplate:template withObject:document publications:items documentAttributes:NULL];
        return [[[NSTextStorage alloc] initWithAttributedString:templatedRichText] autorelease];
    } else {
        NSString *templatedText = [BDSKTemplateObjectProxy stringByParsingTemplate:template withObject:document publications:items];
        return [[[NSTextStorage alloc] initWithString:templatedText] autorelease];
    }
}

@end
