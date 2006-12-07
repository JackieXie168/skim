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

#import "BDSKUndoManager.h"
#import "MultiplePageView.h"
#import "BDSKPrintableView.h"
#import "NSWorkspace_BDSKExtensions.h"
#import "NSFileManager_BDSKExtensions.h"
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
#import "BDSKPreviewer.h"

#import "BDSKTeXTask.h"
#import "BDSKDragTableView.h"
#import "BDSKCustomCiteTableView.h"
#import "BDSKConverter.h"
#import "BibTeXParser.h"
#import "PubMedParser.h"
#import "BDSKJSTORParser.h"
#import "NSString+Templating.h"
#import "BibFiler.h"

#import "ApplicationServices/ApplicationServices.h"
#import "RYZImagePopUpButton.h"
#import "BDSKRatingButton.h"

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
#import "BDSKWebOfScienceParser.h"
#import "NSMutableDictionary+ThreadSafety.h"
#import "NSSet_BDSKExtensions.h"
#import "NSFileManager_ExtendedAttributes.h"
#import "PDFMetadata.h"

NSString *BDSKReferenceMinerStringPboardType = @"CorePasteboardFlavorType 0x57454253";
NSString *BDSKBibItemIndexPboardType = @"edu.ucsd.mmccrack.bibdesk shownPublications index type";
NSString *BDSKBibItemPboardType = @"edu.ucsd.mmccrack.bibdesk BibItem pboard type";


#import <BTParse/btparse.h>

@implementation BibDocument

- (id)init{
    if(self = [super init]){
        publications = [[NSMutableArray alloc] initWithCapacity:1];
        shownPublications = [[NSMutableArray alloc] initWithCapacity:1];
        groupedPublications = [[NSMutableArray alloc] initWithCapacity:1];
        groups = [[NSMutableArray alloc] initWithCapacity:1];
        smartGroups = [[NSMutableArray alloc] initWithCapacity:1];
		allPublicationsGroup = [[BDSKGroup alloc] initWithAllPublications];
		lastImportGroup = nil;
                
        frontMatter = [[NSMutableString alloc] initWithString:@""];
		
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
		
        windowControllers = [[NSMutableArray alloc] initWithCapacity:1];
        
        macroDefinitions = BDSKCreateCaseInsensitiveKeyMutableDictionary();
        
        BDSKUndoManager *newUndoManager = [[[BDSKUndoManager alloc] init] autorelease];
        [newUndoManager setDelegate:self];
        [self setUndoManager:newUndoManager];
		
		itemsForCiteKeys = [[OFMultiValueDictionary alloc] initWithCaseInsensitiveKeys:YES];
		
		promisedPboardTypes = [[NSMutableDictionary alloc] initWithCapacity:2];
		
        // Register as observer of font change events.
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleFontChangedNotification:)
													 name:BDSKTableViewFontChangedNotification
												   object:nil];

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
                                                     name:BDSKBibDocMacroKeyChangedNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleFilterChangedNotification:)
                                                     name:BDSKFilterChangedNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleMacroChangedNotification:)
                                                     name:BDSKBibDocMacroDefinitionChangedNotification
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
        
        [self setDocumentStringEncoding:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKDefaultStringEncodingKey]]; // need to set this for new documents

		sortDescending = NO;
		sortGroupsDescending = NO;
		sortGroupsKey = [BDSKGroupCellStringKey retain];

    }
    return self;
}

