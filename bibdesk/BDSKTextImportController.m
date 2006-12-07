//
//  BDSKTextImportController.m
//  BibDesk
//
//  Created by Michael McCracken on 4/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKTextImportController.h"
#import <Carbon/Carbon.h>

@implementation BDSKTextImportController

- (id)initWithDocument:(BibDocument *)doc{
    self = [super initWithWindowNibName:@"TextImport"];
    if(self){
        document = doc;
        item = [[BibItem alloc] init];
        fields = [[NSMutableArray alloc] init];
		bookmarks = [[NSMutableArray alloc] init];
        showingWebView = NO;
        itemsAdded = 0;
		
		NSString *applicationSupportPath = [[[NSFileManager defaultManager] applicationSupportDirectory:kUserDomain] stringByAppendingPathComponent:@"BibDesk"]; 
		NSString *bookmarksPath = [applicationSupportPath stringByAppendingPathComponent:@"Bookmarks.plist"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:bookmarksPath]) {
			NSEnumerator *bEnum = [[[NSMutableArray alloc] initWithContentsOfFile:bookmarksPath] objectEnumerator];
			NSDictionary *bm;
			
			while(bm = [bEnum nextObject]){
				[bookmarks addObject:[[bm mutableCopy] autorelease]];
			}
		}
    }
    return self;
}

- (void)dealloc{
    [item release];
    [fields release];
    [bookmarks release];
    [sourceBox release];
    [webViewView release];
    [super dealloc];
}

- (void)awakeFromNib{
	[itemTableView registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
    [statusLine setStringValue:@""];
    [citeKeyLine setStringValue:[item citeKey]];
	[webViewBox setContentViewMargins:NSZeroSize];
	[webViewBox setContentView:webView];
    [self setupTypeUI];
    [sourceBox retain];
    [webViewView retain];
    [itemTableView setDoubleAction:@selector(addTextToCurrentFieldAction:)];
    [self setWindowFrameAutosaveName:@"BDSKTextImportController Frame Autosave Name"];
}


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
        NSData *pbData = [pb dataForType:pbType];
        
		if([pbType isEqualToString:NSRTFPboardType]){
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
            pbString = [pb stringForType:pbType];
            pbString = [pbString stringByRemovingSurroundingWhitespace];
			if([pbString rangeOfString:@"http://"].location == 0){
                [self showWebViewWithURLString:pbString];
            }else{
                [sourceTextView setString:pbString];
            }
		}else {
			
			[sourceTextView setString:@""];
		}
	}
}

