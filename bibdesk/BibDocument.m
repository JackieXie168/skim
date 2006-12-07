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
#import "BDSKDragOutlineView.h"


#include <stdio.h>
char * InputFilename; // This is here because the btparse library can't live without it.

NSString*   LocalDragPasteboardName = @"edu.ucsd.cs.mmccrack.bibdesk: Local Publication Drag Pasteboard";


#import "btparse.h"

@implementation BibDocument

- (id)init{
    if(self = [super init]){
        publications = [[NSMutableArray alloc] initWithCapacity:1];
        shownPublications = [[NSMutableArray alloc] initWithCapacity:1];
        fieldsSortDict = [[NSMutableDictionary alloc] init];
        frontMatter = [[NSMutableString alloc] initWithString:@""];

        quickSearchKey = [[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKCurrentQuickSearchKey] retain];
        if(!quickSearchKey){
            quickSearchKey = [[NSString alloc] initWithString:@"Title"];
        }
        PDFpreviewer = [BDSKPreviewer sharedPreviewer];
        showColsArray = [[NSMutableArray arrayWithObjects:
            [NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],nil] retain];
        localDragPboard = [NSPasteboard pasteboardWithName:LocalDragPasteboardName];
        tableColumns = [[NSMutableDictionary dictionaryWithCapacity:6] retain];
        bibEditors = [[NSMutableArray alloc] initWithCapacity:1];
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
     currentSortField = [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKViewByKey];
     [self setupSortDict];
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
        tc = [[NSTableColumn alloc] initWithIdentifier:tcName];
        [tc setResizable:YES];

        [tableColumns setObject:tc forKey:[tc identifier]];
    }
    
    //if(viewByKey)[sortKeyButton selectItemWithTitle:viewByKey];
    // the button is by default set to "Title" - this makes sure we retain the views.
    [tableBox retain]; [outlineBox retain];
    [self didChangeSortKey:sortKeyButton];

    [tableView setDoubleAction:@selector(editPubCmd:)];
    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, NSFilenamesPboardType, nil]];
    [outlineView setDoubleAction:@selector(editPubCmd:)];
    // [outlineView registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, NSFilenamesPboardType, nil]];

    [tableView setMenu:contextualMenu];
    [outlineView setMenu:contextualMenu];
    
    [splitView setPositionAutosaveName:[self fileName]];
    
    // 1:I'm using this as a catch-all.
    // 2:this gets called lots of other places, no need to. [self updateUI]; 

    // workaround for IB flakiness...
    drawerSize = [customCiteDrawer contentSize];
    [customCiteDrawer setContentSize:NSMakeSize(100,drawerSize.height)];

    // finally, make sure the font is correct initially:
    [self handleFontChangedNotification:nil];
}

- (void)dealloc{
#if DEBUG
    //NSLog(@"bibdoc dealloc");
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [publications release]; // these should cause the bibitems to get dealloc'ed
    [shownPublications release];
    [bibEditors release]; // gets rid of all the bibeditors.
    [fieldsSortDict release];
    [frontMatter release];
    [quickSearchTextDict release];
    [quickSearchKey release];
    [showColsArray release];
    [customStringArray release];
    [toolbarItems release];
    [super dealloc];
}

- (void)setPublications:(NSMutableArray *)newPubs{
	if(newPubs != publications){
		[publications autorelease];
		publications = [newPubs mutableCopy];
    }
}

- (NSMutableArray *) publications{
    return [[publications retain] autorelease];
}

- (void)addPublication:(BibItem *)pub{
	[self addPublication:pub lastRequest:YES];
}

- (void)addPublication:(BibItem *)pub lastRequest:(BOOL)last{
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removePublication:pub];
	[undoManager setActionName:NSLocalizedString(@"Add Publication",@"")];
	
	[publications addObject:pub];
	[shownPublications addObject:pub];

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
	[undoManager setActionName:NSLocalizedString(@"Delete Publication",@"")];
	
	BibEditor *editor = [pub editorObj];
	if(editor){
		[editor close];
		[bibEditors removeObjectIdenticalTo:editor];
	}
	[publications removeObjectIdenticalTo:pub];
	[shownPublications removeObjectIdenticalTo:pub];
	
	NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:pub, @"pub",
		(last ? @"YES" : @"NO"), @"lastRequest", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocDelItemNotification
														object:self
													  userInfo:notifInfo];	
}

