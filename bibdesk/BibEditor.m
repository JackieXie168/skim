//  BibEditor.m

//  Created by Michael McCracken on Mon Dec 24 2001.
//  Copyright (c) 2001 Michael McCracken. All rights reserved.
/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#import "BibEditor.h"
#import "BibDocument.h"
#import <OmniAppKit/NSScrollView-OAExtensions.h>
#import "BDAlias.h"

NSString *BDSKAnnoteString = @"Annote";
NSString *BDSKAbstractString = @"Abstract";
NSString *BDSKRssDescriptionString = @"Rss-Description";
NSString *BDSKLocalUrlString = @"Local-Url";
NSString *BDSKUrlString = @"Url";
NSString *BDSKDateCreatedString = @"Date-Added";
NSString *BDSKDateModifiedString = @"Date-Modified";


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
    currentType = [theBib type];    // do this once in init so it's right at the start.
                                    // has to be before we call [self window] because that calls windowDidLoad:.
	theDocument = doc; // don't retain - it retains us.
	
	[self setupCautionIcon];

    // this should probably be moved around.
    [[self window] setTitle:[theBib title]];
    [[self window] setDelegate:self];
    [[self window] registerForDraggedTypes:[NSArray arrayWithObjects:
            NSStringPboardType, NSFilenamesPboardType, nil]];					

#if DEBUG
    NSLog(@"BibEditor alloc");
#endif
    return self;
}

- (void)windowWillLoad{
    [theBib setEditorObj:self];
    [citeKeyField setStringValue:[theBib citeKey]];
    [self setupForm];
    [notesView setString:[theBib valueOfField:BDSKAnnoteString]];
    [abstractView setString:[theBib valueOfField:BDSKAbstractString]];
    [rssDescriptionView setString:[theBib valueOfField:BDSKRssDescriptionString]];
    // NSLog(@"BibEditor gets willLoad.");
}

- (void)windowDidLoad{
	[self setCiteKeyDuplicateWarning:![self citeKeyIsValid:[theBib citeKey]]];
    [self fixURLs];
}


- (BibItem *)currentBib{
    return theBib;
}

