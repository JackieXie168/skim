//  BibDocument.m

//  Created by Michael McCracken on Mon Dec 17 2001.
/*
This software is Copyright (c) 2001,2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BibDocument.h"
#import "BibItem.h"
#import "BibAuthor.h"
#import "BibEditor.h"
#import "BibDocument_DataSource.h"
#import "BibDocumentView_Toolbar.h"
#import "BibAppController.h"
#import "RYZImagePopUpButtonCell.h"


#include <stdio.h>
char * InputFilename; // This is here because the btparse library can't live without it.

NSString* LocalDragPasteboardName = @"edu.ucsd.cs.mmccrack.bibdesk: Local Publication Drag Pasteboard";
NSString* BDSKBibTeXStringPboardType = @"edu.ucsd.cs.mmcrack.bibdesk: Local BibTeX String Pasteboard";


#import "btparse.h"

@implementation BibDocument

- (id)init{
    if(self = [super init]){
        publications = [[NSMutableArray alloc] initWithCapacity:1];
        shownPublications = [[NSMutableArray alloc] initWithCapacity:1];
        frontMatter = [[NSMutableString alloc] initWithString:@""];
        authors = [[NSMutableSet alloc] init];

        quickSearchKey = [[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKCurrentQuickSearchKey] retain];
        if(!quickSearchKey){
            quickSearchKey = [[NSString alloc] initWithString:@"Title"];
        }
        PDFpreviewer = [BDSKPreviewer sharedPreviewer];
        showColsArray = [[NSMutableArray arrayWithObjects:
            [NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],nil] retain];
        localDragPboard = [NSPasteboard pasteboardWithName:LocalDragPasteboardName];
        tableColumns = [[NSMutableDictionary dictionaryWithCapacity:6] retain];
        fileOrderCount = 1;
        // Register as observer of font change events.
        [[NSNotificationCenter defaultCenter] addObserver:self
   selector:@selector(handleFontChangedNotification:)
       name:BDSKTableViewFontChangedNotification
     object:nil];
        
     [[NSNotificationCenter defaultCenter] addObserver:self
   selector:@selector(handlePreviewDisplayChangedNotification:)
       name:BDSKPreviewDisplayChangedNotification
     object:nil];

     // register for general UI changes notifications:
     [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(handleUpdateUINotification:)
                                                  name:BDSKDocumentUpdateUINotification
                                                object:nil];

     // register for tablecolumn changes notifications:
     [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(handleTableColumnChangedNotification:)
                                                  name:BDSKTableColumnChangedNotification
                                                object:nil];
     
     // want to register for changes to the custom string array too...
     [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(handleCustomStringsChangedNotification:)
                                                  name:BDSKCustomStringsChangedNotification
                                                object:nil];

	 //  register to observe for item change notifications here.
	 [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(handleBibItemChangedNotification:)
                                                  name:BDSKBibItemChangedNotification
                                                object:nil];

	 // register to observe for add/delete items.
	 [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(handleBibItemAddDelNotification:)
                                                  name:BDSKDocAddItemNotification
                                                object:self];

	 [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(handleBibItemAddDelNotification:)
                                                  name:BDSKDocDelItemNotification
                                                object:self];
	 
	 
     customStringArray = [[NSMutableArray arrayWithCapacity:6] retain];
     [customStringArray setArray:[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKCustomCiteStringsKey]];

     tableColumnsChanged = YES;
     sortDescending = YES;
    }
    return self;
}


- (void)awakeFromNib{
    NSEnumerator *nibTCE = [[tableView tableColumns] objectEnumerator];
    NSTableColumn *tc;
    NSArray *prefTCNames = [[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKShownColsNamesKey];
    NSEnumerator *prefTCNamesE = [prefTCNames objectEnumerator];
    NSString *tcName;
    
    NSSize drawerSize;
    //NSString *viewByKey = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKViewByKey];
	
	[self setupSearchField];

    // this is kind of a hack... we're getting the pre-configured tableColumns
    //    from the nib file, and then we're treating them just like the other ones.
    
    // add all the tablecolumns that are in the nib to our tableColumns dict.
    while (tc = [nibTCE nextObject]) {
        [tableColumns setObject:tc forKey:[tc identifier]];
    
    }
    // 
    tc = nil;
    // next, add tablecolumns that show up in the system prefs.
    while (tcName = [prefTCNamesE nextObject]) {
        tc = [[[NSTableColumn alloc] initWithIdentifier:tcName] autorelease];
        [tc setResizable:YES];

        [tableColumns setObject:tc forKey:[tc identifier]];
    }
   
    [tableView setDoubleAction:@selector(editPubCmd:)];
    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, NSFilenamesPboardType, nil]];

    [tableView setMenu:contextualMenu];
    
    [splitView setPositionAutosaveName:[self fileName]];
    
    // 1:I'm using this as a catch-all.
    // 2:this gets called lots of other places, no need to. [self updateUI]; 

    // workaround for IB flakiness...
    drawerSize = [customCiteDrawer contentSize];
    [customCiteDrawer setContentSize:NSMakeSize(100,drawerSize.height)];

	showingCustomCiteDrawer = NO;
	
    // finally, make sure the font is correct initially:
	[self setTableFont];
	[tableView reloadData];
	
	
	/* ssp: 2004-08-02
		Setup the action menu button. Thanks to Steffen for his help.
		This isn't really good. You can click slightly left of the button and it will still be activated. I couldn't get Popup buttons to work in a way that I could set the button's look independently from the attached menu. 
		If somebody actually understands the documentation on this (in case it is correct), make it work just like in Mail. 
		This is also slightly complicated using our own subclass of NSPopUpButtonCell to make things happen.
	*/
	BDSKPopUpButtonCell * myCell = [[[BDSKPopUpButtonCell alloc] initImageCell:[NSImage imageNamed:@"Action"]] autorelease];
	[actionMenuButton setCell:myCell];
	[myCell setArrowPosition:NSPopUpNoArrow];
	[myCell setPullsDown:YES];
	[myCell setBordered:NO];
 	[myCell setBezelStyle:NSRegularSquareBezelStyle];
	
	[self updateActionMenu:nil];
    

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popup:) name:NSPopUpButtonWillPopUpNotification object:actionMenuButton];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismiss:) name:BDSKPopUpDismissedNotification object:actionMenuButton];
	
	contextualMenu = [[[NSApp delegate] displayMenuItem] submenu];		// better retain this?
}


- (void)dealloc{
#if DEBUG
    NSLog(@"bibdoc dealloc");
#endif
    if ([self undoManager]) {
		[[self undoManager] removeAllActionsWithTarget:self];
	}
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [publications release]; // these should cause the bibitems to get dealloc'ed
    [shownPublications release];
    [frontMatter release];
    [authors release];
    [quickSearchTextDict release];
    [quickSearchKey release];
    [showColsArray release];
    [customStringArray release];
    [toolbarItems release];
    [tableColumns release];
    [super dealloc];
}



/* ssp:  2004-08-02
Handle Notifications by the popup button to update its icon and its menu before opening
*/
- (void)popup:(NSNotification *)notification {
	[[[actionMenuButton menu] itemAtIndex:0] setImage:[NSImage imageNamed:@"Action_Pressed"]];
}

- (void)dismiss:(NSNotification *)notification {
	[[[actionMenuButton menu] itemAtIndex:0] setImage:[NSImage imageNamed:@"Action"]];
}


- (void) updateActionMenu:(id) aNotification {
	NSMenu * menu = [self menuForSelection];
	NSMenuItem * menuItem = [[[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""] autorelease];
	[menuItem setImage:[NSImage imageNamed:@"Action"]];
	[menu insertItem:menuItem atIndex:0]; 
	[actionMenuButton setMenu:menu];
	
	[actionMenuButton setEnabled:([self numberOfSelectedPubs] != 0)];
}


- (void)setPublications:(NSArray *)newPubs{
	if(newPubs != publications){
		NSUndoManager *undoManager = [self undoManager];
		[[undoManager prepareWithInvocationTarget:self] setPublications:publications];
		[undoManager setActionName:NSLocalizedString(@"Set Publications",@"")];
		
		[publications autorelease];
		publications = [newPubs mutableCopy];
		
		NSEnumerator *pubEnum = [publications objectEnumerator];
		BibItem *pub;
		while (pub = [pubEnum nextObject]) {
			[pub setDocument:self];
		}
		
		NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:newPubs, @"pubs", nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"Set the publications in document"
															object:self
														  userInfo:notifInfo];
    }
}

- (NSMutableArray *) publications{
    return [[publications retain] autorelease];
}

- (void)insertPublication:(BibItem *)pub atIndex:(unsigned int)index {
	[self insertPublication:pub atIndex:index lastRequest:YES];
}

- (void)insertPublication:(BibItem *)pub atIndex:(unsigned int)index lastRequest:(BOOL)last{
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removePublication:pub];
	
	[publications insertObject:pub atIndex:index];
	[shownPublications insertObject:pub atIndex:index];
	[pub setDocument:self];
	
	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:pub, @"pub",
		(last ? @"YES" : @"NO"), @"lastRequest", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocAddItemNotification //should change this
														object:self
													  userInfo:notifInfo];
}

- (void)addPublication:(BibItem *)pub{
	[self addPublication:pub lastRequest:YES];
}

- (void)addPublication:(BibItem *)pub lastRequest:(BOOL)last{
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removePublication:pub];
	
	[publications addObject:pub];
	[shownPublications addObject:pub];
	[pub setDocument:self];

	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:pub, @"pub",
		(last ? @"YES" : @"NO"), @"lastRequest", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocAddItemNotification
														object:self
													  userInfo:notifInfo];
}

- (void)removePublication:(BibItem *)pub{
	[self removePublication:pub lastRequest:YES];
}

- (void)removePublication:(BibItem *)pub lastRequest:(BOOL)last{
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] addPublication:pub];
	
	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:self, @"Sender", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocWillRemoveItemNotification
														object:pub
													  userInfo:notifInfo];	
	
	[pub setDocument:nil];
	[publications removeObjectIdenticalTo:pub];
	[shownPublications removeObjectIdenticalTo:pub];
	
	notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:pub, @"pub",
		(last ? @"YES" : @"NO"), @"lastRequest", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocDelItemNotification
														object:self
													  userInfo:notifInfo];	
}

- (void)handleBibItemAddDelNotification:(NSNotification *)notification{
	NSDictionary *userInfo = [notification userInfo];
	BOOL wasLastRequest = [[userInfo objectForKey:@"lastRequest"] isEqualToString:@"YES"];

	if(wasLastRequest){
	//	NSLog(@"was last request in handleBibItemAddDel");
		// This method should also check the publication to see if it's selected?
		// and maybe also resort it... - maybe not resort this.
        [self refreshAuthors];
		[self updateUI];
	}
}


// accessor method used by AppleScript (at least)
- (NSArray*) authors {
	return [authors allObjects];
}


- (void)refreshAuthors{
    NSEnumerator *pubE = [shownPublications objectEnumerator];
    BibItem *pub = nil;
    
    while (pub = [pubE nextObject]) {
        // for each pub, get its authors and add them to the set
        [authors addObjectsFromArray:[pub pubAuthors]];
    }
    
}

