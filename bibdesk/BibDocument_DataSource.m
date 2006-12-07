//  BibDocument_DataSource.m

//  Created by Michael McCracken on Tue Mar 26 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006
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
#import "BDSKGroupCell.h"
#import "BDSKGroup.h"
#import "BDSKScriptHookManager.h"
#import "BibDocument_Groups.h"
#import "BibDocument_Search.h"
#import "NSBezierPath_BDSKExtensions.h"
#import "BDSKPreviewer.h"
#import "BDSKMainTableView.h"
#import "BDSKGroupTableView.h"
#import "NSFileManager_BDSKExtensions.h"
#import "BDSKAlert.h"
#import "BibTypeManager.h"
#import "NSURL_BDSKExtensions.h"
#import "NSFileManager_ExtendedAttributes.h"
#import "NSSet_BDSKExtensions.h"
#import "BibEditor.h"
#import "BDSKSharedGroup.h"
#import "NSGeometry_BDSKExtensions.h"
#import "BDSKTemplate.h"
#import "BDSKTypeSelectHelper.h"
#import "NSWindowController_BDSKExtensions.h"

@implementation BibDocument (DataSource)

#pragma mark TableView data source

- (int)numberOfRowsInTableView:(NSTableView *)tView{
    if(tView == (NSTableView *)tableView){
        return [shownPublications count];
    }else if(tView == (NSTableView *)ccTableView){
        return [customStringArray count];
    }else if(tView == groupTableView){
        return [self countOfGroups];
    }else{
// should raise an exception or something
        return 0;
    }
}

- (id)tableView:(NSTableView *)tView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    BibItem* pub = nil;
    NSArray *auths = nil;

    NSString *tcID = [tableColumn identifier];
    
    // Shark shows this is a performance hit if we call NSUserDefaults every time, so we'll cache it (presumably it doesn't change that often anyway).
    static NSString *shortDateFormatString = nil;
    if(shortDateFormatString == nil)
        shortDateFormatString = [[[NSUserDefaults standardUserDefaults] stringForKey:NSShortDateFormatString] copy];
    BibTypeManager *typeManager = [BibTypeManager sharedManager];
    
    if(row >= 0 && tView == tableView){ // sortedRow can be -1 if you delete the last pub and sortDescending is true
        pub = [shownPublications objectAtIndex:row];
        auths = [pub pubAuthors];
        
        if([tcID isEqualToString:BDSKCiteKeyString]){
            return [pub citeKey];
        }else if([tcID isEqualToString:BDSKItemNumberString]){
            return [pub fileOrder];
        }else if([tcID isEqualToString: BDSKTitleString] ){
			return [pub title];
		}else if([tcID isEqualToString: BDSKContainerString] ){
			return [pub container];
        }else if([tcID isEqualToString: BDSKDateAddedString]){
            return [[pub dateAdded] descriptionWithCalendarFormat:shortDateFormatString];
        }else if([tcID isEqualToString: BDSKDateModifiedString]){
			return [[pub dateModified] descriptionWithCalendarFormat:shortDateFormatString];
        }else if([tcID isEqualToString: BDSKDateString] ){
			NSString *value = [pub valueOfField:BDSKDateString];
			if([NSString isEmptyString:value] == NO)
				return value;
            NSCalendarDate *date = [pub date];
            if(nil == date) 
                return nil;
			NSString *monthStr = [pub valueOfField:BDSKMonthString];
            if([NSString isEmptyString:monthStr])
                return [date descriptionWithCalendarFormat:@"%Y"];
            else
                return [date descriptionWithCalendarFormat:@"%b %Y"];
        }else if([tcID isEqualToString: BDSKFirstAuthorString] ){
			return [[pub authorAtIndex:0] displayName];
        }else if([tcID isEqualToString: BDSKSecondAuthorString] ){
			return [[pub authorAtIndex:1] displayName]; 
        }else if([tcID isEqualToString: BDSKThirdAuthorString] ){
			return [[pub authorAtIndex:2] displayName];
        }else if([tcID isEqualToString:BDSKLastAuthorString] ){
			return [[pub lastAuthor] displayName];
        }else if([tcID isEqualToString: BDSKFirstAuthorEditorString] ){
			return [[pub authorOrEditorAtIndex:0] displayName];
        }else if([tcID isEqualToString: BDSKSecondAuthorEditorString] ){
			return [[pub authorOrEditorAtIndex:1] displayName]; 
        }else if([tcID isEqualToString: BDSKThirdAuthorEditorString] ){
			return [[pub authorOrEditorAtIndex:2] displayName];
        }else if([tcID isEqualToString:BDSKLastAuthorEditorString] ){
			return [[pub lastAuthorOrEditor] displayName];
		} else if([tcID isEqualToString:BDSKAuthorString]) {
			return [pub pubAuthorsForDisplay];
		} else if([tcID isEqualToString:BDSKAuthorEditorString]){
			return [pub pubAuthorsOrEditorsForDisplay];
        } else if([tcID isEqualToString:BDSKEditorString]) {
			return [pub peopleStringForDisplayFromField:BDSKEditorString];
        }else if([typeManager isURLField:tcID]){
            return [pub smallImageForURLField:tcID];
		}else if([typeManager isRatingField:tcID]){
			return [NSNumber numberWithInt:[pub ratingValueOfField:tcID]];
		}else if([typeManager isBooleanField:tcID]){
            return [NSNumber numberWithBool:[pub boolValueOfField:tcID]];
		}else if([typeManager isTriStateField:tcID]){
			return [NSNumber numberWithInt:[pub triStateValueOfField:tcID]];
		}else if([tcID isEqualToString:BDSKPubTypeString]){
			return [pub pubType];
        }else{
            // the tableColumn isn't something we handle in a custom way.
            return [pub valueOfField:tcID];
        }

    }else if(tView == (NSTableView *)ccTableView){
        return [customStringArray objectAtIndex:row];
    }else if(tView == groupTableView){
		return [self objectInGroupsAtIndex:row];
    }else return nil;
}