- (void)awakeFromNib{
    NSSize drawerSize;
	
	[self setupSearchField];
   
    [tableView setDoubleAction:@selector(editPubCmd:)];
    NSMutableArray *dragTypes = [NSMutableArray arrayWithObjects:BDSKBibItemPboardType, NSStringPboardType, NSFilenamesPboardType, BDSKReferenceMinerStringPboardType, nil];
    [tableView registerForDraggedTypes:[[dragTypes copy] autorelease]];
    [dragTypes addObject:BDSKBibItemIndexPboardType];
    [groupTableView registerForDraggedTypes:dragTypes];

    NSString *filename = [[self fileName] lastPathComponent];
	if (filename == nil) filename = @"";
	[splitView setPositionAutosaveName:@"OASplitView Position Main Window"];
    [groupSplitView setPositionAutosaveName:@"OASplitView Position Group Table"];
    
	[statusBar retain]; // we need to retain, as we might remove it from the window
	if (![[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShowStatusBarKey]) {
		[self toggleStatusBar:nil];
	} else {
		// make sure they are ordered correctly, mainly for the focus ring
		[statusBar removeFromSuperview];
		[[documentWindow contentView]  addSubview:statusBar positioned:NSWindowBelow relativeTo:nil];
	}
	[statusBar setProgressIndicatorStyle:BDSKProgressIndicatorSpinningStyle];

    // workaround for IB flakiness...
    drawerSize = [customCiteDrawer contentSize];
    [customCiteDrawer setContentSize:NSMakeSize(100,drawerSize.height)];

	showingCustomCiteDrawer = NO;
	
    // finally, make sure the font is correct initially:
	[self setTableFont];
	
	// unfortunately we cannot set this in IB
	[actionMenuButton setArrowImage:[NSImage imageNamed:@"ArrowPointingDown"]];
	[actionMenuButton setShowsMenuWhenIconClicked:YES];
	[[actionMenuButton cell] setAltersStateOfSelectedItem:NO];
	[[actionMenuButton cell] setAlwaysUsesFirstItemAsSelected:NO];
	[[actionMenuButton cell] setUsesItemFromMenu:NO];
	[[actionMenuButton cell] setRefreshesMenu:NO];
	
	RYZImagePopUpButton *cornerViewButton = (RYZImagePopUpButton*)[tableView cornerView];
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
    if([headerCell itemWithTitle:currentGroupField])
        [headerCell selectItemWithTitle:currentGroupField];
    else
        [headerCell selectItemAtIndex:0];
	
    [saveTextEncodingPopupButton removeAllItems];
    [saveTextEncodingPopupButton addItemsWithTitles:[[BDSKStringEncodingManager sharedEncodingManager] availableEncodingDisplayedNames]];
    
	[addFieldComboBox setFormatter:[[[BDSKFieldNameFormatter alloc] init] autorelease]];
        
    if([documentWindow respondsToSelector:@selector(setAutorecalculatesKeyViewLoop:)])
        [documentWindow setAutorecalculatesKeyViewLoop:YES];
    
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
        NSAppleEventDescriptor *openEvent = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
        NSString *searchString = [[openEvent descriptorForKeyword:keyAESearchText] stringValue];
        
        if(searchString != nil){
            // We want to handle open events for our Spotlight cache files differently; rather than setting the search field, we can jump to them immediately since they have richer context.  This code gets the path of the document being opened in order to check the file extension.
            NSString *fURLString = [[[openEvent descriptorForKeyword:keyAEResult] coerceToDescriptorType:typeFileURL] stringValue];
            NSURL *fileURL = [(id)CFURLCreateWithFileSystemPath(CFAllocatorGetDefault(), (CFStringRef)fURLString, kCFURLHFSPathStyle, FALSE) autorelease];
            
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
    [self setupToolbar];
    
    // set the frame from prefs first, or setFrameAutosaveName: will overwrite the prefs with the nib values if it returns NO
    [[aController window] setFrameUsingName:@"Main Window Frame Autosave"];
    if([[aController window] setFrameAutosaveName:@"Main Window Frame Autosave"])
        [aController setShouldCascadeWindows:NO];
    
    [documentWindow makeFirstResponder:tableView];	
    [tableView removeAllTableColumns];
	[self setupTableColumns]; // calling it here mostly just makes sure that the menu is set up.
    [self sortPubsByDefaultColumn];
    [self setTableFont];
}

- (void)addWindowController:(NSWindowController *)windowController{
/* ARM:  if the window controller being added to the document's list only has a weak reference to the document (i.e. it doesn't retain its document/data), it needs to be added to the windowControllers ivar, rather than using the NSDocument implementation.  NSDocument assumes that your windowcontrollers retain the document, and this causes problems when we close a doc window while an auxiliary windowcontroller (e.g. BibEditor) is open, since we close those in doc windowWillClose:.  The AppKit allows the document to close, even if it's dirty, since it thinks your other windowcontroller is still hanging around with the data!
    */
    if([windowController window] == documentWindow)
        [super addWindowController:windowController];
    else
        [windowControllers addObject:windowController];
}

- (void)removeWindowController:(NSWindowController *)windowController{
    // see note in addWindowController: override
    if([windowController window] == documentWindow)
        [super removeWindowController:windowController];
    else
        [windowControllers removeObject:windowController];
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
    [macroDefinitions release];
    [itemsForCiteKeys release];
    // set pub document ivars to nil, or we get a crash when they message the undo manager in dealloc (only happens if you edit, click to close the doc, then save)
    [publications makeObjectsPerformSelector:@selector(setDocument:) withObject:nil];
    [publications release];
    [shownPublications release];
    [groupedPublications release];
    [groups release];
    [smartGroups release];
    [allPublicationsGroup release];
    [lastImportGroup release];
    [frontMatter release];
    [quickSearchKey release];
    [customStringArray release];
    [toolbarItems release];
	[statusBar release];
    [windowControllers release];
	[texTask release];
    [macroWC release];
    [promiseDragColumnIdentifier release];
    [lastSelectedColumnForSort release];
    [sortGroupsKey release];
	[promisedPboardTypes release];
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

#pragma mark -
#pragma mark  Document Saving

// if the user is saving in one of our plain text formats, give them an encoding option as well
// this also requires overriding saveToFile:saveOperation:delegate:didSaveSelector:contextInfo:
// to set the document's encoding before writing to the file
- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel{
    if([super prepareSavePanel:savePanel]){
        if([[self fileType] isEqualToString:@"bibTeX database"] || [[self fileType] isEqualToString:@"RIS/Medline File"]){
            NSArray *oldViews = [[[savePanel accessoryView] subviews] retain]; // this should give us the file types popup from super and its label text field
            [savePanel setAccessoryView:SaveEncodingAccessoryView]; // use our accessory view, since we've set the size appropriately in IB
            NSEnumerator *e = [oldViews objectEnumerator];
            NSView *aView = nil;
            while(aView = [e nextObject]){ // now add in the subviews, excluding boxes (the old accessoryView box shouldn't be in the array)
                if(![aView isKindOfClass:[NSBox class]])
                    [[savePanel accessoryView] addSubview:aView];
            }
            if([[savePanel accessoryView] respondsToSelector:@selector(sizeToFit)])
                [(NSBox *)[savePanel accessoryView] sizeToFit]; // this keeps us from truncating the file types popup
            [oldViews release];
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
    if([[self fileType] isEqualToString:@"bibTeX database"] || [[self fileType] isEqualToString:@"RIS/Medline File"])
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
    [self exportAsRSS:nil];
}

- (void)clearChangeCount{
	[self updateChangeCount:NSChangeCleared];
}

- (IBAction)exportAsAtom:(id)sender{
    [self exportAsFileType:@"atom" selected:NO droppingInternal:NO];
}

- (IBAction)exportAsMODS:(id)sender{
    [self exportAsFileType:@"mods" selected:NO droppingInternal:NO];
}

- (IBAction)exportAsHTML:(id)sender{
    [self exportAsFileType:@"html" selected:NO droppingInternal:NO];
}

- (IBAction)exportAsRSS:(id)sender{
    [self exportAsFileType:@"rss" selected:NO droppingInternal:NO];
}

- (IBAction)exportAsEncodedBib:(id)sender{
    [self exportAsFileType:@"bib" selected:NO droppingInternal:NO];
}

- (IBAction)exportAsEncodedPublicBib:(id)sender{
    [self exportAsFileType:@"bib" selected:NO droppingInternal:YES];
}

- (IBAction)exportAsRIS:(id)sender{
    [self exportAsFileType:@"ris" selected:NO droppingInternal:NO];
}

- (IBAction)exportAsLTB:(id)sender{
    [self exportAsFileType:@"ltb" selected:NO droppingInternal:NO];
}

- (IBAction)exportSelectionAsAtom:(id)sender{
    [self exportAsFileType:@"atom" selected:YES droppingInternal:NO];
}

- (IBAction)exportSelectionAsMODS:(id)sender{
    [self exportAsFileType:@"mods" selected:YES droppingInternal:NO];
}

- (IBAction)exportSelectionAsHTML:(id)sender{
    [self exportAsFileType:@"html" selected:YES droppingInternal:NO];
}

- (IBAction)exportSelectionAsRSS:(id)sender{
    [self exportAsFileType:@"rss" selected:YES droppingInternal:NO];
}

- (IBAction)exportSelectionAsEncodedBib:(id)sender{
    [self exportAsFileType:@"bib" selected:YES droppingInternal:NO];
}

- (IBAction)exportSelectionAsEncodedPublicBib:(id)sender{
    [self exportAsFileType:@"bib" selected:YES droppingInternal:YES];
}

- (IBAction)exportSelectionAsRIS:(id)sender{
    [self exportAsFileType:@"ris" selected:YES droppingInternal:NO];
}

- (IBAction)exportSelectionAsLTB:(id)sender{
    [self exportAsFileType:@"ltb" selected:YES droppingInternal:NO];
}

- (void)exportAsFileType:(NSString *)fileType selected:(BOOL)selected droppingInternal:(BOOL)drop{
    NSSavePanel *sp = [NSSavePanel savePanel];
    [sp setRequiredFileType:fileType];
    [sp setDelegate:self];
    if([fileType isEqualToString:@"rss"]){
        [sp setAccessoryView:rssExportAccessoryView];
        // should call a [self setupRSSExportView]; to populate those with saved userdefaults!
    } else {
        if([fileType isEqualToString:@"bib"] || [fileType isEqualToString:@"ris"] || [fileType isEqualToString:@"ltb"]){ // this is for exporting bib files with alternate text encodings
            [sp setAccessoryView:SaveEncodingAccessoryView];
            [saveTextEncodingPopupButton selectItemWithTitle:[[BDSKStringEncodingManager sharedEncodingManager] displayedNameForStringEncoding:[self documentStringEncoding]]];
        }
    }
    NSDictionary *contextInfo = [[NSDictionary dictionaryWithObjectsAndKeys:
		fileType, @"fileType", [NSNumber numberWithBool:drop], @"dropInternal", [NSNumber numberWithBool:selected], @"selected", nil] retain];
	[sp beginSheetForDirectory:nil
                          file:( [self fileName] == nil ? nil : [[NSString stringWithString:[[self fileName] stringByDeletingPathExtension]] lastPathComponent])
                modalForWindow:documentWindow
                 modalDelegate:self
                didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
                   contextInfo:contextInfo];

}

// this is only called by export actions, and isn't part of the regular save process
- (void)savePanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    NSData *fileData = nil;
    NSString *fileName = nil;
    NSSavePanel *sp = (NSSavePanel *)sheet;
    NSDictionary *dict = (NSDictionary *)contextInfo;
	NSString *fileType = [dict objectForKey:@"fileType"];
    BOOL drop = [[dict objectForKey:@"dropInternal"] boolValue];
    BOOL selected = [[dict objectForKey:@"selected"] boolValue];
    NSArray *items = (selected ? [self selectedPublications] : publications);
	
	// first we make sure all edits are committed
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKFinalizeChangesNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionary]];
	
    if(returnCode == NSOKButton){
        fileName = [sp filename];
        if([fileType isEqualToString:@"rss"]){
            fileData = [self rssDataForPublications:items];
        }else if([fileType isEqualToString:@"html"]){
            fileData = [self htmlDataForSelection:selected];
        }else if([fileType isEqualToString:@"mods"]){
            fileData = [self MODSDataForPublications:items];
        }else if([fileType isEqualToString:@"atom"]){
            fileData = [self atomDataForPublications:items];
        }else if([fileType isEqualToString:@"bib"]){            
            NSStringEncoding encoding = [[BDSKStringEncodingManager sharedEncodingManager] stringEncodingForDisplayedName:[saveTextEncodingPopupButton titleOfSelectedItem]];
			if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKAutoSortForCrossrefsKey]){
				[self performSortForCrossrefs];
				items = (selected ? [self selectedPublications] : publications);
			}
            fileData = [self bibTeXDataForPublications:items encoding:encoding droppingInternal:drop];
        }else if([fileType isEqualToString:@"ris"]){
            NSStringEncoding encoding = [[BDSKStringEncodingManager sharedEncodingManager] stringEncodingForDisplayedName:[saveTextEncodingPopupButton titleOfSelectedItem]];
            fileData = [self RISDataForPublications:items encoding:encoding];
        }else if([fileType isEqualToString:@"ltb"]){
            NSStringEncoding encoding = [[BDSKStringEncodingManager sharedEncodingManager] stringEncodingForDisplayedName:[saveTextEncodingPopupButton titleOfSelectedItem]];
            fileData = [self LTBDataForPublications:items encoding:encoding];
        }
        [fileData writeToFile:fileName atomically:YES];
    }
    [sp setRequiredFileType:@"bib"]; // just in case...
    [sp setAccessoryView:nil];
	[dict release];
}

