//  BibEditor.m

//  Created by Michael McCracken on Mon Dec 24 2001.
/*
 This software is Copyright (c) 2001,2002,2003,2004,2005
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


#import "BibEditor.h"
#import "BibEditor_Toolbar.h"
#import "BibDocument.h"
#import <OmniAppKit/NSScrollView-OAExtensions.h>
#import <OmniFoundation/NSString-OFExtensions.h>
#import "BDAlias.h"
#import "NSImage+Toolbox.h"
#import "BDSKComplexString.h"

#ifdef BDSK_USING_TIGER
#import "BDSKZoomablePDFView.h"
#endif

enum{
	BDSKDrawerUnknownState = -1,
	BDSKDrawerStateOpenMask = 1,
	BDSKDrawerStateRightMask = 2,
	BDSKDrawerStateWebMask = 4,
	BDSKDrawerStateTextMask = 8
};

@implementation BibEditor

- (NSString *)windowNibName{
    return @"BibEditor";
}


- (id)initWithBibItem:(BibItem *)aBib document:(BibDocument *)doc{
    self = [super initWithWindowNibName:@"BibEditor"];
    fieldNumbers = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
    citeKeyFormatter = [[BDSKCiteKeyFormatter alloc] init];
    fieldNameFormatter = [[BDSKFieldNameFormatter alloc] init];
	
    theBib = aBib;
    [theBib setEditorObj:self];
    currentType = [[theBib type] retain];    // do this once in init so it's right at the start.
                                    // has to be before we call [self window] because that calls windowDidLoad:.
    theDocument = doc; // don't retain - it retains us.
	pdfSnoopViewLoaded = NO;
	textSnoopViewLoaded = NO;
	webSnoopViewLoaded = NO;
	drawerState = BDSKDrawerUnknownState;
	
	showStatus = YES;
	
	forceEndEditing = NO;
    didSetupForm = NO;
	
    // this should probably be moved around.
    [[self window] setTitle:[theBib title]];
    [[self window] setDelegate:self];
    [[self window] registerForDraggedTypes:[NSArray arrayWithObjects:
            NSStringPboardType, NSFilenamesPboardType, nil]];					
    macroTextFieldWC = [[MacroTextFieldWindowController alloc] init];
    
    notesViewUndoManager = [[NSUndoManager alloc] init];
    abstractViewUndoManager = [[NSUndoManager alloc] init];
    rssDescriptionViewUndoManager = [[NSUndoManager alloc] init];

#if DEBUG
    NSLog(@"BibEditor alloc");
#endif
    return self;
}

- (void)windowDidLoad{
	[self setCiteKeyDuplicateWarning:![self citeKeyIsValid:[theBib citeKey]]];
    [self fixURLs];
}


- (BibItem *)currentBib{
    return theBib;
}

- (void)setupForm{
    static NSFont *requiredFont = nil;
    if(!requiredFont){
        requiredFont = [NSFont systemFontOfSize:13.0];
        [[NSFontManager sharedFontManager] convertFont:requiredFont
                                           toHaveTrait:NSBoldFontMask];
    }
    
    BibAppController *appController = (BibAppController *)[NSApp delegate];
    NSString *tmp;
    NSFormCell *entry;
    NSArray *sKeys;
    int i=0;
    int numRows;
    NSRect rect = [bibFields frame];
    NSPoint origin = rect.origin;
	NSEnumerator *e;

	NSArray *keysNotInForm = [[NSArray alloc] initWithObjects: BDSKAnnoteString, BDSKAbstractString, BDSKRssDescriptionString, BDSKDateCreatedString, BDSKDateModifiedString, nil];

    NSDictionary *reqAtt = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:[NSColor redColor],nil]
                                                         forKeys:[NSArray arrayWithObjects:NSForegroundColorAttributeName,nil]];
	
	// set up for adding all items 
    // remove all items in the NSForm
    [bibFields removeAllEntries];

    // make two passes to get the required entries at top.
    i=0;
    sKeys = [[[theBib pubFields] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    NSMutableSet *addedFields = [[NSMutableSet alloc] initWithCapacity:5];
    e = [[[BibTypeManager sharedManager] requiredFieldsForType:[theBib type]] objectEnumerator];

    while(tmp = [e nextObject]){
        if (![keysNotInForm containsObject:tmp]){
            entry = [bibFields insertEntry:tmp usingTitleFont:requiredFont attributesForTitle:reqAtt indexAndTag:i objectValue:[theBib valueOfField:tmp]];
            
            // Autocompletion stuff
            [entry setFormatter:[appController formatterForEntry:tmp]];

            //[entry setTitleAlignment:NSRightTextAlignment]; this doesn't work...
            i++;

            [addedFields addObject:tmp];
        }
    }

    // now, we add the optional fields in the order they came in the config file.
    
    e = [[[BibTypeManager sharedManager] optionalFieldsForType:[theBib type]] objectEnumerator];
    
    while(tmp = [e nextObject]){
        if(![keysNotInForm containsObject:tmp]){
            entry = [bibFields insertEntry:tmp usingTitleFont:nil attributesForTitle:nil indexAndTag:i objectValue:[theBib valueOfField:tmp]];
            
            [entry setTitleAlignment:NSLeftTextAlignment];
            
            // Autocompletion stuff
			[entry setFormatter:[appController formatterForEntry:tmp]];

            i++;
            [addedFields addObject:tmp];
        }
        
    }
    
    // now add any remaining fields at the end. 
    // (Note: should we add remaining fields after required fields on 
    // the assumption that they're important since the user added them?)
    
    e = [sKeys objectEnumerator];
    while(tmp = [e nextObject]){
        if(![addedFields containsObject:tmp] && ![keysNotInForm containsObject:tmp]){
            
            entry = [bibFields insertEntry:tmp usingTitleFont:nil attributesForTitle:nil indexAndTag:i objectValue:[theBib valueOfField:tmp]];

            [entry setTitleAlignment:NSLeftTextAlignment];
            
            if([tmp isEqualToString:BDSKCrossrefString])
                [entry setFormatter:[citeKeyField formatter]]; // crossref field needs a citekey formatter
            else
                [entry setFormatter:[appController formatterForEntry:tmp]]; // for autocompletion

            i++;
        }
    }
    
    [keysNotInForm release];
    [reqAtt release];
    [addedFields release];
    
    [bibFields sizeToFit];
    
    [bibFields setFrameOrigin:origin];
    [bibFields setNeedsDisplay:YES];
    didSetupForm = YES;
    
}

- (void)setupTypePopUp{
    NSEnumerator *typeNamesE = [[[BibTypeManager sharedManager] bibTypesForFileType:[theBib fileType]] objectEnumerator];
    NSString *typeName = nil;

    [bibTypeButton removeAllItems];
    while(typeName = [typeNamesE nextObject]){
        [bibTypeButton addItemWithTitle:typeName];
    }

    [bibTypeButton selectItemWithTitle:currentType];
}

- (void)awakeFromNib{
	[self setupToolbar];
    
    [citeKeyField setFormatter:citeKeyFormatter];
    [newFieldName setFormatter:fieldNameFormatter];

    [self setupTypePopUp];
    [self setupForm]; // gets called in window will load...?
	
	[statusLine retain]; // we need to retain, as we might remove it from the window
	if (![[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShowEditorStatusBarKey]) {
		[self toggleStatusBar:nil];
	}
    
	// The popupbutton needs to be set before fixURLs is called, and -windowDidLoad gets sent after awakeFromNib.

	// Set the properties of viewLocalButton that cannot be set in IB
	[viewLocalButton setArrowImage:[NSImage imageNamed:@"ArrowPointingDown"]];
	[viewLocalButton setShowsMenuWhenIconClicked:NO];
	[[viewLocalButton cell] setAltersStateOfSelectedItem:NO];
	[[viewLocalButton cell] setAlwaysUsesFirstItemAsSelected:YES];
	[[viewLocalButton cell] setUsesItemFromMenu:NO];
	[[viewLocalButton cell] setRefreshesMenu:YES];
	[[viewLocalButton cell] setDelegate:self];
		
	[viewLocalButton setMenu:[self menuForImagePopUpButtonCell:[viewLocalButton cell]]];

	// Set the properties of viewRemoteButton that cannot be set in IB
	[viewRemoteButton setArrowImage:[NSImage imageNamed:@"ArrowPointingDown"]];
	[viewRemoteButton setShowsMenuWhenIconClicked:NO];
	[[viewRemoteButton cell] setAltersStateOfSelectedItem:NO];
	[[viewRemoteButton cell] setAlwaysUsesFirstItemAsSelected:YES];
	[[viewRemoteButton cell] setUsesItemFromMenu:NO];
	[[viewRemoteButton cell] setRefreshesMenu:YES];
	[[viewRemoteButton cell] setDelegate:self];
		
	[viewRemoteButton setMenu:[self menuForImagePopUpButtonCell:[viewRemoteButton cell]]];

	// Set the properties of documentSnoopButton that cannot be set in IB
	[documentSnoopButton setArrowImage:[NSImage imageNamed:@"ArrowPointingDown"]];
	[documentSnoopButton setShowsMenuWhenIconClicked:NO];
	[[documentSnoopButton cell] setAltersStateOfSelectedItem:YES];
	[[documentSnoopButton cell] setAlwaysUsesFirstItemAsSelected:NO];
	[[documentSnoopButton cell] setUsesItemFromMenu:NO];
	[[documentSnoopButton cell] setRefreshesMenu:NO];
	
	[documentSnoopButton setMenu:[self menuForImagePopUpButtonCell:[documentSnoopButton cell]]];
	[documentSnoopButton selectItemAtIndex:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKSnoopDrawerContentKey]];
		
    [notesView setString:[theBib valueOfField:BDSKAnnoteString inherit:NO]];
    [abstractView setString:[theBib valueOfField:BDSKAbstractString inherit:NO]];
    [rssDescriptionView setString:[theBib valueOfField:BDSKRssDescriptionString inherit:NO]];
	currentEditedView = nil;
    
    // set up identifiers for the tab view items, since we receive delegate messages from it
    NSArray *tabViewItems = [tabView tabViewItems];
    [[tabViewItems objectAtIndex:0] setIdentifier:BDSKBibtexString];
    [[tabViewItems objectAtIndex:1] setIdentifier:BDSKAnnoteString];
    [[tabViewItems objectAtIndex:2] setIdentifier:BDSKAbstractString];
    [[tabViewItems objectAtIndex:3] setIdentifier:BDSKRssDescriptionString];

#ifdef BDSK_USING_TIGER
    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3){
    } else {
        NSSize drawerContentSize = [documentSnoopDrawer contentSize];
        id pdfView = [[NSClassFromString(@"BDSKZoomablePDFView") alloc] initWithFrame:NSMakeRect(0, 0, drawerContentSize.width, drawerContentSize.height)];
        
        // release the old scrollview/PDFImageView combination and replace with the PDFView
        [pdfSnoopContainerView replaceSubview:documentSnoopScrollView with:pdfView];
        [pdfView release];
        [pdfView setAutoresizingMask:(NSViewHeightSizable | NSViewWidthSizable)];
        
        [pdfView setScrollerSize:NSSmallControlSize];
        documentSnoopScrollView = nil;
    }
#endif
    
	[fieldsScrollView setDrawsBackground:NO];
	
	[citeKeyField setStringValue:[theBib citeKey]];
	
	[theBib setEditorObj:self];	
	
	// Set the properties of actionMenuButton that cannot be set in IB
	[actionMenuButton setAlternateImage:[NSImage imageNamed:@"Action_Pressed"]];
	[actionMenuButton setArrowImage:nil];
	[actionMenuButton setShowsMenuWhenIconClicked:YES];
	[[actionMenuButton cell] setAltersStateOfSelectedItem:NO];
	[[actionMenuButton cell] setAlwaysUsesFirstItemAsSelected:NO];
	[[actionMenuButton cell] setUsesItemFromMenu:NO];
	[[actionMenuButton cell] setRefreshesMenu:NO];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(bibDidChange:)
												 name:BDSKBibItemChangedNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(bibWasAddedOrRemoved:)
												 name:BDSKDocAddItemNotification
											   object:theDocument];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(bibWasAddedOrRemoved:)
												 name:BDSKDocDelItemNotification
											   object:theDocument];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(bibWillBeRemoved:)
												 name:BDSKDocWillRemoveItemNotification
											   object:theBib];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(docWillSave:)
												 name:BDSKDocumentWillSaveNotification
											   object:theDocument];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(docWindowWillClose:)
												 name:BDSKDocumentWindowWillCloseNotification
											   object:theDocument];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(typeInfoDidChange:)
												 name:BDSKBibTypeInfoChangedNotification
											   object:[BibTypeManager sharedManager]];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(macrosDidChange:)
												 name:BDSKBibDocMacroDefinitionChangedNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(macrosDidChange:)
												 name:BDSKBibDocMacroKeyChangedNotification
											   object:nil];

	[authorTableView setDoubleAction:@selector(showPersonDetailCmd:)];

    [bibFields setDelegate:self];
    [self setWindowFrameAutosaveName:@"BibEditor window autosave name"];

}

- (void)dealloc{
#if DEBUG
    NSLog(@"BibEditor dealloc");
#endif
    // release theBib? no...
    
    // This fixes some seriously weird issues with Jaguar, and possibly 10.3.  The tableview messages its datasource/delegate (BibEditor) after the editor is dealloced, which causes a crash.
    // See http://www.cocoabuilder.com/search/archive?words=crash+%22setDataSource:nil%22 for similar problems.
    [authorTableView setDelegate:nil];
    [authorTableView setDataSource:nil];
    [notesViewUndoManager release];
    [abstractViewUndoManager release];
    [rssDescriptionViewUndoManager release];   
    [currentType release];
    [citeKeyFormatter release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [fieldNumbers release];
    [fieldNameFormatter release];
    [theBib setEditorObj:nil];
	[viewLocalToolbarItem release];
	[viewRemoteToolbarItem release];
	[documentSnoopToolbarItem release];
	[statusLine release];
	[toolbarItems release];
	[macroTextFieldWC release];
    [super dealloc];
}

- (void)show{
    [self showWindow:self];
}

// note that we don't want the - document accessor! It messes us up by getting called for other stuff.

- (void)finalizeChanges{
    forceEndEditing = YES;
	if ([[self window] makeFirstResponder:[self window]]) {
    /* All fields are now valid; it's safe to use fieldEditor:forObject:
    to claim the field editor. */
    }else{
        /* Force first responder to resign. */
        [[self window] endEditingFor:nil];
    }
	forceEndEditing = NO;
}