- (void)tableView:(NSTableView *)tv setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    if(tv == (NSTableView *)ccTableView){
		[customStringArray replaceObjectAtIndex:row withObject:object];
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:customStringArray forKey:BDSKCustomCiteStringsKey];
	}else if (tv == tableView){
        BibTypeManager *typeManager = [BibTypeManager sharedManager];

		NSString *tcID = [tableColumn identifier];
		if([typeManager isRatingField:tcID]){
			BibItem *pub = [shownPublications objectAtIndex:row];
			int oldRating = [pub ratingValueOfField:tcID];
			int newRating = [object intValue];
			if(newRating != oldRating) {
				[pub setField:tcID toRatingValue:newRating];
				BDSKScriptHook *scriptHook = [[BDSKScriptHookManager sharedManager] makeScriptHookWithName:BDSKChangeFieldScriptHookName];
				if (scriptHook) {
					[scriptHook setField:tcID];
					[scriptHook setOldValues:[NSArray arrayWithObject:[NSString stringWithFormat:@"%i", oldRating]]];
					[scriptHook setNewValues:[NSArray arrayWithObject:[NSString stringWithFormat:@"%i", newRating]]];
					[[BDSKScriptHookManager sharedManager] runScriptHook:scriptHook forPublications:[NSArray arrayWithObject:pub] document:self];
				}
				[[pub undoManager] setActionName:NSLocalizedString(@"Change Rating",@"Change Rating")];
			}
		}else if([typeManager isBooleanField:tcID]){
			BibItem *pub = [shownPublications objectAtIndex:row];
            NSCellStateValue oldStatus = [pub boolValueOfField:tcID];
			NSCellStateValue newStatus = [object intValue];
			if(newStatus != oldStatus) {
				[pub setField:tcID toBoolValue:newStatus];
				BDSKScriptHook *scriptHook = [[BDSKScriptHookManager sharedManager] makeScriptHookWithName:BDSKChangeFieldScriptHookName];
				if (scriptHook) {
					[scriptHook setField:tcID];
					[scriptHook setOldValues:[NSArray arrayWithObject:[NSString stringWithBool:oldStatus]]];
					[scriptHook setNewValues:[NSArray arrayWithObject:[NSString stringWithBool:newStatus]]];
					[[BDSKScriptHookManager sharedManager] runScriptHook:scriptHook forPublications:[NSArray arrayWithObject:pub] document:self];
				}
				[[pub undoManager] setActionName:NSLocalizedString(@"Change Check Box",@"Change Check Box")];
			}
		}else if([typeManager isTriStateField:tcID]){
			BibItem *pub = [shownPublications objectAtIndex:row];
            NSCellStateValue oldStatus = [pub triStateValueOfField:tcID];
			NSCellStateValue newStatus = [object intValue];
			if(newStatus != oldStatus) {
				[pub setField:tcID toTriStateValue:newStatus];
				BDSKScriptHook *scriptHook = [[BDSKScriptHookManager sharedManager] makeScriptHookWithName:BDSKChangeFieldScriptHookName];
				if (scriptHook) {
					[scriptHook setField:tcID];
					[scriptHook setOldValues:[NSArray arrayWithObject:[NSString stringWithTriStateValue:oldStatus]]];
					[scriptHook setNewValues:[NSArray arrayWithObject:[NSString stringWithTriStateValue:newStatus]]];
					[[BDSKScriptHookManager sharedManager] runScriptHook:scriptHook forPublications:[NSArray arrayWithObject:pub] document:self];
				}
				[[pub undoManager] setActionName:NSLocalizedString(@"Change Check Box",@"Change Check Box")];
			}
		}
	}else if(tv == groupTableView){
		BDSKGroup *group = [self objectInGroupsAtIndex:row];
		// we need to check for this because for some reason setObjectValue:... is called when the row is selected in this tableView
		if([NSString isEmptyString:object] || [[group stringValue] isEqualToString:object])
			return;
		if([group isSmart] == YES){
			[(BDSKSmartGroup *)group setName:object];
			[[self undoManager] setActionName:NSLocalizedString(@"Rename Smart Group",@"Rename smart group")];
			[self sortGroupsByKey:sortGroupsKey];
		}else if([group isStatic] == YES){
			[(BDSKStaticGroup *)group setName:object];
			[[self undoManager] setActionName:NSLocalizedString(@"Rename Static Group",@"Rename static group")];
			[self sortGroupsByKey:sortGroupsKey];
		}else{
			NSArray *pubs = [groupedPublications copy];
			[self movePublications:pubs fromGroup:group toGroupNamed:object];
			[pubs release];
		}
	}
}

#pragma mark TableView delegate

- (void)disableWarningAlertDidEnd:(BDSKAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if ([alert checkValue] == YES) {
		[[OFPreferenceWrapper sharedPreferenceWrapper] setBool:NO forKey:BDSKWarnOnRenameGroupKey];
	}
}

- (BOOL)tableView:(NSTableView *)tv shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)row{
    if(tv == (NSTableView *)ccTableView){
		return YES;
	}else if(tv == groupTableView){
		if ([[self objectInGroupsAtIndex:row] hasEditableName] == NO) 
			return NO;
		else if (NSLocationInRange(row, [self rangeOfCategoryGroups]) &&
				 [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKWarnOnRenameGroupKey]) {
			
			BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Warning", @"Warning")
												 defaultButton:NSLocalizedString(@"OK", @"OK")
											   alternateButton:nil
												   otherButton:NSLocalizedString(@"Cancel", @"Cancel")
									 informativeTextWithFormat:NSLocalizedString(@"This action will change the %@ field in %i items. Do you want to proceed?", @""), currentGroupField, [groupedPublications count]];
			[alert setHasCheckButton:YES];
			[alert setCheckValue:NO];
			int rv = [alert runSheetModalForWindow:documentWindow
									 modalDelegate:self 
									didEndSelector:@selector(disableWarningAlertDidEnd:returnCode:contextInfo:) 
								didDismissSelector:NULL 
									   contextInfo:BDSKWarnOnRenameGroupKey];
			if (rv == NSAlertOtherReturn)
				return NO;
		}
		return YES;
	}
    return NO;
}