- (NSArray *)publicationsForAuthor:(BibAuthor *)anAuthor{
    NSMutableSet *auths = [NSMutableSet set];
    NSEnumerator *pubEnum = [publications objectEnumerator];
    BibItem *bi;
    NSMutableArray *anAuthorPubs = [NSMutableArray array];
    
    while(bi = [pubEnum nextObject]){
        [auths addObjectsFromArray:[bi pubAuthors]];
        if([auths member:anAuthor] != nil){
            [anAuthorPubs addObject:bi];
        }
        [auths removeAllObjects];
    }
    return anAuthorPubs;
}


- (BOOL)citeKeyIsUsed:(NSString *)aCiteKey byItemOtherThan:(BibItem *)anItem{
    NSEnumerator *bibE = [publications objectEnumerator];
    BibItem *bi = nil;
    while(bi = [bibE nextObject]){
        if (bi == anItem) continue;
        if ([[bi citeKey] isEqualToString:aCiteKey]) {
            return YES;
        }
    }
    return NO;
}

- (IBAction)generateCiteKeys:(id)sender
{
	NSEnumerator *selEnum = [self selectedPubEnumerator];
	NSNumber *row;
	BibItem *aPub;
	
	while (row = [selEnum nextObject]) {
		aPub = [shownPublications objectAtIndex:[row intValue]];
		[aPub setCiteKey:[aPub suggestedCiteKey]];
	}
}

- (NSString *)windowNibName
{
    return @"BibDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
//	NSLog(@"windowcontroller didloadnib");
    [super windowControllerDidLoadNib:aController];
    [self setupToolbar];
    [[aController window] setFrameAutosaveName:[self displayName]];
    [documentWindow makeFirstResponder:tableView];	
    [self setupTableColumns]; // calling it here mostly just makes sure that the menu is set up.
	[self setTableFont];
}

#pragma mark -
#pragma mark  Document Saving and Reading

- (IBAction)saveDocument:(id)sender{

    [super saveDocument:sender];
    if([[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKAutoSaveAsRSSKey] == NSOnState
       && ![[self fileType] isEqualToString:@"Rich Site Summary file"]){
        // also save doc as RSS
#if DEBUG
        //NSLog(@"also save as RSS in saveDoc");
#endif
        [self exportAsRSS:nil];
    }
}

- (IBAction)exportAsHTML:(id)sender{
    [self exportAsFileType:@"html"];
}

- (IBAction)exportAsRSS:(id)sender{
    [self exportAsFileType:@"rss"];
}

- (void)exportAsFileType:(NSString *)fileType{
    NSSavePanel *sp = [NSSavePanel savePanel];
    [sp setRequiredFileType:fileType];
    [sp setDelegate:self];
    if([fileType isEqualToString:@"rss"]){
        [sp setAccessoryView:rssExportAccessoryView];
        // should call a [self setupRSSExportView]; to populate those with saved userdefaults!
    }
    [sp beginSheetForDirectory:nil
                          file:[[NSString stringWithString:[[self fileName] stringByDeletingPathExtension]] lastPathComponent]
                modalForWindow:documentWindow
                 modalDelegate:self
                didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
                   contextInfo:fileType];

}
- (void)savePanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    NSData *fileData = nil;
    NSString *fileName = nil;
    NSSavePanel *sp = (NSSavePanel *)sheet;
    NSString *fileType = (NSString *)contextInfo;
    
    if(returnCode == NSOKButton){
        fileName = [sp filename];
        if([fileType isEqualToString:@"rss"]){
            fileData = [self dataRepresentationOfType:@"Rich Site Summary file"];
        }else if([fileType isEqualToString:@"html"]){
            fileData = [self dataRepresentationOfType:@"HTML"];
        }
        [fileData writeToFile:fileName atomically:YES];
    }
    [sp setRequiredFileType:@"bib"]; // just in case...
    [sp setAccessoryView:nil];
}

- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)docType{
	if ([docType isEqualToString:@"RIS/Medline File"]){
		// Can't save pubmed files now. Could try saving as bibtex.
		int returnCode = NSRunAlertPanel(@"Cannot Save as PubMed.",
						 @"Saving PubMed Files is not currently supported. You can choose to save as BibTeX instead.",
						 @"Save as BibTeX", @"Don't Save", nil, nil);
		if(returnCode == NSAlertDefaultReturn){
			NSString *newName = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"bib"];
		    return [self writeToFile:newName ofType:@"bibTeX database"];
		}else{
			return NO;
		}
	}else{
	    return [super writeToFile:fileName ofType:docType];
	}
}

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocumentWillSaveNotification
														object:self
													  userInfo:[NSDictionary dictionary]];
    
    if ([aType isEqualToString:@"bibTeX database"]){
        return [self bibDataRepresentation];
    }else if ([aType isEqualToString:@"Rich Site Summary file"]){
        return [self rssDataRepresentation];
    }else if ([aType isEqualToString:@"HTML"]){
        return [self htmlDataRepresentation];
    }else 
		return nil;
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType{
    if([super readFromFile:fileName ofType:docType]){
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *newName = [[[self fileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"bib"];
	int i = 0;
	NSArray *writableTypesArray = [[self class] writableTypes];
	NSString *finalName = [NSString stringWithString:newName];
	
	if(![writableTypesArray containsObject:[self fileType]]){
	    // this sets the file type and name if we open a type for which we are a viewer
	    // we don't want to overwrite an existing file, though
	    while([fm fileExistsAtPath:finalName]){
		i++;
		finalName = [[[newName stringByDeletingPathExtension] stringByAppendingFormat:@"%i",i] stringByAppendingPathExtension:@"bib"];
	    }
	    NSRunAlertPanel(NSLocalizedString(@"Import Successful",
					      "alert title"),
			    NSLocalizedString(@"Your file has been converted to BibTeX and assigned a unique name.  To save the file or change the name, please use the Save As command.",
					      "file has been converted and assigned a unique name, can be saved with save as"),
			    nil,nil, nil, nil);
	    [self setFileName:finalName];
	    [self setFileType:@"bibTeX database"];  // this is the only type we support via the save command

	} return YES;
    
    } else return NO;  // if super failed

}

#define AddDataFromString(s) [d appendData:[s dataUsingEncoding:NSASCIIStringEncoding]]
#define AddDataFromFormCellWithTag(n) [d appendData:[[[rssExportForm cellAtIndex:[rssExportForm indexOfCellWithTag:n]] stringValue] dataUsingEncoding:NSASCIIStringEncoding]]

- (NSData *)rssDataRepresentation{
    BibItem *tmp;
    NSEnumerator *e = [publications objectEnumerator];
    NSMutableData *d = [NSMutableData data];
    /*NSString *applicationSupportPath = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
stringByAppendingPathComponent:@"Application Support"]
stringByAppendingPathComponent:@"BibDesk"]; */

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
    [d appendData:[[rssExportTextField stringValue] dataUsingEncoding:NSASCIIStringEncoding]];
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
    [d appendData:[[[NSCalendarDate calendarDate] descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S %Z"] dataUsingEncoding:NSASCIIStringEncoding]];
    AddDataFromString(@"</lastBuildDate>\n");
    while(tmp = [e nextObject]){
      [d appendData:[[NSString stringWithString:@"\n\n"] dataUsingEncoding:NSASCIIStringEncoding  allowLossyConversion:YES]];
      [d appendData:[[[BDSKConverter sharedConverter] stringByTeXifyingString:[tmp RSSValue]] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    }
    [d appendData:[@"</channel>\n</rss>" dataUsingEncoding:NSASCIIStringEncoding  allowLossyConversion:YES]];
    //    [d appendData:[@"</channel>\n</rdf:RDF>" dataUsingEncoding:NSASCIIStringEncoding  allowLossyConversion:YES]];
    return d;
}

- (NSData *)htmlDataRepresentation{
    NSString *applicationSupportPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/BibDesk"]; 


    NSString *fileTemplate = [NSString stringWithContentsOfFile:[applicationSupportPath stringByAppendingPathComponent:@"htmlExportTemplate"]];
    fileTemplate = [fileTemplate stringByParsingTagsWithStartDelimeter:@"<$"
                                                          endDelimeter:@"/>" 
                                                           usingObject:self];
    return [fileTemplate dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];    
}

- (NSString *)publicationsAsHTML{
    NSMutableString *s = [NSMutableString stringWithString:@""];
    NSString *applicationSupportPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/BibDesk"]; 
    NSString *itemTemplate = [NSString stringWithContentsOfFile:[applicationSupportPath stringByAppendingPathComponent:@"htmlItemExportTemplate"]];
    BibItem *tmp;
    NSEnumerator *e = [publications objectEnumerator];
    while(tmp = [e nextObject]){
        [s appendString:[NSString stringWithString:@"\n\n"]];
        [s appendString:[tmp HTMLValueUsingTemplateString:itemTemplate]];
    }
    return s;
}

- (NSData *)bibDataRepresentation{
    BibItem *tmp;
    NSEnumerator *e = [[publications sortedArrayUsingSelector:@selector(fileOrderCompare:)] objectEnumerator];
    NSMutableData *d = [NSMutableData data];
    NSMutableString *templateFile = [NSMutableString stringWithContentsOfFile:[[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKOutputTemplateFileKey] stringByExpandingTildeInPath]];

    [templateFile appendFormat:@"\n%%%% Created for %@ at %@ \n\n", NSFullUserName(), [NSCalendarDate calendarDate]];
    
    [d appendData:[templateFile dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    [d appendData:[frontMatter dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];

    while(tmp = [e nextObject]){
        [d appendData:[[NSString stringWithString:@"\n\n"] dataUsingEncoding:NSASCIIStringEncoding  allowLossyConversion:YES]];
        //The TeXification is now done in the BibItem bibTeXString method
        //Where it can be done once per field to handle newlines.
        [d appendData:[[tmp bibTeXString] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    }
    return d;
}

#pragma mark -
#pragma mark Opening and Loading Files

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
    if ([aType isEqualToString:@"bibTeX database"]){
        return [self loadBibTeXDataRepresentation:data];
    }else if([aType isEqualToString:@"Rich Site Summary File"]){
        return [self loadRSSDataRepresentation:data];
    }else if([aType isEqualToString:@"RIS/Medline File"]){
        return [self loadPubMedDataRepresentation:data];
    }
    return NO;
}

- (BOOL)loadPubMedDataRepresentation:(NSData *)data{
    int rv = 0;
    BOOL hadProblems = NO;
    NSMutableDictionary *dictionary = nil;
    NSString *tempFileName = nil;
    NSString *dataString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSString* filePath = [self fileName];
    NSMutableArray *newPubs = nil;
    
    // Dirty check to see if we guessed the right encoding.  UTF8 will do fine for ASCII and fairly well for MacRoman but fails for
    // ISO-8859-1 and gives a nil string.  This is a problem with ScienceDirect, if your browser is set to accept 8859-1 by default.
    if(dataString == nil){
	dataString = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
    }
    
    if(!filePath){
        filePath = @"Untitled Document";
    }
    dictionary = [NSMutableDictionary dictionaryWithCapacity:10];
    
    [publications autorelease];
    newPubs = [PubMedParser itemsFromString:dataString
                                      error:&hadProblems
                                frontMatter:frontMatter
                                   filePath:filePath];
    publications = [newPubs retain];
		
	NSEnumerator *pubEnum = [publications objectEnumerator];
	BibItem *pub;
	while (pub = [pubEnum nextObject]) {
		[pub setDocument:self];
	}
    
    if(hadProblems){
        // run a modal dialog asking if we want to use partial data or give up
        rv = NSRunAlertPanel(NSLocalizedString(@"Error reading file!",@""),
                             NSLocalizedString(@"There was a problem reading the file. Do you want to use everything that did work (\"Keep Going\"), edit the file to correct the errors, or give up?\n(If you choose \"Keep Going\" and then save the file, you will probably lose data.)",@""),
                             NSLocalizedString(@"Give up",@""),
                             NSLocalizedString(@"Keep going",@""),
                             NSLocalizedString(@"Edit file", @""));
        if (rv == NSAlertDefaultReturn) {
            // the user said to give up
            return NO;
        }else if (rv == NSAlertAlternateReturn){
            // the user said to keep going, so if they save, they might clobber data...
        }else if(rv == NSAlertOtherReturn){
            // they said to edit the file.
            tempFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
            [dataString writeToFile:tempFileName atomically:YES];
            [[NSApp delegate] openEditWindowWithFile:tempFileName];
            [[NSApp delegate] showErrorPanel:self];
            return NO;
        }
    }
    [shownPublications setArray:publications];
    [self refreshAuthors];
    // since we can't save pubmed files as pubmed files:
    [self updateChangeCount:NSChangeDone];
    
    return YES;
}

- (BOOL)loadRSSDataRepresentation:(NSData *)data{
    //stub
    return NO;
}

- (BOOL)loadBibTeXDataRepresentation:(NSData *)data{
    int rv = 0;
    BOOL hadProblems = NO;
    NSMutableDictionary *dictionary = nil;
    NSString *tempFileName = nil;
    NSString* filePath = [self fileName];
    NSMutableArray *newPubs;

    if(!filePath){
        filePath = @"Untitled Document";
    }
    dictionary = [NSMutableDictionary dictionaryWithCapacity:10];

    // to enable some cheapo timing, uncomment these:
//    NSDate *start = [NSDate date];
//    NSLog(@"start: %@", [start description]);
    [publications autorelease];
    newPubs = [BibTeXParser itemsFromData:data
                                           error:&hadProblems
                                     frontMatter:frontMatter
                                        filePath:filePath];
    publications = [newPubs retain];
		
	NSEnumerator *pubEnum = [publications objectEnumerator];
	BibItem *pub;
	while (pub = [pubEnum nextObject]) {
		[pub setDocument:self];
	}

//    NSLog(@"end %@ elapsed: %f", [[NSDate date] description], [start timeIntervalSinceNow]);

    if(hadProblems){
        // run a modal dialog asking if we want to use partial data or give up
        rv = NSRunAlertPanel(NSLocalizedString(@"Error reading file!",@""),
                             NSLocalizedString(@"There was a problem reading the file. Do you want to use everything that did work (\"Keep Going\"), edit the file to correct the errors, or give up?\n(If you choose \"Keep Going\" and then save the file, you will probably lose data.)",@""),
                             NSLocalizedString(@"Give up",@""),
                             NSLocalizedString(@"Keep going",@""),
                             NSLocalizedString(@"Edit file", @""));
        if (rv == NSAlertDefaultReturn) {
            // the user said to give up
            return NO;
        }else if (rv == NSAlertAlternateReturn){
            // the user said to keep going, so if they save, they might clobber data...
        }else if(rv == NSAlertOtherReturn){
            // they said to edit the file.
            tempFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
            [data writeToFile:tempFileName atomically:YES];
            [[NSApp delegate] openEditWindowWithFile:tempFileName];
            [[NSApp delegate] showErrorPanel:self];
            return NO;
        }
    }
    [shownPublications setArray:publications];
    [self refreshAuthors];
    return YES;
}


- (IBAction)newPub:(id)sender{
    [self createNewBlankPubAndEdit:YES];
}



/* ssp: 2004-07-19
Enhanced delete method that uses a sheet instead of a modal dialogue.
*/
- (IBAction)delPub:(id)sender{
	int numSelectedPubs = [self numberOfSelectedPubs];
	
    if (numSelectedPubs == 0) {
        return;
    }
	
	NSString * pubSingularPlural;
	if (numSelectedPubs == 1) {
		pubSingularPlural= NSLocalizedString(@"publication", @"publication");
	} else {
		pubSingularPlural = NSLocalizedString(@"publications", @"publications");
	}
	
	
	NSBeginCriticalAlertSheet([NSString stringWithFormat:NSLocalizedString(@"Delete %@",@"Delete %@"), pubSingularPlural],NSLocalizedString(@"Delete",@"Delete"),NSLocalizedString(@"Cancel",@"Cancel"),nil,documentWindow,self,@selector(deleteSheetDidEnd:returnCode:contextInfo:),NULL,nil,NSLocalizedString(@"Delete %i %@?",@"Delete %i %@? [i-> number, @-> publication(s)]"),numSelectedPubs, pubSingularPlural);
	
}


- (void) deleteSheetDidEnd:(NSWindow *)sheet returnCode:(int)rv contextInfo:(void *)contextInfo {
    if (rv == NSAlertDefaultReturn) {
        //the user said to delete.
        NSEnumerator * delEnum = [self selectedPubEnumerator];
		NSNumber * rowToDelete;
		id objToDelete;
		int numSelectedPubs = [self numberOfSelectedPubs];
		int numDeletedPubs = 0;
		
        while (rowToDelete = [delEnum nextObject]) {
            objToDelete = [shownPublications objectAtIndex:[rowToDelete intValue]];
			numDeletedPubs++;
			if(numDeletedPubs == numSelectedPubs){
				[self removePublication:objToDelete lastRequest:YES];
			}else{
				[self removePublication:objToDelete lastRequest:NO];
			}
        }
		if (numDeletedPubs > 0) {
			[[self undoManager] setActionName:NSLocalizedString(@"Remove Publication",@"")];
			[tableView deselectAll:nil];
			[self updateUI];
		}
    }else{
        //the user canceled, do nothing.
    }
}



#pragma mark -
#pragma mark Search Field methods

- (IBAction)makeSearchFieldKey:(id)sender{
	if(BDSK_USING_JAGUAR){
		[documentWindow makeFirstResponder:searchFieldTextField];
	}else{
		[documentWindow makeFirstResponder:searchField];
	}
}

- (NSMenu *)searchFieldMenu{
	NSMenu *cellMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
	NSMenuItem *item1, *item2, *item3, *item4, *anItem;
	int curIndex = 0;
	
	item1 = [[NSMenuItem alloc] initWithTitle:@"Recent Searches" action: @selector(limitOne:) keyEquivalent:@""];
	[item1 setTag:NSSearchFieldRecentsTitleMenuItemTag];
	[cellMenu insertItem:item1 atIndex:curIndex++];
	[item1 release];
	item2 = [[NSMenuItem alloc] initWithTitle:@"Recents" action:@selector(limitTwo:) keyEquivalent:@""];
	[item2 setTag:NSSearchFieldRecentsMenuItemTag];
	[cellMenu insertItem:item2 atIndex:curIndex++];
	[item2 release];
	item3 = [[NSMenuItem alloc] initWithTitle:@"Clear" action:@selector(limitThree:) keyEquivalent:@""];
	[item3 setTag:NSSearchFieldClearRecentsMenuItemTag];
	[cellMenu insertItem:item3 atIndex:curIndex++];
	[item3 release];
	// my stuff:
	item4 = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
	[item4 setTag:NSSearchFieldRecentsTitleMenuItemTag]; // makes it go away if there are no recents.
	[cellMenu insertItem:item4 atIndex:curIndex++];
	[item4 release];
	item4 = [[NSMenuItem alloc] initWithTitle:@"Search Fields" action:nil keyEquivalent:@""];
	[cellMenu insertItem:item4 atIndex:curIndex++];
	[item4 release];
	
	item4 = [[NSMenuItem alloc] initWithTitle:@"Add Field ..." action:@selector(quickSearchAddField:) keyEquivalent:@""];
	[cellMenu insertItem:item4 atIndex:curIndex++];
	[item4 release];
	
	item4 = [[NSMenuItem alloc] initWithTitle:@"Remove Field ..." action:@selector(quickSearchRemoveField:) keyEquivalent:@""];
	[cellMenu insertItem:item4 atIndex:curIndex++];
	[item4 release];
	
	[cellMenu insertItem:[NSMenuItem separatorItem] atIndex:curIndex++];
	
	item4 = [[NSMenuItem alloc] initWithTitle:@"All Fields" action:@selector(searchFieldChangeKey:) keyEquivalent:@""];
	[cellMenu insertItem:item4 atIndex:curIndex++];
	[item4 release];
	
	item4 = [[NSMenuItem alloc] initWithTitle:@"Title" action:@selector(searchFieldChangeKey:) keyEquivalent:@""];
	[cellMenu insertItem:item4 atIndex:curIndex++];
	[item4 release];
	
	item4 = [[NSMenuItem alloc] initWithTitle:@"Author" action:@selector(searchFieldChangeKey:) keyEquivalent:@""];
	[cellMenu insertItem:item4 atIndex:curIndex++];
	[item4 release];
	
	item4 = [[NSMenuItem alloc] initWithTitle:@"Date" action:@selector(searchFieldChangeKey:) keyEquivalent:@""];
	[cellMenu insertItem:item4 atIndex:curIndex++];
	[item4 release];
	
	NSArray *prefsQuickSearchKeysArray = [[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKQuickSearchKeys];
    NSString *aKey = nil;
    NSEnumerator *quickSearchKeyE = [prefsQuickSearchKeysArray objectEnumerator];
	
    while(aKey = [quickSearchKeyE nextObject]){
		
		anItem = [[NSMenuItem alloc] initWithTitle:aKey 
											action:@selector(searchFieldChangeKey:)
									 keyEquivalent:@""]; 
		[cellMenu insertItem:anItem atIndex:curIndex++];
		[anItem release];
    }
	
	return cellMenu;
}

- (void)setupSearchField{
	// called in awakeFromNib
	    quickSearchTextDict = [[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKCurrentQuickSearchTextDict] mutableCopy];
	id searchCellOrTextField = nil;
	

	if (BDSK_USING_JAGUAR) {
		/* On a 10.2 - 10.2.x system */
		//@@ backwards Compatibility -, and set up the button
		searchCellOrTextField = searchFieldTextField;
		
		NSArray *prefsQuickSearchKeysArray = [[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKQuickSearchKeys];
		
		NSString *aKey = nil;
		NSEnumerator *quickSearchKeyE = [prefsQuickSearchKeysArray objectEnumerator];

		while(aKey = [quickSearchKeyE nextObject]){
			[quickSearchButton insertItemWithTitle:aKey
										   atIndex:0];
		}
		
		[quickSearchClearButton setEnabled:NO];
		[quickSearchClearButton setToolTip:NSLocalizedString(@"Clear the Quicksearch Field",@"")];
		
	} else {
		searchField = (id) [[NSSearchField alloc] initWithFrame:[[searchFieldBox contentView] frame]];

		[searchFieldBox setContentView:searchField];
				
		searchCellOrTextField = [searchField cell];
		[searchCellOrTextField setSendsWholeSearchString:NO]; // don't wait for Enter key press.
		[searchCellOrTextField setSearchMenuTemplate:[self searchFieldMenu]];
		[searchCellOrTextField setPlaceholderString:[NSString stringWithFormat:@"Search by %@",quickSearchKey]];
		[searchCellOrTextField setRecentsAutosaveName:[NSString stringWithFormat:@"%@ recent searches autosave ",[self fileName]]];
		
		[searchField setDelegate:self];
		[searchField setAction:@selector(searchFieldAction:)];
		
		// fit into tab key loop - doesn't work yet
/*		[actionMenuButton setNextKeyView:searchField];
		[searchField setNextKeyView:tableView]; 
		*/
	}
	
	if(quickSearchTextDict){
/*		if([quickSearchTextDict objectForKey:quickSearchKey]){
			[searchCellOrTextField setStringValue:
				[quickSearchTextDict objectForKey:quickSearchKey]];
			if(BDSK_USING_JAGUAR){
				[quickSearchClearButton setEnabled:YES];
			}
		}else{
			[searchCellOrTextField setStringValue:@""];
		}
*/		
	}else{
		quickSearchTextDict = [[NSMutableDictionary dictionaryWithCapacity:4] retain];
	}
	
	// [self setSelectedSearchFieldKey:quickSearchKey];
	
}

- (IBAction)searchFieldChangeKey:(id)sender{
	if([sender isKindOfClass:[NSPopUpButton class]]){
		[self setSelectedSearchFieldKey:[sender titleOfSelectedItem]];
	}else{
		[self setSelectedSearchFieldKey:[sender title]];
	}
}

- (void)setSelectedSearchFieldKey:(NSString *)newKey{

	id searchCellOrTextField = nil;
	
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:newKey
                                                      forKey:BDSKCurrentQuickSearchKey];
	
	if(BDSK_USING_JAGUAR){
		searchCellOrTextField = searchFieldTextField;
	}else{
		
		NSSearchFieldCell *searchCell = [searchField cell];
		searchCellOrTextField = searchCell;	
		[searchCell setPlaceholderString:[NSString stringWithFormat:@"Search by %@",newKey]];
		
		[searchField setNextKeyView:tableView];
		[tableView setNextKeyView:searchField];
	
		NSMenu *templateMenu = [searchCell searchMenuTemplate];
		if(![quickSearchKey isEqualToString:newKey]){
			// find current key's menuitem and set it to NSOffState
			NSMenuItem *oldItem = [templateMenu itemWithTitle:quickSearchKey];
			[oldItem setState:NSOffState];	
		}
		
		// set new key's menuitem to NSOnState
		NSMenuItem *newItem = [templateMenu itemWithTitle:newKey];
		[newItem setState:NSOnState];
		[searchCell setSearchMenuTemplate:templateMenu];
		
		if(newKey != quickSearchKey){
			
			
			[newKey retain];
			[quickSearchKey release];
			quickSearchKey = newKey;
		}
		
	}

	/*
	NSString *newQueryString = [quickSearchTextDict objectForKey:newKey];
    if(newQueryString){
        [searchCellOrTextField setStringValue:newQueryString];
    }else{
        [searchCellOrTextField setStringValue:@""];
		newQueryString = @"";
    }
	 */
 
	// NSLog(@"in setSelectedSearchFieldKey, newQueryString is [%@]", newQueryString);
	[self hidePublicationsWithoutSubstring:[searchCellOrTextField stringValue] //newQueryString
								   inField:quickSearchKey];
		
}

- (IBAction)quickSearchAddField:(id)sender{
    [addFieldPrompt setStringValue:NSLocalizedString(@"Name of field to search:",@"")];
    [NSApp beginSheet:addFieldSheet
       modalForWindow:documentWindow
        modalDelegate:self
       didEndSelector:@selector(quickSearchAddFieldSheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
}

- (void)quickSearchAddFieldSheetDidEnd:(NSWindow *)sheet
							returnCode:(int) returnCode
						   contextInfo:(void *)contextInfo{
	
    NSMutableArray *prefsQuickSearchKeysMutableArray = nil;
	NSSearchFieldCell *searchFieldCell = [searchField cell];
	NSMenu *searchFieldMenuTemplate = [searchFieldCell searchMenuTemplate];
	NSMenuItem *menuItem = nil;
	NSString *newFieldTitle = nil;
	
    if(returnCode == 1){
		newFieldTitle = [addFieldTextField stringValue];
		
        [self setSelectedSearchFieldKey:newFieldTitle];
		
        prefsQuickSearchKeysMutableArray = [[[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKQuickSearchKeys] mutableCopy] autorelease];
		
        if(!prefsQuickSearchKeysMutableArray){
            prefsQuickSearchKeysMutableArray = [NSMutableArray arrayWithCapacity:1];
        }
        [prefsQuickSearchKeysMutableArray addObject:newFieldTitle];
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:prefsQuickSearchKeysMutableArray
                                                          forKey:BDSKQuickSearchKeys];
		
		menuItem = [[NSMenuItem alloc] initWithTitle:newFieldTitle action:@selector(searchFieldChangeKey:) keyEquivalent:@""];
		[searchFieldMenuTemplate insertItem:menuItem atIndex:10];
		[menuItem release];
		[searchFieldCell setSearchMenuTemplate:searchFieldMenuTemplate];
		[self setSelectedSearchFieldKey:newFieldTitle];
    }else{
        // cancel. we don't have to do anything..?
		
    }
}

- (IBAction)quickSearchRemoveField:(id)sender{
    [delFieldPrompt setStringValue:NSLocalizedString(@"Name of search field to remove:",@"")];
	NSMutableArray *prefsQuickSearchKeysMutableArray = [[[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKQuickSearchKeys] mutableCopy] autorelease];
	
	if(!prefsQuickSearchKeysMutableArray){
		prefsQuickSearchKeysMutableArray = [NSMutableArray arrayWithCapacity:1];
	}
	[delFieldPopupButton removeAllItems];
	
	[delFieldPopupButton addItemsWithTitles:prefsQuickSearchKeysMutableArray];
	
	[NSApp beginSheet:delFieldSheet
       modalForWindow:documentWindow
        modalDelegate:self
       didEndSelector:@selector(quickSearchDelFieldSheetDidEnd:returnCode:contextInfo:)
          contextInfo:prefsQuickSearchKeysMutableArray];
}

- (IBAction)dismissDelFieldSheet:(id)sender{
    [delFieldSheet orderOut:sender];
    [NSApp endSheet:delFieldSheet returnCode:[sender tag]];
}

- (void)quickSearchDelFieldSheetDidEnd:(NSWindow *)sheet
							returnCode:(int) returnCode
						   contextInfo:(void *)contextInfo{
   
    NSMutableArray *prefsQuickSearchKeysMutableArray = (NSMutableArray *)contextInfo;
	NSSearchFieldCell *searchFieldCell = [searchField cell];
	NSMenu *searchFieldMenuTemplate = [searchFieldCell searchMenuTemplate];
	// NSMenuItem *menuItem = nil;
	NSString *delFieldTitle = nil;

    if(returnCode == 1){
		delFieldTitle = [[delFieldPopupButton selectedItem] title];
		
		// if we were using that key, select another?

        prefsQuickSearchKeysMutableArray = [[[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKQuickSearchKeys] mutableCopy] autorelease];

        if(!prefsQuickSearchKeysMutableArray){
            prefsQuickSearchKeysMutableArray = [NSMutableArray arrayWithCapacity:1];
        }
        [prefsQuickSearchKeysMutableArray removeObject:delFieldTitle];
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:prefsQuickSearchKeysMutableArray
                                                          forKey:BDSKQuickSearchKeys];

		int itemIndex = [searchFieldMenuTemplate indexOfItemWithTitle:delFieldTitle];
		[searchFieldMenuTemplate removeItemAtIndex:itemIndex];

		[searchFieldCell setSearchMenuTemplate:searchFieldMenuTemplate];
		[self setSelectedSearchFieldKey:NSLocalizedString(@"All Fields",@"")];
    }else{
        // cancel. we don't have to do anything..?
       
    }
}

- (IBAction)clearQuickSearch:(id)sender{
    [searchFieldTextField setStringValue:@""];
	[self searchFieldAction:searchFieldTextField];
	[quickSearchClearButton setEnabled:NO];
}

- (void)controlTextDidChange:(NSNotification *)notif{
	if([notif object] == searchFieldTextField){
		if([[searchFieldTextField stringValue] isEqualToString:@""]){
			[quickSearchClearButton setEnabled:NO];
		}else{
			[quickSearchClearButton setEnabled:YES];
		}
		[self searchFieldAction:searchFieldTextField];
	}
}

- (IBAction)searchFieldAction:(id)sender{
    if([sender stringValue] != nil){
	[self hidePublicationsWithoutSubstring:[sender stringValue] inField:quickSearchKey];
    }
}

- (void)hidePublicationsWithoutSubstring:(NSString *)substring inField:(NSString *)field{
    
    if([substring isEqualToString:@""]){
        [shownPublications setArray:publications];
        [self updateUI];
        return;
    }
    
    NSString *selectorString = [[[NSString alloc] init] autorelease];
    BOOL isGeneric = NO;
    
    if([field isEqualToString:@"Title"]){
        selectorString=@"title";
    } else {
        if([field isEqualToString:@"Author"]){
            selectorString=@"bibtexAuthorString";
        } else {
            if([field isEqualToString:@"Date"]){
                selectorString=@"calendarDateDescription";
            } else {
                if([field isEqualToString:@"All Fields"]){
                    selectorString=@"allFieldsString";
                } else {
                    if([field isEqualToString:@"Pub Type"]){
                        selectorString=@"type";
                    } else {
                        if([field caseInsensitiveCompare:@"Cite Key"] == NSOrderedSame ||
                           [field caseInsensitiveCompare:@"CiteKey"] == NSOrderedSame ||
                           [field caseInsensitiveCompare:@"Cite-Key"] == NSOrderedSame ||
                           [field caseInsensitiveCompare:@"Key"] == NSOrderedSame){
                            selectorString=@"citeKey";
                        } else {
                            isGeneric = YES; // this means that we don't have an accessor for it in BibItem
                        }
                    }
                }
            }
        }
    }
        
    AGRegex *tip = [AGRegex regexWithPattern:@"(?(?=^.+(AND|OR))(^.+(?= AND| OR))|^.+)"]; // match the any words up to but not including AND or OR if they exist (see "Lookahead assertions" and "CONDITIONAL SUBPATTERNS" in pcre docs)
    AGRegex *andRegex = [AGRegex regexWithPattern:@"AND \\b[^ ]+"]; // match the word following an AND
    NSArray *matchArray = [andRegex findAllInString:substring]; // an array of AGRegexMatch objects
    NSMutableArray *andArray = [NSMutableArray array]; // and array of all the AND terms we're looking for
    
    // get the tip of the search string first (always an AND)
    [andArray addObject:[[tip findInString:substring] group]];

    NSEnumerator *e = [matchArray objectEnumerator];
    AGRegexMatch *m;

    while(m = [e nextObject]){ // get the resulting string from the match, and strip the AND from it; there might be a better way, but this works
        [andArray addObject:[[[m group] componentsSeparatedByString:@"AND "] objectAtIndex:1]];
    }
    // NSLog(@"andArray is %@", [andArray description]);
    
    AGRegex *orRegex = [AGRegex regexWithPattern:@"OR \\b([^ ]+)"]; // match the first word following an OR
    NSMutableArray *orArray = [NSMutableArray array]; // an array of all the OR terms we're looking for
    
    matchArray = [orRegex findAllInString:substring];
    e = [matchArray objectEnumerator];
    
    while(m = [e nextObject]){ // now get all of the OR strings and strip the OR from them
        [orArray addObject:[[[m group] componentsSeparatedByString:@"OR "] objectAtIndex:1]];
    }    
    
    NSMutableSet *aSet = [NSMutableSet setWithCapacity:10];
    NSEnumerator *andEnum = [andArray objectEnumerator];
    NSEnumerator *orEnum = [orArray objectEnumerator];
    NSRange r;
    NSString *componentSubstring = nil;
    BibItem *pub = nil;
    NSEnumerator *pubEnum;
    NSMutableArray *andResultsArray = [NSMutableArray array];
    NSString *accessorResult;
    
    // for each AND term, enumerate the entire publications array and search for a match; if we get a match, add it to a mutable set
    if(isGeneric){ // use the -[BibItem valueOfField:] method to get the substring we want to search in, if it's not a "standard" one
        NSString *value = nil;
        while(componentSubstring = [andEnum nextObject]){ // strip the accents from the search string, and from the string we get from BibItem
            componentSubstring = [[[NSString alloc] initWithData:[componentSubstring dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] 
                                                        encoding:NSASCIIStringEncoding] autorelease];
            pubEnum = [publications objectEnumerator];
            while(pub = [pubEnum nextObject]){
                value = [pub valueOfField:quickSearchKey];
                if(!value){
                    r.location = NSNotFound;
                } else {
                    value = [[[NSString alloc] initWithData:[value dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] 
                                                   encoding:NSASCIIStringEncoding] autorelease];
                    r = [value rangeOfString:componentSubstring
                                     options:NSCaseInsensitiveSearch];
                }
                if(r.location != NSNotFound){
                    // NSLog(@"Found %@ in %@", substring, [pub citeKey]);
                    [aSet addObject:pub];
                }
            }
            [andResultsArray addObject:[[aSet copy] autorelease]];
            [aSet removeAllObjects]; // don't forget this step!
        }
    } else { // if it was a substring that has an accessor in BibItem, use that directly
        while(componentSubstring = [andEnum nextObject]){
            componentSubstring = [[[NSString alloc] initWithData:[componentSubstring dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] 
                                                        encoding:NSASCIIStringEncoding] autorelease];
            pubEnum = [publications objectEnumerator];
            while(pub = [pubEnum nextObject]){
                accessorResult = [pub performSelector:NSSelectorFromString(selectorString) withObject:nil];
                accessorResult = [[[NSString alloc] initWithData:[accessorResult dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] 
                                                        encoding:NSASCIIStringEncoding] autorelease];
                r = [accessorResult rangeOfString:componentSubstring
                                          options:NSCaseInsensitiveSearch];
                if(r.location != NSNotFound){
                    // NSLog(@"Found %@ in %@", substring, [pub citeKey]);
                    [aSet addObject:pub];
                }
            }
            [andResultsArray addObject:[[aSet copy] autorelease]];
            [aSet removeAllObjects]; // don't forget this step!
        }
    }

    // Get all of the OR matches, each in a separate set added to orResultsArray
    NSMutableArray *orResultsArray = [NSMutableArray array];
    
    if(isGeneric){ // use the -[BibItem valueOfField:] method to get the substring we want to search in, if it's not a "standard" one
        while(componentSubstring = [orEnum nextObject]){
            componentSubstring = [[[NSString alloc] initWithData:[componentSubstring dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] 
                                                        encoding:NSASCIIStringEncoding] autorelease];
            NSString *value = nil;
            pubEnum = [publications objectEnumerator];
            while(pub = [pubEnum nextObject]){
                value = [pub valueOfField:quickSearchKey];
                if(!value){
                    r.location = NSNotFound;
                } else {
                    value = [[[NSString alloc] initWithData:[value dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] 
                                                   encoding:NSASCIIStringEncoding] autorelease];
                    r = [value rangeOfString:componentSubstring
                                     options:NSCaseInsensitiveSearch];
                }
                if(r.location != NSNotFound){
                    // NSLog(@"Found %@ in %@", substring, [pub citeKey]);
                    [aSet addObject:pub];
                }
            }
            [orResultsArray addObject:[[aSet copy] autorelease]];
            [aSet removeAllObjects]; // don't forget this step!
        }
    } else { // if it was a substring that has an accessor in BibItem, use that directly
        while(componentSubstring = [orEnum nextObject]){
            componentSubstring = [[[NSString alloc] initWithData:[componentSubstring dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] 
                                                        encoding:NSASCIIStringEncoding] autorelease];        
            pubEnum = [publications objectEnumerator];
            while(pub = [pubEnum nextObject]){
                accessorResult = [pub performSelector:NSSelectorFromString(selectorString) withObject:nil];
                accessorResult = [[[NSString alloc] initWithData:[accessorResult dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] 
                                                        encoding:NSASCIIStringEncoding] autorelease];
                r = [accessorResult rangeOfString:componentSubstring
                                          options:NSCaseInsensitiveSearch];
                if(r.location != NSNotFound){
                    [aSet addObject:pub];
                }
            }
            [orResultsArray addObject:[[aSet copy] autorelease]];
            [aSet removeAllObjects];
        }
    }
        
    NSMutableSet *newSet = [NSMutableSet setWithCapacity:10];
    NSSet *tmpSet;

    // we need to sort the set so we always start with the shortest one
    [andResultsArray sortUsingFunction:compareSetLengths context:nil];
    
    // don't start out by intersecting an empty set
    [newSet setSet:[andResultsArray objectAtIndex:0]];
    // NSLog(@"newSet count is %i", [newSet count]);
    // NSLog(@"nextSet count is %i", [[andResultsArray objectAtIndex:1] count]);
    
    // get the intersection of all of the results from the AND terms
    e = [andResultsArray objectEnumerator];
    while(tmpSet = [e nextObject]){
        [newSet intersectSet:tmpSet];
    }
    
    // union the results from the OR search; use the newSet, so we don't have to worry about duplicates
    e = [orResultsArray objectEnumerator];
    
    while(tmpSet = [e nextObject]){
        [newSet unionSet:tmpSet];
    }
        
    NSArray *foundArray = [[[newSet copy] autorelease] allObjects];
    
    [shownPublications setArray:foundArray];

    [quickSearchTextDict setObject:substring
                            forKey:field];
    
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:[[quickSearchTextDict copy] autorelease]
                                                      forKey:BDSKCurrentQuickSearchTextDict];
    [[OFPreferenceWrapper sharedPreferenceWrapper] autoSynchronize];
    
    [self updateUI]; // calls reloadData
    if([shownPublications count] == 1)
        [tableView selectAll:self];
    
}

int compareSetLengths(NSSet *set1, NSSet *set2, void *context){
    NSNumber *n1 = [NSNumber numberWithInt:[set1 count]];
    NSNumber *n2 = [NSNumber numberWithInt:[set2 count]];
    return [n1 compare:n2];
}

#pragma mark -

- (void)updatePreviews:(NSNotification *)aNotification{
    NSNumber *i;
    NSMutableString *bibString = [NSMutableString stringWithString:@""];
    NSEnumerator *e = [self selectedPubEnumerator];
	
	[previewField setString:@""];
	if([self numberOfSelectedPubs] == 0){
		//   [editPubButton setEnabled:NO];
		//  [delPubButton setEnabled:NO];
	}else{
		// [editPubButton setEnabled:YES];
		// [delPubButton setEnabled:YES];
		//take care of the preview field
		[self displayPreviewForItems:[self selectedPubEnumerator]];
		// (don't just pass it 'e' - it needs its own enum.)
		
		while(i = [e nextObject]){
			[bibString appendString:[[shownPublications objectAtIndex:[i intValue]] bibTeXString]];
		}// while i is num of selected row
		
		if([[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKUsesTeXKey] == NSOnState){
			[NSThread
                detachNewThreadSelector:@selector(PDFFromString:)
                               toTarget:PDFpreviewer
                             withObject:bibString];
		}else{
			// do nothing for now... (later, tell it to nullify the view?)
		}
	}// else more than 0 selected rows
	
}


// replaces sortPubsByColumn
- (void) tableView: (NSTableView *) theTableView
didClickTableColumn: (NSTableColumn *) tableColumn{
	// check whether this is the right kind of table view and don't re-sort when we have a contextual menu click
    if (tableView != (BDSKDragTableView *) theTableView || 	[[NSApp currentEvent] type] == NSRightMouseDown
) return;
    
    BibItem *selection = nil;
    int sortedRow; // see the datasource methods for this; it's tricky
    
    if([tableView selectedRow] != -1){
        sortedRow = (sortDescending ? [shownPublications count] - 1 - [tableView selectedRow] : [tableView selectedRow]);
        selection = [shownPublications objectAtIndex:sortedRow];
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

	NSString *tcID = [tableColumn identifier];
	// resorting should happen whenever you click.
	if([tcID caseInsensitiveCompare:@"Cite Key"] == NSOrderedSame ||
       [tcID caseInsensitiveCompare:@"CiteKey"] == NSOrderedSame ||
       [tcID caseInsensitiveCompare:@"Cite-Key"] == NSOrderedSame ||
       [tcID caseInsensitiveCompare:@"Key"]== NSOrderedSame){
		
		[publications sortUsingSelector:@selector(keyCompare:)];
		[shownPublications sortUsingSelector:@selector(keyCompare:)];
	}else if([tcID isEqualToString:@"Title"]){
		
		[publications sortUsingSelector:@selector(titleCompare:)];
		[shownPublications sortUsingSelector:@selector(titleCompare:)];
	}else if([tcID isEqualToString:@"Date"]){
		
		[publications sortUsingSelector:@selector(dateCompare:)];
		[shownPublications sortUsingSelector:@selector(dateCompare:)];
	}else if([tcID isEqualToString:@"1st Author"]){
		
		[publications sortUsingSelector:@selector(auth1Compare:)];
		[shownPublications sortUsingSelector:@selector(auth1Compare:)];
	}else if([tcID isEqualToString:@"2nd Author"]){
		
		[publications sortUsingSelector:@selector(auth2Compare:)];
		[shownPublications sortUsingSelector:@selector(auth2Compare:)];
	}else if([tcID isEqualToString:@"3rd Author"]){
		
		[publications sortUsingSelector:@selector(auth3Compare:)];
		[shownPublications sortUsingSelector:@selector(auth3Compare:)];
	}else if([tcID isEqualToString:@"Type"]){
		[publications sortUsingSelector:@selector(pubTypeCompare:)];
		[shownPublications sortUsingSelector:@selector(pubTypeCompare:)];
	}else{
		[publications sortUsingFunction:generalBibItemCompareFunc context:[tableColumn identifier]];
		[shownPublications sortUsingFunction:generalBibItemCompareFunc context:[tableColumn identifier]];
	}
	
	

    // Set the graphic for the new column header
    [tableView setIndicatorImage: (sortDescending ?
                                   [NSImage imageNamed:@"sort-down"] :
                                   [NSImage imageNamed:@"sort-up"])
                   inTableColumn: tableColumn];

    [tableView reloadData];
    
    if(selection != nil){
        // NSLog(@"selection later is %@", [selection title]);
        sortedRow = (sortDescending ? [shownPublications count] - 1 - [shownPublications indexOfObjectIdenticalTo:selection] : [shownPublications indexOfObjectIdenticalTo:selection]);
        [tableView selectRow:sortedRow byExtendingSelection:NO];
        [tableView scrollRowToVisible:sortedRow];
    }
}


int generalBibItemCompareFunc(id item1, id item2, void *context){
	NSString *tableColumnName = (NSString *)context;

	NSString *keyPath = [NSString stringWithFormat:@"pubFields.%@", tableColumnName];
	NSString *value1 = (NSString *)[item1 valueForKeyPath:keyPath];
	NSString *value2 = (NSString *)[item2 valueForKeyPath:keyPath];
	if (value1 == nil || value2 == nil) NSLog(@"a value is nil!");
	// @@sort-fix: how do we handle nil values, which may now occur?
	return [value1 compare:value2];
}


- (IBAction)emailPubCmd:(id)sender{
    NSEnumerator *e = [self selectedPubEnumerator];
    NSNumber *i;
    BibItem *pub = nil;
    NSFileWrapper *fw = nil;
    NSTextAttachment *att = nil;
    NSFileManager *dfm = [NSFileManager defaultManager];
    NSString *docPath = [[self fileName] stringByDeletingLastPathComponent];
    NSString *pubPath = nil;
    NSMutableAttributedString *body = [[NSMutableAttributedString alloc] init];
    NSMutableArray *files = [NSMutableArray array];
    //    BOOL sent = NO;

    // other way:
    NSPasteboard *pb = [NSPasteboard pasteboardWithName:@"BDMailPasteboard"];
    NSArray *types = [NSArray arrayWithObjects:NSFilenamesPboardType,nil];
        //NSRTFDPboardType,nil];
    [pb declareTypes:types owner:self];
    
    while (i = [e nextObject]) {
        pub = [shownPublications objectAtIndex:[i intValue]];
        pubPath = [pub localURLPathRelativeTo:docPath];
       
        if([dfm fileExistsAtPath:pubPath]){
            [files addObject:pubPath];
            fw = [[NSFileWrapper alloc] initWithPath:pubPath];
            att = [[NSTextAttachment alloc] initWithFileWrapper:fw];

            [body appendAttributedString:[NSAttributedString attributedStringWithAttachment:att]];
            [fw release]; [att release];
        }
    }


    /* This doesn't seem to work:
        [pb setData:[body RTFDFromRange:NSMakeRange(0,[body length]) documentAttributes:nil]
            forType:NSRTFDPboardType];*/

    [pb setPropertyList:files forType:NSFilenamesPboardType];

    NSPerformService(@"Mail/Send File",pb); // Note: only works with Mail.app.
    
    //sent = [NSMailDelivery deliverMessage:body
    //                             headers: headers
     //                             format: NSMIMEMailFormat
     //                           protocol: nil];

    //if(!sent){
   //     [NSException raise:@"UnimplementedException" format:@"Can't handle errors in mail sending yet."];
   // }

    [body release];
}


- (IBAction)editPubCmd:(id)sender{
    NSString *colID = nil;
    BibItem *pub = nil;
    int row = [tableView selectedRow];// was : [tableView clickedRow];
    int sortedRow = (sortDescending ? [shownPublications count] - 1 - row : row);


    if([tableView clickedColumn] != -1){
	colID = [[[tableView tableColumns] objectAtIndex:[tableView clickedColumn]] identifier];
    }else{
	colID = @"";
    }
    if([colID isEqualToString:@"Local-Url"]){
        pub = [shownPublications objectAtIndex:sortedRow];
        [[NSWorkspace sharedWorkspace] openFile:[pub localURLPathRelativeTo:[[self fileName] stringByDeletingLastPathComponent]]];
    }else if([colID isEqualToString:@"Url"]){
        pub = [shownPublications objectAtIndex:sortedRow];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[pub valueOfField:@"Url"]]];
        // @@ http-adding: change valueOfField to [pub url] and have it auto-add http://
    }else{
		int n = [self numberOfSelectedPubs];
		if ( n > 6) {
		// Do we really want a gazillion of editor windows?
			NSBeginAlertSheet(NSLocalizedString(@"Edit publications", @"Edit publications (multiple open warning)"), NSLocalizedString(@"Cancel", @"Cancel"), NSLocalizedString(@"Open", @"multiple open warning Open button"), nil, documentWindow, self, @selector(multipleEditSheetDidEnd:returnCode:contextInfo:), NULL, nil, NSLocalizedString(@"Bibdesk is about to open %i editor windows. Do you want to proceed?" , @"mulitple open warning question"), n);
		}
		else {
			[self multipleEditSheetDidEnd:nil returnCode:NSAlertAlternateReturn contextInfo:nil];
		}
	}
}

-(void) multipleEditSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	NSEnumerator *e = [self selectedPubEnumerator];
	NSNumber * i;
	
	if (returnCode == NSAlertAlternateReturn ) {
		// the user said to go ahead
		while (i = [e nextObject]) {
			[self editPub:[shownPublications objectAtIndex:[i intValue]]];
		}
	}
	// otherwise do nothing
}

//@@ notifications - when adding pub notifications is fully implemented we won't need this.
- (void)editPub:(BibItem *)pub{
    BibEditor *e = [pub editorObj];
    if(e == nil){
        e = [[[BibEditor alloc] initWithBibItem:pub document:self] autorelease];
        [self addWindowController:e];
    }
    [e show];
}

- (IBAction)copy:(id)sender{
    OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
    if([[sud objectForKey:BDSKDragCopyKey] intValue] == 0){
        [self copyAsBibTex:self];
    }else if([[sud objectForKey:BDSKDragCopyKey] intValue] == 1){
        [self copyAsTex:self];
    }else if([[sud objectForKey:BDSKDragCopyKey] intValue] == 2){
        [self copyAsPDF:self];
    }else if([[sud objectForKey:BDSKDragCopyKey] intValue] == 3){
        [self copyAsRTF:self];
    }
}

- (IBAction)copyAsBibTex:(id)sender{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    NSEnumerator *e = [self selectedPubEnumerator];
    NSMutableString *s = [[NSMutableString string] retain];
    NSNumber *i;
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    while(i=[e nextObject]){
	    [s appendString:@"\n"];
        [s appendString:[[shownPublications objectAtIndex:[i intValue]] bibTeXString]];
		[s appendString:@"\n"];
    }
    [pasteboard setString:s forType:NSStringPboardType];
}    

- (IBAction)copyAsTex:(id)sender{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];

    [pasteboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, BDSKBibTeXStringPboardType, nil] owner:nil];
    [pasteboard setString:[self citeStringForSelection] forType:NSStringPboardType];
    
    NSEnumerator *e = [self selectedPubEnumerator];
    NSMutableString *s = [[NSMutableString string] retain];
    NSNumber *i;
    while(i=[e nextObject]){
        [s appendString:[[shownPublications objectAtIndex:[i intValue]] bibTeXString]];
    }
    [pasteboard setString:s forType:BDSKBibTeXStringPboardType];
    
}


-(NSString*) citeStringForSelection{
	OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
	NSString *startCiteBracket = [sud stringForKey:BDSKCiteStartBracketKey]; 
	NSString *citeString = [sud stringForKey:BDSKCiteStringKey];
    NSMutableString *s = [NSMutableString stringWithFormat:@"\\%@%@", citeString, startCiteBracket];
	NSString *endCiteBracket = [sud stringForKey:BDSKCiteEndBracketKey]; 
	
    NSEnumerator *e = [self selectedPubEnumerator];
    NSNumber *i;
    BOOL sep = ([sud integerForKey:BDSKSeparateCiteKey] == NSOnState);
    
    while(i=[e nextObject]){
        [s appendString:[[shownPublications objectAtIndex:[i intValue]] citeKey]];
        if(sep)
            [s appendString:[NSString stringWithFormat:@"%@ \\%@%@", endCiteBracket, citeString, startCiteBracket]];
        else
            [s appendString:@","];
    }
    if(sep)
        [s replaceCharactersInRange:[s rangeOfString:[NSString stringWithFormat:@"%@ \\%@%@", endCiteBracket, citeString, startCiteBracket]
											 options:NSBackwardsSearch] withString:endCiteBracket];
    else
        [s replaceCharactersInRange:[s rangeOfString:@"," options:NSBackwardsSearch] withString:endCiteBracket];
	
	
	return s;
}



- (IBAction)copyAsPDF:(id)sender{
    NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    NSData *d;
    NSNumber *i;
    NSEnumerator *e = [self selectedPubEnumerator];
    NSMutableString *bibString = [NSMutableString string];

    [pb declareTypes:[NSArray arrayWithObject:NSPDFPboardType] owner:nil];
    while(i = [e nextObject]){
        [bibString appendString:[[shownPublications objectAtIndex:[i intValue]] bibTeXString]];
    }
    [pb setString:bibString forType:BDSKBibTeXStringPboardType];
    d = [PDFpreviewer PDFDataFromString:bibString];
    [pb setData:d forType:NSPDFPboardType];
}

- (IBAction)copyAsRTF:(id)sender{
    NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    NSData *d;
    NSNumber *i;
    NSEnumerator *e = [self selectedPubEnumerator];
    NSMutableString *bibString = [NSMutableString string];
    
    [pb declareTypes:[NSArray arrayWithObject:NSRTFPboardType] owner:nil];
    while(i = [e nextObject]){
        [bibString appendString:[[shownPublications objectAtIndex:[i intValue]] bibTeXString]];
    }
    [pb setString:bibString forType:BDSKBibTeXStringPboardType];
    [PDFpreviewer PDFFromString:bibString];
    d = [PDFpreviewer rtfDataPreview];
    [pb setData:d forType:NSRTFPboardType];
    
}


#pragma mark Paste

// ----------------------------------------------------------------------------------------
// paste: get text, parse it as bibtex, add the entry to publications and (optionally) edit it.
// ----------------------------------------------------------------------------------------


/* ssp: 2004-07-19
*/ 
- (IBAction)paste:(id)sender{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
	NSString * error;

	if (![self addPublicationsFromPasteboard:pasteboard error:&error]) {
			// an error occured
		//Display error message or simply Beep?
		NSBeep();
	}
}



- (void)createNewBlankPub{
    [self createNewBlankPubAndEdit:NO];
}

- (void)createNewBlankPubAndEdit:(BOOL)yn{
    OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
    BibItem *newBI = [[[BibItem alloc] init] autorelease];

    [newBI setFileOrder:fileOrderCount];
	
	NSString *nowStr = [[NSCalendarDate date] description];
	NSDictionary *dictWithDates = [NSDictionary dictionaryWithObjectsAndKeys:nowStr, BDSKDateCreatedString, nowStr, BDSKDateModifiedString, nil];
	[newBI setPubFields:dictWithDates];	
	
    fileOrderCount++;
    [self addPublication:newBI];
	[[self undoManager] setActionName:NSLocalizedString(@"Add Publication",@"")];
    [self updateUI];
    if(yn == YES)
    {
        [self editPub:newBI];
    }
}


/* ssp: 2004-07-18
An attempt to unify the adding of BibItems from the pasteboard
This takes the structural code from the original drag and drop handling code and breaks out the parts for handling file and text pasteboards.
As an experiment, we also try to pass errors back.
Would it be advisable to also give access to the newly added records?
*/
- (BOOL) addPublicationsFromPasteboard:(NSPasteboard*) pb error:(NSString**) error{
    NSArray * types = [pb types];
    
    // check for the NSStringPboardType first, so if it's a clipping with BibTeX we just get the text out of it, and explicitly check for our local BibTeX type
    if([types containsObject:NSStringPboardType] && ![types containsObject:BDSKBibTeXStringPboardType]){
        NSData * pbData = [pb dataForType:NSStringPboardType]; 	
        NSString * str = [[[NSString alloc] initWithData:pbData encoding:NSUTF8StringEncoding] autorelease];
        return [self addPublicationsForString:str error:error];
    } else {
        if([types containsObject:BDSKBibTeXStringPboardType]){
            NSString *str = [pb stringForType:BDSKBibTeXStringPboardType];
            return [self addPublicationsForString:str error:error];
        } else {
            if([pb containsFiles]) {
                NSArray * pbArray = [pb propertyListForType:NSFilenamesPboardType]; // we will get an array
                return [self addPublicationsForFiles:pbArray error:error];
            } else {
                *error = NSLocalizedString(@"didn't find anything appropriate on the pasteboard", @"Bibdesk couldn't find any files or bibliography information in the data it received.");
                return NO;
            }
        }
    }
}


/* ssp: 2004-07-19
'TeXify' the string, convert to data and insert then.
Taken from original -paste: method
Originally, drag and drop and services didn't seem to 'TeXify'
I hope this is the right thing to do.
There may be a bit too much conversion Data->String->Data going on.
*/
- (BOOL) addPublicationsForString:(NSString*) string error:(NSString**) error {
	NSString * TeXifiedString = [[BDSKConverter sharedConverter] stringByTeXifyingString:string];
	NSData * data = [TeXifiedString dataUsingEncoding:NSUTF8StringEncoding];

	return [self addPublicationsForData:data error:error];
}


/* ssp: 2004-07-18
Broken out of  original drag and drop handling
Runs the data it receives through BiBTeXParser and add the BibItems it receives.
Error handling is quasi-nonexistant. 
We don't even have the error handling that used to exist in the -paste: method yet. Did that actually help?
Shouldn't there be some kind of safeguard against opening too many pub editors?
*/
- (BOOL) addPublicationsForData:(NSData*) data error:(NSString**) error {
	BOOL hadProblems = NO;
	NSArray * newPubs = [BibTeXParser itemsFromData:data error:&hadProblems];

	if(hadProblems) {
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
			
		}else if (rv == NSAlertAlternateReturn){
			// the user said to keep going, so if they save, they might clobber data...
		}else if(rv == NSAlertOtherReturn){
			// they said to edit the file.
			NSString * tempFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
			[data writeToFile:tempFileName atomically:YES];
			[[NSApp delegate] openEditWindowWithFile:tempFileName];
			[[NSApp delegate] showErrorPanel:self];			
		}		
	}

	if ([newPubs count] == 0) {
		*error = NSLocalizedString(@"couldn't analyse string", @"Bibdesk couldn't find bibliography data in the text it received.");
		return NO;
	}
	
	
	NSEnumerator * newPubE = [newPubs objectEnumerator];
	BibItem * newBI = nil;

	while(newBI = [newPubE nextObject]){		
		[self addPublication:newBI];
			
		[self updateUI];
		
		if([[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKEditOnPasteKey] == NSOnState) {
			[self editPub:newBI];
		}
	}
	[[self undoManager] setActionName:NSLocalizedString(@"Add Publication",@"")];
	return YES;
}




/* ssp: 2004-07-18
Broken out of  original drag and drop handling
Takes an array of file paths and adds them to the document if possible.
This method always returns YES. Even if some or many operations fail.
*/
- (BOOL) addPublicationsForFiles:(NSArray*) filenames error:(NSString**) error {
	OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];

	NSEnumerator * fileNameEnum = [filenames objectEnumerator];
	NSString * fnStr = nil;
	NSURL * url = nil;
	
	while(fnStr = [fileNameEnum nextObject]){
		if(url = [NSURL fileURLWithPath:fnStr]){
			BibItem * newBI = [[BibItem alloc] initWithType:[pw stringForKey:BDSKPubTypeStringKey]
										 fileType:@"BibTeX"
										  authors:[NSMutableArray arrayWithCapacity:0]];
			
			NSString *newUrl = [[NSURL fileURLWithPath:
				[fnStr stringByExpandingTildeInPath]]absoluteString];
			
			[newBI setField:@"Local-Url" toValue:newUrl];	
			
			if([pw boolForKey:BDSKFilePapersAutomaticallyKey]){
				[[BibFiler sharedFiler] file:YES papers:[NSArray arrayWithObject:newBI]
								fromDocument:self];
			}
			
			[self addPublication:[newBI autorelease]];
			
			[self updateUI];
			
			if([pw integerForKey:BDSKEditOnPasteKey] == NSOnState){
				[self editPub:newBI];
				//[[newBI editorObj] fixEditedStatus];  - deprecated
			}
		}
	}
	if ([filenames count] > 0) {
		[[self undoManager] setActionName:NSLocalizedString(@"Add Publication",@"")];
	}
	return YES;
}





- (void)handleUpdateUINotification:(NSNotification *)notification{
    [self updateUI];
}


- (void)updateUI{
    [self setTableFont];
	[tableView reloadData];

	int shownPubsCount = [shownPublications count];
	int totalPubsCount = [publications count];
	
	if (shownPubsCount != totalPubsCount) { 
		// inform people
		[infoLine setStringValue: [NSString stringWithFormat:
			NSLocalizedString(@"%d of %d Publications",
                          @"need two ints in format string."),
            shownPubsCount,totalPubsCount] ];
	}
	else {
		[infoLine setStringValue:[NSString stringWithFormat:
			NSLocalizedString(@"%d Publications",
							  @"%d Publications (total number)"),
            totalPubsCount]];
	}
	
    [self updatePreviews:nil];
    [self updateActionMenu:nil];
}


//note - ********** the notification handling method will add NSTableColumn instances to the tableColumns dictionary.
- (void)setupTableColumns{
    NSArray *prefsShownColNamesArray = [[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKShownColsNamesKey];
    NSEnumerator *shownColNamesE = [prefsShownColNamesArray objectEnumerator];
    NSTableColumn *tc;
    NSString *colName;

    NSDictionary *tcWidthsByIdentifier = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKColumnWidthsKey];
    NSNumber *tcWidth = nil;
    NSImageCell *imageCell = [[[NSImageCell alloc] init] autorelease];

    [tableView removeAllTableColumns];
    
    while(colName = [shownColNamesE nextObject]){
        tc = [tableColumns objectForKey:colName];
        if(tcWidthsByIdentifier){
            tcWidth = [tcWidthsByIdentifier objectForKey:[tc identifier]];
            if(tcWidth){
                [tc setWidth:[tcWidth floatValue]];
            }
        }
		if([colName isEqualToString:@"Local-Url"]){
			NSImage * pdfImage = [NSImage imageNamed:@"TinyFile"];
			[[tc headerCell] setImage:pdfImage];
		}else{	
			[[tc headerCell] setStringValue:NSLocalizedStringFromTable(colName, @"BibTeXKeys", @"")];
		}
        [tc setEditable:NO];

        if([[tc identifier] isEqualToString:@"No Identifier"]){
            // don't add the 'no ident' tc to either....
            // THIS IS A HACK.
            // I should probably set it up better in the nib, or something.
        }else{
            [tableView addTableColumn:tc];
            if([[tc identifier] isEqualToString:@"Local-Url"] ||
               [[tc identifier] isEqualToString:@"Url"]){
                [tc setDataCell:imageCell];
                
            }
            if(![[tc identifier] isEqualToString:@"Title"]){
                [self contextualMenuAddTableColumnName:[tc identifier] enabled:YES];
                // OK to add multiple times.
            }
        }
    }
}

- (IBAction)dismissAddFieldSheet:(id)sender{
    [addFieldSheet orderOut:sender];
    [NSApp endSheet:addFieldSheet returnCode:[sender tag]];
}

- (NSMenu *)menuForTableColumn:(NSTableColumn *)tc row:(int)row{
	// for now, just returns the same all the time.
	// Could customize menu for details of selected item.
	return contextualMenu;
}


#define ADD_MENUITEM_TAG 47
- (void)contextualMenuAddTableColumnName:(NSString *)name enabled:(BOOL)yn{
    NSMenuItem *item = nil;
    if ([contextualMenu indexOfItemWithTitle:name] == -1) {
        item = [[[NSMenuItem alloc] initWithTitle:name 
                                           action:@selector(contextualMenuSelectTableColumn:)
                                    keyEquivalent:@""] autorelease];
        [contextualMenu insertItem:item atIndex:[contextualMenu indexOfItemWithTag:ADD_MENUITEM_TAG]]; // put it before the add other menu item.
        if (yn) {
            [item setState:NSOnState];
        }else{
            [item setState:NSOffState];
        }
    }

}

- (IBAction)contextualMenuSelectTableColumn:(id)sender{
    [self contextualMenuSelectTableColumn:sender post:YES];
}

- (void)contextualMenuSelectTableColumn:(id)sender post:(BOOL)yn{
    NSTableColumn *tc = nil;
    NSMutableArray *prefsShownColNamesMutableArray = [[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKShownColsNamesKey] mutableCopy];

    if ([sender state] == NSOnState) {
        [tableColumns removeObjectForKey:[sender title]];
        [prefsShownColNamesMutableArray removeObject:[sender title]];
        [sender setState:NSOffState];
    }else{
        tc = [[[NSTableColumn alloc] initWithIdentifier:[sender title]] autorelease];
        [tc setResizable:YES];
        [tableColumns setObject:tc forKey:[tc identifier]];
        if(![prefsShownColNamesMutableArray containsObject:[tc identifier]]){
            [prefsShownColNamesMutableArray addObject:[tc identifier]];
        }
        [sender setState:NSOnState];
    }
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:prefsShownColNamesMutableArray
                                                      forKey:BDSKShownColsNamesKey];
    [self setupTableColumns];
    [self updateUI];
    if(yn){
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKTableColumnChangedNotification
                                                            object:[sender title]
                                                          userInfo:
            [NSDictionary dictionaryWithObjectsAndKeys:self, @"Sender", nil]];
    }
}

- (IBAction)contextualMenuAddTableColumn:(id)sender{
    // get the name, then call contextualMenuAddTableColumnName: enabled: to add it for you
    [addFieldPrompt setStringValue:NSLocalizedString(@"Name of column to add:",@"")];
    [NSApp beginSheet:addFieldSheet
       modalForWindow:documentWindow
        modalDelegate:self
       didEndSelector:@selector(addTableColumnSheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
    
}

- (void)addTableColumnSheetDidEnd:(NSWindow *)sheet
                       returnCode:(int) returnCode
                      contextInfo:(void *)contextInfo{
    NSTableColumn *tc = nil;
    NSMutableArray *prefsShownColNamesMutableArray = nil;

    if(returnCode == 1){
        [self contextualMenuAddTableColumnName:[addFieldTextField stringValue] enabled:YES];
        tc = [[[NSTableColumn alloc] initWithIdentifier:[addFieldTextField stringValue]] autorelease];
        [tc setResizable:YES];
        [tableColumns setObject:tc forKey:[tc identifier]];
        prefsShownColNamesMutableArray = [[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKShownColsNamesKey] mutableCopy];
        [prefsShownColNamesMutableArray addObject:[tc identifier]];
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:prefsShownColNamesMutableArray
                                                          forKey:BDSKShownColsNamesKey];
        [self setupTableColumns];
        [self updateUI];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKTableColumnChangedNotification
                                                            object:[tc identifier]
                                                          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self, @"Sender", nil]];
    }else{
        //do nothing
    }
}






/*
 Returns action/contextual menu that contains items appropriate for the current selection.
 The code may need to be revised if the menu's contents are changed.
*/
- (NSMenu*) menuForSelection {
	NSMenu * myMenu = [[actionMenu copy] autorelease];
	
	// kick out every item we won't need:
	NSEnumerator * itemEnum = [[myMenu itemArray] objectEnumerator];
	NSMenuItem * theItem = nil;
	
	while (theItem = (NSMenuItem*) [itemEnum nextObject]) {
		if (![self validateMenuItem:theItem]) {
			[myMenu removeItem:theItem];
		}
	}
	
	int n = [myMenu numberOfItems] -1;
	
	if ([[myMenu itemAtIndex:n] isSeparatorItem]) {
		// last item is separator => remove
		[myMenu removeItemAtIndex:n];
	}	
	return myMenu;
}







- (void)handleTableColumnChangedNotification:(NSNotification *)notification{
    id menuItem = nil;
    NSString *colName = [notification object];

    // don't pay attention to notifications I send (infinite loop might result)
    if([[notification userInfo] objectForKey:@"Sender"] == self){
        return;
    }
    
    if (nil == [tableColumns objectForKey:colName]) {
        [self contextualMenuAddTableColumnName:colName enabled:NO];
    }
    menuItem = [contextualMenu itemWithTitle:colName];
    [self contextualMenuSelectTableColumn:menuItem post:NO]; 
}

- (void)handleBibItemChangedNotification:(NSNotification *)notification{
	// dead simple for now
	// NSLog(@"got handleBibItemChangedNotification with userinfo %@", [notification userInfo]);
	NSDictionary *userInfo = [notification userInfo];
	
	NSString *changedKey = [userInfo objectForKey:@"key"];
    
    [self refreshAuthors];
    
	if(!changedKey){
		[tableView  reloadData];
		return;
	}
		
	if([quickSearchKey isEqualToString:changedKey] || 
	   [quickSearchKey isEqualToString:@"All Fields"]){
		if(BDSK_USING_JAGUAR){
			[self searchFieldAction:searchFieldTextField];
		}else{
			[NSObject cancelPreviousPerformRequestsWithTarget:self
								 selector:@selector(searchFieldAction:)
								   object:searchField];
			[self performSelector:@selector(searchFieldAction:)
				   withObject:searchField
				   afterDelay:0.5];

		}
	}
	// should: also check if we're filtering by the key that was changed and refilter.
	// should: need to save the highlighted pub and rehighlight after sort...
	
}

- (void)displayPreviewForItems:(NSEnumerator *)enumerator{
    NSNumber *i;
    NSDictionary *titleAttributes = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:1], nil]
                                                                forKeys:[NSArray arrayWithObjects:NSUnderlineStyleAttributeName,  nil]];
    NSMutableAttributedString *s;
    
    [previewField setString:@""];

    while(i = [enumerator nextObject]){

        switch([[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKPreviewDisplayKey]){
            case 0:
                [previewField replaceCharactersInRange: [previewField selectedRange]
                                               withRTF:[[shownPublications objectAtIndex:[i intValue]] RTFValue]];
                break;
            case 1:
                // special handling for annote-only
                // Write out the title
                if([self numberOfSelectedPubs] > 1){
                    s = [[[NSMutableAttributedString alloc] initWithString:[[shownPublications objectAtIndex:[i intValue]] title]
                                                         attributes:titleAttributes] autorelease];
                    [s appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n\n"
                                                                                  attributes:nil] autorelease]];
                    [previewField replaceCharactersInRange: [previewField selectedRange] withRTF:
                        [s RTFFromRange:NSMakeRange(0, [s length]) documentAttributes:nil]];
                }

                if([[[shownPublications objectAtIndex:[i intValue]] valueOfField:@"Annote"] isEqualToString:@""]){
                    [previewField replaceCharactersInRange: [previewField selectedRange] withString:NSLocalizedString(@"No notes.",@"")];
                }else{
                    [previewField replaceCharactersInRange: [previewField selectedRange] withString: [[shownPublications objectAtIndex:[i intValue]] valueOfField:@"Annote"]];
                }
                break;
        }

        [previewField replaceCharactersInRange: [previewField selectedRange] withString:@"\n\n"];
    }
}

