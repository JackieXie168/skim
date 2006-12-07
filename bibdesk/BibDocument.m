//
//  BibDocument.m
//  Bibdesk
//
//  Created by Michael McCracken on Mon Dec 17 2001.
//  Copyright (c) 2001 Michael McCracken. All rights reserved.
//

#import "BibDocument.h"
#import "BibItem.h"
#import "BibAuthor.h"
#import "BibEditor.h"
#import <OmniAppKit/OAPreferenceController.h>
#import <OmniAppKit/NSTableView-OAExtensions.h>
#import <OmniFoundation/NSString-OFExtensions.h>
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
        allAuthors = [[NSMutableArray alloc] initWithCapacity:1];
        frontMatter = [[NSMutableString alloc] initWithString:@""];
        currentSortKey = [[NSString alloc] initWithString:@"Title"];

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
     
     customStringArray = [[NSMutableArray arrayWithCapacity:6] retain];
     [customStringArray setArray:[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKCustomCiteStringsKey]];

     tableColumnsChanged = YES;
    }
    return self;
}


- (void)awakeFromNib{
    NSEnumerator *nibTCE = [[tableView tableColumns] objectEnumerator];
    NSTableColumn *tc;
    NSArray *prefTCNames = [[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKShownColsNamesKey];
    NSEnumerator *prefTCNamesE = [prefTCNames objectEnumerator];
    NSString *tcName;
    
    NSMutableAttributedString *clearStr = [[[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"clear",@"")] autorelease];
    NSDictionary *linkAttributes= [NSDictionary dictionaryWithObjectsAndKeys:             [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName,
        [NSColor blueColor], NSForegroundColorAttributeName,
        NULL];
    NSSize drawerSize;
    //NSString *viewByKey = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKViewByKey];
    NSArray *prefsQuickSearchKeysArray = [[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKQuickSearchKeys];
    NSString *aKey = nil;
    NSEnumerator *quickSearchKeyE = [prefsQuickSearchKeysArray objectEnumerator];

    quickSearchTextDict = [[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKCurrentQuickSearchTextDict] mutableCopy];
    while(aKey = [quickSearchKeyE nextObject]){
        [quickSearchButton insertItemWithTitle:aKey
                                       atIndex:0];
    }
    
    [quickSearchButton selectItemWithTitle:quickSearchKey];
    if(quickSearchTextDict){
        if([quickSearchTextDict objectForKey:quickSearchKey]){
            [quickSearchTextField setStringValue:
                [quickSearchTextDict objectForKey:quickSearchKey]];
        }else{
            [quickSearchTextField setStringValue:@""];
        }
    }else{
        quickSearchTextDict = [[NSMutableDictionary dictionaryWithCapacity:4] retain];
    }

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
    [self didChangeSortKey:sortKeyButton];

    [tableView setDoubleAction:@selector(editPubCmd:)];
    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, NSFilenamesPboardType, nil]];
    [outlineView setDoubleAction:@selector(editPubCmd:)];
    // [outlineView registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, NSFilenamesPboardType, nil]];

    [tableView setMenu:contextualMenu];
    [outlineView setMenu:contextualMenu];
    
    [clearStr setAttributes:linkAttributes range:NSMakeRange(0,[clearStr length])];
    [quickSearchClearButton setAttributedTitle:clearStr];
    [quickSearchClearButton setEnabled:NO];
    [quickSearchClearButton setToolTip:NSLocalizedString(@"Clear the Quicksearch Field",@"")];

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
    NSLog(@"bibdoc dealloc");
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [publications release]; // these should cause the bibitems to get dealloc'ed
    [shownPublications release];
    [bibEditors release]; // gets rid of all the bibeditors.
    [allAuthors release];
    [frontMatter release];
    [currentSortKey release];
    [quickSearchTextDict release];
    [quickSearchKey release];
    [showColsArray release];
    [customStringArray release];
    [super dealloc];
}

- (void)setPublications:(NSMutableArray *)newPubs{
    [publications autorelease];
    publications = newPubs;
}

- (NSMutableArray *) publications{
    return publications; // was: publications retain
}

- (NSArray *)allAuthors{
    return allAuthors;
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
    //[tableView selectColumn:[tableView columnWithIdentifier:@"Title"] byExtendingSelection:NO];
    //[self sortPubsByColumn:tableView];
    [self setupTableColumns]; // calling it here mostly just makes sure that the menu is set up.

    [self controlTextDidChange:nil]; // calls updateUI.
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification{
    //NSLog(@"win did become main");
    [self updateUI]; // mostly because the BDSKPreviewer is a singleton class.
}

#pragma mark || Document Saving and Reading

- (IBAction)saveDocument:(id)sender{
    NSString *rssFileName;
    BOOL rssSaveOK;
    [super saveDocument:sender];
    if([[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKAutoSaveAsRSSKey] == NSOnState
       && ![[self fileType] isEqualToString:@"Rich Site Summary file"]){
        // also save doc as RSS
#if DEBUG
        NSLog(@"also save as RSS in saveDoc");
#endif
        [self exportAsRSS:nil];
    }
}

- (IBAction)exportAsRSS:(id)sender{
    NSSavePanel *sp = [NSSavePanel savePanel];
    [sp setRequiredFileType:@"rss"];
    [sp setDelegate:self];
    [sp setAccessoryView:rssExportAccessoryView];
    [sp beginSheetForDirectory:nil
                          file:[[NSString stringWithString:[[self fileName] stringByDeletingPathExtension]] lastPathComponent]
                modalForWindow:documentWindow
                 modalDelegate:self
                didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
                   contextInfo:nil];

}
- (void)savePanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    NSData *rssData = nil;
    NSString *fileName = nil;
    if(returnCode == NSOKButton){
        fileName = [sheet filename];
        rssData = [self dataRepresentationOfType:@"Rich Site Summary file"];
        [rssData writeToFile:fileName atomically:YES];
    }
    [sheet setRequiredFileType:@"bib"]; // just in case...
    [sheet setAccessoryView:nil];
}


- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    if ([aType isEqualToString:@"bibTeX database"]){
        return [self bibDataRepresentation];
    }else if ([aType isEqualToString:@"Rich Site Summary file"]){
        return [self rssDataRepresentation];
    }
    //else:
    return nil;
    // this is an error, maybe also raise an exception?
}

- (void)saveDependentWindows{
    NSMutableArray *depWins = [NSMutableArray array];
    NSEnumerator *pubE = [publications objectEnumerator]; // yeah, i've got two - so what.
    BibItem *pub;

    // make sure all bibitems have been saved:
    while(pub = [pubE nextObject]){
        if([[pub editorObj] isEdited]){
            [depWins addObject:[pub editorObj]];
        }
    }
    [depWins makeObjectsPerformSelector:@selector(saveDocument:)];
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
    
    [self saveDependentWindows];

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

- (NSData *)bibDataRepresentation{
    BibItem *tmp;
    NSEnumerator *e = [[publications sortedArrayUsingSelector:@selector(fileOrderCompare:)] objectEnumerator];
    NSMutableData *d = [NSMutableData data];
    NSMutableString *templateFile = [NSMutableString stringWithContentsOfFile:[[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKOutputTemplateFileKey] stringByExpandingTildeInPath]];

    [self saveDependentWindows];
    [templateFile appendFormat:@"\n%%%% Created for %@ at %@ \n\n", NSFullUserName(), [NSCalendarDate calendarDate]];
    
    [d appendData:[templateFile dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    [d appendData:[frontMatter dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];

    while(tmp = [e nextObject]){
        [d appendData:[[NSString stringWithString:@"\n\n"] dataUsingEncoding:NSASCIIStringEncoding  allowLossyConversion:YES]];
        [d appendData:[[BDSKConverter stringByTeXifyingString:[tmp textValue]] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    }
    return d;
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
    if ([aType isEqualToString:@"bibTeX database"]){
        return [self loadBibTeXDataRepresentation:data];
    }else if([aType isEqualToString:@"Rich Site Summary File"]){
        return [self loadRSSDataRepresentation:data];
    }
    //else
    return NO;
}

- (BOOL)loadRSSDataRepresentation:(NSData *)data{
    //stub
    return NO;
}

- (BOOL)loadBibTeXDataRepresentation:(NSData *)data{
    int ok = 0;
    int rv = 0;
    BOOL hadProblems = NO;
    FILE *infile = NULL;
    char *fieldname = "\0";
    char *fs_path;
    NSString *s = nil;
    AST *entry = NULL;
    AST *field = NULL;
    BibItem *newBI = nil;
    unsigned char *buf;
    NSMutableDictionary *dictionary = nil;
    long cidx = 0; // used to scan through buf for annotes.
    char annoteDelim = '\0';
    int braceDepth = 0;
    // Weird bug: if you try to open a file like mrabbrv.bib, the next line gets exec_bad_access... what is up with that?
    // NOTE: i'm not sure if that bug exists after 0.6 - we'll see.
    dictionary = [NSMutableDictionary dictionaryWithCapacity:10];    // yes, 10 is arbitrary.
    buf = (unsigned char *) malloc(sizeof(unsigned char) * [data length]);
    
    [data getBytes:buf];

    // so, if filename has non ASCII characters, cString isn't enough:
    // use filesystemrepresentationwithpath: to get something we can pass to fopen.
    (const char *) fs_path = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:[self fileName]];
    infile = fopen(fs_path, "r");

    bt_initialize();
    bt_set_stringopts(BTE_PREAMBLE, BTO_EXPAND);
    bt_set_stringopts(BTE_REGULAR, BTO_MINIMAL); 
    while (entry = bt_parse_entry (infile, fs_path, 0, &ok))
    {
        if (ok)
        {
            // Adding a new BibItem
            if (bt_entry_metatype (entry) != BTE_REGULAR)
            {
                // put preambles etc. into the frontmatter string so we carry them along.
                if ([[NSString stringWithCString:bt_entry_type(entry) ] isEqualToString:@"preamble"]) {
                    [frontMatter appendString:@"\n@preamble{\""];
                    [frontMatter appendString:[NSString stringWithCString:bt_get_text(entry) ]];
                    [frontMatter appendString:@"\"}"];
                }
            }
            else
            {
                newBI = [[BibItem alloc] initWithType:[BibItem typeFromString:
                    [[NSString stringWithCString:bt_entry_type(entry) ] lowercaseString]]
                                              authors:[NSMutableArray arrayWithCapacity:0]
                                        defaultFields:[[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKDefaultFieldsKey] mutableCopy]];
                [newBI setFileOrder:fileOrderCount];
                fileOrderCount++;
                field = NULL;
                while (field = bt_next_field (entry, field, &fieldname))
                {
                // ----------------------------------------------------------------------------------------
                // FIXME  - GENERALIZABLE
                // we could allow any field to have newlines...
                // then we'd need to change the test below.
                // ----------------------------------------------------------------------------------------
                    if(!strcmp(fieldname, "annote") ||
                       !strcmp(fieldname, "abstract") ||
                       !strcmp(fieldname, "rss-description")){
                        if(field->down){
                            cidx = field->down->offset;
                            // the delimiter is at cidx-1
                            if(buf[cidx-1] == '{'){
                                // scan up to the balanced brace
                                for(braceDepth = 1; braceDepth > 0; cidx++){
                                    if(buf[cidx] == '{') braceDepth++;
                                    if(buf[cidx] == '}') braceDepth--;
                                }
                                cidx--;     // just advanced cidx one past the end of the field.
                            }else if(buf[cidx-1] == '"'){
                                // scan up to the next quote.
                                for(; buf[cidx] != '"'; cidx++);
                            }
                            annoteDelim = buf[cidx];
                            buf[cidx] = '\0';
                            s = [NSString stringWithCString:&buf[field->down->offset]];
                            buf[cidx] = annoteDelim;
                        }else{
                            hadProblems = YES;
                        }
                    }else{
                        s = [NSString stringWithCString:bt_get_text(field)];
                    }
#warning inefficient - tons of unneccessary I/O happening here.
                    // we should move stringByTeXifyingString out of the inner loop
                    [dictionary setObject:[BDSKConverter stringByDeTeXifyingString:s]
                                   forKey:[[NSString stringWithCString: fieldname ] capitalizedString]];
                    [(BibAppController *)[NSApp delegate] addString:[BDSKConverter stringByDeTeXifyingString:s]
                             forCompletionEntry:[[NSString stringWithCString: fieldname ] capitalizedString]];
                }
                [newBI setCiteKey:[NSString stringWithCString:bt_entry_key(entry) ]];
                [newBI setFields:dictionary];
                [publications addObject:[newBI autorelease]];
                [dictionary removeAllObjects];
            }
        }else{
            // there was an error... don't die, though - btparse will try to recover.
            hadProblems = YES;
        }
    }// now feof(infile) is guaranteed by btparse to be true...
    
    if(hadProblems){
        // run a modal dialog asking if we want to use partial data or give up
        rv = NSRunAlertPanel(NSLocalizedString(@"Error reading file!",@""),
                             NSLocalizedString(@"There was a problem reading the file. Do you want to use everything that did work (\"Keep Going\"), edit the file to correct the errors, or give up?\n(If you choose \"Keep Going\" and then save the file, you will probably lose data.)",@""),
                        // Eventually, we should have more options - f/i edit and retry.
                        // we should also find a way to view the error...
                        // since we can't do that now, the default is to give up
                        // so you can edit it somewhere else and retry.
                             NSLocalizedString(@"Give up",@""),
                             NSLocalizedString(@"Keep going",@""),
                             NSLocalizedString(@"Edit file", @""));
        if (rv == NSAlertDefaultReturn) {
            // the user said to give up
            fclose(infile);
            bt_cleanup();
            free(buf);
            return NO;
        }else if (rv == NSAlertAlternateReturn){
            // the user said to keep going, so if they save, they might clobber data...
            // note this by setting the update count:
            [self updateChangeCount:NSChangeDone];
        }else if(rv == NSAlertOtherReturn){
            [[NSApp delegate] openEditWindowWithFile:[[self fileName] stringByExpandingTildeInPath]];
            [[NSApp delegate] showErrorPanel:self];
            fclose(infile);
            bt_cleanup();
            free(buf);
            return NO;
        }
    }
    
    [shownPublications setArray:publications];
    // redundant - it's called in windowcontrollerdidloadnib. [self updateUI];
    fclose(infile);
    bt_cleanup();
    free(buf);
    return YES;
}

- (IBAction)newPub:(id)sender{
    [self createNewBlankPubAndEdit:YES];
}

- (IBAction)delPub:(id)sender{
    NSEnumerator *delEnum = nil;
    NSNumber *rowToDelete;
    id objToDelete;
    int rv = 0;
    if ([self numberOfSelectedPubs] == 0) {
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
            [publications removeObjectIdenticalTo:objToDelete];
        }
        [shownPublications setArray:publications];
        [self updateChangeCount:NSChangeDone];
        [[self currentView] deselectAll:nil];
        [self updateUI];
    }else{
        //the user canceled, do nothing.
    }
}

- (IBAction)clearQuickSearch:(id)sender{
    [quickSearchTextField setStringValue:@""];
    [self controlTextDidChange:nil];
}

- (IBAction)didChangeQuickSearchKey:(id)sender{
    [quickSearchKey autorelease];
    quickSearchKey = [[sender titleOfSelectedItem] retain];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:quickSearchKey
                                                      forKey:BDSKCurrentQuickSearchKey];
 
    //   [quickSearchToolbarItem setLabel:[NSString stringWithFormat:@"%@%@",@"Search by ",[sender titleOfSelectedItem]]];
    if([quickSearchTextDict objectForKey:quickSearchKey]){
        [quickSearchTextField setStringValue:
            [quickSearchTextDict objectForKey:quickSearchKey]];
    }else{
        [quickSearchTextField setStringValue:@""];
    }
    [self controlTextDidChange:nil];
    //    [documentWindow setViewsNeedDisplay:YES];
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

    if(returnCode == 1){
        //        NSLog(@"addFieldTextField title is %@", [addFieldTextField stringValue]);
        [quickSearchButton insertItemWithTitle:[addFieldTextField stringValue]
                                       atIndex:0];
        [quickSearchButton selectItemWithTitle:[addFieldTextField stringValue]];
        [self didChangeQuickSearchKey:quickSearchButton];

        prefsQuickSearchKeysMutableArray = [[[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKQuickSearchKeys] mutableCopy] autorelease];

        if(!prefsQuickSearchKeysMutableArray){
            prefsQuickSearchKeysMutableArray = [NSMutableArray arrayWithCapacity:1];
        }
        [prefsQuickSearchKeysMutableArray addObject:[addFieldTextField stringValue]];
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:prefsQuickSearchKeysMutableArray
                                                          forKey:BDSKQuickSearchKeys];
    }else{
        //do nothing -- cancel.
    }
}


- (void)updatePreviews:(NSNotification *)aNotification{
    NSNumber *i;
    NSMutableString *bibString = [NSMutableString stringWithString:@""];
    NSEnumerator *e = [self selectedPubEnumerator];

    if(((NSTableView *)[self currentView] == tableView) ||
       ((NSTableView *)[self currentView] == (NSTableView *)outlineView)){
        [previewField setString:@""];
        if([self numberOfSelectedPubs] == 0){
            [editPubButton setEnabled:NO];
            [delPubButton setEnabled:NO];
        }else{
            [editPubButton setEnabled:YES];
            [delPubButton setEnabled:YES];
            //take care of the preview field
            [self displayPreviewForItems:[self selectedPubEnumerator]];
            // (don't just pass it 'e' - it needs its own enum.)
            
            while(i = [e nextObject]){
                [bibString appendString:[[shownPublications objectAtIndex:[i intValue]] textValue]];
            }// while i is num of selected row

            if([[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKUsesTeXKey] == NSOnState){
                [NSThread
                detachNewThreadSelector:@selector(PDFFromString:)
                               toTarget:PDFpreviewer
                             withObject:[BDSKConverter stringByTeXifyingString:bibString]];
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
    NSView *newView;

    [currentSortKey autorelease];
    currentSortKey = [sender titleOfSelectedItem];
    if([dummyView contentView] != (NSView *) newView){
        if([currentSortKey isEqualToString: @"Author"]){
            [tableBox retain];
            newView = (NSView *) outlineBox;
        }else if([currentSortKey isEqualToString: @"Title"]){
            [outlineBox retain];
            newView = (NSView *) tableBox;
        }
        [dummyView setContentView:newView];
        [self setupTableColumns];
        [self updateUIAndRefreshOutline:YES];
    }
   // [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:currentSortKey forKey:BDSKViewByKey];
}

- (IBAction)sortPubsByColumn:(id)sender{
    NSTableColumn *stc;
    
    if([tableView selectedColumn] != -1){
        stc = [[tableView tableColumns] objectAtIndex:[tableView selectedColumn]];
        [tableView setHighlightedTableColumn:stc];
        if([[stc identifier] isEqualToString:@"Cite Key"]){

            [publications sortUsingSelector:@selector(keyCompare:)];
            [shownPublications sortUsingSelector:@selector(keyCompare:)];
        }else if([[stc identifier] isEqualToString:@"Title"]){

            [publications sortUsingSelector:@selector(titleCompare:)];
            [shownPublications sortUsingSelector:@selector(titleCompare:)];
        }else if([[stc identifier] isEqualToString:@"Date"]){

            [publications sortUsingSelector:@selector(dateCompare:)];
            [shownPublications sortUsingSelector:@selector(dateCompare:)];
        }else if([[stc identifier] isEqualToString:@"1st Author"]){

            [publications sortUsingSelector:@selector(auth1Compare:)];
            [shownPublications sortUsingSelector:@selector(auth1Compare:)];
        }else if([[stc identifier] isEqualToString:@"2nd Author"]){

            [publications sortUsingSelector:@selector(auth2Compare:)];
            [shownPublications sortUsingSelector:@selector(auth2Compare:)];
        }else if([[stc identifier] isEqualToString:@"3rd Author"]){

            [publications sortUsingSelector:@selector(auth3Compare:)];
            [shownPublications sortUsingSelector:@selector(auth3Compare:)];
        }
        [tableView reloadData];
    }
}

- (IBAction)editPubCmd:(id)sender{
    NSEnumerator *e = [self selectedPubEnumerator];
    NSNumber *i;

    while (i = [e nextObject]) {
        [self editPub:[shownPublications objectAtIndex:[i intValue]]];
    }
}

- (void)editPub:(BibItem *)pub{
    [self editPub:pub forceChange:NO];
}
- (void)editPub:(BibItem *)pub forceChange:(BOOL)force{
    BibEditor *e = [pub editorObj];
    if(e == nil){
        e = [[BibEditor alloc] initWithBibItem:pub andBibDocument:self];
        [bibEditors addObject:[e autorelease]];// we need to keep track of the bibeditors
    }
    [e show];
    if(force){
#if DEBUG
        NSLog(@"updating change count");
#endif
        [e updateChangeCount:NSChangeDone];
    }
}

// This is a delegate method of the quick search text field.
#warning Localizable - quicksearchkeys ?
- (void)controlTextDidChange:(NSNotification *)aNotification{
    NSMutableArray *remArray = [NSMutableArray arrayWithCapacity:1];
    NSEnumerator *e = [publications objectEnumerator];
    BibItem *pub;
    NSString *prefix = [quickSearchTextField stringValue];
    NSRange r;

    [[self currentView] deselectAll:self];
    
    if(![prefix isEqualToString:@""]){
        while(pub = [e nextObject]){
            if ([quickSearchKey isEqualToString:@"Title"])
                r = [[pub title]  rangeOfString:prefix
                                        options:NSCaseInsensitiveSearch];
            if ([quickSearchKey isEqualToString:@"Author"])
                r = [[pub authorString]  rangeOfString:prefix
                                               options:NSCaseInsensitiveSearch];
            if ([quickSearchKey isEqualToString:@"Date"]){
                r = [[[pub date] descriptionWithCalendarFormat:@"%B %Y"] rangeOfString:prefix                                                                                options:NSCaseInsensitiveSearch];
            }
            if([quickSearchKey isEqualToString:@"All Fields"]){
                r = [[pub allFieldsString] rangeOfString:prefix
                                                 options:NSCaseInsensitiveSearch];

            }
            if([quickSearchKey isEqualToString:@"Pub Type"]){
                r = [[BibItem stringFromType:[pub type]]
                    rangeOfString:prefix
                          options:NSCaseInsensitiveSearch];
            }else{
                r = [[pub valueOfField:quickSearchKey] rangeOfString:prefix
                                                             options:NSCaseInsensitiveSearch];
            }
            if(r.location == NSNotFound) [remArray addObject:pub];
        }
        [quickSearchClearButton setEnabled:YES];
        [quickSearchClearButton setToolTip:NSLocalizedString(@"Clear quick-search field",@"")];
    }else{
        [quickSearchClearButton setEnabled:NO];
        [quickSearchClearButton setToolTip:NSLocalizedString(@"Empty field",@"")];
    }
    [shownPublications setArray:publications];
    [shownPublications removeObjectsInArray:remArray];

    [quickSearchTextDict setObject:prefix
                            forKey:quickSearchKey];

    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:[[quickSearchTextDict copy] autorelease]
                                                      forKey:BDSKCurrentQuickSearchTextDict];
    [[OFPreferenceWrapper sharedPreferenceWrapper] autoSynchronize];

    [self updateUIAndRefreshOutline:YES]; // calls reloadData
    if([shownPublications count] == 1)
        [[self currentView] selectAll:self];
}

- (IBAction)copy:(id)sender{
    OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
    if([[sud objectForKey:BDSKDragCopyKey] intValue] == 0){
        [self copyAsBibTex:self];
    }if([[sud objectForKey:BDSKDragCopyKey] intValue] == 1){
        [self copyAsTex:self];
    }else{
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
        [s appendString:[[shownPublications objectAtIndex:[i intValue]] textValue]];
    }
    [pasteboard setString:s forType:NSStringPboardType];
}

- (IBAction)copyAsTex:(id)sender{
    NSMutableString *s = [NSMutableString stringWithFormat:@"\\%@{",[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKCiteStringKey]];
    NSEnumerator *e = [self selectedPubEnumerator];
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    NSNumber *i;
    BOOL sep = ([[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKSeparateCiteKey] == NSOnState);
    
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    while(i=[e nextObject]){
        [s appendString:[[shownPublications objectAtIndex:[i intValue]] citeKey]];
        if(sep)
            [s appendString:[NSString stringWithFormat:@"} \\%@{",[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKCiteStringKey]]];
        else
            [s appendString:@", "];
    }
    if(sep)
        [s replaceCharactersInRange:[s rangeOfString:[NSString stringWithFormat:@"} \\%@{", [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKCiteStringKey]] options:NSBackwardsSearch] withString:@"}"];
    else
        [s replaceCharactersInRange:[s rangeOfString:@", " options:NSBackwardsSearch] withString:@"}"];
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
        [bibString appendString:[[shownPublications objectAtIndex:[i intValue]] textValue]];
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

    if ([[pasteboard types] containsObject:NSStringPboardType]) {
        newPubs = [BibItem itemsFromString:[pasteboard stringForType:NSStringPboardType]];
        newPubsE = [newPubs objectEnumerator];
        while(newBI = [newPubsE nextObject]){
            [publications addObject:newBI];
            [shownPublications addObject:newBI];
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
    BibItem *newBI = [[BibItem alloc] initWithType:[pw integerForKey:BDSKPubTypeKey]
                                           authors:[NSMutableArray arrayWithCapacity:0]
                                     defaultFields:[[pw stringArrayForKey:BDSKDefaultFieldsKey] mutableCopy]];

    [newBI setFileOrder:fileOrderCount];
    fileOrderCount++;
    [publications addObject:newBI];
    [self updateUIAndRefreshOutline:YES];
    if(yn == YES)
    {
        [self editPub:newBI];
    }
    [self updateChangeCount:NSChangeDone];
}

- (void)handleUpdateUINotification:(NSNotification *)notification{
    [self updateUI];
}


- (void)updateUI{
    [self updateUIAndRefreshOutline:NO];
}

- (void)updateUIAndRefreshOutline:(BOOL)refresh{
    NSEnumerator *pubE = [shownPublications objectEnumerator];
    NSEnumerator *authE;
    NSString *auth;
    NSArray *authStringArray;
    NSMutableArray *tmpTotalAuthStrings = [NSMutableArray arrayWithCapacity:6];
    BibItem *pub;
    unsigned i;

    [allAuthors removeAllObjects];
        
    while (pub = [pubE nextObject]) {
        authStringArray = [pub pubAuthors];
        authE = [authStringArray objectEnumerator];
        while(auth = [authE nextObject]){
            i = [tmpTotalAuthStrings indexOfObject:auth];
            if(i != NSNotFound){
                [[allAuthors objectAtIndex:i] addPub:pub];
            }else{
                [allAuthors addObject:[[[BibAuthor alloc] initWithName:auth andPub:pub] autorelease]];
                [tmpTotalAuthStrings addObject:auth];
            }
        }
    }

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

#warning FIXME: won't always say "Publications shown"?
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
            if(![[tc identifier] isEqualToString:@"Title"])
                [self contextualMenuAddTableColumnName:[tc identifier] enabled:YES]; // OK to add multiple times.
        }
    }
}

- (IBAction)dismissAddFieldSheet:(id)sender{
    [addFieldSheet orderOut:sender];
    [NSApp endSheet:addFieldSheet returnCode:[sender tag]];
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
    NSMenuItem *menuItem = nil;
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
    // NSLog(@"default line height is %f, pointsize is %f", [font defaultLineHeightForFont], [font pointSize]);
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

    if ([view isKindOfClass:[BDSKDragOutlineView class]]){
        i = (int) [(BDSKDragOutlineView *)view rowForItem:bib];
    }
    if(i != NSNotFound && i != -1){
        [view selectRow:i byExtendingSelection:yn];
        [view scrollRowToVisible:i];
    }
}


#pragma mark || Custom cite drawer stuff

- (IBAction)openCustomCitePrefPane:(id)sender{
    OAPreferenceController *pc = [OAPreferenceController sharedPreferenceController];
    [pc showPreferencesPanel:nil];
    [pc setCurrentClientByClassName:@"BibPref_Cite"];
}

- (IBAction)toggleShowingCustomCiteDrawer:(id)sender{
    [customCiteDrawer toggle:sender];
}



// returns the current view we're using. (not well tested)
- (id)currentView{
    if([currentSortKey isEqualToString: @"Title"]){
        return (id) tableView;
    }else{
        return (id) outlineView;
    }
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem{
    if(menuItem == ctxCopyBibTex || menuItem == ctxCopyTex || menuItem == ctxCopyPDF){
        if([self numberOfSelectedPubs] != 0)
            return YES;
        else
            return NO;
    }else{
        // validate other menu items:
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
    

    NSMutableArray *itemIndexes = nil;
    
    if ((NSTableView *)[self currentView] == tableView) {
        return [tableView selectedRowEnumerator];
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
#warning bibauthor dependence
                childE = [[rowItem children] objectEnumerator];
                while(child = [childE nextObject]){
                    if ([items indexOfObjectIdenticalTo:child] == NSNotFound) {
                        [items addObject:child];
                    }
                }
                
            }
        }
        itemsE = [items objectEnumerator];
        itemIndexes = [NSMutableArray arrayWithCapacity:10];
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
    [[NSApp delegate] removeErrorsFromFileName:[self fileName]];

}

#pragma mark || printing support

- (void)printShowingPrintPanel:(BOOL)flag{
    // do nothing.
}

@end
