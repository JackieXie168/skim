//  BibDocument_DataSource.m

//  Created by Michael McCracken on Tue Mar 26 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006,2007
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

#import "BibDocument_DataSource.h"
#import "BibDocument.h"
#import "BibDocument_Actions.h"
#import "BibItem.h"
#import "BibAuthor.h"
#import "NSImage+Toolbox.h"
#import "BDSKGroupCell.h"
#import "BDSKGroup.h"
#import "BDSKStaticGroup.h"
#import "BDSKScriptHookManager.h"
#import "BibDocument_Groups.h"
#import "BibDocument_Search.h"
#import "NSBezierPath_BDSKExtensions.h"
#import "BDSKPreviewer.h"
#import "BDSKTeXTask.h"
#import "BDSKMainTableView.h"
#import "BDSKGroupTableView.h"
#import "NSFileManager_BDSKExtensions.h"
#import "BDSKAlert.h"
#import "BibTypeManager.h"
#import "NSURL_BDSKExtensions.h"
#import "NSFileManager_ExtendedAttributes.h"
#import "NSSet_BDSKExtensions.h"
#import "BibEditor.h"
#import "NSGeometry_BDSKExtensions.h"
#import "BDSKTemplate.h"
#import "BDSKTemplateObjectProxy.h"
#import "BDSKTypeSelectHelper.h"
#import "NSWindowController_BDSKExtensions.h"
#import "NSTableView_BDSKExtensions.h"
#import "BDSKPublicationsArray.h"
#import "BDSKStringParser.h"
#import "BDSKGroupsArray.h"
#import "BDSKItemPasteboardHelper.h"
#import "NSMenu_BDSKExtensions.h"
#import "NSIndexSet_BDSKExtensions.h"
#import "BDSKSearchGroup.h"

#define MAX_DRAG_IMAGE_WIDTH 700.0

@interface NSPasteboard (BDSKExtensions)
- (BOOL)containsUnparseableFile;
@end

#pragma mark -

@implementation BibDocument (DataSource)

#pragma mark TableView data source

- (int)numberOfRowsInTableView:(NSTableView *)tv{
    if(tv == (NSTableView *)tableView){
        return [shownPublications count];
    }else if(tv == groupTableView){
        return [groups count];
    }else{
// should raise an exception or something
        return 0;
    }
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    if(tv == tableView){
        return [[shownPublications objectAtIndex:row] displayValueOfField:[tableColumn identifier]];
    }else if(tv == groupTableView){
		return [groups objectAtIndex:row];
    }else return nil;
}

- (void)tableView:(NSTableView *)tv setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    if(tv == tableView){

		NSString *tcID = [tableColumn identifier];
		if([tcID isRatingField]){
			BibItem *pub = [shownPublications objectAtIndex:row];
			int oldRating = [pub ratingValueOfField:tcID];
			int newRating = [object intValue];
			if(newRating != oldRating) {
				[pub setField:tcID toRatingValue:newRating];
                [self userChangedField:tcID ofPublications:[NSArray arrayWithObject:pub] from:[NSArray arrayWithObject:[NSString stringWithFormat:@"%i", oldRating]] to:[NSArray arrayWithObject:[NSString stringWithFormat:@"%i", newRating]]];
				[[pub undoManager] setActionName:NSLocalizedString(@"Change Rating", @"Undo action name")];
			}
		}else if([tcID isBooleanField]){
			BibItem *pub = [shownPublications objectAtIndex:row];
            NSCellStateValue oldStatus = [pub boolValueOfField:tcID];
			NSCellStateValue newStatus = [object intValue];
			if(newStatus != oldStatus) {
				[pub setField:tcID toBoolValue:newStatus];
                [self userChangedField:tcID ofPublications:[NSArray arrayWithObject:pub] from:[NSArray arrayWithObject:[NSString stringWithBool:oldStatus]] to:[NSArray arrayWithObject:[NSString stringWithBool:newStatus]]];
				[[pub undoManager] setActionName:NSLocalizedString(@"Change Check Box", @"Undo action name")];
			}
		}else if([tcID isTriStateField]){
			BibItem *pub = [shownPublications objectAtIndex:row];
            NSCellStateValue oldStatus = [pub triStateValueOfField:tcID];
			NSCellStateValue newStatus = [object intValue];
			if(newStatus != oldStatus) {
				[pub setField:tcID toTriStateValue:newStatus];
                [self userChangedField:tcID ofPublications:[NSArray arrayWithObject:pub] from:[NSArray arrayWithObject:[NSString stringWithTriStateValue:oldStatus]] to:[NSArray arrayWithObject:[NSString stringWithTriStateValue:newStatus]]];
				[[pub undoManager] setActionName:NSLocalizedString(@"Change Check Box", @"Undo action name")];
			}
		}
	}else if(tv == groupTableView){
		BDSKGroup *group = [groups objectAtIndex:row];
        // object is always a group, see BDSKGroupCellFormatter
        OBASSERT([object isKindOfClass:[BDSKGroup class]]);
        id newName = [object name];
		if([[group name] isEqual:newName])
			return;
		if([group isCategory]){
			NSArray *pubs = [groupedPublications copy];
			[self movePublications:pubs fromGroup:group toGroupNamed:newName];
			[pubs release];
		}else if([group hasEditableName]){
			[(BDSKMutableGroup *)group setName:newName];
			[[self undoManager] setActionName:NSLocalizedString(@"Rename Group", @"Undo action name")];
		}
	}
}

