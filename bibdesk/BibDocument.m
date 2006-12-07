//  BibDocument.m

//  Created by Michael McCracken on Mon Dec 17 2001.
/*
 This software is Copyright (c) 2001,2002,2003,2004,2005,2006
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
#import "BibAuthor.h"
#import "BibEditor.h"
#import "BibDocument_DataSource.h"
#import "BibDocumentView_Toolbar.h"
#import "BibAppController.h"
#import "BibPrefController.h"
#import "BibPersonController.h"

#import "BDSKUndoManager.h"
#import "MultiplePageView.h"
#import "BDSKPrintableView.h"
#import "NSWorkspace_BDSKExtensions.h"
#import "NSFileManager_BDSKExtensions.h"
#import "BDSKFontManager.h"
#import "BDSKStringEncodingManager.h"
#import "BDSKHeaderPopUpButtonCell.h"
#import "BDSKGroupCell.h"
#import "BDSKScriptHookManager.h"
#import "BDSKCountedSet.h"
#import "BDSKFilterController.h"
#import "BDSKGroup.h"
#import "BibDocument_Groups.h"
#import "BibDocument_Search.h"
#import "BDSKTableSortDescriptor.h"
#import "BDSKAlert.h"
#import "BDSKFieldSheetController.h"
#import "BDSKPreviewer.h"

#import "BDSKTeXTask.h"
#import "BDSKDragTableView.h"
#import "BDSKCustomCiteTableView.h"
#import "BDSKConverter.h"
#import "BibTeXParser.h"
#import "PubMedParser.h"
#import "BDSKJSTORParser.h"
#import "BibFiler.h"

#import "ApplicationServices/ApplicationServices.h"
#import "BDSKImagePopUpButton.h"
#import "BDSKRatingButton.h"
#import "BDSKSplitView.h"
#import "BDSKCollapsibleView.h"

#import "BDSKMacroResolver.h"
#import "MacroWindowController.h"
#import "BDSKTextImportController.h"
#import "BDSKErrorObjectController.h"
#import "BDSKGroupTableView.h"
#import "BDSKFileContentSearchController.h"
#import "NSString_BDSKExtensions.h"
#import "BDSKStatusBar.h"
#import "BDSKPreviewMessageQueue.h"
#import "NSArray_BDSKExtensions.h"
#import "NSTextView_BDSKExtensions.h"
#import "NSTableView_BDSKExtensions.h"
#import "BDSKWebOfScienceParser.h"
#import "NSMutableDictionary+ThreadSafety.h"
#import "NSSet_BDSKExtensions.h"
#import "NSFileManager_ExtendedAttributes.h"
#import "PDFMetadata.h"
#import "BDSKSharingServer.h"
#import "BDSKSharingBrowser.h"
#import "BDSKTemplate.h"
#import "BDSKDocumentInfoWindowController.h"
#import "NSMutableArray+ThreadSafety.h"
#import "BDSKGroupTableView.h"
#import "BDSKFileContentSearchController.h"
#import "BDSKTemplateParser.h"

// these are the same as in Info.plist
NSString *BDSKBibTeXDocumentType = @"bibTeX database";
NSString *BDSKRISDocumentType = @"RIS/Medline File";

NSString *BDSKReferenceMinerStringPboardType = @"CorePasteboardFlavorType 0x57454253";
NSString *BDSKBibItemPboardType = @"edu.ucsd.mmccrack.bibdesk BibItem pboard type";
NSString *BDSKWeblocFilePboardType = @"CorePasteboardFlavorType 0x75726C20";


#import <BTParse/btparse.h>

@implementation BibDocument

- (id)init{
    if(self = [super init]){
        publications = [[NSMutableArray alloc] initWithCapacity:1];
        shownPublications = [[NSMutableArray alloc] initWithCapacity:1];
        groupedPublications = [[NSMutableArray alloc] initWithCapacity:1];
        categoryGroups = [[NSMutableArray alloc] initWithCapacity:1];
        smartGroups = [[NSMutableArray alloc] initWithCapacity:1];
        staticGroups = nil;
        tmpStaticGroups = nil;
		allPublicationsGroup = [[BDSKGroup alloc] initWithAllPublications];
		lastImportGroup = nil;
                
        frontMatter = [[NSMutableString alloc] initWithString:@""];
		
        documentInfo = (NSMutableDictionary *)BDSKCreateCaseInsensitiveKeyMutableDictionary();
    
        currentGroupField = [[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKCurrentGroupFieldKey] retain];

        quickSearchKey = [[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKCurrentQuickSearchKey] retain];
        
        // @@ Changed from "All Fields" to localized "Any Field" in 1.2.2; prefs may still have the old key, so this is a temporary workaround for bug #1420837 as of 31 Jan 2006
        if([quickSearchKey isEqualToString:@"All Fields"]){
            [quickSearchKey release];
            quickSearchKey = [BDSKAllFieldsString copy];
        } else if(quickSearchKey == nil){
            quickSearchKey = [BDSKTitleString copy];
        }
		
		texTask = [[BDSKTeXTask alloc] initWithFileName:@"bibcopy"];
		[texTask setDelegate:self];
        
        macroResolver = [(BDSKMacroResolver *)[BDSKMacroResolver alloc] initWithDocument:self];
        
        BDSKUndoManager *newUndoManager = [[[BDSKUndoManager alloc] init] autorelease];
        [newUndoManager setDelegate:self];
        [self setUndoManager:newUndoManager];
		
        itemsForCiteKeys = [[OFMultiValueDictionary alloc] initWithKeyCallBacks:&BDSKCaseInsensitiveStringKeyDictionaryCallBacks];
		
		promisedPboardTypes = [[NSMutableDictionary alloc] initWithCapacity:2];
        
        isDocumentClosed = NO;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handlePreviewDisplayChangedNotification:)
													 name:BDSKPreviewDisplayChangedNotification
												   object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleGroupFieldChangedNotification:)
													 name:BDSKGroupFieldChangedNotification
												   object:self];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleGroupAddRemoveNotification:)
													 name:BDSKGroupAddRemoveNotification
												   object:nil];

		// register for selection changes notifications:
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleTableSelectionChangedNotification:)
													 name:BDSKTableSelectionChangedNotification
												   object:self];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleGroupTableSelectionChangedNotification:)
													 name:BDSKGroupTableSelectionChangedNotification
												   object:self];

		// register for tablecolumn changes notifications:
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleTableColumnChangedNotification:)
													 name:BDSKTableColumnChangedNotification
												   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleResortDocumentNotification:)
													 name:BDSKResortDocumentNotification
												   object:nil];        

		//  register to observe for item change notifications here.
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleBibItemChangedNotification:)
													 name:BDSKBibItemChangedNotification
												   object:nil];

		// register to observe for add/delete items.
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleBibItemAddDelNotification:)
													 name:BDSKDocSetPublicationsNotification
												   object:self];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleBibItemAddDelNotification:)
													 name:BDSKDocAddItemNotification
												   object:self];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleBibItemAddDelNotification:)
													 name:BDSKDocDelItemNotification
                                                   object:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleMacroChangedNotification:)
                                                     name:BDSKMacroDefinitionChangedNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleFilterChangedNotification:)
                                                     name:BDSKFilterChangedNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleStaticGroupChangedNotification:)
                                                     name:BDSKStaticGroupChangedNotification
                                                   object:nil];
        
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleSharedGroupUpdatedNotification:)
													 name:BDSKSharedGroupUpdatedNotification
												   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleSharedGroupsChangedNotification:)
                                                     name:BDSKSharedGroupsChangedNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleFlagsChangedNotification:)
                                                     name:OAFlagsChangedNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleApplicationWillTerminateNotification:)
                                                     name:NSApplicationWillTerminateNotification
                                                   object:nil];
        
        // @@ ARM: required for 10.3.9 as of 2 December 2005; the delegate notification isn't received by the document
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowWillClose:)
                                                     name:NSWindowWillCloseNotification
                                                   object:nil];
        
		customStringArray = [[NSMutableArray arrayWithCapacity:6] retain];
		[customStringArray setArray:[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKCustomCiteStringsKey]];
        
        // need to set this for new documents
        [self setDocumentStringEncoding:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKDefaultStringEncodingKey]]; 

		sortDescending = NO;
		sortGroupsDescending = [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKSortGroupsDescendingKey];
		sortGroupsKey = [[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKSortGroupsKey] retain];
        
    }
    return self;
}

- (void)awakeFromNib{
    NSSize drawerSize;
	
	[self setupSearchField];
   
    [tableView setDoubleAction:@selector(editPubCmd:)];
    NSArray *dragTypes = [NSArray arrayWithObjects:BDSKBibItemPboardType, BDSKWeblocFilePboardType, BDSKReferenceMinerStringPboardType, NSStringPboardType, NSFilenamesPboardType, NSURLPboardType, nil];
    [tableView registerForDraggedTypes:dragTypes];
    [groupTableView registerForDraggedTypes:dragTypes];
    
    [groupCollapsibleView setCollapseEdges:BDSKMinXEdgeMask];
    [groupCollapsibleView setMinSize:NSMakeSize(56.0, 20.0)];
    [groupGradientView setUpperColor:[NSColor colorWithCalibratedWhite:0.9 alpha:1.0]];
    [groupGradientView setLowerColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]];

    // make sure they are ordered correctly, mainly for the focus ring
	[groupCollapsibleView retain];
    [groupCollapsibleView removeFromSuperview];
    [[[groupTableView enclosingScrollView] superview] addSubview:groupCollapsibleView positioned:NSWindowBelow relativeTo:nil];
	[groupCollapsibleView release];
    
    [groupSplitView setDrawEnd:YES];
    [splitView setDrawEnd:YES];

	[splitView setPositionAutosaveName:@"OASplitView Position Main Window"];
    [groupSplitView setPositionAutosaveName:@"OASplitView Position Group Table"];
    
	[statusBar retain]; // we need to retain, as we might remove it from the window
	if (![[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShowStatusBarKey]) {
		[self toggleStatusBar:nil];
	} else {
		// make sure they are ordered correctly, mainly for the focus ring
		[statusBar removeFromSuperview];
		[[mainBox superview] addSubview:statusBar positioned:NSWindowBelow relativeTo:nil];
	}
	[statusBar setProgressIndicatorStyle:BDSKProgressIndicatorSpinningStyle];

    // workaround for IB flakiness...
    drawerSize = [customCiteDrawer contentSize];
    [customCiteDrawer setContentSize:NSMakeSize(100,drawerSize.height)];

	showingCustomCiteDrawer = NO;
	
	// unfortunately we cannot set this in IB
	[actionMenuButton setArrowImage:[NSImage imageNamed:@"ArrowPointingDown"]];
	[actionMenuButton setShowsMenuWhenIconClicked:YES];
	[[actionMenuButton cell] setAltersStateOfSelectedItem:NO];
	[[actionMenuButton cell] setAlwaysUsesFirstItemAsSelected:NO];
	[[actionMenuButton cell] setUsesItemFromMenu:NO];
	[[actionMenuButton cell] setRefreshesMenu:NO];
	
	[groupActionMenuButton setArrowImage:[NSImage imageNamed:@"ArrowPointingDown"]];
	[groupActionMenuButton setShowsMenuWhenIconClicked:YES];
	[[groupActionMenuButton cell] setAltersStateOfSelectedItem:NO];
	[[groupActionMenuButton cell] setAlwaysUsesFirstItemAsSelected:NO];
	[[groupActionMenuButton cell] setUsesItemFromMenu:NO];
	[[groupActionMenuButton cell] setRefreshesMenu:NO];
	
	[groupActionButton setArrowImage:nil];
	[groupActionButton setAlternateImage:[NSImage imageNamed:@"GroupAction_Pressed"]];
	[groupActionButton setShowsMenuWhenIconClicked:YES];
	[[groupActionButton cell] setAltersStateOfSelectedItem:NO];
	[[groupActionButton cell] setAlwaysUsesFirstItemAsSelected:NO];
	[[groupActionButton cell] setUsesItemFromMenu:NO];
	[[groupActionButton cell] setRefreshesMenu:NO];
	
	BDSKImagePopUpButton *cornerViewButton = (BDSKImagePopUpButton*)[tableView cornerView];
	[cornerViewButton setAlternateImage:[NSImage imageNamed:@"cornerColumns_Pressed"]];
	[cornerViewButton setShowsMenuWhenIconClicked:YES];
	[[cornerViewButton cell] setAltersStateOfSelectedItem:NO];
	[[cornerViewButton cell] setAlwaysUsesFirstItemAsSelected:NO];
	[[cornerViewButton cell] setUsesItemFromMenu:NO];
	[[cornerViewButton cell] setRefreshesMenu:NO];
    
	[cornerViewButton setMenu:[[[NSApp delegate] columnsMenuItem] submenu]];
    
	BDSKGroupTableHeaderView *headerView = (BDSKGroupTableHeaderView *)[groupTableView headerView];
	NSPopUpButtonCell *headerCell = [headerView popUpHeaderCell];
	[headerCell setAction:@selector(changeGroupFieldAction:)];
	[headerCell setTarget:self];
	[headerCell setMenu:[self groupFieldsMenu]];
	[(BDSKHeaderPopUpButtonCell *)headerCell setIndicatorImage:[NSImage imageNamed:sortGroupsDescending ? @"NSDescendingSortIndicator" : @"NSAscendingSortIndicator"]];
    [(BDSKHeaderPopUpButtonCell *)headerCell setUsesItemFromMenu:NO];
	[headerCell setTitle:currentGroupField];
    if([headerCell itemWithTitle:currentGroupField])
        [headerCell selectItemWithTitle:currentGroupField];
    else
        [headerCell selectItemAtIndex:0];
    
    [saveTextEncodingPopupButton removeAllItems];
    [saveTextEncodingPopupButton addItemsWithTitles:[[BDSKStringEncodingManager sharedEncodingManager] availableEncodingDisplayedNames]];
        
    if([documentWindow respondsToSelector:@selector(setAutorecalculatesKeyViewLoop:)])
        [documentWindow setAutorecalculatesKeyViewLoop:YES];
    
    // array of BDSKSharedGroup objects and zeroconf support; 10.4 only for now
    // doesn't do anything when already enabled
    // we don't do this in appcontroller as we want our data to be loaded
    sharedGroups = nil;
    sharedGroupSpinners = nil;
    if(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3){
        if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShouldLookForSharedFilesKey]){
            [[BDSKSharingBrowser sharedBrowser] enableSharedBrowsing];
            // force an initial update of the tableview, if browsing is already in progress
            [self handleSharedGroupsChangedNotification:nil];
        }
        if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShouldShareFilesKey])
            [[BDSKSharingServer defaultServer] enableSharing];
    }    
    
    // @@ awakeFromNib is called long after the document's data is loaded, so the UI update from setPublications is too early when loading a new document; there may be a better way to do this
    [self updateGroupsPreservingSelection:NO];
    [self updateAllSmartGroups];

}

- (NSString *)windowNibName{
        return @"BibDocument";
}

- (void)showWindows{
    [super showWindows];
    // Get the search string keyword if available (Spotlight passes this)
    if(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3){
        NSAppleEventDescriptor *event = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
        NSString *searchString = [[event descriptorForKeyword:keyAESearchText] stringValue];
        
        if([event eventID] == kAEOpenDocuments && searchString != nil){
            // We want to handle open events for our Spotlight cache files differently; rather than setting the search field, we can jump to them immediately since they have richer context.  This code gets the path of the document being opened in order to check the file extension.
            NSString *hfsPath = [[[event descriptorForKeyword:keyAEResult] coerceToDescriptorType:typeFileURL] stringValue];
            
            // hfsPath will be nil for under some conditions, which seems strange; possibly because I wasn't checking eventID == 'odoc'?
            if(hfsPath == nil) NSLog(@"No path available from event %@ (descriptor %@)", event, [event descriptorForKeyword:keyAEResult]);
            NSURL *fileURL = (hfsPath == nil ? nil : [(id)CFURLCreateWithFileSystemPath(CFAllocatorGetDefault(), (CFStringRef)hfsPath, kCFURLHFSPathStyle, FALSE) autorelease]);
            
            OBPOSTCONDITION(fileURL != nil);
            if(fileURL == nil || [[[NSWorkspace sharedWorkspace] UTIForURL:fileURL] isEqualToUTI:@"net.sourceforge.bibdesk.bdskcache"] == NO){
                [self selectGroup:allPublicationsGroup];
                [self setSelectedSearchFieldKey:BDSKAllFieldsString];
                [self setFilterField:searchString];
            }
        }
    }
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    
    [aController setShouldCloseDocument:YES];
    
    [self setupToolbar];
    
    // set the frame from prefs first, or setFrameAutosaveName: will overwrite the prefs with the nib values if it returns NO
    [[aController window] setFrameUsingName:@"Main Window Frame Autosave"];
    // we should only cascade windows if we have multiple documents open; bug #1299305
    // the default cascading does not reset the next location when all windows have closed, so we do cascading ourselves
    static NSPoint nextWindowLocation = {0.0, 0.0};
    [aController setShouldCascadeWindows:NO];
    if ([[aController window] setFrameAutosaveName:@"Main Window Frame Autosave"]) {
        NSRect windowFrame = [[aController window] frame];
        nextWindowLocation = NSMakePoint(NSMinX(windowFrame), NSMaxY(windowFrame));
    }
    nextWindowLocation = [[aController window] cascadeTopLeftFromPoint:nextWindowLocation];
    
    [documentWindow makeFirstResponder:tableView];	
    [tableView removeAllTableColumns];
	[self setupTableColumns]; // calling it here mostly just makes sure that the menu is set up.
    [self sortPubsByDefaultColumn];
}

- (void)dealloc{
#if DEBUG
    NSLog(@"bibdoc dealloc");
#endif
    [fileSearchController release];
    if ([self undoManager]) {
        [[self undoManager] removeAllActionsWithTarget:self];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[BDSKErrorObjectController sharedErrorObjectController] removeErrorObjsForDocument:self];
    [macroResolver release];
    [itemsForCiteKeys release];
    // set pub document ivars to nil, or we get a crash when they message the undo manager in dealloc (only happens if you edit, click to close the doc, then save)
    [publications makeObjectsPerformSelector:@selector(setDocument:) withObject:nil];
    [publications release];
    [shownPublications release];
    [groupedPublications release];
    [categoryGroups release];
    [smartGroups release];
    [staticGroups release];
    [allPublicationsGroup release];
    [lastImportGroup release];
    [frontMatter release];
    [documentInfo release];
    [quickSearchKey release];
    [customStringArray release];
    [toolbarItems release];
	[statusBar release];
	[texTask release];
    [macroWC release];
    [infoWC release];
    [promiseDragColumnIdentifier release];
    [lastSelectedColumnForSort release];
    [sortGroupsKey release];
	[promisedPboardTypes release];
    [sharedGroups release];
    [sharedGroupSpinners release];
    [super dealloc];
}

- (BOOL)undoManagerShouldUndoChange:(id)sender{
	if (![self isDocumentEdited]) {
		BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Warning", @"Warning") 
											 defaultButton:NSLocalizedString(@"Yes", @"undo the changes") 
										   alternateButton:NSLocalizedString(@"No", @"don't undo the changes") 
											   otherButton:nil
								 informativeTextWithFormat:NSLocalizedString(@"You are about to undo past the last point this file was saved. Do you want to do this?", @"") ];

		int rv = [alert runSheetModalForWindow:documentWindow
								 modalDelegate:self
								didEndSelector:NULL
							didDismissSelector:NULL
								   contextInfo:nil];
		if (rv == NSAlertAlternateReturn)
			return NO;
	}
	return YES;
}

// implement for 10.3 compatibility
- (NSURL *)fileURL{
    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3)
        return [NSURL fileURLWithPath:[self fileName]];
    else
        return [super fileURL];
}

#pragma mark Publications acessors

- (void)setPublications:(NSArray *)newPubs undoable:(BOOL)undo{
    if(newPubs != publications){

        // we don't want to undo when initially setting the publications array, or the document is dirty
        // we do want to have undo otherwise though, e.g. for undoing -sortForCrossrefs:
        if(undo){
            NSUndoManager *undoManager = [self undoManager];
            [[undoManager prepareWithInvocationTarget:self] setPublications:publications];
        }
        
		// current publications (if any) will no longer have a document
		[publications makeObjectsPerformSelector:@selector(setDocument:) withObject:nil];
        
		[publications setArray:newPubs];
		[publications makeObjectsPerformSelector:@selector(setDocument:) withObject:self];
        [self rebuildItemsForCiteKeys];
		
		NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:newPubs, @"pubs", nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocSetPublicationsNotification
															object:self
														  userInfo:notifInfo];
    }
}    

- (void)setPublications:(NSArray *)newPubs{
    [self setPublications:newPubs undoable:YES];
}

- (NSMutableArray *) publications{
    return publications;
}

- (void)insertPublications:(NSArray *)pubs atIndexes:(NSIndexSet *)indexes{
    // this assertion is only necessary to preserve file order for undo
    NSParameterAssert([indexes count] == [pubs count]);
    [[[self undoManager] prepareWithInvocationTarget:self] removePublicationsAtIndexes:indexes];
		
	[publications insertObjects:pubs atIndexes:indexes];        
    
	[pubs makeObjectsPerformSelector:@selector(setDocument:) withObject:self];
	[self addToItemsForCiteKeys:pubs];
	
	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:pubs, @"pubs", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocAddItemNotification
														object:self
													  userInfo:notifInfo];
}

- (void)insertPublication:(BibItem *)pub atIndex:(unsigned int)index {
    [self insertPublications:[NSArray arrayWithObject:pub] atIndexes:[NSIndexSet indexSetWithIndex:index]];
}

- (void)addPublications:(NSArray *)pubs{
    [self insertPublications:pubs atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[pubs count])]];
}

- (void)addPublication:(BibItem *)pub{
    [self insertPublication:pub atIndex:0]; // insert new pubs at the beginning, so item number is handled properly
}

- (void)removePublicationsAtIndexes:(NSIndexSet *)indexes{
    NSArray *pubs = [publications objectsAtIndexes:indexes];
	[[[self undoManager] prepareWithInvocationTarget:self] insertPublications:pubs atIndexes:indexes];
	
	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:pubs, @"pubs", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocWillRemoveItemNotification
														object:self
													  userInfo:notifInfo];	
    
    [lastImportGroup removePublicationsInArray:pubs];
    [[self staticGroups] makeObjectsPerformSelector:@selector(removePublicationsInArray:) withObject:pubs];
    
	[publications removeObjectsAtIndexes:indexes];
	
	[pubs makeObjectsPerformSelector:@selector(setDocument:) withObject:nil];
	[self removeFromItemsForCiteKeys:pubs];
	if(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3)
		[[NSFileManager defaultManager] removeSpotlightCacheForItemsNamed:[pubs arrayByPerformingSelector:@selector(citeKey)]];
	
	notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:pubs, @"pubs", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocDelItemNotification
														object:self
													  userInfo:notifInfo];
}

- (void)removePublications:(NSArray *)pubs{
    [self removePublicationsAtIndexes:[publications indexesOfObjectsIdenticalTo:pubs]];
}

- (void)removePublication:(BibItem *)pub{
	NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:[publications indexOfObjectIdenticalTo:pub]];
    [self removePublicationsAtIndexes:indexes];
}

- (NSArray *)publicationsForAuthor:(BibAuthor *)anAuthor{
    NSMutableSet *auths = BDSKCreateFuzzyAuthorCompareMutableSet();
    NSEnumerator *pubEnum = [publications objectEnumerator];
    BibItem *bi;
    NSMutableArray *anAuthorPubs = [NSMutableArray array];
    
    while(bi = [pubEnum nextObject]){
        [auths addObjectsFromArray:[bi pubAuthors]];
        if([auths containsObject:anAuthor]){
            [anAuthorPubs addObject:bi];
        }
        [auths removeAllObjects];
    }
    [auths release];
    return anAuthorPubs;
}

#pragma mark Document Info

- (NSDictionary *)documentInfo{
    return documentInfo;
}

- (void)setDocumentInfoWithoutUndo:(NSDictionary *)dict{
    [documentInfo setDictionary:dict];
}

- (void)setDocumentInfo:(NSDictionary *)dict{
    [[[self undoManager] prepareWithInvocationTarget:self] setDocumentInfo:[[documentInfo copy] autorelease]];
    [documentInfo setDictionary:dict];
}

- (NSString *)documentInfoForKey:(NSString *)key{
    return [documentInfo valueForKey:key];
}

- (void)setDocumentInfo:(NSString *)value forKey:(NSString *)key{
    [[[self undoManager] prepareWithInvocationTarget:self] setDocumentInfo:[self documentInfoForKey:key] forKey:key];
    [documentInfo setValue:value forKey:key];
}

- (id)valueForUndefinedKey:(NSString *)key{
    return [self documentInfoForKey:key];
}

- (NSString *)documentInfoString{
    NSMutableString *string = [NSMutableString stringWithString:@"@bibdesk_info{document_info"];
    NSEnumerator *keyEnum = [documentInfo keyEnumerator];
    NSString *key;
    
    while (key = [keyEnum nextObject]) 
        [string appendStrings:@",\n\t", key, @" = ", [[self documentInfoForKey:key] stringAsBibTeXString], nil];
    [string appendString:@"\n}\n"];
    
    return string;
}

- (IBAction)showDocumentInfoWindow:(id)sender{
    if (!infoWC) {
        infoWC = [(BDSKDocumentInfoWindowController *)[BDSKDocumentInfoWindowController alloc] initWithDocument:self];
    }
    if ([[self windowControllers] containsObject:infoWC] == NO) {
        [self addWindowController:infoWC];
    }
    [infoWC beginSheetModalForWindow:documentWindow];
}

#pragma mark -
#pragma mark  Document Saving

#define SAVE_ENCODING_VIEW_OFFSET 10.0

// if the user is saving in one of our plain text formats, give them an encoding option as well
// this also requires overriding saveToFile:saveOperation:delegate:didSaveSelector:contextInfo:
// to set the document's encoding before writing to the file
- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel{
    if([super prepareSavePanel:savePanel]){
        if([[self fileType] isEqualToString:BDSKBibTeXDocumentType] || [[self fileType] isEqualToString:BDSKRISDocumentType]){
            NSView *oldAccessoryView = [[savePanel accessoryView] retain];
            if(oldAccessoryView == nil){
                [savePanel setAccessoryView:saveEncodingAccessoryView];
            }else{
                NSRect sevFrame, ignored, avFrame = [oldAccessoryView frame];
                float height = NSHeight([saveEncodingAccessoryView frame]);
                avFrame.size.height += height - SAVE_ENCODING_VIEW_OFFSET;
                NSView *accessoryView = [[NSView alloc] initWithFrame:avFrame];
                NSDivideRect([accessoryView bounds], &sevFrame, &ignored, height, NSMaxYEdge);
                [saveEncodingAccessoryView setFrame:sevFrame];
                [accessoryView addSubview:saveEncodingAccessoryView];
                [savePanel setAccessoryView:accessoryView];
                [oldAccessoryView setFrameOrigin:NSZeroPoint];
                [accessoryView addSubview:oldAccessoryView];
                [oldAccessoryView release];
                [accessoryView release];
            }
            // set the popup to reflect the document's present string encoding
            NSString *defaultEncName = [[BDSKStringEncodingManager sharedEncodingManager] displayedNameForStringEncoding:[self documentStringEncoding]];
            [saveTextEncodingPopupButton selectItemWithTitle:defaultEncName];
            [[savePanel accessoryView] setNeedsDisplay:YES];
        } return YES;
    } else return NO; // if super failed
}

// overriden in order to set the string encoding before writing out to disk, in case it was changed in the save-as panel
- (void)saveToFile:(NSString *)fileName 
     saveOperation:(NSSaveOperationType)saveOperation 
          delegate:(id)delegate 
   didSaveSelector:(SEL)didSaveSelector 
       contextInfo:(void *)contextInfo{
    // set the string encoding according to the popup if it's a plain text type
    if([[self fileType] isEqualToString:BDSKBibTeXDocumentType] || [[self fileType] isEqualToString:BDSKRISDocumentType])
        [self setDocumentStringEncoding:[[BDSKStringEncodingManager sharedEncodingManager] 
                                            stringEncodingForDisplayedName:[saveTextEncodingPopupButton titleOfSelectedItem]]];
    [super saveToFile:fileName saveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError {
    // Override so we can determine if this is an autosave in writeToFile:ofType:, since saveToFile... will never be called with NSAutosaveOperation for backwards compatibility.  This is necessary on 10.4 to keep from calling the clearChangeCount hack for an autosave, which incorrectly marks the document as clean.
    currentSaveOperationType = saveOperation;
    return [super writeToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation originalContentsURL:absoluteOriginalContentsURL error:outError];
}

// we override this method only to catch exceptions raised during TeXification of BibItems
// returning NO keeps the document window from closing if the save was initiated by a close
// action, so the user gets a second chance at fixing the problem
// this method eventually gets called for save or save-as operations
- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)docType{

    BOOL success = YES;
    NSString *error = nil;
    @try{
        success = [super writeToFile:fileName ofType:docType];
    }
    @catch(id exception){
        if([exception isKindOfClass:[NSException class]] && [[exception name] isEqualToString:BDSKTeXifyException]){
            success = NO;
            error = [exception reason];
            if([[exception userInfo] valueForKey:@"item"])
                [self highlightBib:[[exception userInfo] valueForKey:@"item"]];
        } else {
            @throw;
        }
    }
    
    // needed because of finalize changes; don't send this if the save failed for any reason, or if we're autosaving!
	if(success && currentSaveOperationType != 3)
        [self performSelector:@selector(clearChangeCount) withObject:nil afterDelay:0.01];
    else if(error != nil){
        NSString *errTitle = currentSaveOperationType == 3 ? NSLocalizedString(@"Unable to Autosave File", @"") : NSLocalizedString(@"Unable to Save File", @"");
        NSString *errMsg = [NSString stringWithFormat:@"%@  %@", error, NSLocalizedString(@"If you are unable to fix this item, you must disable character conversion in BibDesk's preferences and save your file in an encoding such as UTF-8.", @"")];
        // log in case the sheet crashes us for some reason
        NSLog(@"%@!  %@", errTitle, errMsg);
        // we present a special sheet if the save failed due to texification; NSDocument still puts up its own save failed sheet, at least for save-as
        NSBeginCriticalAlertSheet(errTitle, nil, nil, nil, documentWindow, nil, NULL, NULL, NULL, errMsg);
    }

    // rebuild metadata cache for this document whenever we save
    if([self fileName]){
        // don't pass the fileName parameter, since it's likely a temp file somewhere due to the atomic save operation
        NSDictionary *infoDict = [[NSDictionary alloc] initWithObjectsAndKeys:[self publications], @"publications", [self fileName], @"fileName", nil];
        [[NSApp delegate] rebuildMetadataCache:infoDict];
        [infoDict release];
    }
        
    return success;
}

- (IBAction)saveDocument:(id)sender{
    [super saveDocument:sender];
    if([[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKAutoSaveAsRSSKey] == NSOnState && ![[self fileType] isEqualToString:@"Rich Site Summary file"])
        [self exportAsFileType:BDSKRSSExportFileType selected:NO];
}

- (void)clearChangeCount{
	[self updateChangeCount:NSChangeCleared];
}

#pragma mark Document Exporting

- (IBAction)exportAsAction:(id)sender{
    [self exportAsFileType:[sender tag] selected:NO];
}

- (IBAction)exportSelectionAsAction:(id)sender{
    [self exportAsFileType:[sender tag] selected:YES];
}

- (IBAction)changeCurrentExportTemplateStyle:(id)sender{
    NSString *currentSyle = [sender titleOfSelectedItem];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:currentSyle forKey:BDSKExportTemplateStyleKey];
    
    BDSKTemplate *selectedTemplate = [BDSKTemplate templateForStyle:currentSyle];
    [(NSSavePanel *)[sender window] setRequiredFileType:[selectedTemplate fileExtension]];
}

- (BOOL)prepareExportPanel:(NSSavePanel *)savePanel{
    NSArray *styles = [BDSKTemplate allStyleNames];
    NSString *currentStyle = [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKExportTemplateStyleKey];
    if(currentStyle == nil || [styles containsObject:currentStyle] == NO){
        currentStyle = [styles objectAtIndex:0];
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:currentStyle forKey:BDSKExportTemplateStyleKey];
    }
    
    [templateStylePopUpButton removeAllItems];
    [templateStylePopUpButton addItemsWithTitles:styles];
    [templateStylePopUpButton setAction:@selector(changeCurrentExportTemplateStyle:)];
    [templateStylePopUpButton setTarget:self];
    [templateStylePopUpButton selectItemWithTitle:currentStyle];
    
    [savePanel setAccessoryView:templateExportAccessoryView];
    
    return YES;
}

- (void)exportAsFileType:(int)exportFileType selected:(BOOL)selected{
    NSSavePanel *sp = [NSSavePanel savePanel];
    NSString *fileType = nil;
    switch (exportFileType) {
        case BDSKTemplateExportFileType:
            if ([self prepareExportPanel:sp] == NO) {
                NSBeep();
                return;
            }
            fileType = [[BDSKTemplate templateForStyle:[templateStylePopUpButton titleOfSelectedItem]] fileExtension];
            break;
        case BDSKRSSExportFileType:
            fileType = @"rss";
            break;
        case BDSKHTMLExportFileType:
            fileType = @"html";
            break;
        case BDSKRTFExportFileType:
            fileType = @"rtf";
            break;
        case BDSKRTFDExportFileType:
            fileType = @"rtfd";
            break;
        case BDSKDocExportFileType:
            fileType = @"doc";
            break;
        case BDSKBibTeXExportFileType:
            [sp setAccessoryView:dropInternalAccessoryView];
            [dropInternalCheckButton setState:NSOffState];
            [self prepareSavePanel:sp]; // adds the encoding popup
            fileType = @"bib";
            break;
        case BDSKRISExportFileType:
            [self prepareSavePanel:sp]; // adds the encoding popup
            fileType = @"ris";
            break;
        case BDSKLTBExportFileType:
            [self prepareSavePanel:sp]; // adds the encoding popup
            fileType = @"ltb";
            break;
        case BDSKMODSExportFileType:
            fileType = @"mods";
            break;
        case BDSKEndNoteExportFileType:
            fileType = @"xml";
            break;
        case BDSKAtomExportFileType:
            fileType = @"atom";
            break;
    }
    [sp setRequiredFileType:fileType];
    [sp setCanCreateDirectories:YES];
    [sp setCanSelectHiddenExtension:YES];
    [sp setDelegate:self];
    NSDictionary *contextInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
		[NSNumber numberWithInt:exportFileType], @"exportFileType", [NSNumber numberWithBool:selected], @"selected", nil];
    [sp beginSheetForDirectory:nil
                          file:( [self fileName] == nil ? nil : [[NSString stringWithString:[[self fileName] stringByDeletingPathExtension]] lastPathComponent])
                modalForWindow:documentWindow
                 modalDelegate:self
                didEndSelector:@selector(exportPanelDidEnd:returnCode:contextInfo:)
                   contextInfo:contextInfo];

}

// this is only called by export actions, and isn't part of the regular save process
- (void)exportPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    NSData *fileData = nil;
    NSString *fileName = nil;
    NSSavePanel *sp = (NSSavePanel *)sheet;
    NSDictionary *dict = (NSDictionary *)contextInfo;
    int exportFileType = [[dict objectForKey:@"exportFileType"] intValue];
    BOOL selected = [[dict objectForKey:@"selected"] boolValue];
    NSArray *items = (selected ? [self selectedPublications] : publications);
    NSStringEncoding encoding;
	
	// first we make sure all edits are committed
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKFinalizeChangesNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionary]];
	
    if(returnCode == NSOKButton){
        fileName = [sp filename];
        NSString *templateStyle = nil;
        switch (exportFileType) {
            case BDSKRSSExportFileType:
            case BDSKHTMLExportFileType:
            case BDSKRTFExportFileType:
            case BDSKRTFDExportFileType:
            case BDSKDocExportFileType:
                do {
                    templateStyle = [BDSKTemplate defaultStyleNameForFileType:[sp requiredFileType]];
                    if (templateStyle == nil)   
                        break;
                } while (0);
            case BDSKTemplateExportFileType:
                do {
                    if (templateStyle == nil) 
                        templateStyle = [templateStylePopUpButton titleOfSelectedItem];
                    BDSKTemplate *selectedTemplate = [BDSKTemplate templateForStyle:templateStyle];
                    BDSKTemplateFormat templateFormat = [selectedTemplate templateFormat];
                    NSString *extension = [selectedTemplate fileExtension];
                    fileName = [[fileName stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
                    NSEnumerator *accessoryFileEnum = [[selectedTemplate accessoryFileURLs] objectEnumerator];
                    NSURL *accessoryURL = nil;
                    NSURL *destDirURL = [NSURL fileURLWithPath:[fileName stringByDeletingLastPathComponent]];
                    while(accessoryURL = [accessoryFileEnum nextObject]){
                        [[NSFileManager defaultManager] copyObjectAtURL:accessoryURL toDirectoryAtURL:destDirURL error:NULL];
                    }
                    if (templateFormat & BDSKRTFDTemplateFormat) {
                        NSFileWrapper *fileWrapper = [self fileWrapperForPublications:items usingTemplate:selectedTemplate];
                        [fileWrapper writeToFile:fileName atomically:YES updateFilenames:NO];
                        fileData = nil;
                    } else if (templateFormat & BDSKTextTemplateFormat) {
                        fileData = [self stringDataForPublications:items usingTemplate:selectedTemplate];
                    } else {
                        fileData = [self attributedStringDataForPublications:items usingTemplate:selectedTemplate];
                    }
                } while (0);
                break;
            case BDSKMODSExportFileType:
                fileData = [self MODSDataForPublications:items];
                break;
            case BDSKEndNoteExportFileType:
                fileData = [self endNoteDataForPublications:items];
                break;
            case BDSKAtomExportFileType:
                fileData = [self atomDataForPublications:items];
                break;
            case BDSKBibTeXExportFileType:
                encoding = [[BDSKStringEncodingManager sharedEncodingManager] stringEncodingForDisplayedName:[saveTextEncodingPopupButton titleOfSelectedItem]];
                if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKAutoSortForCrossrefsKey]){
                    [self performSortForCrossrefs];
                    items = (selected ? [self selectedPublications] : publications);
                }
                fileData = [self bibTeXDataForPublications:items encoding:encoding droppingInternal:([dropInternalCheckButton state] == NSOnState)];
                break;
            case BDSKRISExportFileType:
                encoding = [[BDSKStringEncodingManager sharedEncodingManager] stringEncodingForDisplayedName:[saveTextEncodingPopupButton titleOfSelectedItem]];
                fileData = [self RISDataForPublications:items encoding:encoding];
                break;
            case BDSKLTBExportFileType:
                encoding = [[BDSKStringEncodingManager sharedEncodingManager] stringEncodingForDisplayedName:[saveTextEncodingPopupButton titleOfSelectedItem]];
                fileData = [self LTBDataForPublications:items encoding:encoding];
                break;
        }
        [fileData writeToFile:fileName atomically:YES];
    }
    [sp setRequiredFileType:@"bib"]; // just in case...
    [sp setAccessoryView:nil];
	[dict release];
}

#pragma mark Data representations

// this is only called for Save (As) menu actions, not for Export
- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    // first we make sure all edits are committed
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKFinalizeChangesNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionary]];
    NSData *data = nil;
    
    if ([aType isEqualToString:BDSKBibTeXDocumentType]){
        if([self documentStringEncoding] == 0)
            [NSException raise:@"String encoding exception" format:@"Document does not have a specified string encoding."];
        if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKAutoSortForCrossrefsKey])
            [self performSortForCrossrefs];
        data = [self bibTeXDataForPublications:publications encoding:[self documentStringEncoding] droppingInternal:NO];
    }else if ([aType isEqualToString:BDSKRISDocumentType]){
        data = [self RISDataForPublications:publications];
    }

    return data;
}

#define AddDataFromString(s) [d appendData:[s dataUsingEncoding:NSUTF8StringEncoding]]
#define AddDataFromFormCellWithTag(n) [d appendData:[[[rssExportForm cellAtIndex:[rssExportForm indexOfCellWithTag:n]] stringValue] dataUsingEncoding:NSUTF8StringEncoding]]

// @@ templating: use template to write rss? Then make accessory view data accessible through a temporary dictionary accessor
- (NSData *)rssDataForPublications:(NSArray *)items{
    NSEnumerator *e = [items objectEnumerator];
	BibItem *pub = nil;
    NSMutableData *d = [NSMutableData data];

    //  NSString *RSSTemplateFileName = [applicationSupportPath stringByAppendingPathComponent:@"rssTemplate.txt"];
    
    // add boilerplate RSS
    //    AddDataFromString(@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<rdf:RDF\nxmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"\nxmlns:bt=\"http://purl.org/rss/1.0/modules/bibtex/\"\nxmlns=\"http://purl.org/rss/1.0/\">\n<channel>\n");
    AddDataFromString(@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<rss version=\"0.92\">\n<channel>\n");
    AddDataFromString(@"<title>");
    AddDataFromFormCellWithTag(0);
    AddDataFromString(@"</title>\n");
    AddDataFromString(@"<link>");
    AddDataFromFormCellWithTag(1);
    AddDataFromString(@"</link>\n");
    AddDataFromString(@"<description>");
    [d appendData:[[rssExportTextField stringValue] dataUsingEncoding:NSUTF8StringEncoding]];
    AddDataFromString(@"</description>\n");
    AddDataFromString(@"<language>");
    AddDataFromFormCellWithTag(2);
    AddDataFromString(@"</language>\n");
    AddDataFromString(@"<copyright>");
    AddDataFromFormCellWithTag(3);
    AddDataFromString(@"</copyright>\n");
    AddDataFromString(@"<editor>");
    AddDataFromFormCellWithTag(4);
    AddDataFromString(@"</editor>\n");
    AddDataFromString(@"<lastBuildDate>");
    [d appendData:[[[NSCalendarDate calendarDate] descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S %Z"] dataUsingEncoding:NSUTF8StringEncoding]];
    AddDataFromString(@"</lastBuildDate>\n");
    
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);
    NSData *doubleLineFeed = [[NSString stringWithString:@"\n\n"] dataUsingEncoding:NSUTF8StringEncoding];
	while(pub = [e nextObject]){
		[d appendData:doubleLineFeed];
        [d appendData:[[pub RSSValue] dataUsingEncoding:NSUTF8StringEncoding]];
    }
	
    [d appendData:[@"</channel>\n</rss>" dataUsingEncoding:NSUTF8StringEncoding]];
    return d;
}

- (NSData *)atomDataForPublications:(NSArray *)items{
    NSEnumerator *e = [items objectEnumerator];
	BibItem *pub = nil;
    NSMutableData *d = [NSMutableData data];
    
    AddDataFromString(@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><feed xmlns=\"http://purl.org/atom/ns#\">");
    
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);
    
    // TODO: output general feed info
    
	while(pub = [e nextObject]){
        AddDataFromString(@"<entry><title>foo</title><description>foo-2</description>");
        AddDataFromString(@"<content type=\"application/xml+mods\">");
        AddDataFromString([pub MODSString]);
        AddDataFromString(@"</content>");
        AddDataFromString(@"</entry>\n");
    }
    AddDataFromString(@"</feed>");
    
    return d;    
}

- (NSData *)MODSDataForPublications:(NSArray *)items{
    NSEnumerator *e = [items objectEnumerator];
	BibItem *pub = nil;
    NSMutableData *d = [NSMutableData data];
    
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);

    AddDataFromString(@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><modsCollection xmlns=\"http://www.loc.gov/mods/v3\">");
	while(pub = [e nextObject]){
        AddDataFromString([pub MODSString]);
        AddDataFromString(@"\n");
    }
    AddDataFromString(@"</modsCollection>");
    
    return d;
}

- (NSData *)endNoteDataForPublications:(NSArray *)items{
    NSEnumerator *e = [items objectEnumerator];
	BibItem *pub = nil;
    NSMutableData *d = [NSMutableData data];
    
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);

    AddDataFromString(@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<xml>\n<records>\n");
	while(pub = [e nextObject]){
        AddDataFromString([pub endNoteString]);
    }
    AddDataFromString(@"</records>\n</xml>\n");
    
    return d;
}

- (NSData *)bibTeXDataForPublications:(NSArray *)items encoding:(NSStringEncoding)encoding droppingInternal:(BOOL)drop{
    NSEnumerator *e = [items objectEnumerator];
	BibItem *pub = nil;
    NSMutableData *d = [NSMutableData data];
    
    if(encoding == 0)
        [NSException raise:@"String encoding exception" format:@"Sender did not specify an encoding to %@.", NSStringFromSelector(_cmd)];
    
    BOOL shouldAppendFrontMatter = YES;
	
    if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShouldUseTemplateFile]){
        NSMutableString *templateFile = [NSMutableString stringWithContentsOfFile:[[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKOutputTemplateFileKey] stringByExpandingTildeInPath]];
        
        [templateFile appendFormat:@"\n%%%% Created for %@ at %@ \n\n", NSFullUserName(), [NSCalendarDate calendarDate]];

        NSString *encodingName = [[BDSKStringEncodingManager sharedEncodingManager] displayedNameForStringEncoding:encoding];

        [templateFile appendFormat:@"\n%%%% Saved with string encoding %@ \n\n", encodingName];
        
        // remove all whitespace so we can make a comparison; just collapsing isn't quite good enough, unfortunately
        NSString *collapsedTemplate = [templateFile stringByRemovingWhitespace];
        NSString *collapsedFrontMatter = [frontMatter stringByRemovingWhitespace];
        if([NSString isEmptyString:collapsedFrontMatter]){
            shouldAppendFrontMatter = NO;
		}else if([collapsedTemplate containsString:collapsedFrontMatter]){
            NSLog(@"*** WARNING! *** Found duplicate preamble %@.  Using template from preferences.", frontMatter);
            shouldAppendFrontMatter = NO;
        }
        
        [d appendData:[templateFile dataUsingEncoding:encoding allowLossyConversion:YES]];
    }
    
    // only append this if it wasn't redundant (this assumes that the original frontmatter is either a subset of the necessary frontmatter, or that the user's preferences should override in case of a conflict)
    if(shouldAppendFrontMatter){
        [d appendData:[frontMatter dataUsingEncoding:encoding allowLossyConversion:YES]];
        [d appendData:[@"\n\n" dataUsingEncoding:encoding allowLossyConversion:YES]];
    }
        
    if([documentInfo count]){
        [d appendData:[[self documentInfoString] dataUsingEncoding:encoding allowLossyConversion:YES]];
    }
    
    // output the document's macros:
	[d appendData:[[[self macroResolver] bibTeXString] dataUsingEncoding:encoding allowLossyConversion:YES]];
    
    // output the bibs
    
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);

	while(pub = [e nextObject]){
        [d appendData:[[NSString stringWithString:@"\n\n"] dataUsingEncoding:encoding  allowLossyConversion:YES]];
        [d appendData:[[pub bibTeXStringDroppingInternal:drop] dataUsingEncoding:encoding allowLossyConversion:YES]];
    }
	
	if([staticGroups count] > 0){
        [d appendData:[@"\n\n@comment{BibDesk Static Groups{\n" dataUsingEncoding:encoding allowLossyConversion:YES]];
		[d appendData:[self serializedStaticGroupsData]];
        [d appendData:[@"}}" dataUsingEncoding:encoding allowLossyConversion:YES]];
	}
	if([smartGroups count] > 0){
        [d appendData:[@"\n\n@comment{BibDesk Smart Groups{\n" dataUsingEncoding:encoding allowLossyConversion:YES]];
		[d appendData:[self serializedSmartGroupsData]];
        [d appendData:[@"}}" dataUsingEncoding:encoding allowLossyConversion:YES]];
	}
	[d appendData:[@"\n" dataUsingEncoding:encoding allowLossyConversion:YES]];
	
    return d;
        
}

- (NSData *)RISDataForPublications:(NSArray *)items encoding:(NSStringEncoding)encoding{
    if(encoding == 0)
        [NSException raise:@"String encoding exception" format:@"Sender did not specify an encoding to %@.", NSStringFromSelector(_cmd)];
    
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);
    
	return [[self RISStringForPublications:items] dataUsingEncoding:encoding allowLossyConversion:YES];
        
}

- (NSData *)RISDataForPublications:(NSArray *)items{
    
    if([self documentStringEncoding] == 0)
        [NSException raise:@"String encoding exception" format:@"Document does not have a specified string encoding."];
    
    return [self RISDataForPublications:items encoding:[self documentStringEncoding]];
    
}

- (NSData *)LTBDataForPublications:(NSArray *)items encoding:(NSStringEncoding)encoding{
    if(encoding == 0)
        [NSException raise:@"String encoding exception" format:@"Sender did not specify an encoding to %@.", NSStringFromSelector(_cmd)];
    
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);
    
	NSString *bibString = [self previewBibTeXStringForPublications:items];
	if(bibString == nil || 
	   [texTask runWithBibTeXString:bibString generatedTypes:BDSKGenerateLTB] == NO || 
	   [texTask hasLTB] == NO)
		return nil;
    NSMutableString *s = [NSMutableString stringWithString:@"\\documentclass{article}\n\\usepackage{amsrefs}\n\\begin{document}\n\n"];
	[s appendString:[texTask LTBString]];
	[s appendString:@"\n\\end{document}\n"];
	return [s dataUsingEncoding:encoding allowLossyConversion:YES];
}

- (NSData *)LTBDataForPublications:(NSArray *)items{
    
    if([self documentStringEncoding] == 0)
        [NSException raise:@"String encoding exception" format:@"Document does not have a specified string encoding."];
    
    return [self LTBDataForPublications:items encoding:[self documentStringEncoding]];
    
}

- (NSData *)stringDataForPublications:(NSArray *)items usingTemplate:(BDSKTemplate *)template{
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);
    
    OBPRECONDITION(nil != template && ([template templateFormat] & BDSKTextTemplateFormat));
    
    NSString *fileTemplate = [BDSKTemplateObjectProxy stringByParsingTemplate:template withObject:self publications:items];
    
    return [fileTemplate dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
}

- (NSData *)attributedStringDataForPublications:(NSArray *)items usingTemplate:(BDSKTemplate *)template{
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);
    
    OBPRECONDITION(nil != template);
    BDSKTemplateFormat format = [template templateFormat];
    OBPRECONDITION(format & (BDSKRTFTemplateFormat | BDSKDocTemplateFormat | BDSKRichHTMLTemplateFormat));
    NSDictionary *docAttributes = nil;
    NSAttributedString *fileTemplate = [BDSKTemplateObjectProxy attributedStringByParsingTemplate:template withObject:self publications:items documentAttributes:&docAttributes];
    NSMutableDictionary *mutableAttributes = [NSMutableDictionary dictionaryWithDictionary:docAttributes];
    
    // create some useful metadata, with an option to disable for the paranoid
    if((floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3) && [[NSUserDefaults standardUserDefaults] boolForKey:@"BDSKDisableExportAttributesKey"]){
        [mutableAttributes addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:NSFullUserName(), NSAuthorDocumentAttribute, [NSDate date], NSCreationTimeDocumentAttribute, [NSLocalizedString(@"BibDesk export of ", @"") stringByAppendingString:[[self fileName] lastPathComponent]], NSTitleDocumentAttribute, nil]];
    }
    
    if (format & BDSKRTFTemplateFormat) {
        return [fileTemplate RTFFromRange:NSMakeRange(0,[fileTemplate length]) documentAttributes:mutableAttributes];
    } else if (format & BDSKRichHTMLTemplateFormat) {
        [mutableAttributes setObject:NSHTMLTextDocumentType forKey:@"DocumentType"]; /* @@ 10.3: NSDocumentTypeDocumentAttribute */
        NSError *error = nil;
        return [fileTemplate dataFromRange:NSMakeRange(0,[fileTemplate length]) documentAttributes:mutableAttributes error:&error];
    } else if (format & BDSKDocTemplateFormat) {
        return [fileTemplate docFormatFromRange:NSMakeRange(0,[fileTemplate length]) documentAttributes:mutableAttributes];
    } else return nil;
}