- (IBAction)saveDocument:(id)sender{
	NSResponder *fr = [[self window] firstResponder];
	NSText *fe = nil;
	NSRange selection = NSMakeRange(0,0);
    
    // Use this ivar to see if setupForm gets called by finalizeChanges.  This causes an exception to
    // be raised when you paste a cite key into the crossref field and hit save before committing the
    // edit.  Under these conditions, the selection is no longer meaningful since setupForm alters the
    // form, and we (may) select the wrong text when we call setSelectedRange after the save. 
    didSetupForm = NO;

    // if we were editing, we will should select the delegate of the field editor. We also keep the selection
	if(fr == [[self window] fieldEditor:YES forObject:bibFields]){
		fe = (NSText *)fr;
		selection = [fe selectedRange];
        fr = [fe delegate];
	}

	// a safety call to be sure that the current field's changes are saved :...
    [self finalizeChanges];
    
    [theDocument saveDocument:sender];
    
    if([[self window] makeFirstResponder:fr] && fe && !didSetupForm){
		[fe setSelectedRange:selection];
    }
}

- (IBAction)toggleStatusBar:(id)sender{
	NSRect tabViewFrame = [tabView frame];
	NSRect contentRect = [[[self window] contentView] frame];
	NSRect infoRect = [statusLine frame];
	if (showStatus) {
		showStatus = NO;
		tabViewFrame.size.height += 20.0;
		[statusLine removeFromSuperview];
	} else {
		showStatus = YES;
		tabViewFrame.size.height -= 20.0;
		infoRect.origin.y = contentRect.size.height - 16.0;
		infoRect.size.width = contentRect.size.width - 16.0;
		[statusLine setFrame:infoRect];
		[[[self window] contentView]  addSubview:statusLine];
	}
	[tabView setFrame:tabViewFrame];
	[[[self window] contentView] setNeedsDisplayInRect:contentRect];
	[[OFPreferenceWrapper sharedPreferenceWrapper] setBool:showStatus forKey:BDSKShowEditorStatusBarKey];
}

- (IBAction)revealLocal:(id)sender{
    NSWorkspace *sw = [NSWorkspace sharedWorkspace];
	NSString *path = [theBib localURLPath];
	[sw selectFile:path inFileViewerRootedAtPath:nil];
}

- (IBAction)viewLocal:(id)sender{
    NSWorkspace *sw = [NSWorkspace sharedWorkspace];
    
    volatile BOOL err = NO;

    NS_DURING

        if(![sw openFile:[theBib localURLPath]]){
                err = YES;
        }

        NS_HANDLER
            err=YES;
        NS_ENDHANDLER
        
        if(err)
            NSBeginAlertSheet(NSLocalizedString(@"Can't open local file", @"can't open local file"),
                              NSLocalizedString(@"OK", @"OK"),
                              nil,nil, [self window],self, NULL, NULL, NULL,
                              NSLocalizedString(@"Sorry, the contents of the Local-Url Field are neither a valid file path nor a valid URL.",
                                                @"explanation of why the local-url failed to open"), nil);

}

- (NSMenu *)submenuForMenuItem:(NSMenuItem *)menuItem{
	if (menuItem == [viewLocalToolbarItem menuFormRepresentation]) {
		return [self menuForImagePopUpButtonCell:[viewLocalButton cell]];
	} 
	else if (menuItem == [viewRemoteToolbarItem menuFormRepresentation]) {
		return [self menuForImagePopUpButtonCell:[viewRemoteButton cell]];
	} 
	else if (menuItem == [documentSnoopToolbarItem menuFormRepresentation]) {
		return [self menuForImagePopUpButtonCell:[documentSnoopButton cell]];
	} 
}

- (NSMenu *)menuForImagePopUpButtonCell:(RYZImagePopUpButtonCell *)cell{
	NSMenu *menu = [[NSMenu alloc] init];
	NSMenu *submenu;
	NSMenuItem *item;
	
	if (cell == [viewLocalButton cell]) {
		// the first one has to be view file, since it's also the button's action when you're clicking on the icon.
		[menu addItemWithTitle:NSLocalizedString(@"View File",@"View file")
						action:@selector(viewLocal:)
				 keyEquivalent:@""];
		
		[menu addItemWithTitle:NSLocalizedString(@"Reveal in Finder",@"Reveal in finder")
						action:@selector(revealLocal:)
				 keyEquivalent:@""];
		
		[menu addItem:[NSMenuItem separatorItem]];
		
		[menu addItemWithTitle:[NSString stringWithFormat:@"%@%C",NSLocalizedString(@"Choose File",@"Choose File..."),0x2026]
						action:@selector(chooseLocalURL:)
				 keyEquivalent:@""];
		
		// get Safari recent downloads
		if (submenu = [self getSafariRecentDownloadsMenu]) {
			item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Link to Download URL",@"Link to Download URL")
											  action:NULL
									   keyEquivalent:@""];
			[item setSubmenu:submenu];
			[menu addItem:item];
			[item release];
		}
		
		// get Preview recent documents
		if (submenu = [self getPreviewRecentDocumentsMenu]) {
			item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Link to Recent File from Preview",@"Link to Recent File from Preview")
											  action:NULL
									   keyEquivalent:@""];
			[item setSubmenu:submenu];
			[menu addItem:item];
			[item release];
		}
	}
	else if (cell == [viewRemoteButton cell]) {
		// the first one has to be view in web brower, since it's also the button's action when you're clicking on the icon.
		[menu addItemWithTitle:NSLocalizedString(@"View in Web Browser",@"View in web browser")
								 action:@selector(viewRemote:)
						  keyEquivalent:@""];
		
		// get Safari recent URLs
		if (submenu = [self getSafariRecentURLsMenu]) {
			[menu addItem:[NSMenuItem separatorItem]];
			item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Link to Download URL",@"Link to Download URL")
										 	  action:NULL
									   keyEquivalent:@""];
			[item setSubmenu:submenu];
			[menu addItem:item];
			[item release];
		}
	}
	else if (cell == [documentSnoopButton cell]) {
		
		item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"View File in Drawer",@"View file in drawer")
										  action:@selector(toggleSnoopDrawer:)
								   keyEquivalent:@""];
		[item setRepresentedObject:pdfSnoopContainerView];
		[menu addItem:item];
		[item release];
		
		item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"View File as Text in Drawer",@"View file as text in drawer")
										  action:@selector(toggleSnoopDrawer:)
								   keyEquivalent:@""];
		[item setRepresentedObject:textSnoopContainerView];
		[menu addItem:item];
		[item release];
		
		item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"View Remote URL in Drawer",@"View remote URL in drawer")
										  action:@selector(toggleSnoopDrawer:)
								   keyEquivalent:@""];
		[item setRepresentedObject:webSnoopContainerView];
		[menu addItem:item];
		[item release];
	}
	
	return [menu autorelease];
}