- (NSString *)tableView:(NSTableView *)tv toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation{
    if (tv == tableView) {
        if ([[aTableColumn identifier] isEqualToString:BDSKImportOrderString] && [[shownPublications objectAtIndex:row] isImported] == NO)
            return NSLocalizedString(@"Click to import this item", @"Tool tip message");
    } else if (tv == groupTableView) {
        return [[groups objectAtIndex:row] toolTip];
    }
    return nil;
}
    

#pragma mark TableView delegate

- (void)disableGroupRenameWarningAlertDidEnd:(BDSKAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if ([alert checkValue] == YES) {
		[[OFPreferenceWrapper sharedPreferenceWrapper] setBool:NO forKey:BDSKWarnOnRenameGroupKey];
	}
}

- (BOOL)tableView:(NSTableView *)tv shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)row{
    if(tv == groupTableView){
		if ([[groups objectAtIndex:row] hasEditableName] == NO) 
			return NO;
		else if (NSLocationInRange(row, [groups rangeOfCategoryGroups]) &&
				 [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKWarnOnRenameGroupKey]) {
			
			BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Warning", @"Message in alert dialog")
												 defaultButton:NSLocalizedString(@"OK", @"Button title")
											   alternateButton:NSLocalizedString(@"Cancel", @"Button title")
												   otherButton:nil
									 informativeTextWithFormat:NSLocalizedString(@"This action will change the %@ field in %i items. Do you want to proceed?", @"Informative text in alert dialog"), [currentGroupField localizedFieldName], [groupedPublications count]];
			[alert setHasCheckButton:YES];
			[alert setCheckValue:NO];
			int rv = [alert runSheetModalForWindow:documentWindow
									 modalDelegate:self 
									didEndSelector:@selector(disableGroupRenameWarningAlertDidEnd:returnCode:contextInfo:) 
								didDismissSelector:NULL 
									   contextInfo:NULL];
			if (rv == NSAlertAlternateReturn)
				return NO;
		}
		return YES;
	}
    return NO;
}

- (void)tableView:(NSTableView *)tv willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)row{
    if (row == -1) return;
    if (tv == tableView) {
        if([aCell isKindOfClass:[NSButtonCell class]]){
            if ([[aTableColumn identifier] isEqualToString:BDSKImportOrderString])
                [aCell setEnabled:[[shownPublications objectAtIndex:row] isImported] == NO];
            else
                [aCell setEnabled:[self hasExternalGroupsSelected] == NO];
        }
    } else if (tv == groupTableView) {
        BDSKGroup *group = [groups objectAtIndex:row];
        NSProgressIndicator *spinner = [groups spinnerForGroup:group];
        
        if (spinner) {
            int column = [[tv tableColumns] indexOfObject:aTableColumn];
            NSRect ignored, rect = [tv frameOfCellAtColumn:column row:row];
            NSSize size = [spinner frame].size;
            NSDivideRect(rect, &ignored, &rect, 3.0f, NSMaxXEdge);
            NSDivideRect(rect, &rect, &ignored, size.width, NSMaxXEdge);
            rect = BDSKCenterRectVertically(rect, size.height, [tv isFlipped]);
            
            [spinner setFrame:rect];
            if ([spinner isDescendantOf:tv] == NO)
                [tv addSubview:spinner];
        }
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
	NSTableView *tv = [aNotification object];
    if(tv == tableView){
        NSNotification *note = [NSNotification notificationWithName:BDSKTableSelectionChangedNotification object:self];
        [[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName forModes:nil];
	}else if(tv == groupTableView){
        NSNotification *note = [NSNotification notificationWithName:BDSKGroupTableSelectionChangedNotification object:self];
        [[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName forModes:nil];
    }
}

- (NSDictionary *)defaultColumnWidthsForTableView:(NSTableView *)aTableView{
    NSMutableDictionary *defaultTableColumnWidths = [NSMutableDictionary dictionaryWithDictionary:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKColumnWidthsKey]];
    [defaultTableColumnWidths addEntriesFromDictionary:[[self mainWindowSetupDictionaryFromExtendedAttributes] objectForKey:BDSKColumnWidthsKey]];
    return defaultTableColumnWidths;
}

- (NSDictionary *)currentTableColumnWidthsAndIdentifiers {
    NSEnumerator *tcE = [[tableView tableColumns] objectEnumerator];
    NSTableColumn *tc = nil;
    NSMutableDictionary *columns = [NSMutableDictionary dictionaryWithCapacity:5];
    
    while(tc = [tcE nextObject]){
        [columns setObject:[NSNumber numberWithFloat:[tc width]]
                    forKey:[tc identifier]];
    }
    return columns;
}    

- (void)tableViewColumnDidResize:(NSNotification *)notification{
	if([notification object] != tableView) return;
      
    // current setting will override those already in the prefs; we may not be displaying all the columns in prefs right now, but we want to preserve their widths
    NSMutableDictionary *defaultWidths = [[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKColumnWidthsKey] mutableCopy];
    [defaultWidths addEntriesFromDictionary:[self currentTableColumnWidthsAndIdentifiers]];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:defaultWidths forKey:BDSKColumnWidthsKey];
    [defaultWidths release];
}


- (void)tableViewColumnDidMove:(NSNotification *)notification{
	if([notification object] != tableView) return;
    
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:[[tableView tableColumnIdentifiers] arrayByRemovingObject:BDSKImportOrderString]
                                                      forKey:BDSKShownColsNamesKey];
}

