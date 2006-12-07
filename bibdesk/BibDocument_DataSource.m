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
    NSString *extension = nil;
    NSString *tcID = [tableColumn identifier];
	NSString *shortDateFormatString = [[NSUserDefaults standardUserDefaults] stringForKey:NSShortDateFormatString];
	
    if(tView == tableView){
        pub = [shownPublications objectAtIndex:sortedRow];
        auths = [pub pubAuthors];
        
        if([tcID caseInsensitiveCompare:BDSKCiteKeyString] == NSOrderedSame ||
		   [tcID caseInsensitiveCompare:@"CiteKey"] == NSOrderedSame ||
		   [tcID caseInsensitiveCompare:@"Cite-Key"] == NSOrderedSame ||
		   [tcID caseInsensitiveCompare:@"Key"]== NSOrderedSame){
            return [pub citeKey];
            
        }else if([tcID isEqualToString: BDSKTitleString] ){
			
			if ([[pub type] isEqualToString:@"inbook"]){
				return [NSString stringWithFormat:@"%@ : %@", [pub valueOfField:@"Chapter"], [pub title]];
			}else{
				return [pub title];
			}
            
        }else if([tcID isEqualToString: BDSKDateCreatedString] ||
				 [tcID isEqualToString: @"Added"] ||
				 [tcID isEqualToString: @"Created"] ){
			NSCalendarDate *date = [pub dateCreated];
			if(date == nil)
                return @"";
            return [date descriptionWithCalendarFormat:shortDateFormatString];
            
        }else if([tcID isEqualToString: BDSKDateModifiedString] ||
				 [tcID isEqualToString: @"Modified"] ){
			NSCalendarDate *date = [pub dateModified];
			if(date == nil)
                return @"";
			return [date descriptionWithCalendarFormat:shortDateFormatString];
			
        }else if([tcID isEqualToString: BDSKDateString] ){
            NSCalendarDate *date = [pub date];
			NSString *monthStr = [pub valueOfField:BDSKMonthString];
			if(date == nil)
                return @"No date";
            else if( !monthStr ||  [monthStr isEqualToString:@""])
                return [date descriptionWithCalendarFormat:NSLocalizedString(@"%Y", @"Date format for only year inside table views")];
            else
                return [date descriptionWithCalendarFormat:NSLocalizedString(@"%b %Y", @"Date format for month and year inside table views")];
            
        }else if([tcID isEqualToString: @"1st Author"] ){
            if([auths count] > 0){
                return [[pub authorAtIndex:0] normalizedName];
            }else{
                return @"-";
            }
            
        }else if([tcID isEqualToString: @"2nd Author"] ){
            if([auths count] > 1)
                return [[pub authorAtIndex:1] normalizedName]; 
            else
                return @"-";
            
        }else if([tcID isEqualToString: @"3rd Author"] ){
            if([auths count] > 2)
                return [[pub authorAtIndex:2] normalizedName];
            else
                return @"-";

		} else if ([tcID isEqualToString:BDSKAuthorString] ||
				   [tcID isEqualToString:@"Authors"]) {
			if ([auths count] > 0) {
				return [pub bibtexAuthorString];
			} else {
				return @"-";
			}										
            
        }else if ([tcID isEqualToString:BDSKLocalUrlString]){
            path = [pub localURLPathRelativeTo:[[self fileName] stringByDeletingLastPathComponent]];
	        extension = [path pathExtension];
            if(path && [[NSFileManager defaultManager] fileExistsAtPath:path]){
				if(![extension isEqualToString:@""]){
					// use the NSImage method, as it seems to be faster, but only for files with extensions
					return [NSImage imageForFileType:extension];
				} else {
					return [[NSWorkspace sharedWorkspace] iconForFile:path];
				}
            }else{
                return nil;
            }

        }else if ([tcID isEqualToString:BDSKUrlString]){
            path = [pub valueOfField:BDSKUrlString];
            if(path && ![path isEqualToString:@""]){
                return [[NSWorkspace sharedWorkspace] iconForFileType:@"webloc"];
            }else{
                return nil;
            }
		}else if([tcID isEqualToString:@"Type"]){
			return [pub type];
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
    if([aNotification object] == tableView) // coalesce notifications so it doesn't have to deal with a notification for every item
        [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:BDSKDocumentUpdateUINotification object:self]
                                                   postingStyle:NSPostWhenIdle
                                                   coalesceMask:NSNotificationCoalescingOnSender
                                                       forModes:nil];
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

// This method returns the string to draw for dragImageForRows, 
// to avoid calling tableView:writeRows: twice, which screws up the 
// draggedItems array.
- (NSString *)citeStringForRows:(NSArray *)dragRows tableViewDragSource:(NSTableView *)tv{
	
    OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
    NSMutableString *s = [[NSMutableString string] retain];
    NSString *startCiteBracket = [sud stringForKey:BDSKCiteStartBracketKey]; 
	NSString *startCite = [NSString stringWithFormat:@"\\%@%@",[sud stringForKey:BDSKCiteStringKey], startCiteBracket];
	NSString *endCiteBracket = [sud stringForKey:BDSKCiteEndBracketKey]; 
    NSMutableArray *rows = nil;
    BOOL sep = ([[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKSeparateCiteKey] == NSOnState);
    NSNumber *idx;

    if(tv == (NSTableView *)ccTableView){
		// check the publications table to see if an item is selected, otherwise we get an error on dragging from the cite drawer
		if([tableView numberOfSelectedRows] == 0) return nil;
        dragRows = [tableView selectedRows]; // get the selection from the main pub table
        startCite = [NSString stringWithFormat:@"\\%@%@",[customStringArray objectAtIndex:[[rows objectAtIndex:0] intValue]], startCiteBracket];
		// rows oi:0 is ok because we don't allow multiple selections in ccTV.
    }  
    // get rows = the main TV's selected rows,

    rows = [NSMutableArray arrayWithCapacity:10];
    NSEnumerator *dragRowE = [dragRows objectEnumerator]; 
    while(idx = [dragRowE nextObject]){
        [rows addObject:idx];
    }
    
    if(!sep) [s appendString:startCite];
    
    int shownCount = [shownPublications count];
    NSEnumerator *enumerator = [rows objectEnumerator]; 
    while (idx = [enumerator nextObject]) {
        int sortedIndex = (sortDescending ? shownCount - 1 - [idx intValue] : [idx intValue]);
        BibItem *pub = [shownPublications objectAtIndex:sortedIndex];
        
        if(sep) [s appendString:startCite];
        [s appendString:[pub citeKey]];
        if(sep) [s appendString:endCiteBracket];
        else [s appendString:@","];
    }// end while
    if(!sep)[s replaceCharactersInRange:[s rangeOfString:@"," options:NSBackwardsSearch] withString:endCiteBracket];

    return s;
    
}

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
    BibItem *pub = nil;

    [draggedItems removeAllObjects];
        
    if(tv == (NSTableView *)ccTableView){
		// check the publications table to see if an item is selected, otherwise we get an error on dragging from the cite drawer
		if([tableView numberOfSelectedRows] == 0) return NO;

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


    // see where we clicked in the table; if we clicked on a local-url column that has a file, we'll copy that file
    // but only if we were passed a single row for now
    NSPoint dragPosition = [tv convertPoint:[[tv window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
    NSTableColumn *clickedColumn = [[tv tableColumns] objectAtIndex:[tv columnAtPoint:dragPosition]];
    int shownCount = [shownPublications count];
    
    // we want the drag to occur for the row that is clicked, not the row that is selected
    if([tv columnAtPoint:dragPosition] != -1 && [[clickedColumn identifier] isEqualToString:BDSKLocalUrlString] &&
       [rows count] == 1){
        i = [rows objectAtIndex:0];
        sortedIndex = (sortDescending ? shownCount - 1 - [i intValue] : [i intValue]);
        pub = [shownPublications objectAtIndex:sortedIndex];
        NSString *path = [pub localURLPathRelativeTo:nil];
        if(path != nil){
            yn = [pboard writeFileContents:path];
            [pboard setPropertyList:[NSArray arrayWithObject:path] forType:NSFilenamesPboardType];
            // NSLog(@"writeFileContents to path %@", (yn ? @"succeeded" : @"failed") );
            dragType = -1; // won't be in defaults
        }
    }
    
    if((dragType == 1) && !sep)
        [s appendString:startCite];

    enumerator = [rows objectEnumerator]; 
    while (i = [enumerator nextObject]) {
        sortedIndex = (sortDescending ? shownCount - 1 - [i intValue] : [i intValue]);
        pub = [shownPublications objectAtIndex:sortedIndex];
        
        [draggedItems addObject:pub];
        [localPBString appendString:[pub bibTeXString]];
        if((dragType == 0) ||
           (dragType == 2)){
            [s appendString:[pub bibTeXString]];
        }
        if(dragType == 1){
            if(sep) [s appendString:startCite];
            [s appendString:[pub citeKey]];
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
    [localDragPboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, BDSKBibItemLocalDragPboardType, nil] owner:nil];
    lyn = [localDragPboard setString:localPBString forType:NSStringPboardType];

    // use dummy data. BDSKBibItemLocalDragPboardType on a pboard *from the same doc*
    //  means you can incorporate the items in the array draggedItems.
    
    lyn &= [localDragPboard setData:[NSData data] forType:BDSKBibItemLocalDragPboardType];
    // NSLog(@"returning %@", (yn && lyn ? @"succeeded" : @"failed") );

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
	
    NSPasteboard *pb;
	
    if(tv == (NSTableView *)ccTableView){
        return NO; // can't drag into that tv.
    }
    
	if([info draggingSource]){
        pb = localDragPboard;     // it's really local, so use the local pboard.
    }else{
        pb = [info draggingPasteboard];
    }
	
    if([[pb types] containsObject:@"CorePasteboardFlavorType 0x57454253"]){ // pasteboard type from Reference Miner, determined using Pasteboard Peeker
        BOOL yn;
        NSMutableArray *pubs = [PubMedParser itemsFromString:[pb stringForType:@"CorePasteboardFlavorType 0x57454253"] error:&yn];
        if(!yn){
            BibItem *newBI;
            NSEnumerator *e = [pubs objectEnumerator];
            while(newBI = [e nextObject]){
                [self addPublication:newBI];
            }
        }
        return !yn;
    }
            
    NSString * myError;
    BOOL result = [self addPublicationsFromPasteboard:pb error:&myError];
    
    if (result) [self updateUI];
    return result;
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


#pragma mark Outlineview datasource methods for Source List

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item{
    if(outlineView != sourceList) [NSException raise:NSInvalidArgumentException 
                                              format:@"OutlineView data source method called by unknown outlineview."];

    if(item == nil){ // root item is nil
        switch (index){
            case 0: 
                // the Library
                return self;
            case 1:
                return collections;
            case 2:
                return notes;
            case 3:
                return sources;
            default:
                [NSException raise:NSInvalidArgumentException 
                            format:@"Unknown index of item in OutlineView data source method."];
                return nil;
        }
    }else{
        if (item == self){
            [NSException raise:NSInvalidArgumentException 
                        format:@"Shouldn't be asking for children of the Library."];
            return nil;
        }else{
            return [item objectAtIndex:index];
        }
    }

}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
    if(outlineView != sourceList) [NSException raise:NSInvalidArgumentException 
                                              format:@"OutlineView data source method called by unknown outlineview."];
    
    if(item == nil){ // root item is nil
        return YES;
    }else{
        if(item == self){
            return NO;
        }else{
            return ([(NSArray *)item count] > 0);
        }
    }        
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item{
    if(outlineView != sourceList) [NSException raise:NSInvalidArgumentException 
                                              format:@"OutlineView data source method called by unknown outlineview."];
    
    if(item == nil){ // root item is nil
        return 4;
    }else{
        if(item == self){
            return 0;
        }else{
            return [(NSArray *)item count];
        }
    }        
}

- (id)outlineView:(NSOutlineView *)outlineView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
           byItem:(id)item{
    if(outlineView != sourceList) [NSException raise:NSInvalidArgumentException 
                                              format:@"OutlineView data source method called by unknown outlineview."];
    
    if(item == nil){ // root item is nil
        return @"root";
    }else{
        if (item == self){
            return NSLocalizedString(@"Library", @"Library label in source list of bibdocument");
        }else if (item == collections){
            return NSLocalizedString(@"Collections", @"Collections label in source list of bibdocument");
        }else if (item == notes){
            return NSLocalizedString(@"Notes", @"Notes label in source list of bibdocument");
        }else if (item == sources){
            return NSLocalizedString(@"Sources", @"External Sources label in source list of bibdocument");
        }else{
            return [item name];
        }
    }        
    
}

// NSOutlineView - drag and drop support

// This method is called after it has been determined that a drag should begin, but before the drag has been started.  To refuse the drag, return NO.  To start a drag, return YES and place the drag data onto the pasteboard (data, owner, etc...).  The drag image and other drag related information will be set up and provided by the outline view once this call returns with YES.  The items array is the list of items that will be participating in the drag.

- (BOOL)outlineView:(NSOutlineView *)olv 
         writeItems:(NSArray*)items 
       toPasteboard:(NSPasteboard*)pboard{
    // temporary - at some point we should write each bibitem in a collection to the pb, and allow dragging items from sources to collections/the library.
    return NO;
}

// This method is used by NSOutlineView to determine a valid drop target.  Based on the mouse position, the outline view will suggest a proposed drop location.  This method must return a value that indicates which dragging operation the data source will perform.  The data source may "re-target" a drop if desired by calling setDropItem:dropChildIndex: and returning something other than NSDragOperationNone.  One may choose to re-target for various reasons (eg. for better visual feedback when inserting into a sorted position).
- (NSDragOperation)outlineView:(NSOutlineView*)olv 
                  validateDrop:(id <NSDraggingInfo>)info 
                  proposedItem:(id)item 
            proposedChildIndex:(int)index{
    if(olv != sourceList) [NSException raise:NSInvalidArgumentException 
                                              format:@"OutlineView data source method called by unknown outlineview."];

    id draggingSource = [info draggingSource];
    
    NSPasteboard *dragPB = [info draggingPasteboard];
    
    if(item == nil){
        // redirect moves onto general space to the library.
        // note that this might get adjusted in the next if-block
        // if the drag is bibitems from our own table, in which case
        // drags back to the library don't make a lot of sense.
        [olv setDropItem:self dropChildIndex:NSOutlineViewDropOnItemIndex];
        item = self;
        index = NSOutlineViewDropOnItemIndex;
    }
    
    if(draggingSource && [localDragPboard hasType:BDSKBibItemLocalDragPboardType]){
        // we are dragging bibitems from within bibdesk (and within our own document)
        // note that draggingSource might be the calling outline view, aka sourceList, aka olv.
        //  onto a collection, allow it. 
        //  onto anywhere else, retarget to collections:0, making new collection...
        if([collections containsObject:item] && index == NSOutlineViewDropOnItemIndex){
            return NSDragOperationCopy;
        }else{
            [olv setDropItem:collections dropChildIndex:0];
            return NSDragOperationCopy;
        }
    }
    
    if([dragPB hasType:NSStringPboardType]){
        // if we're dropping text, allow it in library or collections or notes
        if(item == sources){
            [olv setDropItem:self dropChildIndex:NSOutlineViewDropOnItemIndex];
        }
        return NSDragOperationCopy;
    }else{
        // if we're dropping random data (ie, image, etc) allow it on notes only.
        NSLog(@"NON STRING OR LOCAL DATA DROP proposed item:%@ index: %d", item, index);
        if(item != notes){
            [olv setDropItem:self dropChildIndex:NSOutlineViewDropOnItemIndex];
        }
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}


// This method is called when the mouse is released over an outline view that previously decided to allow a drop via the validateDrop method.  The data source should incorporate the data from the dragging pasteboard at this time.
- (BOOL)outlineView:(NSOutlineView*)olv acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index{
    if(olv != sourceList) [NSException raise:NSInvalidArgumentException 
                                      format:@"OutlineView data source method called by unknown outlineview."];
    
    id draggingSource = [info draggingSource];
            
    if(draggingSource && [localDragPboard hasType:BDSKBibItemLocalDragPboardType]){
        if(index == NSOutlineViewDropOnItemIndex){
            [(BibCollection *) item addPublicationsFromArray:draggedItems];
        }else{
            BibCollection *newBC = [[BibCollection alloc] initWithParent:self];
            [newBC setPublications:draggedItems];
            [(NSMutableArray *) item addObject:[newBC autorelease]];
            [self reloadSourceList];
            [olv expandItem:collections];
            [olv selectRow:[olv rowForItem:newBC] byExtendingSelection:NO];
            [olv editColumn:0 row:[olv rowForItem:newBC]
                  withEvent:nil
                     select:YES];
        }
        [draggedItems removeAllObjects];
    }
    
    return YES;
}

// Delegate methods:

// NSTableView replacements
//- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item;

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item{
    if (item == nil || 
        item == self || 
        item == collections ||
        item == notes ||
        item == sources ){
        return NO;
    }else{
        return YES;
    }
}

// Optional method: needed to allow editing.
- (void)outlineView:(NSOutlineView *)olv setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item  {
    [item setName: object];
}


// - (BOOL)selectionShouldChangeInOutlineView:(NSOutlineView *)outlineView;

//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item;
//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectTableColumn:(NSTableColumn *)tableColumn;
    // NSOutlineView specific
//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item;
//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item;
//- (void)outlineView:(NSOutlineView *)outlineView willDisplayOutlineCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item;



@end


// From JCR:
//To make it more readable, I'd added this category to NSPasteboard:

@implementation NSPasteboard (JCRDragWellExtensions)

- (BOOL) hasType:(id)aType /*"Returns TRUE if aType is one of the types
available from the receiving pastebaord."*/
{ return ([[self types] indexOfObject:aType] == NSNotFound ? NO : YES); }

- (BOOL) containsFiles /*"Returns TRUE if there are filenames available
    in the receiving pasteboard."*/
{ return [self hasType:NSFilenamesPboardType]; }

- (BOOL) containsURL
{return [self hasType:NSURLPboardType];}

@end