- (NSFileWrapper *)fileWrapperForPublications:(NSArray *)items usingTemplate:(BDSKTemplate *)template{
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);
    
    OBPRECONDITION(nil != template && [template templateFormat] & BDSKRTFDTemplateFormat);
    NSDictionary *docAttributes = nil;
    NSAttributedString *fileTemplate = [BDSKTemplateObjectProxy attributedStringByParsingTemplate:template withObject:self publications:items documentAttributes:&docAttributes];
    
    return [fileTemplate RTFDFileWrapperFromRange:NSMakeRange(0,[fileTemplate length]) documentAttributes:docAttributes];
}

#pragma mark -
#pragma mark Opening and Loading Files

- (BOOL)revertToSavedFromFile:(NSString *)fileName ofType:(NSString *)type{
	if([super revertToSavedFromFile:fileName ofType:type]){
		[tableView deselectAll:self]; // clear before resorting
		[self searchFieldAction:searchField]; // redo the search
        [self sortPubsByColumn:nil]; // resort
		return YES;
	}
	return NO;
}

- (BOOL)revertToSavedFromURL:(NSURL *)aURL ofType:(NSString *)type{
	if([super revertToSavedFromURL:aURL ofType:type]){
        [tableView deselectAll:self]; // clear before resorting
		[self searchFieldAction:searchField]; // redo the search
        [self sortPubsByColumn:nil]; // resort
		return YES;
	}
	return NO;
}