- (void)tableView:(NSTableView *)tv didClickTableColumn:(NSTableColumn *)tableColumn{
	// check whether this is the right kind of table view and don't re-sort when we have a contextual menu click
    if ([[NSApp currentEvent] type] == NSRightMouseDown) 
        return;
    if (tableView == tv){
        [self sortPubsByKey:[tableColumn identifier]];
	}else if (groupTableView == tv){
        [self sortGroupsByKey:nil];
	}

}

- (NSMenu *)tableView:(NSTableView *)tv contextMenuForRow:(int)row column:(int)column {
	NSMenu *menu = nil;
    NSMenuItem *item = nil;
    
	if (column == -1 || row == -1) 
		return nil;
	
	if(tv == tableView){
		
		NSString *tcId = [[[tableView tableColumns] objectAtIndex:column] identifier];
        NSURL *theURL;
        
		if([tcId isURLField]){
            menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
            if([tcId isLocalFileField]){
                item = [menu addItemWithTitle:NSLocalizedString(@"Open Linked File", @"Menu item title") action:@selector(openLinkedFile:) keyEquivalent:@""];
                [item setTarget:self];
                [item setRepresentedObject:tcId];
                item = [menu addItemWithTitle:NSLocalizedString(@"Reveal Linked File in Finder", @"Menu item title") action:@selector(revealLinkedFile:) keyEquivalent:@""];
                [item setTarget:self];
                [item setRepresentedObject:tcId];
            }else{
                item = [menu addItemWithTitle:NSLocalizedString(@"Open URL in Browser", @"Menu item title") action:@selector(openRemoteURL:) keyEquivalent:@""];
                [item setTarget:self];
                [item setRepresentedObject:tcId];
            }
            if([tableView numberOfSelectedRows] == 1 &&
               (theURL = [[shownPublications objectAtIndex:row] URLForField:tcId])){
                item = [menu insertItemWithTitle:NSLocalizedString(@"Open With", @"Menu item title") 
                                    andSubmenuOfApplicationsForURL:theURL atIndex:1];
            }
            [menu addItem:[NSMenuItem separatorItem]];
            item = [menu addItemWithTitle:NSLocalizedString(@"Edit", @"Menu item title") action:@selector(editPubCmd:) keyEquivalent:@""];
            [item setTarget:self];
            item = [menu addItemWithTitle:[NSLocalizedString(@"Delete", @"Menu item title") stringByAppendingEllipsis] action:@selector(deleteSelectedPubs:) keyEquivalent:@""];
            [item setTarget:self];
		}else{
			menu = [actionMenu copyWithZone:[NSMenu menuZone]];
		}
		
	}else if (tv == groupTableView){
		menu = [groupMenu copyWithZone:[NSMenu menuZone]];
	}else{
		return nil;
	}
	
	// kick out every item we won't need:
	int i = [menu numberOfItems];
    BOOL wasSeparator = YES;
	
	while (--i >= 0) {
		item = (NSMenuItem*)[menu itemAtIndex:i];
		if ([self validateMenuItem:item] == NO || ((wasSeparator || i == 0) && [item isSeparatorItem]))
			[menu removeItem:item];
        else
            wasSeparator = [item isSeparatorItem];
	}
	while([menu numberOfItems] > 0 && [(NSMenuItem*)[menu itemAtIndex:0] isSeparatorItem])	
		[menu removeItemAtIndex:0];
	
	if([menu numberOfItems] == 0)
		return nil;
	
	return [menu autorelease];
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
	NSMutableIndexSet *rowIndexes = [NSIndexSet indexSetWithIndexesInArray:rows];
	return [self tableView:tv writeRowsWithIndexes:rowIndexes toPasteboard:pboard];
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard{
    OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
    int index = ([NSApp currentModifierFlags] & NSAlternateKeyMask) ? 1 : 0;
	int dragCopyType = [[[sud arrayForKey:BDSKDragCopyTypesKey] objectAtIndex:index] intValue];
    BOOL yn = NO;
	NSString *citeString = [sud stringForKey:BDSKCiteStringKey];
    NSArray *pubs = nil;
    NSArray *additionalFilenames = nil;
    
	OBPRECONDITION(pboard == [NSPasteboard pasteboardWithName:NSDragPboard] || pboard == [NSPasteboard pasteboardWithName:NSGeneralPboard]);

    docState.dragFromExternalGroups = NO;
	
    if(tv == groupTableView){
		if([rowIndexes containsIndex:0]){
			pubs = [NSArray arrayWithArray:publications];
		}else if([rowIndexes count] > 1){
			// multiple dragged rows always are the selected rows
			pubs = [NSArray arrayWithArray:groupedPublications];
		}else if([rowIndexes count] == 1){
            // a single row, not necessarily the selected one
            BDSKGroup *group = [groups objectAtIndex:[rowIndexes firstIndex]];
            if ([group isExternal]) {
                pubs = [NSArray arrayWithArray:[(id)group publications]];
                if ([group isSearch])
                    additionalFilenames = [NSArray arrayWithObject:[[[(BDSKSearchGroup *)group serverInfo] name] stringByAppendingPathExtension:@"bdsksearch"]];
			} else {
                NSMutableArray *pubsInGroup = [NSMutableArray arrayWithCapacity:[publications count]];
                NSEnumerator *pubEnum = [publications objectEnumerator];
                BibItem *pub;
                
                while (pub = [pubEnum nextObject]) {
                    if ([group containsItem:pub]) 
                        [pubsInGroup addObject:pub];
                }
                pubs = pubsInGroup;
            }
            docState.dragFromExternalGroups = [groups hasExternalGroupsAtIndexes:rowIndexes];
		}
		if([pubs count] == 0 && [self hasSearchGroupsSelected] == NO){
            NSBeginAlertSheet(NSLocalizedString(@"Empty Groups", @"Message in alert dialog when dragging from empty groups"),nil,nil,nil,documentWindow,nil,NULL,NULL,NULL,
                              NSLocalizedString(@"The groups you want to drag do not contain any items.", @"Informative text in alert dialog"));
            return NO;
        }
			
    }else if(tv == tableView){
		// drag from the main table
		pubs = [shownPublications objectsAtIndexes:rowIndexes];
        
        docState.dragFromExternalGroups = [self hasExternalGroupsSelected];

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
				
				if([dragColumnId isLocalFileField]){

                    // if we have more than one row, we can't put file contents on the pasteboard, but most apps seem to handle file names just fine
                    unsigned row = [rowIndexes firstIndex];
                    BibItem *pub = nil;
                    NSString *path;
                    NSMutableArray *filePaths = [NSMutableArray arrayWithCapacity:[rowIndexes count]];

                    while(row != NSNotFound){
                        pub = [shownPublications objectAtIndex:row];
                        path = [pub localFilePathForField:dragColumnId];
                        if(path != nil){
                            [filePaths addObject:path];
                            NSError *xerror = nil;
                            // we can always write xattrs; this doesn't alter the original file's content in any way, but fails if you have a really long abstract/annote
                            if([[NSFileManager defaultManager] setExtendedAttributeNamed:OMNI_BUNDLE_IDENTIFIER @".bibtexstring" toValue:[[pub bibTeXString] dataUsingEncoding:NSUTF8StringEncoding] atPath:path options:nil error:&xerror] == NO)
                                NSLog(@"%@ line %d: adding xattrs failed with error %@", __FILENAMEASNSSTRING__, __LINE__, xerror);
                            // writing the standard PDF metadata alters the original file, so we'll make it a separate preference; this is also really slow
                            if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShouldWritePDFMetadata])
                                [pub addPDFMetadataToFileForLocalURLField:dragColumnId];
                        }
                        row = [rowIndexes indexGreaterThanIndex:row];
                    }
                    
                    if([filePaths count]){
                        [pboard declareTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil] owner:nil];
                        return [pboard setPropertyList:filePaths forType:NSFilenamesPboardType];
                    }
                    
				}else if([dragColumnId isRemoteURLField]){
					// cache this so we know which column (field) was dragged
					[self setPromiseDragColumnIdentifier:dragColumnId];
					
					BibItem *pub = [shownPublications objectAtIndex:[rowIndexes firstIndex]];
					NSURL *url = [pub remoteURLForField:dragColumnId];
					if(url != nil){
						// put the URL and a webloc file promise on the pasteboard
                        [pboard declareTypes:[NSArray arrayWithObjects:NSFilesPromisePboardType, NSURLPboardType, nil] owner:self];
                        yn = [pboard setPropertyList:[NSArray arrayWithObject:[[pub displayTitle] stringByAppendingPathExtension:@"webloc"]] forType:NSFilesPromisePboardType];
                        [url writeToPasteboard:pboard];
						return yn;
					}
				}
			}
		}
    }
	
	BOOL success = [self writePublications:pubs forDragCopyType:dragCopyType citeString:citeString toPasteboard:pboard];
	
    if(success && additionalFilenames){
        [pboardHelper addTypes:[NSArray arrayWithObject:NSFilesPromisePboardType] forPasteboard:pboard];
        [pboardHelper setPropertyList:additionalFilenames forType:NSFilesPromisePboardType forPasteboard:pboard];
    }
    
    return success;
}
	