- (void)handleBibItemAddDelNotification:(NSNotification *)notification{
	NSDictionary *userInfo = [notification userInfo];
	BibItem *pub = [userInfo objectForKey:@"pub"];
	BOOL wasLastRequest = [[userInfo objectForKey:@"lastRequest"] isEqualToString:@"YES"];

	if(wasLastRequest){
	//	NSLog(@"was last request in handleBibItemAddDel");
		// This method should also check the publication to see if it's selected?
		// and maybe also resort it... - maybe not resort this. 
		[self updateUI];
	}
}


- (void)setupSortDict{
    // Sub for allAuthors
    [fieldsSortDict setObject:[NSMutableArray array]
                       forKey:@"Author"];
}

- (NSArray *)currentSortFieldArray{
    // in the future, this should build the array on demand.
    return [fieldsSortDict objectForKey:currentSortField];
}

// should become part of above method, when we start allowing sorting by keys other than author.
- (void)refreshAuthors{
    NSMutableArray *authors = [fieldsSortDict objectForKey:@"Author"];
    NSEnumerator *pubE = [shownPublications objectEnumerator];
    NSEnumerator *authE;
    BibAuthor *auth;
    NSArray *authArray;
    NSMutableArray *tmpTotalAuths = [NSMutableArray arrayWithCapacity:6];
    BibItem *pub;
    BibAuthor *bibAuthor = nil;
    unsigned i;

    [tmpTotalAuths  setArray:authors];

    while (pub = [pubE nextObject]) {
        // for each pub, get its authors
        authArray = [pub pubAuthors];
        authE = [authArray objectEnumerator];
        while(auth = [authE nextObject]){
            // for each author auth, set i to be the index of auth in the temp. array.
            i = [tmpTotalAuths indexOfObject:auth];
            if(i == NSNotFound){
                bibAuthor = [[[BibAuthor alloc] initWithName:[auth name] andPub:pub] autorelease];
                [authors addObject:bibAuthor];
                [tmpTotalAuths addObject:auth];
            }else{
                [[authors objectAtIndex:i] addPub:pub];
            }
        }
    }
    
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

- (NSString *)windowNibName
{
    return @"BibDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    [self setupToolbar];
    [[aController window] setFrameAutosaveName:[self displayName]];
    [documentWindow makeFirstResponder:[self currentView]];	
    [self setupTableColumns]; // calling it here mostly just makes sure that the menu is set up.
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification{
    ////NSLog(@"win did become main");
    [self updateUI]; // mostly because the BDSKPreviewer is a singleton class.
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
    [self saveDependentWindows];//@@bibeditor transparency - won't need this.
    
    if ([aType isEqualToString:@"bibTeX database"]){
        return [self bibDataRepresentation];
    }else if ([aType isEqualToString:@"Rich Site Summary file"]){
        return [self rssDataRepresentation];
    }else if ([aType isEqualToString:@"HTML"]){
        return [self htmlDataRepresentation];
    }else 
		return nil;
}

- (void)saveDependentWindows{
    NSMutableArray *depWins = [NSMutableArray array];
    NSEnumerator *pubE = [publications objectEnumerator]; 
    BibItem *pub;

    // make sure all bibitems have saved their changes.
    while(pub = [pubE nextObject]){
        if([pub editorObj]){
            [depWins addObject:[pub editorObj]];
        }
    }
    [depWins makeObjectsPerformSelector:@selector(finalizeChanges)];
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
      [d appendData:[[BDSKConverter stringByTeXifyingString:[tmp RSSValue]] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
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
    
    if(!filePath){
        filePath = @"Untitled Document";
    }
    dictionary = [NSMutableDictionary dictionaryWithCapacity:10];
    
    publications = [[PubMedParser itemsFromString:dataString
                                         error:&hadProblems
                                   frontMatter:frontMatter
                                      filePath:filePath] retain]; 
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
            // note this by setting the update count:
            [self updateChangeCount:NSChangeDone];
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

    if(!filePath){
        filePath = @"Untitled Document";
    }
    dictionary = [NSMutableDictionary dictionaryWithCapacity:10];

    // to enable some cheapo timing, uncomment these:
    //    NSDate *start = [NSDate date];
    //    NSLog(@"start: %@", start);
    publications = [[BibTeXParser itemsFromData:data
                                           error:&hadProblems
                                     frontMatter:frontMatter
                                        filePath:filePath] retain]; 

    // NSLog(@"end %@ elapsed: %f", [NSDate date], [start timeIntervalSinceNow]);
    
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
            // note this by setting the update count:
            [self updateChangeCount:NSChangeDone];
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
    return YES;
}


- (IBAction)newPub:(id)sender{
    [self createNewBlankPubAndEdit:YES];
}

- (IBAction)delPub:(id)sender{
    NSEnumerator *delEnum = nil;
    NSNumber *rowToDelete;
    id objToDelete; 
	int numSelectedPubs = [self numberOfSelectedPubs];
	int numDeletedPubs = 0;
    int rv = 0;
	
    if (numSelectedPubs == 0) {
        return;
    }
    rv = NSRunCriticalAlertPanel(NSLocalizedString(@"Publication delete",@""),
                                 NSLocalizedString(@"Are you sure you want to delete?",@""),
                                 NSLocalizedString(@"Delete",@""),
                                 NSLocalizedString(@"Cancel",@""), nil, nil, nil);
    if (rv == NSAlertDefaultReturn) {
        //the user said to delete.
        delEnum = [self selectedPubEnumerator];
        while (rowToDelete = [delEnum nextObject]) {
            objToDelete = [shownPublications objectAtIndex:[rowToDelete intValue]];
			numDeletedPubs++;
			if(numDeletedPubs == numSelectedPubs){
				[self removePublication:objToDelete lastRequest:YES];
			}else{
				[self removePublication:objToDelete lastRequest:NO];
			}
        }
        [[self currentView] deselectAll:nil];
        [self updateUI];
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
	NSMenu *cellMenu = [[NSMenu alloc] initWithTitle:@"Search Menu"];
	NSMenuItem *item1, *item2, *item3, *item4, *anItem;
	
	item1 = [[NSMenuItem alloc] initWithTitle:@"Recent Searches" action: @selector(limitOne:) keyEquivalent:@""];
	[item1 setTag:NSSearchFieldRecentsTitleMenuItemTag];
	[cellMenu insertItem:item1 atIndex:0];
	[item1 release];
	item2 = [[NSMenuItem alloc] initWithTitle:@"Recents" action:@selector(limitTwo:) keyEquivalent:@""];
	[item2 setTag:NSSearchFieldRecentsMenuItemTag];
	[cellMenu insertItem:item2 atIndex:1];
	[item2 release];
	item3 = [[NSMenuItem alloc] initWithTitle:@"Clear" action:@selector(limitThree:) keyEquivalent:@""];
	[item3 setTag:NSSearchFieldClearRecentsMenuItemTag];
	[cellMenu insertItem:item3 atIndex:2];
	[item3 release];
	// my stuff:
	item4 = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
	[item4 setTag:NSSearchFieldRecentsTitleMenuItemTag]; // makes it go away if there are no recents.
	[cellMenu insertItem:item4 atIndex:3];
	[item4 release];
	item4 = [[NSMenuItem alloc] initWithTitle:@"Search Fields" action:nil keyEquivalent:@""];
	[cellMenu insertItem:item4 atIndex:4];
	[item4 release];
	
	item4 = [[NSMenuItem alloc] initWithTitle:@"Add Field ..." action:@selector(quickSearchAddField:) keyEquivalent:@""];
	[cellMenu insertItem:item4 atIndex:5];
	[item4 release];
	
	item4 = [[NSMenuItem alloc] initWithTitle:@"All Fields" action:@selector(searchFieldChangeKey:) keyEquivalent:@""];
	[cellMenu insertItem:item4 atIndex:6];
	[item4 release];
	
	item4 = [[NSMenuItem alloc] initWithTitle:@"Title" action:@selector(searchFieldChangeKey:) keyEquivalent:@""];
	[cellMenu insertItem:item4 atIndex:7];
	[item4 release];
	
	item4 = [[NSMenuItem alloc] initWithTitle:@"Author" action:@selector(searchFieldChangeKey:) keyEquivalent:@""];
	[cellMenu insertItem:item4 atIndex:8];
	[item4 release];
	
	item4 = [[NSMenuItem alloc] initWithTitle:@"Date" action:@selector(searchFieldChangeKey:) keyEquivalent:@""];
	[cellMenu insertItem:item4 atIndex:9];
	[item4 release];
	
	NSArray *prefsQuickSearchKeysArray = [[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKQuickSearchKeys];
    NSString *aKey = nil;
    NSEnumerator *quickSearchKeyE = [prefsQuickSearchKeysArray objectEnumerator];
	
    while(aKey = [quickSearchKeyE nextObject]){
		
		anItem = [[NSMenuItem alloc] initWithTitle:aKey 
											action:@selector(searchFieldChangeKey:)
									 keyEquivalent:@""]; 
		[cellMenu insertItem:anItem atIndex:10];
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
	}
	
	if(quickSearchTextDict){
		if([quickSearchTextDict objectForKey:quickSearchKey]){
			[searchCellOrTextField setStringValue:
				[quickSearchTextDict objectForKey:quickSearchKey]];
			if(BDSK_USING_JAGUAR){
				[quickSearchClearButton setEnabled:YES];
			}
		}else{
			[searchCellOrTextField setStringValue:@""];
		}
	}else{
		quickSearchTextDict = [[NSMutableDictionary dictionaryWithCapacity:4] retain];
	}
	
	[self setSelectedSearchFieldKey:quickSearchKey];
	
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
		[searchField setNextKeyView:[self currentView]];
		[[self currentView] setNextKeyView:searchField];
	
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
	
	NSString *newQueryString = [quickSearchTextDict objectForKey:newKey];
    if(newQueryString){
        [searchCellOrTextField setStringValue:newQueryString];
    }else{
        [searchCellOrTextField setStringValue:@""];
		newQueryString = @"";
    }
 
	// NSLog(@"in setSelectedSearchFieldKey, newQueryString is [%@]", newQueryString);
	[self hidePublicationsWithoutSubstring:newQueryString
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
	[self hidePublicationsWithoutSubstring:[sender stringValue] inField:quickSearchKey];
}

- (void)hidePublicationsWithoutSubstring:(NSString *)substring inField:(NSString *)field{
    NSMutableArray *remArray = [NSMutableArray arrayWithCapacity:1];
    NSEnumerator *e = [publications objectEnumerator];
    BibItem *pub;

    NSRange r;
	
    [[self currentView] deselectAll:self];
	
	// NSLog(@"looking for [%@] in [%@]",substring, field);
    
    if(![substring isEqualToString:@""]){
        while(pub = [e nextObject]){
            if ([field isEqualToString:@"Title"]){
                r = [[pub title]  rangeOfString:substring
                                        options:NSCaseInsensitiveSearch];
			}else if ([field isEqualToString:@"Author"]){
                r = [[pub bibtexAuthorString]  rangeOfString:substring
                                               options:NSCaseInsensitiveSearch];
			}else if ([field isEqualToString:@"Date"]){
				NSCalendarDate *pubDate = [pub date];
				if(pubDate){
					r = [[pubDate descriptionWithCalendarFormat:@"%B %Y"] rangeOfString:substring
																				options:NSCaseInsensitiveSearch];
				}else{
					r = [@"No Date" rangeOfString:substring
										  options:NSCaseInsensitiveSearch];
					// if there's no good date, we use "no date" because that's what we display.
				}
            }else if([field isEqualToString:@"All Fields"]){
                r = [[pub allFieldsString] rangeOfString:substring
                                                 options:NSCaseInsensitiveSearch];
				
            }else if([field isEqualToString:@"Pub Type"]){
                r = [[pub type] rangeOfString:substring
                                      options:NSCaseInsensitiveSearch];
            }else if([field isEqualToString:@"Cite Key"]){
				NSString *pubCiteKey = [pub citeKey];
				r = [pubCiteKey rangeOfString:substring
									  options:NSCaseInsensitiveSearch];
			}else{
				NSString *value = [pub valueOfField:quickSearchKey];
				if(!value)
					r.location = NSNotFound;
				else
					r = [value rangeOfString:substring options:NSCaseInsensitiveSearch];
            }
			
            if(r.location == NSNotFound) [remArray addObject:pub];
        }
    }else{
		// do nothing
    }
    [shownPublications setArray:publications];
    [shownPublications removeObjectsInArray:remArray];
	
    [quickSearchTextDict setObject:substring
                            forKey:field];
	
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:[[quickSearchTextDict copy] autorelease]
                                                      forKey:BDSKCurrentQuickSearchTextDict];
    [[OFPreferenceWrapper sharedPreferenceWrapper] autoSynchronize];
	
    [self updateUIAndRefreshOutline:YES]; // calls reloadData
    if([shownPublications count] == 1)
        [[self currentView] selectAll:self];
}


#pragma mark -

- (void)updatePreviews:(NSNotification *)aNotification{
    NSNumber *i;
    NSMutableString *bibString = [NSMutableString stringWithString:@""];
    NSEnumerator *e = [self selectedPubEnumerator];

    if(((NSTableView *)[self currentView] == tableView) ||
       ((NSTableView *)[self currentView] == (NSTableView *)outlineView)){
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
    }else{
        // the selection changed on the citestring tableview and we don't care.
    }

}

// Fixme - this is not correct memory management.
- (IBAction)didChangeSortKey:(id)sender{
    NSView *newView = nil;
    NSView *prevView = nil;
    NSString *sortKey = [sender titleOfSelectedItem];
    
    if([sortKey isEqualToString: @"Author"]){
        newView = (NSView *) outlineBox;
        prevView  = (NSView *) tableBox;
    }else if([sortKey isEqualToString: @"Title"]){
        newView = (NSView *) tableBox;
        prevView = (NSView *) outlineBox;
    }
    
    if([dummyView contentView] != (NSView *) newView){
/*        NSLog(@"rcs: tv: %d olv: %d", [tableBox retainCount], [outlineBox retainCount]);
        NSLog(@"csk: %@ ", sortKey);*/

        [dummyView setContentView:newView];
       
        [self setupTableColumns];
        [self updateUIAndRefreshOutline:YES];
    }
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:currentSortField forKey:BDSKViewByKey];
}

// replaces sortPubsByColumn
- (void) tableView: (NSTableView *) theTableView
didClickTableColumn: (NSTableColumn *) tableColumn{
    if (tableView != (BDSKDragTableView *) theTableView) return;
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
	// resorting should happen whenever you click.
	if([[tableColumn identifier] isEqualToString:@"Cite Key"]){
		
		[publications sortUsingSelector:@selector(keyCompare:)];
		[shownPublications sortUsingSelector:@selector(keyCompare:)];
	}else if([[tableColumn identifier] isEqualToString:@"Title"]){
		
		[publications sortUsingSelector:@selector(titleCompare:)];
		[shownPublications sortUsingSelector:@selector(titleCompare:)];
	}else if([[tableColumn identifier] isEqualToString:@"Date"]){
		
		[publications sortUsingSelector:@selector(dateCompare:)];
		[shownPublications sortUsingSelector:@selector(dateCompare:)];
	}else if([[tableColumn identifier] isEqualToString:@"1st Author"]){
		
		[publications sortUsingSelector:@selector(auth1Compare:)];
		[shownPublications sortUsingSelector:@selector(auth1Compare:)];
	}else if([[tableColumn identifier] isEqualToString:@"2nd Author"]){
		
		[publications sortUsingSelector:@selector(auth2Compare:)];
		[shownPublications sortUsingSelector:@selector(auth2Compare:)];
	}else if([[tableColumn identifier] isEqualToString:@"3rd Author"]){
		
		[publications sortUsingSelector:@selector(auth3Compare:)];
		[shownPublications sortUsingSelector:@selector(auth3Compare:)];
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
}


int generalBibItemCompareFunc(id item1, id item2, void *context){
	NSString *tableColumnName = (NSString *)context;

	NSString *keyPath = [NSString stringWithFormat:@"pubFields.%@", tableColumnName];
	NSString *value1 = (NSString *)[item1 valueForKeyPath:keyPath];
	NSString *value2 = (NSString *)[item2 valueForKeyPath:keyPath];
	if (value1 == nil || value2 == nil) NSLog(@"a value is nil!");
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
    NSEnumerator *e = [self selectedPubEnumerator];
    NSNumber *i;
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
        while (i = [e nextObject]) {
            [self editPub:[shownPublications objectAtIndex:[i intValue]]];
        }
    }
}

- (void)editPub:(BibItem *)pub{
    [self editPub:pub forceChange:NO];
}

//@@ notifications - when adding pub notifications is fully implemented we won't need this.
- (void)editPub:(BibItem *)pub forceChange:(BOOL)force{
    BibEditor *e = [pub editorObj];
    if(e == nil){
        e = [[BibEditor alloc] initWithBibItem:pub document:self];

		[bibEditors addObject:[e autorelease]];// we need to keep track of the bibeditors
    }
    [e show];    //    [e showWindow:self];
    if(force){
#if DEBUG
        //NSLog(@"updating change count");
#endif
        [self updateChangeCount:NSChangeDone]; // used to be 'e' updateChangeCount.
    }
}

- (IBAction)copy:(id)sender{
    OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
    if([[sud objectForKey:BDSKDragCopyKey] intValue] == 0){
        [self copyAsBibTex:self];
    }else if([[sud objectForKey:BDSKDragCopyKey] intValue] == 1){
        [self copyAsTex:self];
    }else if([[sud objectForKey:BDSKDragCopyKey] intValue] == 2){
        [self copyAsPDF:self];
    }
}

- (IBAction)copyAsBibTex:(id)sender{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    NSEnumerator *e = [self selectedPubEnumerator];
    NSMutableString *s = [[NSMutableString string] retain];
    NSNumber *i;
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    while(i=[e nextObject]){
        [s appendString:[[shownPublications objectAtIndex:[i intValue]] bibTeXString]];
    }
    [pasteboard setString:s forType:NSStringPboardType];
}

- (IBAction)copyAsTex:(id)sender{
	OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
	NSString *startCiteBracket = [sud stringForKey:BDSKCiteStartBracketKey]; 
	NSString *citeString = [sud stringForKey:BDSKCiteStringKey];
    NSMutableString *s = [NSMutableString stringWithFormat:@"\\%@%@", citeString, startCiteBracket];
	NSString *endCiteBracket = [sud stringForKey:BDSKCiteEndBracketKey]; 
	
    NSEnumerator *e = [self selectedPubEnumerator];
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    NSNumber *i;
    BOOL sep = ([sud integerForKey:BDSKSeparateCiteKey] == NSOnState);
    
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
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
    [pasteboard setString:s forType:NSStringPboardType];
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
    d = [PDFpreviewer PDFDataFromString:bibString];
    [pb setData:d forType:NSPDFPboardType];
}

// ----------------------------------------------------------------------------------------
// paste: get text, parse it as bibtex, add the entry to publications and (optionally) edit it.
// ----------------------------------------------------------------------------------------

- (IBAction)paste:(id)sender{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    NSArray *newPubs;
    NSEnumerator *newPubsE;
    BibItem *newBI;
    BOOL hadProblems = NO;
    NSString *tempFileName = nil;
    NSData *data = nil;
    int rv = 0;

    if ([[pasteboard types] containsObject:NSStringPboardType]) {
        data = [pasteboard dataForType:NSStringPboardType];
        newPubs = [BibTeXParser itemsFromData:data error:&hadProblems];
        if(hadProblems) {
            // run a modal dialog asking if we want to use partial data or give up
            rv = NSRunAlertPanel(NSLocalizedString(@"Error reading file!",@""),
                                 NSLocalizedString(@"There was a problem reading the file. Do you want to use everything that did work (\"Keep Going\"), edit the file to correct the errors, or give up?\n(If you choose \"Keep Going\" and then save the file, you will probably lose data.)",@""),
                                 NSLocalizedString(@"Give up",@""),
                                 NSLocalizedString(@"Keep going",@""),
                                 NSLocalizedString(@"Edit data", @""));
            if (rv == NSAlertDefaultReturn) {
                // the user said to give up
              
            }else if (rv == NSAlertAlternateReturn){
                // the user said to keep going, so if they save, they might clobber data...
                // note this by setting the update count:
                [self updateChangeCount:NSChangeDone];
            }else if(rv == NSAlertOtherReturn){
                // they said to edit the file.
                tempFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
                [data writeToFile:tempFileName atomically:YES];
                [[NSApp delegate] openEditWindowWithFile:tempFileName];
                [[NSApp delegate] showErrorPanel:self];
                
            }
        }
        newPubsE = [newPubs objectEnumerator];
        while(newBI = [newPubsE nextObject]){
            [self addPublication:newBI];

            [self updateUIAndRefreshOutline:YES];
            [self updateChangeCount:NSChangeDone];
            if([[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKEditOnPasteKey] == NSOnState)
                [self editPub:newBI forceChange:YES];
        }
    }else{
        NSBeep();// Pasting the wrong type gets you nowhere.
    }
}


- (void)createNewBlankPub{
    [self createNewBlankPubAndEdit:NO];
}

- (void)createNewBlankPubAndEdit:(BOOL)yn{
    OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
    BibItem *newBI = [[BibItem alloc] initWithType:[pw stringForKey:BDSKPubTypeStringKey]
                                          fileType:@"BibTeX" // Not Sure if this is good.
                                           authors:[NSMutableArray arrayWithCapacity:0]];

    [newBI setFileOrder:fileOrderCount];
    fileOrderCount++;
    [self addPublication:newBI];
    [self updateUIAndRefreshOutline:YES];
    if(yn == YES)
    {
        [self editPub:newBI];
    }
}

- (void)handleUpdateUINotification:(NSNotification *)notification{
    [self updateUI];
}


- (void)updateUI{
    [self updateUIAndRefreshOutline:NO];
}

- (void)updateUIAndRefreshOutline:(BOOL)refresh{
    [self refreshAuthors];
    [self handleFontChangedNotification:nil]; // calls reloadData.
/*    if((NSTableView *)[self currentView] == tableView){
        [tableView reloadData];
    }else{
#warning FIXME - reloadItem never seems to work...
        if(YES){
            [outlineView reloadData];
        }else{
            [outlineView reloadItem:nil];// reloadChildren:YES];
        }
    }
    */

// @@FIXME: will not always say "Publications shown"?
    [infoLine setStringValue: [NSString stringWithFormat:
        NSLocalizedString(@"%d of %d Publications shown.",
                          @"need two ints in format string."),
            [shownPublications count], [publications count] ] ];

    [self updatePreviews:nil];

}


//note - ********** the notification handling method will add NSTableColumn instances to the tableColumns dictionary.
- (void)setupTableColumns{
    NSArray *prefsShownColNamesArray = [[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKShownColsNamesKey];
    NSEnumerator *shownColNamesE = [prefsShownColNamesArray objectEnumerator];
    NSTableColumn *tc;
    NSString *colName;
    BDSKDragTableView *view = (BDSKDragTableView *)[self currentView];
    NSDictionary *tcWidthsByIdentifier = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKColumnWidthsKey];
    NSNumber *tcWidth = nil;
    NSImageCell *imageCell = [[[NSImageCell alloc] init] autorelease];

    [view removeAllTableColumns];
    
    while(colName = [shownColNamesE nextObject]){
        tc = [tableColumns objectForKey:colName];
        if(tcWidthsByIdentifier){
            tcWidth = [tcWidthsByIdentifier objectForKey:[tc identifier]];
            if(tcWidth){
                [tc setWidth:[tcWidth floatValue]];
            }
        }
        [[tc headerCell] setStringValue:colName];
        [tc setEditable:NO];

        if([[tc identifier] isEqualToString:@"No Identifier"]){
            // don't add the 'no ident' tc to either....
            // THIS IS A HACK.
            // I should probably set it up better in the nib, or something.
        }else{
            [view addTableColumn:tc];
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
        tc = [[NSTableColumn alloc] initWithIdentifier:[sender title]];
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
        tc = [[NSTableColumn alloc] initWithIdentifier:[addFieldTextField stringValue]];
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
	//NSLog(@"got handleBibItemChangedNotification with userinfo %@", [notification userInfo]);
	NSDictionary *userInfo = [notification userInfo];
	
	NSString *changedKey = [userInfo objectForKey:@"key"];
		
	if([quickSearchKey isEqualToString:changedKey] || 
	   [quickSearchKey isEqualToString:@"All Fields"]){
		if(BDSK_USING_JAGUAR){
			[self searchFieldAction:searchFieldTextField];
		}else{
			[self searchFieldAction:searchField];
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
    // The font we're using now
    NSFont *font = [NSFont fontWithName:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKTableViewFontKey]
                                   size:
        [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKTableViewFontSizeKey]];
    NSTableView *view  = (NSTableView *) [self currentView];
    
    // adjust the height of the rows: (sometimes this isn't quite right. why?)
    // //NSLog(@"default line height is %f, pointsize is %f", [font defaultLineHeightForFont], [font pointSize]);
    [view setRowHeight:[font defaultLineHeightForFont]+2];
    [view setFont:font];
    [view reloadData];
}

- (void)highlightBib:(BibItem *)bib{
    [self highlightBib:bib byExtendingSelection:NO];
}

- (void)highlightBib:(BibItem *)bib byExtendingSelection:(BOOL)yn{
    NSTableView *view  = (NSTableView *) [self currentView];
    int i = [shownPublications indexOfObjectIdenticalTo:bib];
    i = (sortDescending ? [shownPublications count] - 1 - i : i);
    

    if ([view isKindOfClass:[BDSKDragOutlineView class]]){
        i = (int) [(BDSKDragOutlineView *)view rowForItem:bib];
    }
    if(i != NSNotFound && i != -1){
        [view selectRow:i byExtendingSelection:yn];
        [view scrollRowToVisible:i];
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
}



// returns the current view we're using. 
- (id)currentView{
   if([dummyView contentView] == tableBox){
        return (id) tableView;
    }else{
        return (id) outlineView;
    }
}


- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem{
    if([[menuItem title] isEqualToString:@"Copy BibTex"] ||
       [[menuItem title] isEqualToString:@"Copy Tex Citation"] ||
       [[menuItem title] isEqualToString:@"Copy PDF Citation"] ||
       [[menuItem title] isEqualToString:@"Edit Reference"] ||
       [[menuItem title] isEqualToString:@"Delete Reference"]){
        if([self numberOfSelectedPubs] != 0)
            return YES;
        else
            return NO;

    }else if([[menuItem title] isEqualToString:@"Send via email"]&& [self numberOfSelectedPubs] != 1){
        // Localization note: does using this string work under localizations?
        return NO;
    }else{
        return YES;
    }
}


- (int)numberOfSelectedPubs{
    return [[[self selectedPubEnumerator] allObjects] count];
}


- (NSEnumerator *)selectedPubEnumerator{
    NSEnumerator *rowE = nil;
    id rowIndex = nil;
    id rowItem = nil;
    NSMutableArray *items = nil;
    NSEnumerator *childE = nil;
    id child = nil;
    id item = nil;
    NSEnumerator *itemsE = nil;
    int index;
    NSMutableArray *itemIndexes = [NSMutableArray arrayWithCapacity:10];
    
    if ((NSTableView *)[self currentView] == tableView) {
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
    }else{
        // outlineView
        items = [NSMutableArray arrayWithCapacity:10]; // arbitrary, yes. Bad ?
        
        rowE = [outlineView selectedRowEnumerator];
        while(rowIndex = [rowE nextObject]){
            rowItem = [outlineView itemAtRow:[rowIndex intValue]];
            
            if([rowItem isKindOfClass:[BibItem class]]){
                [items addObject:rowItem];
            }else if([rowItem isKindOfClass:[BibAuthor class]]){
                // rowItem *should* be expanded if we're getting called. (We assume this!)
				// @@ note: this assumes bibauthors. 
                childE = [[rowItem children] objectEnumerator];
                while(child = [childE nextObject]){
                    if ([items indexOfObjectIdenticalTo:child] == NSNotFound) {
                        [items addObject:child];
                    }
                }
                
            }
        }
        itemsE = [items objectEnumerator];
        while(item = [itemsE nextObject]){
            index = [shownPublications indexOfObjectIdenticalTo:item];
            [itemIndexes addObject:[NSNumber numberWithInt:index]];
        }
        return [itemIndexes objectEnumerator];
    }
}

- (void)windowWillClose:(NSNotification *)notification{
    NSMutableArray *depWins = [NSMutableArray array];
    NSEnumerator *pubE = [publications objectEnumerator];
    BibItem *pub;

    // make sure all bibitems have been saved:
    while(pub = [pubE nextObject]){
        if([pub editorObj]){ //should be isedited, or isshowing??
            [depWins addObject:[[pub editorObj] window]];
        }
    }
    [depWins makeObjectsPerformSelector:@selector(close)];
    [customCiteDrawer close];
    [[NSApp delegate] removeErrorObjsForFileName:[self fileName]];

}

- (void)splitViewDoubleClick:(OASplitView *)sender{
    [NSException raise:@"UnimplementedException" format:@"splitview %@ was clicked.", sender];
}

#pragma mark
#pragma mark Printing support

- (NSView *)printableView{
	return previewField; // random hack for now. - this will only print the selected items.
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
    [self runModalPrintOperation:op
						delegate:nil
				  didRunSelector:NULL
					 contextInfo:NULL];
}

@end