- (NSMenu *)getSafariRecentDownloadsMenu{
	NSString *downloadPlistFileName = [NSHomeDirectory()  stringByAppendingPathComponent:@"Library"];
	downloadPlistFileName = [downloadPlistFileName stringByAppendingPathComponent:@"Safari"];
	downloadPlistFileName = [downloadPlistFileName stringByAppendingPathComponent:@"downloads.plist"];
	
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:downloadPlistFileName];
	NSArray *historyArray = [dict objectForKey:@"DownloadHistory"];
	
	if (![historyArray count])
		return nil;
	
	NSMenu *menu = [[NSMenu alloc] init];
	int i = 0;
	
	for (i = 0; i < [historyArray count]; i ++){
		NSDictionary *itemDict = [historyArray objectAtIndex:i];
		NSString *filePath = [itemDict objectForKey:@"DownloadEntryPath"];
		filePath = [filePath stringByExpandingTildeInPath];
		if([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
			NSString *fileName = [filePath lastPathComponent];
			NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:filePath];
			[image setSize: NSMakeSize(16, 16)];
			
			NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:fileName
														  action:@selector(setLocalURLPathFromMenuItem:)
												   keyEquivalent:@""];
			[item setRepresentedObject:filePath];
			[item setImage:image];
			[menu addItem:item];
			[item release];
		}
	}
	
	if ([menu numberOfItems] > 0)
		return [menu autorelease];
	
	[menu release];
	return nil;
}


- (NSMenu *)getSafariRecentURLsMenu{
	NSString *downloadPlistFileName = [NSHomeDirectory()  stringByAppendingPathComponent:@"Library"];
	downloadPlistFileName = [downloadPlistFileName stringByAppendingPathComponent:@"Safari"];
	downloadPlistFileName = [downloadPlistFileName stringByAppendingPathComponent:@"downloads.plist"];
	
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:downloadPlistFileName];
	NSArray *historyArray = [dict objectForKey:@"DownloadHistory"];
	
	if (![historyArray count])
		return nil;
	
	NSMenu *menu = [[NSMenu alloc] init];
	int i = 0;
	
	for (i = 0; i < [historyArray count]; i ++){
		NSDictionary *itemDict = [historyArray objectAtIndex:i];
		NSString *URLString = [itemDict objectForKey:@"DownloadEntryURL"];
		if ([NSURL URLWithString:URLString] && ![URLString isEqualToString:@""]) {
			NSImage *image = [[NSWorkspace sharedWorkspace] iconForFileType:@"webloc"];
			[image setSize: NSMakeSize(16, 16)];
			
			NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:URLString
														  action:@selector(setRemoteURLFromMenuItem:)
												   keyEquivalent:@""];
			[item setRepresentedObject:URLString];
			[item setImage:image];
			[menu addItem:item];
			[item release];
		}
	}

	if ([menu numberOfItems] > 0)
		return [menu autorelease];
	
	[menu release];
	return nil;
}

- (NSMenu *)getPreviewRecentDocumentsMenu{
	BOOL success = CFPreferencesSynchronize((CFStringRef)@"com.apple.Preview",
									   kCFPreferencesCurrentUser,
									   kCFPreferencesCurrentHost);
	
	if(!success){
		NSLog(@"error syncing preview's prefs!");
	}
	
	NSArray *historyArray = (NSArray *) CFPreferencesCopyAppValue((CFStringRef) @"NSRecentDocumentRecords",
								      (CFStringRef) @"com.apple.Preview");
	
	if (![(NSArray *)historyArray count]) {
		CFRelease(historyArray);
		return nil;
	}
	
	NSMenu *menu = [[NSMenu alloc] init];
	int i = 0;
	
	for (i = 0; i < [(NSArray *)historyArray count]; i ++){
		NSDictionary *itemDict = [(NSArray *)historyArray objectAtIndex:i];
		NSData *aliasData = [[itemDict objectForKey:@"_NSLocator"] objectForKey:@"_NSAlias"];
		
		BDAlias *bda = [BDAlias aliasWithData:aliasData];
		
		NSString *filePath = [bda fullPathNoUI];

		filePath = [filePath stringByExpandingTildeInPath];
		if([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
			NSString *fileName = [filePath lastPathComponent];
			NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:filePath];
			[image setSize: NSMakeSize(16, 16)];
			
			NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:fileName
														  action:@selector(setLocalURLPathFromMenuItem:)
												   keyEquivalent:@""];
			[item setRepresentedObject:filePath];
			[item setImage:image];
			[menu addItem:item];
			[item release];
		}
	}
	
	CFRelease(historyArray);
	
	if ([menu numberOfItems] > 0)
		return [menu autorelease];
	
	[menu release];
	return nil;
}


- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem{
	if ([menuItem action] == nil ||
		[menuItem action] == @selector(dummy:)){ // Unused selector for disabled items. Needed to avoid the popupbutton to insert its own
		return NO;
	}
	else if ([menuItem action] == @selector(generateCiteKey:)) {
		// need to setthe title, as the document can change it in the main menu
		[menuItem setTitle: NSLocalizedString(@"Generate Cite Key", @"Generate Cite Key")];
		return YES;
	}
	else if ([menuItem action] == @selector(generateLocalUrl:) ||
			 [menuItem action] == @selector(viewLocal:) ||
			 [menuItem action] == @selector(revealLocal:)) {
		NSString *lurl = [theBib localURLPath];
		return (lurl && [[NSFileManager defaultManager] fileExistsAtPath:lurl]);
	}
	else if ([menuItem action] == @selector(toggleSnoopDrawer:)) {
		NSView *requiredSnoopContainerView = (NSView *)[menuItem representedObject];
		BOOL isCloseItem = [documentSnoopDrawer contentView] == requiredSnoopContainerView &&
							( [documentSnoopDrawer state] == NSDrawerOpenState ||
							  [documentSnoopDrawer state] == NSDrawerOpeningState);
		if (isCloseItem) {
			[menuItem setTitle:NSLocalizedString(@"Close Drawer", @"Close drawer")];
		} else if (requiredSnoopContainerView == pdfSnoopContainerView){
			[menuItem setTitle:NSLocalizedString(@"View File in Drawer", @"View file in drawer")];
		} else if (requiredSnoopContainerView == textSnoopContainerView) {
			[menuItem setTitle:NSLocalizedString(@"View File as Text in Drawer", @"View file as text in drawer")];
		} else if (requiredSnoopContainerView == webSnoopContainerView) {
			[menuItem setTitle:NSLocalizedString(@"View Remote URL in Drawer", @"View remote URL in drawer")];
		}
		if (isCloseItem) {
			// always enable the close item
			return YES;
		} else if (requiredSnoopContainerView == webSnoopContainerView) {
			NSString *rurl = [theBib valueOfField:BDSKUrlString];
			return (![rurl isEqualToString:@""] && [NSURL URLWithString:rurl]);
		} else {
			NSString *lurl = [theBib localURLPath];
			return (lurl && [[NSFileManager defaultManager] fileExistsAtPath:lurl]);
		}
	}
	else if ([menuItem action] == @selector(viewRemote:)) {
		NSString *rurl = [theBib valueOfField:BDSKUrlString];
		return (![rurl isEqualToString:@""] && [NSURL URLWithString:rurl]);
	}
	else if ([menuItem action] == @selector(saveFileAsLocalUrl:)) {
		return ![[[remoteSnoopWebView mainFrame] dataSource] isLoading];
	}
	else if ([menuItem action] == @selector(downloadLinkedFileAsLocalUrl:)) {
		return NO;
	}
    else if ([menuItem action] == @selector(editSelectedFieldAsRawBibTeX:)) {
        return ([bibFields selectedCell] != nil && [bibFields currentEditor] != nil);
    }
    else if ([menuItem action] == @selector(toggleStatusBar:)) {
		if (showStatus) {
			[menuItem setTitle:NSLocalizedString(@"Hide Status Bar", @"Hide Status Bar")];
		} else {
			[menuItem setTitle:NSLocalizedString(@"Show Status Bar", @"Show Status Bar")];
		}
		return YES;
    }
	return YES;
}

- (IBAction)viewRemote:(id)sender{
    NSWorkspace *sw = [NSWorkspace sharedWorkspace];
    NSString *rurl = [theBib valueOfField:BDSKUrlString];
    
    if([rurl isEqualToString:@""])
        return;
    
    if([rurl rangeOfString:@"://"].location == NSNotFound)
        rurl = [@"http://" stringByAppendingString:rurl];

    NSURL *url = [NSURL URLWithString:rurl];
    
    if(url != nil)
        [sw openURL:url];
    else
        NSBeginAlertSheet(NSLocalizedString(@"Error!", @"Error!"),
                          nil, nil, nil, [self window], nil, nil, nil, nil,
                          NSLocalizedString(@"Mac OS X does not recognize this as a valid URL.  Please check the URL field and try again.",
                                            @"Unrecognized URL, edit it and try again.") );
    
}

