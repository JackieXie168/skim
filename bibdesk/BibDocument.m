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
#import "BDSKOwnerProtocol.h"
#import "BibItem.h"
#import "BibAuthor.h"
#import "BibDocument_DataSource.h"
#import "BibDocument_Actions.h"
#import "BibDocumentView_Toolbar.h"
#import "BibAppController.h"
#import "BibPrefController.h"
#import "BDSKGroup.h"
#import "BDSKStaticGroup.h"
#import "BDSKSearchGroup.h"
#import "BDSKPublicationsArray.h"
#import "BDSKGroupsArray.h"

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
#import "BibDocument_Groups.h"
#import "BibDocument_Search.h"
#import "BDSKTableSortDescriptor.h"
#import "BDSKAlert.h"
#import "BDSKFieldSheetController.h"
#import "BDSKPreviewer.h"
#import "BDSKOverlay.h"

#import "BDSKItemPasteboardHelper.h"
#import "BDSKMainTableView.h"
#import "BDSKConverter.h"
#import "BibTeXParser.h"
#import "BDSKStringParser.h"

#import "ApplicationServices/ApplicationServices.h"
#import "BDSKImagePopUpButton.h"
#import "BDSKRatingButton.h"
#import "BDSKSplitView.h"
#import "BDSKCollapsibleView.h"
#import "BDSKZoomablePDFView.h"
#import "BDSKZoomableScrollView.h"

#import "BDSKMacroResolver.h"
#import "BDSKErrorObjectController.h"
#import "BDSKGroupTableView.h"
#import "BDSKFileContentSearchController.h"
#import "NSString_BDSKExtensions.h"
#import "BDSKStatusBar.h"
#import "NSArray_BDSKExtensions.h"
#import "NSTextView_BDSKExtensions.h"
#import "NSTableView_BDSKExtensions.h"
#import "NSDictionary_BDSKExtensions.h"
#import "NSSet_BDSKExtensions.h"
#import "NSFileManager_ExtendedAttributes.h"
#import "PDFMetadata.h"
#import "BDSKSharingServer.h"
#import "BDSKSharingBrowser.h"
#import "BDSKTemplate.h"
#import "BDSKGroupTableView.h"
#import "BDSKFileContentSearchController.h"
#import "BDSKTemplateParser.h"
#import "BDSKTemplateObjectProxy.h"
#import "NSMenu_BDSKExtensions.h"
#import "NSWindowController_BDSKExtensions.h"
#import "NSData_BDSKExtensions.h"
#import "NSURL_BDSKExtensions.h"
#import "BDSKShellTask.h"
#import "NSError_BDSKExtensions.h"
#import "BDSKColoredBox.h"
#import "BDSKSearchField.h"
#import "BDSKCustomCiteDrawerController.h"
#import "NSObject_BDSKExtensions.h"
#import "BDSKDocumentController.h"

// these are the same as in Info.plist
NSString *BDSKBibTeXDocumentType = @"BibTeX Database";
NSString *BDSKRISDocumentType = @"RIS/Medline File";
NSString *BDSKMinimalBibTeXDocumentType = @"Minimal BibTeX Database";
NSString *BDSKLTBDocumentType = @"Amsrefs LTB";
NSString *BDSKEndNoteDocumentType = @"EndNote XML";
NSString *BDSKMODSDocumentType = @"MODS XML";
NSString *BDSKAtomDocumentType = @"Atom XML";

NSString *BDSKReferenceMinerStringPboardType = @"CorePasteboardFlavorType 0x57454253";
NSString *BDSKBibItemPboardType = @"edu.ucsd.mmccrack.bibdesk BibItem pboard type";
NSString *BDSKWeblocFilePboardType = @"CorePasteboardFlavorType 0x75726C20";

// private keys used for storing window information in xattrs
static NSString *BDSKMainWindowExtendedAttributeKey = @"net.sourceforge.bibdesk.BDSKDocumentWindowAttributes";
static NSString *BDSKGroupSplitViewFractionKey = @"BDSKGroupSplitViewFractionKey";
static NSString *BDSKMainTableSplitViewFractionKey = @"BDSKMainTableSplitViewFractionKey";
static NSString *BDSKDocumentWindowFrameKey = @"BDSKDocumentWindowFrameKey";
static NSString *BDSKSelectedPublicationsKey = @"BDSKSelectedPublicationsKey";
static NSString *BDSKDocumentStringEncodingKey = @"BDSKDocumentStringEncodingKey";
static NSString *BDSKDocumentScrollPercentageKey = @"BDSKDocumentScrollPercentageKey";
static NSString *BDSKSelectedGroupsKey = @"BDSKSelectedGroupsKey";
static NSString *BDSKRecentSearchesKey = @"BDSKRecentSearchesKey";

@interface NSDocument (BDSKPrivateExtensions)
// declare a private NSDocument method so we can override it
- (void)changeSaveType:(id)sender;
@end

@implementation BibDocument

- (id)init{
    if(self = [super init]){
        publications = [[BDSKPublicationsArray alloc] initWithCapacity:1];
        shownPublications = [[NSMutableArray alloc] initWithCapacity:1];
        groupedPublications = [[NSMutableArray alloc] initWithCapacity:1];
        groups = [[BDSKGroupsArray alloc] init];
        [groups setDocument:self];
        
        frontMatter = [[NSMutableString alloc] initWithString:@""];
		
        documentInfo = [[NSMutableDictionary alloc] initForCaseInsensitiveKeys];
        
        macroResolver = [[BDSKMacroResolver alloc] initWithOwner:self];
        
        BDSKUndoManager *newUndoManager = [[[BDSKUndoManager alloc] init] autorelease];
        [newUndoManager setDelegate:self];
        [self setUndoManager:newUndoManager];
		
        pboardHelper = [[BDSKItemPasteboardHelper alloc] init];
        [pboardHelper setDelegate:self];
        
        docState.isDocumentClosed = NO;
        
        // need to set this for new documents
        [self setDocumentStringEncoding:[BDSKStringEncodingManager defaultEncoding]]; 
        
        // these are set in windowControllerDidLoadNib: from the xattr defaults if available
        sortKey = nil;
        previousSortKey = nil;
        sortGroupsKey = nil;
        currentGroupField = nil;
        docState.sortDescending = NO;
        docState.sortGroupsDescending = NO;
        
        // these are created lazily when needed
        fileSearchController = nil;
        drawerController = nil;
        macroWC = nil;
        documentInfo = nil;
        infoWC = nil;
        previewer = nil;
        toolbarItems = nil;
        docState.lastPreviewHeight = 0.0;
        docState.lastGroupViewWidth = 0.0;
        
        // these are temporary state variables
        promiseDragColumnIdentifier = nil;
        docState.dragFromSharedGroups = NO;
        docState.currentSaveOperationType = 0;
        
        [self registerForNotifications];
    }
    return self;
}

- (void)dealloc{
    [fileSearchController release];
    if ([self undoManager]) {
        [[self undoManager] removeAllActionsWithTarget:self];
    }
    // workaround for crash: to reproduce, create empty doc, hit cmd-n for new editor window, then cmd-q to quit, choose "don't save"; this results in an -undoManager message to the dealloced document
    [publications makeObjectsPerformSelector:@selector(setOwner:) withObject:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [OFPreference removeObserver:self forPreference:nil];
    [pboardHelper release];
    [macroResolver release];
    [publications release];
    [shownPublications release];
    [groupedPublications release];
    [groups release];
    [frontMatter release];
    [documentInfo release];
    [drawerController release];
    [toolbarItems release];
	[statusBar release];
	[splitView release];
    [[previewTextView enclosingScrollView] release];
    [previewer release];
    [macroWC release];
    [infoWC release];
    [promiseDragColumnIdentifier release];
    [sortKey release];
    [sortGroupsKey release];
    [pubmedView release];
    [super dealloc];
}

- (NSString *)windowNibName{
        return @"BibDocument";
}

- (void)encodingAlertDidEnd:(NSAlert *)alert returnCode:(int)code contextInfo:(void *)ctxt {
    if (NSAlertDefaultReturn == code) {
        // setting delegate to nil ensures that xattrs won't be written out; the cleanup isn't an issue, since this doc just opened
        [documentWindow setDelegate:nil];
        [documentWindow close];
        [self close];
    } else {
        NSLog(@"User decided to ignore an encoding warning.");
    }    
}

- (void)showWindows{
    [super showWindows];
    
    // Get the search string keyword if available (Spotlight passes this)
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
            [self selectLibraryGroup:nil];
            [searchField setSearchKey:BDSKAllFieldsString];
            [self setSearchString:searchString];
        }
    }
    
    // some xattr setup has to be done after the window is on-screen
    NSDictionary *xattrDefaults = [self mainWindowSetupDictionaryFromExtendedAttributes];
    
    NSData *groupData = [xattrDefaults objectForKey:BDSKSelectedGroupsKey];
    if ([groupData length]) {
        // !!! remove for release
        @try{ [self selectGroups:[NSKeyedUnarchiver unarchiveObjectWithData:groupData]]; }
        @catch(id exception){ NSLog(@"Ignoring exception while unarchiving saved group selection: \"%@\"", exception); }
    }
    [self selectItemsForCiteKeys:[xattrDefaults objectForKey:BDSKSelectedPublicationsKey defaultObject:[NSArray array]] selectLibrary:NO];
    NSPoint scrollPoint = [xattrDefaults pointForKey:BDSKDocumentScrollPercentageKey defaultValue:NSZeroPoint];
    [[tableView enclosingScrollView] setScrollPositionAsPercentage:scrollPoint];
        
    // this is a sanity check; an encoding of kCFStringEncodingInvalidId is not valid, so is a signal we should ignore xattrs
    NSStringEncoding encodingFromFile = [xattrDefaults unsignedIntForKey:BDSKDocumentStringEncodingKey defaultValue:kCFStringEncodingInvalidId];
    if (encodingFromFile != kCFStringEncodingInvalidId && encodingFromFile != [self documentStringEncoding]) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Document was opened with incorrect encoding", @"Message in alert dialog when opening a document with different encoding")
                                         defaultButton:NSLocalizedString(@"Close", @"Button title")
                                       alternateButton:NSLocalizedString(@"Ignore", @"Button title") otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"The document was opened with encoding %@, but it was previously saved with encoding %@.  You should close it without saving and reopen with the correct encoding.", @"Informative text in alert dialog when opening a document with different encoding"), [NSString localizedNameOfStringEncoding:[self documentStringEncoding]], [NSString localizedNameOfStringEncoding:encodingFromFile]];
        [alert setAlertStyle:NSCriticalAlertStyle];
        [alert beginSheetModalForWindow:documentWindow modalDelegate:self didEndSelector:@selector(encodingAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
    }    
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    
    // this is the controller for the main window
    [aController setShouldCloseDocument:YES];
    
    // hidden default to remove xattrs; this presently occurs before we use them, but it may need to be earlier at some point
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"BDSKRemoveExtendedAttributesFromDocuments"] && [self fileURL]) {
        [[NSFileManager defaultManager] removeAllExtendedAttributesAtPath:[[self fileURL] path] traverseLink:YES error:NULL];
    }
    
    // get document-specific attributes (returns empty dictionary if there are none, so defaultValue works correctly)
    NSDictionary *xattrDefaults = [self mainWindowSetupDictionaryFromExtendedAttributes];
    OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
    
    NSString *searchKey = [xattrDefaults objectForKey:BDSKCurrentQuickSearchKey defaultObject:[pw objectForKey:BDSKCurrentQuickSearchKey]];
    // @@ Changed from "All Fields" to localized "Any Field" in 1.2.2; prefs may still have the old key, so this is a temporary workaround for bug #1420837 as of 31 Jan 2006
    if([searchKey isEqualToString:@"All Fields"])
        searchKey = [BDSKAllFieldsString copy];
    else if([searchKey isEqualToString:@"Added"] || [searchKey isEqualToString:@"Created"])
        searchKey = BDSKDateAddedString;
    else if([searchKey isEqualToString:@"Modified"])
        searchKey = BDSKDateModifiedString;
	[searchField setSearchKey:searchKey];
    [searchField setRecentSearches:[xattrDefaults objectForKey:BDSKRecentSearchesKey defaultObject:[NSArray array]]];
    [self setupToolbar];
    
    // First remove the statusbar if we should, as it affects proper resizing of the window and splitViews
	[statusBar retain]; // we need to retain, as we might remove it from the window
	if (![pw boolForKey:BDSKShowStatusBarKey]) {
		[self toggleStatusBar:nil];
	} else {
		// make sure they are ordered correctly, mainly for the focus ring
		[statusBar removeFromSuperview];
		[[mainBox superview] addSubview:statusBar positioned:NSWindowBelow relativeTo:nil];
	}
	[statusBar setProgressIndicatorStyle:BDSKProgressIndicatorSpinningStyle];
    
    // This must also be done before we resize the window and the splitViews
    [groupCollapsibleView setCollapseEdges:BDSKMinXEdgeMask];
    [groupCollapsibleView setMinSize:NSMakeSize(56.0, 20.0)];
    [groupGradientView setUpperColor:[NSColor colorWithCalibratedWhite:0.9 alpha:1.0]];
    [groupGradientView setLowerColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]];

    // make sure they are ordered correctly, mainly for the focus ring
	[groupCollapsibleView retain];
    [groupCollapsibleView removeFromSuperview];
    [[[groupTableView enclosingScrollView] superview] addSubview:groupCollapsibleView positioned:NSWindowBelow relativeTo:nil];
	[groupCollapsibleView release];

    NSRect frameRect = [xattrDefaults rectForKey:BDSKDocumentWindowFrameKey defaultValue:NSZeroRect];
    
    // we should only cascade windows if we have multiple documents open; bug #1299305
    // the default cascading does not reset the next location when all windows have closed, so we do cascading ourselves
    static NSPoint nextWindowLocation = {0.0, 0.0};
    
    if (NSEqualRects(frameRect, NSZeroRect) == NO) {
        [[aController window] setFrame:frameRect display:YES];
        [aController setShouldCascadeWindows:NO];
        nextWindowLocation = [[aController window] cascadeTopLeftFromPoint:NSMakePoint(NSMinX(frameRect), NSMaxY(frameRect))];
    } else {
        // set the frame from prefs first, or setFrameAutosaveName: will overwrite the prefs with the nib values if it returns NO
        [[aController window] setFrameUsingName:@"Main Window Frame Autosave"];

        [aController setShouldCascadeWindows:NO];
        if ([[aController window] setFrameAutosaveName:@"Main Window Frame Autosave"]) {
            NSRect windowFrame = [[aController window] frame];
            nextWindowLocation = NSMakePoint(NSMinX(windowFrame), NSMaxY(windowFrame));
        }
        nextWindowLocation = [[aController window] cascadeTopLeftFromPoint:nextWindowLocation];
    }
            
    [documentWindow setAutorecalculatesKeyViewLoop:YES];
    [documentWindow makeFirstResponder:tableView];	
    
    // SplitViews setup
    [groupSplitView setDrawEnd:YES];
    [splitView setDrawEnd:YES];
    
    // set autosave names first
	[splitView setPositionAutosaveName:@"OASplitView Position Main Window"];
    [groupSplitView setPositionAutosaveName:@"OASplitView Position Group Table"];
    
    // set previous splitview frames
    float fraction;
    fraction = [xattrDefaults floatForKey:BDSKGroupSplitViewFractionKey defaultValue:-1.0];
    if (fraction >= 0)
        [groupSplitView setFraction:fraction];
    fraction = [xattrDefaults floatForKey:BDSKMainTableSplitViewFractionKey defaultValue:-1.0];
    if (fraction >= 0)
        [splitView setFraction:fraction];
    
    // it might be replaced by the file content search view
    [splitView retain];
    [mainBox setBackgroundColor:[NSColor controlBackgroundColor]];
    
    [[previewTextView enclosingScrollView] retain];
    
    // TableView setup
    [tableView removeAllTableColumns];
    [tableView setupTableColumnsWithIdentifiers:[xattrDefaults objectForKey:BDSKShownColsNamesKey defaultObject:[pw objectForKey:BDSKShownColsNamesKey]]];
    sortKey = [[xattrDefaults objectForKey:BDSKDefaultSortedTableColumnKey defaultObject:[pw objectForKey:BDSKDefaultSortedTableColumnKey]] retain];
    previousSortKey = [sortKey retain];
    docState.sortDescending = [xattrDefaults  boolForKey:BDSKDefaultSortedTableColumnIsDescendingKey defaultValue:[pw boolForKey:BDSKDefaultSortedTableColumnIsDescendingKey]];
    [tableView setHighlightedTableColumn:[tableView tableColumnWithIdentifier:sortKey]];
    
    [sortGroupsKey autorelease];
    sortGroupsKey = [[xattrDefaults objectForKey:BDSKSortGroupsKey defaultObject:[pw objectForKey:BDSKSortGroupsKey]] retain];
    docState.sortGroupsDescending = [xattrDefaults boolForKey:BDSKSortGroupsDescendingKey defaultValue:[pw boolForKey:BDSKSortGroupsDescendingKey]];
    [self setCurrentGroupField:[xattrDefaults objectForKey:BDSKCurrentGroupFieldKey defaultObject:[pw objectForKey:BDSKCurrentGroupFieldKey]]];
    
    [tableView setDoubleAction:@selector(editPubOrOpenURLAction:)];
    NSArray *dragTypes = [NSArray arrayWithObjects:BDSKBibItemPboardType, BDSKWeblocFilePboardType, BDSKReferenceMinerStringPboardType, NSStringPboardType, NSFilenamesPboardType, NSURLPboardType, nil];
    [tableView registerForDraggedTypes:dragTypes];
    [groupTableView registerForDraggedTypes:dragTypes];

	// ImagePopUpButtons setup
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
    
	BDSKHeaderPopUpButtonCell *headerCell = (BDSKHeaderPopUpButtonCell *)[groupTableView popUpHeaderCell];
	[headerCell setAction:@selector(changeGroupFieldAction:)];
	[headerCell setTarget:self];
	[headerCell setMenu:[self groupFieldsMenu]];
	[headerCell setIndicatorImage:[NSImage imageNamed:docState.sortGroupsDescending ? @"NSDescendingSortIndicator" : @"NSAscendingSortIndicator"]];
    [headerCell setUsesItemFromMenu:NO];
	[headerCell setTitle:currentGroupField];
    if([headerCell itemWithTitle:currentGroupField])
        [headerCell selectItemWithTitle:currentGroupField];
    else
        [headerCell selectItemAtIndex:0];
    
    // array of BDSKSharedGroup objects and zeroconf support, doesn't do anything when already enabled
    // we don't do this in appcontroller as we want our data to be loaded
    if([pw boolForKey:BDSKShouldLookForSharedFilesKey]){
        if([[BDSKSharingBrowser sharedBrowser] isBrowsing])
            // force an initial update of the tableview, if browsing is already in progress
            [self handleSharedGroupsChangedNotification:nil];
        else
            [[BDSKSharingBrowser sharedBrowser] enableSharedBrowsing];
    }
    if([pw boolForKey:BDSKShouldShareFilesKey])
        [[BDSKSharingServer defaultServer] enableSharing];
    
    // @@ awakeFromNib is called long after the document's data is loaded, so the UI update from setPublications is too early when loading a new document; there may be a better way to do this
    [self updateSmartGroupsCountAndContent:NO];
    [self updateCategoryGroupsPreservingSelection:NO];
}

