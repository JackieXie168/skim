//  BibDocument_DataSource.m

//  Created by Michael McCracken on Tue Mar 26 2002.
/*
This software is Copyright (c) 2001,2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#import "BibDocument.h"
#import "BibItem.h"
#import "BibDocument_DataSource.h"
#import "BibAuthor.h"

@implementation BibDocument (DataSource)

#pragma mark ||  Methods to support table view.

- (void)tableView: (NSTableView *)aTableView willDisplayCell: (id)aCell
   forTableColumn: (NSTableColumn *)aTableColumn
              row:(int)row
{
    if([aCell class] != [NSImageCell class]){

        [aCell setDrawsBackground: ((row % 2) == 0)];
    }
}

- (int)numberOfRowsInTableView:(NSTableView *)tView{
    if(tView == (NSTableView *)tableView){
        return [shownPublications count];
    }else if(tView == (NSTableView *)ccTableView){
        return [customStringArray count];
    }else{
// should raise an exception or something
        return 0;
    }
}

- (id)tableView:(NSTableView *)tView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    BibItem* pub = nil;
    NSArray *auths = nil;
    int sortedRow = (sortDescending ? [shownPublications count] - 1 - row : row);
    NSString *path = nil;
    
    if(tView == tableView){
        pub = [shownPublications objectAtIndex:sortedRow];
        auths = [pub pubAuthors];
        
        if([[tableColumn identifier] isEqualToString: @"Cite Key"] ){
            return [pub citeKey];
            
        }else if([[tableColumn identifier] isEqualToString: @"Title"] ){
            return [pub title];
            
        }else if([[tableColumn identifier] isEqualToString: @"Date"] ){
            if([pub date] == nil)
                return @"No date";
            else if([[pub valueOfField:@"Month"] isEqualToString:@""])
                return [[pub date] descriptionWithCalendarFormat:@"%Y"];
            else
                return [[pub date] descriptionWithCalendarFormat:@"%b %Y"];
            
        }else if([[tableColumn identifier] isEqualToString: @"1st Author"] ){
            if([auths count] > 0){
                return [[pub authorAtIndex:0] name];
            }else{
                return @"-";
            }
            
        }else if([[tableColumn identifier] isEqualToString: @"2nd Author"] ){
            if([auths count] > 1)
                return [[pub authorAtIndex:1] name]; 
            else
                return @"-";
            
        }else if([[tableColumn identifier] isEqualToString: @"3rd Author"] ){
            if([auths count] > 2)
                return [[pub authorAtIndex:2] name];
            else
                return @"-";
            
        }else if ([[tableColumn identifier] isEqualToString:@"Local-Url"]){
            path = [pub localURLPathRelativeTo:[[self fileName] stringByDeletingLastPathComponent]];
            if(path && [[NSFileManager defaultManager] fileExistsAtPath:path]){
                return [[NSWorkspace sharedWorkspace] iconForFile:path];
            }else{
                return nil;
            }

        }else if ([[tableColumn identifier] isEqualToString:@"Url"]){
            path = [pub valueOfField:@"Url"];
            if(path && ![path isEqualToString:@""]){
                return [[NSWorkspace sharedWorkspace] iconForFileType:@"webloc"];
            }else{
                return nil;
            }

        }else{
            // the tableColumn isn't something we handle in a custom way.
            return [pub valueOfField:[tableColumn identifier]];
        }

    }else if(tView == (NSTableView *)ccTableView){
        return [customStringArray objectAtIndex:row];
    }
    else return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [self updatePreviews:aNotification];
}


- (void)tableViewColumnDidResize:(NSNotification *)notification{
    OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
    NSMutableDictionary *columns = [[[pw objectForKey:BDSKColumnWidthsKey] mutableCopy] autorelease];
    NSEnumerator *tcE = [[[notification object] tableColumns] objectEnumerator];
    NSTableColumn *tc = nil;

    if (!columns) columns = [NSMutableDictionary dictionaryWithCapacity:5];

    while(tc = (NSTableColumn *) [tcE nextObject]){
        [columns setObject:[NSNumber numberWithFloat:[tc width]]
                    forKey:[tc identifier]];
    }
    ////NSLog(@"tableViewColumnDidResize - setting %@ forKey: %@ ", columns, BDSKColumnWidthsKey);
    [pw setObject:columns forKey:BDSKColumnWidthsKey];
}


- (void)tableViewColumnDidMove:(NSNotification *)notification{
    NSMutableArray *columnsInOrder = [NSMutableArray arrayWithCapacity:5];

    NSEnumerator *tcE = [[[notification object] tableColumns] objectEnumerator];
    NSTableColumn *tc = nil;

    while(tc = (NSTableColumn *) [tcE nextObject]){
        [columnsInOrder addObject:[tc identifier]];
    }

    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:columnsInOrder
                                                      forKey:BDSKShownColsNamesKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocumentUpdateUINotification
                                                        object:nil];

}



// drag and drop support

// This method is called after it has been determined that a drag should begin, but before the drag has been started.  To refuse the drag, return NO.  To start a drag, return YES and place the drag data onto the pasteboard (data, owner, etc...).  The drag image and other drag related information will be set up and provided by the table view once this call returns with YES.  The rows array is the list of row numbers that will be participating in the drag.

- (BOOL)tableView:(NSTableView *)tv
        writeRows:(NSArray*)rows
     toPasteboard:(NSPasteboard*)pboard{
    OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
    BOOL yn = NO;
	BOOL lyn = NO;
	NSString *startCiteBracket = [sud stringForKey:BDSKCiteStartBracketKey]; 
	NSString *startCite = [NSString stringWithFormat:@"\\%@%@",[sud stringForKey:BDSKCiteStringKey], startCiteBracket];
	NSString *endCiteBracket = [sud stringForKey:BDSKCiteEndBracketKey]; 

    NSMutableString *s = [[NSMutableString string] retain];
    NSMutableString *localPBString = [NSMutableString string];
    NSEnumerator *enumerator;
    NSNumber *i;
    BOOL sep = ([[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKSeparateCiteKey] == NSOnState);

    int dragType = [[sud objectForKey:BDSKDragCopyKey] intValue];

    NSEnumerator *selRowE;
    NSNumber *idx;
    NSMutableArray* newRows;
    int sortedIndex = 0;

    if([tv numberOfSelectedRows] == 0) return NO;

    if(tv == (NSTableView *)ccTableView){
        startCite = [NSString stringWithFormat:@"\\%@%@",[customStringArray objectAtIndex:[[rows objectAtIndex:0] intValue]], startCiteBracket];
		// rows oi:0 is ok because we don't allow multiple selections in ccTV.

        // if it's the ccTableView, then rows has the rows of the ccTV.
        // we need to change rows to be the main TV's selected rows,
        // so that the regular code still works
        newRows = [NSMutableArray arrayWithCapacity:10];
        selRowE = [tableView selectedRowEnumerator]; 
        while(idx = [selRowE nextObject]){
            [newRows addObject:idx];
        }
        rows = [NSArray arrayWithArray:newRows];
        // NSLog(@"rows is %@", rows);
    }// ccTableView


    if((dragType == 1) && !sep)
        [s appendString:startCite];

    enumerator = [rows objectEnumerator]; 
    while (i = [enumerator nextObject]) {
        sortedIndex = (sortDescending ? [shownPublications count] - 1 - [i intValue] : [i intValue]);
        
        [localPBString appendString:[[shownPublications objectAtIndex:sortedIndex] bibTeXString]];
        if((dragType == 0) ||
           (dragType == 2)){
            [s appendString:[[shownPublications objectAtIndex:sortedIndex] bibTeXString]];
        }
        if(dragType == 1){
            if(sep) [s appendString:startCite];
            [s appendString:[[shownPublications objectAtIndex:sortedIndex] citeKey]];
            if(sep) [s appendString:endCiteBracket];
            else [s appendString:@","];
        }
    }// end while

    if(dragType == 1){
        if(!sep)[s replaceCharactersInRange:[s rangeOfString:@"," options:NSBackwardsSearch] withString:endCiteBracket];
    }
    if((dragType == 0) ||
       (dragType == 1)){
        [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        yn = [pboard setString:s forType:NSStringPboardType];
    }else if (dragType == 2){
        [pboard declareTypes:[NSArray arrayWithObject:NSPDFPboardType] owner:nil];
        yn = [pboard setData:[PDFpreviewer PDFDataFromString:s] forType:NSPDFPboardType];
    }else if (dragType == 3){
		[pboard declareTypes:[NSArray arrayWithObject:NSRTFPboardType] owner:nil];
        yn = [pboard setData:[PDFpreviewer rtfDataPreview] forType:NSRTFPboardType];
    }
    [localDragPboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    lyn = [localDragPboard setString:localPBString forType:NSStringPboardType];
    return yn && lyn;

}


// This method is used by NSTableView to determine a valid drop target.  Based on the mouse position, the table view will suggest a proposed drop location.  This method must return a value that indicates which dragging operation the data source will perform.  The data source may "re-target" a drop if desired by calling setDropRow:dropOperation: and returning something other than NSDragOperationNone.  One may choose to re-target for various reasons (eg. for better visual feedback when inserting into a sorted position).
- (NSDragOperation)tableView:(NSTableView*)tv
                validateDrop:(id <NSDraggingInfo>)info
                 proposedRow:(int)row
       proposedDropOperation:(NSTableViewDropOperation)op{
    if(tv == (NSTableView *)ccTableView){
        return NSDragOperationNone;// can't drag into that tv.
    }
    if ([info draggingSource]) {
       if([info draggingSource] == tableView)
       {
           // can't copy onto same table
           return NSDragOperationNone;
       }
        [tv setDropRow:[tv numberOfRows] dropOperation:NSDragOperationCopy];
        return NSDragOperationCopy;    
    }else{
        //it's not from me
        [tv setDropRow:[tv numberOfRows] dropOperation:NSDragOperationCopy];
        return NSDragOperationEvery; // if it's not from me, copying is OK
    }
}

// This method is called when the mouse is released over an outline view that previously decided to allow a drop via the validateDrop method.  The data source should incorporate the data from the dragging pasteboard at this time.
- (BOOL)tableView:(NSTableView*)tv
       acceptDrop:(id <NSDraggingInfo>)info
              row:(int)row
    dropOperation:(NSTableViewDropOperation)op{

    BibItem *newBI;
    NSPasteboard *pb;
    NSMutableArray *newBIs;
    NSEnumerator *fileNameEnum;
    NSData *pbData; 
    NSArray *pbArray;
    NSArray *newPubs;
    NSEnumerator *newPubE;
    NSString *fnStr;
    NSArray *types;
    NSURL *url;
    BOOL hadProblems = NO;
    OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];

    if(tv == (NSTableView *)ccTableView){
        return NO; // can't drag into that tv.
    }
    
    if([info draggingSource]){
        pb = localDragPboard;     // it's really local, so use the local pboard.
    }else{
       // pb = [NSPasteboard  pasteboardWithName:NSDragPboard];
        pb = [info draggingPasteboard];
    }
    types = [pb types];
#if DEBUG
    //NSLog(@"types is %@", types);
    //NSLog(@"pb is %@ and \n sender dpb is %@", pb, [info draggingPasteboard]);
#endif
    

    if([pb containsFiles]){
        newBIs = [NSMutableArray array];
        pbArray = [pb propertyListForType:NSFilenamesPboardType]; // we will get an array
#if DEBUG
        //NSLog(@"got filenames %@", pbArray);
#endif
        fileNameEnum = [pbArray objectEnumerator];
        while(fnStr = [fileNameEnum nextObject]){
            if(url = [NSURL fileURLWithPath:fnStr]){
                newBI = [[BibItem alloc] initWithType:[pw stringForKey:BDSKPubTypeStringKey]
                                             fileType:@"BibTeX"
                                              authors:[NSMutableArray arrayWithCapacity:0]];
              
				[self addPublication:newBI];
				
				NSString *newUrl = [[NSURL fileURLWithPath:
                    [fnStr stringByExpandingTildeInPath]]absoluteString];
				
				[newBI setField:@"Local-Url" toValue:newUrl];	

				if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKFilePapersAutomaticallyKey]){
					[[BibFiler sharedFiler] filePapers:[NSArray arrayWithObject:newBI]
										  fromDocument:self];
				}
				
                [self updateUI];
                [self updateChangeCount:NSChangeDone];

                if([pw integerForKey:BDSKEditOnPasteKey] == NSOnState){
                    [self editPub:newBI forceChange:YES];
                    //[[newBI editorObj] fixEditedStatus];  - deprecated
                }
            }
        }
        return YES;
    }else if([types containsObject:NSStringPboardType]){
        pbData = [pb dataForType:NSStringPboardType]; 

        newPubs = [BibTeXParser itemsFromData:pbData
                                          error:&hadProblems];
        if(hadProblems) return NO;
            
        newPubE = [newPubs objectEnumerator];
        
        while(newBI = [newPubE nextObject]){

            if (newBI != nil) {
                [publications addObject:newBI];
                [shownPublications addObject:newBI];
                [self updateUI];
                [self updateChangeCount:NSChangeDone];
                if([[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKEditOnPasteKey] == NSOnState)
                    [self editPub:newBI forceChange:YES];
            }else{

            }
        }
    }else{
        return NO;
    }
    
    [self updateUI];
    return YES;
}


#pragma mark || Methods to support the type-ahead selector.
- (NSArray *)typeAheadSelectionItems{
    NSEnumerator *e = [shownPublications objectEnumerator];
    NSMutableArray *a = [NSMutableArray arrayWithCapacity:10];
    BibItem *pub = nil;

    while(pub = [e nextObject]){
        [a addObject:[pub bibtexAuthorString]];
    }
    return a;
}
    // This is where we build the list of possible items which the user can select by typing the first few letters. You should return an array of NSStrings.

- (NSString *)currentlySelectedItem{
    int n = [self numberOfSelectedPubs];
    BibItem *bib;
    if (n == 1){
        bib = [shownPublications objectAtIndex:[[[self selectedPubEnumerator] nextObject] intValue]];
        return [bib bibtexAuthorString];
    }else{
        return nil;
    }
}
// Type-ahead-selection behavior can change if an item is currently selected (especially if the item was selected by type-ahead-selection). Return nil if you have no selection or a multiple selection.

// fixme -  also need to call the processkeychars in keydown...
- (void)typeAheadSelectItemAtIndex:(int)itemIndex{
    int sortedItemIndex = (sortDescending ? [shownPublications count] - 1 - itemIndex : itemIndex);
    [self highlightBib:[shownPublications objectAtIndex:sortedItemIndex] byExtendingSelection:NO];
}
// We call this when a type-ahead-selection match has been made; you should select the item based on its index in the array you provided in -typeAheadSelectionItems.



@end


// From JCR:
//To make it more readable, I'd added this category to NSPasteboard:

@implementation NSPasteboard (JCRDragWellExtensions)

- (BOOL) hasType:aType /*"Returns TRUE if aType is one of the types
available from the receiving pastebaord."*/
{ return ([[self types] indexOfObject:aType] == NSNotFound ? NO : YES); }

- (BOOL) containsFiles /*"Returns TRUE if there are filenames available
    in the receiving pasteboard."*/
{ return [self hasType:NSFilenamesPboardType]; }

- (BOOL) containsURL
{return [self hasType:NSURLPboardType];}

@end