- (BOOL)writePublications:(NSArray *)pubs forDragCopyType:(int)dragCopyType citeString:(NSString *)citeString toPasteboard:(NSPasteboard*)pboard{
	NSString *mainType = nil;
	NSString *string = nil;
	NSData *data = nil;
	
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
			break;
		case BDSKRTFDragCopyType:
			mainType = NSRTFPboardType;
			break;
		case BDSKLaTeXDragCopyType:
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
            {
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
            }
	}
    
	[pboardHelper declareType:mainType dragCopyType:dragCopyType forItems:pubs forPasteboard:pboard];
    
    if(string != nil)
        [pboardHelper setString:string forType:mainType forPasteboard:pboard];
	else if(data != nil)
        [pboardHelper setData:data forType:mainType forPasteboard:pboard];
    else if(dragCopyType >= BDSKTemplateDragCopyType)
        [pboardHelper setData:nil forType:mainType forPasteboard:pboard];
        
    return YES;
}

- (void)tableView:(NSTableView *)aTableView concludeDragOperation:(NSDragOperation)operation{
    [self clearPromisedDraggedItems];
}

- (void)clearPromisedDraggedItems{
	[pboardHelper clearPromisedTypesForPasteboard:[NSPasteboard pasteboardWithName:NSDragPboard]];
}

