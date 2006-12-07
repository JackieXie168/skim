//
//  BDSKTextImportController.m
//  BibDesk
//
//  Created by Michael McCracken on 4/13/05.
/*
 This software is Copyright (c) 2005,2006
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

#import "BDSKTextImportController.h"
#import "BDSKFormCellFormatter.h"
#import "BDSKCiteKeyFormatter.h"
#import "BDSKFieldNameFormatter.h"
#import "BDSKEdgeView.h"
#import <WebKit/WebKit.h>
#import "BibDocument.h"
#import "RYZImagePopUpButtonCell.h"
#import "NSFileManager_BDSKExtensions.h"
#import "BibAppController.h"
#import "BDSKFieldEditor.h"

@interface BDSKTextImportController (Private)

- (void)loadPasteboardData;
- (void)showWebViewWithURLString:(NSString *)urlString;
- (void)setShowingWebView:(BOOL)showWebView;
- (void)setupTypeUI;
- (void)setType:(NSString *)type;

- (void)sheetDidEnd:(NSPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)urlSheetDidEnd:(NSPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)addFieldSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)setLoading:(BOOL)loading;

- (void)cancelDownload;
- (void)setLocalUrlFromDownload;
- (void)setDownloading:(BOOL)downloading;
- (void)saveDownloadPanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (BOOL)addCurrentSelectionToFieldAtIndex:(int)index;

- (void)startTemporaryTypeAheadMode;
- (void)endTemporaryTypeAheadModeAndSet:(BOOL)flag;
- (BOOL)isInTemporaryTypeAheadMode;

- (void)addBookmarkWithURLString:(NSString *)URLString title:(NSString *)title;
- (void)saveBookmarks;
- (void)addBookmarkSheetDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (BOOL)editSelectedCellAsMacro;

@end

@implementation BDSKTextImportController

- (id)initWithDocument:(BibDocument *)doc{
    self = [super initWithWindowNibName:[self windowNibName]];
    if(self){
        document = doc;
        item = [[BibItem alloc] init];
        fields = [[NSMutableArray alloc] init];
		bookmarks = [[NSMutableArray alloc] init];
        showingWebView = NO;
        itemsAdded = [[NSMutableArray alloc] init];
		webSelection = nil;
		tableCellFormatter = [[BDSKFormCellFormatter alloc] initWithDelegate:self macroResolver:doc];
		crossrefFormatter = [[BDSKCiteKeyFormatter alloc] init];
		
		NSString *applicationSupportPath = [[[NSFileManager defaultManager] applicationSupportDirectory:kUserDomain] stringByAppendingPathComponent:@"BibDesk"]; 
		NSString *bookmarksPath = [applicationSupportPath stringByAppendingPathComponent:@"Bookmarks.plist"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:bookmarksPath]) {
			NSEnumerator *bEnum = [[[NSMutableArray alloc] initWithContentsOfFile:bookmarksPath] objectEnumerator];
			NSDictionary *bm;
			
			while(bm = [bEnum nextObject]){
				[bookmarks addObject:[[bm mutableCopy] autorelease]];
			}
		}
		macroTextFieldWC = [[MacroTableViewWindowController alloc] init];
    }
    return self;
}

- (void)dealloc{
    OBASSERT(download == nil);
    [item release];
    [fields release];
    [bookmarks release];
    [itemsAdded release];
    [tableCellFormatter release];
    [crossrefFormatter release];
    [sourceBox release];
    [webViewView release];
	[macroTextFieldWC release];
	[webSelection release];
    [tableFieldEditor release];
    [super dealloc];
}

- (NSString *)windowNibName { return @"TextImport"; }

- (void)awakeFromNib{
	[itemTableView registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
    [statusLine setStringValue:@""];
	[webViewBox setEdges:BDSKEveryEdgeMask];
	[webViewBox setColor:[NSColor lightGrayColor] forEdge:NSMaxYEdge];
	[webViewBox setContentView:webView];
    [self setupTypeUI];
    [sourceBox retain];
    [webViewView retain];
	[webView setEditingDelegate:self];
    [itemTableView setDoubleAction:@selector(addTextToCurrentFieldAction:)];
    [self setWindowFrameAutosaveName:@"BDSKTextImportController Frame Autosave Name"];
	[fieldNameField setFormatter:[[[BDSKFieldNameFormatter alloc] init] autorelease]];
	// Set the properties of actionMenuButton that cannot be set in IB
	[actionMenuButton setAlternateImage:[NSImage imageNamed:@"Action_Pressed"]];
	[actionMenuButton setArrowImage:nil];
	[actionMenuButton setShowsMenuWhenIconClicked:YES];
	[[actionMenuButton cell] setAltersStateOfSelectedItem:NO];
	[[actionMenuButton cell] setAlwaysUsesFirstItemAsSelected:NO];
	[[actionMenuButton cell] setUsesItemFromMenu:NO];
	[[actionMenuButton cell] setRefreshesMenu:NO];
}

#pragma mark Calling the main sheet

- (void)beginSheetForPasteboardModalForWindow:(NSWindow *)docWindow modalDelegate:(id)modalDelegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo{
	// we start with the pasteboard data, so we can directly show the main sheet 
	NSParameterAssert([self window]); // make sure we loaded the nib
	[self loadPasteboardData];
	
	// remember the arguments to pass in the callback later
	theDocWindow = docWindow;
	theModalDelegate = modalDelegate;
	theDidEndSelector = didEndSelector;
	theContextInfo = contextInfo;
	
	[self retain]; // make sure we stay around till we are done
	
	[NSApp beginSheet:[self window]
	   modalForWindow:docWindow
		modalDelegate:self
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) 
		  contextInfo:NULL];
}

- (void)beginSheetForWebModalForWindow:(NSWindow *)docWindow modalDelegate:(id)modalDelegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo{
	// we start with a webview, so we first ask for the URL to load
	NSParameterAssert([self window]); // make sure we loaded the nib
	[self setShowingWebView:YES];
	
	// load the popup buttons with our bookmarks
	NSEnumerator *bEnum = [bookmarks objectEnumerator];
	NSDictionary *bm;
	
	[bookmarkPopUpButton removeAllItems];
	[bookmarkPopUpButton addItemWithTitle:NSLocalizedString(@"Bookmarks",@"Bookmarks")];
	while (bm = [bEnum nextObject]) {
		[bookmarkPopUpButton addItemWithTitle:[bm objectForKey:@"Title"]];
	}
	
	// remember the arguments to pass in the callback later
	theDocWindow = [docWindow retain];
	theModalDelegate = [modalDelegate retain];
	theDidEndSelector = didEndSelector;
	theContextInfo = contextInfo;
	
	[self retain]; // make sure we stay around till we are done
	
	// now show the URL sheet. We will show the main sheet when that is done.
	[NSApp beginSheet:urlSheet
	   modalForWindow:docWindow
		modalDelegate:self
	   didEndSelector:@selector(urlSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:[[NSNumber alloc] initWithBool:YES]];
}
		
- (void)beginSheetForFileModalForWindow:(NSWindow *)docWindow modalDelegate:(id)modalDelegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo{
	// we start with a file, so we first ask for the file to load
	NSParameterAssert([self window]); // make sure we loaded the nib
	
	// remember the arguments to pass in the callback later
	theDocWindow = docWindow;
	theModalDelegate = modalDelegate;
	theDidEndSelector = didEndSelector;
	theContextInfo = contextInfo;
	
	[self retain]; // make sure we stay around till we are done
	
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	[oPanel setAllowsMultipleSelection:NO];
	[oPanel setCanChooseDirectories:NO];

	[oPanel beginSheetForDirectory:nil 
							  file:nil 
							 types:nil
					modalForWindow:docWindow
					 modalDelegate:self 
					didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
					   contextInfo:[[NSNumber alloc] initWithBool:YES]];
}

#pragma mark Actions

- (IBAction)addItemAction:(id)sender{
    // make the tableview stop editing:
    [[self window] makeFirstResponder:[self window]];
    
	[itemsAdded addObject:item];
    [document addPublication:item];
	[item setCiteKey:[item suggestedCiteKey]]; // only now can we generate, due to unique specifiers
	[item release];
	
	int numItems = [itemsAdded count];
	NSString *pubSingularPlural = (numItems == 1) ? NSLocalizedString(@"publication", @"publication") : NSLocalizedString(@"publications", @"publications");
    [statusLine setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%d %@ added.", @"format string for pubs added. args: one int for number added, then one string for singular or plural of publication(s)."), numItems, pubSingularPlural]];

    item = [[BibItem alloc] init];
    [itemTypeButton selectItemWithTitle:[item type]];
    [itemTableView reloadData];
}

- (IBAction)closeAction:(id)sender{
    // make the tableview stop editing:
    [[self window] makeFirstResponder:[self window]];
    [NSApp endSheet:[self window] returnCode:[sender tag]]; 
	// closing the window will be done in the callback
}

- (IBAction)addItemAndCloseAction:(id)sender{
	[self addItemAction:sender];
	[self closeAction:sender];
}

- (IBAction)showHelpAction:(id)sender{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"Adding-References-From-Text-Sources" inBook:@"BibDesk Help"];
}

- (IBAction)addTextToCurrentFieldAction:(id)sender{
    
    if ([self addCurrentSelectionToFieldAtIndex:[sender selectedRow]] == NO)
        NSBeep();
}

- (IBAction)changeTypeOfBibAction:(id)sender{
    NSString *type = [[sender selectedItem] title];
    [self setType:type];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:type
                                                      forKey:BDSKPubTypeStringKey];

	[[item undoManager] setActionName:NSLocalizedString(@"Change Type",@"")];
    [itemTableView reloadData];
}

- (IBAction)importFromPasteboardAction:(id)sender{
	[self loadPasteboardData];
}

- (IBAction)importFromWebAction:(id)sender{
	NSEnumerator *bEnum = [bookmarks objectEnumerator];
	NSDictionary *bm;
	
	[bookmarkPopUpButton removeAllItems];
	[bookmarkPopUpButton addItemWithTitle:NSLocalizedString(@"Bookmarks",@"Bookmarks")];
	while (bm = [bEnum nextObject]) {
		[bookmarkPopUpButton addItemWithTitle:[bm objectForKey:@"Title"]];
	}
	
	[NSApp beginSheet:urlSheet
       modalForWindow:[self window]
        modalDelegate:self
       didEndSelector:@selector(urlSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (IBAction)dismissUrlSheet:(id)sender{
    [urlSheet orderOut:sender];
    [NSApp endSheet:urlSheet returnCode:[sender tag]];
}

- (IBAction)importFromFileAction:(id)sender{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];

    [oPanel beginSheetForDirectory:nil 
                              file:nil 
							 types:nil
                    modalForWindow:[self window]
                     modalDelegate:self 
                    didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
                       contextInfo:nil];
}

- (IBAction)chooseBookmarkAction:(id)sender{
	int index = [bookmarkPopUpButton indexOfSelectedItem];
	NSString *URLString = [[bookmarks objectAtIndex:index-1] objectForKey:@"URLString"];
	[urlTextField setStringValue:URLString];
    
	[urlSheet orderOut:sender];
    [NSApp endSheet:urlSheet returnCode:1];
}

- (IBAction)dismissAddBookmarkSheet:(id)sender{
    [addBookmarkSheet orderOut:sender];
    [NSApp endSheet:addBookmarkSheet returnCode:[sender tag]];
}

- (IBAction)stopOrReloadAction:(id)sender{
	if(isDownloading){
		[self setDownloading:NO];
	}else if (isLoading){
		[webView stopLoading:sender];
	}else{
		[webView reload:sender];
	}
}

- (IBAction)addField:(id)sender{
    [fieldNameField setStringValue:@""];
    [NSApp beginSheet:addFieldSheet
       modalForWindow:[self window]
        modalDelegate:self
       didEndSelector:@selector(addFieldSheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
}

- (IBAction)dismissAddFieldSheet:(id)sender{
    [addFieldSheet orderOut:sender];
    [NSApp endSheet:addFieldSheet returnCode:[sender tag]];
}

- (IBAction)editSelectedFieldAsRawBibTeX:(id)sender{
	int row = [itemTableView selectedRow];
	if (row == -1) 
		return;
    [self editSelectedCellAsMacro];
	if([itemTableView editedRow] != row)
		[itemTableView editColumn:2 row:row withEvent:nil select:YES];
}

#pragma mark WebView contextual menu actions

- (void)copyLocationAsRemoteUrl:(id)sender{
	NSString *URLString = [[[[[webView mainFrame] dataSource] request] URL] absoluteString];
	
	if (URLString) {
		[item setField:BDSKUrlString toValue:URLString];
		[[item undoManager] setActionName:NSLocalizedString(@"Edit Publication",@"")];
		[itemTableView reloadData];
	}
}

- (void)copyLinkedLocationAsRemoteUrl:(id)sender{
	NSString *URLString = [(NSURL *)[sender representedObject] absoluteString];
	
	if (URLString) {
		[item setField:BDSKUrlString toValue:URLString];
		[[item undoManager] setActionName:NSLocalizedString(@"Edit Publication",@"")];
		[itemTableView reloadData];
	}
}

- (void)saveFileAsLocalUrl:(id)sender{
	WebDataSource *dataSource = [[webView mainFrame] dataSource];
	if (!dataSource || [dataSource isLoading]) 
		return;
	
	NSString *fileName = [[[[dataSource request] URL] relativePath] lastPathComponent];
	NSString *extension = [fileName pathExtension];

    NSSavePanel *sPanel = [NSSavePanel savePanel];
    if (![extension isEqualToString:@""]) 
		[sPanel setRequiredFileType:extension];
    if([sPanel respondsToSelector:@selector(setCanCreateDirectories:)])
		[sPanel setCanCreateDirectories:YES];

    [sPanel beginSheetForDirectory:nil 
                              file:fileName 
                    modalForWindow:[self window]
                     modalDelegate:self 
                    didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:) 
                       contextInfo:nil];
}

- (void)downloadLinkedFileAsLocalUrl:(id)sender{
	NSURL *linkURL = (NSURL *)[sender representedObject];
    if (isDownloading)
        return;
	if (linkURL) {
		download = [[WebDownload alloc] initWithRequest:[NSURLRequest requestWithURL:linkURL] delegate:self];
	}
	if (!download) {
		NSBeginAlertSheet(NSLocalizedString(@"Invalid or unsupported URL",@""),
						  nil, nil, nil, 
						  [self window], 
						  nil, nil, nil, nil,
						  NSLocalizedString(@"The URL to download is either invalid or unsupported.",@""));
	}
}

- (void)bookmarkPage:(id)sender{
	WebDataSource *datasource = [[webView mainFrame] dataSource];
	NSString *URLString = [[[datasource request] URL] absoluteString];
	NSString *title = [datasource pageTitle];
	if(title == nil) title = [URLString lastPathComponent];
	
	[self addBookmarkWithURLString:URLString title:title];
}

- (void)bookmarkLink:(id)sender{
	NSDictionary *element = (NSDictionary *)[sender representedObject];
	NSString *URLString = [(NSURL *)[element objectForKey:WebElementLinkURLKey] absoluteString];
	NSString *title = [element objectForKey:WebElementLinkLabelKey];
	if(title == nil) title = [URLString lastPathComponent];
	
	[self addBookmarkWithURLString:URLString title:title];
}

@end


@implementation BDSKTextImportController (Private)

#pragma mark Setup

- (void)loadPasteboardData{
    NSPasteboard* pb = [NSPasteboard generalPasteboard];

    NSArray *typeArray = [NSArray arrayWithObjects:NSURLPboardType, NSRTFDPboardType, 
        NSRTFPboardType, NSStringPboardType, nil];
    
    NSString *pbType = [pb availableTypeFromArray:typeArray];    
    if([pbType isEqualToString:NSURLPboardType]){
        // setup webview and load page
        
		[self setShowingWebView:YES];
        
        NSArray *urls = (NSArray *)[pb propertyListForType:pbType];
        NSURL *url = [NSURL URLWithString:[urls objectAtIndex:0]];
        NSURLRequest *urlreq = [NSURLRequest requestWithURL:url];
        
        [[webView mainFrame] loadRequest:urlreq];
        
    }else{
		
		[self setShowingWebView:NO];
		
        NSString *pbString = nil;
        NSData *pbData;
        
		if([pbType isEqualToString:NSRTFPboardType]){
            pbData = [pb dataForType:pbType];
            pbString = [[[NSAttributedString alloc] initWithRTF:pbData
                                             documentAttributes:NULL] autorelease];
            pbString = [[(NSAttributedString *)pbString string] stringByRemovingSurroundingWhitespace];

            if([pbString rangeOfString:@"http://"].location == 0){
                [self showWebViewWithURLString:pbString];
            }else{
                NSRange r = NSMakeRange(0,[[sourceTextView string] length]);
                [sourceTextView replaceCharactersInRange:r withRTF:pbData];
			}
            
		}else if([pbType isEqualToString:NSRTFDPboardType]){
            pbData = [pb dataForType:pbType];
            pbString = [[[NSAttributedString alloc] initWithRTFD:pbData
                                              documentAttributes:NULL] autorelease];
            pbString = [[(NSAttributedString *)pbString string] stringByRemovingSurroundingWhitespace];
            
            if([pbString rangeOfString:@"http://"].location == 0){
                [self showWebViewWithURLString:pbString];
            }else{
                NSRange r = NSMakeRange(0,[[sourceTextView string] length]);
                [sourceTextView replaceCharactersInRange:r withRTFD:pbData];
            }
            
		}else if([pbType isEqualToString:NSStringPboardType]){
            pbData = [pb dataForType:pbType];
            pbString = [pb stringForType:pbType];
            pbString = [pbString stringByRemovingSurroundingWhitespace];
			if([pbString rangeOfString:@"http://"].location == 0){
                [self showWebViewWithURLString:pbString];
            }else{
                [sourceTextView setString:pbString];
            }
		}else {
			
			[sourceTextView setString:NSLocalizedString(@"Sorry, BibDesk can't read this data type.", @"warning message when choosing \"new publication from pasteboard\" for an unsupported type")];
		}
	}
}

- (void)showWebViewWithURLString:(NSString *)urlString{
    [self setShowingWebView:YES];
    NSURL *url = [NSURL URLWithString:[urlString stringByRemovingSurroundingWhitespace]];
    NSURLRequest *urlreq = [NSURLRequest requestWithURL:url];
    
    [[webView mainFrame] loadRequest:urlreq];
        
}

- (void)setShowingWebView:(BOOL)showWebView{
	if (showWebView != showingWebView) {
		showingWebView = showWebView;
		if (showingWebView) {
			[webViewView setFrame:[sourceBox frame]];
			[splitView replaceSubview:sourceBox with:webViewView];
		} else {
			[splitView replaceSubview:webViewView with:sourceBox];
		}
	}
}

- (void)setupTypeUI{

    // setup the type popup:
    NSEnumerator *typeNamesE = [[[BibTypeManager sharedManager] bibTypesForFileType:[item fileType]] objectEnumerator];
    NSString *typeName = nil;
    
    [itemTypeButton removeAllItems];
    while(typeName = [typeNamesE nextObject]){
        [itemTypeButton addItemWithTitle:typeName];
    }
    
    NSString *type = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKPubTypeStringKey];
    
    [self setType:type];
    
    [itemTableView reloadData];
}

- (void)setType:(NSString *)type{
    
    [itemTypeButton selectItemWithTitle:type];
    [item setType:type];

    BibTypeManager *typeMan = [BibTypeManager sharedManager];

    [fields removeAllObjects];
    
    [fields addObjectsFromArray:[typeMan requiredFieldsForType:type]];
    [fields addObjectsFromArray:[typeMan optionalFieldsForType:type]];
	
	NSEnumerator *fieldEnum = [[typeMan userDefaultFieldsForType:type] objectEnumerator];
	NSString *field = nil;
	// the default fields can contain fields already contained in typeInfo
	while (field = [fieldEnum nextObject]) {
		if (![fields containsObject:field])
			[fields addObject:field];
	}
	if(![fields containsObject:BDSKLocalUrlString])
		[fields addObject:BDSKLocalUrlString];
	if(![fields containsObject:BDSKUrlString])
		[fields addObject:BDSKUrlString];
	if(![fields containsObject:BDSKAbstractString])
		[fields addObject:BDSKAbstractString];
	if(![fields containsObject:BDSKAnnoteString])
		[fields addObject:BDSKAnnoteString];
}

#pragma mark Sheet callbacks

- (void)sheetDidEnd:(NSPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	
	if (theModalDelegate != nil && theDidEndSelector != NULL) {
		NSMethodSignature *signature = [theModalDelegate methodSignatureForSelector:theDidEndSelector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:theDidEndSelector];
		[invocation setArgument:&self atIndex:2];
		[invocation setArgument:&returnCode atIndex:3];
		[invocation setArgument:&theContextInfo atIndex:4];
		[invocation invokeWithTarget:theModalDelegate];
	}
	
	theDocWindow = nil;
	theModalDelegate = nil;
	theDidEndSelector = NULL;
	theContextInfo = NULL;
	
	[[self window] orderOut:self];
	// cleanup
    [self cancelDownload];
	[webView stopLoading:nil];
	// select the items we just added
	[document highlightBibs:itemsAdded];
	[itemsAdded removeAllObjects];
	
	[self release]; // we are done, balance retain from beginSheet... methods
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
	// this variable is true when we called the open sheet initially before showing the main window 
	BOOL initialFileLoad = [[(NSNumber *)contextInfo autorelease] boolValue];
	
	if (initialFileLoad) {
		// this is the initial web load, the main window is not yet there
		
		if (returnCode == NSOKButton) {
			// show the main window
			
			[NSApp beginSheet:[self window]
			   modalForWindow:theDocWindow
				modalDelegate:self
			   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) 
				  contextInfo:NULL];
			
		} else {
			// the user cancelled. As we don't end the main sheet we have to call our didEndSelector ourselves
			
			[self sheetDidEnd:sheet returnCode:returnCode contextInfo:contextInfo];
			return;
		}
	}
	
	// now do the things we need to do always
    if(returnCode == NSOKButton){
        NSString *fileName = [sheet filename];
		NSURL *url = [NSURL fileURLWithPath:fileName];
		NSTextStorage *text = [sourceTextView textStorage];
		NSLayoutManager *layoutManager = [[text layoutManagers] objectAtIndex:0];

		[[text mutableString] setString:@""];	// Empty the document
		
		[self setShowingWebView:NO];
		
		[layoutManager retain];			// Temporarily remove layout manager so it doesn't do any work while loading
		[text removeLayoutManager:layoutManager];
		[text beginEditing];			// Bracket with begin/end editing for efficiency
		[text readFromURL:url options:nil documentAttributes:NULL];	// Read!
		[text endEditing];
		[text addLayoutManager:layoutManager];	// Hook layout manager back up
		[layoutManager release];

    }        
}

- (void)urlSheetDidEnd:(NSPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
	// this variable is true when we called the URL sheet initially before showing the main window 
	BOOL initialWebLoad = [[(NSNumber *)contextInfo autorelease] boolValue];
	
	if (initialWebLoad) {
		// this is the initial web load, the main window is not yet there
		
		// we need to release these, as we had retained them
		[theDocWindow autorelease];
		[theModalDelegate autorelease];
		
		if (returnCode == NSOKButton) {
			// show the main window
			
			[NSApp beginSheet:[self window]
			   modalForWindow:theDocWindow
				modalDelegate:self
			   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) 
				  contextInfo:NULL];
			
		} else {
			// the user cancelled. As we don't end the main sheet we have to call our didEndSelector ourselves
			
			[self sheetDidEnd:sheet returnCode:returnCode contextInfo:contextInfo];
			return;
		}
	}
	
	// now do the things we need to do always
    if(returnCode == NSOKButton){
		// setup webview and load page
        
		[self setShowingWebView:YES];
        
        NSString *urlString = [urlTextField stringValue];
        
        if([urlString rangeOfString:@"://"].location == NSNotFound)
            urlString = [@"http://" stringByAppendingString:urlString];
        
        NSURL *url = [NSURL URLWithString:urlString];
        
        if(url == nil){
            [sheet orderOut:nil];
            NSBeginAlertSheet(NSLocalizedString(@"Error", @""), nil, nil, nil, [self window], nil, nil, nil, nil, 
                              NSLocalizedString(@"Mac OS X does not recognize this as a valid URL.  Please re-enter the address and try again.", @"") );
        } else {        
            NSURLRequest *urlreq = [NSURLRequest requestWithURL:url];
            [[webView mainFrame] loadRequest:urlreq];
        }
    }        
}

- (void)addFieldSheetDidEnd:(NSWindow *)sheet
                 returnCode:(int)returnCode
                contextInfo:(void *)contextInfo{
    if(returnCode == NSOKButton){
        if(![fields containsObject:[fieldNameField stringValue]]){
			NSString *name = [[fieldNameField stringValue] capitalizedString]; // add it as a capitalized string to avoid duplicates
			int row = [fields count];
			
			[fields addObject:name];
			[item addField:name];
			[[item undoManager] setActionName:NSLocalizedString(@"Add Field",@"")];
			[itemTableView reloadData];
			[itemTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
			[itemTableView editColumn:2 row:row withEvent:nil select:YES];
        }
    }
    // else, nothing.
}

- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    
	if (returnCode == NSOKButton) {
		if ([[[[webView mainFrame] dataSource] data] writeToFile:[sheet filename] atomically:YES]) {
			NSString *fileURLString = [[NSURL fileURLWithPath:[sheet filename]] absoluteString];
			
			[item setField:BDSKLocalUrlString toValue:fileURLString];
			[item autoFilePaper];
			
			[[item undoManager] setActionName:NSLocalizedString(@"Edit Publication",@"")];
		} else {
			NSLog(@"Could not write downloaded file.");
		}
    }

    [itemTableView reloadData];
}

#pragma mark Page loading methods

- (void)setLoading:(BOOL)loading{
    if (isLoading != loading) {
        isLoading = loading;
        if (isLoading) {
			NSString *message = [NSString stringWithFormat:@"%@%C",NSLocalizedString(@"Loading page",@"Loading page"),0x2026];
			[progressIndicator setToolTip:message];
			[statusLine setStringValue:@""];
			[stopOrReloadButton setImage:[NSImage imageNamed:@"stop_small"]];
			[stopOrReloadButton setToolTip:NSLocalizedString(@"Stop loading page",@"Stop loading page")];
			[stopOrReloadButton setKeyEquivalent:@""];
			[progressIndicator startAnimation:self];
			[progressIndicator setToolTip:message];
			[statusLine setStringValue:message];
		} else {
			[stopOrReloadButton setImage:[NSImage imageNamed:@"reload_small"]];
			[stopOrReloadButton setToolTip:NSLocalizedString(@"Reload page",@"Reload page")];
			[stopOrReloadButton setKeyEquivalent:@"r"];
			[progressIndicator stopAnimation:self];
			[progressIndicator setToolTip:@""];
			[statusLine setStringValue:@""];
		}
	}
}

#pragma mark Download methods

- (void)cancelDownload{
	[download cancel];
	[self setDownloading:NO];
}

- (void)setLocalUrlFromDownload{
	NSString *fileURLString = [[NSURL fileURLWithPath:downloadFileName] absoluteString];
	
	[item setField:BDSKLocalUrlString toValue:fileURLString];
	[item autoFilePaper];
	
	[[item undoManager] setActionName:NSLocalizedString(@"Edit Publication",@"")];
	[itemTableView reloadData];
}

- (void)setDownloading:(BOOL)downloading{
    if (isDownloading != downloading) {
        isDownloading = downloading;
        if (isDownloading) {
			NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Downloading file. Received 0%%%C",@"Downloading file. Received 0%..."),0x2026];
			[progressIndicator setToolTip:message];
			[statusLine setStringValue:@""];
			[stopOrReloadButton setImage:[NSImage imageNamed:@"stop_small"]];
			[stopOrReloadButton setToolTip:NSLocalizedString(@"Cancel download",@"Cancel download")];
			[stopOrReloadButton setKeyEquivalent:@""];
            [progressIndicator startAnimation:self];
			[progressIndicator setToolTip:message];
			[statusLine setStringValue:message];
            [downloadFileName release];
			downloadFileName = nil;
        } else {
			[stopOrReloadButton setImage:[NSImage imageNamed:@"reload_small"]];
			[stopOrReloadButton setToolTip:NSLocalizedString(@"Reload page",@"Reload page")];
			[stopOrReloadButton setKeyEquivalent:@"r"];
            [progressIndicator stopAnimation:self];
			[progressIndicator setToolTip:@""];
			[statusLine setStringValue:@""];
            [download release];
            download = nil;
            receivedContentLength = 0;
        }
    }
}

- (void)saveDownloadPanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    if (returnCode == NSOKButton) {
        [download setDestination:[sheet filename] allowOverwrite:YES];
    } else {
        [self cancelDownload];
    }
}

#pragma mark Bookmark methods

- (void)addBookmarkWithURLString:(NSString *)URLString title:(NSString *)title{
	[bookmarkField setStringValue:title];
	
	[NSApp beginSheet:addBookmarkSheet
       modalForWindow:[self window]
        modalDelegate:self
       didEndSelector:@selector(addBookmarkSheetDidEnd:returnCode:contextInfo:)
          contextInfo:[URLString retain]];
}

- (void)addBookmarkSheetDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    NSString *URLString = (NSString *)contextInfo;
	if (returnCode == NSOKButton) {
		NSMutableDictionary *bookmark = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										URLString, @"URLString", [bookmarkField stringValue], @"Title", nil];
		[bookmarks addObject:bookmark];
		
		[self saveBookmarks];
	}
	[URLString release]; //the contextInfo was retained
}

- (void)saveBookmarks{
	NSString *error = nil;
	NSData *data = [NSPropertyListSerialization dataFromPropertyList:bookmarks
															  format:NSPropertyListXMLFormat_v1_0 
													errorDescription:&error];
	if (error) {
		NSLog(@"Error writing bookmarks: %@", error);
		return;
	}
	
	NSString *applicationSupportPath = [[[NSFileManager defaultManager] applicationSupportDirectory:kUserDomain] stringByAppendingPathComponent:@"BibDesk"]; 
	NSString *bookmarksPath = [applicationSupportPath stringByAppendingPathComponent:@"Bookmarks.plist"];
	[data writeToFile:bookmarksPath atomically:YES];
}

#pragma mark Menu validation

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem{
	if ([menuItem action] == @selector(saveFileAsLocalUrl:)) {
		return ![[[webView mainFrame] dataSource] isLoading];
	} else if ([menuItem action] == @selector(importFromPasteboardAction:)) {
		[menuItem setTitle:NSLocalizedString(@"Load Pasteboard",@"Load Pasteboard")];
		return YES;
	} else if ([menuItem action] == @selector(importFromFileAction:)) {
		[menuItem setTitle:[NSString stringWithFormat:@"%@%C", NSLocalizedString(@"Load File",@"Load File"),0x2026]];
		return YES;
	} else if ([menuItem action] == @selector(importFromWebAction:)) {
		[menuItem setTitle:[NSString stringWithFormat:@"%@%C", NSLocalizedString(@"Load Website",@"Load Website"),0x2026]];
		return YES;
	} else if ([menuItem action] == @selector(editSelectedFieldAsRawBibTeX:)) {
		int row = [itemTableView selectedRow];
		return (row != -1 && ![macroTextFieldWC isEditing] && ![[fields objectAtIndex:row] isEqualToString:BDSKCrossrefString]);
	}
	return YES;
}

#pragma mark WebUIDelegate methods

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems{
	NSMutableArray *menuItems = [NSMutableArray arrayWithCapacity:6];
	NSMenuItem *menuItem;
	
	NSEnumerator *iEnum = [defaultMenuItems objectEnumerator];
	while (menuItem = [iEnum nextObject]) { 
		if ([menuItem tag] == WebMenuItemTagCopy) {
			// copy text items
			if ([menuItems count] > 0)
				[menuItems addObject:[NSMenuItem separatorItem]];
			
			[menuItems addObject:menuItem];
		}
		if ([menuItem tag] == WebMenuItemTagCopyLinkToClipboard) {
			NSURL *linkURL = [element objectForKey:WebElementLinkURLKey];
			// copy link items
			if ([menuItems count] > 0)
				[menuItems addObject:[NSMenuItem separatorItem]];
			
			[menuItems addObject:menuItem];
			
			menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Copy Link To Url Field",@"Copy link to url field")
											  action:@selector(copyLinkedLocationAsRemoteUrl:)
									   keyEquivalent:@""];
			[menuItem setTarget:self];
			[menuItem setRepresentedObject:linkURL];
			[menuItems addObject:[menuItem autorelease]];
			
			menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[NSString stringWithFormat:@"%@%C",NSLocalizedString(@"Save Link As Local File",@"Save link as local file"),0x2026]
											  action:@selector(downloadLinkedFileAsLocalUrl:)
									   keyEquivalent:@""];
			[menuItem setTarget:self];
			[menuItem setRepresentedObject:linkURL];
			[menuItems addObject:[menuItem autorelease]];
			
			menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[NSString stringWithFormat:@"%@%C",NSLocalizedString(@"Bookmark Link",@"Bookmark linked page"),0x2026]
											  action:@selector(bookmarkLink:)
									   keyEquivalent:@""];
			[menuItem setTarget:self];
			[menuItem setRepresentedObject:element];
			[menuItems addObject:[menuItem autorelease]];
		}
	}
	
	// current location items
	if ([menuItems count] > 0) 
		[menuItems addObject:[NSMenuItem separatorItem]];
		
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Copy Page Location To Url Field",@"Copy page location to url field")
									  action:@selector(copyLocationAsRemoteUrl:)
							   keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItems addObject:[menuItem autorelease]];
	
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[NSString stringWithFormat:@"%@%C",NSLocalizedString(@"Save Page As Local File",@"Save page as local file"),0x2026]
									  action:@selector(saveFileAsLocalUrl:)
							   keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItems addObject:[menuItem autorelease]];
	
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[NSString stringWithFormat:@"%@%C",NSLocalizedString(@"Bookmark This Page",@"Bookmark this page"),0x2026]
									  action:@selector(bookmarkPage:)
							   keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItems addObject:[menuItem autorelease]];
	
	// navigation items
	[menuItems addObject:[NSMenuItem separatorItem]];
	
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Back",@"Back")
									  action:@selector(goBack:)
							   keyEquivalent:@"["];
	[menuItems addObject:[menuItem autorelease]];
	
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Forward",@"Forward")
									  action:@selector(goForward:)
							   keyEquivalent:@"]"];
	[menuItems addObject:[menuItem autorelease]];
	
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Reload",@"Reload")
									  action:@selector(reload:)
							   keyEquivalent:@"r"];
	[menuItems addObject:[menuItem autorelease]];
	
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Stop",@"Stop")
									  action:@selector(stopLoading:)
							   keyEquivalent:@""];
	[menuItems addObject:[menuItem autorelease]];
	
	// text size items
	[menuItems addObject:[NSMenuItem separatorItem]];
	
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Increase Text Size",@"Increase Text Size")
									  action:@selector(makeTextLarger:)
							   keyEquivalent:@""];
	[menuItems addObject:[menuItem autorelease]];
	
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Decrease Text Size",@"Increase Text Size")
									  action:@selector(makeTextSmaller:)
							   keyEquivalent:@""];
	[menuItems addObject:[menuItem autorelease]];
	
	return menuItems;
}

#pragma mark WebEditingDelegate methods

// workaround for webview bug, which looses its selection when the focus changes to another view
- (void)webViewDidChangeSelection:(NSNotification *)notification{
	NSView *docView = [[[[notification object] mainFrame] frameView] documentView];
	if (![docView conformsToProtocol:@protocol(WebDocumentText)]) return;
	NSString *selString = [docView selectedString];
	if ([NSString isEmptyString:selString] || selString == webSelection)
		return;
	[webSelection release];
	webSelection = [selString copy];
}

#pragma mark WebFrameLoadDelegate methods

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame{
	[self setLoading:YES];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame{
	[self setLoading:NO];
	[backButton setEnabled:[sender canGoBack]];
	[forwardButton setEnabled:[sender canGoForward]];
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame{
	[self setLoading:NO];
	
	if ([error code] == NSURLErrorCancelled) {// don't warn when the user cancels
		return;
	}
	
    NSString *errorDescription = [error localizedDescription];
    if (!errorDescription) {
        errorDescription = NSLocalizedString(@"An error occured during page load.",@"An error occured during page load.");
    }
    
    NSBeginAlertSheet(NSLocalizedString(@"Page Load Failed",@"Page Load Failed"), 
					  nil, nil, nil, 
					  [self window], 
					  nil, nil, nil, nil, 
					  errorDescription);
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame{
	[self setLoading:NO];
	
	if ([error code] == NSURLErrorCancelled) {// don't warn when the user cancels
		return;
	}
	
    NSString *errorDescription = [error localizedDescription];
    if (!errorDescription) {
        errorDescription = NSLocalizedString(@"An error occured during page load.",@"An error occured during page load.");
    }
    
    NSBeginAlertSheet(NSLocalizedString(@"Page Load Failed",@"Page Load Failed"), 
					  nil, nil, nil, 
					  [self window], 
					  nil, nil, nil, nil, 
					  errorDescription);
}

#pragma mark NSURLDownloadDelegate methods

- (void)downloadDidBegin:(NSURLDownload *)download{
    [self setDownloading:YES];
}

- (NSWindow *)downloadWindowForAuthenticationSheet:(WebDownload *)download{
    return [self window];
}

- (void)download:(NSURLDownload *)theDownload didReceiveResponse:(NSURLResponse *)response{
    expectedContentLength = [response expectedContentLength];

    if (expectedContentLength > 0) {
    }
}

- (void)download:(NSURLDownload *)theDownload decideDestinationWithSuggestedFilename:(NSString *)filename{
	[[NSSavePanel savePanel] beginSheetForDirectory:nil
											   file:filename
									 modalForWindow:[self window]
									  modalDelegate:self
									 didEndSelector:@selector(saveDownloadPanelDidEnd:returnCode:contextInfo:)
										contextInfo:nil];
}

- (void)download:(NSURLDownload *)theDownload didReceiveDataOfLength:(unsigned)length{
    if (expectedContentLength > 0) {
        receivedContentLength += length;
        int percent = round(100.0 * (double)receivedContentLength / (double)expectedContentLength);
		NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Downloading file. Received %i%%%C",@"Downloading file..."),percent,0x2026];
		[progressIndicator setToolTip:message];
		[statusLine setStringValue:message];
    }
}

- (BOOL)download:(NSURLDownload *)download shouldDecodeSourceDataOfMIMEType:(NSString *)encodingType;{
    return YES;
}

- (void)download:(NSURLDownload *)download didCreateDestination:(NSString *)path{
    [downloadFileName release];
	downloadFileName = [path copy];
}

- (void)downloadDidFinish:(NSURLDownload *)theDownload{
    [self setDownloading:NO];
	
	[self setLocalUrlFromDownload];
}

- (void)download:(NSURLDownload *)theDownload didFailWithError:(NSError *)error
{
    [self setDownloading:NO];
        
    NSString *errorDescription = [error localizedDescription];
    if (!errorDescription) {
        errorDescription = NSLocalizedString(@"An error occured during download.",@"An error occured during download.");
    }
    
    NSBeginAlertSheet(NSLocalizedString(@"Download Failed",@"Download Failed"), 
					  nil, nil, nil, 
					  [self window], 
					  nil, nil, nil, nil, 
					  errorDescription);
}

#pragma mark Editing

- (BOOL)addCurrentSelectionToFieldAtIndex:(int)index{
    if ([fields count] <= index)
        return NO;
    
    NSString *selKey = [fields objectAtIndex:index];
    NSString *selString = nil;

    if(showingWebView){
		selString = webSelection;
        //NSLog(@"selstr %@", selString);
    }else{
        NSRange selRange = [sourceTextView selectedRange];
        NSLayoutManager *layoutManager = [sourceTextView layoutManager];
        NSColor *foregroundColor = [NSColor lightGrayColor]; 
        NSDictionary *highlightAttrs = [NSDictionary dictionaryWithObjectsAndKeys: foregroundColor, NSForegroundColorAttributeName, nil];

        selString = [[sourceTextView string] substringWithRange:selRange];
        [layoutManager addTemporaryAttributes:highlightAttrs
                            forCharacterRange:selRange];
    }
	if ([NSString isEmptyString:selString] == YES)
		return NO;
	
    [item setField:selKey toValue:selString];
    
	[[item undoManager] setActionName:NSLocalizedString(@"Edit Publication",@"")];
    [itemTableView reloadData];
    return YES;
}

- (NSRange)control:(NSControl *)control textView:(NSTextView *)textView rangeForUserCompletion:(NSRange)charRange {
    if (control != itemTableView) {
		return charRange;
	} else if ([macroTextFieldWC isEditing]) {
		return [[NSApp delegate] rangeForUserCompletion:charRange 
								  forBibTeXStringString:[textView string]];
	} else {
		return [[NSApp delegate] entry:[fields objectAtIndex:[itemTableView selectedRow]] 
				rangeForUserCompletion:charRange 
							  ofString:[textView string]];

	}
	return charRange;
}

- (NSArray *)control:(NSControl *)control textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index{
    if (control != itemTableView) {
		return words;
	} else if ([macroTextFieldWC isEditing]) {
		return [[NSApp delegate] possibleMatches:[document macroDefinitions] 
						   forBibTeXStringString:[textView string] 
								partialWordRange:charRange 
								indexOfBestMatch:index];
	} else {
		return [[NSApp delegate] entry:[fields objectAtIndex:[itemTableView selectedRow]] 
						   completions:words 
				   forPartialWordRange:charRange 
							  ofString:[textView string] 
				   indexOfSelectedItem:index];
	}
}

- (BOOL)control:(NSControl *)control textViewShouldAutoComplete:(NSTextView *)textview {
    if (control == itemTableView)
		return [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKEditorFormShouldAutoCompleteKey];
	return NO;
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject {
	if (anObject != itemTableView)
		return nil;
	if (tableFieldEditor == nil) {
		tableFieldEditor = [[BDSKFieldEditor alloc] init];
	}
	return tableFieldEditor;
}

#pragma mark Macro editing

- (BOOL)editSelectedCellAsMacro{
	int row = [itemTableView selectedRow];
	if ([macroTextFieldWC isEditing] || row == -1 || [[fields objectAtIndex:row] isEqualToString:BDSKCrossrefString]) 
		return NO;
	NSString *value = [item valueOfField:[fields objectAtIndex:row]];
	NSText *fieldEditor = [itemTableView currentEditor];
	[tableCellFormatter setEditAsComplexString:YES];
	if (fieldEditor) {
		[fieldEditor setString:[tableCellFormatter editingStringForObjectValue:value]];
		[[[itemTableView tableColumnWithIdentifier:@"value"] dataCellForRow:row] setObjectValue:value];
		[fieldEditor selectAll:self];
	}
	return [macroTextFieldWC attachToView:itemTableView atRow:row column:2 withValue:value];
}

#pragma mark BDSKMacroFormatter delegate

- (BOOL)formatter:(BDSKFormCellFormatter *)formatter shouldEditAsComplexString:(NSString *)object {
	return [self editSelectedCellAsMacro];
}

#pragma mark NSControl text delegate

- (void)controlTextDidEndEditing:(NSNotification *)aNotification {
	if ([aNotification object] == itemTableView)
		[tableCellFormatter setEditAsComplexString:NO];
}

#pragma mark TableView Data source

- (int)numberOfRowsInTableView:(NSTableView *)tableView{
    return [fields count]; 
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    NSString *key = [fields objectAtIndex:row];
    NSString *tcID = [tableColumn identifier];
    
    if([tcID isEqualToString:@"FieldName"]){
        return key;
    }else if([tcID isEqualToString:@"Num"]){
        if(row < 10)
            return [NSString stringWithFormat:@"%C%d", 0x2318, row];
        else if(row < 20)
            return [NSString stringWithFormat:@"%C%C%d", 0x2325, 0x2318, row - 10];
        else if(row < 30)
            return [NSString stringWithFormat:@"%C%C%d", 0x21E7, 0x2318, row - 20];
        else return @"";
    }else{
        return [[item pubFields] objectForKey:key];
    }
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	NSString *tcID = [tableColumn identifier];
    if([tcID isEqualToString:@"FieldName"] ||
       [tcID isEqualToString:@"Num"] ){
        return; // don't edit the first 2 columns. Shouldn't happen anyway.
    }
    
    NSString *key = [fields objectAtIndex:row];
	if ([object isEqualAsComplexString:[item valueOfField:key]])
		return;
	
	[item setField:key toValue:object];
	[[item undoManager] setActionName:NSLocalizedString(@"Edit Publication",@"")];
}

// This method is used by NSTableView to determine a valid drop target.  Based on the mouse position, the table view will suggest a proposed drop location.  This method must return a value that indicates which dragging operation the data source will perform.  The data source may "re-target" a drop if desired by calling setDropRow:dropOperation: and returning something other than NSDragOperationNone.  One may choose to re-target for various reasons (eg. for better visual feedback when inserting into a sorted position).
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op{
    if(op ==  NSTableViewDropOn)
        return NSDragOperationCopy;
    else return NSDragOperationNone;
}

// This method is called when the mouse is released over a table view that previously decided to allow a drop via the validateDrop method.  The data source should incorporate the data from the dragging pasteboard at this time.
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op{
    NSPasteboard *pb = [info draggingPasteboard];
    NSString *pbType = [pb availableTypeFromArray:[NSArray arrayWithObjects:NSStringPboardType, nil]];
    if ([NSStringPboardType isEqualToString:pbType]){

        NSString *key = [fields objectAtIndex:row];
        [item setField:key toValue:[pb stringForType:NSStringPboardType]];
		
		[[item undoManager] setActionName:NSLocalizedString(@"Edit Publication",@"")];
        [itemTableView reloadData];
    }
    return YES;
}

// this is used by the paste: action defined in NSTableView-OAExtensions
- (void)tableView:(NSTableView *)tv addItemsFromPasteboard:(NSPasteboard *)pboard{
	int index = [tv selectedRow];
	NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]];
	
	if (type == nil || index == -1)
		return;
	
    NSString *selKey = [fields objectAtIndex:index];
	NSString *string = [pboard stringForType:NSStringPboardType];
	
	[item setField:selKey toValue:string];
    
	[[item undoManager] setActionName:NSLocalizedString(@"Edit Publication",@"")];
    [itemTableView reloadData];
}

#pragma mark TableView delegate methods

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    if([[tableColumn identifier] isEqualToString:@"FieldValue"])
        return YES;
	return NO;
}

- (void)tableView:(NSTableView *)tv willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	if([[tableColumn identifier] isEqualToString:@"FieldValue"]){
		NSString *field = [fields objectAtIndex:row];
		NSFormatter *formatter;
		if ([field isEqualToString:BDSKCrossrefString]) {
			formatter = crossrefFormatter;
		} else {
			formatter = tableCellFormatter;
			[(BDSKFormCellFormatter *)formatter setHighlighted:[tv isRowSelected:row]];
		}
		[cell setFormatter:formatter];
	}
}

#pragma mark || Methods to support the type-ahead selector.

- (void)updateTypeAheadStatus:(NSString *)searchString{
    if(!searchString)
        [statusLine setStringValue:[self isInTemporaryTypeAheadMode] ? @"Press Enter to set or Tab to cancel." : @""]; // resets the status line to its default value
    else
        [statusLine setStringValue:[NSString stringWithFormat:@"%@ \"%@\"", NSLocalizedString(@"Finding field:", @""), [searchString capitalizedString]]];
}

- (NSArray *)typeAheadSelectionItems{
    return fields;
}
    // This is where we build the list of possible items which the user can select by typing the first few letters. You should return an array of NSStrings.

- (NSString *)currentlySelectedItem{
    int row = [itemTableView selectedRow];
    if (row == -1)
        return nil;
    return [fields objectAtIndex:row];
}
// Type-ahead-selection behavior can change if an item is currently selected (especially if the item was selected by type-ahead-selection). Return nil if you have no selection or a multiple selection.

// fixme -  also need to call the processkeychars in keydown...
- (void)typeAheadSelectItemAtIndex:(int)itemIndex{
    OBPRECONDITION([[self window] firstResponder] == itemTableView);
    [itemTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:itemIndex] byExtendingSelection:NO];
    [itemTableView scrollRowToVisible:itemIndex];
}
// We call this when a type-ahead-selection match has been made; you should select the item based on its index in the array you provided in -typeAheadSelectionItems.

- (void)startTemporaryTypeAheadMode{
    if (temporaryTypeAheadMode == YES)
        return;
    temporaryTypeAheadMode = YES;
    savedFirstResponder = [[self window] firstResponder];
    if ([savedFirstResponder isKindOfClass:[NSTextView class]] && [(NSTextView *)savedFirstResponder isFieldEditor]) {
        savedFirstResponder = [(NSTextView *)savedFirstResponder delegate];
    }
    [[self window] makeFirstResponder:itemTableView];
    [statusLine setStringValue:NSLocalizedString(@"Start typing to select a field. Press Enter to set or Tab to cancel.", @"")];
}

- (void)endTemporaryTypeAheadModeAndSet:(BOOL)flag{
    if (temporaryTypeAheadMode == NO)
        return;
    temporaryTypeAheadMode = NO;
    [[self window] makeFirstResponder:savedFirstResponder];
    savedFirstResponder = nil;
    [statusLine setStringValue:@""];
    if (flag)
        [self addTextToCurrentFieldAction:itemTableView];
    [statusLine setStringValue:@""];
}

- (BOOL)isInTemporaryTypeAheadMode{
    return temporaryTypeAheadMode;
}

#pragma mark Splitview delegate methods

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset{
	return proposedMin + 126; // from IB
}

- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset{
	return proposedMax - 200.0;
}

@end


@implementation TextImportItemTableView

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent{
    
    unichar c = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    unsigned int flags = [theEvent modifierFlags];
    
    if (flags & NSCommandKeyMask) {
        // these are returned for digits and the shift modifier, at least with the standard keyboard
        NSRange range = [@")!@#$%^&*(" rangeOfCharacterFromSet:[NSCharacterSet characterSetWithRange:NSMakeRange(c,1)]];
        if (range.location != NSNotFound) {
            unsigned index = (unsigned)(range.location + 20);
            if (flags & NSAlternateKeyMask)
                index += 10;
            if ([[self dataSource] addCurrentSelectionToFieldAtIndex:index] == NO) {
                NSBeep();
                return NO;
            } else return YES;
        
        } else if (c >= '0' && c <= '9') {
        
            unsigned index = (unsigned)(c - '0');
            if (flags & NSAlternateKeyMask)
                index += 10;
            if (flags & NSShiftKeyMask)
                index += 20;
            if ([[self dataSource] addCurrentSelectionToFieldAtIndex:index] == NO) {
                NSBeep();
                return NO;
            } else return YES;
        
        } else if ([[self dataSource] isInTemporaryTypeAheadMode] == NO && c == '=') {
        
            [[self dataSource] startTemporaryTypeAheadMode];
            return YES;
        }
    }
    
    return [super performKeyEquivalent:theEvent];
}

- (void)keyDown:(NSEvent *)event{
    NSString *chars = [event charactersIgnoringModifiers];
    unichar c = ([chars length]) ? [chars characterAtIndex:0] : 0;
    unsigned int flags = ([event modifierFlags] & 0xffff0000U);
    
    static NSCharacterSet *fieldNameCharSet = nil;
    if (fieldNameCharSet == nil) 
        fieldNameCharSet = [[[[BibTypeManager sharedManager] strictInvalidCharactersForField:BDSKCiteKeyString inFileType:BDSKBibtexString] invertedSet] copy];
    
    if ([[self dataSource] isInTemporaryTypeAheadMode]) {
        if (flags != 0) {
            NSBeep();
            return;
        } else if (c == NSTabCharacter || c == 0x001b) {
            [[self dataSource] endTemporaryTypeAheadModeAndSet:NO];
            return;
        } else if (c == NSCarriageReturnCharacter || c == NSEnterCharacter || c == NSNewlineCharacter) {
            [[self dataSource] endTemporaryTypeAheadModeAndSet:YES];
            return;
        } else if ([fieldNameCharSet characterIsMember:c] == NO && c != NSDownArrowFunctionKey && c != NSUpArrowFunctionKey) {
            NSBeep();
            return;
        }
    }
    
    if ([fieldNameCharSet characterIsMember:c] && flags == 0) {
        [typeAheadHelper prefixProcessKeyDownCharacter:c];
    }else{
        [super keyDown:event];
    }
}

- (BOOL)resignFirstResponder {
    [[self dataSource] endTemporaryTypeAheadModeAndSet:NO];
    return [super resignFirstResponder];
}

- (void)awakeFromNib{
    typeAheadHelper = [[OATypeAheadSelectionHelper alloc] init];
    [typeAheadHelper setDataSource:[self dataSource]];
    [typeAheadHelper setCyclesSimilarResults:YES];
}

- (void)dealloc{
    [typeAheadHelper setDataSource:nil];
    [typeAheadHelper release];
    [super dealloc];
}

- (void)reloadData{
    [super reloadData];
    [typeAheadHelper queueSelectorOnce:@selector(rebuildTypeAheadSearchCache)];
}

@end