- (void)setupForm{
    BibAppController *appController = (BibAppController *)[NSApp delegate];
    NSString *tmp;
    NSFormCell *entry;
    NSArray *sKeys;
    NSFont *requiredFont = [NSFont labelFontOfSize:12.0];
    int i=0;
    int numRows;
    NSRect rect = [bibFields frame];
    NSPoint origin = rect.origin;
	NSEnumerator *e;

	NSArray *keysNotInForm = [NSArray arrayWithObjects: BDSKAnnoteString, BDSKAbstractString, BDSKRssDescriptionString, BDSKDateCreatedString, BDSKDateModifiedString, nil];

    NSDictionary *reqAtt = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSColor redColor],nil]
                                                       forKeys:[NSArray arrayWithObjects:NSForegroundColorAttributeName,nil]];

    
    [[NSFontManager sharedFontManager] convertFont:requiredFont
                                       toHaveTrait:NSBoldFontMask];
	
	// set up for adding all items 
    // remove all items in the NSForm (NSForm doesn't have a removeAllEntries.)
    numRows = [bibFields numberOfRows];
    for(i=0;i < numRows; i++){
        [bibFields removeEntryAtIndex:0]; // it shifts indices every time so we have to pop them.
    }

    // make two passes to get the required entries at top.
    i=0;
    sKeys = [[[theBib pubFields] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    NSMutableSet *addedFields = [NSMutableSet set];
    NSArray *requiredKeys = [theBib requiredFieldNames];
    e = [requiredKeys objectEnumerator];
    while(tmp = [e nextObject]){
        if (![keysNotInForm containsObject:tmp]){
            
            entry = [bibFields insertEntry:tmp atIndex:i];
            [entry setTarget:self];
            [entry setAction:@selector(textFieldDidEndEditing:)];
            [entry setTag:i];
            [entry setObjectValue:[theBib valueOfField:tmp]];
            [entry setTitleFont:requiredFont];
            [entry setAttributedTitle:[[[NSAttributedString alloc] initWithString:tmp
                                                                       attributes:reqAtt] autorelease]];
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
            entry = [bibFields insertEntry:tmp atIndex:i];
            [entry setTarget:self];
            [entry setAction:@selector(textFieldDidEndEditing:)];
            [entry setTag:i];
            [entry setObjectValue:[theBib valueOfField:tmp]];
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
            
            entry = [bibFields insertEntry:tmp atIndex:i];
            [entry setTarget:self];
            [entry setAction:@selector(textFieldDidEndEditing:)];
            [entry setTag:i];
            [entry setObjectValue:[theBib valueOfField:tmp]];
            [entry setTitleAlignment:NSLeftTextAlignment];
            // Autocompletion stuff
			[entry setFormatter:[appController formatterForEntry:tmp]];
            i++;
        }
    }
    [bibFields sizeToFit];
    
    [bibFields setFrameOrigin:origin];
    [bibFields setNeedsDisplay:YES];
}

- (void)awakeFromNib{
    NSEnumerator *typeNamesE = [[[BibTypeManager sharedManager] bibTypesForFileType:[theBib fileType]] objectEnumerator];
    NSString *typeName = nil;
    
    [citeKeyField setFormatter:citeKeyFormatter];
    [newFieldName setFormatter:fieldNameFormatter];

    [bibTypeButton removeAllItems];
    while(typeName = [typeNamesE nextObject]){
        [bibTypeButton addItemWithTitle:typeName];
    }

    [bibTypeButton selectItemWithTitle:currentType];
    [self setupForm]; // gets called in window will load...?
    
	// The popupbutton needs to be set before fixURLs is called, and -windowDidLoad gets sent after awakeFromNib.

	//	creating an RYZImagePopUpButton in IB results in one that has the wrong cell.
	// So we still create it there, we just replace it here with a proper one:
	RYZImagePopUpButton *newViewLocalButton = [[RYZImagePopUpButton alloc] initWithFrame:[viewLocalButton frame]];
	[[[self window] contentView] replaceSubview:viewLocalButton
                                               with:newViewLocalButton];
        [newViewLocalButton release]; // retained by the view

	// copy the 'springs' from the placeholder in IB:
	[newViewLocalButton setAutoresizingMask:[viewLocalButton autoresizingMask]];
	viewLocalButton = newViewLocalButton;

	[viewLocalButton setArrowImage:[NSImage imageNamed:@"ArrowPointingDown"]];
	[viewLocalButton setShowsMenuWhenIconClicked:NO];
	[[viewLocalButton cell] setAltersStateOfSelectedItem:NO];
	[[viewLocalButton cell] setAlwaysUsesFirstItemAsSelected:YES];
	[[viewLocalButton cell] setUsesItemFromMenu:NO];
	[[viewLocalButton cell] setRefreshesMenu:YES];
	[[viewLocalButton cell] setDelegate:self];
		
	[viewLocalButton setMenu:[self menuForImagePopUpButton]];
	
    [notesView setString:[theBib valueOfField:BDSKAnnoteString]];
    [abstractView setString:[theBib valueOfField:BDSKAbstractString]];
    [rssDescriptionView setString:[theBib valueOfField:BDSKRssDescriptionString]];
    
	[fieldsScrollView setDrawsBackground:NO];
	
	[citeKeyField setStringValue:[theBib citeKey]];
	
	[theBib setEditorObj:self];	
	
	// unfortunately we cannot set this in BI
	[actionMenuButton setAlternateImage:[NSImage imageNamed:@"Action_Pressed"]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(bibDidChange:)
												 name:BDSKBibItemChangedNotification
											   object:theBib];
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

	[authorTableView setDoubleAction:@selector(showPersonDetailCmd:)];
		
}

- (void)dealloc{
#if DEBUG
    NSLog(@"BibEditor dealloc");
#endif
    // release theBib? no...
    [citeKeyFormatter release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[cautionIconImage release]; 
    [fieldNumbers release];
    [_pdfSnoopImage release];
    [_textSnoopString release];
    [fieldNameFormatter release];
	[theBib setEditorObj:nil];
    [super dealloc];
}

- (void)show{
    [self showWindow:self];
}

// note that we don't want the - document accessor! It messes us up by getting called for other stuff.

- (void)finalizeChanges{
    if ([[self window] makeFirstResponder:[self window]]) {
    /* All fields are now valid; it's safe to use fieldEditor:forObject:
    to claim the field editor. */
    }else{
        /* Force first responder to resign. */
        [[self window] endEditingFor:nil];
    }
}

- (IBAction)saveDocument:(id)sender{
    // a safety call to be sure that the current field's changes are saved :...
    [self finalizeChanges];

    [theDocument saveDocument:sender];
}

- (IBAction)revealLocal:(id)sender{
    NSWorkspace *sw = [NSWorkspace sharedWorkspace];
	NSString *path = [theBib localURLPathRelativeTo:[[theDocument fileName] stringByDeletingLastPathComponent]];
	[sw selectFile:path inFileViewerRootedAtPath:nil];
}

- (IBAction)viewLocal:(id)sender{
    NSWorkspace *sw = [NSWorkspace sharedWorkspace];
    
    BOOL err = NO;

    NS_DURING

        if(![sw openFile:[theBib localURLPathRelativeTo:[[theDocument fileName] stringByDeletingLastPathComponent]]]){
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

- (NSMenu *)menuForImagePopUpButton{
	NSMenu *viewLocalMenu = [[NSMenu alloc] init];
	// the first one has to be view file, since it's also the button's action when you're clicking on the icon.
	[viewLocalMenu addItemWithTitle:NSLocalizedString(@"View File",@"View file string")
							 action:@selector(viewLocal:)
					  keyEquivalent:@""];
	
	[viewLocalMenu addItemWithTitle:NSLocalizedString(@"Reveal in Finder",@"Reveal in finder")
							 action:@selector(revealLocal:)
					  keyEquivalent:@""];
	
	[viewLocalMenu addItemWithTitle:NSLocalizedString(@"Choose File...",@"Choose file string")
							 action:@selector(chooseLocalURL:)
					  keyEquivalent:@""];
	
	// get Safari recent downloads
	NSArray *safariItems = [self getSafariRecentDownloadsMenu];
	int i = 0;
	for (i = 0; i < [safariItems count]; i ++){
		[viewLocalMenu addItem:[safariItems objectAtIndex:i]];
	}
	
	NSArray *previewItems = [self getPreviewRecentDocumentsMenu];
	for (i = 0; i < [previewItems count]; i ++){
		[viewLocalMenu addItem:[previewItems objectAtIndex:i]];
	}
	return [viewLocalMenu autorelease];
}


- (NSArray *)getSafariRecentDownloadsMenu{
	NSString *downloadPlistFileName = [NSHomeDirectory()  stringByAppendingPathComponent:@"Library"];
	downloadPlistFileName = [downloadPlistFileName stringByAppendingPathComponent:@"Safari"];
	downloadPlistFileName = [downloadPlistFileName stringByAppendingPathComponent:@"downloads.plist"];
	
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:downloadPlistFileName];

	NSArray *historyArray = [dict objectForKey:@"DownloadHistory"];
	NSMutableArray *array = [NSMutableArray array];
	int i = 0;
	BOOL separatorAdded = NO;
	
	for (i = 0; i < [historyArray count]; i ++){
		NSDictionary *itemDict = [historyArray objectAtIndex:i];
		NSString *filePath = [itemDict objectForKey:@"DownloadEntryPath"];
		filePath = [filePath stringByExpandingTildeInPath];
		if([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
			if(!separatorAdded){
				separatorAdded = YES;
				[array addObject:[NSMenuItem separatorItem]];
				NSString *headerString = NSLocalizedString(@"Link to downloaded file:",@"");
				NSMenuItem *headerItem = [[NSMenuItem alloc] initWithTitle:headerString
																	action:nil
															 keyEquivalent:@""];
				[headerItem setTarget:self];
				[array addObject:[headerItem autorelease]];
			}
			NSString *fileName = [filePath lastPathComponent];
			NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:filePath];
			[image setSize: NSMakeSize(16, 16)];
			
			NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:fileName
														  action:@selector(setLocalURLPathFromMenuItem:)
												   keyEquivalent:@""];
			[item setRepresentedObject:filePath];
			[item setImage:image];
			if([item respondsToSelector:@selector(setIndentationLevel:)]){
			    [item setIndentationLevel:1];
			}
			[array addObject:[item autorelease]];
		}
	}

	return array;
}

- (NSArray *)getPreviewRecentDocumentsMenu{
	BOOL success = CFPreferencesSynchronize((CFStringRef)@"com.apple.Preview",
									   kCFPreferencesCurrentUser,
									   kCFPreferencesCurrentHost);
	
	if(!success){
		NSLog(@"error syncing preview's prefs!");
	}
	
	NSArray *historyArray = (NSArray *) CFPreferencesCopyAppValue((CFStringRef) @"NSRecentDocumentRecords",
								      (CFStringRef) @"com.apple.Preview");

	NSMutableArray *array = [NSMutableArray array];
	
	if (!historyArray) return array;
	
	int i = 0;
	BOOL separatorAdded = NO;
	
	for (i = 0; i < [(NSArray *)historyArray count]; i ++){
		NSDictionary *itemDict1 = [(NSArray *)historyArray objectAtIndex:i];
		NSDictionary *itemDict2 = [itemDict1 objectForKey:@"_NSLocator"];
		NSData *aliasData = [itemDict2 objectForKey:@"_NSAlias"];
		
		BDAlias *bda = [BDAlias aliasWithData:aliasData];
		
		NSString *filePath = [bda fullPath];

		filePath = [filePath stringByExpandingTildeInPath];
		if([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
			if(!separatorAdded){
				separatorAdded = YES;
				[array addObject:[NSMenuItem separatorItem]];
				NSString *headerString = NSLocalizedString(@"Link to Recent File from Preview:",@"");
				NSMenuItem *headerItem = [[NSMenuItem alloc] initWithTitle:headerString
																	action:nil
															 keyEquivalent:@""];
				[headerItem setTarget:self];
				[array addObject:[headerItem autorelease]];
			}
			NSString *fileName = [filePath lastPathComponent];
			NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:filePath];
			[image setSize: NSMakeSize(16, 16)];
			
			NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:fileName
														  action:@selector(setLocalURLPathFromMenuItem:)
												   keyEquivalent:@""];
			[item setRepresentedObject:filePath];
			[item setImage:image];
			if([item respondsToSelector:@selector(setIndentationLevel:)]){
			    [item setIndentationLevel:1];
			}
			[array addObject:[item autorelease]];
		}
	}
	
	CFRelease(historyArray);
	return array;
}


- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem{
	if([menuItem action] == nil){
		return NO;
	}
	else if ([menuItem action] == @selector(generateCiteKey:)) {
		[menuItem setTitle: NSLocalizedString(@"Generate Cite Key", @"Generate Cite Key")];
		if ([tabView indexOfTabViewItem:[tabView selectedTabViewItem]] != 0) {
			return NO;
		}
	}
	return YES;
}

- (IBAction)viewRemote:(id)sender{
    NSWorkspace *sw = [NSWorkspace sharedWorkspace];
    NSString *rurl = [theBib valueOfField:BDSKUrlString];
    if ([@"" caseInsensitiveCompare:rurl] != NSOrderedSame) {
        [sw openURL:[NSURL URLWithString:rurl]];
    }
}

#pragma mark Cite Key handling methods
- (void)setupCautionIcon{
	IconRef cautionIconRef;
	OSErr err = GetIconRef(kOnSystemDisk,
						   kSystemIconsCreator,
						   kAlertCautionBadgeIcon,
						   &cautionIconRef);
	if(err){
		[NSException raise:@"BDSK No Icon Exception"  
					format:@"Error getting the caution badge icon. To decipher the error number (%d),\n see file:///Developer/Documentation/Carbon/Reference/IconServices/index.html#//apple_ref/doc/uid/TP30000239", err];
	}
	
	int size = 32;
	
	cautionIconImage = [[NSImage alloc] initWithSize:NSMakeSize(size,size)]; 
	CGRect iconCGRect = CGRectMake(0,0,size,size);
	
	[cautionIconImage lockFocus]; 
	
	PlotIconRefInContext((CGContextRef)[[NSGraphicsContext currentContext] 
		graphicsPort],
						 &iconCGRect,
						 kAlignAbsoluteCenter, //kAlignNone,
						 kTransformNone,
						 NULL /*inLabelColor*/,
						 kPlotIconRefNormalFlags,
						 cautionIconRef); 
	
	[cautionIconImage unlockFocus];
}

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
		[citeKeyWarningButton setImage:cautionIconImage];
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
}