- (void)showWebViewWithURLString:(NSString *)urlString{
    [self setShowingWebView:YES];
    NSURL *url = [NSURL URLWithString:[urlString stringByRemovingSurroundingWhitespace]];
    NSURLRequest *urlreq = [NSURLRequest requestWithURL:url];
    
    [[webView mainFrame] loadRequest:urlreq];
        
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

- (void)setType:(NSString *)type{
    
    [itemTypeButton selectItemWithTitle:type];
    [item makeType:type];

    BibTypeManager *typeMan = [BibTypeManager sharedManager];

    [fields removeAllObjects];
    
    [fields addObjectsFromArray:[typeMan requiredFieldsForType:type]];
    [fields addObjectsFromArray:[typeMan optionalFieldsForType:type]];
    [fields addObjectsFromArray:[typeMan userDefaultFieldsForType:type]];
	if (![fields containsObject:BDSKLocalUrlString]) 
		[fields addObject:BDSKLocalUrlString];
	if (![fields containsObject:BDSKUrlString]) 
		[fields addObject:BDSKUrlString];
	
}

// this should be called by the caller when the sheet is removed
- (void)cleanup{
    [self cancelDownload];
	[webView stopLoading:nil];
}
		
- (void)beginSheetForPasteboardModalForWindow:(NSWindow *)docWindow modalDelegate:(id)modalDelegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo{
	// we start with the pasteboard data, so we can directly show the main sheet 
	if (![NSBundle loadNibNamed:[self windowNibName] owner:self]) return; // make sure we loaded the nib
	[self loadPasteboardData];
	
	[NSApp beginSheet:[self window]
	   modalForWindow:docWindow
		modalDelegate:modalDelegate
	   didEndSelector:didEndSelector
		  contextInfo:contextInfo];
}

- (void)beginSheetForWebModalForWindow:(NSWindow *)docWindow modalDelegate:(id)modalDelegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo{
	// we start with a webview, so we first ask for the URL to load
	if (![NSBundle loadNibNamed:[self windowNibName] owner:self]) return; // make sure we loaded the nib
	[self setShowingWebView:YES];
	
	// load the popup buttons with our bookmarks
	NSEnumerator *bEnum = [bookmarks objectEnumerator];
	NSDictionary *bm;
	
	[bookmarkPopUpButton removeAllItems];
	[bookmarkPopUpButton addItemWithTitle:NSLocalizedString(@"Bookmarks",@"Bookmarks")];
	while (bm = [bEnum nextObject]) {
		[bookmarkPopUpButton addItemWithTitle:[bm objectForKey:@"Title"]];
	}
	
	// remember the arguments to pass for the main sheet later
	theDocWindow = [docWindow retain];
	theModalDelegate = [modalDelegate retain];
	theDidEndSelector = didEndSelector;
	theContextInfo = contextInfo; // this one should be retained by the caller if it is non-nil
	
	// now show the URL sheet
	[NSApp beginSheet:urlSheet
	   modalForWindow:docWindow
		modalDelegate:self
	   didEndSelector:@selector(urlSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:[[NSNumber alloc] initWithBool:YES]];
}
		
- (void)beginSheetForFileModalForWindow:(NSWindow *)docWindow modalDelegate:(id)modalDelegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo{
	// we start with a file, so we first ask for the file to load
	if (![NSBundle loadNibNamed:[self windowNibName] owner:self]) return; // make sure we loaded the nib
	
	// remember the arguments to pass for the main sheet later
	theDocWindow = [docWindow retain];
	theModalDelegate = [modalDelegate retain];
	theDidEndSelector = didEndSelector;
	theContextInfo = contextInfo; // this one should be retained by the caller if it is non-nil
	
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
- (IBAction)addCurrentItemAction:(id)sender{
    // make the tableview stop editing:
    [[self window] makeFirstResponder:[self window]];
    
    [document addPublication:[item autorelease]];

    [statusLine setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%d publication%@ added.", @"format string for pubs added. args: one int for number added then one string for plural string."), ++itemsAdded, (itemsAdded > 1 ? @"s" : @"")]];

    item = [[BibItem alloc] init];
    [itemTypeButton selectItemWithTitle:[item type]];
    [citeKeyLine setStringValue:[item citeKey]];
    [itemTableView reloadData];
}

- (IBAction)stopAddingAction:(id)sender{
    [[self window] orderOut:sender];
    [NSApp endSheet:[self window] returnCode:[sender tag]];
}

- (IBAction)addTextToCurrentFieldAction:(id)sender{
    
    [self addCurrentSelectionToFieldAtIndex:[sender selectedRow]];
}


- (void)addCurrentSelectionToFieldAtIndex:(int)index{    
    NSString *selKey = [fields objectAtIndex:index];
    NSString *selString = nil;

    if(showingWebView){
		NSView *docView = [[[webView mainFrame] frameView] documentView];
		if (![docView conformsToProtocol:@protocol(WebDocumentText)]) return;
		selString = [docView selectedString];
        NSLog(@"selstr %@", selString);
    }else{
        NSRange selRange = [sourceTextView selectedRange];
        NSLayoutManager *layoutManager = [sourceTextView layoutManager];
        NSColor *foregroundColor = [NSColor lightGrayColor]; 
        NSDictionary *highlightAttrs = [NSDictionary dictionaryWithObjectsAndKeys: foregroundColor, NSForegroundColorAttributeName, nil];

        selString = [[sourceTextView string] substringWithRange:selRange];
        [layoutManager addTemporaryAttributes:highlightAttrs
                            forCharacterRange:selRange];
    }
    [item setField:selKey toValue:selString];
    
    [item setCiteKey:[item suggestedCiteKey]];
    [citeKeyLine setStringValue:[item citeKey]];
    
    [itemTableView reloadData];
}

- (IBAction)changeTypeOfBibAction:(id)sender{
    NSString *type = [[sender selectedItem] title];
    [self setType:type];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:type
                                                      forKey:BDSKPubTypeStringKey];
    [item setCiteKey:[item suggestedCiteKey]];
    [citeKeyLine setStringValue:[item citeKey]];

    [itemTableView reloadData];
}

- (IBAction)importFromPasteboardAction:(id)sender{
	[self loadPasteboardData];
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

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
	// this variable is true when we called the open sheet initially before showing the main window 
	BOOL initialFileLoad = [[(NSNumber *)contextInfo autorelease] boolValue];
	
	if (initialFileLoad) {
		// this is the initial web load, the main window is not yet there
		
		// we need to release these, as we had retained them
		[theDocWindow autorelease];
		[theModalDelegate autorelease];
		
		if (returnCode == NSOKButton) {
			// show the main window and pass it the information initially given by the modalDelegate
			
			[NSApp beginSheet:[self window]
			   modalForWindow:theDocWindow
				modalDelegate:theModalDelegate
			   didEndSelector:theDidEndSelector
				  contextInfo:theContextInfo];
			
		} else {
			// the user cancelled. As we don't end the main sheet we have to call the didEndSelector ourselves
			
			NSMethodSignature *signature = [theModalDelegate methodSignatureForSelector:theDidEndSelector];
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
			[invocation setSelector:theDidEndSelector];
			[invocation setArgument:&sheet atIndex:2];
			[invocation setArgument:&returnCode atIndex:3];
			[invocation setArgument:&theContextInfo atIndex:4];
			[invocation invokeWithTarget:theModalDelegate];
			
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
          contextInfo:nil];
}

- (IBAction)dismissUrlSheet:(id)sender{
    [urlSheet orderOut:sender];
    [NSApp endSheet:urlSheet returnCode:[sender tag]];
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
			// show the main window and pass it the information initially given by the modalDelegate
			
			[NSApp beginSheet:[self window]
			   modalForWindow:theDocWindow
				modalDelegate:theModalDelegate
			   didEndSelector:theDidEndSelector
				  contextInfo:theContextInfo];
			
		} else {
			// the user cancelled. As we don't end the main sheet we have to call the didEndSelector ourselves
			
			NSMethodSignature *signature = [theModalDelegate methodSignatureForSelector:theDidEndSelector];
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
			[invocation setSelector:theDidEndSelector];
			[invocation setArgument:&sheet atIndex:2];
			[invocation setArgument:&returnCode atIndex:3];
			[invocation setArgument:&theContextInfo atIndex:4];
			[invocation invokeWithTarget:theModalDelegate];
			
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

- (IBAction)chooseBookmarkAction:(id)sender{
	int index = [bookmarkPopUpButton indexOfSelectedItem];
	NSString *URLString = [[bookmarks objectAtIndex:index-1] objectForKey:@"URLString"];
	[urlTextField setStringValue:URLString];
    
	[urlSheet orderOut:sender];
    [NSApp endSheet:urlSheet returnCode:1];
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

- (IBAction)showHelpAction:(id)sender{
    
    OSErr err = AHLookupAnchor((CFStringRef)@"BibDesk Help", (CFStringRef)@"Adding-from-Text");
    if (err == kAHInternalErr || err == kAHInternalErr){
        NSLog(@"Help Book: error looking up anchor \"Adding-from-Text\"");
    }
}

#pragma mark WebView contextual menu actions

- (void)copyLocationAsRemoteUrl:(id)sender{
	NSString *URLString = [[[[[webView mainFrame] dataSource] request] URL] absoluteString];
	
	if (URLString) {
		[item setField:BDSKUrlString toValue:URLString];
		[itemTableView reloadData];
	}
}

- (void)copyLinkedLocationAsRemoteUrl:(id)sender{
	NSString *URLString = [(NSURL *)[sender representedObject] absoluteString];
	
	if (URLString) {
		[item setField:BDSKUrlString toValue:URLString];
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

- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    
	if (returnCode == NSOKButton) {
		if ([[[[webView mainFrame] dataSource] data] writeToFile:[sheet filename] atomically:YES]) {
			NSString *fileURLString = [[NSURL fileURLWithPath:[sheet filename]] absoluteString];
			
			[item setField:BDSKLocalUrlString toValue:fileURLString];
			[item autoFilePaper];
		} else {
			NSLog(@"Could not write downloaded file.");
		}
    }

    [itemTableView reloadData];
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

#pragma mark Page loading methods


- (void)cancelLoad{
	[webView stopLoading:self];
	[self setLoading:NO];
}

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

- (IBAction)dismissAddBookmarkSheet:(id)sender{
    [addBookmarkSheet orderOut:sender];
    [NSApp endSheet:addBookmarkSheet returnCode:[sender tag]];
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
			
			menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy Link To Url Field",@"Copy link to url field")
											  action:@selector(copyLinkedLocationAsRemoteUrl:)
									   keyEquivalent:@""];
			[menuItem setTarget:self];
			[menuItem setRepresentedObject:linkURL];
			[menuItems addObject:[menuItem autorelease]];
			
			menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@%C",NSLocalizedString(@"Save Link As Local File",@"Save link as local file"),0x2026]
											  action:@selector(downloadLinkedFileAsLocalUrl:)
									   keyEquivalent:@""];
			[menuItem setTarget:self];
			[menuItem setRepresentedObject:linkURL];
			[menuItems addObject:[menuItem autorelease]];
			
			menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@%C",NSLocalizedString(@"Bookmark Link",@"Bookmark linked page"),0x2026]
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
		
	menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy Page Location To Url Field",@"Copy page location to url field")
									  action:@selector(copyLocationAsRemoteUrl:)
							   keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItems addObject:[menuItem autorelease]];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@%C",NSLocalizedString(@"Save Page As Local File",@"Save page as local file"),0x2026]
									  action:@selector(saveFileAsLocalUrl:)
							   keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItems addObject:[menuItem autorelease]];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@%C",NSLocalizedString(@"Bookmark This Page",@"Bookmark this page"),0x2026]
									  action:@selector(bookmarkPage:)
							   keyEquivalent:@""];
	[menuItem setTarget:self];
	[menuItems addObject:[menuItem autorelease]];
	
	// navigation items
	[menuItems addObject:[NSMenuItem separatorItem]];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Back",@"Back")
									  action:@selector(goBack:)
							   keyEquivalent:@"["];
	[menuItems addObject:[menuItem autorelease]];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Forward",@"Forward")
									  action:@selector(goForward:)
							   keyEquivalent:@"]"];
	[menuItems addObject:[menuItem autorelease]];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reload",@"Reload")
									  action:@selector(reload:)
							   keyEquivalent:@"r"];
	[menuItems addObject:[menuItem autorelease]];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Stop",@"Stop")
									  action:@selector(stopLoading:)
							   keyEquivalent:@""];
	[menuItems addObject:[menuItem autorelease]];
	
	// text size items
	[menuItems addObject:[NSMenuItem separatorItem]];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Increase Text Size",@"Increase Text Size")
									  action:@selector(makeTextLarger:)
							   keyEquivalent:@""];
	[menuItems addObject:[menuItem autorelease]];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Decrease Text Size",@"Increase Text Size")
									  action:@selector(makeTextSmaller:)
							   keyEquivalent:@""];
	[menuItems addObject:[menuItem autorelease]];
	
	return menuItems;
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
        else return @"";
    }else{
        return [[item pubFields] objectForKey:key];
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    NSString *tcID = [tableColumn identifier];
    if([tcID isEqualToString:@"FieldName"] ||
       [tcID isEqualToString:@"Num"] ){
        return NO;
    }
    return YES;
}


- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    NSString *tcID = [tableColumn identifier];
    if([tcID isEqualToString:@"FieldName"] ||
       [tcID isEqualToString:@"Num"] ){
        return; // don't edit the first column. Shouldn't happen anyway.
    }
    
    NSString *key = [fields objectAtIndex:row];
    [item setField:key toValue:object];
    [item setCiteKey:[item suggestedCiteKey]];
    [citeKeyLine setStringValue:[item citeKey]];
}

// This method is called after it has been determined that a drag should begin, but before the drag has been started.  To refuse the drag, return NO.  To start a drag, return YES and place the drag data onto the pasteboard (data, owner, etc...).  The drag image and other drag related information will be set up and provided by the table view once this call returns with YES.  The rows array is the list of row numbers that will be participating in the drag.
- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard{
    return NO;   
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
        [itemTableView reloadData];
    }
    return YES;
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
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    if (isLocal) return NSDragOperationEvery;
    else return NSDragOperationCopy;
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent{
    
    NSString *chars = [theEvent charactersIgnoringModifiers];
    unsigned int flags = [theEvent modifierFlags];
    
    if (flags | NSCommandKeyMask && 
        [chars containsCharacterInSet:[NSCharacterSet characterSetWithCharactersInString:@"01234567890"]]) {

        unsigned index = (unsigned)[chars characterAtIndex:0];
        [[self delegate] addCurrentSelectionToFieldAtIndex:index-48]; // 48 is the char value of 0.
        return YES;
    }
    
    return [super performKeyEquivalent:theEvent];
}

@end