// this is implemented for 10.3.9 compatibility only; override NSDocumentController to use the NSError-compatible methods?
- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)type
{
    return [self readFromURL:[NSURL fileURLWithPath:fileName] ofType:type error:NULL];
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)aType error:(NSError **)outError
{
    NSStringEncoding encoding = [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKDefaultStringEncodingKey];
    return [self readFromURL:absoluteURL ofType:aType encoding:encoding error:outError];
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)aType encoding:(NSStringEncoding)encoding error:(NSError **)outError
{
	// for types we only view, we set the file type to BibTeX as that retains the complete information in the file
	if([aType isEqualToString:BDSKRISDocumentType] == NO)
        [self setFileType:BDSKBibTeXDocumentType];
    BOOL success;
    NSData *data = [NSData dataWithContentsOfURL:absoluteURL];
    
    NSError *error = nil;
	if ([aType isEqualToString:BDSKBibTeXDocumentType]){
        success = [self loadBibTeXDataRepresentation:data fromURL:absoluteURL encoding:encoding error:&error];
    }else if([aType isEqualToString:BDSKRISDocumentType]){
		success = [self loadRISDataRepresentation:data fromURL:absoluteURL encoding:encoding error:&error];
    }else{
		// sniff the string to see what format we got
		NSString *string = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
		if(string == nil){
            error = [NSError errorWithDomain:OMNI_BUNDLE_IDENTIFIER @"NSCocoaErrorDomain" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"This document type could not be converted to a text format.", @""), NSLocalizedDescriptionKey, nil]];
            // if we don't give *outError a valid pointer, the second time you drop an unparseable file on the dock icon will cause a crash
            if(outError) *outError = error;
			return NO;
        }
		switch([string contentStringType]){
			case BDSKBibTeXStringType:
				success = [self loadBibTeXDataRepresentation:data fromURL:absoluteURL encoding:encoding error:&error];
                break;
			case BDSKRISStringType:
				success = [self loadRISDataRepresentation:data fromURL:absoluteURL encoding:encoding error:&error];
                break;
			case BDSKJSTORStringType:
				success = [self loadJSTORDataRepresentation:data fromURL:absoluteURL encoding:encoding error:&error];
                break;
			case BDSKWOSStringType:
				success = [self loadWebOfScienceDataRepresentation:data fromURL:absoluteURL encoding:encoding error:&error];
                break;
			default:
				success = NO;
		}
	}
    
    // @@ move this to NSDocumentController; need to figure out where to add it, though
    if(success == NO){
        int rv;
        // run a modal dialog asking if we want to use partial data or give up
        rv = NSRunCriticalAlertPanel([error localizedDescription] ? [error localizedDescription] : NSLocalizedString(@"Error reading file!",@""),
                                     [NSString stringWithFormat:NSLocalizedString(@"There was a problem reading the file.  Do you want to use everything that did work (\"Keep Going\"), edit the file to correct the errors, or give up?\n\nIf you choose \"Keep Going\" and then save the file, you will probably lose data.",@""), [error localizedDescription]],
                                     NSLocalizedString(@"Give Up",@""),
                                     NSLocalizedString(@"Keep Going",@""),
                                     NSLocalizedString(@"Edit File", @""));
        if (rv == NSAlertDefaultReturn) {
            // the user said to give up
            [[BDSKErrorObjectController sharedErrorObjectController] removeErrorObjsForDocument:nil]; // this removes errors from a previous failed load
            [[BDSKErrorObjectController sharedErrorObjectController] handoverErrorObjsForDocument:self]; // this dereferences the doc from the errors, so they won't be removed when the document is deallocated
        }else if (rv == NSAlertAlternateReturn){
            // the user said to keep going, so if they save, they might clobber data...
            // if we don't return YES, NSDocumentController puts up its lame alert saying the document could not be opened, and we get no partial data
            success = YES;
        }else if(rv == NSAlertOtherReturn){
            // they said to edit the file.
            [[BDSKErrorObjectController sharedErrorObjectController] openEditWindowForDocument:self];
            [[BDSKErrorObjectController sharedErrorObjectController] showErrorPanel:self];
        }
    }
    if(outError) *outError = error;
    return success;        
}

- (BOOL)loadRISDataRepresentation:(NSData *)data fromURL:(NSURL *)absoluteURL encoding:(NSStringEncoding)encoding error:(NSError **)outError {
    NSString *dataString = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
    NSMutableArray *newPubs = nil;
    
    if(dataString == nil){
        NSString *encStr = [[BDSKStringEncodingManager sharedEncodingManager] displayedNameForStringEncoding:encoding];
        [NSException raise:BDSKStringEncodingException 
                    format:NSLocalizedString(@"Unable to interpret data as %@.  Try a different encoding.", 
                                             @"need a single NSString format specifier"), encStr];
    }
        
    NSError *error = nil;
	newPubs = [PubMedParser itemsFromString:dataString
                                      error:&error
                                frontMatter:frontMatter
                                   filePath:[absoluteURL path]];
        
    if(outError) *outError = error;
    [self setPublications:newPubs undoable:NO];
    
    // since we can't save pubmed files as pubmed files:
    [self updateChangeCount:NSChangeDone];
    return error == nil;
}


- (BOOL)loadJSTORDataRepresentation:(NSData *)data fromURL:(NSURL *)absoluteURL encoding:(NSStringEncoding)encoding error:(NSError **)outError {
    NSString *dataString = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
    NSMutableArray *newPubs = nil;
    
    if(dataString == nil){
        NSString *encStr = [[BDSKStringEncodingManager sharedEncodingManager] displayedNameForStringEncoding:encoding];
        [NSException raise:BDSKStringEncodingException 
                    format:NSLocalizedString(@"Unable to interpret data as %@.  Try a different encoding.", 
                                             @"need a single NSString format specifier"), encStr];
    }
        
    NSError *error = nil;
	newPubs = [BDSKJSTORParser itemsFromString:dataString
										 error:&error
								   frontMatter:frontMatter
									  filePath:[absoluteURL path]];
    
    [self setPublications:newPubs undoable:NO];
    if(outError) *outError = error;
    
    // since we can't save JSTOR files as JSTOR files:
    [self setFileName:nil];
    
    return error == nil;
}


- (BOOL)loadWebOfScienceDataRepresentation:(NSData *)data fromURL:(NSURL *)absoluteURL encoding:(NSStringEncoding)encoding error:(NSError **)outError {
    NSString *dataString = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
    NSMutableArray *newPubs = nil;
    
    if(dataString == nil){
        NSString *encStr = [[BDSKStringEncodingManager sharedEncodingManager] displayedNameForStringEncoding:encoding];
        [NSException raise:BDSKStringEncodingException 
                    format:NSLocalizedString(@"Unable to interpret data as %@.  Try a different encoding.", 
                                             @"need a single NSString format specifier"), encStr];
    }

    NSError *error = nil;
	newPubs = [BDSKWebOfScienceParser itemsFromString:dataString
												error:&error
										  frontMatter:frontMatter
											 filePath:[absoluteURL path]];
    
    if(outError) *outError = error;
    [self setPublications:newPubs undoable:NO];
    
    // since we can't save wos files as wos files:
    [self setFileName:nil];
    return error == nil;
}