- (void)tableView:(NSTableView *)tv willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)row{
    if (row == -1) return;
    if (tv == tableView) {
        if ([aCell isKindOfClass:[NSButtonCell class]]) {
            if ([[shownPublications objectAtIndex:row] document] == nil) 
                [aCell setEnabled:NO];
            else
                [aCell setEnabled:YES];
        }
    } else if (tv == groupTableView) {
        BDSKGroup *group = [self objectInGroupsAtIndex:row];
        if ([group isShared] == NO) return;
        
        NSProgressIndicator *spinner = [sharedGroupSpinners objectForKey:[group name]];
        
        if ([(BDSKSharedGroup *)group isRetrieving]) {
            int column = [[tv tableColumns] indexOfObject:aTableColumn];
            NSRect ignored, rect = [tv frameOfCellAtColumn:column row:row];
            NSSize size = [spinner frame].size;
            NSDivideRect(rect, &ignored, &rect, 3.0f, NSMaxXEdge);
            NSDivideRect(rect, &rect, &ignored, size.width, NSMaxXEdge);
            rect = BDSKCenterRectVertically(rect, size.height, [tv isFlipped]);
            
            [spinner setFrame:rect];
            if([[tv subviews] containsObject:spinner] == NO)
                [tv addSubview:spinner];
            [spinner startAnimation:nil];
        } else {
            [spinner stopAnimation:nil];
            [spinner removeFromSuperview];
        }
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
	NSTableView *tv = [aNotification object];
    if(tv == tableView){
        NSNotification *note = [NSNotification notificationWithName:BDSKTableSelectionChangedNotification object:self];
        [[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName forModes:nil];
    }else if(tv == (NSTableView *)ccTableView){
		[removeCustomCiteStringButton setEnabled:([tv numberOfSelectedRows] > 0)];
	}else if(tv == groupTableView){
        NSNotification *note = [NSNotification notificationWithName:BDSKGroupTableSelectionChangedNotification object:self];
        [[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName forModes:nil];
    }
}

- (void)tableViewColumnDidResize:(NSNotification *)notification{
	if([notification object] != tableView) return;
    
	OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
    NSMutableDictionary *columns = [[[pw objectForKey:BDSKColumnWidthsKey] mutableCopy] autorelease];
    NSEnumerator *tcE = [[tableView tableColumns] objectEnumerator];
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
	if([notification object] != tableView) return;
    
	NSMutableArray *columnsInOrder = [NSMutableArray arrayWithCapacity:5];

    NSEnumerator *tcE = [[tableView tableColumns] objectEnumerator];
    NSTableColumn *tc = nil;

    while(tc = (NSTableColumn *) [tcE nextObject]){
        [columnsInOrder addObject:[tc identifier]];
    }

    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:columnsInOrder
                                                      forKey:BDSKShownColsNamesKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKTableColumnChangedNotification
                                                        object:self];

}

- (BOOL)tableViewShouldEditNextItemWhenEditingEnds:(NSTableView *)tv{
	if (tv == groupTableView && [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKWarnOnRenameGroupKey])
		return NO;
	return YES;
}

- (NSString *)tableViewFontNamePreferenceKey:(NSTableView *)tv {
    if (tv == tableView)
        return BDSKMainTableViewFontNameKey;
    else if (tv == groupTableView)
        return BDSKGroupTableViewFontNameKey;
    else 
        return nil;
}

- (NSString *)tableViewFontSizePreferenceKey:(NSTableView *)tv {
    if (tv == tableView)
        return BDSKMainTableViewFontSizeKey;
    else if (tv == groupTableView)
        return BDSKGroupTableViewFontSizeKey;
    else 
        return nil;
}

#pragma mark TableView dragging source

// for 10.3 compatibility and OmniAppKit dataSource methods
- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard{
	NSMutableIndexSet *rowIndexes = [NSMutableIndexSet indexSet];
	NSEnumerator *rowEnum = [rows objectEnumerator];
	NSNumber *row;
	
	while (row = [rowEnum nextObject]) 
		[rowIndexes addIndex:[row intValue]];
	
	return [self tableView:tv writeRowsWithIndexes:rowIndexes toPasteboard:pboard];
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard{
    OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
	int dragCopyType = [sud integerForKey:BDSKDragCopyKey];
    BOOL yn = NO;
	NSString *citeString = [sud stringForKey:BDSKCiteStringKey];
    NSArray *pubs = nil;
	
	OBPRECONDITION(pboard == [NSPasteboard pasteboardWithName:NSDragPboard] || pboard == [NSPasteboard pasteboardWithName:NSGeneralPboard]);

    dragFromSharedGroups = NO;
	
    if(tv == groupTableView){
		if([rowIndexes containsIndex:0]){
			pubs = [[publications copy] autorelease];
		}else if([rowIndexes count] > 1){
			// multiple dragged rows always are the selected rows
			pubs = [[groupedPublications copy] autorelease];
		}else if([rowIndexes count] == 1){
            // a single row, not necessarily the selected one
            BDSKGroup *group = [self objectInGroupsAtIndex:[rowIndexes firstIndex]];
            if ([group isShared]) {
                pubs = [(BDSKSharedGroup *)group publications];
			} else {
                NSArray *allPubs = [publications copy];
                NSMutableArray *pubsInGroup = [NSMutableArray arrayWithCapacity:[allPubs count]];
                NSEnumerator *pubEnum = [allPubs objectEnumerator];
                BibItem *pub;
                [allPubs release];
                
                while (pub = [pubEnum nextObject]) {
                    if ([group containsItem:pub]) 
                        [pubsInGroup addObject:pub];
                }
                pubs = pubsInGroup;
            }
            dragFromSharedGroups = [self hasSharedGroupsAtIndexes:rowIndexes];
		}
		if([pubs count] == 0){
            NSBeginAlertSheet(NSLocalizedString(@"Empty Groups", @""),nil,nil,nil,documentWindow,nil,NULL,NULL,NULL,
                              NSLocalizedString(@"The groups you want to drag do not contain any items.", @""));
            return NO;
        }
			
    } else if(tv == (NSTableView *)ccTableView){
		// drag from the custom cite drawer table
		// check the publications table to see if an item is selected, otherwise we get an error on dragging from the cite drawer
		if([tableView numberOfSelectedRows] == 0){
            NSBeginAlertSheet(NSLocalizedString(@"Nothing selected in document", @""),nil,nil,nil,documentWindow,nil,NULL,NULL,NULL,
                              NSLocalizedString(@"You need to select an item in the document before dragging from the cite drawer.", @""));
            return NO;
        }

        citeString = [customStringArray objectAtIndex:[rowIndexes firstIndex]];
		// firstIndex is ok because we don't allow multiple selections in ccTV.

        // if it's the ccTableView, then rows has the rows of the ccTV.
        // we need to change rows to be the main TV's selected rows,
        // so that the regular code still works
        pubs = [self selectedPublications];
        dragCopyType = 1; // only type that makes sense here
        
        dragFromSharedGroups = [self hasSharedGroupsAtIndexes:[groupTableView selectedRowIndexes]];
    }else{
		// drag from the main table
		pubs = [shownPublications objectsAtIndexes:rowIndexes];
        
        dragFromSharedGroups = [self hasSharedGroupsAtIndexes:[groupTableView selectedRowIndexes]];

		if(pboard == [NSPasteboard pasteboardWithName:NSDragPboard]){
			// see where we clicked in the table
			// if we clicked on a local file column that has a file, we'll copy that file
			// if we clicked on a remote URL column that has a URL, we'll copy that URL
			// but only if we were passed a single row for now
			
			// we want the drag to occur for the row that is dragged, not the row that is selected
			if([rowIndexes count]){
				NSPoint eventPt = [[tv window] mouseLocationOutsideOfEventStream];
				NSPoint dragPosition = [tv convertPoint:eventPt fromView:nil];
				int dragColumn = [tv columnAtPoint:dragPosition];
				NSString *dragColumnId = nil;
						
				if(dragColumn == -1)
					return NO;
				
				dragColumnId = [[[tv tableColumns] objectAtIndex:dragColumn] identifier];
				
				if([[BibTypeManager sharedManager] isLocalFileField:dragColumnId]){

                    // if we have more than one row, we can't put file contents on the pasteboard, but most apps seem to handle file names just fine
                    unsigned row = [rowIndexes firstIndex];
                    BibItem *pub = nil;
                    NSString *path;
                    NSMutableArray *filePaths = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
                    [pboard declareTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil] owner:nil];

                    while(row != NSNotFound){
                        pub = [shownPublications objectAtIndex:row];
                        path = [pub localFilePathForField:dragColumnId];
                        if(path != nil){
                            [filePaths addObject:path];
                            if(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3){
                                NSError *xerror = nil;
                                // we can always write xattrs; this doesn't alter the original file's content in any way, but fails if you have a really long abstract/annote
                                if([[NSFileManager defaultManager] setExtendedAttributeNamed:OMNI_BUNDLE_IDENTIFIER @".bibtexstring" toValue:[[pub bibTeXString] dataUsingEncoding:NSUTF8StringEncoding] atPath:path options:nil error:&xerror] == NO)
                                    NSLog(@"%@ line %d: adding xattrs failed with error %@", __FILENAMEASNSSTRING__, __LINE__, xerror);
                                // writing the standard PDF metadata alters the original file, so we'll make it a separate preference; this is also really slow
                                if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShouldWritePDFMetadata])
                                    [pub addPDFMetadataToFileForLocalURLField:dragColumnId];
                            }
                        }
                        row = [rowIndexes indexGreaterThanIndex:row];
                    }

                    return [pboard setPropertyList:filePaths forType:NSFilenamesPboardType];
                    
				}else if([[BibTypeManager sharedManager] isRemoteURLField:dragColumnId]){
					// cache this so we know which column (field) was dragged
					[self setPromiseDragColumnIdentifier:dragColumnId];
					
					BibItem *pub = [shownPublications objectAtIndex:[rowIndexes firstIndex]];
					NSURL *url = [pub remoteURLForField:dragColumnId];
					if(url != nil){
						// put the URL and a webloc file promise on the pasteboard
						if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3){
							// ARM: file promise drags from a tableview are really buggy on 10.3 and earlier, and I don't feel like fighting them right now for webloc files (which require a destination path for creation)
							[pboard declareTypes:[NSArray arrayWithObjects:NSURLPboardType, nil] owner:self];
							[url writeToPasteboard:pboard];
							yn = YES;
						} else {
							[pboard declareTypes:[NSArray arrayWithObjects:NSFilesPromisePboardType, NSURLPboardType, nil] owner:self];
							yn = [pboard setPropertyList:[NSArray arrayWithObject:[[pub displayTitle] stringByAppendingPathExtension:@"webloc"]] forType:NSFilesPromisePboardType];
							[url writeToPasteboard:pboard];
						}
						return yn;
					}
				}
			}
		}
    }
	
	return [self writePublications:pubs forDragCopyType:dragCopyType citeString:citeString toPasteboard:pboard];
}
	