- (BOOL)undoManagerShouldUndoChange:(id)sender{
	if (![self isDocumentEdited]) {
		BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Warning", @"Message in alert dialog") 
											 defaultButton:NSLocalizedString(@"Yes", @"Button title") 
										   alternateButton:NSLocalizedString(@"No", @"Button title") 
											   otherButton:nil
								 informativeTextWithFormat:NSLocalizedString(@"You are about to undo past the last point this file was saved. Do you want to do this?", @"Informative text in alert dialog") ];

		int rv = [alert runSheetModalForWindow:documentWindow];
		if (rv == NSAlertAlternateReturn)
			return NO;
	}
	return YES;
}

// this is needed for the BDSKOwner protocol
- (NSUndoManager *)undoManager {
    return [super undoManager];
}

- (BOOL)isMainDocument {
    return [[[NSDocumentController sharedDocumentController] mainDocument] isEqual:self];
}

- (void)windowWillClose:(NSNotification *)notification{
    docState.isDocumentClosed = YES;
    
    [fileSearchController stopSearching];
    if([drawerController isDrawerOpen])
        [drawerController toggle:nil];
    [self saveSortOrder];
    [self saveWindowSetupInExtendedAttributesAtURL:[self fileURL] forSave:NO];
    
    // reset the previewer; don't send [self updatePreviews:] here, as the tableview will be gone by the time the queue posts the notification
    if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKUsesTeXKey] &&
       [[BDSKPreviewer sharedPreviewer] isWindowVisible] &&
       [self isMainDocument] &&
       [tableView selectedRow] != -1 )
        [[BDSKPreviewer sharedPreviewer] updateWithBibTeXString:nil];    
	
	[pboardHelper absolveDelegateResponsibility];
    
    // safety call here, in case the pasteboard is retaining the document; we don't want notifications after the window closes, since all the pointers to UI elements will be garbage
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// returns empty dictionary if no attributes set
- (NSDictionary *)mainWindowSetupDictionaryFromExtendedAttributes {
    NSDictionary *dict = nil;
    if ([self fileURL]) {
        dict = [[NSFileManager defaultManager] propertyListFromExtendedAttributeNamed:BDSKMainWindowExtendedAttributeKey atPath:[[self fileURL] path] traverseLink:YES error:NULL];
    }
    if (nil == dict)
        dict = [NSDictionary dictionary];
    return dict;
}

- (void)saveWindowSetupInExtendedAttributesAtURL:(NSURL *)anURL forSave:(BOOL)isSave{
    
    NSString *path = [anURL path];
    if (path && [[NSUserDefaults standardUserDefaults] boolForKey:@"BDSKDisableDocumentExtendedAttributes"] == NO) {
        
        // We could set each of these as a separate attribute name on the file, but then we'd need to muck around with prepending net.sourceforge.bibdesk. to each key, and that seems messy.
        NSMutableDictionary *dictionary = [[self mainWindowSetupDictionaryFromExtendedAttributes] mutableCopy];
        
        [dictionary setObject:[tableView tableColumnIdentifiers] forKey:BDSKShownColsNamesKey];
        [dictionary setObject:[self currentTableColumnWidthsAndIdentifiers] forKey:BDSKColumnWidthsKey];
        [dictionary setObject:sortKey forKey:BDSKDefaultSortedTableColumnKey];
        [dictionary setBoolValue:docState.sortDescending forKey:BDSKDefaultSortedTableColumnIsDescendingKey];
        [dictionary setObject:sortGroupsKey forKey:BDSKSortGroupsKey];
        [dictionary setBoolValue:docState.sortGroupsDescending forKey:BDSKSortGroupsDescendingKey];
        [dictionary setRectValue:[documentWindow frame] forKey:BDSKDocumentWindowFrameKey];
        [dictionary setFloatValue:[groupSplitView fraction] forKey:BDSKGroupSplitViewFractionKey];
        [dictionary setFloatValue:[splitView fraction] forKey:BDSKMainTableSplitViewFractionKey];
        [dictionary setObject:currentGroupField forKey:BDSKCurrentGroupFieldKey];
        [dictionary setObject:[searchField searchKey] forKey:BDSKCurrentQuickSearchKey];
        [dictionary setObject:[searchField recentSearches] forKey:BDSKRecentSearchesKey];
        
        // if this isn't a save operation, the encoding in xattr is already correct, while our encoding might be different from the actual file encoding, if the user might ignored an encoding warning without saving
        if(isSave)
            [dictionary setUnsignedIntValue:[self documentStringEncoding] forKey:BDSKDocumentStringEncodingKey];
        
        // encode groups so we can select them later with isEqual: (saving row indexes would not be as reliable)
        [dictionary setObject:([self hasExternalGroupsSelected] ? [NSData data] : [NSKeyedArchiver archivedDataWithRootObject:[self selectedGroups]]) forKey:BDSKSelectedGroupsKey];
        
        NSArray *selectedKeys = [[self selectedPublications] arrayByPerformingSelector:@selector(citeKey)];
        if ([selectedKeys count] == 0 || [self hasExternalGroupsSelected])
            selectedKeys = [NSArray array];
        [dictionary setObject:selectedKeys forKey:BDSKSelectedPublicationsKey];
        [dictionary setPointValue:[[tableView enclosingScrollView] scrollPositionAsPercentage] forKey:BDSKDocumentScrollPercentageKey];
        
        if(previewer){
            [dictionary setFloatValue:[previewer PDFScaleFactor] forKey:BDSKPreviewPDFScaleFactorKey];
            [dictionary setFloatValue:[previewer RTFScaleFactor] forKey:BDSKPreviewRTFScaleFactorKey];
        }
        
        if(fileSearchController){
            [dictionary setObject:[fileSearchController sortDescriptorData] forKey:BDSKFileContentSearchSortDescriptorKey];
        }
        
        NSError *error;
        
        if ([[NSFileManager defaultManager] setExtendedAttributeNamed:BDSKMainWindowExtendedAttributeKey 
                                                  toPropertyListValue:dictionary
                                                               atPath:path options:nil error:&error] == NO) {
            NSLog(@"%@: %@", self, error);
        }
        
        [dictionary release];
    } 
}

#pragma mark -
#pragma mark Publications acessors

- (void)setPublicationsWithoutUndo:(NSArray *)newPubs{
    [publications makeObjectsPerformSelector:@selector(setOwner:) withObject:nil];
    [publications setArray:newPubs];
    [publications makeObjectsPerformSelector:@selector(setOwner:) withObject:self];
}    

- (void)setPublications:(NSArray *)newPubs{
    if(newPubs != publications){
        NSUndoManager *undoManager = [self undoManager];
        [[undoManager prepareWithInvocationTarget:self] setPublications:publications];
        
        [self setPublicationsWithoutUndo:newPubs];
        
        NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:newPubs, @"pubs", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocSetPublicationsNotification
                                                            object:self
                                                          userInfo:notifInfo];
    }
}

- (BDSKPublicationsArray *) publications{
    return publications;
}

- (void)insertPublications:(NSArray *)pubs atIndexes:(NSIndexSet *)indexes{
    // this assertion is only necessary to preserve file order for undo
    NSParameterAssert([indexes count] == [pubs count]);
    [[[self undoManager] prepareWithInvocationTarget:self] removePublicationsAtIndexes:indexes];
		
	[publications insertObjects:pubs atIndexes:indexes];        
    
	[pubs makeObjectsPerformSelector:@selector(setOwner:) withObject:self];
	
	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:pubs, @"pubs", [pubs arrayByPerformingSelector:@selector(searchIndexInfo)], @"searchIndexInfo", nil];
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
    
    [[groups lastImportGroup] removePublicationsInArray:pubs];
    [[groups staticGroups] makeObjectsPerformSelector:@selector(removePublicationsInArray:) withObject:pubs];
    
	[publications removeObjectsAtIndexes:indexes];
	
	[pubs makeObjectsPerformSelector:@selector(setOwner:) withObject:nil];
    [[NSFileManager defaultManager] removeSpotlightCacheFilesForCiteKeys:[pubs arrayByPerformingSelector:@selector(citeKey)]];
	
	notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:pubs, @"pubs", [pubs arrayByPerformingSelector:@selector(searchIndexInfo)], @"searchIndexInfo", nil];
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

#pragma mark Groups accessors

- (BDSKGroupsArray *)groups{
    return groups;
}

#pragma mark -

- (void)getCopyOfPublicationsOnMainThread:(NSMutableArray *)dstArray{
    if([NSThread inMainThread] == NO){
        [self performSelectorOnMainThread:_cmd withObject:dstArray waitUntilDone:YES];
    } else {
        NSArray *array = [[NSArray alloc] initWithArray:[self publications] copyItems:YES];
        [dstArray addObjectsFromArray:array];
        [array release];
    }
}