- (BOOL)loadRSSDataRepresentation:(NSData *)data error:(NSError **)outError {
    if(outError != NULL) *outError = [NSError errorWithDomain:@"BDSKUnimplementedError" code:0 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Loading RSS files is not supported at this time.", @"") forKey:NSLocalizedDescriptionKey]];
    return NO;
}

- (void)setDocumentStringEncoding:(NSStringEncoding)encoding{
    documentStringEncoding = encoding;
}

- (NSStringEncoding)documentStringEncoding{
    return documentStringEncoding;
}

- (BOOL)loadBibTeXDataRepresentation:(NSData *)data fromURL:(NSURL *)absoluteURL encoding:(NSStringEncoding)encoding error:(NSError **)outError {
    NSMutableArray *newPubs;

    [self setDocumentStringEncoding:encoding];

    NSError *error = nil;
	newPubs = [BibTeXParser itemsFromData:data error:&error frontMatter:frontMatter filePath:[absoluteURL path] document:self];
	if(outError) *outError = error;	
    [self setPublications:newPubs undoable:NO];

    return error == nil;
}

#pragma mark -
#pragma mark Publication actions

- (IBAction)newPub:(id)sender{
    if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) {
        [self createNewPubUsingCrossrefAction:sender];
    } else {
        [self createNewBlankPubAndEdit:YES];
    }
}

// this method is called for the main table; it's a wrapper for delete or remove from group
- (IBAction)removeSelectedPubs:(id)sender{
	NSArray *selectedGroups = [self selectedGroups];
	
	if([selectedGroups containsObject:allPublicationsGroup]){
		[self deleteSelectedPubs:sender];
	}else{
		BOOL canRemove = NO;
        if ([self hasStaticGroupsSelected])
            canRemove = YES;
        else if ([[[BibTypeManager sharedManager] singleValuedGroupFields] containsObject:[self currentGroupField]] == NO)
            canRemove = [self hasCategoryGroupsSelected];
		if(canRemove == NO){
			NSBeep();
			return;
		}
        // the items may not belong to the groups that you're trying to remove them from, but we'll warn as if they were
        if ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKWarnOnRemovalFromGroupKey]) {
            NSString *groupName = ([selectedGroups count] > 1 ? NSLocalizedString(@"multiple groups", @"multiple groups") : [NSString stringWithFormat:NSLocalizedString(@"group \"%@\"", @"group \"Name\""), [[selectedGroups firstObject] stringValue]]);
            BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Warning", @"Warning")
                                                 defaultButton:NSLocalizedString(@"Yes", @"OK")
                                               alternateButton:nil
                                                   otherButton:NSLocalizedString(@"No", @"Cancel")
                                     informativeTextWithFormat:NSLocalizedString(@"You are about to remove %i %@ from %@.  Do you want to proceed?", @""), [tableView numberOfSelectedRows], ([tableView numberOfSelectedRows] > 1 ? NSLocalizedString(@"items", @"") : NSLocalizedString(@"item",@"")), groupName];
            [alert setHasCheckButton:YES];
            [alert setCheckValue:NO];
            int rv = [alert runSheetModalForWindow:documentWindow
                                     modalDelegate:self 
                                    didEndSelector:@selector(disableWarningAlertDidEnd:returnCode:contextInfo:) 
                                didDismissSelector:NULL 
                                       contextInfo:BDSKWarnOnRemovalFromGroupKey];
            if (rv == NSAlertOtherReturn)
                return;
        }
		[self removePublications:[self selectedPublications] fromGroups:selectedGroups];
	}
}

- (IBAction)deleteSelectedPubs:(id)sender{
	int numSelectedPubs = [self numberOfSelectedPubs];
	
    if (numSelectedPubs == 0 ||
        [self hasSharedGroupsSelected] == YES) {
        return;
    }
	
	if ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKWarnOnDeleteKey]) {
		BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Warning", @"Warning")
											 defaultButton:NSLocalizedString(@"OK", @"OK")
										   alternateButton:nil
											   otherButton:NSLocalizedString(@"Cancel", @"Cancel")
								 informativeTextWithFormat:NSLocalizedString(@"You are about to delete %i items. Do you want to proceed?", @""), numSelectedPubs];
		[alert setHasCheckButton:YES];
		[alert setCheckValue:NO];
		int rv = [alert runSheetModalForWindow:documentWindow
								 modalDelegate:self 
								didEndSelector:@selector(disableWarningAlertDidEnd:returnCode:contextInfo:) 
							didDismissSelector:NULL 
								   contextInfo:BDSKWarnOnDeleteKey];
		if (rv == NSAlertOtherReturn)
			return;
	}

    // deletion changes the scroll position
    NSPoint scrollLocation = [[tableView enclosingScrollView] scrollPositionAsPercentage];
    unsigned lastIndex = [[tableView selectedRowIndexes] lastIndex];
	[self removePublications:[self selectedPublications]];
    [[tableView enclosingScrollView] setScrollPositionAsPercentage:scrollLocation];
    
    // should select the publication following the last deleted publication (if any)
	if(lastIndex >= [tableView numberOfRows])
        lastIndex = [tableView numberOfRows] - 1;
    if(lastIndex != -1)
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:lastIndex] byExtendingSelection:NO];
    
	NSString * pubSingularPlural;
	if (numSelectedPubs == 1) {
		pubSingularPlural = NSLocalizedString(@"publication", @"publication");
	} else {
		pubSingularPlural = NSLocalizedString(@"publications", @"publications");
	}
	
    [self setStatus:[NSString stringWithFormat:NSLocalizedString(@"Deleted %i %@",@"Deleted %i %@ [i-> number, @-> publication(s)]"),numSelectedPubs, pubSingularPlural] immediate:NO];
	
	[[self undoManager] setActionName:[NSString stringWithFormat:NSLocalizedString(@"Delete %@", @"Delete Publication(s)"),pubSingularPlural]];
}

- (void)disableWarningAlertDidEnd:(BDSKAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if ([alert checkValue] == YES) {
		NSString *showWarningKey = (NSString *)contextInfo;
		[[OFPreferenceWrapper sharedPreferenceWrapper] setBool:NO forKey:showWarningKey];
	}
}

- (IBAction)emailPubCmd:(id)sender{
    NSEnumerator *e = [[self selectedPublications] objectEnumerator];
    BibItem *pub = nil;
    
    NSFileManager *dfm = [NSFileManager defaultManager];
    NSString *pubPath = nil;
    NSMutableString *body = [NSMutableString string];
    NSMutableArray *files = [NSMutableArray array];
    
    while (pub = [e nextObject]) {
        pubPath = [pub localUrlPath];
        
        if([dfm fileExistsAtPath:pubPath])
            [files addObject:pubPath];
        
        // use the detexified version without internal fields, since TeXification introduces things that 
        // AppleScript can't deal with (OAInternetConfig may end up using AS)
        [body appendString:[pub bibTeXStringUnexpandedAndDeTeXifiedWithoutInternalFields]];
        [body appendString:@"\n\n"];
    }
    
    // ampersands are common in publication names
    [body replaceOccurrencesOfString:@"&" withString:@"\\&" options:NSLiteralSearch range:NSMakeRange(0, [body length])];
    // escape backslashes
    [body replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:NSLiteralSearch range:NSMakeRange(0, [body length])];
    // escape double quotes
    [body replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSLiteralSearch range:NSMakeRange(0, [body length])];

    // OAInternetConfig will use the default mail helper (at least it works with Mail.app and Entourage)
    OAInternetConfig *ic = [OAInternetConfig internetConfig];
    [ic launchMailTo:nil
          carbonCopy:nil
     blindCarbonCopy:nil
             subject:@"BibDesk references"
                body:body
         attachments:files];

}


- (IBAction)editPubCmd:(id)sender{
    NSString *colID = nil;

    if([tableView clickedColumn] != -1){
		colID = [[[tableView tableColumns] objectAtIndex:[tableView clickedColumn]] identifier];
    }
    if([[BibTypeManager sharedManager] isLocalURLField:colID]){
		[self openLinkedFileForField:colID];
    }else if([[BibTypeManager sharedManager] isRemoteURLField:colID]){
		[self openRemoteURLForField:colID];
    }else{
		int n = [self numberOfSelectedPubs];
        int rv = NSAlertAlternateReturn;
		if (n > 6) {
            // Do we really want a gazillion of editor windows?
			BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Edit publications", @"Edit publications (multiple open warning)")
												 defaultButton:NSLocalizedString(@"No", @"No")
											   alternateButton:NSLocalizedString(@"Yes", @"Yes")
												   otherButton:nil
									 informativeTextWithFormat:[NSString stringWithFormat:NSLocalizedString(@"BibDesk is about to open %i editor windows.  Is this really what you want?" , @"multiple editor open warning question"), n]];
			rv = [alert runSheetModalForWindow:documentWindow
								 modalDelegate:nil
								didEndSelector:NULL 
							didDismissSelector:NULL 
								   contextInfo:NULL];
		} 
        if(rv == NSAlertAlternateReturn){
            NSEnumerator *e = [[self selectedPublications] objectEnumerator];
            BibItem *pub;
            while (pub = [e nextObject]) {
                if ([pub document] == self)
                    [self editPub:pub];
            }
		}
	}
}

//@@ notifications - when adding pub notifications is fully implemented we won't need this.
- (void)editPub:(BibItem *)pub{
    BibEditor *e = nil;
	NSEnumerator *wcEnum = [[self windowControllers] objectEnumerator];
	NSWindowController *wc;
	
	while(wc = [wcEnum nextObject]){
		if([wc isKindOfClass:[BibEditor class]] && [(BibEditor*)wc currentBib] == pub){
			e = (BibEditor*)wc;
			break;
		}
	}
    if(e == nil){
        e = [[BibEditor alloc] initWithBibItem:pub document:self];
        [self addWindowController:e];
        [e release];
    }
    [e show];
}

- (void)showPerson:(BibAuthor *)person{
    OBASSERT(person != nil && [person isKindOfClass:[BibAuthor class]]);
    BibPersonController *pc = [person personController];
    
    if(pc == nil){
        pc = [[BibPersonController alloc] initWithPerson:person];
        [self addWindowController:pc];
        [pc release];
    }
    [pc show];
}

- (IBAction)selectAllPublications:(id)sender {
	[tableView selectAll:sender];
}

- (IBAction)deselectAllPublications:(id)sender {
	[tableView deselectAll:sender];
}

- (IBAction)openLinkedFile:(id)sender{
	NSString *field = [sender representedObject];
    if (field == nil)
		field = BDSKLocalUrlString;
    [self openLinkedFileForField:field];
}

- (void)openLinkedFileForField:(NSString *)field{
	int n = [self numberOfSelectedPubs];
    
    int rv = NSAlertAlternateReturn;
    if (n > 6) {
		// Do we really want a gazillion of files open?
        BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Open Linked Files", @"Open Linked Files (multiple open warning)")
                                             defaultButton:NSLocalizedString(@"No", @"No")
                                           alternateButton:NSLocalizedString(@"Open", @"multiple open warning Open button")
                                               otherButton:nil
                                 informativeTextWithFormat:[NSString stringWithFormat:NSLocalizedString(@"BibDesk is about to open %i linked files. Do you want to proceed?" , @"mulitple open linked files question"), n]];
        rv = [alert runSheetModalForWindow:documentWindow
                             modalDelegate:nil
                            didEndSelector:NULL 
                        didDismissSelector:NULL 
                               contextInfo:NULL];
	}
    if(rv == NSAlertAlternateReturn){
        NSEnumerator *e = [[self selectedPublications] objectEnumerator];
        BibItem *pub;
        NSURL *fileURL;
        
        NSString *searchString;
        // See bug #1344720; don't search if this is a known field (Title, Author, etc.).  This feature can be annoying because Preview.app zooms in on the search result in this case, in spite of your zoom settings (bug report filed with Apple).
        if([quickSearchKey isEqualToString:BDSKKeywordsString] || [quickSearchKey isEqualToString:BDSKAllFieldsString])
            searchString = [searchField stringValue];
        else
            searchString = @"";
        
        // the user said to go ahead
        while (pub = [e nextObject]) {
            fileURL = [pub URLForField:field];
            if(fileURL == nil) continue;
            if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3){
                [[NSWorkspace sharedWorkspace] openURL:fileURL];
            } else {
                [[NSWorkspace sharedWorkspace] openURL:fileURL withSearchString:searchString];
            }
        }
	}
}

- (IBAction)revealLinkedFile:(id)sender{
	NSString *field = [sender representedObject];
    if (field == nil)
		field = BDSKLocalUrlString;
    [self revealLinkedFileForField:field];
}

- (void)revealLinkedFileForField:(NSString *)field{
	int n = [self numberOfSelectedPubs];
    
    int rv = NSAlertAlternateReturn;
    if (n > 6) {
		// Do we really want a gazillion of Finder windows?
        BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Reveal Linked Files", @"Reveal Linked Files (multiple reveal warning)")
                                             defaultButton:NSLocalizedString(@"No", @"No")
                                           alternateButton:NSLocalizedString(@"Reveal", @"multiple reveal warning Reveal button")
                                               otherButton:nil
                                 informativeTextWithFormat:[NSString stringWithFormat:NSLocalizedString(@"BibDesk is about to reveal %i linked files. Do you want to proceed?" , @"mulitple reveal linked files question"), n]];
        rv = [alert runSheetModalForWindow:documentWindow
                             modalDelegate:nil
                            didEndSelector:NULL 
                        didDismissSelector:NULL 
                               contextInfo:NULL];
	}
    if(rv == NSAlertAlternateReturn){
        NSEnumerator *e = [[self selectedPublications] objectEnumerator];
        BibItem *pub;
        
        while (pub = [e nextObject]) {
            [[NSWorkspace sharedWorkspace]  selectFile:[pub localFilePathForField:field] inFileViewerRootedAtPath:nil];
        }
	}
}

- (IBAction)openRemoteURL:(id)sender{
	NSString *field = [sender representedObject];
    if (field == nil)
		field = BDSKUrlString;
    [self openRemoteURLForField:field];
}

- (void)openRemoteURLForField:(NSString *)field{
	int n = [self numberOfSelectedPubs];
    
    int rv = NSAlertAlternateReturn;
    if (n > 6) {
		// Do we really want a gazillion of browser windows?
        BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Open Remote URL", @"Open Remote URL (multiple open warning)")
                                             defaultButton:NSLocalizedString(@"No", @"No")
                                           alternateButton:NSLocalizedString(@"Open", @"multiple open warning Open button")
                                               otherButton:nil
                                 informativeTextWithFormat:[NSString stringWithFormat:NSLocalizedString(@"BibDesk is about to open %i URLs. Do you want to proceed?" , @"mulitple open URLs question"), n]];
        rv = [alert runSheetModalForWindow:documentWindow
                             modalDelegate:nil
                            didEndSelector:NULL 
                        didDismissSelector:NULL 
                               contextInfo:NULL];
	}
    if(rv == NSAlertAlternateReturn){
        NSEnumerator *e = [[self selectedPublications] objectEnumerator];
        BibItem *pub;
        
		while (pub = [e nextObject]) {
			[[NSWorkspace sharedWorkspace] openURL:[pub remoteURLForField:field]];
		}
	}
}

- (void)editAction:(id)sender {
	id firstResponder = [documentWindow firstResponder];
	if (firstResponder == tableView) {
		[self editPubCmd:sender];
	} else if (firstResponder == groupTableView) {
		[self editGroupAction:sender];
	}
}

- (IBAction)alternateDelete:(id)sender {
	id firstResponder = [documentWindow firstResponder];
	if (firstResponder == tableView) {
		[self deleteSelectedPubs:sender];
	} else if (firstResponder == groupTableView) {
		[self removeSelectedGroups:sender];
	}
}

// -delete: and -insertNewline: are defined indirectly in NSTableView-OAExtensions using our dataSource method

#pragma mark Pasteboard || copy

// -cut: and copy: are defined indirectly in NSTableView-OAExtensions using our dataSource method
// note: cut: calls delete:

- (IBAction)alternateCut:(id)sender {
	if ([documentWindow firstResponder] == tableView) {
		[tableView copy:sender];
		[self alternateDelete:sender];
	}
}

- (IBAction)copyAsAction:(id)sender{
	int copyType = [sender tag];
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
	NSString *citeString = [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKCiteStringKey];
	[self writePublications:[self selectedPublications] forDragCopyType:copyType citeString:citeString toPasteboard:pboard];
}

- (NSString *)citeStringForPublications:(NSArray *)items citeString:(NSString *)citeString{
	OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
	BOOL prependTilde = [sud boolForKey:BDSKCitePrependTildeKey];
	NSString *startCite = [NSString stringWithFormat:@"%@\\%@%@", (prependTilde? @"~" : @""), citeString, [sud stringForKey:BDSKCiteStartBracketKey]]; 
	NSString *endCite = [sud stringForKey:BDSKCiteEndBracketKey]; 
    NSMutableString *s = [NSMutableString stringWithString:startCite];
	
    BOOL sep = [sud boolForKey:BDSKSeparateCiteKey];
	NSString *separator = (sep)? [NSString stringWithFormat:@"%@%@", endCite, startCite] : @",";
    BibItem *pub;
	BOOL first = YES;
    
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);
    
    NSEnumerator *e = [items objectEnumerator];
    while(pub = [e nextObject]){
		if(first) first = NO;
		else [s appendString:separator];
        [s appendString:[pub citeKey]];
    }
	[s appendString:endCite];
	
	return s;
}

- (NSString *)bibTeXStringForPublications:(NSArray *)items{
	return [self bibTeXStringDroppingInternal:NO forPublications:items];
}

- (NSString *)bibTeXStringDroppingInternal:(BOOL)drop forPublications:(NSArray *)items{
    NSMutableString *s = [NSMutableString string];
	NSEnumerator *e = [items objectEnumerator];
	BibItem *pub;
	
    while(pub = [e nextObject]){
		NS_DURING
			[s appendString:@"\n"];
			[s appendString:[pub bibTeXStringDroppingInternal:drop]];
			[s appendString:@"\n"];
		NS_HANDLER
			if([[localException name] isEqualToString:BDSKTeXifyException])
				NSLog(@"Discarding exception raised for item \"%@\"", [pub citeKey]);
			else
				[localException raise];
		NS_ENDHANDLER
    }
	
	return s;
}

- (NSString *)previewBibTeXStringForPublications:(NSArray *)items{
    
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);

	unsigned numberOfPubs = [items count];
	
	NSMutableString *bibString = [[NSMutableString alloc] initWithCapacity:(numberOfPubs * 100)];

	// in case there are @preambles in it
	[bibString appendString:frontMatter];
	[bibString appendString:@"\n"];
	
    @try{
        [bibString appendString:[[self macroResolver] bibTeXString]];
    }
    @catch(id exception){
        if([exception isKindOfClass:[NSException class]] && [[exception name] isEqualToString:BDSKTeXifyException])
            NSLog(@"Discarding exception %@", [exception reason]);
        else
            @throw;
    }
	
	NSEnumerator *e = [items objectEnumerator];
	BibItem *aPub = nil;
	BibItem *aParent = nil;
	NSMutableArray *selItems = [[NSMutableArray alloc] initWithCapacity:numberOfPubs];
	NSMutableSet *parentItems = [[NSMutableSet alloc] initWithCapacity:numberOfPubs];
	NSMutableArray *selParentItems = [[NSMutableArray alloc] initWithCapacity:numberOfPubs];
    	
	while(aPub = [e nextObject]){
		[selItems addObject:aPub];

		if(aParent = [aPub crossrefParent])
			[parentItems addObject:aParent];
	}
	
	e = [selItems objectEnumerator];
	while(aPub = [e nextObject]){
		if([parentItems containsObject:aPub]){
			[parentItems removeObject:aPub];
			[selParentItems addObject:aPub];
		}else{
			NS_DURING
				[bibString appendString:[aPub bibTeXStringDroppingInternal:NO]];
			NS_HANDLER
				if([[localException name] isEqualToString:BDSKTeXifyException])
					NSLog(@"Discarding exception raised for item \"%@\"", [aPub citeKey]);
				else
					[localException raise];
			NS_ENDHANDLER
		}
	}
	
	e = [selParentItems objectEnumerator];
	while(aPub = [e nextObject]){
		NS_DURING
			[bibString appendString:[aPub bibTeXStringDroppingInternal:NO]];
		NS_HANDLER
			if([[localException name] isEqualToString:BDSKTeXifyException])
				NSLog(@"Discarding exception raised for item \"%@\"", [aPub citeKey]);
			else
				[localException raise];
		NS_ENDHANDLER
	}
	
	e = [parentItems objectEnumerator];        
	while(aPub = [e nextObject]){
		NS_DURING
			[bibString appendString:[aPub bibTeXStringDroppingInternal:NO]];
		NS_HANDLER
			if([[localException name] isEqualToString:BDSKTeXifyException])
				NSLog(@"Discarding exception raised for item \"%@\"", [aPub citeKey]);
			else
				[localException raise];
		NS_ENDHANDLER
	}
					
	[selItems release];
	[parentItems release];
	[selParentItems release];
	
	return [bibString autorelease];
}