- (BOOL)writePublications:(NSArray *)pubs forDragCopyType:(int)dragCopyType citeString:(NSString *)citeString toPasteboard:(NSPasteboard*)pboard{
	NSMutableArray *promisedTypes = [NSMutableArray arrayWithObjects:BDSKBibItemPboardType, nil];
	NSString *mainType = nil;
	NSString *string = nil;
	NSData *data = nil;
    BOOL yn = YES;
	
	switch(dragCopyType){
		case BDSKBibTeXDragCopyType:
			mainType = NSStringPboardType;
			string = [self bibTeXStringForPublications:pubs];
			OBASSERT(string != nil);
			break;
		case BDSKCiteDragCopyType:
			mainType = NSStringPboardType;
			string = [self citeStringForPublications:pubs citeString:citeString];
			OBASSERT(string != nil);
			break;
		case BDSKPDFDragCopyType:
			mainType = NSPDFPboardType;
			if([pubs isEqualToArray:[self selectedPublications]] &&
			   [[BDSKPreviewer sharedPreviewer] isWindowVisible]){
				// we are copying, and the previewer is showing, so we reuse it's PDF data if available
				data = [[BDSKPreviewer sharedPreviewer] PDFData];
			}
			break;
		case BDSKRTFDragCopyType:
			mainType = NSRTFPboardType;
			if([pubs isEqualToArray:[self selectedPublications]] &&
			   [[BDSKPreviewer sharedPreviewer] isWindowVisible]){
				// we are copying, and the previewer is showing, so we reuse it's RTF data if available
				data = [[BDSKPreviewer sharedPreviewer] RTFData];
			}
			break;
		case BDSKLaTeXDragCopyType:
			mainType = NSStringPboardType;
			if([pubs isEqualToArray:[self selectedPublications]] &&
			   [[BDSKPreviewer sharedPreviewer] isWindowVisible]){
				// we are copying, and the previewer is showing, so we reuse it's LaTeX string if available
				string = [[BDSKPreviewer sharedPreviewer] LaTeXString];
			}
			break;
		case BDSKLTBDragCopyType:
			mainType = NSStringPboardType;
			break;
		case BDSKMinimalBibTeXDragCopyType:
			mainType = NSStringPboardType;
			string = [self bibTeXStringDroppingInternal:YES forPublications:pubs];
			OBASSERT(string != nil);
			break;
		case BDSKRISDragCopyType:
			mainType = NSStringPboardType;
			string = [self RISStringForPublications:pubs];
			break;
		default:
            do{
                NSString *style = [[BDSKTemplate allStyleNames] objectAtIndex:dragCopyType - BDSKTemplateDragCopyType];
                BDSKTemplate *template = [BDSKTemplate templateForStyle:style];
                BDSKTemplateFormat format = [template templateFormat];
                if (format & BDSKTextTemplateFormat) {
                    mainType = NSStringPboardType;
                    string = [BDSKTemplateObjectProxy stringByParsingTemplate:template withObject:self publications:pubs];
                } else if (format & BDSKRichTextTemplateFormat) {
                    NSDictionary *docAttributes = nil;
                    NSAttributedString *templateString = [BDSKTemplateObjectProxy attributedStringByParsingTemplate:template withObject:self publications:pubs documentAttributes:&docAttributes];
                    if (format & BDSKRTFDTemplateFormat) {
                        mainType = NSRTFDPboardType;
                        data = [templateString RTFDFromRange:NSMakeRange(0,[templateString length]) documentAttributes:docAttributes];
                    } else {
                        mainType = NSRTFPboardType;
                        data = [templateString RTFFromRange:NSMakeRange(0,[templateString length]) documentAttributes:docAttributes];
                    }
                }
            }while(0);
	}
    
	[pboard declareTypes:[NSArray arrayWithObjects:mainType, BDSKBibItemPboardType, nil] owner:self];
	
	if([mainType isEqualToString:NSStringPboardType]){
		if(string == nil) // This should be a LaTeX string. We provide it lazily when needed 
			[promisedTypes insertObject:NSStringPboardType atIndex:0];
		else
			yn = [pboard setString:string forType:NSStringPboardType];
	}else if(mainType){
		if(data == nil) // We provide the data lazily when needed 
			[promisedTypes insertObject:mainType atIndex:0];
		else
			yn = [pboard setData:data forType:mainType];
	}
	
	[self setPromisedItems:pubs types:promisedTypes dragCopyType:dragCopyType forPasteboard:pboard];

    return yn;
}