- (void)getCopyOfMacrosOnMainThread:(NSMutableDictionary *)dstDict{
    if([NSThread inMainThread] == NO){
        [self performSelectorOnMainThread:_cmd withObject:dstDict waitUntilDone:YES];
    } else {
        NSDictionary *dict = [[NSDictionary alloc] initWithDictionary:[macroResolver macroDefinitions] copyItems:YES];
        [dstDict addEntriesFromDictionary:dict];
        [dict release];
    }
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

#pragma mark Macro stuff

- (BDSKMacroResolver *)macroResolver{
    return macroResolver;
}

#pragma mark -
#pragma mark  Document Saving

+ (NSArray *)writableTypes
{
    NSMutableArray *writableTypes = [[[super writableTypes] mutableCopy] autorelease];
    [writableTypes addObjectsFromArray:[BDSKTemplate allStyleNames]];
    return writableTypes;
}

#define SAVE_ENCODING_VIEW_OFFSET 30.0
#define SAVE_FORMAT_POPUP_OFFSET 31.0

static NSPopUpButton *popUpButtonSubview(NSView *view)
{
	if ([view isKindOfClass:[NSPopUpButton class]])
		return (NSPopUpButton *)view;
	
	NSEnumerator *viewEnum = [[view subviews] objectEnumerator];
	NSView *subview;
	NSPopUpButton *popup;
	
	while (subview = [viewEnum nextObject]) {
		if (popup = popUpButtonSubview(subview))
			return popup;
	}
	return nil;
}

// if the user is saving in one of our plain text formats, give them an encoding option as well
// this also requires overriding saveToURL:ofType:forSaveOperation:error:
// to set the document's encoding before writing to the file
- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel{
    if([super prepareSavePanel:savePanel] == NO)
        return NO;
    
    NSView *accessoryView = [savePanel accessoryView];
    NSPopUpButton *saveFormatPopupButton = popUpButtonSubview(accessoryView);
    OBASSERT(saveFormatPopupButton != nil);
    NSRect popupFrame = [saveTextEncodingPopupButton frame];
    popupFrame.origin.y += SAVE_FORMAT_POPUP_OFFSET;
    [saveFormatPopupButton setFrame:popupFrame];
    [saveAccessoryView addSubview:saveFormatPopupButton];
    NSRect savFrame = [saveAccessoryView frame];
    savFrame.size.width = NSWidth([accessoryView frame]);
    
    if(NSSaveToOperation == docState.currentSaveOperationType){
        savFrame.origin = NSMakePoint(0.0, SAVE_ENCODING_VIEW_OFFSET);
        [saveAccessoryView setFrame:savFrame];
        [exportAccessoryView addSubview:saveAccessoryView];
        accessoryView = exportAccessoryView;
    }else{
        [saveAccessoryView setFrame:savFrame];
        accessoryView = saveAccessoryView;
    }
    [savePanel setAccessoryView:accessoryView];
    
    // set the popup to reflect the document's present string encoding
    [saveTextEncodingPopupButton setEncoding:[self documentStringEncoding]];
    [saveTextEncodingPopupButton setEnabled:YES];
    
    if(NSSaveToOperation == docState.currentSaveOperationType){
        [exportSelectionCheckButton setState:NSOffState];
        [exportSelectionCheckButton setEnabled:[self numberOfSelectedPubs] > 0 || [self hasLibraryGroupSelected] == NO];
    }
    [accessoryView setNeedsDisplay:YES];
    
    return YES;
}

// this is a private method, the action of the file format poup
- (void)changeSaveType:(id)sender{
    NSSet *typesWithEncoding = [NSSet setWithObjects:BDSKBibTeXDocumentType, BDSKRISDocumentType, BDSKMinimalBibTeXDocumentType, BDSKLTBDocumentType, nil];
    NSString *selectedType = [[sender selectedItem] representedObject];
    [saveTextEncodingPopupButton setEnabled:[typesWithEncoding containsObject:selectedType]];
    if ([[self superclass] instancesRespondToSelector:@selector(changeSaveType:)])
        [super changeSaveType:sender];
}

- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
    // Override so we can determine if this is a save, saveAs or export operation, so we can prepare the correct accessory view
    docState.currentSaveOperationType = saveOperation;
    [super runModalSavePanelForSaveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}

- (BOOL)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError{
    
    // Set the string encoding according to the popup.  NB: the popup has the incorrect encoding if it wasn't displayed, so don't reset encoding unless we're actually modifying this document.
    if (NSSaveAsOperation == saveOperation)
        [self setDocumentStringEncoding:[saveTextEncodingPopupButton encoding]];
    
    BOOL success = [super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation error:outError];
    if(success == NO)
        return NO;
    
    if(saveOperation == NSSaveToOperation){
        // write template accessory files if necessary
        BDSKTemplate *selectedTemplate = [BDSKTemplate templateForStyle:typeName];
        if(selectedTemplate){
            NSEnumerator *accessoryFileEnum = [[selectedTemplate accessoryFileURLs] objectEnumerator];
            NSURL *accessoryURL = nil;
            NSURL *destDirURL = [absoluteURL URLByDeletingLastPathComponent];
            while(accessoryURL = [accessoryFileEnum nextObject]){
                [[NSFileManager defaultManager] copyObjectAtURL:accessoryURL toDirectoryAtURL:destDirURL error:NULL];
            }
        }
        
        // save our window setup if we export to BibTeX or RIS
        if([[self class] isNativeType:typeName] || [typeName isEqualToString:BDSKMinimalBibTeXDocumentType])
            [self saveWindowSetupInExtendedAttributesAtURL:absoluteURL forSave:YES];
        
    }else if(saveOperation == NSSaveOperation || saveOperation == NSSaveAsOperation){
        [[BDSKScriptHookManager sharedManager] runScriptHookWithName:BDSKSaveDocumentScriptHookName 
                                                     forPublications:publications
                                                            document:self];
        
        // rebuild metadata cache for this document whenever we save
        NSEnumerator *pubsE = [[self publications] objectEnumerator];
        NSMutableArray *pubsInfo = [[NSMutableArray alloc] initWithCapacity:[publications count]];
        BibItem *anItem;
        NSDictionary *info;
        BOOL update = (saveOperation == NSSaveOperation); // for saveTo we should update all items, as our path changes
        
        while(anItem = [pubsE nextObject]){
            OMNI_POOL_START {
                if(info = [anItem metadataCacheInfoForUpdate:update])
                    [pubsInfo addObject:info];
            } OMNI_POOL_END;
        }
        
        NSDictionary *infoDict = [[NSDictionary alloc] initWithObjectsAndKeys:pubsInfo, @"publications", absoluteURL, @"fileURL", nil];
        [pubsInfo release];
        [[NSApp delegate] rebuildMetadataCache:infoDict];
        [infoDict release];
        
        // save window setup to extended attributes, so it is set also if we use saveAs
        [self saveWindowSetupInExtendedAttributesAtURL:absoluteURL forSave:YES];
    }
    
    return YES;
}

- (BOOL)writeToURL:(NSURL *)absoluteURL 
            ofType:(NSString *)typeName 
  forSaveOperation:(NSSaveOperationType)saveOperation 
originalContentsURL:(NSURL *)absoluteOriginalContentsURL 
             error:(NSError **)outError {
    // Override so we can determine if this is an autosave in writeToURL:ofType:error:.
    // This is necessary on 10.4 to keep from calling the clearChangeCount hack for an autosave, which incorrectly marks the document as clean.
    docState.currentSaveOperationType = saveOperation;
    return [super writeToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation originalContentsURL:absoluteOriginalContentsURL error:outError];
}

- (BOOL)writeToURL:(NSURL *)fileURL ofType:(NSString *)docType error:(NSError **)outError{

    BOOL success = YES;
    NSError *nsError = nil;
    NSArray *items = publications;
    
    if(docState.currentSaveOperationType == NSSaveToOperation && [exportSelectionCheckButton state] == NSOnState)
        items = [self numberOfSelectedPubs] > 0 ? [self selectedPublications] : groupedPublications;
    
    NSFileWrapper *fileWrapper = [self fileWrapperOfType:docType forPublications:items error:&nsError];
    success = nil == fileWrapper ? NO : [fileWrapper writeToFile:[fileURL path] atomically:YES updateFilenames:NO];
    
    // see if this is our error or Apple's
    if (NO == success && [nsError isLocalError]) {
        
        // get offending BibItem if possible
        BibItem *theItem = [nsError valueForKey:BDSKUnderlyingItemErrorKey];
        if (theItem)
            [self selectPublication:theItem];
        
        NSString *errTitle = NSAutosaveOperation == docState.currentSaveOperationType ? NSLocalizedString(@"Unable to autosave file", @"Error description") : NSLocalizedString(@"Unable to save file", @"Error description");
        
        // @@ do this in fileWrapperOfType:forPublications:error:?  should just use error localizedDescription
        NSString *errMsg = [nsError valueForKey:NSLocalizedRecoverySuggestionErrorKey];
        if (nil == errMsg)
            errMsg = NSLocalizedString(@"The underlying cause of this error is unknown.  Please submit a bug report with the file attached.", @"Error informative text");
        
        nsError = [NSError mutableLocalErrorWithCode:kBDSKDocumentSaveError localizedDescription:errTitle underlyingError:nsError];
        [nsError setValue:errMsg forKey:NSLocalizedRecoverySuggestionErrorKey];        
    }
    // needed because of finalize changes; don't send -clearChangeCount if the save failed for any reason, or if we're autosaving!
    else if (docState.currentSaveOperationType != NSAutosaveOperation)
        [self performSelector:@selector(clearChangeCount) withObject:nil afterDelay:0.01];
    
    // setting to nil is okay
    if (outError) *outError = nsError;
    
    return success;
}

- (void)clearChangeCount{
	[self updateChangeCount:NSChangeCleared];
}

#pragma mark Data representations

- (NSFileWrapper *)fileWrapperOfType:(NSString *)aType error:(NSError **)outError
{
    return [self fileWrapperOfType:aType forPublications:publications error:outError];
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)aType forPublications:(NSArray *)items error:(NSError **)outError
{
    // first we make sure all edits are committed
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKFinalizeChangesNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionary]];
    
    NSFileWrapper *fileWrapper = nil;
    
    // check if we need a fileWrapper; only needed for RTFD templates
    BDSKTemplate *selectedTemplate = [BDSKTemplate templateForStyle:aType];
    if([selectedTemplate templateFormat] & BDSKRTFDTemplateFormat){
        fileWrapper = [self fileWrapperForPublications:items usingTemplate:selectedTemplate];
        if(fileWrapper == nil){
            if (outError) 
                *outError = [NSError mutableLocalErrorWithCode:kBDSKDocumentSaveError localizedDescription:NSLocalizedString(@"Unable to create file wrapper for the selected template", @"Error description")];
        }
    }else{
        NSError *error = nil;
        NSData *data = [self dataOfType:aType forPublications:items error:&error];
        if(data != nil && error == nil){
            fileWrapper = [[[NSFileWrapper alloc] initRegularFileWithContents:data] autorelease];
        } else {
            if(outError != NULL)
                *outError = error;
        }
    }
    return fileWrapper;
}

- (NSData *)dataOfType:(NSString *)aType error:(NSError **)outError
{
    return [self dataOfType:aType forPublications:publications error:outError];
}

- (NSData *)dataOfType:(NSString *)aType forPublications:(NSArray *)items error:(NSError **)outError
{
    NSData *data = nil;
    NSError *error = nil;
    NSStringEncoding encoding = [self documentStringEncoding];
    NSParameterAssert(encoding != 0);
    
    // export operations need their own encoding
    if(NSSaveToOperation == docState.currentSaveOperationType)
        encoding = [saveTextEncodingPopupButton encoding];
        
    if ([aType isEqualToString:BDSKBibTeXDocumentType] || [aType isEqualToUTI:[[NSWorkspace sharedWorkspace] UTIForPathExtension:@"bib"]]){
        if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKAutoSortForCrossrefsKey])
            [self performSortForCrossrefs];
        data = [self bibTeXDataForPublications:items encoding:encoding droppingInternal:NO error:&error];
    }else if ([aType isEqualToString:BDSKRISDocumentType] || [aType isEqualToUTI:[[NSWorkspace sharedWorkspace] UTIForPathExtension:@"ris"]]){
        data = [self RISDataForPublications:items encoding:encoding error:&error];
    }else if ([aType isEqualToString:BDSKMinimalBibTeXDocumentType]){
        data = [self bibTeXDataForPublications:items encoding:encoding droppingInternal:YES error:&error];
    }else if ([aType isEqualToString:BDSKLTBDocumentType]){
        data = [self LTBDataForPublications:items encoding:encoding error:&error];
    }else if ([aType isEqualToString:BDSKEndNoteDocumentType]){
        data = [self endNoteDataForPublications:items];
    }else if ([aType isEqualToString:BDSKMODSDocumentType] || [aType isEqualToUTI:[[NSWorkspace sharedWorkspace] UTIForPathExtension:@"mods"]]){
        data = [self MODSDataForPublications:items];
    }else if ([aType isEqualToString:BDSKAtomDocumentType] || [aType isEqualToUTI:[[NSWorkspace sharedWorkspace] UTIForPathExtension:@"atom"]]){
        data = [self atomDataForPublications:items];
    }else{
        BDSKTemplate *selectedTemplate = [BDSKTemplate templateForStyle:aType];
        BDSKTemplateFormat templateFormat = [selectedTemplate templateFormat];
        
        if (templateFormat & BDSKRTFDTemplateFormat) {
            // @@ shouldn't reach here, should have already redirected to fileWrapperOfType:forPublications:error:
        } else if ([selectedTemplate scriptPath] != nil) {
            data = [self dataForPublications:items usingTemplate:selectedTemplate];
        } else if (templateFormat & BDSKTextTemplateFormat) {
            data = [self stringDataForPublications:items usingTemplate:selectedTemplate];
        } else {
            data = [self attributedStringDataForPublications:items usingTemplate:selectedTemplate];
        }
    }
    
    // grab the underlying error; if we recognize it, pass it up as a kBDSKDocumentSaveError
    if(nil == data && outError){
        // see if this was an encoding failure; if so, we can suggest how to fix it
        // NSLocalizedRecoverySuggestion is appropriate for display as error message in alert
        if(kBDSKStringEncodingError == [error code]){
            // encoding conversion failure (string to data)
            NSStringEncoding usedEncoding = [[error valueForKey:NSStringEncodingErrorKey] intValue];
            NSMutableString *message = [NSMutableString stringWithFormat:NSLocalizedString(@"The document cannot be saved using %@ encoding.", @"Error informative text"), [NSString localizedNameOfStringEncoding:usedEncoding]];
            
            [message appendString:@"  "];
            [message appendString:[error valueForKey:NSLocalizedRecoverySuggestionErrorKey]];
            [message appendString:@"  "];
            
            // see if TeX conversion is enabled; it will help for ASCII, and possibly other encodings, but not UTF-8
            if ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShouldTeXifyWhenSavingAndCopyingKey] == NO) {
                [message appendFormat:NSLocalizedString(@"You should enable accented character conversion in the Files preference pane or save using an encoding such as %@.", @"Error informative text"), [NSString localizedNameOfStringEncoding:NSUTF8StringEncoding]];
            } else if (NSUTF8StringEncoding != usedEncoding){
                // could suggest disabling TeX conversion, but the error might be from something out of the range of what we try to convert, so combining TeXify && UTF-8 would work
                [message appendFormat:NSLocalizedString(@"You should save using an encoding such as %@.", @"Error informative text"), [NSString localizedNameOfStringEncoding:NSUTF8StringEncoding]];
            } else {
                // if UTF-8 fails, you're hosed...
                [message appendString:NSLocalizedString(@"Please report this error to BibDesk's developers.", @"Error informative text")];
            }
            
            error = [NSError mutableLocalErrorWithCode:kBDSKDocumentSaveError localizedDescription:NSLocalizedString(@"Unable to save document", @"Error description") underlyingError:error];
            [error setValue:message forKey:NSLocalizedRecoverySuggestionErrorKey];
                        
        } else if(kBDSKTeXifyError == [error code]) {
            NSError *underlyingError = [[error copy] autorelease];
            // TeXification error; this has a specific item
            error = [NSError mutableLocalErrorWithCode:kBDSKDocumentSaveError localizedDescription:NSLocalizedString(@"Unable to save document", @"Error description") underlyingError:underlyingError];
            [error setValue:[underlyingError valueForKey:BDSKUnderlyingItemErrorKey] forKey:BDSKUnderlyingItemErrorKey];
            [error setValue:[NSString stringWithFormat:@"%@  %@", [underlyingError localizedDescription], NSLocalizedString(@"If you are unable to fix this item, you must disable character conversion in BibDesk's preferences and save your file in an encoding such as UTF-8.", @"Error informative text")] forKey:NSLocalizedRecoverySuggestionErrorKey];
        }
        *outError = error;
    }
    
    return data;    
}