#pragma mark Cite Key handling methods

- (IBAction)showCiteKeyWarning:(id)sender{
	int rv;
	rv = NSRunCriticalAlertPanel(NSLocalizedString(@"",@""), 
								 NSLocalizedString(@"The citation key you entered is either already used in this document or is empty. Please provide a unique one.",@""),
								  NSLocalizedString(@"OK",@"OK"), nil, nil, nil);
}

- (IBAction)citeKeyDidChange:(id)sender{
    NSString *proposedCiteKey = [sender stringValue];
	NSString *prevCiteKey = [theBib citeKey];
	
   	if(![proposedCiteKey isEqualToString:prevCiteKey]){
		// if proposedCiteKey is empty or invalid (bad chars only)
		//  this call will set & sanitize citeKey (and invalidate our display)
		[theBib setCiteKey:proposedCiteKey];
		NSString *newKey = [theBib citeKey];
		
		[sender setStringValue:newKey];
		
		[[[self window] undoManager] setActionName:NSLocalizedString(@"Change Cite Key",@"")];
		
		// autofile paper if we have enough information
		if ( [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKFilePapersAutomaticallyKey] &&
			 [theBib needsToBeFiled] && [theBib canSetLocalUrl] ) {
			[[BibFiler sharedFiler] filePapers:[NSArray arrayWithObject:theBib] fromDocument:[theBib document] ask:NO];
			[theBib setNeedsToBeFiled:NO]; // unset the flag even when we fail, to avoid retrying at every edit
			[self setStatus:NSLocalizedString(@"Autofiled linked file.",@"Autofiled linked file.")];
		}

		// still need to check duplicates ourselves:
		if(![self citeKeyIsValid:newKey]){
			[self setCiteKeyDuplicateWarning:YES];
		}else{
			[self setCiteKeyDuplicateWarning:NO];
		}
				
	}
}

- (void)setCiteKeyDuplicateWarning:(BOOL)set{
	if(set){
		[citeKeyWarningButton setImage:[NSImage cautionIconImage]];
		[citeKeyWarningButton setToolTip:NSLocalizedString(@"This cite-key is a duplicate",@"")];
	}else{
		[citeKeyWarningButton setImage:nil];
		[citeKeyWarningButton setToolTip:NSLocalizedString(@"",@"")]; // @@ this should be nil?
	}
	[citeKeyWarningButton setEnabled:set];
	[citeKeyField setTextColor:(set ? [NSColor redColor] : [NSColor blackColor])];
}

// @@ should also check validity using citekeyformatter
- (BOOL)citeKeyIsValid:(NSString *)proposedCiteKey{
	
    return !([(BibDocument *)theDocument citeKeyIsUsed:proposedCiteKey byItemOtherThan:theBib] ||
			 [proposedCiteKey isEqualToString:@""]);
}

- (IBAction)generateCiteKey:(id)sender
{
	[theBib setCiteKey:[theBib suggestedCiteKey]];
	
	[[[self window] undoManager] setActionName:NSLocalizedString(@"Generate Cite Key",@"")];
	[tabView selectFirstTabViewItem:self];
}

- (IBAction)generateLocalUrl:(id)sender
{
	if (![theBib canSetLocalUrl]){
		NSString *message = NSLocalizedString(@"Not all fields needed for generating the file location are set. Do you want me to continue anyway?",@"");
		NSString *otherButton = nil;
		if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKFilePapersAutomaticallyKey]){
			message = NSLocalizedString(@"Not all fields needed for generating the file location are set. Do you want me to continue anyway, or wait till all the necessary fields are set?",@""),
			otherButton = NSLocalizedString(@"Wait",@"Wait");
		}
		int rv = NSRunAlertPanel(NSLocalizedString(@"Warning",@"Warning"),
								 message, 
								 NSLocalizedString(@"OK",@"OK"),
								 NSLocalizedString(@"Cancel",@"Cancel"),
								 otherButton);
		if (rv == NSAlertAlternateReturn){
			return;
		}else if(rv == NSAlertOtherReturn){
			[theBib setNeedsToBeFiled:YES];
			return;
		}
	}
	
	[[BibFiler sharedFiler] filePapers:[NSArray arrayWithObject:theBib] fromDocument:[theBib document] ask:NO];
	
	[tabView selectFirstTabViewItem:self];
	
	[[[self window] undoManager] setActionName:NSLocalizedString(@"Move File",@"")];
}

- (IBAction)bibTypeDidChange:(id)sender{
    if (![[self window] makeFirstResponder:[self window]]){
        [[self window] endEditingFor:nil];
    }
    [self setCurrentType:[bibTypeButton titleOfSelectedItem]];
    if(![[theBib type] isEqualToString:currentType]){
        [theBib setType:currentType];
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:currentType
                                                           forKey:BDSKPubTypeStringKey];
		
		[[[self window] undoManager] setActionName:NSLocalizedString(@"Change Type",@"")];
    }
}

- (void)updateTypePopup{ // used to update UI after dragging into the editor
    [bibTypeButton selectItemWithTitle:[theBib type]];
}

- (void)setCurrentType:(NSString *)type{
    [currentType release];
    currentType = [type retain];
}

- (void)fixURLs{
    NSString *lurl = [theBib localURLPath];
    NSString *rurl = [theBib valueOfField:BDSKUrlString];
    NSImage *icon;
    BOOL drawerWasOpen = ([documentSnoopDrawer state] == NSDrawerOpenState ||
						  [documentSnoopDrawer state] == NSDrawerOpeningState);
	BOOL drawerShouldReopen = NO;
	
	// we need to reopen with the correct content
    if(drawerWasOpen) [documentSnoopDrawer close];
    
    if (lurl && [[NSFileManager defaultManager] fileExistsAtPath:lurl]){
		icon = [[NSWorkspace sharedWorkspace] iconForFile:lurl];
		[viewLocalButton setIconImage:icon];      
		[viewLocalButton setIconActionEnabled:YES];
		[viewLocalToolbarItem setToolTip:NSLocalizedString(@"View File",@"View file")];
		[[self window] setRepresentedFilename:lurl];
		if([documentSnoopDrawer contentView] != webSnoopContainerView)
			drawerShouldReopen = drawerWasOpen;
    }else{
        [viewLocalButton setIconImage:[NSImage imageNamed:@"QuestionMarkFile"]];
		[viewLocalButton setIconActionEnabled:NO];
        [viewLocalToolbarItem setToolTip:NSLocalizedString(@"Choose a file to link with in the Local-Url Field", @"bad/empty local url field")];
        [[self window] setRepresentedFilename:@""];
    }

    if([NSURL URLWithString:rurl] && ![rurl isEqualToString:@""]){
		icon = [[NSWorkspace sharedWorkspace] iconForFileType:@"webloc"];
		[viewRemoteButton setIconImage:icon];
        [viewRemoteButton setIconActionEnabled:YES];
        [viewRemoteToolbarItem setToolTip:rurl];
		if([documentSnoopDrawer contentView] == webSnoopContainerView)
			drawerShouldReopen = drawerWasOpen;
    }else{
        [viewRemoteButton setIconImage:[NSImage imageNamed:@"WeblocFile_Disabled"]];
		[viewRemoteButton setIconActionEnabled:NO];
        [viewRemoteToolbarItem setToolTip:NSLocalizedString(@"Choose a URL to link with in the Url Field", @"bad/empty url field")];
    }
	
    drawerState = BDSKDrawerUnknownState; // this makes sure the button will be updated
    if (drawerShouldReopen){
		// this takes care of updating the button and the drawer content
		[documentSnoopDrawer open];
	}else{
		[self updateDocumentSnoopButton];
	}
}

#pragma mark choose local-url or url support

- (IBAction)chooseLocalURL:(id)sender{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setResolvesAliases:NO];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setPrompt:NSLocalizedString(@"Choose", @"Choose file")];

    [oPanel beginSheetForDirectory:nil 
                              file:nil 
                    modalForWindow:[self window] 
                     modalDelegate:self 
                    didEndSelector:@selector(chooseLocalURLPanelDidEnd:returnCode:contextInfo:) 
                       contextInfo:nil];
  
}

- (void)chooseLocalURLPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{

    if(returnCode == NSOKButton){
        NSString *fileURLString = [[NSURL fileURLWithPath:[[sheet filenames] objectAtIndex:0]] absoluteString];
        
		[theBib setField:BDSKLocalUrlString toValue:fileURLString];
		[theBib autoFilePaper];
		
		[[[self window] undoManager] setActionName:NSLocalizedString(@"Edit Publication",@"")];
    }        
}

- (void)setLocalURLPathFromMenuItem:(NSMenuItem *)sender{
	NSString *path = [sender representedObject];
	
	[theBib setField:BDSKLocalUrlString toValue:[[NSURL fileURLWithPath:path] absoluteString]];
	[theBib autoFilePaper];
	
	[[[self window] undoManager] setActionName:NSLocalizedString(@"Edit Publication",@"")];
}

- (void)setRemoteURLFromMenuItem:(NSMenuItem *)sender{
	[theBib setField:BDSKUrlString toValue:[sender representedObject]];
	
	[[[self window] undoManager] setActionName:NSLocalizedString(@"Edit Publication",@"")];
}

// ----------------------------------------------------------------------------------------
#pragma mark add-Field-Sheet Support
// Add field sheet support
// ----------------------------------------------------------------------------------------