- (void)tableView:(NSTableView *)aTableView concludeDragOperation:(NSDragOperation)operation{
	[self clearPromisedTypesForPasteboard:[NSPasteboard pasteboardWithName:NSDragPboard]];
}

// we generate PDF, RTF and archived items data only when they are dropped or pasted
- (void)pasteboard:(NSPasteboard *)pboard provideDataForType:(NSString *)type{
	NSArray *items = [self promisedItemsForPasteboard:pboard];
	
	if(items != nil){
		if([type isEqualToString:NSPDFPboardType]){
			NSString *bibString = [self previewBibTeXStringForPublications:items];
			if(bibString != nil && 
			   [texTask runWithBibTeXString:bibString generatedTypes:BDSKGeneratePDF] && 
			   [texTask hasPDFData]){
				[pboard setData:[texTask PDFData] forType:NSPDFPboardType];
			}else{
				NSBeep();
			}
		}else if([type isEqualToString:NSRTFPboardType]){
			NSString *bibString = [self previewBibTeXStringForPublications:items];
			if(bibString != nil && 
			   [texTask runWithBibTeXString:bibString generatedTypes:BDSKGenerateRTF] && 
			   [texTask hasRTFData]){
				[pboard setData:[texTask RTFData] forType:NSRTFPboardType];
			}else{
				NSBeep();
			}
		}else if([type isEqualToString:NSStringPboardType]){
			// this must be LaTeX or amsrefs LTB
			NSString *bibString = [self previewBibTeXStringForPublications:items];
			int dragCopyType = [self promisedDragCopyTypeForPasteboard:pboard];
			if(dragCopyType == BDSKLTBDragCopyType){
				if(bibString != nil && 
				   [texTask runWithBibTeXString:bibString generatedTypes:BDSKGenerateLTB] && 
				   [texTask hasLTB]){
					[pboard setString:[texTask LTBString] forType:NSStringPboardType];
				}else{
					NSBeep();
				}
			}else{
				if(bibString != nil && 
				   [texTask runWithBibTeXString:bibString generatedTypes:BDSKGenerateLaTeX] && 
				   [texTask hasLaTeX]){
					[pboard setString:[texTask LaTeXString] forType:NSStringPboardType];
				}else{
					NSBeep();
				}
			}
		}else if([type isEqualToString:BDSKBibItemPboardType]){
            NSMutableData *data = [NSMutableData data];
            NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
            
            [archiver encodeObject:items forKey:@"publications"];
            [archiver finishEncoding];
            [archiver release];
			
            [pboard setData:data forType:BDSKBibItemPboardType];
		}
	}
	[self removePromisedType:type forPasteboard:pboard];
}

- (NSDragOperation)tableView:(NSTableView *)tv draggingSourceOperationMaskForLocal:(BOOL)isLocal{
	if (tv == tableView) {
		return (isLocal)? NSDragOperationEvery : NSDragOperationCopy;
	} else if (tv == ccTableView) {
		return (isLocal)? NSDragOperationNone : NSDragOperationCopy;
	} else {
		return (isLocal)? NSDragOperationEvery : NSDragOperationCopy;
	}
}

- (NSImage *)tableView:(NSTableView *)tv dragImageForRowsWithIndexes:(NSIndexSet *)dragRows{
    NSImage *image = nil;
    
    NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSDragPboard];
    NSString *dragType = [pb availableTypeFromArray:[NSArray arrayWithObjects:NSFilenamesPboardType, NSURLPboardType, NSFilesPromisePboardType, NSPDFPboardType, NSRTFPboardType, NSStringPboardType, nil]];
	NSArray *promisedDraggedItems = [self promisedItemsForPasteboard:[NSPasteboard pasteboardWithName:NSDragPboard]];
	int dragCopyType = -1;
	int count = 0;
	
    if ([dragType isEqualToString:NSFilenamesPboardType]) {
		NSArray *fileNames = [pb propertyListForType:NSFilenamesPboardType];
		count = [fileNames count];
        NSURL *fileURL = count ? [NSURL fileURLWithPath:[[pb propertyListForType:NSFilenamesPboardType] objectAtIndex:0]] : nil;
        fileURL = [fileURL fileURLByResolvingAliases];
		image = fileURL != nil ? [NSImage imageForURL:fileURL] : [NSImage missingFileImage];
    
    } else if ([dragType isEqualToString:NSURLPboardType]) {
        count = 1;
        image = [[[NSImage imageForURL:[NSURL URLFromPasteboard:pb]] copy] autorelease];
		[image setSize:NSMakeSize(32,32)];
    
	} else if ([dragType isEqualToString:NSFilesPromisePboardType]) {
		NSArray *fileNames = [pb propertyListForType:NSFilesPromisePboardType];
		count = [fileNames count];
        image = [NSImage imageForFileType:[[fileNames lastObject] pathExtension]];
    
	} else {
		OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
		NSMutableString *s = [NSMutableString string];
		BibItem *firstItem = [promisedDraggedItems objectAtIndex:0];
		BOOL sep;
		
		dragCopyType = [sud integerForKey:BDSKDragCopyKey];
		// don't depend on this being non-zero; this method gets called for drags where promisedDraggedItems is nil
		count = [promisedDraggedItems count];
		
		// we draw only the first item and indicate other items using ellipsis
		switch (dragCopyType) {
			case BDSKBibTeXDragCopyType:
				[s appendString:[firstItem bibTeXStringDroppingInternal:YES]];
				if (count > 1) {
					[s appendString:@"\n"];
					[s appendString:[NSString horizontalEllipsisString]];
				}
				break;
			case BDSKCiteDragCopyType:
				sep = [sud boolForKey:BDSKSeparateCiteKey];
				
				if ([sud boolForKey:BDSKCitePrependTildeKey])
					[s appendString:@"~"];
				[s appendString:@"\\"];
				if (tv == ccTableView) 
					[s appendString:[customStringArray objectAtIndex:[dragRows firstIndex]]];
				else
					[s appendString:[sud stringForKey:BDSKCiteStringKey]];
				[s appendString:[sud stringForKey:BDSKCiteStartBracketKey]];
				[s appendString:[firstItem citeKey]];
				if (count > 1 && sep == NO) {
					[s appendString:@","];
					[s appendString:[NSString horizontalEllipsisString]];
				}
				[s appendString:[sud stringForKey:BDSKCiteEndBracketKey]];
				if (count > 1 && sep == YES) 
					[s appendString:[NSString horizontalEllipsisString]];
				break;
			case BDSKPDFDragCopyType:
			case BDSKRTFDragCopyType:
				[s appendString:@"["];
				[s appendString:[firstItem citeKey]];
				[s appendString:@"]"];
				if (count > 1) 
					[s appendString:[NSString horizontalEllipsisString]];
				break;
			case BDSKLaTeXDragCopyType:
				[s appendString:@"\\bibitem{"];
				[s appendString:[firstItem citeKey]];
				[s appendString:@"}"];
				if (count > 1) 
					[s appendString:[NSString horizontalEllipsisString]];
		}
		
		NSAttributedString *attrString = [[[NSAttributedString alloc] initWithString:s] autorelease];
		NSSize size = [attrString size];
		NSRect rect = NSZeroRect;
		NSPoint point = NSMakePoint(3.0, 2.0); // offset of the string
		NSColor *color = [NSColor secondarySelectedControlColor];
		
        if (size.width == 0 || size.height == 0) {
            NSLog(@"string size was zero");
            size = NSMakeSize(30.0,20.0); // work around bug in NSAttributedString
        }
        
		size.width += 2 * point.x;
		size.height += 2 * point.y;
		rect.size = size;
		rect = NSInsetRect(rect, 1.0, 1.0); // inset by half of the linewidth
		
		image = [[[NSImage alloc] initWithSize:size] autorelease];
        
        [image lockFocus];
        
		[NSGraphicsContext saveGraphicsState];
		[[color colorWithAlphaComponent:0.2] setFill];
		[NSBezierPath fillRoundRectInRect:rect radius:4.0];
		[[color colorWithAlphaComponent:0.8] setStroke];
		[NSBezierPath setDefaultLineWidth:2.0];
		[NSBezierPath strokeRoundRectInRect:rect radius:4.0];
		
		NSRectClip(NSInsetRect(rect, 2.0, 2.0));
        [attrString drawAtPoint:point];
		[NSGraphicsContext restoreGraphicsState];
        
        [image unlockFocus];
	}
	
    return [image dragImageWithCount:count inside:dragCopyType == BDSKBibTeXDragCopyType];
}

