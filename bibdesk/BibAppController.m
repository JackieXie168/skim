//
//  BibAppController.m
//  Bibdesk
//
//  Created by Michael McCracken on Sat Jan 19 2002.
//  Copyright (c) 2001 Michael McCracken. All rights reserved.
//
#import "BibItem.h"
#import "BibAppController.h"
#import "BibPrefController.h"
#import "BDSKPreviewer.h"

#import "NSTextView_BDSKExtensions.h"
#import "NSString_BDSKExtensions.h"



// ----------------------------------------------------------------------------------------
// copy-n-pasted from my version of btparse's error.c:
// ***Don't change this just here ***//

/*!
    @class BDSKErrObj
    @abstract used to pass errors up from btparse
    @discussion Just a struct - subclasses from NSObject so we can use NSObject's Key-value coding.
*/

//
// ----------------------------------------------------------------------------------------


@implementation BibAppController

+ (void)initialize
{
    BOOL isDir;
    NSString *applicationSupportPath;
    NSFileManager *DFM = [NSFileManager defaultManager];

       // now check if the application support directory is there...
    applicationSupportPath = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
        stringByAppendingPathComponent:@"Application Support"]
        stringByAppendingPathComponent:@"BibDesk"];

    if (![DFM fileExistsAtPath:applicationSupportPath
                   isDirectory:&isDir]){
        // create it
        [DFM createDirectoryAtPath:applicationSupportPath
                        attributes:nil];
    }
    if(![DFM fileExistsAtPath:[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.tex"]]){
        // copy .tex file:
        [DFM copyPath:[[NSBundle mainBundle] pathForResource:@"bibpreview" ofType:@"tex"]
               toPath:[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.tex"] handler:nil];
    }
    if(![DFM fileExistsAtPath:[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.bib"]]){
        // copy .bib file:
        [DFM copyPath:[[NSBundle mainBundle] pathForResource:@"bibpreview" ofType:@"bib"]
               toPath:[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.bib"] handler:nil];
    }
    if(![DFM fileExistsAtPath:[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.pdf"]]){
        // copy .pdf file:
        [DFM copyPath:[[NSBundle mainBundle] pathForResource:@"bibpreview" ofType:@"pdf"]
               toPath:[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.pdf"] handler:nil];
    }
    if(![DFM fileExistsAtPath:[applicationSupportPath stringByAppendingPathComponent:@"template.txt"]]){
        // copy .pdf file:
        [DFM copyPath:[[NSBundle mainBundle] pathForResource:@"template" ofType:@"txt"]
               toPath:[applicationSupportPath stringByAppendingPathComponent:@"template.txt"] handler:nil];
    }
    if(![DFM fileExistsAtPath:[applicationSupportPath stringByAppendingPathComponent:@"rssTemplate.txt"]]){
        // copy .pdf file:
        [DFM copyPath:[[NSBundle mainBundle] pathForResource:@"rssTemplate" ofType:@"txt"]
               toPath:[applicationSupportPath stringByAppendingPathComponent:@"rssTemplate.txt"] handler:nil];
    }


    [NSApp registerServicesMenuSendTypes:[NSArray arrayWithObjects:NSStringPboardType,nil] returnTypes:[NSArray arrayWithObjects:NSStringPboardType,nil]];
}

- (void)awakeFromNib{
#if DEBUG
    NSLog(@"awakeFromNibCalled");
#endif
    [errorTableView setDoubleAction:@selector(gotoError:)];
}



// auto-completion stuff
- (void)addString:(NSString *)string forCompletionEntry:(NSString *)entry{
    NSMutableArray *completionArray = nil;
    if (![[_autoCompletionDict allKeys] containsObject:entry]) {
        completionArray = [[NSMutableArray alloc] initWithCapacity:5];
    }else{
        completionArray = [[_autoCompletionDict objectForKey:entry] mutableCopy];
    }
    [completionArray addObject:string];
    [completionArray autorelease];
    [_autoCompletionDict setObject:[completionArray copy] forKey:entry];
}

- (NSFormatter *)formatterForEntry:(NSString *)entry{
    BDSKFormCellFormatter *formatter = nil;
    formatter = [_formatters objectForKey:entry];
    if (formatter == nil) {
        formatter = [[BDSKFormCellFormatter alloc] init];
        [formatter setEntry:entry];
        [_formatters setObject:formatter forKey:entry];
    }
    return formatter;
}

- (NSArray *)stringsForCompletionEntry:(NSString *)entry{
    return [(NSArray *)[_autoCompletionDict objectForKey:entry] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}



- (IBAction)checkForUpdates:(id)sender{
    NSString *currVersionNumber = [[[NSBundle bundleForClass:[self class]]
        infoDictionary] objectForKey:@"CFBundleVersion"];

    NSDictionary *productVersionDict = [NSDictionary dictionaryWithContentsOfURL:
        [NSURL URLWithString:@"http://www.cs.ucsd.edu/~mmccrack/bibdesk-versions-xml.txt"]];

    NSString *latestVersionNumber = [productVersionDict valueForKey:@"BibDesk"];

    int button;
    if(latestVersionNumber == nil){
        NSRunAlertPanel(NSLocalizedString(@"Error",
                                          @"Title of alert when an error happens"),
                        NSLocalizedString(@"There was an error checking for updates.",
                                          @"Alert text when the error happens."),
                        NSLocalizedString(@"Give up", @"Accept & give up"), nil, nil);
        return;
    }
    
    if([latestVersionNumber isEqualToString: currVersionNumber])
    {
        // tell user software is up to date
        NSRunAlertPanel(NSLocalizedString(@"BibDesk is up-to-date",
                                          @"Title of alert when a the user's software is up to date."),
                        NSLocalizedString(@"You have the most recent version of BibDesk.",
                                          @"Alert text when the user's software is up to date."),
                        NSLocalizedString(@"OK", @"OK"), nil, nil);        
    }
    else
    {
        // tell user to download a new version
        button = NSRunAlertPanel(NSLocalizedString(@"A New Version is Available",
                                                       @"Alert when new version is available"),
                                     [NSString stringWithFormat:
                                         NSLocalizedString(@"A new version of BibDesk is available (version %@). Would you like to download the new version now?",
                                                           @"format string asking if the user would like to get the new version"), latestVersionNumber],
                                     @"OK", @"Cancel", nil);
        if (button == NSOKButton) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.cs.ucsd.edu/~mmccrack/bibdesk.html"]];
        }
    }
    
}

- (IBAction)visitWebSite:(id)sender{
    if(![[NSWorkspace sharedWorkspace] openURL:
        [NSURL URLWithString:@"http://www.cs.ucsd.edu/~mmccrack/bibdesk.html"]]){
        NSBeep();
    }
}

// this is stolen from the preferences because i'm not sure how to make my view a first responder.
- (void)changeFont:(id)fontManager{
    NSFont *newFont;
    OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
    NSFont *oldFont =
        [NSFont fontWithName:[pw objectForKey:BDSKTableViewFontKey]
                        size:[pw floatForKey:BDSKTableViewFontSizeKey]];

    newFont = [[NSFontPanel sharedFontPanel] panelConvertFont:oldFont];
    [pw setObject:[newFont fontName] forKey:BDSKTableViewFontKey];
    [pw setFloat:[newFont pointSize] forKey:BDSKTableViewFontSizeKey];
    //    [fontPreviewField setStringValue:
    //        [[newFont displayName] stringByAppendingFormat:@" %.0f",[newFont pointSize]]];
    // make it have live updates:
    //  [[[NSDocumentController sharedDocumentController] documents]
    //makeObjectsPerformSelector:@selector(updateUI)];
        [pw synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKTableViewFontChangedNotification
                                                            object:nil];
}


- (IBAction)showPreferencePanel:(id)sender{
    [[OAPreferenceController sharedPreferenceController] showPreferencesPanel:nil];
}


- (id)init
{
    if(self = [super init]){
        //register as a listener for the previewpanel opening and closing
        [[NSNotificationCenter defaultCenter] addObserver:self
                                 selector:@selector(handleWindowCloseNotification:)
                                     name:NSWindowWillCloseNotification
                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleErrorNotification:)
                                                     name:@"BTPARSE ERROR"
                                                   object:nil];
        _errors = [[NSMutableArray alloc] initWithCapacity:5];
        _finder = [BibFinder sharedFinder];
        _autoCompletionDict = [[NSMutableDictionary alloc] initWithCapacity:15]; // arbitrary
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [prefController release];
    [_autoCompletionDict release];
    [_errors release];
    [super dealloc];
}

- (void)handleWindowCloseNotification:(NSNotification *)notification{
    if ([notification object] == [[BDSKPreviewer sharedPreviewer] window] ) {
        showingPreviewPanel = NO;
         [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:@"not showing" forKey:@"BDSK Showing Preview Key"];
    }
}

/*reference:
@interface BDSKErrObj : NSObject{
    NSString *fileName;
    int lineNumber;

    NSString *itemDescription;
    int itemNumber;

    NSString *errorClassName;
    NSString *errorMessage;
}*/

#pragma mark || tableView datasource methods
- (int)numberOfRowsInTableView:(NSTableView *)tableView{
    return [_errors count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    if ([[tableColumn identifier] isEqualToString:@"lineNumber"]) {
        return [NSString stringWithFormat:@"%@", [[_errors objectAtIndex:row] valueForKey:@"lineNumber"]];
    }
    if ([[tableColumn identifier] isEqualToString:@"errorClass"]) {
        return [NSString stringWithFormat:@"%@", [[_errors objectAtIndex:row] valueForKey:@"errorClassName"]];
    }
    if ([[tableColumn identifier] isEqualToString:@"fileName"]) {
        return [[NSString stringWithFormat:@"%@", [[_errors objectAtIndex:row] valueForKey:@"fileName"]] lastPathComponent];
    }
    if ([[tableColumn identifier] isEqualToString:@"errorMessage"]) {
        return [NSString stringWithFormat:@"%@", [[_errors objectAtIndex:row] valueForKey:@"errorMessage"]];
    }else{
        return @"";
    }
}

#pragma mark || error reporting and editing stuff

- (IBAction)toggleShowingErrorPanel:(id)sender{
    if (![errorPanel isVisible]) {
        [self showErrorPanel:sender];
    }else{
        [self hideErrorPanel:sender];
    }
}

- (IBAction)hideErrorPanel:(id)sender{
    [errorPanel orderOut:sender];
}

- (IBAction)showErrorPanel:(id)sender{
    [errorPanel makeKeyAndOrderFront:sender];
}

- (void)handleErrorNotification:(NSNotification *)notification{
    id errDict = [notification object];
    NSString *errorClass = [errDict valueForKey:@"errorClassName"];

    if (errorClass) {
        [_errors addObject:errDict];
        [errorTableView reloadData];
        //[errorTableView scrollRowToVisible:[_errors count]];
        if ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShowWarningsKey]) {
            [self showErrorPanel:self];
        }
    }
}

- (void)removeErrorsFromFileName:(NSString *)fileName{
    NSMutableArray *errorsToRemove = [NSMutableArray arrayWithCapacity:10];
    NSEnumerator *enumerator = [_errors objectEnumerator];
    id errObj;

    while (errObj = [enumerator nextObject]) {
        if ([[errObj valueForKey:@"fileName"] isEqualToString:fileName]) {
            [errorsToRemove addObject:errObj];
    	}
    }
    [_errors removeObjectsInArray:errorsToRemove];
    [errorTableView reloadData];
}

- (IBAction)gotoError:(id)sender{
    id errObj = nil;
    int selectedRow = [sender selectedRow];
    if(selectedRow != -1){
      errObj = [_errors objectAtIndex:selectedRow];
      [self gotoErrorObj:errObj];
    }
}

- (void)gotoErrorObj:(id)errObj{
    NSString *fileName = [errObj valueForKey:@"fileName"];
    NSNumber *lineNumber = [errObj valueForKey:@"lineNumber"];
    NSFileManager *dfm = [NSFileManager defaultManager];

    [self openEditWindowWithFile:fileName];
    
    if ([dfm fileExistsAtPath:fileName]) {
        [sourceEditTextView selectLine:[lineNumber intValue]];
    }
}

- (IBAction)openEditWindowWithFile:(NSString *)fileName{
    NSFileManager *dfm = [NSFileManager defaultManager];
    if (!fileName) return;

    if ([dfm fileExistsAtPath:fileName]) {
        if(![currentFileName isEqualToString:fileName]){
            [sourceEditTextView setString:[NSString stringWithContentsOfFile:fileName]];
            [sourceEditWindow setTitle:[fileName lastPathComponent]];
        }
        [sourceEditWindow makeKeyAndOrderFront:self];
        [currentFileName autorelease];
        currentFileName = [fileName retain]; // should use an accessor!
    }
}

- (IBAction)reopenDocument:(id)sender{
    NSString *s = [sourceEditTextView string];
    NSString *expandedCurrentFileName = [currentFileName stringByExpandingTildeInPath];

    expandedCurrentFileName = [expandedCurrentFileName uniquePathByAddingNumber];
    
    [s writeToFile:expandedCurrentFileName atomically:YES];

    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:expandedCurrentFileName
                                                                            display:YES];
    
}

- (IBAction)showFindPanel:(id)sender{
    [_finder showWindow:self];
}

- (IBAction)showPreviewPanel:(id)sender{
    if(!showingPreviewPanel){
        [[BDSKPreviewer sharedPreviewer] showWindow:self]; // why self?
        showingPreviewPanel = YES;
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:@"showing" forKey:@"BDSK Showing Preview Key"];
    }
}

- (IBAction)toggleShowingPreviewPanel:(id)sender{
    if(!showingPreviewPanel){
        [[BDSKPreviewer sharedPreviewer] showWindow:self];
        showingPreviewPanel = YES;
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:@"showing" forKey:@"BDSK Showing Preview Key"];
    }else{
        [[[BDSKPreviewer sharedPreviewer] window] close];
        showingPreviewPanel = NO; // redundant.
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:@"not showing" forKey:@"BDSK Showing Preview Key"];
    }    
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    if ([[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKStartupBehaviorKey] intValue] == 0) {
        return YES;
    }else{
        return NO;
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    if ([[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKStartupBehaviorKey] intValue] == 2) {
        [[NSDocumentController sharedDocumentController] openDocument:nil];// get NSDocController to run the fancy open panel.
    }
    if ([[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKStartupBehaviorKey] intValue] == 3) {
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:
 [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKDefaultBibFilePathKey] display:YES];
    }
    // register as a service provider for completecitation:
    [NSApp setServicesProvider:self];
    NSUpdateDynamicServices();

    if([@"showing" isEqualToString:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:@"BDSK Showing Preview Key"]]){
        [self showPreviewPanel:self];
    }
  
}

- (void)completeCitationFromSelection:(NSPasteboard *)pboard
                             userData:(NSString *)userData
                                error:(NSString **)error{
    NSString *pboardString;
    NSArray *types;
    NSMutableArray *items;
    NSEnumerator *e;
    BibItem *key;
    BOOL yn;
    NSMutableString *keys = [NSMutableString string];
    NSMutableString *commentString = [NSMutableString string];
    NSString *queryString;
    NSMutableString *queryKey;
    NSCharacterSet *delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@":="];
    //NSCharacterSet *emptySet =  [NSCharacterSet characterSetWithCharactersInString:@""];
    NSCharacterSet *ampersandSet =  [NSCharacterSet characterSetWithCharactersInString:@"&"];
    NSScanner *scanner;
    NSMutableDictionary *searchConstraints = [NSMutableDictionary dictionary];
    NSString *citeString = [NSString stringWithFormat:@"\\%@{",[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKCiteStringKey]];
    
    types = [pboard types];
    if (![types containsObject:NSStringPboardType]) {
        *error = NSLocalizedString(@"Error: couldn't complete text.",
                                   @"pboard couldn't give string.");
        return;
    }
    pboardString = [pboard stringForType:NSStringPboardType];
    if (!pboardString) {
        *error = NSLocalizedString(@"Error: couldn't complete text.",
                                   @"pboard couldn't give string.");
        return;
    }

    scanner = [NSScanner scannerWithString:pboardString];
    // Now split the string into a key and value pair by looking for a delimiter
    // (we'll use a bunch of handy delimiters, including the first space, so it's flexible.)
    // alternatively we can just type the title, like we used to.

    [scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&queryKey];
    // scan the first key (also might be a simple title for original style search)
    
    if (![scanner isAtEnd]){
        while(![scanner isAtEnd]){
            [scanner scanCharactersFromSet:delimiterSet intoString:nil]; // scan the delimiters away
            [scanner scanUpToCharactersFromSet:ampersandSet intoString:&queryString]; // scan to either the end, or the next query key.
                                                                                  // might have to remove a trailing space:
            if([[queryString substringWithRange:NSMakeRange([queryString length]-1,1)] isEqualToString:@" "]){
                queryString = [queryString substringWithRange:NSMakeRange(0,[queryString length]-1)];
                // FIXME? does this leak memory? is the intoString: argument autoreleased?
            }
            [scanner scanCharactersFromSet:ampersandSet intoString:nil]; // scan the ampersands away.
            [searchConstraints setObject:queryString forKey:queryKey];
            if(![scanner isAtEnd]) // do i have to do this?
                [scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&queryKey];// scan another 
        }
        items = [_finder itemsMatchingConstraints:searchConstraints];
    }else{
        // if it was at end, we are done, and we'll scan in the title:
        items = [_finder itemsMatchingText:queryKey inKey:@"Title"];
    }
    
    e = [items objectEnumerator];
    if([items count] > 0){
        if(key = [e nextObject]){
            [keys appendString:citeString];
            [keys appendString:[key citeKey]];
            [commentString appendString:[key citeKey]];
            [commentString appendString:@" = "];
            [commentString appendString:[key title]];
        }
        while(key = [e nextObject]){
            [keys appendString:@", "];
            [keys appendString:[key citeKey]];
            [commentString appendString:@"; "];
            [commentString appendString:[key citeKey]];
            [commentString appendString:@" = "];
            [commentString appendString:[key title]];
        }
        [keys appendString:@"} %% "];
        // let people set this as a pref?s
        [keys appendString:commentString];
        types = [NSArray arrayWithObject:NSStringPboardType];
        [pboard declareTypes:types owner:nil];

        yn = [pboard setString:keys forType:NSStringPboardType];
    }
    return;
}

@end