// raises the add field sheet
- (IBAction)raiseAddField:(id)sender{
    [newFieldName setStringValue:@""];
    [NSApp beginSheet:newFieldWindow
       modalForWindow:[self window]
        modalDelegate:self
       didEndSelector:@selector(addFieldSheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
}
//dismisses it
- (IBAction)dismissAddField:(id)sender{
    [newFieldWindow orderOut:sender];
    [NSApp endSheet:newFieldWindow returnCode:[sender tag]];
}

// tag, and hence return code is 0 for OK and 1 for cancel.
// called upon dismissal
- (void)addFieldSheetDidEnd:(NSWindow *)sheet
                 returnCode:(int) returnCode
                contextInfo:(void *)contextInfo{
    if(returnCode == 0){
        if(![[[theBib pubFields] allKeys] containsObject:[newFieldName stringValue]]){
		NSString *name = [[newFieldName stringValue] capitalizedString]; // add it as a capitalized string to avoid duplicates

		[theBib addField:name];
		[[[self window] undoManager] setActionName:NSLocalizedString(@"Add Field",@"")];
		[self finalizeChanges];
		[self setupForm];
		[self makeKeyField:name];
        }
    }
    // else, nothing.
}

- (void)makeKeyField:(NSString *)fieldName{
    int sel = -1;
    int i = 0;

    for (i = 0; i < [bibFields numberOfRows]; i++) {
        if ([[[bibFields cellAtIndex:i] title] isEqualToString:fieldName]) {
            sel = i;
        }
    }
    if(sel > -1) [bibFields selectTextAtIndex:sel];
}

// ----------------------------------------------------------------------------------------
#pragma mark ||  delete-Field-Sheet Support
// ----------------------------------------------------------------------------------------

// raises the del field sheet
- (IBAction)raiseDelField:(id)sender{
    // populate the popupbutton
	BibTypeManager *typeMan = [BibTypeManager sharedManager];
	NSMutableArray *removableFields = [[[theBib pubFields] allKeys] mutableCopy];
	[removableFields removeObjectsInArray:[NSArray arrayWithObjects:BDSKUrlString, BDSKLocalUrlString, BDSKAnnoteString, BDSKAbstractString, BDSKRssDescriptionString, nil]];
	[removableFields removeObjectsInArray:[typeMan requiredFieldsForType:currentType]];
	[removableFields removeObjectsInArray:[typeMan optionalFieldsForType:currentType]];
	[removableFields removeObjectsInArray:[typeMan userDefaultFieldsForType:currentType]];
	if ([removableFields count]) {
		[removableFields sortUsingSelector:@selector(caseInsensitiveCompare:)];
		[delFieldPopUp setEnabled:YES];
	} else {
		[removableFields addObject:NSLocalizedString(@"No fields to remove",@"")];
		[delFieldPopUp setEnabled:NO];
	}
    
	[delFieldPopUp removeAllItems];
    [delFieldPopUp addItemsWithTitles:removableFields];
    [delFieldPopUp selectItemAtIndex:0];
	
	[removableFields release];
	
    [NSApp beginSheet:delFieldWindow
       modalForWindow:[self window]
        modalDelegate:self
       didEndSelector:@selector(delFieldSheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
}

//dismisses it
- (IBAction)dismissDelField:(id)sender{
    [delFieldWindow orderOut:sender];
    [NSApp endSheet:delFieldWindow returnCode:[sender tag]];
}

// tag, and hence return code is 0 for delete and 1 for cancel.
// called upon dismissal
- (void)delFieldSheetDidEnd:(NSWindow *)sheet
                 returnCode:(int) returnCode
                contextInfo:(void *)contextInfo{
    if(returnCode == 0){

        [theBib removeField:[delFieldPopUp titleOfSelectedItem]];
		[[[self window] undoManager] setActionName:NSLocalizedString(@"Remove Field",@"")];
		[self finalizeChanges];
        [self setupForm];
    }
    // else, nothing.
}

#pragma mark Text Change handling

- (BOOL)control:(NSControl *)control textShouldStartEditing:(NSText *)fieldEditor{

    if (control != bibFields) return YES;
    
    NSFormCell *selectedCell = [bibFields selectedCell];
    
    NSString *value = [theBib valueOfField:[selectedCell title]];
    
    if([value isComplex] && ![value isInherited]){
        [self editFormCellAsMacro:selectedCell];
        return NO;
    }else{
        // edit it in the usual way.
        return YES;
    }
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor{

    if (control != bibFields) return YES;
    
    NSFormCell *selectedCell = [bibFields selectedCell];
    
    NSString *value = [theBib valueOfField:[selectedCell title]];
    
	if([value isInherited] &&
	   [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKWarnOnEditInheritedKey]){
		[dontWarnOnEditInheritedCheckButton setState:NSOffState];
		[NSApp beginSheet:editInheritedWarningSheet
		   modalForWindow:[self window]
			modalDelegate:self
		   didEndSelector:NULL
		   contextInfo:nil];
		int rv = [NSApp runModalForWindow:editInheritedWarningSheet];
		[NSApp endSheet:editInheritedWarningSheet];
		[editInheritedWarningSheet orderOut:self];
		
		if (rv == NSAlertAlternateReturn) {
			return NO;
		} else if (rv == NSAlertOtherReturn) {
			[self openParentItem:self];
			return NO;
		}
	}
	
    if([value isComplex]){
        [self editFormCellAsMacro:selectedCell];
        return NO;
    }else{
        // edit it in the usual way.
        return YES;
    }
}

- (IBAction)dismissEditInheritedSheet:(id)sender{
	[NSApp stopModalWithCode:[sender tag]];
}

- (IBAction)changeWarnOnEditInherited:(id)sender{
    [[OFPreferenceWrapper sharedPreferenceWrapper] setBool:([sender state] == NSOffState) 
													forKey:BDSKWarnOnEditInheritedKey];
}

- (IBAction)editSelectedFieldAsRawBibTeX:(id)sender{
    NSFormCell *cell = [bibFields selectedCell];
    if(cell == nil) return;
    
    //NSLog(@"edit as raw: %@", cell);
    [self editFormCellAsMacro:cell];
}

- (void)editFormCellAsMacro:(NSFormCell *)cell{
    float titleWidth = [cell titleWidth];
    int cellRow = 0;
    int cellCol = 0;
    BOOL foundCell = [bibFields getRow:&cellRow
                                column:&cellCol
                                ofCell:cell];
    if(!foundCell)[NSException raise:NSInternalInconsistencyException
                              format:@"Called editFormCellAsMacro with wrong cell."];
    
    NSRect frame = [bibFields cellFrameAtRow:cellRow 
                                      column:0]; // we want column 0.
    
    NSPoint loc = [bibFields convertPoint:frame.origin toView:nil];
    loc = [[self window] convertBaseToScreen:loc];
    
    loc.x = loc.x + titleWidth;
    loc.y = loc.y + 4; // 4 is a magic number based on the nib
    
    // it doesn't need to be a complex string
    NSString *value = [theBib valueOfField:[cell title]];
    
    [macroTextFieldWC startEditingValue:value
                             atLocation:loc
                                  width:frame.size.width - titleWidth + 4
                               withFont:[cell font]
                              fieldName:[cell title]
						  macroResolver:theDocument];
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMacroTextFieldWindowWillCloseNotification:)
                                                 name:BDSKMacroTextFieldWindowWillCloseNotification
                                               object:macroTextFieldWC];
    
}

- (void)handleMacroTextFieldWindowWillCloseNotification:(NSNotification *)notification{
    NSDictionary *userInfo = [notification userInfo];
    NSString *fieldName = [userInfo objectForKey:@"fieldName"];
    NSString *value = [userInfo objectForKey:@"stringValue"];
	NSString *prevValue = [theBib valueOfField:fieldName];
    
    if(![value isEqualAsComplexString:prevValue]){
		[self recordChangingField:fieldName toValue:value];
	}
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:BDSKMacroTextFieldWindowWillCloseNotification
                                                  object:macroTextFieldWC];
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor{
	if (control == bibFields) {
		
		NSCell *cell = [bibFields cellAtIndex:[bibFields indexOfSelectedItem]];
		NSString *message = nil;
		
		if ([[cell title] isEqualToString:BDSKCrossrefString]) {
			
			if ([[theBib citeKey] caseInsensitiveCompare:[cell stringValue]] == NSOrderedSame) {
				message = NSLocalizedString(@"An item cannot cross reference to itself.", @"");
			} else {
				NSString *parentCr = [[theDocument publicationForCiteKey:[cell stringValue]] valueOfField:BDSKCrossrefString inherit:NO];
				
				if (parentCr && ![parentCr isEqualToString:@""]) {
					message = NSLocalizedString(@"Cannot cross reference to an item that has the Crossref field set.", @"");
				} else if ([theDocument citeKeyIsCrossreffed:[theBib citeKey]]) {
					message = NSLocalizedString(@"Cannot set the Crossref field, as the current item is cross referenced.", @"");
				}
			}
			
			if (message) {
				NSRunAlertPanel(NSLocalizedString(@"Invalid Crossref Value", @"Invalid Crossref Value"),
								message,
								NSLocalizedString(@"OK", @"OK"), nil, nil);
				[cell setStringValue:@""];
				return NO;
			}
		}
		
		if (![[cell stringValue] isStringTeXQuotingBalancedWithBraces:YES connected:NO]) {
			NSString *cancelButton = nil;
			
			if (forceEndEditing) {
				message = NSLocalizedString(@"The value you entered contains unbalanced braces and cannot be saved.", @"");
			} else {
				message = NSLocalizedString(@"The value you entered contains unbalanced braces and cannot be saved. Do you want to keep editing?", @"");
				cancelButton = NSLocalizedString(@"Cancel", @"Cancel");
			}
			
			int rv = NSRunAlertPanel(NSLocalizedString(@"Invalid Value", @"Invalid Value"),
									 message,
									 NSLocalizedString(@"OK", @"OK"), cancelButton, nil);
			
			if (forceEndEditing || rv == NSAlertAlternateReturn) {
				[cell setStringValue:[theBib valueOfField:[cell title]]];
				return YES;
			} else {
				return NO;
			}
		}
	
	} else if (control == citeKeyField) {
		
		NSCharacterSet *invalidSet = [[BibTypeManager sharedManager] fragileCiteKeyCharacterSet];
		NSRange r = [[control stringValue] rangeOfCharacterFromSet:invalidSet];
		
		if (r.location != NSNotFound) {
			NSString *message = nil;
			NSString *cancelButton = nil;
			
			if (forceEndEditing) {
				message = NSLocalizedString(@"The cite key you entered contains characters that could be invalid in TeX.", @"");
			} else {
				message = NSLocalizedString(@"The cite key you entered contains characters that could be invalid in TeX. Do you want to continue editing with the invalid characters removed?", @"");
				cancelButton = NSLocalizedString(@"Cancel", @"Cancel");
			}
			
			int rv = NSRunAlertPanel(NSLocalizedString(@"Invalid Value", @"Invalid Value"),
									 message,
									 NSLocalizedString(@"OK", @"OK"), 
									 cancelButton, nil);
			
			if (forceEndEditing || rv == NSAlertAlternateReturn) {
				return YES;
			 } else {
				[control setStringValue:[[control stringValue] stringByReplacingCharactersInSet:invalidSet withString:@""]];
				return NO;
			}
		}
		
	}
	
	return YES;
}


- (void)controlTextDidEndEditing:(NSNotification *)aNotification{
	
	id control = [aNotification object];
	if (control != bibFields || [control indexOfSelectedItem] == -1)
		return;
	
    NSCell *sel = [control cellAtIndex: [control indexOfSelectedItem]];
    NSString *title = [sel title];
	NSString *value = [sel stringValue];
	NSString *prevValue = [theBib valueOfField:title];
	
    if(![value isEqualToString:prevValue] &&
	   !([prevValue isInherited] && [value isEqualToString:@""])){
		[self recordChangingField:title toValue:value];
    }
	// make sure we have the correct (complex) string value
	[sel setObjectValue:[theBib valueOfField:title]];
}

- (void)recordChangingField:(NSString *)fieldName toValue:(NSString *)value{

    [theBib setField:fieldName toValue:value];
	
	[[[self window] undoManager] setActionName:NSLocalizedString(@"Edit Publication",@"")];
    
	NSMutableString *status = [NSMutableString stringWithString:@""];
	
    // autogenerate cite key if we have enough information
    if ( [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKCiteKeyAutogenerateKey] &&
         [theBib canSetCiteKey] ) {
        [self generateCiteKey:nil];
		[status appendString:NSLocalizedString(@"Autogenerated Cite Key.",@"Autogenerated Cite Key.")];
    }
    
    // autofile paper if we have enough information
    if ( [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKFilePapersAutomaticallyKey] &&
         [theBib needsToBeFiled] && [theBib canSetLocalUrl] ) {
        [[BibFiler sharedFiler] filePapers:[NSArray arrayWithObject:theBib] fromDocument:[theBib document] ask:NO];
        [theBib setNeedsToBeFiled:NO]; // unset the flag even when we fail, to avoid retrying at every edit
		if (![status isEqualToString:@""]) {
			[status appendString:@" "];
		}
		[status appendString:NSLocalizedString(@"Autofiled linked file.",@"Autofiled linked file.")];
    }
    
	if (![status isEqualToString:@""]) {
		[self setStatus:status];
	}
}

- (NSString *)status {
	return [statusLine stringValue];
}

- (void)setStatus:(NSString *)status {
	[statusLine setStringValue:status];
}

- (void)bibDidChange:(NSNotification *)notification{
// unused	BibItem *notifBib = [notification object];
	NSDictionary *userInfo = [notification userInfo];
	NSString *changeType = [userInfo objectForKey:@"type"];
	BibItem *sender = (BibItem *)[notification object];
	NSString *crossref = [theBib valueOfField:BDSKCrossrefString inherit:NO];
	BOOL parentDidChange = (crossref != nil && 
							([crossref caseInsensitiveCompare:[sender citeKey]] == NSOrderedSame || 
							 [crossref caseInsensitiveCompare:[userInfo objectForKey:@"oldCiteKey"]] == NSOrderedSame));
	
    // If it is not our item or his crossref parent, we don't care, but our parent may have changed his cite key
	if (sender != theBib && !parentDidChange)
		return;

	if([changeType isEqualToString:@"Add/Del Field"]){
		[self finalizeChanges];
		[self setupForm];
		return;
	}

	NSString *changeKey = [userInfo objectForKey:@"key"];
	NSString *newValue = [userInfo objectForKey:@"value"];

	if([changeKey isEqualToString:BDSKTypeString]){
		[self finalizeChanges];
		[self setupForm];
		[self updateTypePopup];
		return;
	}
	
    // Rebuild the form if the crossref changed, or our parent's cite key changed.
	if([changeKey isEqualToString:BDSKCrossrefString] || 
	   (parentDidChange && [changeKey isEqualToString:BDSKCiteKeyString])){
		[self finalizeChanges];
		[self setupForm];
		[[self window] setTitle:[theBib title]];
		[authorTableView reloadData];
		pdfSnoopViewLoaded = NO;
		textSnoopViewLoaded = NO;
		webSnoopViewLoaded = NO;
		[self fixURLs];
		return;
	}
	
	if([changeKey isEqualToString:BDSKTypeString]){
		if(![newValue isEqualToString:currentType]){
			[self finalizeChanges];
			[self setupForm];
			return;
		}
	}
	
	if([changeKey isEqualToString:BDSKCiteKeyString]){
		[citeKeyField setStringValue:newValue];
		// still need to check duplicates ourselves:
		if(![self citeKeyIsValid:newValue]){
			[self setCiteKeyDuplicateWarning:YES];
		}else{
			[self setCiteKeyDuplicateWarning:NO];
		}
	}else{
		// essentially a cellWithTitle: for NSForm
		NSArray *cells = [bibFields cells];
		NSEnumerator *cellE = [cells objectEnumerator];
		NSFormCell *entry = nil;
		while(entry = [cellE nextObject]){
			if([[entry title] isEqualToString:changeKey])
				break;
		}
		if(entry){
			[entry setObjectValue:[theBib valueOfField:changeKey]];
			[bibFields setNeedsDisplay:YES];
		}
	}
	
	if([changeKey isEqualToString:BDSKLocalUrlString]){
		pdfSnoopViewLoaded = NO;
		textSnoopViewLoaded = NO;
		[self fixURLs];
	}
	else if([changeKey isEqualToString:BDSKUrlString]){
		webSnoopViewLoaded = NO;
		[self fixURLs];
	}
	else if([changeKey isEqualToString:BDSKTitleString]){
		[[self window] setTitle:newValue];
	}
	else if([changeKey isEqualToString:BDSKAuthorString]){
		[authorTableView reloadData];
	}
    else if([changeKey isEqualToString:BDSKAnnoteString]){
        // make a copy of the current value, so we don't overwrite it when we set the field value to the text storage
        NSString *tmpValue = [[theBib valueOfField:BDSKAnnoteString inherit:NO] copy];
        [notesView setString:(tmpValue == nil ? @"" : tmpValue)];
        [tmpValue release];
        // set this in pubFields directly, so we don't go into an endless loop
        if(currentEditedView == notesView)
            [[theBib pubFields] setValue:[[notesView textStorage] mutableString] forKey:BDSKAnnoteString];
        [notesViewUndoManager removeAllActions];
    }
    else if([changeKey isEqualToString:BDSKAbstractString]){
        NSString *tmpValue = [[theBib valueOfField:BDSKAbstractString inherit:NO] copy];
        [abstractView setString:(tmpValue == nil ? @"" : tmpValue)];
        [tmpValue release];
        if(currentEditedView == abstractView)
            [[theBib pubFields] setValue:[[abstractView textStorage] mutableString] forKey:BDSKAbstractString];
        [abstractViewUndoManager removeAllActions];
    }
    else if([changeKey isEqualToString:BDSKRssDescriptionString]){
        NSString *tmpValue = [[theBib valueOfField:BDSKRssDescriptionString inherit:NO] copy];
        [rssDescriptionView setString:(tmpValue == nil ? @"" : tmpValue)];
        [tmpValue release];
        if(currentEditedView == abstractView)
            [[theBib pubFields] setValue:[[rssDescriptionView textStorage] mutableString] forKey:BDSKRssDescriptionString];
        [rssDescriptionViewUndoManager removeAllActions];
    }
            
}
	
- (void)bibWasAddedOrRemoved:(NSNotification *)notification{
	NSDictionary *userInfo = [notification userInfo];
	BibItem *pub = (BibItem *)[userInfo objectForKey:@"pub"];
	NSString *crossref = [theBib valueOfField:BDSKCrossrefString inherit:NO];
	
	if ([crossref caseInsensitiveCompare:[pub citeKey]] == NSOrderedSame) {
		[self finalizeChanges];
		[self setupForm];
	}
}
 
- (void)typeInfoDidChange:(NSNotification *)aNotification{
	[self setupTypePopUp];
	[theBib makeType]; // make sure this is done now, and not later
	[self finalizeChanges];
	[self setupForm];
}

- (void)macrosDidChange:(NSNotification *)notification{
	id sender = [notification object];
	if([sender isKindOfClass:[BibDocument class]] && sender != theDocument)
		return; // only macro changes for our own document or the global macros
	
	NSArray *cells = [bibFields cells];
	NSEnumerator *cellE = [cells objectEnumerator];
	NSFormCell *entry = nil;
	NSString *value;
	
	while(entry = [cellE nextObject]){
		value = [theBib valueOfField:[entry title]];
		if([value isComplex])
			[entry setObjectValue:value];
	}
}

#pragma mark annote/abstract/rss

- (void)textDidBeginEditing:(NSNotification *)aNotification{
    // Add the mutableString of the text storage to the item's pubFields, so changes
    // are automatically tracked.  We still have to update the UI manually.
    // The contents of the text views are initialized with the current contents of the BibItem in windowWillLoad:
	currentEditedView = [aNotification object];
    if(currentEditedView == notesView){
        [theBib setField:BDSKAnnoteString toValue:[[notesView textStorage] mutableString]];
        [[theBib undoManager] setActionName:NSLocalizedString(@"Edit Annotation",@"")];
    } else if(currentEditedView == abstractView){
        [theBib setField:BDSKAbstractString toValue:[[abstractView textStorage] mutableString]];
        [[theBib undoManager] setActionName:NSLocalizedString(@"Edit Abstract",@"")];
    }else if(currentEditedView == rssDescriptionView){
        [theBib setField:BDSKRssDescriptionString toValue:[[rssDescriptionView textStorage] mutableString]];
        [[theBib undoManager] setActionName:NSLocalizedString(@"Edit RSS Description",@"")];
    }
}

// Clear all the undo actions when changing tab items, just in case; otherwise we
// crash if you edit in one view, switch tabs, switch back to the previous view and hit undo.
// We can't use textDidEndEditing, since just switching tabs doesn't change first responder.
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem{
    [notesViewUndoManager removeAllActions];
    [abstractViewUndoManager removeAllActions];
    [rssDescriptionViewUndoManager removeAllActions];
}

// sent by the notesView and the abstractView
- (void)textDidEndEditing:(NSNotification *)aNotification{
	currentEditedView = nil;
}

// sent by the notesView and the abstractView; this ensures that the annote/abstract preview gets updated
- (void)textDidChange:(NSNotification *)aNotification{
    NSNotification *notif = [NSNotification notificationWithName:BDSKPreviewDisplayChangedNotification object:nil];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notif 
                                               postingStyle:NSPostWhenIdle 
                                               coalesceMask:NSNotificationCoalescingOnName 
                                                   forModes:nil];
}

#pragma mark document interaction

- (void)docWillSave:(NSNotification *)notification{
	// NSDictionary *userInfo = [notification userInfo];
	
    if (![[self window] makeFirstResponder:[self window]]) {
        [[self window] endEditingFor:nil];
    }
}
	
- (void)bibWillBeRemoved:(NSNotification *)notification{
	// NSDictionary *userInfo = [notification userInfo];
	
	[self close];
}
	
- (void)docWindowWillClose:(NSNotification *)notification{
	// NSDictionary *userInfo = [notification userInfo];
	
	[[self window] close];
}

- (IBAction)showMacrosWindow:(id)sender{
    [theDocument showMacrosWindow:self];
}

// Note:  implementing setDocument or -document can have strange side effects with our document window controller array at present.
// every window controller subclass managed by the document needs to have this implemented in order for automatic closing/releasing,
// but we're doing it manually at present.
- (void)setDocument:(NSDocument *)d{
}

// these methods are for crossref interaction with the form
- (void)openParentItem:(id)sender{
    BibItem *parent = [theBib crossrefParent];
    if(parent)
        [theDocument editPub:parent];
}

- (void)arrowClickedInFormCell:(id)cell{
	[self openParentItem:nil];
}

- (BOOL)formCellHasArrowButton:(id)cell{
	return ([[theBib valueOfField:[cell title]] isInherited] || 
			([[cell title] isEqualToString:BDSKCrossrefString] && [theBib crossrefParent]));
}


#pragma mark snoop drawer stuff

// update the arrow image direction when the window changes
- (void)windowDidMove:(NSNotification *)aNotification{
    [self updateDocumentSnoopButton];
}

- (void)windowDidResize:(NSNotification *)notification{
    [self updateDocumentSnoopButton];
}

- (void)updateDocumentSnoopButton
{
	NSView *requiredSnoopContainerView = (NSView *)[[documentSnoopButton selectedItem] representedObject];
    NSString *lurl = [theBib localURLPath];
    NSString *rurl = [theBib valueOfField:BDSKUrlString];
	int state = 0;
	
	if ([documentSnoopDrawer contentView] == requiredSnoopContainerView &&
		( [documentSnoopDrawer state] == NSDrawerOpenState ||
		  [documentSnoopDrawer state] == NSDrawerOpeningState) )
		state |= BDSKDrawerStateOpenMask;
	if ([documentSnoopDrawer edge] == NSMaxXEdge)
		state |= BDSKDrawerStateRightMask;
	if (requiredSnoopContainerView == webSnoopContainerView)
		state |= BDSKDrawerStateWebMask;
	if (requiredSnoopContainerView == textSnoopContainerView)
		state |= BDSKDrawerStateTextMask;
	
	if (state == drawerState)
		return; // we don't need to change the button
	
	drawerState = state;
	
	if ( (state & BDSKDrawerStateOpenMask) || 
		 ((state & BDSKDrawerStateWebMask) && [NSURL URLWithString:rurl] && ![rurl isEqualToString:@""]) ||
		 (!(state & BDSKDrawerStateWebMask) && lurl && [[NSFileManager defaultManager] fileExistsAtPath:lurl]) ) {
		
		NSString *badgeType = @"pdf";
		if (state & BDSKDrawerStateWebMask)
			badgeType = @"webloc";
		else if (state & BDSKDrawerStateTextMask)
			badgeType = @"txt";
		NSImage *drawerImage = [NSImage imageNamed:@"drawerRight"];
		NSImage *arrowImage = [NSImage imageNamed:@"drawerArrow"];
		NSImage *badgeImage = [[NSWorkspace sharedWorkspace] iconForFileType:badgeType];
		NSRect iconRect = NSMakeRect(0, 0, 32, 32);
		NSSize arrowSize = [arrowImage size];
		NSRect arrowRect = NSMakeRect(0, 0, arrowSize.width, arrowSize.height);
		NSRect arrowDrawRect = NSMakeRect(29 - arrowSize.width, ceil((32-arrowSize.height)/2), arrowSize.width, arrowSize.height);
		NSRect badgeDrawRect = NSMakeRect(15, 0, 16, 16);
		NSImage *image = [[[NSImage alloc] initWithSize:iconRect.size] autorelease];
		
		if (state & BDSKDrawerStateRightMask) {
			if (state & BDSKDrawerStateOpenMask)
				arrowImage = [arrowImage imageFlippedHorizontally];
		} else {
			arrowDrawRect.origin.x = 3;
			badgeDrawRect.origin.x = 1;
			drawerImage = [drawerImage imageFlippedHorizontally];
			if (!(state & BDSKDrawerStateOpenMask))
				arrowImage = [arrowImage imageFlippedHorizontally];
		}
		
		[image lockFocus];
		[drawerImage drawInRect:iconRect fromRect:iconRect  operation:NSCompositeSourceOver  fraction: 1.0];
		[badgeImage drawInRect:badgeDrawRect fromRect:iconRect  operation:NSCompositeSourceOver  fraction: 1.0];
		[arrowImage drawInRect:arrowDrawRect fromRect:arrowRect  operation:NSCompositeSourceOver  fraction: 1.0];
		[image unlockFocus];
		
        [documentSnoopButton fadeIconImageToImage:image];
		
		if (state & BDSKDrawerStateOpenMask) {
			[documentSnoopToolbarItem setToolTip:NSLocalizedString(@"Close Drawer", @"Close drawer")];
		} else if (state & BDSKDrawerStateWebMask) {
			[documentSnoopToolbarItem setToolTip:NSLocalizedString(@"View Remote URL in Drawer", @"View remote URL in drawer")];
		} else if (state & BDSKDrawerStateTextMask) {
			[documentSnoopToolbarItem setToolTip:NSLocalizedString(@"View File as Text in Drawer", @"View file as text in drawer")];
		} else {
			[documentSnoopToolbarItem setToolTip:NSLocalizedString(@"View File in Drawer", @"View file in drawer")];
		}
		
		[documentSnoopButton setIconActionEnabled:YES];
	}
	else {
        [documentSnoopButton setIconImage:[NSImage imageNamed:@"drawerDisabled"]];
		
		if (state & BDSKDrawerStateOpenMask) {
			[documentSnoopToolbarItem setToolTip:NSLocalizedString(@"Close Drawer", @"Close drawer")];
		} else {
			[documentSnoopToolbarItem setToolTip:NSLocalizedString(@"Choose Content to View in Drawer", @"Choose content to view in drawer")];
		}
		
		[documentSnoopButton setIconActionEnabled:NO];
	}
}

- (void)updateSnoopDrawerContent{
	if ([documentSnoopDrawer contentView] == pdfSnoopContainerView) {

		NSString *lurl = [theBib localURLPath];
		if (!lurl || pdfSnoopViewLoaded) return;

        if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3){
            [documentSnoopImageView loadFromPath:lurl];
            [documentSnoopScrollView setDocumentViewAlignment:NSImageAlignTopLeft];
        } else {
#ifdef BDSK_USING_TIGER
            id pdfDocument = [[NSClassFromString(@"PDFDocument") alloc] initWithURL:[NSURL fileURLWithPath:lurl]];
            id pdfView = [[pdfSnoopContainerView subviews] objectAtIndex:0];
            [(BDSKZoomablePDFView *)pdfView setDocument:pdfDocument];
            [pdfDocument release];
#endif
        }
        pdfSnoopViewLoaded = YES;
	}
	else if ([documentSnoopDrawer contentView] == textSnoopContainerView) {
		NSString *lurl = [theBib localURLPath];
		if (!lurl) return;
        if (!textSnoopViewLoaded) {
			NSString *cmdString = [NSString stringWithFormat:@"%@/pdftotext -f 1 -l 1 \"%@\" -",[[NSBundle mainBundle] resourcePath], lurl, nil];
            NSString *textSnoopString = [[BDSKShellTask shellTask] runShellCommand:cmdString withInputString:nil];
			[documentSnoopTextView setString:textSnoopString];
			textSnoopViewLoaded = YES;
        }
	}
	else if ([documentSnoopDrawer contentView] == webSnoopContainerView) {
		if (!webSnoopViewLoaded) {
			NSString *rurl = [theBib valueOfField:BDSKUrlString];
			if ([rurl isEqualToString:@""]) return;
			[[remoteSnoopWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:rurl]]];
			webSnoopViewLoaded = YES;
		}
	}
}