- (NSString *)RISStringForPublications:(NSArray *)items{
    NSMutableString *s = [NSMutableString string];
	NSEnumerator *e = [items objectEnumerator];
	BibItem *pub;
	
    while(pub = [e nextObject]){
		[s appendString:@"\n"];
		[s appendString:[pub RISStringValue]];
		[s appendString:@"\n"];
    }
	
	return s;
}

#pragma mark Pasteboard || paste

// ----------------------------------------------------------------------------------------
// paste: get text, parse it as bibtex, add the entry to publications and (optionally) edit it.
// ----------------------------------------------------------------------------------------

// -paste: is defined indirectly in NSTableView-OAExtensions using our dataSource method

// Don't use the default action in NSTableView-OAExtensions here, as it uses another pasteboard and some more overhead
- (IBAction)duplicate:(id)sender{
	if ([documentWindow firstResponder] != tableView ||
		[self numberOfSelectedPubs] == 0 ||
        [self hasSharedGroupsSelected] == YES) {
		NSBeep();
		return;
	}
	
    NSArray *newPubs = [[NSArray alloc] initWithArray:[self selectedPublications] copyItems:YES];
    
    [self addPublications:newPubs]; // notification will take care of clearing the search/sorting
    [self highlightBibs:newPubs];
    [newPubs release];
	
    if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKEditOnPasteKey]) {
        [self editPubCmd:nil]; // this will aske the user when there are many pubs
    }
}

- (void)createNewBlankPub{
    [self createNewBlankPubAndEdit:NO];
}

- (void)createNewBlankPubAndEdit:(BOOL)yn{
    BibItem *newBI = [[[BibItem alloc] init] autorelease];
    
	NSEnumerator *groupEnum = [[self selectedGroups] objectEnumerator];
	BDSKGroup *group;
	while (group = [groupEnum nextObject]) {
		if ([group isCategory])
			[newBI addToGroup:group handleInherited:BDSKOperationSet];
    }
	
    [self addPublication:newBI];
	[[self undoManager] setActionName:NSLocalizedString(@"Add Publication",@"")];
    [self highlightBib:newBI];
    if(yn == YES)
    {
        [self editPub:newBI];
    }
}

- (BOOL)addPublicationsFromPasteboard:(NSPasteboard *)pb error:(NSError **)outError{
	// these are the types we support, the order here is important!
    NSString *type = [pb availableTypeFromArray:[NSArray arrayWithObjects:BDSKBibItemPboardType, BDSKWeblocFilePboardType, BDSKReferenceMinerStringPboardType, NSStringPboardType, NSFilenamesPboardType, NSURLPboardType, nil]];
    NSArray *newPubs = nil;
    NSArray *newFilePubs = nil;
	NSError *error = nil;
    
    if([type isEqualToString:BDSKBibItemPboardType]){
        NSData *pbData = [pb dataForType:BDSKBibItemPboardType];
		newPubs = [self newPublicationsFromArchivedData:pbData];
    } else if([type isEqualToString:BDSKReferenceMinerStringPboardType]){ // pasteboard type from Reference Miner, determined using Pasteboard Peeker
        NSString *pbString = [pb stringForType:BDSKReferenceMinerStringPboardType]; 	
        // sniffing the string for RIS is broken because RefMiner puts junk at the beginning
		newPubs = [self newPublicationsForString:pbString type:1 error:&error];
    }else if([type isEqualToString:NSStringPboardType]){
        NSString *pbString = [pb stringForType:NSStringPboardType]; 	
		// sniff the string to see what its type is
		newPubs = [self newPublicationsForString:pbString type:[pbString contentStringType] error:&error];
    }else if([type isEqualToString:NSFilenamesPboardType]){
		NSArray *pbArray = [pb propertyListForType:NSFilenamesPboardType]; // we will get an array
        // try this first, in case these files are a type we can open
        NSMutableArray *unparseableFiles = [[NSMutableArray alloc] initWithCapacity:[pbArray count]];
        newPubs = [self extractPublicationsFromFiles:pbArray unparseableFiles:unparseableFiles];
		if ([unparseableFiles count] > 0) {
            newFilePubs = [self newPublicationsForFiles:unparseableFiles error:&error];
            newPubs = [newPubs arrayByAddingObjectsFromArray:newFilePubs];
        }
        [unparseableFiles release];
    }else if([type isEqualToString:BDSKWeblocFilePboardType]){
        NSURL *pbURL = [NSURL URLWithString:[pb stringForType:BDSKWeblocFilePboardType]]; 	
		if([pbURL isFileURL])
            newPubs = newFilePubs = [self newPublicationsForFiles:[NSArray arrayWithObject:[pbURL path]] error:&error];
        else
            newPubs = [self newPublicationForURL:pbURL error:&error];
    }else if([type isEqualToString:NSURLPboardType]){
        NSURL *pbURL = [NSURL URLFromPasteboard:pb]; 	
		if([pbURL isFileURL])
            newPubs = newFilePubs = [self newPublicationsForFiles:[NSArray arrayWithObject:[pbURL path]] error:&error];
        else
            newPubs = [self newPublicationForURL:pbURL error:&error];
	}else{
        // errors are key, value
        OFError(&error, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"Did not find anything appropriate on the pasteboard", @"BibDesk couldn't find any files or bibliography information in the data it received."), nil);
	}
	
	if (newPubs == nil || error != nil){
        if(outError) *outError = error;
		return NO;
    }
    
	if ([newPubs count] == 0) 
		return YES; // nothing to do
	
    [groupTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];    
	[self addPublications:newPubs];
	[self highlightBibs:newPubs];
	if (newFilePubs != nil)
		[newFilePubs makeObjectsPerformSelector:@selector(autoFilePaper)];
    
    // set Date-Added to the current date, since unarchived items will have their own (incorrect) date
    NSCalendarDate *importDate = [NSCalendarDate date];
    [newPubs makeObjectsPerformSelector:@selector(setField:toValue:) withObject:BDSKDateAddedString withObject:[importDate description]];
	
	if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKEditOnPasteKey]) {
		[self editPubCmd:nil]; // this will ask the user when there are many pubs
	}
	
	[[self undoManager] setActionName:NSLocalizedString(@"Add Publication",@"")];
    
    // set up the smart group that shows the latest import
    // @@ do this for items added via the editor?  doesn't seem as useful
    if(lastImportGroup == nil)
        lastImportGroup = [[BDSKStaticGroup alloc] initWithLastImport:newPubs];
    else 
        [lastImportGroup setPublications:newPubs];
    
    return YES;
}

- (NSArray *)newPublicationsFromArchivedData:(NSData *)data{
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    // we set the delegate so we can pass it the macroresolver for any complex string it might decode
    [unarchiver setDelegate:self];
    
    NSArray *newPubs = [unarchiver decodeObjectForKey:@"publications"];
    [unarchiver finishDecoding];
    [unarchiver release];
    
    return newPubs;
}

- (BDSKMacroResolver *)unarchiverMacroResolver:(NSKeyedUnarchiver *)unarchiver{
    return macroResolver;
}

- (NSArray *)newPublicationsForString:(NSString *)string type:(int)type error:(NSError **)outError {
    NSArray *newPubs = nil;
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSError *parseError = nil;
    
    switch(type){
		case BDSKBibTeXStringType:
			newPubs = [BibTeXParser itemsFromData:data error:&parseError document:self];
			break;
		case BDSKRISStringType:
			newPubs = [PubMedParser itemsFromString:string error:&parseError];
			break;
		case BDSKJSTORStringType:
			newPubs = [BDSKJSTORParser itemsFromString:string error:&parseError];
            break;
        case BDSKWOSStringType:
            newPubs = [BDSKWebOfScienceParser itemsFromString:string error:&parseError];
            break;
        case BDSKUnknownStringType:
            break;
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Type %d is not supported", type];
    }

    // The parser methods may return a non-empty array (partial data) if they failed; we check for parseError != nil as an error condition, then, although that's generally not correct
	if(parseError != nil) {

		// run a modal dialog asking if we want to use partial data or give up
		int rv = 0;
		rv = NSRunAlertPanel(NSLocalizedString(@"Error reading file!",@""),
							 NSLocalizedString(@"There was a problem inserting the data. Do you want to keep going and use everything that BibDesk could analyse or open a window containing the data to edit it and remove the errors?\n(It's likely that choosing \"Keep Going\" will lose some data.)",@""),
							 NSLocalizedString(@"Cancel",@""),
							 NSLocalizedString(@"Keep going",@""),
							 NSLocalizedString(@"Edit data", @""));
		if (rv == NSAlertDefaultReturn) {
			// the user said to give up
			newPubs = nil;
		}else if (rv == NSAlertAlternateReturn){
			// the user said to keep going, so if they save, they might clobber data...
		}else if(rv == NSAlertOtherReturn){
			// they said to edit the file.
			NSString * tempFileName = [[NSApp delegate] temporaryFilePath:[[self fileName] lastPathComponent] createDirectory:NO];
			[data writeToFile:tempFileName atomically:YES];
			[[BDSKErrorObjectController sharedErrorObjectController] openEditWindowWithFile:tempFileName forDocument:self];
			[[BDSKErrorObjectController sharedErrorObjectController] showErrorPanel:self];		
			newPubs = nil;	
		}		
	}

    // we reach this for unsupported data types (BDSKUnknownStringType)
	if ([newPubs count] == 0 && parseError == nil)
        OFError(&parseError, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"BibDesk couldn't find bibliography data in this text.", @"Error message when pasting unknown text in."), nil);

	if(outError) *outError = parseError;
    return newPubs;
}

// sniff the contents of each file, returning them in an array of BibItems, while unparseable files are added to the mutable array passed as a parameter
- (NSArray *)extractPublicationsFromFiles:(NSArray *)filenames unparseableFiles:(NSMutableArray *)unparseableFiles {
    
    NSParameterAssert(unparseableFiles != nil);
    NSParameterAssert([unparseableFiles count] == 0);
    
    NSEnumerator *e = [filenames objectEnumerator];
    NSString *fileName;
    NSData *contentData;
    NSString *contentString;
    NSMutableArray *array = [NSMutableArray array];
    int type = -1;
    
    // some common types that people might use as attachments; we don't need to sniff these
    NSSet *unreadableTypes = [NSSet caseInsensitiveStringSetWithObjects:@"pdf", @"ps", @"eps", @"doc", @"htm", @"textClipping", @"webloc", @"html", @"rtf", @"tiff", @"tif", @"png", @"jpg", @"jpeg", nil];
    
    while(fileName = [e nextObject]){
        type = -1;
        
        // we /can/ create a string from these (usually), but there's no point in wasting the memory
        if([unreadableTypes containsObject:[fileName pathExtension]]){
            [unparseableFiles addObject:fileName];
            continue;
        }
        
        contentData = [[NSData alloc] initWithContentsOfFile:fileName];
        // @@ this is probably a reasonable choice for the encoding, but we could try the same heuristic as used in the MDImporter
        contentString = [[NSString alloc] initWithData:contentData encoding:[self documentStringEncoding]];
        // try our fallback encoding, Latin 1
        if(contentString == nil){
            NSLog(@"unable to interpret file %@ using encoding %@; trying %@", [fileName lastPathComponent], [NSString localizedNameOfStringEncoding:[self documentStringEncoding]], [NSString localizedNameOfStringEncoding:NSISOLatin1StringEncoding]);
            contentString = [[NSString alloc] initWithData:contentData encoding:NSISOLatin1StringEncoding];
        }
        [contentData release];
        
        if(contentString != nil){
            type = [contentString contentStringType];
    
            if(type >= 0)
                [array addObjectsFromArray:[self newPublicationsForString:contentString type:type error:NULL]];
            else {
                [contentString release];
                contentString = nil;
            }
        }
        if(contentString == nil || type == -1)
            [unparseableFiles addObject:fileName];
    }

    return array;
}

- (NSArray *)newPublicationsForFiles:(NSArray *)filenames error:(NSError **)error {
    NSMutableArray *newPubs = [NSMutableArray arrayWithCapacity:[filenames count]];
	NSEnumerator *e = [filenames objectEnumerator];
	NSString *fnStr = nil;
	NSURL *url = nil;
	BibItem *newBI = nil;
    	
	while(fnStr = [e nextObject]){
        fnStr = [fnStr stringByStandardizingPath];
		if(url = [NSURL fileURLWithPath:fnStr]){
            NSError *xerror = nil;
			NSData *btData = nil;
            
            if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKReadExtendedAttributesKey] && (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3))
                btData = [[NSFileManager defaultManager] extendedAttributeNamed:OMNI_BUNDLE_IDENTIFIER @".bibtexstring" atPath:fnStr traverseLink:NO error:&xerror];

            if(btData == nil && [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShouldUsePDFMetadata])
                newBI = [BibItem itemWithPDFMetadata:[PDFMetadata metadataForURL:url error:&xerror]];
            
            if(newBI == nil && (btData == nil || (newBI = [[BibTeXParser itemsFromData:btData error:&xerror document:self] firstObject]) == nil))
                newBI = [[[BibItem alloc] init] autorelease];
            
            [newBI setField:BDSKLocalUrlString toValue:[url absoluteString]];
			[newPubs addObject:newBI];
            
            newBI = nil;
		}
	}
	
	return newPubs;
}

- (NSArray *)newPublicationForURL:(NSURL *)url error:(NSError **)error {
    if(url == nil){
        OFError(error, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"Did not find expected URL on the pasteboard", @"BibDesk couldn't find any URL in the data it received."), nil);
        return nil;
    }
    
	BibItem *newBI = [[[BibItem alloc] init] autorelease];
    
    [newBI setField:BDSKUrlString toValue:[url absoluteString]];
    
	return [NSArray arrayWithObject:newBI];
}

#pragma mark Lazy Pasteboard

- (void)setPromisedItems:(NSArray *)items types:(NSArray *)types dragCopyType:(int)dragCopyType forPasteboard:(NSPasteboard *)pboard {
	NSString *dict = [NSDictionary dictionaryWithObjectsAndKeys:items, @"items", [[types mutableCopy] autorelease], @"types", [NSNumber numberWithInt:dragCopyType], @"dragCopyType", nil];
	[promisedPboardTypes setObject:dict forKey:[pboard name]];
}

- (NSArray *)promisedTypesForPasteboard:(NSPasteboard *)pboard {
	return [[promisedPboardTypes objectForKey:[pboard name]] objectForKey:@"types"];
}

- (NSArray *)promisedItemsForPasteboard:(NSPasteboard *)pboard {
	return [[promisedPboardTypes objectForKey:[pboard name]] objectForKey:@"items"];
}

- (int)promisedDragCopyTypeForPasteboard:(NSPasteboard *)pboard {
	return [[[promisedPboardTypes objectForKey:[pboard name]] objectForKey:@"dragCopyType"] intValue];
}

- (void)removePromisedType:(NSString *)type forPasteboard:(NSPasteboard *)pboard {
	NSMutableArray *types = [[promisedPboardTypes objectForKey:[pboard name]] objectForKey:@"types"];
	[types removeObject:type];
	if([types count] == 0)
		[self clearPromisedTypesForPasteboard:pboard];
}

- (void)clearPromisedTypesForPasteboard:(NSPasteboard *)pboard {
	[promisedPboardTypes removeObjectForKey:[pboard name]];
}

- (void)providePromisedTypesForPasteboard:(NSPasteboard *)pboard {
	NSArray *types = [[self promisedTypesForPasteboard:pboard] copy]; // we need to copy as types can be removed
	NSEnumerator *typeEnum = nil;
	NSString *type;
	
	if (types == nil) return;
	typeEnum = [types objectEnumerator];
	[types release];
	
	while (type = [typeEnum nextObject]) 
		[self pasteboard:pboard provideDataForType:type];
}

- (void)providePromisedTypes {
	NSEnumerator *nameEnum = [[promisedPboardTypes allKeys] objectEnumerator];
	NSString *name;
	
	while (name = [nameEnum nextObject]) {
		NSPasteboard *pboard = [NSPasteboard pasteboardWithName:name];
		NSArray *types = [[self promisedTypesForPasteboard:pboard] copy]; // we need to copy as types can be removed
		NSEnumerator *typeEnum = nil;
		NSString *type;
		
		if (types == nil) return;
		typeEnum = [types objectEnumerator];
		[types release];
		
		while (type = [typeEnum nextObject]) 
			[self pasteboard:pboard provideDataForType:type];
	}
}

// NSPasteboard delegate method for the owner
- (void)pasteboardChangedOwner:(NSPasteboard *)pboard {
	[self clearPromisedTypesForPasteboard:pboard];
}

#pragma mark -
#pragma mark Sorting

- (void) tableView: (NSTableView *) theTableView didClickTableColumn: (NSTableColumn *) tableColumn{
	// check whether this is the right kind of table view and don't re-sort when we have a contextual menu click
    if ([[NSApp currentEvent] type] == NSRightMouseDown) 
        return;
    if (tableView == theTableView){
        [self sortPubsByColumn:tableColumn];
	}else if (groupTableView == theTableView){
        [self sortGroupsByKey:nil];
	}

}

- (NSSortDescriptor *)sortDescriptorForTableColumnIdentifier:(NSString *)tcID ascending:(BOOL)ascend{

    NSParameterAssert([NSString isEmptyString:tcID] == NO);
    
    NSSortDescriptor *sortDescriptor = nil;
    
	if([tcID isEqualToString:BDSKCiteKeyString]){
		sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"citeKey" ascending:ascend selector:@selector(localizedCaseInsensitiveNumericCompare:)];
        
	}else if([tcID isEqualToString:BDSKTitleString]){
		
		sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"stringCache.title" ascending:ascend selector:@selector(localizedCompare:)];
		
	}else if([tcID isEqualToString:BDSKContainerString]){
		
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"container" ascending:ascend selector:@selector(localizedCompare:)];
        
	}else if([tcID isEqualToString:BDSKDateString]){
		
		sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"date" ascending:ascend selector:@selector(compare:)];		
        
	}else if([tcID isEqualToString:BDSKDateAddedString] ||
			 [tcID isEqualToString:@"Added"] ||
			 [tcID isEqualToString:@"Created"]){
		
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"dateAdded" ascending:ascend selector:@selector(compare:)];
        
	}else if([tcID isEqualToString:BDSKDateModifiedString] ||
			 [tcID isEqualToString:@"Modified"]){
		
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"dateModified" ascending:ascend selector:@selector(compare:)];
        
	}else if([tcID isEqualToString:BDSKFirstAuthorString] ||
             [tcID isEqualToString:BDSKAuthorString] || [tcID isEqualToString:@"Authors"]){
        
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"firstAuthor" ascending:ascend selector:@selector(sortCompare:)];
        
	}else if([tcID isEqualToString:BDSKSecondAuthorString]){
		
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"secondAuthor" ascending:ascend selector:@selector(sortCompare:)];
		
	}else if([tcID isEqualToString:BDSKThirdAuthorString]){
		
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"thirdAuthor" ascending:ascend selector:@selector(sortCompare:)];
        
	}else if([tcID isEqualToString:BDSKFirstAuthorEditorString] ||
             [tcID isEqualToString:BDSKAuthorEditorString]){
        
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"firstAuthorOrEditor" ascending:ascend selector:@selector(sortCompare:)];
        
	}else if([tcID isEqualToString:BDSKSecondAuthorEditorString]){
		
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"secondAuthorOrEditor" ascending:ascend selector:@selector(sortCompare:)];
		
	}else if([tcID isEqualToString:BDSKThirdAuthorEditorString]){
		
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"thirdAuthorOrEditor" ascending:ascend selector:@selector(sortCompare:)];
        
	}else if([tcID isEqualToString:BDSKTypeString]){
        
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"type" ascending:ascend selector:@selector(localizedCaseInsensitiveCompare:)];
        
    }else if([tcID isEqualToString:BDSKItemNumberString]){
        
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"fileOrder" ascending:ascend selector:@selector(compare:)];		
        
    }else if([tcID isEqualToString:BDSKBooktitleString]){
        
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"stringCache.Booktitle" ascending:ascend selector:@selector(localizedCompare:)];
        
    }else if([[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKBooleanFieldsKey] containsObject:tcID] ||
             [[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKTriStateFieldsKey] containsObject:tcID] ||
             [[BibTypeManager sharedManager] isURLField:tcID]){
        
        // use the triStateCompare: for URL fields so the subsort is more useful (this turns the URL comparison into empty/non-empty)
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:tcID ascending:ascend selector:@selector(triStateCompare:)];
        
    }else if([[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKRatingFieldsKey] containsObject:tcID]){
        
        // Use NSSortDescriptor instead of the BDSKTableSortDescriptor, so 0 values are handled correctly; if we ever store these as NSNumbers, the selector must be changed to compare:.
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:tcID ascending:ascend selector:@selector(numericCompare:)];
        
    }else{
        // this assumes that all other columns must be NSString objects
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:tcID ascending:ascend selector:@selector(localizedCaseInsensitiveNumericCompare:)];
	}
 
    OBASSERT(sortDescriptor);
    return [sortDescriptor autorelease];
}