#pragma mark Data representations

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    // first we make sure all edits are committed
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKFinalizeChangesNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionary]];
    NSData *data = nil;
    
    if ([aType isEqualToString:@"bibTeX database"]){
        if([self documentStringEncoding] == 0)
            [NSException raise:@"String encoding exception" format:@"Document does not have a specified string encoding."];
        if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKAutoSortForCrossrefsKey])
            [self performSortForCrossrefs];
        data = [self bibTeXDataForPublications:publications encoding:[self documentStringEncoding] droppingInternal:NO];
    }else if ([aType isEqualToString:@"Rich Site Summary file"]){
        data = [self rssDataForPublications:publications];
    }else if ([aType isEqualToString:@"HTML"]){
        data = [self htmlDataForSelection:NO];
    }else if ([aType isEqualToString:@"MODS"]){
        data = [self MODSDataForPublications:publications];
    }else if ([aType isEqualToString:@"ATOM"]){
        data = [self atomDataForPublications:publications];
    }else if ([aType isEqualToString:@"RIS/Medline File"]){
        data = [self RISDataForPublications:publications];
    }

    return data;
}

#define AddDataFromString(s) [d appendData:[s dataUsingEncoding:NSUTF8StringEncoding]]
#define AddDataFromFormCellWithTag(n) [d appendData:[[[rssExportForm cellAtIndex:[rssExportForm indexOfCellWithTag:n]] stringValue] dataUsingEncoding:NSUTF8StringEncoding]]

- (NSData *)rssDataForPublications:(NSArray *)items{
    NSEnumerator *e = [items objectEnumerator];
    id tmp = nil;
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
        [d appendData:[[tmp RSSValue] dataUsingEncoding:NSUTF8StringEncoding]];
    }
	
    [d appendData:[@"</channel>\n</rss>" dataUsingEncoding:NSUTF8StringEncoding]];
    return d;
}

- (NSData *)htmlDataForSelection:(BOOL)selected{
    NSString *applicationSupportPath = [[NSFileManager defaultManager] currentApplicationSupportPathForCurrentUser]; 
    
	NSString *fileTemplate = nil;
    if (selected) {
		NSMutableString *tmpString = [NSMutableString stringWithContentsOfFile:[applicationSupportPath stringByAppendingPathComponent:@"htmlExportTemplate"]];
		[tmpString replaceOccurrencesOfString:@"<$publicationsAsHTML/>" withString:@"<$selectionAsHTML/>" options:0 range:NSMakeRange(0, [tmpString length])];
		fileTemplate = tmpString;
	} else {
		fileTemplate = [NSString stringWithContentsOfFile:[applicationSupportPath stringByAppendingPathComponent:@"htmlExportTemplate"]];
	}
	fileTemplate = [fileTemplate stringByParsingTagsWithStartDelimeter:@"<$"
                                                          endDelimeter:@"/>" 
                                                           usingObject:self];
    return [fileTemplate dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];    
}

