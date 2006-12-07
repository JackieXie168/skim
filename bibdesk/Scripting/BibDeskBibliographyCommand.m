//
//  BibDeskBibliographyCommand.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 29/11/05.
/*
 This software is Copyright (c) 2004,2005,2006
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

#import "BibDeskBibliographyCommand.h"
#import "BibDocument.h"
#import "BibDocument+Scripting.h"
#import "BibItem.h"
#import "BDSKPublicationsArray.h"
#import "NSArray_BDSKExtensions.h"

/* 
ssp: 2004-07-11
 NSScriptCommand for the "bibliography for" command.
 This is sent to the BibDocument.
*/
@implementation BibDeskBibliographyCommand

/*
 ssp: 2004-07-11
 Takes an array of items as given by AppleScript in the formt of NSIndexSpecifiers, runs the items through BibTeX and RTF conversion and returns an attributed string.
 BDSKPreviewer being able to return NSAttributedStrings instead of NSData for RTF might save a few conversions. For the time being I implemented a little function in BibDocument+Scripting. This could be merged into Bibdocument.
 As the BibItem's 'text' attribute, somehow the styling is lost somewhere in the process. Hints?!
*/
- (id) performDefaultImplementation {
    id param = [self directParameter];
	
	//	This should be an NSArray of NSIndexSpecifiers. Perhaps do some error checking
	if (![param isKindOfClass:[NSArray class]]) return nil;
	
	// Determine the document responsible for this
	NSIndexSpecifier * index = [param objectAtIndex:0];
	NSScriptObjectSpecifier * parent = [index containerSpecifier];
	BibDocument *doc = [parent objectsByEvaluatingSpecifier];
	//NSLog([doc description]);
	if (doc == nil) return nil;
	
	NSArray *pubs = [[doc publications] objectsAtIndexSpecifiers:(NSArray*)param];
	
	// make RTF and return it.
	NSTextStorage * ts = [doc textStorageForPublications:pubs];
	
	return ts;
}

@end