- (void)sortPubsByColumn:(NSTableColumn *)tableColumn{
    
    // use this for a subsort
    NSString *lastSortedTableColumnIdentifier = [lastSelectedColumnForSort identifier];
        
    // cache the selection; this works for multiple publications
    NSArray *pubsToSelect = nil;
    if([tableView numberOfSelectedRows])
        pubsToSelect = [self selectedPublications];
    
    // a nil argument means resort the current column in the same order
    if(tableColumn == nil){
        if(lastSelectedColumnForSort == nil)
            return;
        tableColumn = lastSelectedColumnForSort; // use the previous one
        sortDescending = !sortDescending; // we'll reverse this again in the next step
    }
    
    if (lastSelectedColumnForSort == tableColumn) {
        // User clicked same column, change sort order
        sortDescending = !sortDescending;
    } else {
        // User clicked new column, change old/new column headers,
        // save new sorting selector, and re-sort the array.
        sortDescending = NO;
        if (lastSelectedColumnForSort) {
            [tableView setIndicatorImage: nil
                           inTableColumn: lastSelectedColumnForSort];
            [lastSelectedColumnForSort release];
        }
        lastSelectedColumnForSort = [tableColumn retain];
        [tableView setHighlightedTableColumn: tableColumn]; 
	}
    
    // should never be nil at this point
    OBPRECONDITION(lastSortedTableColumnIdentifier);
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:[self sortDescriptorForTableColumnIdentifier:[tableColumn identifier] ascending:!sortDescending], [self sortDescriptorForTableColumnIdentifier:lastSortedTableColumnIdentifier ascending:!sortDescending], nil];
    [tableView setSortDescriptors:sortDescriptors]; // just using this to store them; it's really a no-op
    

    // @@ DON'T RETURN WITHOUT RESETTING THIS!
    // this is a hack to keep us from getting selection change notifications while sorting (which updates the TeX and attributed text previews)
    [tableView setDelegate:nil];
    
    // sort by new primary column, subsort with previous primary column
    [shownPublications sortUsingDescriptors:sortDescriptors];

    // Set the graphic for the new column header
    [tableView setIndicatorImage: (sortDescending ?
                                   [NSImage imageNamed:@"NSDescendingSortIndicator"] :
                                   [NSImage imageNamed:@"NSAscendingSortIndicator"])
                   inTableColumn: tableColumn];

    // have to reload so the rows get set up right, but a full updateUI flashes the preview, which is annoying (and the preview won't change if we're maintaining the selection)
    [tableView reloadData];

    // fix the selection
    [self highlightBibs:pubsToSelect];
    [tableView scrollRowToVisible:[tableView selectedRow]]; // just go to the last one

    // reset ourself as delegate
    [tableView setDelegate:self];
}

- (void)sortPubsByDefaultColumn{
    OFPreferenceWrapper *defaults = [OFPreferenceWrapper sharedPreferenceWrapper];
    
    NSString *colName = [defaults objectForKey:BDSKDefaultSortedTableColumnKey];
    if([NSString isEmptyString:colName])
        return;
    
    NSTableColumn *tc = [tableView tableColumnWithIdentifier:colName];
    if(tc == nil)
        return;
    
    lastSelectedColumnForSort = [tc retain];
    sortDescending = [defaults boolForKey:BDSKDefaultSortedTableColumnIsDescendingKey];
    [self sortPubsByColumn:nil];
    [tableView setHighlightedTableColumn:tc];
}

#pragma mark -
#pragma mark Table Column Setup

- (NSImage *)headerImageForField:(NSString *)field {
	static NSMutableDictionary *headerImageCache = nil;
	
	if (headerImageCache == nil) {
		NSDictionary *paths = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKTableHeaderImagesKey];
		headerImageCache = [[NSMutableDictionary alloc] initWithCapacity:1];
		if (paths) {
			NSEnumerator *keyEnum = [paths keyEnumerator];
			NSString *key, *path;
			NSImage *image;
			
			while (key = [keyEnum nextObject]) {
				path = [paths objectForKey:key];
				if ([[NSFileManager defaultManager] fileExistsAtPath:path] &&
					(image = [[NSImage alloc] initWithContentsOfFile:path])) {
					[headerImageCache setObject:image forKey:key];
					[image release];
				}
			}
		}
		if ([headerImageCache objectForKey:BDSKLocalUrlString] == nil)
			[headerImageCache setObject:[NSImage imageNamed:@"TinyFile"] forKey:BDSKLocalUrlString];
	}
	
	return [headerImageCache objectForKey:field];
}

- (NSString *)headerTitleForField:(NSString *)field {
	static NSMutableDictionary *headerTitleCache = nil;
	
	if (headerTitleCache == nil) {
		NSDictionary *titles = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKTableHeaderTitlesKey];
		headerTitleCache = [[NSMutableDictionary alloc] initWithCapacity:1];
		if (titles) {
			NSEnumerator *keyEnum = [titles keyEnumerator];
			NSString *key, *title;
			
			while (key = [keyEnum nextObject]) {
				title = [titles objectForKey:key];
				[headerTitleCache setObject:title forKey:key];
			}
		}
		if ([headerTitleCache objectForKey:BDSKUrlString] == nil)
			[headerTitleCache setObject:@"@" forKey:BDSKUrlString];
	}
	
	return [headerTitleCache objectForKey:field];
}

//note - ********** the notification handling method will add NSTableColumn instances to the tableColumns dictionary.
- (void)setupTableColumns{
	NSArray *prefsShownColNamesArray = [[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKShownColsNamesKey];
    NSEnumerator *shownColNamesE = [prefsShownColNamesArray objectEnumerator];
    NSTableColumn *tc;
    NSString *colName;
    BibTypeManager *typeManager = [BibTypeManager sharedManager];
    
    NSDictionary *tcWidthsByIdentifier = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKColumnWidthsKey];
    NSNumber *tcWidth = nil;
    NSImageCell *imageCell = [[[NSImageCell alloc] init] autorelease];
	
    NSMutableArray *columns = [NSMutableArray arrayWithCapacity:[prefsShownColNamesArray count]];
	
	while(colName = [shownColNamesE nextObject]){
		tc = [tableView tableColumnWithIdentifier:colName];
		
		if(tc == nil){
			NSImage *image;
			NSString *title;
			
			// it is a new column, so create it
			tc = [[[NSTableColumn alloc] initWithIdentifier:colName] autorelease];
            if([tc respondsToSelector:@selector(setResizingMask:)])
                [tc setResizingMask:(NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask)];
            else
                [tc setResizable:YES];
			[tc setEditable:NO];
			[[tc dataCell] setDrawsBackground:NO]; // this is necessary for the alternating row background before Tiger
            if([typeManager isURLField:colName]){
                [tc setDataCell:imageCell];
            }else if([typeManager isRatingField:colName]){
				BDSKRatingButtonCell *ratingCell = [[[BDSKRatingButtonCell alloc] initWithMaxRating:5] autorelease];
				[ratingCell setBordered:NO];
				[ratingCell setAlignment:NSCenterTextAlignment];
                [tc setDataCell:ratingCell];
            }else if([typeManager isBooleanField:colName]){
				NSButtonCell *switchButtonCell = [[[NSButtonCell alloc] initTextCell:@""] autorelease];
				[switchButtonCell setButtonType:NSSwitchButton];
				[switchButtonCell setImagePosition:NSImageOnly];
				[switchButtonCell setControlSize:NSSmallControlSize];
                [switchButtonCell setAllowsMixedState:NO];
                [tc setDataCell:switchButtonCell];
			}else if([typeManager isTriStateField:colName]){
				NSButtonCell *switchButtonCell = [[[NSButtonCell alloc] initTextCell:@""] autorelease];
				[switchButtonCell setButtonType:NSSwitchButton];
				[switchButtonCell setImagePosition:NSImageOnly];
				[switchButtonCell setControlSize:NSSmallControlSize];
                [switchButtonCell setAllowsMixedState:YES];
                [tc setDataCell:switchButtonCell];
			}
			if(image = [self headerImageForField:colName]){
				[(NSCell *)[tc headerCell] setImage:image];
			}else if(title = [self headerTitleForField:colName]){
				[[tc headerCell] setStringValue:title];
			}else{	
				[[tc headerCell] setStringValue:NSLocalizedStringFromTable(colName, @"BibTeXKeys", @"")];
			}
		}
		
		[columns addObject:tc];
	}
	
    [tableView removeAllTableColumns];
    NSEnumerator *columnsE = [columns objectEnumerator];
	
    while(tc = [columnsE nextObject]){
        if(tcWidthsByIdentifier && 
		  (tcWidth = [tcWidthsByIdentifier objectForKey:[tc identifier]])){
			[tc setWidth:[tcWidth floatValue]];
        }

		[tableView addTableColumn:tc];
    }
    [tableView setHighlightedTableColumn: lastSelectedColumnForSort]; 
    [tableView tableViewFontChanged:nil];
}

- (NSMenu *)tableView:(NSTableView *)tv menuForTableHeaderColumn:(NSTableColumn *)tc{
	if(tv != tableView)
		return nil;
	// for now, just returns the same all the time.
	// Could customize menu for details of selected item.
	return [[[NSApp delegate] columnsMenuItem] submenu];
}

- (IBAction)columnsMenuSelectTableColumn:(id)sender{
    NSMutableArray *prefsShownColNamesMutableArray = [[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKShownColsNamesKey] mutableCopy];

    if ([sender state] == NSOnState) {
        [prefsShownColNamesMutableArray removeObject:[sender title]];
        [sender setState:NSOffState];
    }else{
        if(![prefsShownColNamesMutableArray containsObject:[sender title]]){
            [prefsShownColNamesMutableArray addObject:[sender title]];
        }
        [sender setState:NSOnState];
    }
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:prefsShownColNamesMutableArray
                                                      forKey:BDSKShownColsNamesKey];
    [prefsShownColNamesMutableArray release];
    [self setupTableColumns];
    [self updateUI];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKTableColumnChangedNotification
														object:self];
}

- (IBAction)columnsMenuAddTableColumn:(id)sender{
    // first we fill the popup
	BibTypeManager *typeMan = [BibTypeManager sharedManager];
    NSArray *colNames = [typeMan allFieldNamesIncluding:[NSArray arrayWithObjects:BDSKCiteKeyString, BDSKDateString, @"Added", @"Modified", BDSKFirstAuthorString, BDSKSecondAuthorString, BDSKThirdAuthorString, BDSKFirstAuthorEditorString, BDSKSecondAuthorEditorString, BDSKThirdAuthorEditorString, BDSKAuthorEditorString, BDSKItemNumberString, BDSKContainerString, nil]
                                              excluding:[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKShownColsNamesKey]];
    
    BDSKAddFieldSheetController *addFieldController = [[BDSKAddFieldSheetController alloc] initWithPrompt:NSLocalizedString(@"Name of column to add:",@"")
                                                                                              fieldsArray:colNames];
	NSString *newColumnName = [addFieldController runSheetModalForWindow:documentWindow];
    [addFieldController release];
    
    if(newColumnName == nil)
        return;
    
    NSMutableArray *prefsShownColNamesMutableArray = [[[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKShownColsNamesKey] mutableCopy] autorelease];

    // Check if an object already exists in the tableview, bail without notification if it does
    // This means we can't have a column more than once.
    if ([prefsShownColNamesMutableArray containsObject:newColumnName])
        return;

    // Store the new column in the preferences
    [prefsShownColNamesMutableArray addObject:newColumnName];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:prefsShownColNamesMutableArray
                                                      forKey:BDSKShownColsNamesKey];
    
    // Actually redraw the view now with the new column.
    [self setupTableColumns];
    [self updateUI];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKTableColumnChangedNotification
                                                        object:self];
}

/*
 Returns action/contextual menu that contains items appropriate for the current selection.
 The code may need to be revised if the menu's contents are changed.
*/
- (NSMenu *)tableView:(NSTableView *)tv contextMenuForRow:(int)row column:(int)column {
	NSMenu *myMenu = nil;
    
	if (column == -1 || row == -1) 
		return nil;
	
	if(tv == tableView){
		
		NSString *tcId = [[[tableView tableColumns] objectAtIndex:column] identifier];
		
		if([[BibTypeManager sharedManager] isLocalURLField:tcId]){
			myMenu = [fileMenu copy];
			[[myMenu itemAtIndex:0] setRepresentedObject:tcId];
			[[myMenu itemAtIndex:1] setRepresentedObject:tcId];
		}else if([[BibTypeManager sharedManager] isRemoteURLField:tcId]){
			myMenu = [URLMenu copy];
			[[myMenu itemAtIndex:0] setRepresentedObject:tcId];
		}else{
			myMenu = [actionMenu copy];
		}
		
	}else if (tv == groupTableView){
		myMenu = [groupMenu copy];
	}else{
		return nil;
	}
	
	// kick out every item we won't need:
	NSMenuItem *theItem = nil;
	int i = [myMenu numberOfItems];
	
	while (--i >= 0) {
		theItem = (NSMenuItem*)[myMenu itemAtIndex:i];
		if (![self validateMenuItem:theItem] ||
			((i == [myMenu numberOfItems] - 1 || i == 0) && [theItem isSeparatorItem])) {
			[myMenu removeItem:theItem];
		}
	}
	while([myMenu numberOfItems] > 0 && [(NSMenuItem*)[myMenu itemAtIndex:0] isSeparatorItem])	
		[myMenu removeItemAtIndex:0];
	
	if([myMenu numberOfItems] == 0)
		return nil;
	
	return [myMenu autorelease];
}

#pragma mark -
#pragma mark Notification handlers

- (void)handleTableColumnChangedNotification:(NSNotification *)notification{
    // don't pay attention to notifications I send (infinite loop might result)
    if([notification object] == self)
        return;
	
    [self setupTableColumns];
	[self updateUI];
}

- (void)handlePreviewDisplayChangedNotification:(NSNotification *)notification{
    // note: this is only supposed to handle the pretty-printed preview, /not/ the TeX preview
    [self displayPreviewForItems:[self selectedPublications]];
}

- (void)handleBibItemAddDelNotification:(NSNotification *)notification{
    // NB: this method gets called for setPublications: also, so checking for AddItemNotification might not do what you expect
	if([[notification name] isEqualToString:BDSKDocDelItemNotification] == NO)
		[self setFilterField:@""]; // clear the search when adding

    // this handles the remaining UI updates necessary (tableView and previews)
	[self updateGroupsPreservingSelection:YES];
    // update smart group counts
    [self updateAllSmartGroups];
}

- (void)handleBibItemChangedNotification:(NSNotification *)notification{

	NSDictionary *userInfo = [notification userInfo];
    
    // see if it's ours
	if([userInfo objectForKey:@"document"] != self || [userInfo objectForKey:@"document"] == nil)
        return;

	NSString *changedKey = [userInfo objectForKey:@"key"];
    
    // need to handle crossrefs if a cite key changed
    if([changedKey isEqualToString:BDSKCiteKeyString]){
        BibItem *pub = [notification object];
        NSString *oldKey = [userInfo objectForKey:@"oldCiteKey"];
        NSString *newKey = [pub citeKey];
        [itemsForCiteKeys removeObjectIdenticalTo:pub forKey:oldKey];
        [itemsForCiteKeys addObject:pub forKey:newKey];
		[self changeCrossrefKey:oldKey toKey:newKey];
    }

    [self invalidateGroupsForCrossreffedCiteKey:[[notification object] citeKey]];
	[self updateAllSmartGroups];
    
    if([[self currentGroupField] isEqualToString:changedKey]){
        // this handles all UI updates if we call it, so don't bother with any others
        [self updateGroupsPreservingSelection:YES];
    } else if(![[searchField stringValue] isEqualToString:@""] && 
       ([quickSearchKey isEqualToString:changedKey] || [quickSearchKey isEqualToString:BDSKAllFieldsString]) ){
        // don't perform a search if the search field is empty
		[self searchFieldAction:searchField];
	} else { 
        // groups and quicksearch won't update for us
        if([[lastSelectedColumnForSort identifier] isEqualToString:changedKey])
            [self sortPubsByColumn:nil]; // resort if the changed value was in the currently sorted column
        [self updateUI];
        [self updatePreviews:nil];
    }	
}

- (void)handleMacroChangedNotification:(NSNotification *)aNotification{
	id sender = [aNotification object];
	if([sender isKindOfClass:[BibDocument class]] && sender != self)
		return; // only macro changes for ourselves or the global macros
	
    [tableView reloadData];
    [self updatePreviews:nil];
}

- (void)handleTableSelectionChangedNotification:(NSNotification *)notification{
    [self updatePreviews:nil];
    [groupTableView updateHighlights];
}

- (void)handleResortDocumentNotification:(NSNotification *)notification{
    [self sortPubsByColumn:nil];
}

- (void)handleFlagsChangedNotification:(NSNotification *)notification{
    unsigned int modifierFlags = [[notification object] modifierFlags];
    
    if (modifierFlags & NSAlternateKeyMask) {
        [groupAddButton setImage:[NSImage imageNamed:@"GroupAddSmart"]];
        [groupAddButton setAlternateImage:[NSImage imageNamed:@"GroupAddSmart_Pressed"]];
        [groupAddButton setToolTip:NSLocalizedString(@"Add new smart group.", @"")];
    } else {
        [groupAddButton setImage:[NSImage imageNamed:@"GroupAdd"]];
        [groupAddButton setAlternateImage:[NSImage imageNamed:@"GroupAdd_Pressed"]];
        [groupAddButton setToolTip:NSLocalizedString(@"Add new group.", @"")];
    }
}

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification{
    [self saveSortOrder];
}

#pragma mark UI updating

- (void)handlePrivateUpdatePreviews{
    // we can be called from a queue after the document was closed
    if (isDocumentClosed)
        return;

    OBASSERT([NSThread inMainThread]);
            
    NSArray *selPubs = [self selectedPublications];
    
    //take care of the preview field (NSTextView below the pub table); if the enumerator is nil, the view will get cleared out
    [self displayPreviewForItems:selPubs];

    if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKUsesTeXKey] &&
	   [[[BDSKPreviewer sharedPreviewer] window] isVisible]){

		if(!selPubs){
			// clear the previews
			[[BDSKPreviewer sharedPreviewer] updateWithBibTeXString:nil];
			return;
		}

        NSString *bibString = [self previewBibTeXStringForPublications:selPubs];
        [[BDSKPreviewer sharedPreviewer] updateWithBibTeXString:bibString];
    }
}

- (void)updatePreviews:(NSNotification *)aNotification{
    // Coalesce these notifications here, since something like select all -> generate cite keys will force a preview update for every
    // changed key, so we have to update all the previews each time.  This should be safer than using cancelPrevious... since those
    // don't get performed on the main thread (apparently), and can lead to problems.
    if (isDocumentClosed == NO)
        [self queueSelectorOnce:@selector(handlePrivateUpdatePreviews)];
}