- (NSString *)publicationsAsHTML{
	return [self HTMLStringForPublications:publications];
}

- (NSString *)selectionAsHTML{
	return [self HTMLStringForPublications:[self selectedPublications]];
}

- (NSString *)HTMLStringForPublications:(NSArray *)items{
    NSMutableString *s = [NSMutableString stringWithString:@""];
    NSString *applicationSupportPath = [[[NSFileManager defaultManager] applicationSupportDirectory:kUserDomain] stringByAppendingPathComponent:@"BibDesk"]; 
    NSString *defaultItemTemplate = [NSString stringWithContentsOfFile:[applicationSupportPath stringByAppendingPathComponent:@"htmlItemExportTemplate"]];
    NSString *itemTemplatePath;
    NSString *itemTemplate;
    NSEnumerator *e = [items objectEnumerator];
    BibItem *pub = nil;
    
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);
    
	while(pub = [e nextObject]){

		itemTemplatePath = [applicationSupportPath stringByAppendingFormat:@"/htmlItemExportTemplate-%@", [pub type]];
		if ([[NSFileManager defaultManager] fileExistsAtPath:itemTemplatePath]) {
			itemTemplate = [NSString stringWithContentsOfFile:itemTemplatePath];
		} else {
			itemTemplate = defaultItemTemplate;
        }
		[s appendString:[NSString stringWithString:@"\n\n"]];
        [s appendString:[pub HTMLValueUsingTemplateString:itemTemplate]];
    }
    return s;
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
        
    
    // output the document's macros:
	[d appendData:[[self bibTeXMacroString] dataUsingEncoding:encoding allowLossyConversion:YES]];
    
    // output the bibs
    
    if([items count]) NSParameterAssert([[items objectAtIndex:0] isKindOfClass:[BibItem class]]);

	while(pub = [e nextObject]){
        [d appendData:[[NSString stringWithString:@"\n\n"] dataUsingEncoding:encoding  allowLossyConversion:YES]];
        [d appendData:[[pub bibTeXStringDroppingInternal:drop] dataUsingEncoding:encoding allowLossyConversion:YES]];
    }
	
	if([smartGroups count]> 0){
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
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
    return [self readFromData:data ofType:aType error:NULL];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)aType error:(NSError **)outError {
    
	NSStringEncoding encoding = [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKDefaultStringEncodingKey];
	
	// we set the file type to BibTeX as that retains the complete information in the file
	[self setFileType:@"bibTeX database"];
    BOOL success;
    
    NSError *error = nil;
	if ([aType isEqualToString:@"bibTeX database"]){
        success = [self loadBibTeXDataRepresentation:data encoding:encoding error:&error];
    }else if([aType isEqualToString:@"RIS/Medline File"]){
		success = [self loadRISDataRepresentation:data encoding:encoding error:&error];
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
				success = [self loadBibTeXDataRepresentation:data encoding:encoding error:&error];
                break;
			case BDSKRISStringType:
				success = [self loadRISDataRepresentation:data encoding:encoding error:&error];
                break;
			case BDSKJSTORStringType:
				success = [self loadJSTORDataRepresentation:data encoding:encoding error:&error];
                break;
			case BDSKWOSStringType:
				success = [self loadWebOfScienceDataRepresentation:data encoding:encoding error:&error];
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


- (BOOL)loadRISDataRepresentation:(NSData *)data encoding:(NSStringEncoding)encoding error:(NSError **)outError {
    NSMutableDictionary *dictionary = nil;
    NSString *dataString = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
    NSString* filePath = [self fileName];
    NSMutableArray *newPubs = nil;
    
    if(dataString == nil){
        NSString *encStr = [[BDSKStringEncodingManager sharedEncodingManager] displayedNameForStringEncoding:encoding];
        [NSException raise:BDSKStringEncodingException 
                    format:NSLocalizedString(@"Unable to interpret data as %@.  Try a different encoding.", 
                                             @"need a single NSString format specifier"), encStr];
    }
    
    if(!filePath){
        filePath = @"Untitled Document";
    }
    dictionary = [NSMutableDictionary dictionaryWithCapacity:10];
    
    NSError *error = nil;
	newPubs = [PubMedParser itemsFromString:dataString
                                      error:&error
                                frontMatter:frontMatter
                                   filePath:filePath];
        
    if(outError) *outError = error;
    [self setPublications:newPubs undoable:NO];
    
    // since we can't save pubmed files as pubmed files:
    [self updateChangeCount:NSChangeDone];
    return error == nil;
}


- (BOOL)loadJSTORDataRepresentation:(NSData *)data encoding:(NSStringEncoding)encoding error:(NSError **)outError {
    NSMutableDictionary *dictionary = nil;
    NSString *dataString = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
    NSString* filePath = [self fileName];
    NSMutableArray *newPubs = nil;
    
    if(dataString == nil){
        NSString *encStr = [[BDSKStringEncodingManager sharedEncodingManager] displayedNameForStringEncoding:encoding];
        [NSException raise:BDSKStringEncodingException 
                    format:NSLocalizedString(@"Unable to interpret data as %@.  Try a different encoding.", 
                                             @"need a single NSString format specifier"), encStr];
    }
    
    if(!filePath){
        filePath = @"Untitled Document";
    }
    dictionary = [NSMutableDictionary dictionaryWithCapacity:10];
    
    NSError *error = nil;
	newPubs = [BDSKJSTORParser itemsFromString:dataString
										 error:&error
								   frontMatter:frontMatter
									  filePath:filePath];
    
    [self setPublications:newPubs undoable:NO];
    if(outError) *outError = error;
    
    // since we can't save JSTOR files as JSTOR files:
    [self setFileName:nil];
    
    return error == nil;
}


- (BOOL)loadWebOfScienceDataRepresentation:(NSData *)data encoding:(NSStringEncoding)encoding error:(NSError **)outError {
    NSMutableDictionary *dictionary = nil;
    NSString *dataString = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
    NSString* filePath = [self fileName];
    NSMutableArray *newPubs = nil;
    
    if(dataString == nil){
        NSString *encStr = [[BDSKStringEncodingManager sharedEncodingManager] displayedNameForStringEncoding:encoding];
        [NSException raise:BDSKStringEncodingException 
                    format:NSLocalizedString(@"Unable to interpret data as %@.  Try a different encoding.", 
                                             @"need a single NSString format specifier"), encStr];
    }
    
    if(!filePath){
        filePath = @"Untitled Document";
    }
    dictionary = [NSMutableDictionary dictionaryWithCapacity:10];
    
    NSError *error = nil;
	newPubs = [BDSKWebOfScienceParser itemsFromString:dataString
												error:&error
										  frontMatter:frontMatter
											 filePath:filePath];
    
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

- (BOOL)loadBibTeXDataRepresentation:(NSData *)data encoding:(NSStringEncoding)encoding error:(NSError **)outError {
    NSMutableDictionary *dictionary = nil;
    NSString* filePath = [self fileName];
    NSMutableArray *newPubs;

    if(!filePath){
        filePath = @"Untitled Document";
    }
    dictionary = [NSMutableDictionary dictionaryWithCapacity:10];
    
    [self setDocumentStringEncoding:encoding];

    NSError *error = nil;
	newPubs = [BibTeXParser itemsFromData:data error:&error frontMatter:frontMatter filePath:filePath document:self];
	if(outError) *outError = error;	
    [self setPublications:newPubs undoable:NO];

    return error == nil;
}

#pragma mark -
#pragma mark Publication actions

- (IBAction)newPub:(id)sender{
    [self createNewBlankPubAndEdit:YES];
}

// this method is called for the main table; it's a wrapper for delete or remove from group
- (IBAction)removeSelectedPubs:(id)sender{
	NSArray *selectedGroups = [self selectedGroups];
	
	if([selectedGroups containsObject:allPublicationsGroup]){
		[self deleteSelectedPubs:sender];
	}else{
		BOOL canRemove = NO;
        if ([[[BibTypeManager sharedManager] singleValuedGroupFields] containsObject:[self currentGroupField]] == NO) {
            NSEnumerator *groupEnum = [selectedGroups objectEnumerator];
            BDSKGroup *group;
            while(group = [groupEnum nextObject]){
                if([group isSmart] == NO){
                    canRemove = YES;
                    break;
                }
            }
        }
		if(canRemove == NO){
			NSBeep();
			return;
		}
        // the items may not belong to the groups that you're trying to remove them from, but we'll warn as if they were
        if ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKWarnOnRemovalFromGroupKey]) {
            BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Warning", @"Warning")
                                                 defaultButton:NSLocalizedString(@"Yes", @"OK")
                                               alternateButton:nil
                                                   otherButton:NSLocalizedString(@"No", @"Cancel")
                                     informativeTextWithFormat:NSLocalizedString(@"You are about to remove %i %@ from the %@ \"%@.\"  Do you want to proceed?", @""), [tableView numberOfSelectedRows], ([tableView numberOfSelectedRows] > 1 ? NSLocalizedString(@"items", @"") : NSLocalizedString(@"item",@"")), ([selectedGroups count] > 1 ? NSLocalizedString(@"groups", @"") : NSLocalizedString(@"group",@"")), [[selectedGroups valueForKey:@"stringValue"] componentsJoinedByCommaAndAnd]];
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
	
    if (numSelectedPubs == 0) {
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

    unsigned lastIndex = [[tableView selectedRowIndexes] lastIndex];
	[self removePublications:[self selectedPublications]];
    
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
        pubPath = [pub localURLPath];
        
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
		[self multipleOpenFileSheetDidEnd:nil returnCode:NSAlertAlternateReturn contextInfo:[colID retain]];
    }else if([[BibTypeManager sharedManager] isRemoteURLField:colID]){
		[self multipleOpenURLSheetDidEnd:nil returnCode:NSAlertAlternateReturn contextInfo:[colID retain]];
    }else{
		int n = [self numberOfSelectedPubs];
		if (n > 6) {
			// Do we really want a gazillion of editor windows?
			NSBeginAlertSheet(NSLocalizedString(@"Edit publications", @"Edit publications (multiple open warning)"), 
							  NSLocalizedString(@"No", @"Cancel"), 
							  NSLocalizedString(@"Yes", @"multiple open warning Open button"), 
							  nil, 
							  documentWindow, self, 
							  @selector(multipleEditSheetDidEnd:returnCode:contextInfo:), NULL, 
							  nil, 
							  NSLocalizedString(@"BibDesk is about to open %i editor windows.  Is this really what you want?" , @"multiple editor open warning question"), n);
		} else {
			[self multipleEditSheetDidEnd:nil returnCode:NSAlertAlternateReturn contextInfo:nil];
		}
	}
}

- (void)multipleEditSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	NSEnumerator *e = [[self selectedPublications] objectEnumerator];
	BibItem *pub;
	
	if (returnCode == NSAlertAlternateReturn ) {
		// the user said to go ahead
		while (pub = [e nextObject]) {
			[self editPub:pub];
		}
	}
	// otherwise do nothing
}

//@@ notifications - when adding pub notifications is fully implemented we won't need this.
- (void)editPub:(BibItem *)pub{
    BibEditor *e = nil;
	NSEnumerator *wcEnum = [windowControllers objectEnumerator];
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

- (IBAction)selectAllPublications:(id)sender {
	[tableView selectAll:sender];
}

- (IBAction)deselectAllPublications:(id)sender {
	[tableView deselectAll:sender];
}

- (IBAction)openLinkedFile:(id)sender{
	int n = [self numberOfSelectedPubs];
	NSString *field = [sender representedObject];
    if (field == nil)
		field = BDSKLocalUrlString;
	if (n > 6) {
		// Do we really want a gazillion of files to open?
		NSBeginAlertSheet(NSLocalizedString(@"Open Linked Files", @"Open Linked Files (multiple open warning)"), 
						  NSLocalizedString(@"No", @"No"), 
						  NSLocalizedString(@"Open", @"multiple open warning Open button"), 
						  nil, 
						  documentWindow, self, 
						  @selector(multipleOpenFileSheetDidEnd:returnCode:contextInfo:), NULL, 
						  [field retain], 
						  NSLocalizedString(@"BibDesk is about to open %i linked files. Do you want to proceed?" , @"mulitple open linked files question"), n);
	} else {
		[self multipleOpenFileSheetDidEnd:nil returnCode:NSAlertAlternateReturn contextInfo:[field retain]];
	}
}

-(void)multipleOpenFileSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	NSEnumerator *e = [[self selectedPublications] objectEnumerator];
	BibItem *pub;
	NSString *field = (NSString *)contextInfo;
    
    NSString *searchString;
    // See bug #1344720; don't search if this is a known field (Title, Author, etc.).  This feature can be annoying because Preview.app zooms in on the search result in this case, in spite of your zoom settings (bug report filed with Apple).
    if([quickSearchKey isEqualToString:BDSKKeywordsString] || [quickSearchKey isEqualToString:BDSKAllFieldsString])
        searchString = [searchField stringValue];
    else
        searchString = @"";
    
    NSURL *fileURL;
	
	if (returnCode == NSAlertAlternateReturn ) {
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
	// otherwise do nothing
	[field release];
}

- (IBAction)revealLinkedFile:(id)sender{
	int n = [self numberOfSelectedPubs];
	NSString *field = [sender representedObject];
    if (field == nil)
		field = BDSKLocalUrlString;
	if (n > 6) {
		// Do we really want a gazillion of Finder windows?
		NSBeginAlertSheet(NSLocalizedString(@"Reveal Linked Files", @"Reveal Linked Files (multiple reveal warning)"), 
						  NSLocalizedString(@"No", @"No"), 
						  NSLocalizedString(@"Reveal", @"multiple reveal warning Reveal button"), 
						  nil, 
						  documentWindow, self, 
						  @selector(multipleRevealFileSheetDidEnd:returnCode:contextInfo:), NULL, 
						  [field retain], 
						  NSLocalizedString(@"BibDesk is about to reveal %i linked files. Do you want to proceed?" , @"mulitple reveal linked files question"), n);
	} else {
		[self multipleRevealFileSheetDidEnd:nil returnCode:NSAlertAlternateReturn contextInfo:[field retain]];
	}
}

- (void)multipleRevealFileSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	NSEnumerator *e = [[self selectedPublications] objectEnumerator];
	BibItem *pub;
	NSString *field = (NSString *)contextInfo;
	
	if (returnCode == NSAlertAlternateReturn ) {
		// the user said to go ahead
		while (pub = [e nextObject]) {
			[[NSWorkspace sharedWorkspace]  selectFile:[pub localFilePathForField:field] inFileViewerRootedAtPath:nil];
		}
	}
	// otherwise do nothing
	[field release];
}

- (IBAction)openRemoteURL:(id)sender{
	int n = [self numberOfSelectedPubs];
	NSString *field = [sender representedObject];
    if (field == nil)
		field = BDSKUrlString;
	if (n > 6) {
		// Do we really want a gazillion of Finder windows?
		NSBeginAlertSheet(NSLocalizedString(@"Open Remote URL", @"Open Remote URL (multiple open warning)"), 
						  NSLocalizedString(@"No", @"No"), 
						  NSLocalizedString(@"Open", @"multiple open warning Open button"), 
						  nil, 
						  documentWindow, self, 
						  @selector(multipleOpenURLSheetDidEnd:returnCode:contextInfo:), NULL, 
						  [field retain], 
						  NSLocalizedString(@"BibDesk is about to open %i URLs. Do you want to proceed?" , @"mulitple open URLs question"), n);
	} else {
		[self multipleOpenURLSheetDidEnd:nil returnCode:NSAlertAlternateReturn contextInfo:[field retain]];
	}
}

- (void)multipleOpenURLSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	NSEnumerator *e = [[self selectedPublications] objectEnumerator];
	BibItem *pub;
	NSString *field = (NSString *)contextInfo;
	
	if (returnCode == NSAlertAlternateReturn ) {
		// the user said to go ahead
		while (pub = [e nextObject]) {
			[[NSWorkspace sharedWorkspace] openURL:[pub remoteURLForField:field]];
		}
	}
	// otherwise do nothing
	[field release];
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
		[self removeSmartGroupAction:sender];
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
        [bibString appendString:[self bibTeXMacroString]];
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
				[bibString appendString:[aPub bibTeXStringDroppingInternal:YES]];
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
			[bibString appendString:[aPub bibTeXStringDroppingInternal:YES]];
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
			[bibString appendString:[aPub bibTeXStringDroppingInternal:YES]];
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
		[self numberOfSelectedPubs] == 0) {
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
		if ([group isSmart] == NO && group != allPublicationsGroup)
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
    NSString *type = [pb availableTypeFromArray:[NSArray arrayWithObjects:BDSKBibItemPboardType, BDSKReferenceMinerStringPboardType, NSStringPboardType, NSFilenamesPboardType, nil]];
    NSArray *newPubs = nil;
    NSArray *newFilePubs = nil;
	NSError *error = nil;
    
    if([type isEqualToString:BDSKBibItemPboardType]){
        NSData *pbData = [pb dataForType:BDSKBibItemPboardType];
		newPubs = [NSKeyedUnarchiver unarchiveObjectWithData:pbData];
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
    
    // this will be the start date for our smart group that shows the latest import
    NSDate *addDate = [NSDate dateWithTimeIntervalSinceNow:-1.0];
	
    [groupTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];    
	[self addPublications:newPubs];
	[self highlightBibs:newPubs];
	if (newFilePubs != nil)
		[newFilePubs makeObjectsPerformSelector:@selector(autoFilePaper)];
    
    // set Date-Added to the current date, since unarchived items will have their own (incorrect) date
    NSString *todayDescription = [[NSCalendarDate date] description];
    [newPubs makeObjectsPerformSelector:@selector(setField:toValue:) withObject:BDSKDateCreatedString withObject:todayDescription];
	
	if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKEditOnPasteKey]) {
		[self editPubCmd:nil]; // this will ask the user when there are many pubs
	}
	
	[[self undoManager] setActionName:NSLocalizedString(@"Add Publication",@"")];
    
    // set up the smart group that shows the latest import; we use a +/- 1 second time interval
    // to determine which pubs belong in this group
    // @@ do this for items added via the editor?  doesn't seem as useful
    [self updateLastImportGroupFromDate:addDate toDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    
    return YES;
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
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Type %d is not supported", type];
    }

	if(parseError != nil) {
		// original code follows:
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
        
	}else if([tcID isEqualToString:BDSKDateCreatedString] ||
			 [tcID isEqualToString:@"Added"] ||
			 [tcID isEqualToString:@"Created"]){
		
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"dateCreated" ascending:ascend selector:@selector(compare:)];
        
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
        
	}else if([tcID isEqualToString:BDSKTypeString]){
        
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"type" ascending:ascend selector:@selector(localizedCaseInsensitiveCompare:)];
        
    }else if([tcID isEqualToString:BDSKItemNumberString]){
        
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"fileOrder" ascending:ascend selector:@selector(compare:)];		
        
    }else if([tcID isEqualToString:BDSKBooktitleString]){
        
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"stringCache.Booktitle" ascending:ascend selector:@selector(localizedCompare:)];
        
    }else if([[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKBooleanFieldsKey] containsObject:tcID] ||
             [[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKTriStateFieldsKey] containsObject:tcID] || 
             [[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKRatingFieldsKey] containsObject:tcID]){
        
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
    
    // this is a hack to keep us from getting selection change notifications while sorting (which updates the TeX and attributed text previews)
    [tableView setDelegate:nil];
    
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
    [self setTableFont];
}

