//  BibDocument_DataSource.m

//  Created by Michael McCracken on Tue Mar 26 2002.
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

#import "BibDocument.h"
#import "BibItem.h"
#import "BibDocument_DataSource.h"
#import "BibAuthor.h"
#import "NSImage+Toolbox.h"

@implementation BibDocument (DataSource)

#pragma mark ||  Methods to support table view.

- (void)tableView: (NSTableView *)aTableView willDisplayCell: (id)aCell
   forTableColumn: (NSTableColumn *)aTableColumn
              row:(int)row
{
    if([aCell isKindOfClass:[NSTextFieldCell class]]){

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

    NSString *path = nil;
    NSString *tcID = [tableColumn identifier];
	NSString *shortDateFormatString = [[NSUserDefaults standardUserDefaults] stringForKey:NSShortDateFormatString];
	NSArray *localFileFields = [[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKLocalFileFieldsKey];
	NSArray *remoteURLFields = [[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKRemoteURLFieldsKey];
    NSArray *ratingFields = [[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKRatingFieldsKey];
    NSArray *booleanFields = [[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKBooleanFieldsKey];
    
    if(row >= 0 && tView == tableView){ // sortedRow can be -1 if you delete the last pub and sortDescending is true
        pub = [shownPublications objectAtIndex:row usingLock:pubsLock];
        auths = [pub pubAuthors];
        
        if([tcID isEqualToString:BDSKCiteKeyString]){
            return [pub citeKey];
            
        }else if([tcID isEqualToString:BDSKItemNumberString]){
            return [NSNumber numberWithInt:[pub fileOrder]];
            
        }else if([tcID isEqualToString: BDSKTitleString] ){
			NSString *title = [pub title];
			if ([title isEqualToString:@""])
				return @"-";
			return title;
		
		}else if([tcID isEqualToString: BDSKContainerString] ){
			NSString *container = [pub container];
			if ([container isEqualToString:@""])
				return @"-";
			return container;
            
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
                return NSLocalizedString(@"No date",@"No date");
            else if([NSString isEmptyString:monthStr])
                return [date descriptionWithCalendarFormat:@"%Y"];
            else
                return [date descriptionWithCalendarFormat:@"%b %Y"];
            
        }else if([tcID isEqualToString: BDSKFirstAuthorString] ){
            if([auths count] > 0){
                return [[pub authorAtIndex:0] normalizedName];
            }else{
                return @"-";
            }
            
        }else if([tcID isEqualToString: BDSKSecondAuthorString] ){
            if([auths count] > 1)
                return [[pub authorAtIndex:1] normalizedName]; 
            else
                return @"-";
            
        }else if([tcID isEqualToString: BDSKThirdAuthorString] ){
            if([auths count] > 2)
                return [[pub authorAtIndex:2] normalizedName];
            else
                return @"-";

		} else if ([tcID isEqualToString:BDSKAuthorString] ||
				   [tcID isEqualToString:@"Authors"]) {
			if ([auths count] > 0) {
				return [pub bibTeXAuthorStringNormalized:YES];
			} else {
				return @"-";
			}										
            
        }else if ([localFileFields containsObject:tcID]){
            path = [pub localFilePathForField:tcID];
            if(path && [[NSFileManager defaultManager] fileExistsAtPath:path]){
                return [NSImage smallImageForFile:path];
            }else if(path){
				return [NSImage imageNamed:@"QuestionMarkFile"];
			}else{
                return nil;
            }
        }else if ([remoteURLFields containsObject:tcID]){
            return [NSImage smallImageForURL:[pub URLForField:tcID]];
		}else if([ratingFields containsObject:tcID]){
			return [NSNumber numberWithInt:[pub ratingValueOfField:tcID]];
		}else if([booleanFields containsObject:tcID]){
			return [NSNumber numberWithBool:[pub boolValueOfField:tcID]];
		}else if([tcID isEqualToString:BDSKTypeString]){
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

- (void)tableView:(NSTableView *)tv setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    if(tv == (NSTableView *)ccTableView){
		[customStringArray replaceObjectAtIndex:row withObject:object];
	}else {
        NSArray *ratingFields = [[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKRatingFieldsKey];
        NSArray *booleanFields = [[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKBooleanFieldsKey];

		NSString *tcID = [tableColumn identifier];
		if([ratingFields containsObject:tcID]){
			BibItem *pub = [shownPublications objectAtIndex:row usingLock:pubsLock];
			int rating = [pub ratingValueOfField:tcID];
			if(rating != [object intValue]) {
				[pub setRatingField:tcID toValue:[object intValue]];
				[[pub undoManager] setActionName:NSLocalizedString(@"Change Rating",@"Change Rating")];
			}
		}else if([booleanFields containsObject:tcID]){
			BibItem *pub = [shownPublications objectAtIndex:row usingLock:pubsLock];
			BOOL status = [pub boolValueOfField:tcID];
			if(status != [object boolValue]) {
				[pub setBooleanField:tcID toValue:[object boolValue]];
				[[pub undoManager] setActionName:NSLocalizedString(@"Change Read",@"Change Read")];
			}
		}
	}
}

- (BOOL)tableView:(NSTableView *)tv shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)row{
    if(tv == tableView){
		return NO;
	}else if(tv == (NSTableView *)ccTableView){
		return YES;
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
	NSTableView *tv = [aNotification object];
    if(tv == tableView){
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKTableSelectionChangedNotification object:self];
    }else if(tv == (NSTableView *)ccTableView){
		[removeCustomCiteStringButton setEnabled:([tv numberOfSelectedRows] > 0)];
	}
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
	// WARNING: don't notify changes to other docs, as this is very buggy. 
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
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKTableColumnChangedNotification
                                                        object:self];

}


// drag and drop support

// This method returns the string to draw for dragImageForRows, 
// to avoid calling tableView:writeRows: twice, which screws up the 
// draggedItems array.
- (NSString *)citeStringForRows:(NSArray *)dragRows tableViewDragSource:(NSTableView *)tv{
    NSString *citeString;

    if(tv == (NSTableView *)ccTableView){
		// check the publications table to see if an item is selected, otherwise we get an error on dragging from the cite drawer
		if([tableView numberOfSelectedRows] == 0) return nil;
        citeString = [customStringArray objectAtIndex:[[dragRows objectAtIndex:0] intValue]];
		// rows oi:0 is ok because we don't allow multiple selections in ccTV.
        dragRows = [tableView selectedRows]; // get the selection from the main pub table
    }else{
		citeString = [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKCiteStringKey];
	}
	
	return [self citeStringForPublications:dragRows citeString:citeString];
}

- (BOOL)tableView:(NSTableView *)tv
        writeRows:(NSArray*)rows
     toPasteboard:(NSPasteboard*)pboard{
    OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
	int dragType = [sud integerForKey:BDSKDragCopyKey];
    BOOL yn = NO;
	NSString *citeString = [sud stringForKey:BDSKCiteStringKey];
	NSString *bibString;
    
	[draggedItems removeAllObjects];
        
    if(tv == (NSTableView *)ccTableView){
		// drag from the custom cite drawer table
		// check the publications table to see if an item is selected, otherwise we get an error on dragging from the cite drawer
		if([tableView numberOfSelectedRows] == 0){
            NSBeginAlertSheet(NSLocalizedString(@"Nothing selected in document", @""),nil,nil,nil,documentWindow,nil,NULL,NULL,NULL,
                              NSLocalizedString(@"You need to select an item in the document before dragging from the cite drawer.", @""));
            return NO;
        }

        citeString = [customStringArray objectAtIndex:[[rows objectAtIndex:0] intValue]];
		// rows oi:0 is ok because we don't allow multiple selections in ccTV.

        // if it's the ccTableView, then rows has the rows of the ccTV.
        // we need to change rows to be the main TV's selected rows,
        // so that the regular code still works
        rows = [self selectedPublications];
        dragType = 1; // only type that makes sense here
        // NSLog(@"rows is %@", rows);
    }else{
		// drag from the main table
		// see where we clicked in the table; if we clicked on a local-url column that has a file, we'll copy that file
		// but only if we were passed a single row for now
        NSPoint eventPt = [[tv window] mouseLocationOutsideOfEventStream];
		NSPoint dragPosition = [tv convertPoint:eventPt fromView:nil];
		int dragColumn = [tv columnAtPoint:dragPosition];
		NSString *dragColumnId = nil;
        		
		if(dragColumn == -1)
            return NO;
        
        dragColumnId = [[[tv tableColumns] objectAtIndex:dragColumn] identifier];
		NSArray *localFileFields = [[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKLocalFileFieldsKey];
		NSArray *remoteURLFields = [[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKRemoteURLFieldsKey];
		
		// we want the drag to occur for the row that is dragged, not the row that is selected
		if([rows count] == 1){
			if([localFileFields containsObject:dragColumnId]){
				NSNumber *i = [rows objectAtIndex:0];
				BibItem *pub = [shownPublications objectAtIndex:[i intValue] usingLock:pubsLock];
				NSString *path = [pub localFilePathForField:dragColumnId];
				if(path != nil){
					[pboard declareTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSFileContentsPboardType, BDSKBibTeXStringPboardType, nil] owner:nil];
					yn = [pboard writeFileContents:path] && 
						 [pboard setPropertyList:[NSArray arrayWithObject:path] forType:NSFilenamesPboardType];
					// NSLog(@"writeFileContents to path %@", (yn ? @"succeeded" : @"failed") );
					dragType = -1; // won't be in defaults
				}
			}else if([remoteURLFields containsObject:dragColumnId]){
                // cache this so we know which column (field) was dragged
                [self setPromiseDragColumnIdentifier:dragColumnId];
                
				NSNumber *i = [rows objectAtIndex:0];
				BibItem *pub = [shownPublications objectAtIndex:[i intValue] usingLock:pubsLock];
				NSURL *url = [pub remoteURLForField:dragColumnId];
				if(url != nil){
					// put the URL and a webloc file promise on the pasteboard
					if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3){
						// ARM: file promise drags from a tableview are really buggy on 10.3 and earlier, and I don't feel like fighting them right now for webloc files (which require a destination path for creation)
						[pboard declareTypes:[NSArray arrayWithObjects:NSURLPboardType, BDSKBibTeXStringPboardType, nil] owner:nil];
						[url writeToPasteboard:pboard];
					} else {
						[pboard declareTypes:[NSArray arrayWithObjects:NSFilesPromisePboardType, NSURLPboardType, BDSKBibTeXStringPboardType, nil] owner:nil];
						[pboard setPropertyList:[NSArray arrayWithObject:[[pub displayTitle] stringByAppendingPathExtension:@"webloc"]] forType:NSFilesPromisePboardType];
						[url writeToPasteboard:pboard];
					}
					yn = YES;
					dragType = -1; // won't be in defaults
				}
			}
		}
    }
	
	bibString = [self bibTeXStringForPublications:rows];
	
    switch(dragType){
		case 0:
			[pboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, BDSKBibTeXStringPboardType, nil] owner:nil];
			yn = [pboard setString:bibString
						   forType:NSStringPboardType];
			break;
		case 1:
			[pboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, BDSKBibTeXStringPboardType, nil] owner:nil];
			yn = [pboard setString:[self citeStringForPublications:rows citeString:citeString]
						   forType:NSStringPboardType];
			break;
		case 2:
			[pboard declareTypes:[NSArray arrayWithObjects:NSPDFPboardType, BDSKBibTeXStringPboardType, nil] owner:self];
			// we will generate the PDF data later when requested
			yn = YES;
			break;
		case 3:
			[pboard declareTypes:[NSArray arrayWithObjects:NSRTFPboardType, BDSKBibTeXStringPboardType, nil] owner:self];
			// we will generate the RTF data later when requested
			yn = YES;
    }
    
	yn &= [pboard setString:bibString forType:BDSKBibTeXStringPboardType];
    // NSLog(@"returning %@", (yn ? @"succeeded" : @"failed") );

    return yn;
}

// we generate PDF and RTF data only when they are dropped
- (void)pasteboard:(NSPasteboard *)pboard provideDataForType:(NSString *)type{
	NSString *bibString = [pboard stringForType:BDSKBibTeXStringPboardType];
	
	if(!bibString){
		NSBeep();
		return;
	}
	
	if([type isEqualToString:NSPDFPboardType]){
		if([texTask runWithBibTeXString:bibString generatedTypes:BDSKGeneratePDF] && [texTask hasPDFData]){
			[pboard setData:[texTask PDFData] forType:NSPDFPboardType];
		}else{
			NSBeep();
		}
	}else if([type isEqualToString:NSRTFPboardType]){
		if([texTask runWithBibTeXString:bibString generatedTypes:BDSKGenerateRTF] && [texTask hasRTFData]){
			[pboard setData:[texTask RTFData] forType:NSRTFPboardType];
		}else{
			NSBeep();
		}
	}
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

// This method is called when the mouse is released over a table view that previously decided to allow a drop via the validateDrop method.  The data source should incorporate the data from the dragging pasteboard at this time.

- (BOOL)tableView:(NSTableView*)tv
       acceptDrop:(id <NSDraggingInfo>)info
              row:(int)row
    dropOperation:(NSTableViewDropOperation)op{
	
    NSPasteboard *pboard = [info draggingPasteboard];
	
    if(tv == (NSTableView *)ccTableView){
        return NO; // can't drag into that tv.
    }
	
    if([[pboard types] containsObject:BDSKReferenceMinerStringPboardType]){ // pasteboard type from Reference Miner, determined using Pasteboard Peeker
        BOOL error;
        NSArray *pubs = [PubMedParser itemsFromString:[pboard stringForType:BDSKReferenceMinerStringPboardType] error:&error];
        if(!error)
            [self addPublications:pubs];
        return !error;
    }
            
    NSString * myError;
    BOOL result = [self addPublicationsFromPasteboard:pboard error:&myError];
    
    if (result) [self updateUI];
    return result;
}





#pragma mark || Methods to support the type-ahead selector.

- (void)updateTypeAheadStatus:(NSString *)searchString{
    if(!searchString)
        [self updateUI]; // resets the status line to its default value
    else
        [self setStatus:[NSString stringWithFormat:@"%@ \"%@\"", NSLocalizedString(@"Finding item with author or title:", @""), searchString]];
}

- (NSArray *)typeAheadSelectionItems{
    NSEnumerator *e = [shownPublications objectEnumerator];
    NSMutableArray *a = [NSMutableArray arrayWithCapacity:[shownPublications count]];
    BibItem *pub = nil;

    while(pub = [e nextObject]){
        [a addObject:[[pub bibTeXAuthorString] stringByAppendingString:[pub title]]];
    }
    return a;
}
    // This is where we build the list of possible items which the user can select by typing the first few letters. You should return an array of NSStrings.

- (NSString *)currentlySelectedItem{
    int n = [self numberOfSelectedPubs];
    BibItem *bib;
    if (n == 1){
        bib = [shownPublications objectAtIndex:[tableView selectedRow] usingLock:pubsLock];
        return [[bib bibTeXAuthorString] stringByAppendingString:[bib title]];
    }else{
        return nil;
    }
}
// Type-ahead-selection behavior can change if an item is currently selected (especially if the item was selected by type-ahead-selection). Return nil if you have no selection or a multiple selection.

// fixme -  also need to call the processkeychars in keydown...
- (void)typeAheadSelectItemAtIndex:(int)itemIndex{
    [self highlightBib:[shownPublications objectAtIndex:itemIndex usingLock:pubsLock] byExtendingSelection:NO];
}
// We call this when a type-ahead-selection match has been made; you should select the item based on its index in the array you provided in -typeAheadSelectionItems.



- (NSArray *)tableView:(NSTableView *)tv namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)indexSet;
{
    unsigned rowIdx = [indexSet firstIndex];
    NSMutableDictionary *fullPathDict = [NSMutableDictionary dictionaryWithCapacity:[indexSet count]];
    
    // We're supposed to return this to our caller (usually the Finder); just an array of file names, not full paths
    NSMutableArray *fileNames = [NSMutableArray arrayWithCapacity:[indexSet count]];
    
    NSURL *url = nil;
    NSString *fullPath = nil;
    BibItem *theBib = nil;
    
    // this ivar stores the field name (e.g. Url, L2)
    NSString *fieldName = [self promiseDragColumnIdentifier];
    
    // create a dictionary with each destination file path as key (handed to us from the Finder/dropDestination) and each item's URL as value
    while(rowIdx != NSNotFound){
        theBib = [shownPublications objectAtIndex:rowIdx];
        if((url = [theBib remoteURLForField:fieldName])){
            fullPath = [[[dropDestination path] stringByAppendingPathComponent:[theBib displayTitle]] stringByAppendingPathExtension:@"webloc"];
            [fullPathDict setValue:url forKey:fullPath];
            [fileNames addObject:[theBib displayTitle]];
        }
        rowIdx = [indexSet indexGreaterThanIndex:rowIdx];
    }
    [self setPromiseDragColumnIdentifier:nil];
    
    // We generally want to run promised file creation in the background to avoid blocking our UI, although these files are so small it probably doesn't matter.
    [NSThread detachNewThreadSelector:@selector(createWeblocFiles:) toTarget:self withObject:fullPathDict];

    return fileNames;
}

- (void)createWeblocFiles:(NSDictionary *)fullPathDict{
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NS_DURING    
        NSString *path;
        NSEnumerator *pathEnum = [fullPathDict keyEnumerator];
    
    while(path = [pathEnum nextObject])
        [[NSFileManager defaultManager] createWeblocFileAtPath:path withURL:[fullPathDict objectForKey:path]];
    NS_HANDLER
        NSLog(@"%@: discarding %@: %@", NSStringFromSelector(_cmd), [localException name], [localException reason]);
    NS_ENDHANDLER
    
    [pool release];
}

- (void)setPromiseDragColumnIdentifier:(NSString *)identifier;
{
    if(promiseDragColumnIdentifier != identifier){
        [promiseDragColumnIdentifier release];
        promiseDragColumnIdentifier = [identifier copy];
    }
}

- (NSString *)promiseDragColumnIdentifier;
{
    return promiseDragColumnIdentifier;
}


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