- (void)displayPreviewForItems:(NSArray *)items{

    if(NSIsEmptyRect([previewField visibleRect]))
        return;
        
    static NSAttributedString *noAttrDoubleLineFeed;
    if(noAttrDoubleLineFeed == nil)
        noAttrDoubleLineFeed = [[NSAttributedString alloc] initWithString:@"\n\n" attributes:nil];
    
    int displayType = [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKPreviewDisplayKey];
    
    NSDictionary *bodyAttributes = nil;
    NSDictionary *titleAttributes = nil;
    if (displayType == 1 || displayType == 2) {
        NSDictionary *cachedFonts = [(BDSKFontManager *)[BDSKFontManager sharedFontManager] cachedFontsForPreviewPane];
        bodyAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[cachedFonts objectForKey:@"Body"], NSFontAttributeName, nil];
        titleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[cachedFonts objectForKey:@"Body"], NSFontAttributeName, [NSNumber numberWithBool:YES], NSUnderlineStyleAttributeName, nil];
    }
    
    NSMutableAttributedString *s;
  
    int maxItems = [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKPreviewMaxNumberKey];
    
    if (maxItems > 0 && [items count] > maxItems)
        items = [items subarrayWithRange:NSMakeRange(0, maxItems)];
    
    NSTextStorage *textStorage = [previewField textStorage];

    // do this _before_ messing with the text storage; otherwise you can have a leftover selection that ends up being out of range
    NSRange zeroRange = NSMakeRange(0, 0);
    if([previewField respondsToSelector:@selector(setSelectedRanges:)]){
        static NSArray *zeroRanges = nil;
        if(!zeroRanges) zeroRanges = [[NSArray alloc] initWithObjects:[NSValue valueWithRange:zeroRange], nil];
        [previewField setSelectedRanges:zeroRanges];
    } else {
        [previewField setSelectedRange:zeroRange];
    }
            
    NSLayoutManager *layoutManager = [[textStorage layoutManagers] lastObject];
    [layoutManager retain];
    [textStorage removeLayoutManager:layoutManager]; // optimization: make sure the layout manager doesn't do any work while we're loading

    [textStorage beginEditing];
    [[textStorage mutableString] setString:@""];
    
    unsigned int numberOfSelectedPubs = [items count];
    NSEnumerator *enumerator = [items objectEnumerator];
    BibItem *pub = nil;
    NSString *fieldValue;
    BOOL isFirst = YES;
    
    switch(displayType){
        case 0:
            while(pub = [enumerator nextObject]){
                if (isFirst == YES) isFirst = NO;
                else [[textStorage mutableString] appendCharacter:NSFormFeedCharacter]; // page break for printing; doesn't display
                [textStorage appendAttributedString:[pub attributedStringValue]];
                [textStorage appendAttributedString:noAttrDoubleLineFeed];
            }
            break;
        case 1:
            while(pub = [enumerator nextObject]){
                // Write out the title
                if(numberOfSelectedPubs > 1){
                    s = [[NSMutableAttributedString alloc] initWithString:[pub displayTitle]
                                                               attributes:titleAttributes];
                    [s appendAttributedString:noAttrDoubleLineFeed];
                    [textStorage appendAttributedString:s];
                    [s release];
                }
                fieldValue = [pub valueOfField:BDSKAnnoteString inherit:NO];
                if([fieldValue isEqualToString:@""])
                    fieldValue = NSLocalizedString(@"No notes.",@"");
                s = [[NSMutableAttributedString alloc] initWithString:fieldValue
                                                           attributes:bodyAttributes];
                [textStorage appendAttributedString:s];
                [s release];
                [textStorage appendAttributedString:noAttrDoubleLineFeed];
            }
            break;
        case 2:
            while(pub = [enumerator nextObject]){
                // Write out the title
                if(numberOfSelectedPubs > 1){
                    s = [[NSMutableAttributedString alloc] initWithString:[pub displayTitle]
                                                               attributes:titleAttributes];
                    [s appendAttributedString:noAttrDoubleLineFeed];
                    [textStorage appendAttributedString:s];
                    [s release];
                }
                fieldValue = [pub valueOfField:BDSKAbstractString inherit:NO];
                if([fieldValue isEqualToString:@""])
                    fieldValue = NSLocalizedString(@"No abstract.",@"");
                s = [[NSMutableAttributedString alloc] initWithString:fieldValue
                                                           attributes:bodyAttributes];
                [textStorage appendAttributedString:s];
                [s release];
                [textStorage appendAttributedString:noAttrDoubleLineFeed];
            }
            break;
        case 3:
            do{
                NSString *style = [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKPreviewTemplateStyleKey];
                BDSKTemplate *template = [BDSKTemplate templateForStyle:style];
                if (template == nil)
                    template = [BDSKTemplate templateForStyle:[BDSKTemplate defaultStyleNameForFileType:@"rtf"]];
                NSAttributedString *templateString = [BDSKTemplateObjectProxy attributedStringByParsingTemplate:template withObject:self publications:items documentAttributes:NULL];
                [textStorage appendAttributedString:templateString];
            }while(0);
            break;
    }
    
    [textStorage endEditing];
    [textStorage addLayoutManager:layoutManager];
    [layoutManager release];
    
    if([NSString isEmptyString:[searchField stringValue]] == NO)
        [previewField highlightComponentsOfSearchString:[searchField stringValue]];
    
}

- (void)updateUI{
	[tableView reloadData];
    
	int shownPubsCount = [shownPublications count];
	int groupPubsCount = [groupedPublications count];
	int totalPubsCount = [publications count];
    // show the singular form correctly
	NSMutableString *statusStr = [[NSMutableString alloc] init];
	NSString *ofStr = NSLocalizedString(@"of", @"of");

	if (shownPubsCount != groupPubsCount) { 
		[statusStr appendFormat:@"%i %@ ", shownPubsCount, ofStr];
	}
	[statusStr appendFormat:@"%i %@", groupPubsCount, (groupPubsCount == 1) ? NSLocalizedString(@"publication", @"publication") : NSLocalizedString(@"publications", @"publications")];
	if ([self hasSharedGroupsSelected] == YES) {
        // we can only one shared group selected at a time
        [statusStr appendFormat:@" %@ \"%@\"", NSLocalizedString(@"in shared group", @"in shared group"), [[[self selectedGroups] lastObject] stringValue]];
	} else if (groupPubsCount != totalPubsCount) {
		NSString *groupStr = ([groupTableView numberOfSelectedRows] == 1) ?
			[NSString stringWithFormat:@"%@ \"%@\"", NSLocalizedString(@"group", @"group"), [[[self selectedGroups] lastObject] stringValue]] :
			NSLocalizedString(@"multiple groups", @"multiple groups");
        [statusStr appendFormat:@" %@ %@ (%@ %i)", NSLocalizedString(@"in", @"in"), groupStr, ofStr, totalPubsCount];
	}
	[self setStatus:statusStr];
    [statusStr release];
}

- (BOOL)highlightItemForPartialItem:(NSDictionary *)partialItem{
    
    // make sure we can see the publication, if it's still here
    [self selectGroup:allPublicationsGroup];
    [tableView deselectAll:self];
    [self setFilterField:@""];
    
    NSString *itemKey = [partialItem objectForKey:@"net_sourceforge_bibdesk_citekey"];
    if(itemKey == nil)
        itemKey = [partialItem objectForKey:BDSKCiteKeyString];
    
    OBPOSTCONDITION(itemKey != nil);
    
    NSEnumerator *pubEnum = [shownPublications objectEnumerator];
    BibItem *anItem;
    BOOL matchFound = NO;
    
    while(anItem = [pubEnum nextObject]){
        if([[anItem citeKey] isEqualToString:itemKey]){
            [self highlightBib:anItem];
            matchFound = YES;
        }
    }
    return matchFound;
}

- (void)highlightBib:(BibItem *)bib{
	[self highlightBibs:[NSArray arrayWithObject:bib]];
}

- (void)highlightBibs:(NSArray *)bibArray{
    
	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
	NSEnumerator *pubEnum = [bibArray objectEnumerator];
	BibItem *bib;
	int i;
	
	while(bib = [pubEnum nextObject]){
		i = [shownPublications indexOfObjectIdenticalTo:bib];    
		if(i != NSNotFound)
			[indexes addIndex:i];
	}
    
    if([indexes count]){
        [tableView selectRowIndexes:indexes byExtendingSelection:NO];
        [tableView scrollRowToVisible:[indexes firstIndex]];
    }
}

- (void)setStatus:(NSString *)status {
	[self setStatus:status immediate:YES];
}

- (void)setStatus:(NSString *)status immediate:(BOOL)now {
	if(now)
		[statusBar setStringValue:status];
	else
		[statusBar performSelector:@selector(setStringValue:) withObject:status afterDelay:0.01];
}

#pragma mark View Actions

- (IBAction)toggleStatusBar:(id)sender{
	[statusBar toggleBelowView:mainBox offset:1.0];
	[[OFPreferenceWrapper sharedPreferenceWrapper] setBool:[statusBar isVisible] forKey:BDSKShowStatusBarKey];
}

- (IBAction)changeMainTableFont:(id)sender{
    NSString *fontName = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKMainTableViewFontNameKey];
    float fontSize = [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKMainTableViewFontSizeKey];
	[[NSFontManager sharedFontManager] setSelectedFont:[NSFont fontWithName:fontName size:fontSize] isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:sender];
    
    id firstResponder = [documentWindow firstResponder];
    if (firstResponder != tableView)
        [documentWindow makeFirstResponder:tableView];
}

- (IBAction)changeGroupTableFont:(id)sender{
    NSString *fontName = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKGroupTableViewFontNameKey];
    float fontSize = [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKGroupTableViewFontSizeKey];
	[[NSFontManager sharedFontManager] setSelectedFont:[NSFont fontWithName:fontName size:fontSize] isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:sender];
    
    id firstResponder = [documentWindow firstResponder];
    if (firstResponder != groupTableView)
        [documentWindow makeFirstResponder:groupTableView];
}

- (IBAction)changePreviewDisplay:(id)sender{
    int tag = [sender tag];
    if(tag != [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKPreviewDisplayKey]){
        [[OFPreferenceWrapper sharedPreferenceWrapper] setInteger:tag forKey:BDSKPreviewDisplayKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewDisplayChangedNotification object:nil];
    }
}

- (IBAction)refreshSharing:(id)sender{
    [[BDSKSharingServer defaultServer] restartSharingIfNeeded];
}

- (IBAction)refreshSharedBrowsing:(id)sender{
    [[BDSKSharingBrowser sharedBrowser] restartSharedBrowsingIfNeeded];
}

#pragma mark TeXTask delegate

- (BOOL)texTaskShouldStartRunning:(BDSKTeXTask *)aTexTask{
	[self setStatus:[NSString stringWithFormat:@"%@%C",NSLocalizedString(@"Generating data. Please wait", @"Generating data. Please wait..."), 0x2026]];
	[statusBar startAnimation:nil];
	return YES;
}

- (void)texTask:(BDSKTeXTask *)aTexTask finishedWithResult:(BOOL)success{
	[statusBar stopAnimation:nil];
	[self updateUI];
}

#pragma mark Custom cite drawer stuff

- (IBAction)toggleShowingCustomCiteDrawer:(id)sender{
    [customCiteDrawer toggle:sender];
	if(showingCustomCiteDrawer){
		showingCustomCiteDrawer = NO;
	}else{
		showingCustomCiteDrawer = YES;
	}
}

- (IBAction)addCustomCiteString:(id)sender{
    int row = [customStringArray count];
	[customStringArray addObject:@"citeCommand"];
    [ccTableView reloadData];
	[ccTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[ccTableView editColumn:0 row:row withEvent:nil select:YES];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:customStringArray forKey:BDSKCustomCiteStringsKey];
}

- (IBAction)removeCustomCiteString:(id)sender{
    if([ccTableView numberOfSelectedRows] == 0)
		return;
	
	if ([ccTableView editedRow] != -1)
		[documentWindow makeFirstResponder:ccTableView];
	[customStringArray removeObjectAtIndex:[ccTableView selectedRow]];
	[ccTableView reloadData];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:customStringArray forKey:BDSKCustomCiteStringsKey];
}

- (int)numberOfSelectedPubs{
    return [tableView numberOfSelectedRows];
}

- (NSArray *)selectedPublications{

    if([tableView selectedRow] == -1)
        return nil;
    
    return [shownPublications objectsAtIndexes:[tableView selectedRowIndexes]];
}

#pragma mark Main window stuff

- (void)saveSortOrder{ 
    // @@ if we switch to NSArrayController, we should just archive the sort descriptors (see BDSKFileContentSearchController)
    OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
    [pw setObject:[lastSelectedColumnForSort identifier] forKey:BDSKDefaultSortedTableColumnKey];
    [pw setBool:sortDescending forKey:BDSKDefaultSortedTableColumnIsDescendingKey];
    [pw setObject:sortGroupsKey forKey:BDSKSortGroupsKey];
    [pw setBool:sortGroupsDescending forKey:BDSKSortGroupsDescendingKey];
}  

- (void)windowWillClose:(NSNotification *)notification{

    if([notification object] != documentWindow) // this is critical; 
        return;
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocumentWindowWillCloseNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionary]];
    isDocumentClosed = YES;
    [[BDSKErrorObjectController sharedErrorObjectController] removeErrorObjsForDocument:self];
    [customCiteDrawer close];
    [self saveSortOrder];
    
    // reset the previewer; don't send [self updatePreviews:] here, as the tableview will be gone by the time the queue posts the notification
    if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKUsesTeXKey] &&
       [[[BDSKPreviewer sharedPreviewer] window] isVisible] &&
       [tableView selectedRow] != -1 )
        [[BDSKPreviewer sharedPreviewer] updateWithBibTeXString:nil];    
	
	[self providePromisedTypes];
	
    // safety call here, in case the pasteboard is retaining the document; we don't want notifications after the window closes, since all the pointers to UI elements will be garbage
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (void)pageDownInPreview:(id)sender{
    NSPoint p = [previewField scrollPositionAsPercentage];
    
    float pageheight = NSHeight([[[previewField enclosingScrollView] documentView] bounds]);
    float viewheight = NSHeight([[previewField enclosingScrollView] documentVisibleRect]);
    
    if(p.y > 0.99 || viewheight >= pageheight){ // select next row if the last scroll put us at the end
        int i = [[tableView selectedRowIndexes] lastIndex];
		if (i == NSNotFound)
			i = 0;
		else if (i < [tableView numberOfRows])
			i++;
		[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
        [tableView scrollRowToVisible:i];
        return; // adjust page next time
    }
    [previewField pageDown:sender];
}

- (void)pageUpInPreview:(id)sender{
    NSPoint p = [previewField scrollPositionAsPercentage];
    
    if(p.y < 0.01){ // select previous row if we're already at the top
        int i = [[tableView selectedRowIndexes] firstIndex];
		if (i == NSNotFound)
			i = 0;
		else if (i > 0)
			i--;
		[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
        [tableView scrollRowToVisible:i];
        return; // adjust page next time
    }
    [previewField pageUp:sender];
}

- (void)splitViewDoubleClick:(OASplitView *)sender{
	NSView *firstView = [[sender subviews] objectAtIndex:0];
	NSView *secondView = [[sender subviews] objectAtIndex:1];
	NSRect firstFrame = [firstView frame];
	NSRect secondFrame = [secondView frame];
	
	if (sender == splitView) {
		// first = table, second = preview
		if(NSHeight([secondView frame]) != 0){ // not sure what the criteria for isSubviewCollapsed, but it doesn't work
			lastPreviewHeight = NSHeight(secondFrame); // cache this
			firstFrame.size.height += lastPreviewHeight;
			secondFrame.size.height = 0;
		} else {
			if(lastPreviewHeight == 0)
				lastPreviewHeight = NSHeight([sender frame]) / 3; // a reasonable value for uncollapsing the first time
			secondFrame.size.height = lastPreviewHeight;
			firstFrame.size.height = NSHeight([sender frame]) - lastPreviewHeight - [sender dividerThickness];
		}
	} else {
		// first = group, second = table+preview
		if(NSWidth([firstView frame]) != 0){
			lastGroupViewWidth = NSWidth(firstFrame); // cache this
			secondFrame.size.width += lastGroupViewWidth;
			firstFrame.size.width = 0;
		} else {
			if(lastGroupViewWidth == 0)
				lastGroupViewWidth = 120; // a reasonable value for uncollapsing the first time
			firstFrame.size.width = lastGroupViewWidth;
			secondFrame.size.width = NSWidth([sender frame]) - lastGroupViewWidth - [sender dividerThickness];
		}
	}
	
	[firstView setFrame:firstFrame];
	[secondView setFrame:secondFrame];
    [sender adjustSubviews];
}


#pragma mark Macro stuff

- (BDSKMacroResolver *)macroResolver{
    return macroResolver;
}

- (IBAction)showMacrosWindow:(id)sender{
    if (!macroWC) {
        macroWC = [[MacroWindowController alloc] initWithMacroResolver:[self macroResolver]];
    }
    if ([[self windowControllers] containsObject:macroWC] == NO) {
        [self addWindowController:macroWC];
    }
    [macroWC showWindow:self];
}

#pragma mark
#pragma mark Cite Keys and Crossref support

- (BOOL)citeKeyIsUsed:(NSString *)aCiteKey byItemOtherThan:(BibItem *)anItem{
    NSArray *items = [[self itemsForCiteKeys] arrayForKey:aCiteKey];
    
	if ([items count] > 1)
		return YES;
	if ([items count] == 1 && [items objectAtIndex:0] != anItem)	
		return YES;
	return NO;
}

- (IBAction)generateCiteKey:(id)sender
{
    unsigned int numberOfSelectedPubs = [self numberOfSelectedPubs];
	if (numberOfSelectedPubs == 0 ||
        [self hasSharedGroupsSelected] == YES) return;
	
	NSEnumerator *selEnum = [[self selectedPublications] objectEnumerator];
	BibItem *aPub;
    NSMutableArray *arrayOfPubs = [NSMutableArray arrayWithCapacity:numberOfSelectedPubs];
    NSMutableArray *arrayOfOldValues = [NSMutableArray arrayWithCapacity:numberOfSelectedPubs];
    NSMutableArray *arrayOfNewValues = [NSMutableArray arrayWithCapacity:numberOfSelectedPubs];
	BDSKScriptHook *scriptHook = [[BDSKScriptHookManager sharedManager] makeScriptHookWithName:BDSKWillGenerateCiteKeyScriptHookName];
	
    // first we make sure all edits are committed
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKFinalizeChangesNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionary]];
	
    // put these pubs into an array, since the indices can change after we set the cite key, due to sorting or searching
	while (aPub = [selEnum nextObject]) {
        [arrayOfPubs addObject:aPub];
		if(scriptHook){
			[arrayOfOldValues addObject:[aPub citeKey]];
			[arrayOfNewValues addObject:[aPub suggestedCiteKey]];
		}
	}
	
	if (scriptHook) {
		[scriptHook setField:BDSKCiteKeyString];
		[scriptHook setOldValues:arrayOfOldValues];
		[scriptHook setNewValues:arrayOfNewValues];
		[[BDSKScriptHookManager sharedManager] runScriptHook:scriptHook forPublications:arrayOfPubs];
	}
    
	scriptHook = [[BDSKScriptHookManager sharedManager] makeScriptHookWithName:BDSKDidGenerateCiteKeyScriptHookName];
	[arrayOfOldValues removeAllObjects];
	[arrayOfNewValues removeAllObjects];
    selEnum = [arrayOfPubs objectEnumerator];
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    unsigned poolCount = 0;
	
    while(aPub = [selEnum nextObject]){
		NSString *newKey = [aPub suggestedCiteKey];
        [aPub setCiteKey:newKey];
        		
        if(scriptHook){
			[arrayOfOldValues addObject:[aPub citeKey]];
			[arrayOfNewValues addObject:newKey];
		}
        
        // all the UI and group updates while generating cite keys can run us out of memory
        if(poolCount++ > 50){
            [pool release];
            pool = [[NSAutoreleasePool alloc] init];
            poolCount = 0;
        }
	}

    // should be safe to release here since arrays were created outside the scope of this local pool
    [pool release];

	if (scriptHook) {
		[scriptHook setField:BDSKCiteKeyString];
		[scriptHook setOldValues:arrayOfOldValues];
		[scriptHook setNewValues:arrayOfNewValues];
		[[BDSKScriptHookManager sharedManager] runScriptHook:scriptHook forPublications:arrayOfPubs];
	}
	
	[[self undoManager] setActionName:(numberOfSelectedPubs > 1 ? NSLocalizedString(@"Generate Cite Keys",@"") : NSLocalizedString(@"Generate Cite Key",@""))];
}