- (IBAction)dismissAddFieldSheet:(id)sender{
    [addFieldSheet orderOut:sender];
    [NSApp endSheet:addFieldSheet returnCode:[sender tag]];
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
	OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
	NSArray *prefsShownColNamesArray = [pw arrayForKey:BDSKShownColsNamesKey];
	BibTypeManager *typeMan = [BibTypeManager sharedManager];
	NSMutableSet *fieldNameSet = [NSMutableSet setWithSet:[typeMan allFieldNames]];
	[fieldNameSet unionSet:[NSSet setWithObjects:BDSKCiteKeyString, BDSKDateString, @"Added", @"Modified", BDSKFirstAuthorString, BDSKSecondAuthorString, BDSKThirdAuthorString, BDSKItemNumberString, BDSKContainerString, nil]];
	NSMutableArray *colNames = [[fieldNameSet allObjects] mutableCopy];
	[colNames sortUsingSelector:@selector(caseInsensitiveCompare:)];
	[colNames removeObjectsInArray:prefsShownColNamesArray];
	
	[addFieldComboBox removeAllItems];
	[addFieldComboBox addItemsWithObjectValues:colNames];
    [addFieldPrompt setStringValue:NSLocalizedString(@"Name of column to add:",@"")];
	
	[colNames release];
    
	[NSApp beginSheet:addFieldSheet
       modalForWindow:documentWindow
        modalDelegate:self
       didEndSelector:@selector(addTableColumnSheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
    
}

- (void)addTableColumnSheetDidEnd:(NSWindow *)sheet
                       returnCode:(int) returnCode
                      contextInfo:(void *)contextInfo{

    if(returnCode == 1){
		NSMutableArray *prefsShownColNamesMutableArray = [[[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKShownColsNamesKey] mutableCopy] autorelease];
        NSString *newColumnName = [addFieldComboBox stringValue];

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
    }else{
        //do nothing (because nothing was entered or selected)
    }
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
		myMenu = [smartGroupMenu copy];
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

- (void)handleFontChangedNotification:(NSNotification *)notification{
	[self setTableFont];
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

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification{
    [self saveSortOrder];
}

#pragma mark UI updating

- (void)handlePrivateUpdatePreviews{

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
    [self queueSelectorOnce:@selector(handlePrivateUpdatePreviews)];
}

- (void)displayPreviewForItems:(NSArray *)items{

    if(NSIsEmptyRect([previewField visibleRect]))
        return;
        
    static NSDictionary *titleAttributes;
    if(titleAttributes == nil)
        titleAttributes = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:1], nil]
                                                        forKeys:[NSArray arrayWithObjects:NSUnderlineStyleAttributeName,  nil]];
    static NSAttributedString *noAttrDoubleLineFeed;
    if(noAttrDoubleLineFeed == nil)
        noAttrDoubleLineFeed = [[NSAttributedString alloc] initWithString:@"\n\n" attributes:nil];
    
    NSMutableAttributedString *s;
  
    int maxItems = [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKPreviewMaxNumberKey];
    int itemCount = 0;
    
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
    
    NSEnumerator *enumerator = [items objectEnumerator];
    
    unsigned int numberOfSelectedPubs = [items count];
    BibItem *pub = nil;

    while((pub = [enumerator nextObject]) && (maxItems == 0 || itemCount < maxItems)){
                
		itemCount++;
        NSString *fieldValue;

        switch([[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKPreviewDisplayKey]){
            case 0:                
                if(itemCount > 1)
                    [[textStorage mutableString] appendCharacter:NSFormFeedCharacter]; // page break for printing; doesn't display
                [textStorage appendAttributedString:[pub attributedStringValue]];
                break;
            case 1:
                // special handling for annote-only
                // Write out the title
                if(numberOfSelectedPubs > 1){
                    s = [[[NSMutableAttributedString alloc] initWithString:[pub displayTitle]
                                                               attributes:titleAttributes] autorelease];
                    [s appendAttributedString:noAttrDoubleLineFeed];
                    [textStorage appendAttributedString:s];
                }
                fieldValue = [pub valueOfField:BDSKAnnoteString inherit:NO];
                if([fieldValue isEqualToString:@""]){
                    [[textStorage mutableString] appendString:NSLocalizedString(@"No notes.",@"")];
                }else{
                    [[textStorage mutableString] appendString:fieldValue];
                }
                break;
            case 2:
                // special handling for abstract-only
                // Write out the title
                if(numberOfSelectedPubs > 1){
                    s = [[[NSMutableAttributedString alloc] initWithString:[pub displayTitle]
                                                                attributes:titleAttributes] autorelease];
                    [s appendAttributedString:noAttrDoubleLineFeed];
                    [textStorage appendAttributedString:s];
                }
                fieldValue = [pub valueOfField:BDSKAbstractString inherit:NO];
                if([fieldValue isEqualToString:@""]){
                    [[textStorage mutableString] appendString:NSLocalizedString(@"No abstract.",@"")];
                }else{
                    [[textStorage mutableString] appendString:fieldValue];
                }
                break;                
        }
        [[textStorage mutableString] appendString:@"\n\n"];
        
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
	if (groupPubsCount != totalPubsCount) { 
		NSString *groupStr = ([groupTableView numberOfSelectedRows] == 1) ?
			[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"group", @"group"), [[[self selectedGroups] lastObject] stringValue]] :
			NSLocalizedString(@"multiple groups", @"multiple groups");
		[statusStr appendFormat:@" %@ %@ (%@ %i)", NSLocalizedString(@"in", @"in"), groupStr, ofStr, totalPubsCount];
	}
	[self setStatus:statusStr];
    [statusStr release];
}

- (void)setTableFont{
    // The font we're using now
    NSFont *font = [NSFont fontWithName:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKTableViewFontKey]
                                   size:[[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKTableViewFontSizeKey]];
	
	[tableView setFont:font];
    
    NSLayoutManager *lm = [[NSLayoutManager alloc] init];
    [tableView setRowHeight:([lm defaultLineHeightForFont:font] + 2.0f)];
    [lm release];
    
	[tableView tile];
    [tableView reloadData]; // othewise the change isn't immediately visible
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

- (IBAction)toggleStatusBar:(id)sender{
	[statusBar toggleBelowView:groupSplitView offset:1.0];
	[[OFPreferenceWrapper sharedPreferenceWrapper] setBool:[statusBar isVisible] forKey:BDSKShowStatusBarKey];
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
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:[lastSelectedColumnForSort identifier] forKey:BDSKDefaultSortedTableColumnKey];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setBool:sortDescending forKey:BDSKDefaultSortedTableColumnIsDescendingKey];
}  

- (void)windowWillClose:(NSNotification *)notification{

    if([notification object] != documentWindow) // this is critical; 
        return;
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocumentWindowWillCloseNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionary]];
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