#pragma mark TableView dragging destination

- (NSDragOperation)tableView:(NSTableView*)tv
                validateDrop:(id <NSDraggingInfo>)info
                 proposedRow:(int)row
       proposedDropOperation:(NSTableViewDropOperation)op{
    
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKBibItemPboardType, BDSKWeblocFilePboardType, BDSKReferenceMinerStringPboardType, NSStringPboardType, NSFilenamesPboardType, NSURLPboardType, nil]];
    
    if(tv == (NSTableView *)ccTableView){
        return NSDragOperationNone;// can't drag into that tv.
    }else if(tv == tableView){
		if(type == nil) 
			return NSDragOperationNone;
		if ([info draggingSource] == groupTableView && dragFromSharedGroups && [groupTableView selectedRow] == 0) {
            [tv setDropRow:-1 dropOperation:NSTableViewDropOn];
            return NSDragOperationCopy;
        }
        if([info draggingSource] == tableView || [info draggingSource] == groupTableView || [info draggingSource] == ccTableView || type == nil) {
			// can't copy onto same table
			return NSDragOperationNone;
		}
        // set drop row to -1 and NSTableViewDropOperation to NSTableViewDropOn, when we don't target specific rows http://www.corbinstreehouse.com/blog/?p=123
        if(row == -1 || op == NSTableViewDropAbove || (row < [shownPublications count] && [[shownPublications objectAtIndex:row] document] == nil)){
            [tv setDropRow:-1 dropOperation:NSTableViewDropOn];
		}else if(([type isEqualToString:NSFilenamesPboardType] == NO || [[info draggingPasteboard] containsUnparseableFile] == NO) &&
                 [type isEqualToString:BDSKWeblocFilePboardType] == NO && [type isEqualToString:NSURLPboardType] == NO){
            [tv setDropRow:-1 dropOperation:NSTableViewDropOn];
        }
        if ([type isEqualToString:BDSKBibItemPboardType])   
            return NSDragOperationCopy;
        else
            return NSDragOperationEvery;
    }else if(tv == groupTableView){
		if (([info draggingSource] == groupTableView || [info draggingSource] == tableView) && dragFromSharedGroups) {
            if (row != 0)
                return NSDragOperationNone;
            [tv setDropRow:row dropOperation:NSTableViewDropOn];
            return NSDragOperationCopy;
        }
            
        // not sure why this check is necessary, but it silences an error message when you drag off the list of items
        if([info draggingSource] == ccTableView || [info draggingSource] == groupTableView || row >= [tv numberOfRows] || [[self objectInGroupsAtIndex:row]  isValidDropTarget] == NO || (type == nil && [info draggingSource] != tableView)) 
            return NSDragOperationNone;
        
        // here we actually target a specific row
        [tv setDropRow:row dropOperation:NSTableViewDropOn];
        if([info draggingSource] == tableView){
            if([type isEqualToString:BDSKBibItemPboardType])
                return NSDragOperationLink;
            else
                return NSDragOperationNone;
        } else if([type isEqualToString:BDSKBibItemPboardType]){
            return NSDragOperationCopy; // @@ can't drag row indexes from another document; should use NSArchiver instead
        }else{
            return NSDragOperationEvery;
        }
    }
    return NSDragOperationNone;
}

// This method is called when the mouse is released over a table view that previously decided to allow a drop via the validateDrop method.  The data source should incorporate the data from the dragging pasteboard at this time.