- (NSData *)atomDataForPublications:(NSArray *)items{
    NSEnumerator *e = [items objectEnumerator];
	BibItem *pub = nil;
    NSMutableData *d = [NSMutableData data];
    
    [d appendUTF8DataFromString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><feed xmlns=\"http://purl.org/atom/ns#\">"];
    
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);
    
    // TODO: output general feed info
    
	while(pub = [e nextObject]){
        [d appendUTF8DataFromString:@"<entry><title>foo</title><description>foo-2</description>"];
        [d appendUTF8DataFromString:@"<content type=\"application/xml+mods\">"];
        [d appendUTF8DataFromString:[pub MODSString]];
        [d appendUTF8DataFromString:@"</content>"];
        [d appendUTF8DataFromString:@"</entry>\n"];
    }
    [d appendUTF8DataFromString:@"</feed>"];
    
    return d;    
}

- (NSData *)MODSDataForPublications:(NSArray *)items{
    NSEnumerator *e = [items objectEnumerator];
	BibItem *pub = nil;
    NSMutableData *d = [NSMutableData data];
    
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);

    [d appendUTF8DataFromString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><modsCollection xmlns=\"http://www.loc.gov/mods/v3\">"];
	while(pub = [e nextObject]){
        [d appendUTF8DataFromString:[pub MODSString]];
        [d appendUTF8DataFromString:@"\n"];
    }
    [d appendUTF8DataFromString:@"</modsCollection>"];
    
    return d;
}

- (NSData *)endNoteDataForPublications:(NSArray *)items{
    NSMutableData *d = [NSMutableData data];
    
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);
    
    [d appendUTF8DataFromString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<xml>\n<records>\n"];
    [d performSelector:@selector(appendUTF8DataFromString:) withObjectsByMakingObjectsFromArray:items performSelector:@selector(endNoteString)];
    [d appendUTF8DataFromString:@"</records>\n</xml>\n"];
    
    return d;
}

- (NSData *)bibTeXDataForPublications:(NSArray *)items encoding:(NSStringEncoding)encoding droppingInternal:(BOOL)drop error:(NSError **)outError{
    NSParameterAssert(encoding != 0);

    NSEnumerator *e = [items objectEnumerator];
	BibItem *pub = nil;
    NSMutableData *outputData = [NSMutableData dataWithCapacity:4096];
    NSString *tmpString = nil;
    NSError *error = nil;
    BOOL isOK = YES;
        
    BOOL shouldAppendFrontMatter = YES;
    NSString *encodingName = [NSString localizedNameOfStringEncoding:encoding];
    
    NSStringEncoding groupsEncoding = [[BDSKStringEncodingManager sharedEncodingManager] isUnparseableEncoding:encoding] ? encoding : NSUTF8StringEncoding;

    if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShouldUseTemplateFile]){
        NSMutableString *templateFile = [NSMutableString stringWithContentsOfFile:[[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKOutputTemplateFileKey] stringByExpandingTildeInPath]];
        
        [templateFile appendFormat:@"\n%%%% Created for %@ at %@ \n\n", NSFullUserName(), [NSCalendarDate calendarDate]];

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
        
        isOK = [outputData appendDataFromString:templateFile encoding:encoding error:&error];
        if(NO == isOK)
            [error setValue:NSLocalizedString(@"Unable to convert template string.", @"string encoding error context") forKey:NSLocalizedRecoverySuggestionErrorKey];
    }
    
    NSData *doubleNewlineData = [@"\n\n" dataUsingEncoding:encoding];

    // only append this if it wasn't redundant (this assumes that the original frontmatter is either a subset of the necessary frontmatter, or that the user's preferences should override in case of a conflict)
    if(isOK && shouldAppendFrontMatter){
        isOK = [outputData appendDataFromString:frontMatter encoding:encoding error:&error];
        if(NO == isOK)
            [error setValue:NSLocalizedString(@"Unable to convert file header.", @"string encoding error context") forKey:NSLocalizedRecoverySuggestionErrorKey];
        [outputData appendData:doubleNewlineData];
    }
        
    if(isOK && [documentInfo count]){
        isOK = [outputData appendDataFromString:[self documentInfoString] encoding:encoding error:&error];
        if(NO == isOK)
            [error setValue:NSLocalizedString(@"Unable to convert document info.", @"string encoding error context") forKey:NSLocalizedRecoverySuggestionErrorKey];
    }
    
    // output the document's macros:
    if(isOK)
        tmpString = [[self macroResolver] bibTeXStringReturningError:&error];
    isOK = (nil != tmpString) && [outputData appendDataFromString:tmpString encoding:encoding error:&error];
    if(NO == isOK)
        [error setValue:NSLocalizedString(@"Unable to convert macros.", @"string encoding error context") forKey:NSLocalizedRecoverySuggestionErrorKey];
    
    // output the bibs
    
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);

    while(isOK && (pub = [e nextObject])){
        [outputData appendData:doubleNewlineData];
        tmpString = [pub bibTeXStringDroppingInternal:drop error:&error];
        isOK = (nil != tmpString) && [outputData appendDataFromString:tmpString encoding:encoding error:&error];
        if(NO == isOK){
            [error setValue:[NSString stringWithFormat:NSLocalizedString(@"Unable to convert item with cite key %@.", @"string encoding error context"), [pub citeKey]] forKey:NSLocalizedRecoverySuggestionErrorKey];
        }
    }
    
    // The data from groups is always UTF-8, and we shouldn't convert it unless we have an unparseable encoding; the comment key strings should be representable in any encoding
    if(isOK && ([[groups staticGroups] count] > 0)){
        isOK = [outputData appendDataFromString:@"\n\n@comment{BibDesk Static Groups{\n" encoding:encoding error:&error] &&
               [outputData appendStringData:[groups serializedGroupsDataOfType:BDSKStaticGroupType] convertedFromUTF8ToEncoding:groupsEncoding error:&error] &&
               [outputData appendDataFromString:@"}}" encoding:encoding error:&error];
        if(NO == isOK)
            [error setValue:NSLocalizedString(@"Unable to convert static groups.", @"string encoding error context") forKey:NSLocalizedRecoverySuggestionErrorKey];
    }
    if(isOK && ([[groups smartGroups] count] > 0)){
        isOK = [outputData appendDataFromString:@"\n\n@comment{BibDesk Smart Groups{\n" encoding:encoding error:&error] &&
               [outputData appendStringData:[groups serializedGroupsDataOfType:BDSKSmartGroupType] convertedFromUTF8ToEncoding:groupsEncoding error:&error] &&
               [outputData appendDataFromString:@"}}" encoding:encoding error:&error];
            [error setValue:NSLocalizedString(@"Unable to convert smart groups.", @"string encoding error context") forKey:NSLocalizedRecoverySuggestionErrorKey];
    }
    if(isOK && ([[groups URLGroups] count] > 0)){
        isOK = [outputData appendDataFromString:@"\n\n@comment{BibDesk URL Groups{\n" encoding:encoding error:&error] &&
               [outputData appendStringData:[groups serializedGroupsDataOfType:BDSKURLGroupType] convertedFromUTF8ToEncoding:groupsEncoding error:&error] &&
               [outputData appendDataFromString:@"}}" encoding:encoding error:&error];
        if(NO == isOK)
            [error setValue:NSLocalizedString(@"Unable to convert external file groups.", @"string encoding error context") forKey:NSLocalizedRecoverySuggestionErrorKey];
    }
    if(isOK && ([[groups scriptGroups] count] > 0)){
        isOK = [outputData appendDataFromString:@"\n\n@comment{BibDesk Script Groups{\n" encoding:encoding error:&error] &&
               [outputData appendStringData:[groups serializedGroupsDataOfType:BDSKScriptGroupType] convertedFromUTF8ToEncoding:groupsEncoding error:&error] &&
               [outputData appendDataFromString:@"}}" encoding:encoding error:&error];
        if(NO == isOK)
            [error setValue:NSLocalizedString(@"Unable to convert script groups.", @"string encoding error context") forKey:NSLocalizedRecoverySuggestionErrorKey];
    }
    if(isOK)
        [outputData appendDataFromString:@"\n" encoding:encoding error:&error];
        
    if (NO == isOK && outError != NULL) *outError = error;

    return isOK ? outputData : nil;
        
}

- (NSData *)RISDataForPublications:(NSArray *)items encoding:(NSStringEncoding)encoding error:(NSError **)error{

    NSParameterAssert(encoding);
    
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);
    NSString *RISString = [self RISStringForPublications:items];
    NSData *data = [RISString dataUsingEncoding:encoding allowLossyConversion:NO];
    if (nil == data && error) {
        OFErrorWithInfo(error, "BDSKSaveError", NSLocalizedDescriptionKey, [NSString stringWithFormat:NSLocalizedString(@"Unable to convert the bibliography to encoding %@", @"Error description"), [NSString localizedNameOfStringEncoding:encoding]], NSStringEncodingErrorKey, [NSNumber numberWithInt:encoding], nil);
    }
	return data;
}

- (NSData *)LTBDataForPublications:(NSArray *)items encoding:(NSStringEncoding)encoding error:(NSError **)error{

    NSParameterAssert(encoding);
    
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);
    
    NSPasteboard *pboard = [NSPasteboard pasteboardWithUniqueName];
    [pboardHelper declareType:NSStringPboardType dragCopyType:BDSKLTBDragCopyType forItems:items forPasteboard:pboard];
    NSString *ltbString = [pboard stringForType:NSStringPboardType];
    [pboardHelper clearPromisedTypesForPasteboard:pboard];
	if(ltbString == nil){
        if (error) OFErrorWithInfo(error, "BDSKSaveError", NSLocalizedDescriptionKey, NSLocalizedString(@"Unable to run TeX processes for these publications", @"Error description"), nil);
		return nil;
    }
    
    NSMutableString *s = [NSMutableString stringWithString:@"\\documentclass{article}\n\\usepackage{amsrefs}\n\\begin{document}\n\n"];
	[s appendString:ltbString];
	[s appendString:@"\n\\end{document}\n"];
    
    NSData *data = [s dataUsingEncoding:encoding allowLossyConversion:NO];
    if (nil == data && error) {
        OFErrorWithInfo(error, "BDSKSaveError", NSLocalizedDescriptionKey, [NSString stringWithFormat:NSLocalizedString(@"Unable to convert the bibliography to encoding %@", @"Error description"), [NSString localizedNameOfStringEncoding:encoding]], NSStringEncodingErrorKey, [NSNumber numberWithInt:encoding], nil);
    }        
	return data;
}

- (NSData *)stringDataForPublications:(NSArray *)items usingTemplate:(BDSKTemplate *)template{
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);
    
    OBPRECONDITION(nil != template && ([template templateFormat] & BDSKTextTemplateFormat));
    
    NSString *fileTemplate = [BDSKTemplateObjectProxy stringByParsingTemplate:template withObject:self publications:items];
    return [fileTemplate dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
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
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"BDSKDisableExportAttributesKey"]){
        [mutableAttributes addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:NSFullUserName(), NSAuthorDocumentAttribute, [NSDate date], NSCreationTimeDocumentAttribute, [NSLocalizedString(@"BibDesk export of ", @"Error description") stringByAppendingString:[[self fileURL] lastPathComponent]], NSTitleDocumentAttribute, nil]];
    }
    
    if (format & BDSKRTFTemplateFormat) {
        return [fileTemplate RTFFromRange:NSMakeRange(0,[fileTemplate length]) documentAttributes:mutableAttributes];
    } else if (format & BDSKRichHTMLTemplateFormat) {
        [mutableAttributes setObject:NSHTMLTextDocumentType forKey:NSDocumentTypeDocumentAttribute];
        NSError *error = nil;
        return [fileTemplate dataFromRange:NSMakeRange(0,[fileTemplate length]) documentAttributes:mutableAttributes error:&error];
    } else if (format & BDSKDocTemplateFormat) {
        return [fileTemplate docFormatFromRange:NSMakeRange(0,[fileTemplate length]) documentAttributes:mutableAttributes];
    } else return nil;
}