- (void)handlePreviewDisplayChangedNotification:(NSNotification *)notification{
    [self displayPreviewForItems:[self selectedPubEnumerator]];
}

- (void)handleCustomStringsChangedNotification:(NSNotification *)notification{
    [customStringArray setArray:[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKCustomCiteStringsKey]];
    [ccTableView reloadData];
}

- (void)handleFontChangedNotification:(NSNotification *)notification{
	[self setTableFont];
}

- (void)setTableFont{
    // The font we're using now
    NSFont *font = [NSFont fontWithName:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKTableViewFontKey]
                                   size:
        [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKTableViewFontSizeKey]];
	
	[tableView setRowHeight:[font defaultLineHeightForFont]+2];
	[tableView setFont:font];
	[tableView tile];
}

- (void)highlightBib:(BibItem *)bib{
    [self highlightBib:bib byExtendingSelection:NO];
}

- (void)highlightBib:(BibItem *)bib byExtendingSelection:(BOOL)yn{
 
    int i = [shownPublications indexOfObjectIdenticalTo:bib];
    i = (sortDescending ? [shownPublications count] - 1 - i : i);
    

    if(i != NSNotFound && i != -1){
        [tableView selectRow:i byExtendingSelection:yn];
        [tableView scrollRowToVisible:i];
    }
}