- (IBAction)bibTypeDidChange:(id)sender{
    if (![[self window] makeFirstResponder:[self window]]){
        [[self window] endEditingFor:nil];
    }
    currentType = [bibTypeButton titleOfSelectedItem];
    if([theBib type] != currentType){
        [theBib makeType:currentType];
		[self finalizeChanges];
        [self setupForm];
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:currentType
                                                           forKey:BDSKPubTypeStringKey];
    }
}

- (void)fixURLs{
    NSString *lurl = [theBib localURLPathRelativeTo:[[theDocument fileName] stringByDeletingLastPathComponent]];
    NSString *rurl = [theBib valueOfField:BDSKUrlString];
    NSImage *icon;
    NSURL *remote = [NSURL URLWithString:rurl];
    NSDictionary *linkAttributes;
    NSMutableAttributedString *link = [[NSMutableAttributedString alloc] initWithString:rurl];
    NSString *ext = nil;


    BOOL drawerWasOpen = ([documentSnoopDrawer state] == NSDrawerOpenState);
    BOOL drawerIsOpening = ([documentSnoopDrawer state] == NSDrawerOpeningState);

    if(drawerWasOpen) [documentSnoopDrawer close];
    //local is either a file:// URL -or a path
    // How to use stringByExpandingTildeInPath to expand the URL? get the url, get its path, then expand that, then replace it as the url? ugly. 

    
    if (lurl && [[NSFileManager defaultManager] fileExistsAtPath:lurl]){
            icon = [[NSWorkspace sharedWorkspace] iconForFile:lurl];
            [viewLocalButton setIconImage:icon];      
            [[viewLocalButton cell] seticonActionEnabled:YES];
            [viewLocalButton setToolTip:@"View File"];
            [[self window] setRepresentedFilename:lurl];
			
			ext = [lurl pathExtension];
			BOOL fileIsPSOrPDF = ([ext isEqualToString:@"ps"] || [ext isEqualToString:@"pdf"]);
			
			if(fileIsPSOrPDF){
				[documentSnoopButton setEnabled:YES];
				[documentSnoopButton setToolTip:NSLocalizedString(@"Show first page in a drawer.", @"show first page in a drawer")];
				[documentTextSnoopButton setEnabled:YES];
				[documentTextSnoopButton setToolTip:NSLocalizedString(@"Show first page as text in a drawer.", @"show first page as text in a drawer")];
            }
			
            if(drawerWasOpen || drawerIsOpening){
                if(!_pdfSnoopImage){
                    _pdfSnoopImage = [[NSImage alloc] initWithContentsOfFile:lurl];
                }

                //NSLog(@"setting snoop to %@ from file %@", _pdfSnoopImage, lurl);

                if(_pdfSnoopImage){
                    // [documentSnoopImageView setImage:_pdfSnoopImage];
                    [documentSnoopImageView loadFromPath:lurl];
                    [_pdfSnoopImage setBackgroundColor:[NSColor whiteColor]];
                    
                    [documentSnoopScrollView setDocumentViewAlignment:NSImageAlignTopLeft];
                    if(drawerWasOpen) // open it again.
                        [documentSnoopDrawer open];
                    
                }
            }
    }else{
        [viewLocalButton setIconImage:[NSImage imageNamed:@"QuestionMarkFile"]];
		[[viewLocalButton cell] seticonActionEnabled:NO];
        [viewLocalButton setToolTip:NSLocalizedString(@"Choose a file to link with in the Local-Url Field", @"bad/empty local url field")];
        [[self window] setRepresentedFilename:@""];

        [documentSnoopButton setEnabled:NO];
        [documentSnoopButton setToolTip:NSLocalizedString(@"Bad or Empty Local-Url Field", @"bad/empty local field")];
        [documentTextSnoopButton setEnabled:NO];
        [documentTextSnoopButton setToolTip:NSLocalizedString(@"Bad or Empty Local-Url Field", @"bad/empty local field")];
        
    }

    if(remote && ![rurl isEqualToString:@""]){
        linkAttributes= [NSDictionary dictionaryWithObjectsAndKeys: rurl, NSLinkAttributeName,
            [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName,
            [NSColor blueColor], NSForegroundColorAttributeName,
            NULL];
        [link setAttributes:linkAttributes range:NSMakeRange(0,[rurl length])];
        [viewRemoteButton setAttributedTitle:link];     // set the URL field
        linkAttributes= [NSDictionary dictionaryWithObjectsAndKeys: rurl, NSLinkAttributeName,
            [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName,
            [NSColor redColor], NSForegroundColorAttributeName,
            NULL];
		[link setAttributes:linkAttributes range:NSMakeRange(0,[rurl length])];
        [viewRemoteButton setAttributedAlternateTitle:link];     // set the URL field

        [viewRemoteButton setEnabled:YES];
        [viewRemoteButton setToolTip:NSLocalizedString(@"View in web browser", @"")];
    }else{
        [viewRemoteButton setTitle:rurl];
        [viewRemoteButton setEnabled:NO];
        [viewRemoteButton setToolTip:NSLocalizedString(@"Bad or Empty Url Field", @"")];
    }

    [link release];
}

#pragma mark || choose-local-url open-sheet support

- (IBAction)chooseLocalURL:(id)sender{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    int result = [oPanel runModalForDirectory:nil
										 file:nil
										types:nil];
    if (result == NSOKButton) {
		NSString *fileURLString = [[NSURL fileURLWithPath:[[oPanel filename] stringByStandardizingPath]] absoluteString];
        [theBib setField:@"Local-Url" toValue:fileURLString];
		if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKFilePapersAutomaticallyKey]){
			[[BibFiler sharedFiler] file:YES 
								  papers:[NSArray arrayWithObject:theBib]
							fromDocument:(BibDocument *)theDocument];
			NSRunAlertPanel(NSLocalizedString(@"Paper Filed",@""),
							NSLocalizedString(@"The paper %@ was moved to your Papers Directory.",@""),
							NSLocalizedString(@"OK",@"OK"),
							nil, nil, fileURLString);
		}
		
		[self finalizeChanges];
		[self setupForm];
        [self fixURLs];
    }
    
}

