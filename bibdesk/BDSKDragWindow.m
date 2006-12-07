/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#import "BDSKDragWindow.h"

#import "BibDocument.h"
#import "BibItem.h"
#import "BibEditor.h"

@implementation BDSKDragWindow

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;

    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];

    if ( [[pboard types] containsObject:NSStringPboardType] ) {
        if (sourceDragMask & NSDragOperationCopy) {
            return NSDragOperationCopy;
        }
    }
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        if (sourceDragMask & NSDragOperationCopy) {
            return NSDragOperationCopy;
        }
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    NSString *pbString;
    NSArray *fileNames;
    NSArray *draggedPubs;
    NSEnumerator *draggedPubsE;
    BibItem *tempBI;
    NSMutableDictionary *bibDict;
    NSEnumerator *newKeyE;
    NSString *key;
    NSString *value;

    BibItem *editorBib = [[self windowController] currentBib];
    NSArray *oldKeys = [[editorBib dict] allKeys];
        
    sourceDragMask = [sender draggingSourceOperationMask];
    if([sender draggingSource]){
        pboard = [NSPasteboard pasteboardWithName:LocalDragPasteboardName];     // it's really local, so use the local pboard.
    }else{
        pboard = [sender draggingPasteboard];
    }


    // Check first for filenames because we want to treat them differently,
    // and every time someone puts a filenames type on a pboard, they put a URL type too...
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        fileNames = [pboard propertyListForType:NSFilenamesPboardType];

        if (sourceDragMask & NSDragOperationCopy) {
            [editorBib setField:@"Local-Url"
                        toValue:[fileNames objectAtIndex:0]];
            [[self windowController] updateChangeCount:NSChangeDone];
        }
    }else if([[pboard types] containsObject:NSURLPboardType]){

        fileNames = [pboard propertyListForType:NSURLPboardType];
        
        if(sourceDragMask & NSDragOperationCopy){
            [editorBib setField:@"Url"
                        toValue:[fileNames objectAtIndex:0]];
            [[self windowController] updateChangeCount:NSChangeDone];
        }
    }else if ( [[pboard types] containsObject:NSStringPboardType] ) {
        // get the item from the string
        pbString = [pboard stringForType:NSStringPboardType];
        // need items from string here...
        draggedPubs = [BibItem itemsFromString:pbString];
        draggedPubsE = [draggedPubs objectEnumerator];
        while(tempBI = [draggedPubsE nextObject]){
            bibDict = [tempBI dict];
            newKeyE = [bibDict keyEnumerator];

#warning - fixme, read this comment: i don't understand it anymore
            // Test a keyboard? mask so that sometimes we can override all fields.

            while(key = [newKeyE nextObject]){
                value = [[editorBib dict] objectForKey:key]; // value is the value of key in the dragged-onto window.
//                NSLog(@"a key is %@, its value is [%@]", key, value);
                if (([oldKeys containsObject:key] &&
                     [value isEqualToString:@""]) ||
                    (![oldKeys containsObject:key] &&
                     ![[bibDict objectForKey:key] isEqualToString:@""])){

                    [editorBib setField:key
                                toValue:[bibDict objectForKey:key]];
                    [[self windowController] updateChangeCount:NSChangeDone];
                }
            }
        }//for each dragged-in pub
    }
    // my windowcontroller is a BibEditor object
    [[self windowController] setupForm];
    [[self windowController] fixURLs];
    return YES;
}

@end