#pragma mark
#pragma mark || Custom cite drawer stuff

- (IBAction)openCustomCitePrefPane:(id)sender{
    OAPreferenceController *pc = [OAPreferenceController sharedPreferenceController];
    [pc showPreferencesPanel:nil];
    [pc setCurrentClientByClassName:@"BibPref_Cite"];
}

- (IBAction)toggleShowingCustomCiteDrawer:(id)sender{
    [customCiteDrawer toggle:sender];
	if(showingCustomCiteDrawer){
		showingCustomCiteDrawer = NO;
	}else{
		showingCustomCiteDrawer = YES;
	}
}



- (int)numberOfSelectedPubs{
    return [[[self selectedPubEnumerator] allObjects] count];
}


- (NSEnumerator *)selectedPubEnumerator{
    id item = nil;
    NSEnumerator *itemsE = nil;
    NSMutableArray *itemIndexes = [NSMutableArray arrayWithCapacity:10];
    
	// selectedRowEnum has to check sortDescending.. : ->
	if(sortDescending){
		int count = [shownPublications count];
		itemsE = [tableView selectedRowEnumerator];
		while(item = [itemsE nextObject]){
			[itemIndexes addObject:[NSNumber numberWithInt:(count-[item intValue]- 1)]];
		}
		return [itemIndexes objectEnumerator];
	}else{
		return [tableView selectedRowEnumerator];
	}
    
}