- (BOOL)tableView:(NSTableView*)tv
       acceptDrop:(id <NSDraggingInfo>)info
              row:(int)row
    dropOperation:(NSTableViewDropOperation)op{
	
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKBibItemPboardType, BDSKWeblocFilePboardType, BDSKReferenceMinerStringPboardType, NSStringPboardType, NSFilenamesPboardType, NSURLPboardType, nil]];
	
    if(tv == (NSTableView *)ccTableView){
        return NO; // can't drag into that tv.
    } else if(tv == tableView){
		if(row != -1){
            BibItem *pub = [shownPublications objectAtIndex:row];
            NSURL *theURL = nil;
            
            if([pub document] == nil){
                return NO;
            }else if([type isEqualToString:NSFilenamesPboardType]){
                NSArray *fileNames = [pboard propertyListForType:NSFilenamesPboardType];
                if ([fileNames count] == 0)
                    return NO;
                theURL = [NSURL fileURLWithPath:[[fileNames objectAtIndex:0] stringByExpandingTildeInPath]];
            }else if([type isEqualToString:BDSKWeblocFilePboardType]){
                theURL = [NSURL URLWithString:[pboard stringForType:BDSKWeblocFilePboardType]];
            }else if([type isEqualToString:NSURLPboardType]){
                theURL = [NSURL URLFromPasteboard:pboard];
            }else return NO;
            
            NSString *field = ([theURL isFileURL]) ? BDSKLocalUrlString : BDSKUrlString;
            
            if(theURL == nil || [theURL isEqual:[pub URLForField:field]])
                return NO;
            
            [pub setField:field toValue:[theURL absoluteString]];
            
            if([field isEqualToString:BDSKLocalUrlString])
                [pub autoFilePaperAfterDelay];
            
            [self highlightBib:pub];
            [[pub undoManager] setActionName:NSLocalizedString(@"Edit Publication",@"")];
            return YES;
            
        }else{
            [groupTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
            
            if([type isEqualToString:NSFilenamesPboardType]){
                NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
                if([filenames count] == 1){
                    NSString *file = [filenames lastObject];
                    if([[file pathExtension] caseInsensitiveCompare:@"aux"] == NSOrderedSame){
                        NSString *auxString = [NSString stringWithContentsOfFile:file encoding:[self documentStringEncoding] guessEncoding:YES];
                        
                        if (auxString == nil)
                            return NO;
                        
                        NSScanner *scanner = [NSScanner scannerWithString:auxString];
                        NSString *key = nil;
                        NSArray *items = nil;
                        NSMutableArray *selItems = [NSMutableArray array];
                        
                        while ([scanner isAtEnd] == NO && 
                               [scanner scanUpToString:@"\\bibcite{" intoString:NULL] && 
                               [scanner scanString:@"\\bibcite{" intoString:NULL]) {
                            if([scanner scanUpToString:@"}" intoString:&key]) {
                                if (items = [itemsForCiteKeys arrayForKey:key])
                                    [selItems addObjectsFromArray:items];
                            }
                        }
                        [self highlightBibs:selItems];
                        
                        return YES;
                    }
                }
            }
            
            BOOL result = [self addPublicationsFromPasteboard:pboard error:NULL];
            
            if (result) [self updateUI];
            return result;
        }
    } else if(tv == groupTableView){
        NSArray *pubs = nil;
        
        // retain is required to fix bug #1356183
        BDSKGroup *group = [[[self objectInGroupsAtIndex:row] retain] autorelease];
        BOOL shouldSelect = [[self selectedGroups] containsObject:group];
		
		if (([info draggingSource] == groupTableView || [info draggingSource] == tableView) && dragFromSharedGroups && row == 0) {
            return [self addPublicationsFromPasteboard:pboard error:NULL];
        } else if([info draggingSource] == groupTableView || [group isValidDropTarget] == NO) {
            return NO;
        } else if([info draggingSource] == tableView){
            // we already have these publications, so we just want to add them to the group, not the document
            
			pubs = [self promisedItemsForPasteboard:[NSPasteboard pasteboardWithName:NSDragPboard]];
        } else {
            if([self addPublicationsFromPasteboard:pboard error:NULL] == NO)
                return NO;
            
            pubs = [self selectedPublications];            
        }

        OBPRECONDITION([pubs count]);
        
        // add to the group we're dropping on, /not/ the currently selected group; no need to add to all pubs group, though
        if(group != nil && row != 0){
            [self addPublications:pubs toGroup:group];
            // reselect if necessary, or we default to selecting the all publications group (which is really annoying when creating a new pub by dropping a PDF on a group)
            if(shouldSelect) 
                [self selectGroup:group];
            [groupTableView reloadData];
        }
        
        return YES;
    }
      
    return NO;
}

#pragma mark TableView actions

// the next 3 are called from tableview actions defined in NSTableView_OAExtensions

- (void)tableView:(NSTableView *)tv insertNewline:(id)sender{
	if (tv == tableView) {
		[self editPubCmd:sender];
	} else if (tv == groupTableView) {
		[self renameGroupAction:sender];
	}
}

- (void)tableView:(NSTableView *)tv deleteRows:(NSArray *)rows{
	// the rows are always the selected rows
	if (tv == tableView) {
		[self removeSelectedPubs:nil];
	} else if (tv == groupTableView) {
		[self removeSelectedGroups:nil];
	}
}

- (void)tableView:(NSTableView *)tv addItemsFromPasteboard:(NSPasteboard *)pboard{

	if (tv != tableView) {
		NSBeep();
		return;
	}

    NSError *error = nil;
	if ([self addPublicationsFromPasteboard:pboard error:&error] == NO) {
        if(error != nil && [NSResponder instancesRespondToSelector:@selector(presentError:)])
            [tv presentError:error];
		else
            NSBeep();
	}
}

