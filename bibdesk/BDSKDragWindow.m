// BDSKDragWindow.m
/*
 This software is Copyright (c) 2002,2003,2004,2005
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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


#import "BDSKDragWindow.h"

#import <Carbon/Carbon.h>
#import "BibDocument.h"
#import "BibItem.h"
#import "BibEditor.h"

@implementation BDSKDragWindow

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
	NSString *pboardType;
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
	
	if([sender draggingSource]){
        pboard = [NSPasteboard pasteboardWithName:LocalDragPasteboardName];     // it's really local, so use the local pboard.
    }else{
        pboard = [sender draggingPasteboard];
    }
	pboardType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSFilenamesPboardType, NSURLPboardType, NSStringPboardType, nil]];

    if ( [pboardType isEqualToString:NSStringPboardType] ) {
        unsigned modifier = GetCurrentKeyModifiers();
        if ( (sourceDragMask & NSDragOperationLink) ||
			 (modifier & (optionKey | cmdKey)) == (optionKey | cmdKey) ){ // hack to get the correct cursor
            return NSDragOperationLink;
        }
        if (sourceDragMask & NSDragOperationCopy) {
            return NSDragOperationCopy;
        }
    }
    if (pboardType && (sourceDragMask & NSDragOperationCopy)) {
		return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
	NSString *pboardType;
	NSArray *fileNames;
    BOOL hadProblems = NO;
    BibItem *editorBib = [[self windowController] currentBib];
    
    // sourceDragMask for files sets NSDragOperationCopy, NSDragOperationLink, and NSDragOperationGeneric
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    
	if([sender draggingSource]){
        pboard = [NSPasteboard pasteboardWithName:LocalDragPasteboardName];     // it's really local, so use the local pboard.
    }else{
        pboard = [sender draggingPasteboard];
    }
	pboardType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSFilenamesPboardType, NSURLPboardType, NSStringPboardType, nil]];

    // Check first for filenames because we want to treat them differently,
    // and every time someone puts a filenames type on a pboard, they put a URL type too...
	if([pboardType isEqualToString:NSFilenamesPboardType]){
		// a file, we link the Local-Url field
		fileNames = [pboard propertyListForType:NSFilenamesPboardType];
		
		if (!(sourceDragMask & NSDragOperationCopy) || [fileNames count] == 0)
			return NO;
		
		NSString *fileUrlString = [[NSURL fileURLWithPath:
			[[fileNames objectAtIndex:0] stringByExpandingTildeInPath]]absoluteString];
		
		[editorBib setField:BDSKLocalUrlString
					toValue:fileUrlString];
		[editorBib autoFilePaper];
		[[editorBib undoManager] setActionName:NSLocalizedString(@"Edit Publication",@"")];
		
		return YES;
	
	}else if([pboardType isEqualToString:NSURLPboardType]){
		// a URL but not a file, we link the remote Url field
		fileNames = [pboard propertyListForType:NSURLPboardType];
		
		if (!(sourceDragMask & NSDragOperationCopy) || [fileNames count] == 0)
			return NO;
		
		[editorBib setField:BDSKUrlString
					toValue:[fileNames objectAtIndex:0]];
		[[editorBib undoManager] setActionName:NSLocalizedString(@"Edit Publication",@"")];
		
		return YES;
	
	}else if([pboardType isEqualToString:NSStringPboardType]) {
		// this should be a bibitem either as RIS of BibteX
		// get the item from the string
		NSData *pbData = [pboard dataForType:NSStringPboardType];
		NSArray *draggedPubs;
		BibItem *tempBI;
        
        // sniff the string to see if it's BibTeX or RIS
        NSString *pbString = [[NSString alloc] initWithData:pbData encoding:NSUTF8StringEncoding];
        
        if([pbString isRISString]){
            draggedPubs = [PubMedParser itemsFromString:pbString error:&hadProblems];
        } else {
            // must be BibTeX
			[[NSApp delegate] setDocumentForErrors:[editorBib document]];
            draggedPubs = [BibTeXParser itemsFromData:pbData error:&hadProblems];
        }
        [pbString release]; 
        if(hadProblems) return NO;
        
        tempBI = [draggedPubs objectAtIndex:0]; // no point in dealing with multiple pubs for a single editor
		[tempBI setDocument:[editorBib document]]; // this assures that the macroResolver is set for complex strings

        // Test a keyboard mask so that we can override all fields when dragging into the editor window (option)
        // create a crossref (cmd-option), or fill empty fields (no modifiers)
        unsigned modifier = GetCurrentKeyModifiers(); // use the Carbon function since [[NSApp currentEvent] modifierFlags] won't work if we're not the front app
        
        // we don't seem to get NSDragOperationLink unless it's control-left mouse, so we'll test the mask manually
        if((sourceDragMask & NSDragOperationLink) || 
           (modifier & (optionKey | cmdKey)) == (optionKey | cmdKey))
            sourceDragMask = NSDragOperationLink;
        
        if(sourceDragMask & NSDragOperationLink){
			
			NSString *crossref = [tempBI citeKey];
			NSString *message = nil;
			
			// first check if we don't create a Crossref chain
			if ([[editorBib citeKey] caseInsensitiveCompare:crossref] == NSOrderedSame) {
				message = NSLocalizedString(@"An item cannot cross reference to itself.", @"");
			} else {
				BibDocument *doc = [editorBib document]; 
				NSString *parentCr = [[doc publicationForCiteKey:crossref] valueOfField:BDSKCrossrefString inherit:NO];
				
				if (parentCr && ![parentCr isEqualToString:@""]) {
					message = NSLocalizedString(@"Cannot cross reference to an item that has the Crossref field set.", @"");
				} else if ([doc citeKeyIsCrossreffed:[editorBib citeKey]]) {
					message = NSLocalizedString(@"Cannot set the Crossref field, as the current item is cross referenced.", @"");
				}
			}
			
			if (message) {
				NSRunAlertPanel(NSLocalizedString(@"Invalid Crossref Value", @"Invalid Crossref Value"),
								message,
								NSLocalizedString(@"OK", @"OK"), nil, nil);
				return NO;
			}
            // add the crossref field if it doesn't exist, then set it to the citekey of the drag source's bibitem
            if(![[[editorBib pubFields] allKeys] containsObject:BDSKCrossrefString])
                [editorBib addField:BDSKCrossrefString];
            [editorBib setField:BDSKCrossrefString toValue:crossref];
			[[editorBib undoManager] setActionName:NSLocalizedString(@"Edit Publication",@"")];
            return YES;
        }
        
        // we aren't linking, so here we decide which fields to overwrite, and just copy values over
		NSDictionary *bibDict = [tempBI pubFields];
		NSEnumerator *newKeyE = [bibDict keyEnumerator];
		NSString *key;
		NSString *oldValue;
		NSString *newValue;
		
        if(modifier & optionKey){
            [editorBib setCiteKey:[tempBI citeKey]];
        }
        [editorBib setType:[tempBI type]]; // do we want this always?
        
		while(key = [newKeyE nextObject]){
			newValue = [bibDict objectForKey:key];
			if([newValue isEqualToString:@""])
				continue;
			
			oldValue = [[editorBib pubFields] objectForKey:key]; // value is the value of key in the dragged-onto window.
			
			// only set the field if we force or the value was empty
			if((modifier & optionKey) || oldValue == nil || [oldValue isEqualToString:@""]){
				if(oldValue == nil)
					[editorBib addField:key];
				[editorBib setField:key toValue:newValue];
            }
        }
		
		[[editorBib undoManager] setActionName:NSLocalizedString(@"Edit Publication",@"")];
		
		return YES;
		
    }
    
	// we did not find a valid dragtype
	return NO;
}

@end