- (NSData *)dataForPublications:(NSArray *)items usingTemplate:(BDSKTemplate *)template{
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);
    
    OBPRECONDITION(nil != template && nil != [template scriptPath]);
    
    NSData *fileTemplate = [BDSKTemplateObjectProxy dataByParsingTemplate:template withObject:self publications:items];
    return fileTemplate;
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

- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)aType error:(NSError **)outError
{
	// first remove all editor windows, as they will be invalid afterwards
    unsigned int index = [[self windowControllers] count];
    while(--index)
        [[[self windowControllers] objectAtIndex:index] close];
    
    if([super revertToContentsOfURL:absoluteURL ofType:aType error:outError]){
        [self setSearchString:@""];
        [self updateSmartGroupsCountAndContent:NO];
        [self updateCategoryGroupsPreservingSelection:YES];
        [self sortGroupsByKey:sortGroupsKey]; // resort
		[tableView deselectAll:self]; // clear before resorting
		[self search:searchField]; // redo the search
        [self sortPubsByKey:nil]; // resort
		return YES;
	}
	return NO;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)aType error:(NSError **)outError
{
    NSStringEncoding encoding = [BDSKStringEncodingManager defaultEncoding];
    return [self readFromURL:absoluteURL ofType:aType encoding:encoding error:outError];
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)aType encoding:(NSStringEncoding)encoding error:(NSError **)outError
{
    BOOL success;
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:absoluteURL options:NSUncachedRead error:&error];
    if (nil == data) {
        if (outError) *outError = error;
        return NO;
    }
    
    // make sure we clear all macros and groups that are saved in the file, should only have those for revert
    // better do this here, so we don't remove them when reading the data fails
    [macroResolver removeAllMacros];
    [groups removeAllNonSharedGroups]; // this also removes spinners and editor windows for external groups
    [frontMatter setString:@""];
    
	if ([aType isEqualToString:BDSKBibTeXDocumentType] || [aType isEqualToUTI:[[NSWorkspace sharedWorkspace] UTIForPathExtension:@"bib"]]){
        success = [self readFromBibTeXData:data fromURL:absoluteURL encoding:encoding error:&error];
    }else if([aType isEqualToString:BDSKRISDocumentType] || [aType isEqualToUTI:[[NSWorkspace sharedWorkspace] UTIForPathExtension:@"ris"]]){
		success = [self readFromData:data ofStringType:BDSKRISStringType fromURL:absoluteURL encoding:encoding error:&error];
    }else{
		// sniff the string to see what format we got
		NSString *string = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
		if(string == nil){
            OFErrorWithInfo(&error, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"Unable To Open Document", @"Error description"), NSLocalizedRecoverySuggestionErrorKey, NSLocalizedString(@"This document does not appear to be a text file.", @"Error informative text"), nil);
            if(outError) *outError = error;
            
            // bypass the partial data warning, since we have no data
			return NO;
        }
        int type = [string contentStringType];
        if(type == BDSKBibTeXStringType){
            success = [self readFromBibTeXData:data fromURL:absoluteURL encoding:encoding error:&error];
		}else if (type == BDSKNoKeyBibTeXStringType){
            OFErrorWithInfo(&error, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"Unable To Open Document", @"Error description"), NSLocalizedRecoverySuggestionErrorKey, NSLocalizedString(@"This file appears to contain invalid BibTeX because of missing cite keys. Try to open using temporary cite keys to fix this.", @"Error informative text"), nil);
            if (outError) *outError = error;
            
            // bypass the partial data warning; we have no data in this case
            return NO;
		}else if (type == BDSKUnknownStringType){
            OFErrorWithInfo(&error, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"Unable To Open Document", @"Error description"), NSLocalizedRecoverySuggestionErrorKey, NSLocalizedString(@"This text file does not contain a recognized data type.", @"Error informative text"), nil);
            if (outError) *outError = error;
            
            // bypass the partial data warning; we have no data in this case
            return NO;
        }else{
            success = [self readFromData:data ofStringType:type fromURL:absoluteURL encoding:encoding error:&error];
        }

	}
    
    // @@ move this to NSDocumentController; need to figure out where to add it, though
    if(success == NO){
        int rv;
        // run a modal dialog asking if we want to use partial data or give up
        rv = NSRunCriticalAlertPanel([error localizedDescription] ? [error localizedDescription] : NSLocalizedString(@"Error reading file!", @"Message in alert dialog when unable to read file"),
                                     [NSString stringWithFormat:NSLocalizedString(@"There was a problem reading the file.  Do you want to give up, edit the file to correct the errors, or keep going with everything that could be analyzed?\n\nIf you choose \"Keep Going\" and then save the file, you will probably lose data.", @"Informative text in alert dialog"), [error localizedDescription]],
                                     NSLocalizedString(@"Give Up", @"Button title"),
                                     NSLocalizedString(@"Edit File", @"Button title"),
                                     NSLocalizedString(@"Keep Going", @"Button title"));
        if (rv == NSAlertDefaultReturn) {
            // the user said to give up
            [[BDSKErrorObjectController sharedErrorObjectController] documentFailedLoad:self shouldEdit:NO]; // this hands the errors to a new error editor and sets that as the documentForErrors
        }else if (rv == NSAlertAlternateReturn){
            // the user said to edit the file.
            [[BDSKErrorObjectController sharedErrorObjectController] documentFailedLoad:self shouldEdit:YES]; // this hands the errors to a new error editor and sets that as the documentForErrors
        }else if(rv == NSAlertOtherReturn){
            // the user said to keep going, so if they save, they might clobber data...
            // if we don't return YES, NSDocumentController puts up its lame alert saying the document could not be opened, and we get no partial data
            success = YES;
        }
    }
    if(outError) *outError = error;
    return success;        
}

- (BOOL)readFromBibTeXData:(NSData *)data fromURL:(NSURL *)absoluteURL encoding:(NSStringEncoding)encoding error:(NSError **)outError {
    NSString *filePath = [absoluteURL path];
    NSStringEncoding parserEncoding = [[BDSKStringEncodingManager sharedEncodingManager] isUnparseableEncoding:encoding] ? NSUTF8StringEncoding : encoding;
    
    [self setDocumentStringEncoding:encoding];
    
    if(parserEncoding != encoding){
        NSString *string = [[NSString alloc] initWithData:data encoding:encoding];
        if([string canBeConvertedToEncoding:NSUTF8StringEncoding]){
            data = [string dataUsingEncoding:NSUTF8StringEncoding];
            filePath = [[NSApp delegate] temporaryFilePath:[filePath lastPathComponent] createDirectory:NO];
            [data writeToFile:filePath atomically:YES];
            [string release];
        }else{
            parserEncoding = encoding;
            NSLog(@"Unable to convert data from encoding %@ to UTF-8", [NSString localizedNameOfStringEncoding:encoding]);
        }
    }
    
    NSError *error = nil;
	NSArray *newPubs = [BibTeXParser itemsFromData:data frontMatter:frontMatter filePath:filePath document:self encoding:parserEncoding error:&error];
	if(outError) *outError = error;	
    [self setPublicationsWithoutUndo:newPubs];
    
    return error == nil;
}

- (BOOL)readFromData:(NSData *)data ofStringType:(int)type fromURL:(NSURL *)absoluteURL encoding:(NSStringEncoding)encoding error:(NSError **)outError {
    
    NSAssert(type == BDSKRISStringType || type == BDSKJSTORStringType || type == BDSKWOSStringType, @"Unknown data type");

    NSError *error = nil;    
    NSString *dataString = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
    NSArray *newPubs = nil;
    
    if(dataString == nil && outError){
        OFErrorWithInfo(&error, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"Unable to Interpret", @"Error description"), NSLocalizedRecoverySuggestionErrorKey, [NSString stringWithFormat:NSLocalizedString(@"Unable to interpret data as %@.  Try a different encoding.", @"Error informative text"), [NSString localizedNameOfStringEncoding:encoding]], NSStringEncodingErrorKey, [NSNumber numberWithInt:encoding], nil);
        *outError = error;
        return NO;
    }
    
	newPubs = [BDSKStringParser itemsFromString:dataString ofType:type error:&error];
        
    if(outError) *outError = error;
    [self setPublicationsWithoutUndo:newPubs];
    
    if (type == BDSKRISStringType) // since we can't save pubmed files as pubmed files:
        [self updateChangeCount:NSChangeDone];
    else // since we can't save other files in its native format
        [self setFileName:nil];
    
    return error == nil;
}

#pragma mark -

- (void)setDocumentStringEncoding:(NSStringEncoding)encoding{
    docState.documentStringEncoding = encoding;
}

- (NSStringEncoding)documentStringEncoding{
    return docState.documentStringEncoding;
}

#pragma mark -

- (void)temporaryCiteKeysAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    NSString *tmpKey = [(NSString *)contextInfo autorelease];
    if(returnCode == NSAlertDefaultReturn){
        NSArray *selItems = [self selectedPublications];
        [self selectPublications:[[self publications] allItemsForCiteKey:tmpKey]];
        [self generateCiteKeysForSelectedPublications];
        [self selectPublications:selItems];
    }
}

- (void)reportTemporaryCiteKeys:(NSString *)tmpKey forNewDocument:(BOOL)isNew{
    if([publications count] == 0)
        return;
    
    NSArray *tmpKeyItems = [[self publications] allItemsForCiteKey:tmpKey];
    
    if([tmpKeyItems count] == 0)
        return;
    
    if(isNew)
        [self selectPublications:tmpKeyItems];
    
    NSString *infoFormat = isNew ? NSLocalizedString(@"This document was opened using the temporary cite key \"%@\" for the selected publications.  In order to use your file with BibTeX, you must generate valid cite keys for all of these items.  Do you want me to do this now?", @"Informative text in alert dialog")
                            : NSLocalizedString(@"New items are added using the temporary cite key \"%@\".  In order to use your file with BibTeX, you must generate valid cite keys for these items.  Do you want me to do this now?", @"Informative text in alert dialog");
    
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Temporary Cite Keys", @"Message in alert dialog when opening a file with temporary cite keys") 
                                     defaultButton:NSLocalizedString(@"Generate", @"Button title") 
                                   alternateButton:NSLocalizedString(@"Don't Generate", @"Button title") 
                                       otherButton:nil
                         informativeTextWithFormat:infoFormat, tmpKey];

    [alert beginSheetModalForWindow:documentWindow
                      modalDelegate:self
                     didEndSelector:@selector(temporaryCiteKeysAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:[tmpKey retain]];
}

#pragma mark -
#pragma mark String representations

- (NSString *)bibTeXStringForPublications:(NSArray *)items{
	return [self bibTeXStringDroppingInternal:NO forPublications:items];
}

- (NSString *)bibTeXStringDroppingInternal:(BOOL)drop forPublications:(NSArray *)items{
    NSMutableString *s = [NSMutableString string];
	NSEnumerator *e = [items objectEnumerator];
	BibItem *pub;
    NSString *bibString = nil;
    NSError *error = nil;
	
    while(pub = [e nextObject]){
        if(bibString = [pub bibTeXStringDroppingInternal:drop error:&error]){
            [s appendString:@"\n"];
            [s appendString:bibString];
            [s appendString:@"\n"];
        } else
            NSLog(@"Discarding texification error for item \"%@\"", [pub citeKey]);
    }
	
	return s;
}

- (NSString *)previewBibTeXStringForPublications:(NSArray *)items{
    
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);

	unsigned numberOfPubs = [items count];
	NSMutableString *bibString = [[NSMutableString alloc] initWithCapacity:(numberOfPubs * 100)];
    NSString *tmpString = nil;
    NSError *error = nil;

	// in case there are @preambles in it
	[bibString appendString:frontMatter];
	[bibString appendString:@"\n"];
	
    tmpString = [[self macroResolver] bibTeXStringReturningError:&error];
    
    if(tmpString != nil)
        [bibString appendString:tmpString];
    else
        NSLog(@"Discarding error \"%@\"", [error description]);
	
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
            if(tmpString = [aPub bibTeXStringReturningError:&error])
                [bibString appendString:tmpString];
            else
                NSLog(@"Discarding error \"%@\" for item \"%@\"", [error description], [aPub citeKey]);
		}
	}
	
	e = [selParentItems objectEnumerator];
	while(aPub = [e nextObject]){
        if(tmpString = [aPub bibTeXStringReturningError:&error])
            [bibString appendString:tmpString];
        else
            NSLog(@"Discarding error \"%@\" for item \"%@\"", [error description], [aPub citeKey]);
	}
	
	e = [parentItems objectEnumerator];        
	while(aPub = [e nextObject]){
        if(tmpString = [aPub bibTeXStringReturningError:&error])
            [bibString appendString:tmpString];
        else
            NSLog(@"Discarding error \"%@\" for item \"%@\"", [error description], [aPub citeKey]);
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

#pragma mark -
#pragma mark New publications from pasteboard

- (void)addPublications:(NSArray *)newPubs publicationsToAutoFile:(NSArray *)pubsToAutoFile temporaryCiteKey:(NSString *)tmpCiteKey selectLibrary:(BOOL)select{
    if (select)
        [self selectLibraryGroup:nil];    
	[self addPublications:newPubs];
    if ([self hasLibraryGroupSelected])
        [self selectPublications:newPubs];
	if (pubsToAutoFile != nil){
        // tried checking [pb isEqual:[NSPasteboard pasteboardWithName:NSDragPboard]] before using delay, but pb is a CFPasteboardUnique
        [pubsToAutoFile makeObjectsPerformSelector:@selector(autoFilePaper)];
    }
    
    // set Date-Added to the current date, since unarchived items will have their own (incorrect) date
    NSCalendarDate *importDate = [NSCalendarDate date];
    [newPubs makeObjectsPerformSelector:@selector(setField:toValue:) withObject:BDSKDateAddedString withObject:[importDate description]];
	
	if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKEditOnPasteKey]) {
		[self editPubCmd:nil]; // this will ask the user when there are many pubs
	}
	
	[[self undoManager] setActionName:NSLocalizedString(@"Add Publication", @"Undo action name")];
    
    // set up the smart group that shows the latest import
    // @@ do this for items added via the editor?  doesn't seem as useful
    [groups setLastImportedPublications:newPubs];
    
    if(tmpCiteKey != nil)
        [self reportTemporaryCiteKeys:tmpCiteKey forNewDocument:NO];
}