- (void)setLocalURLPathFromMenuItem:(NSMenuItem *)sender{
	NSString *path = [sender representedObject];
	
	[theBib setField:@"Local-Url" toValue:[[NSURL fileURLWithPath:[path stringByStandardizingPath]] absoluteString]];
	[self finalizeChanges];
	[self setupForm];
	[self fixURLs];
}

// ----------------------------------------------------------------------------------------
#pragma mark ||  add-Field-Sheet Support
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
    NSEnumerator *keyE = [[[[theBib pubFields] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]objectEnumerator];
    NSString *k;
    [delFieldPopUp removeAllItems];
    while(k = [keyE nextObject]){
        if(![k isEqualToString:BDSKAnnoteString] &&
           ![k isEqualToString:BDSKAbstractString] &&
           ![k isEqualToString:BDSKRssDescriptionString])
            [delFieldPopUp addItemWithTitle:k];
    }
    [delFieldPopUp selectItemAtIndex:0];
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

- (void)controlTextDidEndEditing:(NSNotification *)aNotification{
    // here for undo
}

// sent by the NSForm
- (IBAction)textFieldDidEndEditing:(id)sender{
    NSCell *sel = [sender cellAtIndex: [sender indexOfSelectedItem]];
    NSString *title = [sel title];
	NSString *value = [sel stringValue];
	NSString *prevValue = [theBib valueOfField:title];
	
    if([sender indexOfSelectedItem] != -1 &&
	   ![value isEqualToString:prevValue]){
		
		[theBib setField:title toValue:value];
		
		// autogenerate cite key if we have enough information
		if ( [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKCiteKeyAutogenerateKey] == NSOnState &&
			 [theBib canSetCiteKey] ) {
			[self generateCiteKey:sender];
		}
	}
}

- (void)bibDidChange:(NSNotification *)notification{
// unused	BibItem *notifBib = [notification object];
	NSDictionary *userInfo = [notification userInfo];
	
	if([[userInfo objectForKey:@"type"] isEqualToString:@"Add/Del Field"]){
		[self finalizeChanges];
		[self setupForm];
		return;
	}

	NSString *changedTitle = [userInfo objectForKey:@"key"];
	NSString *newValue = [userInfo objectForKey:@"value"];
	
	if([changedTitle isEqualToString:@"Cite Key"]){
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
			if([[entry title] isEqualToString:changedTitle])
				break;
		}
		if(entry)
			[entry setObjectValue:newValue];
	}
	
	if([changedTitle isEqualToString:BDSKUrlString] || 
	   [changedTitle isEqualToString:BDSKLocalUrlString]){
            [self fixURLs];
            // ARM: This is a hack to get the icon to show up immediately; perhaps the button should do this itself?  I think it's unable to set the image in fixURLs because of the drag op
            [[viewLocalButton cell] drawWithFrame:[viewLocalButton frame]
                                           inView:[viewLocalButton superview]];      
		[_textSnoopString release];
		[_pdfSnoopImage release];
		_textSnoopString = nil;
		_pdfSnoopImage = nil;
	}
	
	if([changedTitle isEqualToString:@"Title"]){
		[[self window] setTitle:newValue];
	}
	
	if([changedTitle isEqualToString:@"Author"]){
		[authorTableView reloadData];
	}
	
}