- (NSDictionary *)macroDefinitions {
    return macroDefinitions;
}

- (void)setMacroDefinitions:(NSDictionary *)newMacroDefinitions {
    if (macroDefinitions != newMacroDefinitions) {
        [macroDefinitions release];
        macroDefinitions = BDSKCreateCaseInsensitiveKeyMutableDictionary();
        [macroDefinitions setDictionary:newMacroDefinitions];
    }
}

- (void)addMacroDefinitionWithoutUndo:(NSString *)macroString forMacro:(NSString *)macroKey{
    [macroDefinitions setObject:macroString forKey:macroKey];
}

- (void)changeMacroKey:(NSString *)oldKey to:(NSString *)newKey{
    if([macroDefinitions objectForKey:oldKey] == nil)
        [NSException raise:NSInvalidArgumentException
                    format:@"tried to change the value of a macro key that doesn't exist"];
    [[[self undoManager] prepareWithInvocationTarget:self]
        changeMacroKey:newKey to:oldKey];
    NSString *val = [macroDefinitions valueForKey:oldKey];
    [val retain]; // so the next line doesn't kill it
    [macroDefinitions removeObjectForKey:oldKey];
    [macroDefinitions setObject:[val autorelease] forKey:newKey];
	
	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:newKey, @"newKey", oldKey, @"oldKey", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibDocMacroKeyChangedNotification
														object:self
													  userInfo:notifInfo];    
}