- (BOOL)addPublicationsFromPasteboard:(NSPasteboard *)pb selectLibrary:(BOOL)select error:(NSError **)outError{
	// these are the types we support, the order here is important!
    NSString *type = [pb availableTypeFromArray:[NSArray arrayWithObjects:BDSKBibItemPboardType, BDSKWeblocFilePboardType, BDSKReferenceMinerStringPboardType, NSStringPboardType, NSFilenamesPboardType, NSURLPboardType, nil]];
    NSArray *newPubs = nil;
    NSArray *newFilePubs = nil;
	NSError *error = nil;
    NSString *temporaryCiteKey = nil;
    
    if([type isEqualToString:BDSKBibItemPboardType]){
        NSData *pbData = [pb dataForType:BDSKBibItemPboardType];
		newPubs = [self newPublicationsFromArchivedData:pbData];
    } else if([type isEqualToString:BDSKReferenceMinerStringPboardType]){ // pasteboard type from Reference Miner, determined using Pasteboard Peeker
        NSString *pbString = [pb stringForType:BDSKReferenceMinerStringPboardType]; 	
        // sniffing the string for RIS is broken because RefMiner puts junk at the beginning
		newPubs = [self newPublicationsForString:pbString type:BDSKReferenceMinerStringType error:&error];
        if(temporaryCiteKey = [[error userInfo] valueForKey:@"temporaryCiteKey"])
            error = nil; // accept temporary cite keys, but show a warning later
    }else if([type isEqualToString:NSStringPboardType]){
        NSString *pbString = [pb stringForType:NSStringPboardType]; 	
		// sniff the string to see what its type is
		newPubs = [self newPublicationsForString:pbString type:[pbString contentStringType] error:&error];
        if(temporaryCiteKey = [[error userInfo] valueForKey:@"temporaryCiteKey"])
            error = nil; // accept temporary cite keys, but show a warning later
    }else if([type isEqualToString:NSFilenamesPboardType]){
		NSArray *pbArray = [pb propertyListForType:NSFilenamesPboardType]; // we will get an array
        // try this first, in case these files are a type we can open
        NSMutableArray *unparseableFiles = [[NSMutableArray alloc] initWithCapacity:[pbArray count]];
        newPubs = [self extractPublicationsFromFiles:pbArray unparseableFiles:unparseableFiles error:&error];
		if(temporaryCiteKey = [[error userInfo] objectForKey:@"temporaryCiteKey"])
            error = nil; // accept temporary cite keys, but show a warning later
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
        OFErrorWithInfo(&error, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"Did not find anything appropriate on the pasteboard", @"Error description"), nil);
	}
	
    if (newPubs == nil || error != nil){
        if(outError) *outError = error;
		return NO;
    }
    
	if ([newPubs count] > 0) 
		[self addPublications:newPubs publicationsToAutoFile:newFilePubs temporaryCiteKey:temporaryCiteKey selectLibrary:select];
    
    return YES;
}

- (BOOL)addPublicationsFromFile:(NSString *)fileName error:(NSError **)outError{
    NSError *error = nil;
    NSString *temporaryCiteKey = nil;
    NSArray *newPubs = [self extractPublicationsFromFiles:[NSArray arrayWithObject:fileName] unparseableFiles:nil error:&error];
    
    if(temporaryCiteKey = [[error userInfo] valueForKey:@"temporaryCiteKey"])
        error = nil; // accept temporary cite keys, but show a warning later
    
    if([newPubs count] == 0){
        if(outError) *outError = error;
        return NO;
    }
    
    [self addPublications:newPubs publicationsToAutoFile:nil temporaryCiteKey:temporaryCiteKey selectLibrary:YES];
    
    return YES;
}

- (NSArray *)newPublicationsFromArchivedData:(NSData *)data{
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    [BDSKComplexString setMacroResolverForUnarchiving:macroResolver];
    
    NSArray *newPubs = [unarchiver decodeObjectForKey:@"publications"];
    [unarchiver finishDecoding];
    [unarchiver release];
    
    [BDSKComplexString setMacroResolverForUnarchiving:nil];
    
    return newPubs;
}

- (NSArray *)newPublicationsForString:(NSString *)string type:(int)type error:(NSError **)outError {
    NSArray *newPubs = nil;
    NSError *parseError = nil;
    
    if(type == BDSKBibTeXStringType){
        newPubs = [BibTeXParser itemsFromString:string document:self error:&parseError];
    }else if(type == BDSKNoKeyBibTeXStringType){
        newPubs = [BibTeXParser itemsFromString:[string stringWithPhoneyCiteKeys:@"FixMe"] document:self error:&parseError];
	}else if (type != BDSKUnknownStringType){
        newPubs = [BDSKStringParser itemsFromString:string ofType:type error:&parseError];
    }
    
    // The parser methods may return a non-empty array (partial data) if they failed; we check for parseError != nil as an error condition, then, although that's generally not correct
	if(parseError != nil) {

		// run a modal dialog asking if we want to use partial data or give up
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error Reading String", @"Message in alert dialog when failing to parse dropped or copied string")
                                         defaultButton:NSLocalizedString(@"Cancel", @"Button title")
                                       alternateButton:NSLocalizedString(@"Edit data", @"Button title")
                                           otherButton:NSLocalizedString(@"Keep going", @"Button title")
                             informativeTextWithFormat:NSLocalizedString(@"There was a problem inserting the data. Do you want to ignore this data, open a window containing the data to edit it and remove the errors, or keep going and use everything that BibDesk could analyse?\n(It's likely that choosing \"Keep Going\" will lose some data.)", @"Informative text in alert dialog")];
		int rv = [alert runModal];
        
		if(rv == NSAlertDefaultReturn){
			// the user said to give up
			newPubs = nil;
		}else if (rv == NSAlertAlternateReturn){
			// they said to edit the file.
			[[BDSKErrorObjectController sharedErrorObjectController] showEditorForLastPasteDragError];
			newPubs = nil;	
		}else if(rv == NSAlertOtherReturn){
			// the user said to keep going, so if they save, they might clobber data...
		}		
	}else if(type == BDSKNoKeyBibTeXStringType && parseError == nil){

        // return an error when we inserted temporary keys, let the caller decide what to do with it
        // don't override a parseError though, as that is probably more relevant
        OFErrorWithInfo(&parseError, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"Temporary Cite Keys", @"Error description"), @"temporaryCiteKey", @"FixMe", nil);
    }

    // we reach this for unsupported data types (BDSKUnknownStringType)
	if ([newPubs count] == 0 && parseError == nil)
        OFErrorWithInfo(&parseError, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"BibDesk couldn't find bibliography data in this text.", @"Error description"), nil);

	if(outError) *outError = parseError;
    return newPubs;
}

// sniff the contents of each file, returning them in an array of BibItems, while unparseable files are added to the mutable array passed as a parameter
- (NSArray *)extractPublicationsFromFiles:(NSArray *)filenames unparseableFiles:(NSMutableArray *)unparseableFiles error:(NSError **)outError {
    NSEnumerator *e = [filenames objectEnumerator];
    NSString *fileName;
    NSString *contentString;
    NSMutableArray *array = [NSMutableArray array];
    int type = BDSKUnknownStringType;
    
    // some common types that people might use as attachments; we don't need to sniff these
    NSSet *unreadableTypes = [NSSet caseInsensitiveStringSetWithObjects:@"pdf", @"ps", @"eps", @"doc", @"htm", @"textClipping", @"webloc", @"html", @"rtf", @"tiff", @"tif", @"png", @"jpg", @"jpeg", nil];
    
    while(fileName = [e nextObject]){
        type = BDSKUnknownStringType;
        
        // we /can/ create a string from these (usually), but there's no point in wasting the memory
        if([unreadableTypes containsObject:[fileName pathExtension]]){
            [unparseableFiles addObject:fileName];
            continue;
        }
        
        contentString = [[NSString alloc] initWithContentsOfFile:fileName encoding:[self documentStringEncoding] guessEncoding:YES];
        
        if(contentString != nil){
            type = [contentString contentStringType];
    
            if(type >= 0){
                NSError *parseError = nil;
                [array addObjectsFromArray:[self newPublicationsForString:contentString type:type error:&parseError]];
                if(parseError && outError) *outError = parseError;
            } else {
                [contentString release];
                contentString = nil;
            }
        }
        if(contentString == nil || type == BDSKUnknownStringType)
            [unparseableFiles addObject:fileName];
    }

    return array;
}

- (NSArray *)newPublicationsForFiles:(NSArray *)filenames error:(NSError **)error {
    NSMutableArray *newPubs = [NSMutableArray arrayWithCapacity:[filenames count]];
	NSEnumerator *e = [filenames objectEnumerator];
	NSString *fnStr = nil;
	NSURL *url = nil;
    	
	while(fnStr = [e nextObject]){
        fnStr = [fnStr stringByStandardizingPath];
		if(url = [NSURL fileURLWithPath:fnStr]){
            NSError *xerror = nil;
            BibItem *newBI = nil;
            
            if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKReadExtendedAttributesKey]){
                NSData *btData = [[NSFileManager defaultManager] extendedAttributeNamed:OMNI_BUNDLE_IDENTIFIER @".bibtexstring" atPath:fnStr traverseLink:NO error:&xerror];
                if(btData){
                    NSString *btString = [[NSString alloc] initWithData:btData encoding:NSUTF8StringEncoding];
                    newBI = [[BibTeXParser itemsFromString:btString document:self error:&xerror] firstObject];
                    [btString release];
                }
            }
            
            if(newBI == nil && [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShouldUsePDFMetadata])
                newBI = [BibItem itemWithPDFMetadata:[PDFMetadata metadataForURL:url error:&xerror]];
            
            if(newBI == nil)
                newBI = [[[BibItem alloc] init] autorelease];
            
            [newBI setField:BDSKLocalUrlString toValue:[url absoluteString]];
			[newPubs addObject:newBI];
		}
	}
	
	return newPubs;
}

- (NSArray *)newPublicationForURL:(NSURL *)url error:(NSError **)error {
    if(url == nil){
        OFErrorWithInfo(error, BDSKParserError, NSLocalizedDescriptionKey, NSLocalizedString(@"Did not find expected URL on the pasteboard", @"Error description"), nil);
        return nil;
    }
    
	BibItem *newBI = [[[BibItem alloc] init] autorelease];
    
    [newBI setField:BDSKUrlString toValue:[url absoluteString]];
    
	return [NSArray arrayWithObject:newBI];
}

#pragma mark -
#pragma mark BDSKItemPasteboardHelper delegate

- (void)pasteboardHelperWillBeginGenerating:(BDSKItemPasteboardHelper *)helper{
	[self setStatus:[NSLocalizedString(@"Generating data. Please wait", @"Status message when generating drag/paste data") stringByAppendingEllipsis]];
	[statusBar startAnimation:nil];
}

- (void)pasteboardHelperDidEndGenerating:(BDSKItemPasteboardHelper *)helper{
	[statusBar stopAnimation:nil];
	[self updateStatus];
}

- (NSString *)pasteboardHelper:(BDSKItemPasteboardHelper *)pboardHelper bibTeXStringForItems:(NSArray *)items{
    return [self previewBibTeXStringForPublications:items];
}

#pragma mark -
#pragma mark Sorting

- (void)sortPubsByKey:(NSString *)key{
    
    NSTableColumn *tableColumn = nil;
    
    // cache the selection; this works for multiple publications
    NSArray *pubsToSelect = nil;
    if([tableView numberOfSelectedRows])
        pubsToSelect = [self selectedPublications];
    
    // a nil argument means resort the current column in the same order
    if(key == nil){
        if(sortKey == nil)
            return;
        key = sortKey;
        docState.sortDescending = !docState.sortDescending; // we'll reverse this again in the next step
    }
    
    tableColumn = [tableView tableColumnWithIdentifier:key];
    
    if ([sortKey isEqualToString:key]) {
        // User clicked same column, change sort order
        docState.sortDescending = !docState.sortDescending;
    } else {
        // User clicked new column, change old/new column headers,
        // save new sorting selector, and re-sort the array.
        docState.sortDescending = NO;
        if (sortKey)
            [tableView setIndicatorImage:nil inTableColumn:[tableView tableColumnWithIdentifier:sortKey]];
        if([previousSortKey isEqualToString:sortKey] == NO){
            [previousSortKey release];
            previousSortKey = sortKey; // this is retained
        }else{
            [sortKey release];
        }
        sortKey = [key retain];
        [tableView setHighlightedTableColumn:tableColumn]; 
	}
    
    if(previousSortKey == nil)
        previousSortKey = [sortKey retain];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:[BDSKTableSortDescriptor tableSortDescriptorForIdentifier:sortKey ascending:!docState.sortDescending], [BDSKTableSortDescriptor tableSortDescriptorForIdentifier:previousSortKey ascending:!docState.sortDescending], nil];
    [tableView setSortDescriptors:sortDescriptors]; // just using this to store them; it's really a no-op
    

    // @@ DON'T RETURN WITHOUT RESETTING THIS!
    // this is a hack to keep us from getting selection change notifications while sorting (which updates the TeX and attributed text previews)
    [tableView setDelegate:nil];
    
    // sort by new primary column, subsort with previous primary column
    [shownPublications mergeSortUsingDescriptors:sortDescriptors];

    // Set the graphic for the new column header
    [tableView setIndicatorImage: (docState.sortDescending ?
                                   [NSImage imageNamed:@"NSDescendingSortIndicator"] :
                                   [NSImage imageNamed:@"NSAscendingSortIndicator"])
                   inTableColumn: tableColumn];

    // have to reload so the rows get set up right, but a full updateStatus flashes the preview, which is annoying (and the preview won't change if we're maintaining the selection)
    [tableView reloadData];

    // fix the selection
    [self selectPublications:pubsToSelect];
    [tableView scrollRowToCenter:[tableView selectedRow]]; // just go to the last one

    // reset ourself as delegate
    [tableView setDelegate:self];
}