// sent by the notesView and the abstractView
- (void)textDidChange:(NSNotification *)aNotification{
    if([aNotification object] == notesView){
        [theBib setField:BDSKAnnoteString toValue:[notesView string]];
    }
    else if([aNotification object] == abstractView){
        [theBib setField:BDSKAbstractString toValue:[abstractView string]];
    }
    else if([aNotification object] == rssDescriptionView){
        // NSLog(@"setting rssdesc to %@", [rssDescriptionView string]);
        [theBib setField:BDSKRssDescriptionString toValue:[rssDescriptionView string]];
    }
}

- (void)docWillSave:(NSNotification *)notification{
	// NSDictionary *userInfo = [notification userInfo];
	
    if (![[self window] makeFirstResponder:[self window]]) {
        [[self window] endEditingFor:nil];
    }
}
	
- (void)bibWillBeRemoved:(NSNotification *)notification{
	// NSDictionary *userInfo = [notification userInfo];
	
	[self close];
	[theBib setEditorObj:nil]; //cmh: obsolete?
}
	
- (void)docWindowWillClose:(NSNotification *)notification{
	// NSDictionary *userInfo = [notification userInfo];
	
	[[self window] close];
}

#pragma mark -
#pragma mark snoop drawer stuff

- (void)toggleSnoopDrawer:(id)sender{
	NSView* oldContentView = [documentSnoopDrawer contentView];
		
    if (sender == documentSnoopButton) {
        [documentSnoopDrawer setContentView:pdfSnoopContainerView];
    }else{
        [documentSnoopDrawer setContentView:textSnoopContainerView];
    }
	
	if (oldContentView == [documentSnoopDrawer contentView]) {
		[documentSnoopDrawer toggle:sender];
	}
	else {
		[documentSnoopDrawer close:sender];
		[documentSnoopDrawer open:sender];
	}
}