- (void)addMacroDefinition:(NSString *)macroString forMacro:(NSString *)macroKey{
    // we're adding a new one, so to undo, we remove.
    [[[self undoManager] prepareWithInvocationTarget:self]
            removeMacro:macroKey];

    [macroDefinitions setObject:macroString forKey:macroKey];
	
	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:macroKey, @"macroKey", @"Add macro", @"type", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibDocMacroDefinitionChangedNotification
														object:self
													  userInfo:notifInfo];    
}

- (void)setMacroDefinition:(NSString *)newDefinition forMacro:(NSString *)macroKey{
    NSString *oldDef = [macroDefinitions objectForKey:macroKey];
    // we're just changing an existing one, so to undo, we change back.
    [[[self undoManager] prepareWithInvocationTarget:self]
            setMacroDefinition:oldDef forMacro:macroKey];
    [macroDefinitions setObject:newDefinition forKey:macroKey];

	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:macroKey, @"macroKey", @"Change macro", @"type", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibDocMacroDefinitionChangedNotification
														object:self
													  userInfo:notifInfo];    
}


- (void)removeMacro:(NSString *)macroKey{
    NSString *currentValue = [macroDefinitions objectForKey:macroKey];
    if(!currentValue){
        return;
    }else{
        [[[self undoManager] prepareWithInvocationTarget:self]
        addMacroDefinition:currentValue
                  forMacro:macroKey];
    }
    [macroDefinitions removeObjectForKey:macroKey];
	
	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:macroKey, @"macroKey", @"Remove macro", @"type", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibDocMacroDefinitionChangedNotification
														object:self
													  userInfo:notifInfo];    
}