// as the window delegate, we receive these from NSInputManager and doCommandBySelector:
- (void)moveLeft:(id)sender{
    if([documentWindow firstResponder] != groupTableView && [documentWindow makeFirstResponder:groupTableView])
        if([groupTableView numberOfSelectedRows] == 0)
            [groupTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

- (void)moveRight:(id)sender{
    if([documentWindow firstResponder] != tableView && [documentWindow makeFirstResponder:tableView]){
        if([tableView numberOfSelectedRows] == 0)
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    } else if([documentWindow firstResponder] == tableView)
        [self editPubCmd:nil];
}

#pragma mark || Methods to support the type-ahead selector.

// used for status bar
- (void)typeSelectHelper:(BDSKTypeSelectHelper *)typeSelectHelper updateSearchString:(NSString *)searchString{
    NSString *tcID = [lastSelectedColumnForSort identifier];
    if(!searchString || !tcID)
        [self updateUI]; // resets the status line to its default value
    else
        [self setStatus:[NSString stringWithFormat:NSLocalizedString(@"Finding item with %@: \"%@\"", @""), tcID, searchString]];
}

// This is where we build the list of possible items which the user can select by typing the first few letters. You should return an array of NSStrings.
- (NSArray *)typeSelectHelperSelectionItems:(BDSKTypeSelectHelper *)typeSelectHelper{
    if(typeSelectHelper == [tableView typeSelectHelper]){    
        
        // Some users seem to expect that the currently sorted table column is used for typeahead;
        // since the datasource method already knows how to convert columns to BibItem values, we
        // can it almost directly.  It might be possible to cache this in the datasource method itself
        // to avoid calling it twice on -reloadData, but that will only work if -reloadData reloads
        // all rows instead of just visible rows.
        
        NSString *field = [lastSelectedColumnForSort identifier];
        NSTableColumn *column = [tableView tableColumnWithIdentifier:field];
        unsigned int row, numberOfRows = [tableView numberOfRows];
        NSMutableArray *a = [NSMutableArray arrayWithCapacity:numberOfRows];

        // table datasource returns an NSImage for URL fields, so we'll ignore those columns
        if([[BibTypeManager sharedManager] isURLField:field] == NO && nil != column){
            id value;
            typedef id (*dataIMP)(id, SEL, id, id, unsigned int);
            SEL selector = @selector(tableView:objectValueForTableColumn:row:);
            dataIMP get_datasource_value = (dataIMP)[self methodForSelector:selector];
            
            for (row = 0; row < numberOfRows; row++){
                value = get_datasource_value(self, selector, tableView, column, row);
                
                // use @"" for nil values; ensure typeahead index matches shownPublications index
                [a addObject:value ? [value description] : @""];
            }
        }
        return a;
        
    } else if(typeSelectHelper == [groupTableView typeSelectHelper]){
        
        int i;
		int groupCount = [self countOfGroups];
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:groupCount];
        BDSKGroup *group;
        
		OBPRECONDITION(groupCount);
        for(i = 0; i < groupCount; i++){
			group = [self objectInGroupsAtIndex:i];
            [array addObject:[group stringValue]];
		}
        return array;
        
    } else return [NSArray array];
}

// Type-ahead-selection behavior can change if an item is currently selected (especially if the item was selected by type-ahead-selection). Return nil if you have no selection or a multiple selection.
- (unsigned int)typeSelectHelperCurrentlySelectedIndex:(BDSKTypeSelectHelper *)typeSelectHelper{
    if(typeSelectHelper == [tableView typeSelectHelper]){    
        if ([self numberOfSelectedPubs] == 1){
            return [tableView selectedRow];
        }else{
            return NSNotFound;
        }
    } else if(typeSelectHelper == [groupTableView typeSelectHelper]){
        if([groupTableView numberOfSelectedRows] != 1)
            return NSNotFound;
        else
            return [[groupTableView selectedRowIndexes] firstIndex];
    } else return NSNotFound;
}

// We call this when a type-ahead-selection match has been made; you should select the item based on its index in the array you provided in -typeAheadSelectionItems.
- (void)typeSelectHelper:(BDSKTypeSelectHelper *)typeSelectHelper selectItemAtIndex:(unsigned int)itemIndex{
    NSTableView *tv = nil;
    if(typeSelectHelper == [tableView typeSelectHelper])
        tv = tableView;
    else if(typeSelectHelper == [groupTableView typeSelectHelper])
        tv = groupTableView;
    else
        return;
    [tv selectRowIndexes:[NSIndexSet indexSetWithIndex:itemIndex] byExtendingSelection:NO];
    [tv scrollRowToVisible:itemIndex];
}

// promise drags (currently used for webloc files)
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
    BOOL isLocalFile = [[BibTypeManager sharedManager] isLocalFileField:fieldName];
    
    NSString *originalPath;
    NSString *fileName;
    NSString *basePath = [dropDestination path];

    while(rowIdx != NSNotFound){
        theBib = [shownPublications objectAtIndex:rowIdx];
        if(isLocalFile){
            originalPath = [theBib localFilePathForField:fieldName];
            fileName = [originalPath lastPathComponent];
            NSParameterAssert(fileName);
            fullPath = [basePath stringByAppendingPathComponent:fileName];
            [fileNames addObject:fileName];
            // create a dictionary with each original file path (source) as key, and destination path as value
            [fullPathDict setValue:fullPath forKey:originalPath];
            
        } else if((url = [theBib remoteURLForField:fieldName])){
                fullPath = [[basePath stringByAppendingPathComponent:[theBib displayTitle]] stringByAppendingPathExtension:@"webloc"];
                // create a dictionary with each destination file path as key (handed to us from the Finder/dropDestination) and each item's URL as value
                [fullPathDict setValue:url forKey:fullPath];
                [fileNames addObject:[theBib displayTitle]];
        }
        rowIdx = [indexSet indexGreaterThanIndex:rowIdx];
    }
    [self setPromiseDragColumnIdentifier:nil];
    
    // We generally want to run promised file creation in the background to avoid blocking our UI, although webloc files are so small it probably doesn't matter.
    if(isLocalFile)
        [[NSFileManager defaultManager] copyFilesInBackgroundThread:fullPathDict];
    else
        [[NSFileManager defaultManager] createWeblocFilesInBackgroundThread:fullPathDict];

    return fileNames;
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

#pragma mark Tracking rects

- (BOOL)tableView:(NSTableView *)tv shouldTrackTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
    // this can happen when we revert
    if (row == -1 || row >= [[self publications] count])
        return NO;
    
    NSString *tcID = [tableColumn identifier];
    return [[BibTypeManager sharedManager] isURLField:tcID] && [[[self publications] objectAtIndex:row] URLForField:tcID];
}

- (void)tableView:(NSTableView *)tv mouseEnteredTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
    if (row == -1 || row >= [[self publications] count])
        return;
    
    NSString *tcID = [tableColumn identifier];
    BibItem *pub = [[self publications] objectAtIndex:row];
    NSURL *url = [pub URLForField:tcID];
    if (url)
        [self setStatus:[url isFileURL] ? [[url path] stringByAbbreviatingWithTildeInPath] : [url absoluteString]];
}

- (void)tableView:(NSTableView *)tv mouseExitedTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
    [self updateUI];
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

- (BOOL)containsUnparseableFile{
    NSString *type = [self availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]];
    
    if(type == nil)
        return NO;
    
    NSArray *fileNames = [self propertyListForType:NSFilenamesPboardType];
    
    if([fileNames count] != 1)  
        return NO;
        
    NSString *fileName = [fileNames lastObject];
    NSSet *unreadableTypes = [NSSet caseInsensitiveStringSetWithObjects:@"pdf", @"ps", @"eps", @"doc", @"htm", @"textClipping", @"webloc", @"html", @"rtf", @"tiff", @"tif", @"png", @"jpg", @"jpeg", nil];
    NSSet *readableTypes = [NSSet caseInsensitiveStringSetWithObjects:@"bib", @"aux", @"ris", @"fcgi", @"refman", nil];
    
    if([unreadableTypes containsObject:[fileName pathExtension]])
        return YES;
    if([readableTypes containsObject:[fileName pathExtension]])
        return NO;
    
    NSString *contentString = [[NSString alloc] initWithContentsOfFile:fileName encoding:NSUTF8StringEncoding guessEncoding:YES];
    
    if(contentString == nil)
        return YES;
    if([contentString contentStringType] == BDSKUnknownStringType){
        [contentString release];
        return YES;
    }
    [contentString release];
    return NO;
}

@end