- (void)toggleSnoopDrawer:(id)sender{
	NSView *requiredSnoopContainerView = (NSView *)[sender representedObject];
	
	// we force a reload, as the user might have browsed
	if (requiredSnoopContainerView == webSnoopContainerView) 
		webSnoopViewLoaded = NO;
	
	if ([documentSnoopDrawer contentView] == requiredSnoopContainerView) {
		[documentSnoopDrawer toggle:sender];
	} else {
        [documentSnoopDrawer setContentView:requiredSnoopContainerView];
		[documentSnoopDrawer close:sender];
		[documentSnoopDrawer open:sender];
	}
	// we remember the last item that was selected in the preferences, so it sticks between windows
	[[OFPreferenceWrapper sharedPreferenceWrapper] setInteger:[documentSnoopButton indexOfSelectedItem]
													   forKey:BDSKSnoopDrawerContentKey];
}

- (void)drawerWillOpen:(NSNotification *)notification{
	[self updateSnoopDrawerContent];
	
	if([[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKSnoopDrawerSavedSizeKey] != nil)
        [documentSnoopDrawer setContentSize:NSSizeFromString([[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKSnoopDrawerSavedSizeKey])];
    [documentSnoopScrollView scrollToTop];
}

- (void)drawerDidOpen:(NSNotification *)notification{
	[self updateDocumentSnoopButton];
}

- (void)drawerWillClose:(NSNotification *)notification{
	[[self window] makeFirstResponder:nil]; // this is necessary to avoid a crash after browsing
}

- (void)drawerDidClose:(NSNotification *)notification{
	[self updateDocumentSnoopButton];
}

- (NSSize)drawerWillResizeContents:(NSDrawer *)sender toSize:(NSSize)contentSize{
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:NSStringFromSize(contentSize) forKey:BDSKSnoopDrawerSavedSizeKey];
    return contentSize;
}

- (BOOL)windowShouldClose:(id)sender{
    NSString *errMsg = nil;
    NSString *alternateButtonTitle = nil;
    
    // case 1: the item has not been edited
    if(![theBib hasBeenEdited]){
        errMsg = NSLocalizedString(@"The item has not been edited.  Would you like to keep it?", @"");
        // only give the option to discard if the bib has not been edited; otherwise, it's likely that autofile/autogen citekey just hasn't happened yet
        alternateButtonTitle = NSLocalizedString(@"Discard", @"");
    // case 2: cite key hasn't been set, and paper needs to be filed
    }else if([[theBib citeKey] isEqualToString:@"cite-key"] && [theBib needsToBeFiled] && [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKFilePapersAutomaticallyKey]){
        errMsg = NSLocalizedString(@"The cite key for this entry has not been set, and AutoFile did not have enough information to file the paper.  Would you like to keep it as-is?", @"");
    // case 3: only the paper needs to be filed
    }else if([theBib needsToBeFiled] && [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKFilePapersAutomaticallyKey]){
        errMsg = NSLocalizedString(@"AutoFile did not have enough information to file this paper.  Would you like to keep it as-is?", @"");
    // case 4: only the cite key needs to be set
    }else if([[theBib citeKey] isEqualToString:@"cite-key"]){
        errMsg = NSLocalizedString(@"The cite key for this entry has not been set.  Would you like to keep it as-is?", @"");
	// case 5: good to go
    }else{
        return YES;
    }
	
    NSBeginAlertSheet(NSLocalizedString(@"Warning!", @""),
                      NSLocalizedString(@"Keep", @""),   //default button NSAlertDefaultReturn
                      alternateButtonTitle,              //far left button NSAlertAlternateReturn
                      NSLocalizedString(@"Cancel", @""), //middle button NSAlertOtherReturn
                      [self window],
                      self, // modal delegate
                      @selector(shouldCloseSheetDidEnd:returnCode:contextInfo:),
                      NULL, // did dismiss sel
                      NULL,
                      errMsg);
    return NO; // this method returns before the callback

}

- (void)shouldCloseSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    switch (returnCode){
        case NSAlertOtherReturn:
            break; // do nothing
        case NSAlertAlternateReturn:
            [[theBib retain] autorelease]; // make sure it stays around till we're closed
            [[theBib document] removePublication:theBib]; // now fall through to default
        default:
            [sheet orderOut:nil];
            [self close];
    }
}