// select duplicates, then allow user to delete/copy/whatever
- (IBAction)selectPossibleDuplicates:(id)sender{
    
	[self setFilterField:@""]; // make sure we can see everything
    
    [documentWindow makeFirstResponder:tableView]; // make sure tableview has the focus
    
    CFIndex index = [tableView numberOfRows];
    id object1, object2;
    
    OBASSERT(lastSelectedColumnForSort);
    
    NSMutableSet *itemsToSelect = [NSMutableSet setWithCapacity:10];
    
    // Compare objects in the currently sorted table column using the isEqual: method to test adjacent cells in order to check for duplicates based on a specific sort key.  BibTool does this, but its effectiveness is obviously limited by the key used <http://lml.ls.fi.upm.es/manuales/bibtool/m_2_11_1.html>.
    while(--index){
        object1 = [self tableView:tableView objectValueForTableColumn:lastSelectedColumnForSort row:index];
        object2 = [self tableView:tableView objectValueForTableColumn:lastSelectedColumnForSort row:(index - 1)];
        if([object1 isEqual:object2]){
            [itemsToSelect addObject:[shownPublications objectAtIndex:index]];
            [itemsToSelect addObject:[shownPublications objectAtIndex:(index - 1)]];
        }
    }
	CFIndex countOfItems = [itemsToSelect count];
	
	[self highlightBibs:[itemsToSelect allObjects]];
    
    if(countOfItems)
        [tableView scrollRowToVisible:[tableView selectedRow]];  // make sure at least one item is visible
    else
        NSBeep();
    
	NSString *pubSingularPlural = (countOfItems == 1) ? NSLocalizedString(@"publication", @"publication") : NSLocalizedString(@"publications", @"publications");
    // update status line after the updateUI notification, or else it gets overwritten
    [self setStatus:[NSString stringWithFormat:NSLocalizedString(@"%i duplicate %@ found.", @"[number] duplicate publication(s) found"), countOfItems, pubSingularPlural] immediate:NO];
}

// select duplicates, then allow user to delete/copy/whatever
- (IBAction)selectDuplicates:(id)sender{
    
	[self setFilterField:@""]; // make sure we can see everything
    
    [documentWindow makeFirstResponder:tableView]; // make sure tableview has the focus
    NSZone *zone = [self zone];
    
    NSMutableArray *pubsToRemove = [[self publications] mutableCopy];
    CFIndex countOfItems = [pubsToRemove count];
    BibItem **pubs = NSZoneMalloc(zone, sizeof(BibItem *) * countOfItems);
    [pubsToRemove getObjects:pubs];
    
    // Tests equality based on standard fields (high probability that these will be duplicates)
    NSSet *uniquePubs = (NSSet *)CFSetCreate(CFAllocatorGetDefault(), (const void **)pubs, countOfItems, &BDSKBibItemEqualityCallBacks);
    [pubsToRemove removeIdenticalObjectsFromArray:[uniquePubs allObjects]]; // remove all unique ones based on pointer equality
    [uniquePubs release];
    NSZoneFree(zone, pubs);
    
    countOfItems = [pubsToRemove count];
    pubs = NSZoneMalloc(zone, sizeof(BibItem *) * countOfItems);
    [pubsToRemove getObjects:pubs];
    NSSet *removeSet = (NSSet *)CFSetCreate(CFAllocatorGetDefault(), (const void **)pubs, countOfItems, &BDSKBibItemEqualityCallBacks);
    NSZoneFree(zone, pubs);
    
    [pubsToRemove removeAllObjects];
    [pubsToRemove addObjectsFromArray:publications];
    CFIndex idx = [pubsToRemove count];
    
    while(idx--){
        if([removeSet containsObject:[pubsToRemove objectAtIndex:idx]] == NO)
            [pubsToRemove removeObjectAtIndex:idx];
    }
    
    [removeSet release];
	[self highlightBibs:pubsToRemove];
    [pubsToRemove release];

    if(countOfItems)
        [tableView scrollRowToVisible:[tableView selectedRow]];  // make sure at least one item is visible
    else
        NSBeep();
    
	NSString *pubSingularPlural = (countOfItems == 1) ? NSLocalizedString(@"publication", @"publication") : NSLocalizedString(@"publications", @"publications");
    // update status line after the updateUI notification, or else it gets overwritten
    [self setStatus:[NSString stringWithFormat:NSLocalizedString(@"%i duplicate %@ found.", @"[number] duplicate publication(s) found"), countOfItems, pubSingularPlural] immediate:NO];
}

- (void)rebuildItemsForCiteKeys{
	[itemsForCiteKeys release];
    itemsForCiteKeys = [[OFMultiValueDictionary alloc] initWithKeyCallBacks:&BDSKCaseInsensitiveStringKeyDictionaryCallBacks];
	NSArray *pubs = [publications copy];
	[self addToItemsForCiteKeys:pubs];
	[pubs release];
}

- (void)addToItemsForCiteKeys:(NSArray *)pubs{
	BibItem *pub;
	NSEnumerator *e = [pubs objectEnumerator];
	
	while(pub = [e nextObject])
		[itemsForCiteKeys addObject:pub forKey:[pub citeKey]];
}

- (void)removeFromItemsForCiteKeys:(NSArray *)pubs{
	BibItem *pub;
	NSEnumerator *e = [pubs objectEnumerator];
	
	while(pub = [e nextObject])
		[itemsForCiteKeys removeObject:pub forKey:[pub citeKey]];
}

- (OFMultiValueDictionary *)itemsForCiteKeys{
	return itemsForCiteKeys;
}

- (BibItem *)publicationForCiteKey:(NSString *)key{
	if ([NSString isEmptyString:key]) 
		return nil;
    
	NSArray *items = [[self itemsForCiteKeys] arrayForKey:key];
	
	if ([items count] == 0)
		return nil;
    // may have duplicate items for the same key, so just return the first one
    return [items objectAtIndex:0];
}

- (NSArray *)allPublicationsForCiteKey:(NSString *)key{
	NSArray *items = nil;
    if ([NSString isEmptyString:key] == NO) 
		items = [[self itemsForCiteKeys] arrayForKey:key];
    return (items == nil) ? [NSArray array] : items;
}

- (BOOL)citeKeyIsCrossreffed:(NSString *)key{
	if ([NSString isEmptyString:key]) 
		return NO;
    
	NSEnumerator *pubEnum = [publications objectEnumerator];
	BibItem *pub;
	
	while (pub = [pubEnum nextObject]) {
		if ([key caseInsensitiveCompare:[pub valueOfField:BDSKCrossrefString inherit:NO]] == NSOrderedSame) {
			return YES;
        }
	}
	return NO;
}

- (void)changeCrossrefKey:(NSString *)oldKey toKey:(NSString *)newKey{
	if ([NSString isEmptyString:oldKey]) 
		return;
    
	NSEnumerator *pubEnum = [publications objectEnumerator];
	BibItem *pub;
	
	while (pub = [pubEnum nextObject]) {
		if ([oldKey caseInsensitiveCompare:[pub valueOfField:BDSKCrossrefString inherit:NO]] == NSOrderedSame) {
			[pub setField:BDSKCrossrefString toValue:newKey];
        }
	}
}

- (void)invalidateGroupsForCrossreffedCiteKey:(NSString *)key{
	if ([NSString isEmptyString:key]) 
		return;
    
	NSEnumerator *pubEnum = [publications objectEnumerator];
	BibItem *pub;
	
	while (pub = [pubEnum nextObject]) {
		if ([key caseInsensitiveCompare:[pub valueOfField:BDSKCrossrefString inherit:NO]] == NSOrderedSame) {
			[pub invalidateGroupNames];
        }
	}
}

- (void)performSortForCrossrefs{
	NSEnumerator *pubEnum = [publications objectEnumerator];
	BibItem *pub = nil;
	BibItem *parent;
	NSString *key;
	NSMutableSet *prevKeys = [NSMutableSet set];
	BOOL moved = NO;
	NSArray *selectedPubs = [self selectedPublications];
	
	// We only move parents that come after a child.
	while (pub = [pubEnum nextObject]){
		key = [[pub valueOfField:BDSKCrossrefString inherit:NO] lowercaseString];
		if (![NSString isEmptyString:key] && [prevKeys containsObject:key]) {
            [prevKeys removeObject:key];
			parent = [self publicationForCiteKey:key];
			[publications removeObjectIdenticalTo:parent];
			[publications addObject:parent];
			moved = YES;
		}
		[prevKeys addObject:[[pub citeKey] lowercaseString]];
	}
	
	if (moved) {
		[self sortPubsByColumn:nil];
		[self highlightBibs:selectedPubs];
		[self setStatus:NSLocalizedString(@"Publications sorted for cross references.", @"")];
	}
}

- (IBAction)sortForCrossrefs:(id)sender{
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] setPublications:publications];
	[undoManager setActionName:NSLocalizedString(@"Sort Publications",@"")];
	
	[self performSortForCrossrefs];
}

- (void)selectCrossrefParentForItem:(BibItem *)item{
    NSString *crossref = [item valueOfField:BDSKCrossrefString inherit:NO];
    [tableView deselectAll:nil];
    BibItem *parent = [self publicationForCiteKey:crossref];
    if(crossref && parent){
        [self highlightBib:parent];
        [tableView scrollRowToVisible:[tableView selectedRow]];
    } else
        NSBeep(); // if no parent found
}

- (IBAction)selectCrossrefParentAction:(id)sender{
    BibItem *selectedBI = [[self selectedPublications] lastObject];
    [self selectCrossrefParentForItem:selectedBI];
}

- (void)createNewPubUsingCrossrefForItem:(BibItem *)item{
    BibItem *newBI = [[BibItem alloc] init];
	NSString *parentType = [item type];
    
	[newBI setField:BDSKCrossrefString toValue:[item citeKey]];
	if ([parentType isEqualToString:@"proceedings"]) {
		[newBI setType:@"inproceedings"];
	} else if ([parentType isEqualToString:@"book"] || 
			   [parentType isEqualToString:@"booklet"] || 
			   [parentType isEqualToString:@"techreport"] || 
			   [parentType isEqualToString:@"manual"]) {
		if (![[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKPubTypeStringKey] isEqualToString:@"inbook"]) 
			[newBI setType:@"incollection"];
	}
    [self addPublication:newBI];
    [newBI release];
    [self editPub:newBI];
}

- (IBAction)createNewPubUsingCrossrefAction:(id)sender{
    BibItem *selectedBI = [[self selectedPublications] lastObject];
    [self createNewPubUsingCrossrefForItem:selectedBI];
}

- (IBAction)duplicateTitleToBooktitle:(id)sender{
	if ([self numberOfSelectedPubs] == 0 ||
        [self hasSharedGroupsSelected] == YES) return;
	
	BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Overwrite Booktitle?", @"")
										 defaultButton:NSLocalizedString(@"Don't Overwrite", @"Don't Overwrite")
									   alternateButton:NSLocalizedString(@"Overwrite", @"Overwrite")
										   otherButton:nil
						 informativeTextWithFormat:NSLocalizedString(@"Do you want me to overwrite the Booktitle field when it was already entered?", @"")];
	int rv = [alert runSheetModalForWindow:documentWindow
							 modalDelegate:nil
							didEndSelector:NULL 
						didDismissSelector:NULL 
							   contextInfo:NULL];
	BOOL overwrite = (rv == NSAlertAlternateReturn);
	
	NSSet *parentTypes = [NSSet setWithArray:[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKTypesForDuplicateBooktitleKey]];
	NSEnumerator *selEnum = [[self selectedPublications] objectEnumerator];
	BibItem *aPub;
	
    // first we make sure all edits are committed
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKFinalizeChangesNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionary]];
	
	while (aPub = [selEnum nextObject]) {
		if([parentTypes containsObject:[aPub type]])
			[aPub duplicateTitleToBooktitleOverwriting:overwrite];
	}
	[[self undoManager] setActionName:([self numberOfSelectedPubs] > 1 ? NSLocalizedString(@"Duplicate Titles",@"") : NSLocalizedString(@"Duplicate Title",@""))];
}

#pragma mark
#pragma mark Printing support

- (NSView *)printableView{
    BDSKPrintableView *printableView = [[BDSKPrintableView alloc] initForScreenDisplay:NO];
    [printableView setAttributedString:[previewField textStorage]];    
    return [printableView autorelease];
}

- (void)printShowingPrintPanel:(BOOL)showPanels {
    // Obtain a custom view that will be printed
    NSView *printView = [self printableView];
	
    // Construct the print operation and setup Print panel
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:printView
                                                          printInfo:[self printInfo]];
    [op setShowPanels:showPanels];
    [op setCanSpawnSeparateThread:YES];
    if (showPanels) {
        // Add accessory view, if needed
    }
	
    // Run operation, which shows the Print panel if showPanels was YES
    [op runOperationModalForWindow:[self windowForSheet] delegate:nil didRunSelector:NULL contextInfo:NULL];
}

#pragma mark 
#pragma mark AutoFile stuff

- (IBAction)consolidateLinkedFiles:(id)sender{
    if ([self hasSharedGroupsSelected] == YES) {
        NSBeep();
        return;
    }
    BOOL check = YES;
    int rv = NSRunAlertPanel(NSLocalizedString(@"Consolidate Linked Files",@""),
                             NSLocalizedString(@"This will put all files linked to the selected items in your Papers Folder, according to the format string. Do you want me to generate a new location for all linked files, or only for those for which all the bibliographical information used in the generated file name has been set?",@""),
                             NSLocalizedString(@"Move Complete Only",@"Move Complete Only"),
                             NSLocalizedString(@"Cancel",@"Cancel"), 
                             NSLocalizedString(@"Move All",@"Move All"));
    if(rv == NSAlertOtherReturn){
        check = NO;
    }else if(rv == NSAlertAlternateReturn){
        return;
    }

    // first we make sure all edits are committed
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKFinalizeChangesNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionary]];

	[[BibFiler sharedFiler] filePapers:[self selectedPublications] fromDocument:self check:check];
	
	[[self undoManager] setActionName:NSLocalizedString(@"Consolidate Files",@"")];
}

#pragma mark blog stuff


- (IBAction)postItemToWeblog:(id)sender{

	[NSException raise:BDSKUnimplementedException
				format:@"postItemToWeblog is unimplemented."];
	
	NSString *appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Blapp"]; // pref
	NSLog(@"%@",appPath);
#if 0	
	AppleEvent *theAE;
	OSERR err = AECreateAppleEvent (NNWEditDataItemAppleEventClass,
									NNWEditDataItemAppleEventID,
									'MMcC', // Blapp
									kAutoGenerateReturnID,
									kAnyTransactionID,
									&theAE);


	
	
	OSErr AESend (
				  const AppleEvent * theAppleEvent,
				  AppleEvent * reply,
				  AESendMode sendMode,
				  AESendPriority sendPriority,
				  SInt32 timeOutInTicks,
				  AEIdleUPP idleProc,
				  AEFilterUPP filterProc
				  );
#endif
}

#pragma mark Text import sheet support

- (IBAction)importFromPasteboardAction:(id)sender{
    
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    NSString *type = [pasteboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKReferenceMinerStringPboardType, BDSKBibItemPboardType, NSStringPboardType, nil]];
    
    if(type != nil){
        NSError *error = nil;
        BOOL isKnownFormat = YES;
		if([type isEqualToString:NSStringPboardType]){
			// sniff the string to see if we should add it directly
			NSString *pboardString = [pasteboard stringForType:type];
			isKnownFormat = ([pboardString contentStringType] != BDSKUnknownStringType);
		}
		
        if(isKnownFormat && [self addPublicationsFromPasteboard:pasteboard error:&error] && error == nil)
            return; // it worked, so we're done here
    }
    
    BDSKTextImportController *tic = [(BDSKTextImportController *)[BDSKTextImportController alloc] initWithDocument:self];

    [tic beginSheetForPasteboardModalForWindow:documentWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	[tic release];
}

- (IBAction)importFromFileAction:(id)sender{
    BDSKTextImportController *tic = [(BDSKTextImportController *)[BDSKTextImportController alloc] initWithDocument:self];

    [tic beginSheetForFileModalForWindow:documentWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	[tic release];
}

- (IBAction)importFromWebAction:(id)sender{
    BDSKTextImportController *tic = [(BDSKTextImportController *)[BDSKTextImportController alloc] initWithDocument:self];

    [tic beginSheetForWebModalForWindow:documentWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	[tic release];
}

// Declaring protocol conformance in the category headers shuts the compiler up, but causes a hang in -[NSObject conformsToProtocol:], which sucks.  Therefore, we use wrapper methods here to call the real (category) implementations.
- (void)restoreDocumentStateByRemovingSearchView:(NSView *)view{ 
    [self _restoreDocumentStateByRemovingSearchView:view]; 
}

- (NSIndexSet *)indexesOfRowsToHighlightInRange:(NSRange)indexRange tableView:(BDSKGroupTableView *)tview{
    return [self _indexesOfRowsToHighlightInRange:indexRange tableView:tview];
}

- (NSIndexSet *)tableViewSingleSelectionIndexes:(BDSKGroupTableView *)tview{
    return [self _tableViewSingleSelectionIndexes:tview];
}

- (void)setFileName:(NSString *)fileName{ 
    // make sure that changes in the displayName are observed, as NSDocument doesn't use a KVC compliant method for setting it
    [self willChangeValueForKey:@"displayName"];
    [super setFileName:fileName];
    [self didChangeValueForKey:@"displayName"];
}

// just create this setter to avoid a run time warning
- (void)setDisplayName:(NSString *)newName{}

@end


@implementation BDSKTemplateObjectProxy

+ (NSString *)stringByParsingTemplate:(BDSKTemplate *)template withObject:(id)anObject publications:(NSArray *)items {
    NSString *string = [template mainPageString];
    BDSKTemplateObjectProxy *objectProxy = [[self alloc] initWithObject:anObject publications:items template:template];
    string = [BDSKTemplateParser stringByParsingTemplate:string usingObject:objectProxy delegate:objectProxy];
    [objectProxy release];
    return string;
}

+ (NSAttributedString *)attributedStringByParsingTemplate:(BDSKTemplate *)template withObject:(id)anObject publications:(NSArray *)items documentAttributes:(NSDictionary **)docAttributes {
    NSAttributedString *string = [template mainPageAttributedStringWithDocumentAttributes:docAttributes];
    BDSKTemplateObjectProxy *objectProxy = [[self alloc] initWithObject:anObject publications:items template:template];
    string = [BDSKTemplateParser attributedStringByParsingTemplate:string usingObject:objectProxy delegate:objectProxy];
    [objectProxy release];
    return string;
}

- (id)initWithObject:(id)anObject publications:(NSArray *)items template:(BDSKTemplate *)aTemplate {
    if (self = [super init]) {
        object = [anObject retain];
        publications = [items copy];
        template = [aTemplate retain];
        currentIndex = 0;
    }
    return self;
}

- (void)dealloc {
    [object release];
    [publications release];
    [template release];
    [super dealloc];
}

- (id)valueForUndefinedKey:(NSString *)key { return [object valueForKey:key]; }

- (NSArray *)publications { return publications; }

- (id)publicationsUsingTemplate{
    NSEnumerator *e = [publications objectEnumerator];
    BibItem *pub = nil;
    
    OBPRECONDITION(nil != template);
    BDSKTemplateFormat format = [template templateFormat];
    id returnString = nil;
    
    if (format & BDSKTextTemplateFormat) {
        
        returnString = [NSMutableString stringWithString:@""];        
        while(pub = [e nextObject]){
            [pub setItemIndex:++currentIndex];
            [returnString appendString:[pub stringValueUsingTemplate:template]];
        }
        
    } else if (format & BDSKRichTextTemplateFormat) {
        
        returnString = [[[NSMutableAttributedString alloc] init] autorelease];
        while(pub = [e nextObject]){
            [pub setItemIndex:++currentIndex];
            [returnString appendAttributedString:[pub attributedStringValueUsingTemplate:template]];
        }
    }
    
    return returnString;
}

// legacy method, as it may appear as a key in older templates
- (id)publicationsAsHTML{ return [self publicationsUsingTemplate]; }

- (NSCalendarDate *)currentDate{ return [NSCalendarDate date]; }

// BDSKTemplateParserDelegate protocol
- (void)templateParserWillParseTemplate:(id)template usingObject:(id)anObject isAttributed:(BOOL)flag {
    if ([anObject isKindOfClass:[BibItem class]]) {
        [(BibItem *)anObject setItemIndex:++currentIndex];
        [(BibItem *)anObject prepareForTemplateParsing];
    }
}

- (void)templateParserDidParseTemplate:(id)template usingObject:(id)anObject isAttributed:(BOOL)flag {
    if ([anObject isKindOfClass:[BibItem class]]) 
        [(BibItem *)anObject cleanupAfterTemplateParsing];
}

@end