- (NSDragOperation)tableView:(NSTableView *)tv draggingSourceOperationMaskForLocal:(BOOL)isLocal{
    return isLocal ? NSDragOperationEvery : NSDragOperationCopy;
}

- (NSImage *)tableView:(NSTableView *)tv dragImageForRowsWithIndexes:(NSIndexSet *)dragRows{
    return [self dragImageForPromisedItemsUsingCiteString:[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKCiteStringKey]];
}

- (NSImage *)dragImageForPromisedItemsUsingCiteString:(NSString *)citeString{
    NSImage *image = nil;
    
    NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSDragPboard];
    NSString *dragType = [pb availableTypeFromArray:[NSArray arrayWithObjects:NSFilenamesPboardType, NSURLPboardType, NSFilesPromisePboardType, NSPDFPboardType, NSRTFPboardType, NSStringPboardType, nil]];
	NSArray *promisedDraggedItems = [pboardHelper promisedItemsForPasteboard:[NSPasteboard pasteboardWithName:NSDragPboard]];
	int dragCopyType = -1;
	int count = 0;
    BOOL inside = NO;
	
    if ([dragType isEqualToString:NSFilenamesPboardType]) {
		NSArray *fileNames = [pb propertyListForType:NSFilenamesPboardType];
		count = [fileNames count];
		image = [[NSWorkspace sharedWorkspace] iconForFiles:fileNames];
    
    } else if ([dragType isEqualToString:NSURLPboardType]) {
        count = 1;
        image = [[[NSImage imageForURL:[NSURL URLFromPasteboard:pb]] copy] autorelease];
		[image setSize:NSMakeSize(32,32)];
    
	} else if ([dragType isEqualToString:NSFilesPromisePboardType]) {
		NSArray *fileNames = [pb propertyListForType:NSFilesPromisePboardType];
		count = [fileNames count];
        NSString *pathExt = count ? [[fileNames objectAtIndex:0] pathExtension] : @"";
        // promise drags don't use full paths
        image = [[NSWorkspace sharedWorkspace] iconForFileType:pathExt];
    
	} else {
		OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
        int index = ([NSApp currentModifierFlags] & NSAlternateKeyMask) ? 1 : 0;
		NSMutableString *s = [NSMutableString string];
        
        dragCopyType = [[[sud arrayForKey:BDSKDragCopyTypesKey] objectAtIndex:index] intValue];
		
		// don't depend on this being non-zero; this method gets called for drags where promisedDraggedItems is nil
		count = [promisedDraggedItems count];
		
		// we draw only the first item and indicate other items using ellipsis
        if (count) {
            BibItem *firstItem = [promisedDraggedItems objectAtIndex:0];

            switch (dragCopyType) {
                case BDSKBibTeXDragCopyType:
                case BDSKMinimalBibTeXDragCopyType:
                    [s appendString:[firstItem bibTeXStringDroppingInternal:YES]];
                    if (count > 1) {
                        [s appendString:@"\n"];
                        [s appendString:[NSString horizontalEllipsisString]];
                    }
                    inside = YES;
                    break;
                case BDSKCiteDragCopyType:
                    // Are we using a custom citeString (from the drawer?)
                    [s appendString:[self citeStringForPublications:[NSArray arrayWithObject:firstItem] citeString:citeString]];
                    if (count > 1) 
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
                    break;
                case BDSKLTBDragCopyType:
                    [s appendString:@"\\bib{"];
                    [s appendString:[firstItem citeKey]];
                    [s appendString:@"}{"];
                    [s appendString:[firstItem pubType]];
                    [s appendString:@"}"];
                    if (count > 1) 
                        [s appendString:[NSString horizontalEllipsisString]];
                    break;
                case BDSKRISDragCopyType:
                    [s appendString:[firstItem RISStringValue]];
                    if (count > 1) 
                        [s appendString:[NSString horizontalEllipsisString]];
                    inside = YES;
                    break;
            }
		}
		NSAttributedString *attrString = [[[NSAttributedString alloc] initWithString:s] autorelease];
		NSSize size = [attrString size];
		NSRect rect = NSZeroRect;
		NSPoint point = NSMakePoint(3.0, 2.0); // offset of the string
		NSColor *color = [NSColor secondarySelectedControlColor];
		
        if (size.width <= 0 || size.height <= 0) {
            NSLog(@"string size was zero");
            size = NSMakeSize(30.0,20.0); // work around bug in NSAttributedString
        }
        if (size.width > MAX_DRAG_IMAGE_WIDTH)
            size.width = MAX_DRAG_IMAGE_WIDTH;
        
		size.width += 2 * point.x;
		size.height += 2 * point.y;
		rect.size = size;
		
		image = [[[NSImage alloc] initWithSize:size] autorelease];
        
        [image lockFocus];
        
		[NSGraphicsContext saveGraphicsState];
        [NSBezierPath drawHighlightInRect:rect radius:4.0 lineWidth:2.0 color:color];
		
		NSRectClip(NSInsetRect(rect, 3.0, 3.0));
        [attrString drawAtPoint:point];
		[NSGraphicsContext restoreGraphicsState];
        
        [image unlockFocus];
	}
	
    return [image dragImageWithCount:count inside:inside];
}