- (void)saveSortOrder{ 
    // @@ if we switch to NSArrayController, we should just archive the sort descriptors (see BDSKFileContentSearchController)
    OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
    [pw setObject:sortKey forKey:BDSKDefaultSortedTableColumnKey];
    [pw setBool:docState.sortDescending forKey:BDSKDefaultSortedTableColumnIsDescendingKey];
    [pw setObject:sortGroupsKey forKey:BDSKSortGroupsKey];
    [pw setBool:docState.sortGroupsDescending forKey:BDSKSortGroupsDescendingKey];    
}  

#pragma mark -
#pragma mark Selection

- (int)numberOfSelectedPubs{
    return [tableView numberOfSelectedRows];
}

- (NSArray *)selectedPublications{

    if(nil == tableView || [tableView selectedRow] == -1)
        return nil;
    
    return [shownPublications objectsAtIndexes:[tableView selectedRowIndexes]];
}

- (BOOL)selectItemsForCiteKeys:(NSArray *)citeKeys selectLibrary:(BOOL)flag {

    // make sure we can see the publication, if it's still in the document
    if (flag)
        [self selectLibraryGroup:nil];
    [tableView deselectAll:self];
    [self setSearchString:@""];

    NSEnumerator *keyEnum = [citeKeys objectEnumerator];
    NSString *key;
    NSMutableArray *itemsToSelect = [NSMutableArray array];
    while (key = [keyEnum nextObject]) {
        BibItem *anItem = [publications itemForCiteKey:key];
        if (anItem)
            [itemsToSelect addObject:anItem];
    }
    [self selectPublications:itemsToSelect];
    return [itemsToSelect count];
}

- (BOOL)selectItemForPartialItem:(NSDictionary *)partialItem{
        
    NSString *itemKey = [partialItem objectForKey:@"net_sourceforge_bibdesk_citekey"];
    if(itemKey == nil)
        itemKey = [partialItem objectForKey:BDSKCiteKeyString];
    
    BOOL matchFound = NO;

    if(itemKey != nil)
        matchFound = [self selectItemsForCiteKeys:[NSArray arrayWithObject:itemKey] selectLibrary:YES];
    
    return matchFound;
}

- (void)selectPublication:(BibItem *)bib{
	[self selectPublications:[NSArray arrayWithObject:bib]];
}

- (void)selectPublications:(NSArray *)bibArray{
    
	NSIndexSet *indexes = [shownPublications indexesOfObjectsIdenticalTo:bibArray];
    
    if([indexes count]){
        [tableView selectRowIndexes:indexes byExtendingSelection:NO];
        [tableView scrollRowToCenter:[indexes firstIndex]];
    }
}

#pragma mark -
#pragma mark Notification handlers

- (void)registerForNotifications{
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        
		[nc addObserver:self
               selector:@selector(handlePreviewDisplayChangedNotification:)
	               name:BDSKPreviewDisplayChangedNotification
                 object:nil];
		[nc addObserver:self
               selector:@selector(handleGroupFieldChangedNotification:)
	               name:BDSKGroupFieldChangedNotification
                 object:self];
		[nc addObserver:self
               selector:@selector(handleGroupFieldAddRemoveNotification:)
	               name:BDSKGroupFieldAddRemoveNotification
                 object:nil];
		[nc addObserver:self
               selector:@selector(handleTableSelectionChangedNotification:)
	               name:BDSKTableSelectionChangedNotification
                 object:self];
		[nc addObserver:self
               selector:@selector(handleGroupTableSelectionChangedNotification:)
	               name:BDSKGroupTableSelectionChangedNotification
                 object:self];
		[nc addObserver:self
               selector:@selector(handleBibItemChangedNotification:)
	               name:BDSKBibItemChangedNotification
                 object:nil];
		[nc addObserver:self
               selector:@selector(handleBibItemAddDelNotification:)
	               name:BDSKDocSetPublicationsNotification
                 object:self];
		[nc addObserver:self
               selector:@selector(handleBibItemAddDelNotification:)
	               name:BDSKDocAddItemNotification
                 object:self];
		[nc addObserver:self
               selector:@selector(handleBibItemAddDelNotification:)
	               name:BDSKDocDelItemNotification
                 object:self];
        [nc addObserver:self
               selector:@selector(handleMacroChangedNotification:)
                   name:BDSKMacroDefinitionChangedNotification
                 object:nil];
        [nc addObserver:self
               selector:@selector(handleFilterChangedNotification:)
                   name:BDSKFilterChangedNotification
                 object:nil];
        [nc addObserver:self
               selector:@selector(handleGroupNameChangedNotification:)
                   name:BDSKGroupNameChangedNotification
                 object:nil];
        [nc addObserver:self
               selector:@selector(handleStaticGroupChangedNotification:)
                   name:BDSKStaticGroupChangedNotification
                 object:nil];
		[nc addObserver:self
               selector:@selector(handleSharedGroupUpdatedNotification:)
	               name:BDSKSharedGroupUpdatedNotification
                 object:nil];
        [nc addObserver:self
               selector:@selector(handleSharedGroupsChangedNotification:)
                   name:BDSKSharedGroupsChangedNotification
                 object:nil];
        [nc addObserver:self
               selector:@selector(handleURLGroupUpdatedNotification:)
                   name:BDSKURLGroupUpdatedNotification
                 object:nil];
        [nc addObserver:self
               selector:@selector(handleScriptGroupUpdatedNotification:)
                   name:BDSKScriptGroupUpdatedNotification
                 object:nil];
        [nc addObserver:self
               selector:@selector(handleWillAddRemoveGroupNotification:)
                   name:BDSKWillAddRemoveGroupNotification
                 object:nil];
        [nc addObserver:self
               selector:@selector(handleDidAddRemoveGroupNotification:)
                   name:BDSKDidAddRemoveGroupNotification
                 object:nil];
        [nc addObserver:self
               selector:@selector(handleFlagsChangedNotification:)
                   name:OAFlagsChangedNotification
                 object:nil];
        [nc addObserver:self
               selector:@selector(handleApplicationWillTerminateNotification:)
                   name:NSApplicationWillTerminateNotification
                 object:nil];
        // observe these two on behalf of our BibItems, or else all BibItems register for these notifications and -[BibItem dealloc] gets expensive when unregistering; this means that (shared) items without a document won't get these notifications
        [nc addObserver:self
               selector:@selector(handleTypeInfoDidChangeNotification:)
                   name:BDSKBibTypeInfoChangedNotification
                 object:[BibTypeManager sharedManager]];
        [nc addObserver:self
               selector:@selector(handleCustomFieldsDidChangeNotification:)
                   name:BDSKDocumentControllerDidChangeMainDocumentNotification
                 object:nil];
        [OFPreference addObserver:self
                         selector:@selector(handleIgnoredSortTermsChangedNotification:)
                    forPreference:[OFPreference preferenceForKey:BDSKIgnoredSortTermsKey]];
        [OFPreference addObserver:self
                         selector:@selector(handleNameDisplayChangedNotification:)
                    forPreference:[OFPreference preferenceForKey:BDSKAuthorNameDisplayKey]];
        [OFPreference addObserver:self
                         selector:@selector(handleTeXPreviewNeedsUpdateNotification:)
                    forPreference:[OFPreference preferenceForKey:BDSKBTStyleKey]];
}

- (void)handlePreviewDisplayChangedNotification:(NSNotification *)notification{
    // note: this is only supposed to handle the pretty-printed preview, /not/ the TeX preview
    [self updatePreviewPane];
}

- (void)handleTeXPreviewNeedsUpdateNotification:(NSNotification *)notification{
    if([previewer isVisible])
        [self updatePreviews];
    else if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKUsesTeXKey] &&
            [[BDSKPreviewer sharedPreviewer] isWindowVisible] &&
            [self isMainDocument])
        [self updatePreviewer:[BDSKPreviewer sharedPreviewer]];
}

- (void)handleBibItemAddDelNotification:(NSNotification *)notification{
    // NB: this method gets called for setPublications: also, so checking for AddItemNotification might not do what you expect
	if([[notification name] isEqualToString:BDSKDocDelItemNotification] == NO)
		[self setSearchString:@""]; // clear the search when adding

    // update smart group counts
    [self updateSmartGroupsCountAndContent:NO];
    // this handles the remaining UI updates necessary (tableView and previews)
	[self updateCategoryGroupsPreservingSelection:YES];
}

- (BOOL)sortKeyDependsOnKey:(NSString *)key{
    if([sortKey isEqualToString:BDSKTitleString])
        return [key isEqualToString:BDSKTitleString] || [key isEqualToString:BDSKChapterString] || [key isEqualToString:BDSKPagesString] || [key isEqualToString:BDSKPubTypeString];
    else if([sortKey isEqualToString:BDSKContainerString])
        return [key isEqualToString:BDSKContainerString] || [key isEqualToString:BDSKJournalString] || [key isEqualToString:BDSKBooktitleString] || [key isEqualToString:BDSKVolumeString] || [key isEqualToString:BDSKSeriesString] || [key isEqualToString:BDSKPubTypeString];
    else if([sortKey isEqualToString:BDSKDateString])
        return [key isEqualToString:BDSKDateString] || [key isEqualToString:BDSKYearString] || [key isEqualToString:BDSKMonthString];
    else if([sortKey isEqualToString:BDSKFirstAuthorString] || [sortKey isEqualToString:BDSKSecondAuthorString] || [sortKey isEqualToString:BDSKThirdAuthorString] || [sortKey isEqualToString:BDSKLastAuthorString])
        return [key isEqualToString:BDSKAuthorString];
    else if([sortKey isEqualToString:BDSKFirstAuthorEditorString] || [sortKey isEqualToString:BDSKSecondAuthorEditorString] || [sortKey isEqualToString:BDSKThirdAuthorEditorString] || [sortKey isEqualToString:BDSKLastAuthorEditorString])
        return [key isEqualToString:BDSKAuthorString] || [key isEqualToString:BDSKEditorString];
    else
        return [sortKey isEqualToString:key];
}

- (void)handlePrivateBibItemChanged:(NSString *)changedKey{
    // we can be called from a queue after the document was closed
    if (docState.isDocumentClosed)
        return;
    
    BOOL isCurrentGroupField = [[self currentGroupField] isEqualToString:changedKey];
    
	[self updateSmartGroupsCountAndContent:isCurrentGroupField == NO];
    
    if(isCurrentGroupField){
        // this handles all UI updates if we call it, so don't bother with any others
        [self updateCategoryGroupsPreservingSelection:YES];
    } else if(![[searchField stringValue] isEqualToString:@""] && 
       ([[searchField searchKey] isEqualToString:changedKey] || [[searchField searchKey] isEqualToString:BDSKAllFieldsString]) ){
        // don't perform a search if the search field is empty
		[self search:searchField];
	} else { 
        // groups and quicksearch won't update for us
        if([self sortKeyDependsOnKey:changedKey])
            [self sortPubsByKey:nil]; // resort if the changed value was in the currently sorted column
        else
            [tableView reloadData];
        [self updateStatus];
        [self updatePreviews];
    }
}

- (void)handleBibItemChangedNotification:(NSNotification *)notification{

	NSDictionary *userInfo = [notification userInfo];
    
    // see if it's ours
	if([userInfo objectForKey:@"owner"] != self)
        return;

	NSString *changedKey = [userInfo objectForKey:@"key"];
    BibItem *pub = [notification object];
    NSString *key = [pub citeKey];
    NSString *oldKey = nil;
    NSEnumerator *pubEnum = [publications objectEnumerator];
    
    // need to handle cite keys and crossrefs if a cite key changed
    if([changedKey isEqualToString:BDSKCiteKeyString]){
        oldKey = [userInfo objectForKey:@"oldCiteKey"];
        [publications changeCiteKey:oldKey toCiteKey:key forItem:pub];
        if([NSString isEmptyString:oldKey])
            oldKey = nil;
    }
    
    while (pub = [pubEnum nextObject]) {
        NSString *crossref = [pub valueOfField:BDSKCrossrefString inherit:NO];
        if([NSString isEmptyString:crossref] == NO)
            continue;
        // invalidate groups that depend on inherited values
        if ([key caseInsensitiveCompare:crossref] == NSOrderedSame)
            [pub invalidateGroupNames];
        // change the crossrefs if we change the parent cite key
        if (oldKey && [oldKey caseInsensitiveCompare:crossref] == NSOrderedSame)
            [pub setField:BDSKCrossrefString toValue:key];
    }
    
    // queue for UI updating, in case the item is changed as part of a batch process such as Find & Replace or AutoFile
    [self queueSelectorOnce:@selector(handlePrivateBibItemChanged:) withObject:changedKey];
}

- (void)handleMacroChangedNotification:(NSNotification *)aNotification{
	id changedOwner = [[aNotification object] owner];
	if(changedOwner && changedOwner != self)
		return; // only macro changes for ourselves or the global macros
	
    [tableView reloadData];
    [self updatePreviews];
}

- (void)handleTableSelectionChangedNotification:(NSNotification *)notification{
    [self updatePreviews];
    [groupTableView updateHighlights];
}

- (void)handleIgnoredSortTermsChangedNotification:(NSNotification *)notification{
    [self sortPubsByKey:nil];
}

- (void)handleNameDisplayChangedNotification:(NSNotification *)notification{
    [tableView reloadData];
    if([currentGroupField isPersonField])
        [groupTableView reloadData];
    [self handlePreviewDisplayChangedNotification:notification];
}