- (NSString *)valueOfMacro:(NSString *)macroString{
    // Note we treat upper and lowercase values the same, 
    // because that's how btparse gives the string constants to us.
    // It is not quite correct because bibtex does discriminate,
    // but this is the best we can do.  The OFCreateCaseInsensitiveKeyMutableDictionary()
    // is used to create a dictionary with case-insensitive keys.
    return [macroDefinitions objectForKey:macroString];
}

- (NSString *)bibTeXMacroString{
    BOOL shouldTeXify = [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShouldTeXifyWhenSavingAndCopyingKey];
	NSMutableString *macroString = [NSMutableString string];
    NSString *value;
    NSArray *macros = [[macroDefinitions allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    foreach(macro, macros){
		value = [macroDefinitions objectForKey:macro];
		if(shouldTeXify){
			
			@try{
				value = [[BDSKConverter sharedConverter] stringByTeXifyingString:value];
			}
            @catch(id localException){
				if([localException isKindOfClass:[NSException class]] && [[localException name] isEqualToString:BDSKTeXifyException]){
                    NSException *exception = [NSException exceptionWithName:BDSKTeXifyException reason:[NSString stringWithFormat:NSLocalizedString(@"Character \"%@\" in the macro %@ can't be converted to TeX.", @"character conversion warning"), [localException reason], macro] userInfo:[NSDictionary dictionary]];
                    @throw exception;
				} else 
                    @throw;
            }							
		}                
        [macroString appendFormat:@"\n@STRING{%@ = \"%@\"}\n", macro, value];
    }
	return macroString;
}

- (IBAction)showMacrosWindow:(id)sender{
    if (!macroWC){
        macroWC = [[MacroWindowController alloc] init];
        [macroWC setMacroDataSource:self];
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
	if (numberOfSelectedPubs == 0) return;
	
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
    countOfItems = [pubsToRemove count];
    CFIndex idx = countOfItems;
    
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
	itemsForCiteKeys = [[OFMultiValueDictionary alloc] initWithCaseInsensitiveKeys:YES];
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

- (IBAction)selectCrossrefParentAction:(id)sender{
    BibItem *selectedBI = [[self selectedPublications] lastObject];
    NSString *crossref = [selectedBI valueOfField:BDSKCrossrefString inherit:NO];
    [tableView deselectAll:nil];
    BibItem *parent = [self publicationForCiteKey:crossref];
    if(crossref && parent){
        [self highlightBib:parent];
        [tableView scrollRowToVisible:[tableView selectedRow]];
    } else
        NSBeep(); // if no parent found
}

- (IBAction)createNewPubUsingCrossrefAction:(id)sender{
    BibItem *selectedBI = [[self selectedPublications] lastObject];
    BibItem *newBI = [[BibItem alloc] init];
	NSString *parentType = [selectedBI type];
    
	[newBI setField:BDSKCrossrefString toValue:[selectedBI citeKey]];
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

- (IBAction)duplicateTitleToBooktitle:(id)sender{
	if ([self numberOfSelectedPubs] == 0) return;
	
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

    // first we make sure all edits are committed
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKFinalizeChangesNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionary]];

	[[BibFiler sharedFiler] filePapers:[self selectedPublications] fromDocument:self ask:YES];
	
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

- (void)setFileName:(NSString *)fileName{ 
    // make sure that changes in the displayName are observed, as NSDocument doesn't use a KVC compliant method for setting it
    [self willChangeValueForKey:@"displayName"];
    [super setFileName:fileName];
    [self didChangeValueForKey:@"displayName"];
}

// just create this setter to avoid a run time warning
- (void)setDisplayName:(NSString *)newName{}

@end