#pragma mark TableView dragging destination

- (NSDragOperation)tableView:(NSTableView*)tv
                validateDrop:(id <NSDraggingInfo>)info
                 proposedRow:(int)row
       proposedDropOperation:(NSTableViewDropOperation)op{
    
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKBibItemPboardType, BDSKWeblocFilePboardType, BDSKReferenceMinerStringPboardType, NSStringPboardType, NSFilenamesPboardType, NSURLPboardType, nil]];
    BOOL isDragFromMainTable = [[info draggingSource] isEqual:tableView];
    BOOL isDragFromGroupTable = [[info draggingSource] isEqual:groupTableView];
    BOOL isDragFromDrawer = [[info draggingSource] isEqual:[drawerController tableView]];
    
    if(tv == tableView){
        if([self hasExternalGroupsSelected] || type == nil) 
			return NSDragOperationNone;
		if (isDragFromGroupTable && docState.dragFromExternalGroups && [self hasLibraryGroupSelected]) {
            [tv setDropRow:-1 dropOperation:NSTableViewDropOn];
            return NSDragOperationCopy;
        }
        if(isDragFromMainTable || isDragFromGroupTable || isDragFromDrawer) {
			// can't copy onto same table
			return NSDragOperationNone;
		}
        // set drop row to -1 and NSTableViewDropOperation to NSTableViewDropOn, when we don't target specific rows http://www.corbinstreehouse.com/blog/?p=123
        if(row == -1 || op == NSTableViewDropAbove){
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
		if ((isDragFromGroupTable || isDragFromMainTable) && docState.dragFromExternalGroups) {
            if (row != 0)
                return NSDragOperationNone;
            [tv setDropRow:row dropOperation:NSTableViewDropOn];
            return NSDragOperationCopy;
        }
        
        if(op == NSTableViewDropAbove){
            // here we actually target the whole table, as we don't insert in a specific location
            row = -1;
            [tv setDropRow:row dropOperation:NSTableViewDropOn];
        }
        
        if(isDragFromDrawer || isDragFromGroupTable || type == nil || (row >= 0 && [[groups objectAtIndex:row]  isValidDropTarget] == NO) || (row == 0 && isDragFromMainTable))
            return NSDragOperationNone;
        
        if(isDragFromMainTable){
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
    
    if(tv == tableView){
        if([self hasExternalGroupsSelected])
            return NO;
		if(row != -1){
            BibItem *pub = [shownPublications objectAtIndex:row];
            NSURL *theURL = nil;
            
            if([type isEqualToString:NSFilenamesPboardType]){
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
                [pub autoFilePaper];
            
            [self selectPublication:pub];
            [[pub undoManager] setActionName:NSLocalizedString(@"Edit Publication", @"Undo action name")];
            return YES;
            
        }else{
            [self selectLibraryGroup:nil];
            
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
                                if (items = [publications allItemsForCiteKey:key])
                                    [selItems addObjectsFromArray:items];
                            }
                        }
                        [self selectPublications:selItems];
                        
                        return YES;
                    }
                }
            }
            
            return [self addPublicationsFromPasteboard:pboard selectLibrary:YES error:NULL];
        }
    } else if(tv == groupTableView){
        NSArray *pubs = nil;
        BOOL isDragFromMainTable = [[info draggingSource] isEqual:tableView];
        BOOL isDragFromGroupTable = [[info draggingSource] isEqual:groupTableView];
        BOOL isDragFromDrawer = [[info draggingSource] isEqual:[drawerController tableView]];
        
        // retain is required to fix bug #1356183
        BDSKGroup *group = row == -1 ? nil : [[[groups objectAtIndex:row] retain] autorelease];
        BOOL shouldSelect = row == -1 || [[self selectedGroups] containsObject:group];
		
		if ((isDragFromGroupTable || isDragFromMainTable) && docState.dragFromExternalGroups && row == 0) {
            return [self addPublicationsFromPasteboard:pboard selectLibrary:NO error:NULL];
        } else if(isDragFromGroupTable || isDragFromDrawer || (row >= 0 && [group isValidDropTarget] == NO)) {
            return NO;
        } else if(isDragFromMainTable){
            // we already have these publications, so we just want to add them to the group, not the document
            
			pubs = [pboardHelper promisedItemsForPasteboard:[NSPasteboard pasteboardWithName:NSDragPboard]];
        } else {
            if([self addPublicationsFromPasteboard:pboard selectLibrary:YES error:NULL] == NO)
                return NO;
            
            pubs = [self selectedPublications];            
        }

        if(row == -1 && [pubs count]){
            // add a new static groups with the added items, use a common author name or keyword if available
            NSEnumerator *pubEnum = [pubs objectEnumerator];
            BibItem *pub = [pubEnum nextObject];
            NSMutableSet *auths = BDSKCreateFuzzyAuthorCompareMutableSet();
            NSMutableSet *keywords = [[NSMutableSet alloc] initWithSet:[pub groupsForField:BDSKKeywordsString]];
            [auths setSet:[pub allPeople]];
            while(pub = [pubEnum nextObject]){
                [auths intersectSet:[pub allPeople]];
                [keywords intersectSet:[pub groupsForField:BDSKKeywordsString]];
            }
            group = [[BDSKStaticGroup alloc] init];
            if([auths count])
                [(BDSKStaticGroup *)group setName:[[auths anyObject] displayName]];
            else if([keywords count])
                [(BDSKStaticGroup *)group setName:[keywords anyObject]];
            [auths release];
            [keywords release];
            [groups addStaticGroup:(BDSKStaticGroup *)group];
            [group release];
        }
        
        // add to the group we're dropping on, /not/ the currently selected group; no need to add to all pubs group, though
        if(group != nil && row != 0 && [pubs count]){
            [self addPublications:pubs toGroup:group];
            // reselect if necessary, or we default to selecting the all publications group (which is really annoying when creating a new pub by dropping a PDF on a group)
            // don't use row, because we might have added the Last Import group
            if(shouldSelect) 
                [groupTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[groups indexOfObjectIdenticalTo:group]] byExtendingSelection:NO];
        }
        
        return YES;
    }
      
    return NO;
}