- (void)drawerWillOpen:(NSNotification *)notification{
    //@@snoop text: these variables all go with the refactoring
    NSString *cmdString = nil;
    NSString *lurl = [theBib valueOfField:BDSKLocalUrlString];
    NSURL *local = nil;
    

    [self fixURLs]; //no this won't cause a loop - see fixURLs. Please don't break that though. Boy it's fragile.
    if ([documentSnoopDrawer contentView] == pdfSnoopContainerView) {
		[documentSnoopButton setToolTip:NSLocalizedString(@"Close drawer", @"")];
	} else {
		[documentTextSnoopButton setToolTip:NSLocalizedString(@"Close drawer", @"")];
	}

    // @@snoop text - refactor this into a separate method later
    // @@URL handling refactor this
    if(![@"" isEqualToString:lurl]){
        local = [NSURL URLWithString:lurl];
        if(!local){
            local = [NSURL fileURLWithPath:[lurl stringByExpandingTildeInPath]];
        }
    }else{
        return;
    }

    if([documentSnoopDrawer contentView] == textSnoopContainerView){

    cmdString = [NSString stringWithFormat:@"%@/pdftotext -f 1 -l 1 \"%@\" -",[[NSBundle mainBundle] resourcePath], [local path],
        nil];

        if(!_textSnoopString){
            _textSnoopString = [[[BDSKShellTask shellTask] runShellCommand:cmdString withInputString:nil] retain];
        }
        [documentSnoopTextView setString:_textSnoopString];
    }
}


- (void)drawerWillClose:(NSNotification *)notification{
    [documentSnoopButton setToolTip:NSLocalizedString(@"Show the first page as PDF in a drawer.", @"")];
    [documentTextSnoopButton setToolTip:NSLocalizedString(@"Show the first page as Text in a drawer.", @"")];
}

- (void)windowWillClose:(NSNotification *)notification{
 //@@citekey   [[self window] makeFirstResponder:citeKeyField]; // makes the field check if there is a duplicate field.
    if (![[self window] makeFirstResponder:[self window]]) {
		[[self window] endEditingFor:nil];
	}
	[documentSnoopDrawer close];
	[theDocument removeWindowController:self];
}

// we want to have the same undoManager as our document, so we use this 
// NSWindow delegate method to return the doc's undomanager.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender{
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

- (void)setDocument:(NSDocument *)d{
	
}




@end