- (void)handleFlagsChangedNotification:(NSNotification *)notification{
    unsigned int modifierFlags = [NSApp currentModifierFlags];
    
    if (modifierFlags & NSAlternateKeyMask) {
        [groupAddButton setImage:[NSImage imageNamed:@"GroupAddSmart"]];
        [groupAddButton setAlternateImage:[NSImage imageNamed:@"GroupAddSmart_Pressed"]];
        [groupAddButton setToolTip:NSLocalizedString(@"Add new smart group.", @"Tool tip message")];
    } else {
        [groupAddButton setImage:[NSImage imageNamed:@"GroupAdd"]];
        [groupAddButton setAlternateImage:[NSImage imageNamed:@"GroupAdd_Pressed"]];
        [groupAddButton setToolTip:NSLocalizedString(@"Add new group.", @"Tool tip message")];
    }
}

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification{
    [self saveSortOrder];
}

- (void)handleTypeInfoDidChangeNotification:(NSNotification *)notification{
    [publications makeObjectsPerformSelector:@selector(typeInfoDidChange:) withObject:notification];
}

- (void)handleCustomFieldsDidChangeNotification:(NSNotification *)notification{
    [publications makeObjectsPerformSelector:@selector(customFieldsDidChange:) withObject:notification];
}

#pragma mark -
#pragma mark Preview updating

- (void)doUpdatePreviews{
    // we can be called from a queue after the document was closed
    if (docState.isDocumentClosed)
        return;

    OBASSERT([NSThread inMainThread]);
    
    //take care of the preview field (NSTextView below the pub table); if the enumerator is nil, the view will get cleared out
    [self updatePreviewPane];
    
    if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKUsesTeXKey] &&
	   [[BDSKPreviewer sharedPreviewer] isWindowVisible] &&
       [self isMainDocument])
        [self updatePreviewer:[BDSKPreviewer sharedPreviewer]];
}

- (void)updatePreviews{
    // Coalesce these messages here, since something like select all -> generate cite keys will force a preview update for every
    // changed key, so we have to update all the previews each time.  This should be safer than using cancelPrevious... since those
    // don't get performed on the main thread (apparently), and can lead to problems.
    if (docState.isDocumentClosed == NO)
        [self queueSelectorOnce:@selector(doUpdatePreviews)];
}

- (void)updatePreviewer:(BDSKPreviewer *)aPreviewer{
    NSArray *items = [self selectedPublications];
    NSString *bibString = [items count] ? [self previewBibTeXStringForPublications:items] : nil;
    [aPreviewer updateWithBibTeXString:bibString];
}

- (void)updatePreviewPane{
    int displayType = [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKPreviewDisplayKey];
    NSView *view = [previewTextView enclosingScrollView];
    
    if(displayType == BDSKPDFPreviewDisplay || displayType == BDSKRTFPreviewDisplay){
        if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKUsesTeXKey] == NO)
            return;
        if(previewer == nil){
            previewer = [[BDSKPreviewer alloc] init];
            NSDictionary *xatrrDefaults = [self mainWindowSetupDictionaryFromExtendedAttributes];
            [previewer setPDFScaleFactor:[xatrrDefaults floatForKey:BDSKPreviewPDFScaleFactorKey defaultValue:0.0]];
            [previewer setRTFScaleFactor:[xatrrDefaults floatForKey:BDSKPreviewRTFScaleFactorKey defaultValue:1.0]];
        }
        view = displayType == BDSKRTFPreviewDisplay ? (NSView *)[[previewer textView] enclosingScrollView] : (NSView *)[previewer pdfView];
        if(currentPreviewView != view){
            [view setFrame:[currentPreviewView frame]];
            [[currentPreviewView superview] replaceSubview:currentPreviewView with:view];
            currentPreviewView = view;
            [[previewer progressOverlay] overlayView:currentPreviewView];
        }
        [self updatePreviewer:previewer];
        return;
    }else if(currentPreviewView != view){
        [[previewer progressOverlay] remove];
        [previewer updateWithBibTeXString:nil];
        [view setFrame:[currentPreviewView frame]];
        [[currentPreviewView superview] replaceSubview:currentPreviewView with:view];
        currentPreviewView = view;
    }

    if(NSIsEmptyRect([previewTextView visibleRect]))
        return;
        
    static NSAttributedString *noAttrDoubleLineFeed;
    if(noAttrDoubleLineFeed == nil)
        noAttrDoubleLineFeed = [[NSAttributedString alloc] initWithString:@"\n\n" attributes:nil];
    
    NSArray *items = [self selectedPublications];
    NSDictionary *bodyAttributes = nil;
    NSDictionary *titleAttributes = nil;
    if (displayType == BDSKNotesPreviewDisplay || displayType == BDSKAbstractPreviewDisplay) {
        NSDictionary *cachedFonts = [[NSFontManager sharedFontManager] cachedFontsForPreviewPane];
        bodyAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[cachedFonts objectForKey:@"Body"], NSFontAttributeName, nil];
        titleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[cachedFonts objectForKey:@"Body"], NSFontAttributeName, [NSNumber numberWithBool:YES], NSUnderlineStyleAttributeName, nil];
    }
  
    unsigned int maxItems = [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKPreviewMaxNumberKey];
    
    if (maxItems > 0 && [items count] > maxItems)
        items = [items subarrayWithRange:NSMakeRange(0, maxItems)];
    
    NSTextStorage *textStorage = [previewTextView textStorage];

    // do this _before_ messing with the text storage; otherwise you can have a leftover selection that ends up being out of range
    NSRange zeroRange = NSMakeRange(0, 0);
    static NSArray *zeroRanges = nil;
    if(!zeroRanges) zeroRanges = [[NSArray alloc] initWithObjects:[NSValue valueWithRange:zeroRange], nil];
    [previewTextView setSelectedRanges:zeroRanges];
            
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
    static NSAttributedString *attributedFormFeed = nil;
    if (nil == attributedFormFeed)
        attributedFormFeed = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%C", NSFormFeedCharacter] attributes:nil];
    
    switch(displayType){
        case BDSKDetailsPreviewDisplay:
            while(pub = [enumerator nextObject]){
                if (isFirst == YES) isFirst = NO;
                else [textStorage appendAttributedString:attributedFormFeed]; // page break for printing; doesn't display
                [textStorage appendAttributedString:[pub attributedStringValue]];
                [textStorage appendAttributedString:noAttrDoubleLineFeed];
            }
            break;
        case BDSKNotesPreviewDisplay:
            while(pub = [enumerator nextObject]){
                // Write out the title
                if(numberOfSelectedPubs > 1){
                    [textStorage appendString:[pub displayTitle] attributes:titleAttributes];
                    [textStorage appendAttributedString:noAttrDoubleLineFeed];
                }
                fieldValue = [pub valueOfField:BDSKAnnoteString inherit:NO];
                if([fieldValue isEqualToString:@""])
                    fieldValue = NSLocalizedString(@"No notes.", @"Preview message when notes are empty");
                [textStorage appendString:fieldValue attributes:bodyAttributes];
                [textStorage appendAttributedString:noAttrDoubleLineFeed];
            }
            break;
        case BDSKAbstractPreviewDisplay:
            while(pub = [enumerator nextObject]){
                // Write out the title
                if(numberOfSelectedPubs > 1){
                    [textStorage appendString:[pub displayTitle] attributes:titleAttributes];
                    [textStorage appendAttributedString:noAttrDoubleLineFeed];
                }
                fieldValue = [pub valueOfField:BDSKAbstractString inherit:NO];
                if([fieldValue isEqualToString:@""])
                    fieldValue = NSLocalizedString(@"No abstract.", @"Preview message when abstract is empty");
                [textStorage appendString:fieldValue attributes:bodyAttributes];
                [textStorage appendAttributedString:noAttrDoubleLineFeed];
            }
            break;
        case BDSKTemplatePreviewDisplay:
            {
            NSString *style = [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKPreviewTemplateStyleKey];
            BDSKTemplate *template = [BDSKTemplate templateForStyle:style];
            if (template == nil)
                template = [BDSKTemplate templateForStyle:[BDSKTemplate defaultStyleNameForFileType:@"rtf"]];
            NSAttributedString *templateString;
            
            // make sure this is really one of the attributed string types...
            if([template templateFormat] & BDSKRichTextTemplateFormat){
                templateString = [BDSKTemplateObjectProxy attributedStringByParsingTemplate:template withObject:self publications:items documentAttributes:NULL];
                [textStorage appendAttributedString:templateString];
            } else if([template templateFormat] & BDSKTextTemplateFormat){
                // parse as plain text, so the HTML is interpreted properly by NSAttributedString
                NSString *str = [BDSKTemplateObjectProxy stringByParsingTemplate:template withObject:self publications:items];
                // we generally assume UTF-8 encoding for all template-related files
                templateString = [[NSAttributedString alloc] initWithHTML:[str dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:NULL];
                [textStorage appendAttributedString:templateString];
                [templateString release];
            }
            }
            break;
    }
    
    [textStorage endEditing];
    [textStorage addLayoutManager:layoutManager];
    [layoutManager release];
    
    if([NSString isEmptyString:[searchField stringValue]] == NO)
        [previewTextView highlightComponentsOfSearchString:[searchField stringValue]];
    
}

#pragma mark -
#pragma mark Status bar

- (void)setStatus:(NSString *)status {
	[self setStatus:status immediate:YES];
}

- (void)setStatus:(NSString *)status immediate:(BOOL)now {
	if(now)
		[statusBar setStringValue:status];
	else
		[statusBar performSelector:@selector(setStringValue:) withObject:status afterDelay:0.01];
}

- (void)updateStatus{
	int shownPubsCount = [shownPublications count];
	int groupPubsCount = [groupedPublications count];
	int totalPubsCount = [publications count];
	NSMutableString *statusStr = [[NSMutableString alloc] init];
	NSString *ofStr = NSLocalizedString(@"of", @"partial status message: [number] of [number] publications");

	if (shownPubsCount != groupPubsCount) { 
		[statusStr appendFormat:@"%i %@ ", shownPubsCount, ofStr];
	}
	[statusStr appendFormat:@"%i %@", groupPubsCount, (groupPubsCount == 1) ? NSLocalizedString(@"publication", @"publication, in status message") : NSLocalizedString(@"publications", @"publications, in status message")];
	// we can have only a single external group selected at a time
    if ([self hasSharedGroupsSelected] == YES) {
        [statusStr appendFormat:@" %@ \"%@\"", NSLocalizedString(@"in shared group", @"Partial status message"), [[[self selectedGroups] lastObject] stringValue]];
	} else if ([self hasURLGroupsSelected] == YES) {
        [statusStr appendFormat:@" %@ \"%@\"", NSLocalizedString(@"in external file group", @"Partial status message"), [[[self selectedGroups] lastObject] stringValue]];
	} else if ([self hasScriptGroupsSelected] == YES) {
        [statusStr appendFormat:@" %@ \"%@\"", NSLocalizedString(@"in script group", @"Partial status message"), [[[self selectedGroups] lastObject] stringValue]];
	} else if ([self hasSearchGroupsSelected] == YES) {
        [statusStr appendFormat:@" %@ \"%@\"", NSLocalizedString(@"in search group", @"Partial status message"), [[[self selectedGroups] lastObject] stringValue]];
	} else if (groupPubsCount != totalPubsCount) {
		NSString *groupStr = ([groupTableView numberOfSelectedRows] == 1) ?
			[NSString stringWithFormat:@"%@ \"%@\"", NSLocalizedString(@"in group", @"Partial status message"), [[[self selectedGroups] lastObject] stringValue]] :
			NSLocalizedString(@"in multiple groups", @"Partial status message");
        [statusStr appendFormat:@" %@ (%@ %i)", groupStr, ofStr, totalPubsCount];
	}
    if ([self hasSearchGroupsSelected] == YES) {
        int matchCount = [[[self selectedGroups] firstObject] numberOfAvailableResults];
        if (matchCount > 0)
            [statusStr appendFormat:NSLocalizedString(@". There were %i matches.", @"Partial status message"), matchCount];
        if (matchCount > groupPubsCount)
            [statusStr appendString:NSLocalizedString(@" Hit \"Search\" to load more.", @"Partial status message")];
    }
	[self setStatus:statusStr];
    [statusStr release];
}

#pragma mark -
#pragma mark Columns Menu

- (NSMenu *)columnsMenu{
    return [tableView columnsMenu];
}

#pragma mark -
#pragma mark Printing support

- (IBAction)printDocument:(id)sender{
    if(BDSKPDFPreviewDisplay == [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKPreviewDisplayKey])
        [[previewer pdfView] printWithInfo:[self printInfo] autoRotate:NO];
    else
        [super printDocument:sender];
}

- (NSView *)printableView{
    int displayType = [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKPreviewDisplayKey];
    if(displayType == BDSKPDFPreviewDisplay){
        // we don't reach this, we let the pdfView do the printing
        return [previewer pdfView]; 
    }else if(displayType == BDSKRTFPreviewDisplay){
        BDSKPrintableView *printableView = [[BDSKPrintableView alloc] initForScreenDisplay:NO];
        [printableView setAttributedString:[[previewer textView] textStorage]];    
        return [printableView autorelease];
    }else{
        BDSKPrintableView *printableView = [[BDSKPrintableView alloc] initForScreenDisplay:NO];
        [printableView setAttributedString:[previewTextView textStorage]];    
        return [printableView autorelease];
    }
}

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError {
    NSPrintInfo *info = [self printInfo];
    [[info dictionary] addEntriesFromDictionary:printSettings];
    return [NSPrintOperation printOperationWithView:[self printableView] printInfo:info];
}

#pragma mark -
#pragma mark Protocols forwarding

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

#pragma mark DisplayName KVO

- (void)setFileURL:(NSURL *)absoluteURL{ 
    // make sure that changes in the displayName are observed, as NSDocument doesn't use a KVC compliant method for setting it
    [self willChangeValueForKey:@"displayName"];
    [super setFileURL:absoluteURL];
    [self didChangeValueForKey:@"displayName"];
}

// just create this setter to avoid a run time warning
- (void)setDisplayName:(NSString *)newName{}

// avoid warning for BDSKOwner protocol conformance
- (NSURL *)fileURL {
    return [super fileURL];
}

- (BOOL)isDocument{
    return YES;
}

@end