- (void)windowWillClose:(NSNotification *)notification{
 //@@citekey   [[self window] makeFirstResponder:citeKeyField]; // makes the field check if there is a duplicate field.
	[self finalizeChanges];
    [macroTextFieldWC close]; // close so it's not hanging around by itself; this works if the doc window closes, also
    [documentSnoopDrawer close];
    [theDocument removeWindowController:self];
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems{
	NSMutableArray *menuItems = [NSMutableArray arrayWithCapacity:8];
	NSMenuItem *item;
	
	NSEnumerator *iEnum = [defaultMenuItems objectEnumerator];
	while (item = [iEnum nextObject]) { 
		if ([item tag] == WebMenuItemTagCopy ||
			[item tag] == WebMenuItemTagCopyLinkToClipboard ||
			[item tag] == WebMenuItemTagCopyImageToClipboard) {
			
			[menuItems addObject:item];
		}
	}
	if ([menuItems count] > 0) 
		[menuItems addObject:[NSMenuItem separatorItem]];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Back",@"Back")
									  action:@selector(goBack:)
							   keyEquivalent:@""];
	[menuItems addObject:[item autorelease]];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Forward",@"Forward")
									  action:@selector(goForward:)
							   keyEquivalent:@""];
	[menuItems addObject:[item autorelease]];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reload",@"Reload")
									  action:@selector(reload:)
							   keyEquivalent:@""];
	[menuItems addObject:[item autorelease]];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Stop",@"Stop")
									  action:@selector(stopLoading:)
							   keyEquivalent:@""];
	[menuItems addObject:[item autorelease]];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Increase Text Size",@"Increase Text Size")
									  action:@selector(makeTextLarger:)
							   keyEquivalent:@""];
	[menuItems addObject:[item autorelease]];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Decrease Text Size",@"Increase Text Size")
									  action:@selector(makeTextSmaller:)
							   keyEquivalent:@""];
	[menuItems addObject:[item autorelease]];
	
	[menuItems addObject:[NSMenuItem separatorItem]];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Save as Local File",@"Save as local file")
									  action:@selector(saveFileAsLocalUrl:)
							   keyEquivalent:@""];
	[item setTarget:self];
	[menuItems addObject:[item autorelease]];
	
	return menuItems;
}