- (void)windowWillClose:(NSNotification *)notification{
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocumentWindowWillCloseNotification
														object:self
													  userInfo:[NSDictionary dictionary]];

    [customCiteDrawer close];
    [[NSApp delegate] removeErrorObjsForFileName:[self fileName]];

}

- (void)windowDidBecomeMain:(NSNotification *)notification{
    // handle the update at initial file load
    [self updateUI];
}

- (void)splitViewDoubleClick:(OASplitView *)sender{
    [NSException raise:@"UnimplementedException" format:@"splitview %@ was clicked.", sender];
}

#pragma mark
#pragma mark Printing support

- (NSView *)printableView{
	return previewField; // random hack for now. - this will only print the selected items.
}


/* ssp: 2004-07-19
Basic printing of the preview
Along with new menu validation code in the main file.
Requires improved version of BDSKPreviewer class with accessor function
The results are quite crappy, but these were low-hanging fruit and people seem to want the feature.
*/
- (void) printDocument:(id)sender {
	[[[BDSKPreviewer sharedPreviewer] pdfView] print:sender];
}


- (void)printShowingPrintPanel:(BOOL)showPanels {
    // Obtain a custom view that will be printed
    NSView *printView = [self printableView];
	
    // Construct the print operation and setup Print panel
    NSPrintOperation *op = [NSPrintOperation
                printOperationWithView:printView
							 printInfo:[self printInfo]];
    [op setShowPanels:showPanels];
    if (showPanels) {
        // Add accessory view, if needed
    }
	
    // Run operation, which shows the Print panel if showPanels was YES
    // [self runModalPrintOperation:op						delegate:nil				  didRunSelector:NULL					 contextInfo:NULL];
	[op runOperationModalForWindow:documentWindow delegate:nil didRunSelector:NULL contextInfo:NULL];
}

#pragma mark 
#pragma mark AutoFile stuff
- (IBAction)consolidateLinkedFiles:(id)sender{
	[[BibFiler sharedFiler] showPreviewForPapers:[self publications] fromDocument:self];
}

#pragma mark blog stuff


- (IBAction)postItemToWeblog:(id)sender{
//	NSEnumerator *pubE = [self selectedPubEnumerator];
//	BibItem *pub = [pubE nextObject];

	[NSException raise:@"unimplementedFunctionException"
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

@end