#pragma mark HFS Promise drags

// promise drags (currently used for webloc files)
- (NSArray *)tableView:(NSTableView *)tv namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)indexSet;
{

    if ([tv isEqual:tableView]) {
        unsigned rowIdx = [indexSet firstIndex];
        NSMutableDictionary *fullPathDict = [NSMutableDictionary dictionaryWithCapacity:[indexSet count]];
        
        // We're supposed to return this to our caller (usually the Finder); just an array of file names, not full paths
        NSMutableArray *fileNames = [NSMutableArray arrayWithCapacity:[indexSet count]];
        
        NSURL *url = nil;
        NSString *fullPath = nil;
        BibItem *theBib = nil;
        
        // this ivar stores the field name (e.g. Url, L2)
        NSString *fieldName = [self promiseDragColumnIdentifier];
        BOOL isLocalFile = [fieldName isLocalFileField];
        
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
    } else if ([tv isEqual:groupTableView]) {
        BDSKGroup *group = [groups objectAtIndex:[indexSet firstIndex]];
        NSMutableDictionary *plist = [[[group dictionaryValue] mutableCopy] autorelease];
        if (plist) {
            // we probably don't want to share this info with anyone else
            [plist removeObjectForKey:@"search term"];
            [plist removeObjectForKey:@"history"];
            
            NSString *fileName = [group respondsToSelector:@selector(serverInfo)] ? [[(BDSKSearchGroup *)group serverInfo] name] : [group name];
            fileName = [fileName stringByAppendingPathExtension:@"bdsksearch"];
            NSString *fullPath = [[dropDestination path] stringByAppendingPathComponent:fileName];
            
            // make sure the filename is unique
            fullPath = [[NSFileManager defaultManager] uniqueFilePath:fullPath createDirectory:NO];
            return ([plist writeToFile:fullPath atomically:YES]) ? [NSArray arrayWithObject:fileName] : nil;
        } else
            return nil;
    }
    NSAssert(0, @"code path should be unreached");
    return nil;
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

#pragma mark -

- (BOOL)isDragFromExternalGroups;
{
    return docState.dragFromExternalGroups;
}

- (void)setDragFromExternalGroups:(BOOL)flag;
{
    docState.dragFromExternalGroups = flag;
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
	if ([self addPublicationsFromPasteboard:pboard selectLibrary:YES error:&error] == NO) {
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
            [self selectLibraryGroup:nil];
}

- (void)moveRight:(id)sender{
    if([documentWindow firstResponder] != tableView && [documentWindow makeFirstResponder:tableView]){
        if([tableView numberOfSelectedRows] == 0)
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    } else if([documentWindow firstResponder] == tableView)
        [self editPubCmd:nil];
}

#pragma mark -
#pragma mark TypeSelectHelper delegate

// used for status bar
- (void)typeSelectHelper:(BDSKTypeSelectHelper *)typeSelectHelper updateSearchString:(NSString *)searchString{
    if(searchString == nil || sortKey == nil)
        [self updateStatus]; // resets the status line to its default value
    else
        [self setStatus:[NSString stringWithFormat:NSLocalizedString(@"Finding item with %@: \"%@\"", @"Status message:Finding item with [sorting field]: \"[search string]\""), [sortKey localizedFieldName], searchString]];
}

// This is where we build the list of possible items which the user can select by typing the first few letters. You should return an array of NSStrings.
- (NSArray *)typeSelectHelperSelectionItems:(BDSKTypeSelectHelper *)typeSelectHelper{
    if(typeSelectHelper == [tableView typeSelectHelper]){    
        
        // Some users seem to expect that the currently sorted table column is used for typeahead;
        // since the datasource method already knows how to convert columns to BibItem values, we
        // can it almost directly.  It might be possible to cache this in the datasource method itself
        // to avoid calling it twice on -reloadData, but that will only work if -reloadData reloads
        // all rows instead of just visible rows.
        
        unsigned int i, count = [shownPublications count];
        NSMutableArray *a = [NSMutableArray arrayWithCapacity:count];

        // table datasource returns an NSImage for URL fields, so we'll ignore those columns
        if([sortKey isURLField] == NO && nil != sortKey){
            BibItem *pub;
            id value;
            
            for (i = 0; i < count; i++){
                pub = [shownPublications objectAtIndex:i];
                value = [pub displayValueOfField:sortKey];
                
                // use @"" for nil values; ensure typeahead index matches shownPublications index
                [a addObject:value ? [value description] : @""];
            }
        }else{
            for (i = 0; i < count; i++)
                [a addObject:@""];
        }
        return a;
        
    } else if(typeSelectHelper == [groupTableView typeSelectHelper]){
        
        int i;
		int groupCount = [groups count];
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:groupCount];
        BDSKGroup *group;
        
		OBPRECONDITION(groupCount);
        for(i = 0; i < groupCount; i++){
			group = [groups objectAtIndex:i];
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

#pragma mark -
#pragma mark Tracking rects

- (BOOL)tableView:(NSTableView *)tv shouldTrackTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
    // this can happen when we revert
    if (row == -1 || row >= [self numberOfRowsInTableView:tv])
        return NO;
    
    NSString *tcID = [tableColumn identifier];
    return [tcID isURLField] && [[shownPublications objectAtIndex:row] URLForField:tcID];
}

- (void)tableView:(NSTableView *)tv mouseEnteredTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
    if (row == -1 || row >= [self numberOfRowsInTableView:tv])
        return;
    
    BibItem *pub = [shownPublications objectAtIndex:row];
    NSURL *url = [pub URLForField:[tableColumn identifier]];
    if (url)
        [self setStatus:[url isFileURL] ? [[url path] stringByAbbreviatingWithTildeInPath] : [url absoluteString]];
}

- (void)tableView:(NSTableView *)tv mouseExitedTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
    [self updateStatus];
}

@end

#pragma mark -

@implementation NSPasteboard (BDSKExtensions)

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