- (void)saveFileAsLocalUrl:(id)sender{
	WebDataSource *dataSource = [[remoteSnoopWebView mainFrame] dataSource];
	if (!dataSource || [dataSource isLoading]) 
		return;
	
	NSString *fileName = [[[[dataSource request] URL] relativePath] lastPathComponent];
	NSString *extension = [fileName pathExtension];
   
	NSSavePanel *sPanel = [NSSavePanel savePanel];
    if (![extension isEqualToString:@""]) 
		[sPanel setRequiredFileType:extension];
    int result = [sPanel runModalForDirectory:nil file:fileName];
    if (result == NSOKButton) {
		if ([[dataSource data] writeToFile:[sPanel filename] atomically:YES]) {
			NSString *fileURLString = [[NSURL fileURLWithPath:[sPanel filename]] absoluteString];
			
			[theBib setField:BDSKLocalUrlString toValue:fileURLString];
			[theBib autoFilePaper];
			
			[[[self window] undoManager] setActionName:NSLocalizedString(@"Edit Publication",@"")];
		} else {
			NSLog(@"Could not write downloaded file.");
		}
    }
}

- (void)downloadLinkedFileAsLocalUrl:(id)sender{
	NSURL *linkURL = (NSURL *)[sender representedObject];
	// not yet implemented 
}

#pragma mark undo manager

// we want to have the same undoManager as our document, so we use this 
// NSWindow delegate method to return the doc's undomanager, except for
// the abstract/annote/rss text views.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender{
    // work around for a bug(?) in Panther, as the main menu appears to use this method rather than -undoManagerForTextView:
	id firstResponder = [sender firstResponder];
	if(firstResponder == notesView)
        return notesViewUndoManager;
    else if(firstResponder == abstractView)
        return abstractViewUndoManager;
    else if(firstResponder == rssDescriptionView)
        return rssDescriptionViewUndoManager;
	
	return [theDocument undoManager];
}


#pragma mark author table view datasource methods

- (int)numberOfRowsInTableView:(NSTableView *)tableView{
	return [theBib numberOfAuthors];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn 
			row:(int)row{
	NSString *tcid = [tableColumn identifier];
	
	if([tcid isEqualToString:@"name"]){
		return [[theBib authorAtIndex:row] name];
	}else{
		return @"";
	}
}


- (IBAction)showPersonDetailCmd:(id)sender{
	if (sender != authorTableView)
		[authorTableView selectAll:self];
	// find selected author
    NSEnumerator *e = [authorTableView selectedRowEnumerator]; //@@ 10.3 deprecated for IndexSets
	NSNumber *idx = nil;
	while (idx = [e nextObject]){
		int i = [idx intValue];
		BibAuthor *auth = [theBib authorAtIndex:i];
		[self showPersonDetail:auth];
	}
}

- (void)showPersonDetail:(BibAuthor *)person{
	BibPersonController *pc = [person personController];
	if(pc == nil){
            pc = [[BibPersonController alloc] initWithPerson:person document:theDocument];
            [theDocument addWindowController:pc];
            [pc release];
	}
	[pc show];
}


- (IBAction)addAuthors:(id)sender{
	[NSApp beginSheet:addAuthorSheet
	   modalForWindow:[self window]
		modalDelegate:self
	   didEndSelector:@selector(addAuthorSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
}

- (IBAction)dismissAddAuthorSheet:(id)sender{
    [addAuthorSheet orderOut:sender];
    [NSApp endSheet:addAuthorSheet returnCode:[sender tag]];
}

// tag, and hence return code is 0 for OK and 1 for cancel.
// called upon dismissal
- (void)addAuthorSheetDidEnd:(NSWindow *)sheet
                 returnCode:(int) returnCode
                contextInfo:(void *)contextInfo{
	NSString *str = [addAuthorTextView string];
	if(returnCode == 0){
		
		NSArray *lines = [str componentsSeparatedByString:@"\n"];
		NSLog(@"lines are [%@] on add authors", lines);
	}else{
		// do nothing, user cancelled
	}
	[addAuthorTextView setString:@""];
}




@end