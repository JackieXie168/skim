//  BibAppController.m

//  Created by Michael McCracken on Sat Jan 19 2002.
/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BibItem.h"
#import "BibAppController.h"
#import "BibPrefController.h"
#import "BDSKPreviewer.h"
#import "BibDocument.h"
#import "BibDocumentView_Toolbar.h"
#import "NSTextView_BDSKExtensions.h"
#import "NSString_BDSKExtensions.h"
#import "BDSKConverter.h"

#import <Carbon/Carbon.h>

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

#ifdef USECRASHREPORTER
    // start the crash reporter; 10.3+ only
    if(!BDSK_USING_JAGUAR)
        [[ILCrashReporter defaultReporter] launchReporterForCompany:@"BibDesk Project" reportAddr:@"bibdesk-crashes@lists.sourceforge.net"];
#endif
    
    // now check if the application support directory is there...
    applicationSupportPath = [[DFM applicationSupportDirectory:kUserDomain] stringByAppendingPathComponent:@"BibDesk"];
    
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
    if(![DFM fileExistsAtPath:[applicationSupportPath stringByAppendingPathComponent:@"previewtemplate.tex"]]){
        // copy previewtemplate.tex file (user-modifiable):
        [DFM copyPath:[[NSBundle mainBundle] pathForResource:@"previewtemplate" ofType:@"tex"]
               toPath:[applicationSupportPath stringByAppendingPathComponent:@"previewtemplate.tex"] handler:nil];
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
        // copy template.txt file:
        [DFM copyPath:[[NSBundle mainBundle] pathForResource:@"template" ofType:@"txt"]
               toPath:[applicationSupportPath stringByAppendingPathComponent:@"template.txt"] handler:nil];
    }
    if(![DFM fileExistsAtPath:[applicationSupportPath stringByAppendingPathComponent:@"rssTemplate.txt"]]){
        // copy rss template file:
        [DFM copyPath:[[NSBundle mainBundle] pathForResource:@"rssTemplate" ofType:@"txt"]
               toPath:[applicationSupportPath stringByAppendingPathComponent:@"rssTemplate.txt"] handler:nil];
    }
    if(![DFM fileExistsAtPath:[applicationSupportPath stringByAppendingPathComponent:@"htmlExportTemplate"]]){
        // copy html file template file:
        [DFM copyPath:[[NSBundle mainBundle] pathForResource:@"htmlExportTemplate" ofType:nil]
               toPath:[applicationSupportPath stringByAppendingPathComponent:@"htmlExportTemplate"] handler:nil];
        
    }if(![DFM fileExistsAtPath:[applicationSupportPath stringByAppendingPathComponent:@"htmlItemExportTemplate"]]){
        // copy html item template file:
        [DFM copyPath:[[NSBundle mainBundle] pathForResource:@"htmlItemExportTemplate" ofType:nil]
               toPath:[applicationSupportPath stringByAppendingPathComponent:@"htmlItemExportTemplate"] handler:nil];
    }

    [NSApp registerServicesMenuSendTypes:[NSArray arrayWithObjects:NSStringPboardType,nil] returnTypes:[NSArray arrayWithObjects:NSStringPboardType,nil]];
    if([[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:@"NSToolbar Configuration OAPreferences"] != nil){
	[[OFPreferenceWrapper sharedPreferenceWrapper] removeObjectForKey:@"NSToolbar Configuration OAPreferences"];
    }
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
                                                     name:BDSKParserErrorNotification
                                                   object:nil];
        _errors = [[NSMutableArray alloc] initWithCapacity:5];
        _finder = [[BibFinder sharedFinder] retain];
        _autoCompletionDict = [[NSMutableDictionary alloc] initWithCapacity:15]; // arbitrary
	 	_formatters = [[NSMutableDictionary alloc] initWithCapacity:15]; // arbitrary
        _autocompletePunctuationCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@",:;"] retain];
		
		NSString *formatString = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKCiteKeyFormatKey];
		NSString *error = nil;
		
		if (![[BDSKConverter sharedConverter] validateFormat:&formatString forField:@"Cite Key" inFileType:@"BibTeX" error:&error]) {
			NSLog(@"Invalid Cite Key format: %@ Restore default.", error);
			
			formatString = [[[OFPreferenceWrapper sharedPreferenceWrapper] preferenceForKey:BDSKCiteKeyFormatKey] defaultObjectValue];			
		}
		[self setRequiredFieldsForCiteKey: [[BDSKConverter sharedConverter] requiredFieldsForFormat:formatString]];
		[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:formatString forKey:BDSKCiteKeyFormatKey];
		
		formatString = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKLocalUrlFormatKey];
		error = nil;
		
		if (![[BDSKConverter sharedConverter] validateFormat:&formatString forField:@"Local-Url" inFileType:@"BibTeX" error:&error]) {
			NSLog(@"Invalid Local-Url format: %@ Restore default.", error);
			
			formatString = [[[OFPreferenceWrapper sharedPreferenceWrapper] preferenceForKey:BDSKLocalUrlFormatKey] defaultObjectValue];			
		}
		[self setRequiredFieldsForLocalUrl: [[BDSKConverter sharedConverter] requiredFieldsForFormat:formatString]];
		[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:formatString forKey:BDSKLocalUrlFormatKey];
    }
    return self;
}

- (NSDictionary *)encodingDefinitionDictionary{
    // From a model standpoint, it probably would make more sense to have an array of dictionaries, but the arrays are directly useful for
    // populating the popup menus.  Just remember to add a displayName _and_ a corresponding NSStringEncoding if you need to add another one.
    // This is used in the Files pref pane, and in the open/save accessory views at present (0.97.2+).
    NSArray *displayNames = [NSArray arrayWithObjects:@"ASCII (TeX)", @"NEXTSTEP", @"Japanese EUC", @"UTF-8", @"ISO Latin 1", @"Non-lossy ASCII",
        @"ISO Latin 2", @"Unicode", @"Cyrillic", @"Windows Latin 1", @"Greek", @"Turkish", @"Windows Latin 2", @"Mac OS Roman", nil];
    NSArray *encodings = [NSArray arrayWithObjects:[NSNumber numberWithInt:NSASCIIStringEncoding], [NSNumber numberWithInt:NSNEXTSTEPStringEncoding],
        [NSNumber numberWithInt:NSJapaneseEUCStringEncoding], [NSNumber numberWithInt:NSUTF8StringEncoding], [NSNumber numberWithInt:NSISOLatin1StringEncoding],
        [NSNumber numberWithInt:NSNonLossyASCIIStringEncoding], [NSNumber numberWithInt:NSISOLatin2StringEncoding], [NSNumber numberWithInt:NSUnicodeStringEncoding],
        [NSNumber numberWithInt:NSWindowsCP1251StringEncoding], [NSNumber numberWithInt:NSWindowsCP1252StringEncoding], [NSNumber numberWithInt:NSWindowsCP1253StringEncoding],
        [NSNumber numberWithInt:NSWindowsCP1254StringEncoding], [NSNumber numberWithInt:NSWindowsCP1250StringEncoding], [NSNumber numberWithInt:NSMacOSRomanStringEncoding], nil];
    
    NSAssert( [displayNames count] == [encodings count], @"Number of encoding names displayed does not match number of string encodings defined" );
    
    return [NSDictionary dictionaryWithObjectsAndKeys:displayNames, @"DisplayNames", encodings, @"StringEncodings", nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_autoCompletionDict release];
	[requiredFieldsForCiteKey release];
	[_formatters release];
    [_autocompletePunctuationCharacterSet release];
	[_finder release];
    [_errors release];
    [super dealloc];
}

- (void)awakeFromNib{

    [errorTableView setDoubleAction:@selector(gotoError:)];
    [openUsingFilterAccessoryView retain];
	[showHideCustomCiteStringsMenuItem setRepresentedObject:@"showHideCustomCiteMenuItem"];

	// register to observe when the preview needs to be updated (handle this here rather than on a per document basis as the preview is currently global for the application)
	[[NSNotificationCenter defaultCenter] addObserver:self
			selector:@selector(handlePreviewNeedsUpdate:)
			name:BDSKPreviewNeedsUpdateNotification
			object:nil];
        
        // Add a Scripts menu; should display the script graphic on 10.3+.  Searches in (mainbundle)/Contents/Scripts and (Library domains)/Application Support/Bibdesk/Scripts
        NSMenu *newMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@"Scripts"];
        OAScriptMenuItem *scriptItem = [[OAScriptMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Scripts" action:NULL keyEquivalent:@""];
        [scriptItem setSubmenu:newMenu];
        [newMenu release];
        [[NSApp mainMenu] insertItem:scriptItem atIndex:[[NSApp mainMenu] indexOfItemWithTitle:@"Help"]];
        [scriptItem release];
        [openTextEncodingPopupButton removeAllItems];
        [openTextEncodingPopupButton addItemsWithTitles:[[self encodingDefinitionDictionary] objectForKey:@"DisplayNames"]];

}



- (NSMenuItem*) displayMenuItem {
	return displayMenuItem;
}

- (void) setDisplayMenuItem:(NSMenuItem*) item {
	NSMenuItem * temp = displayMenuItem;
	displayMenuItem = [item retain];
	[temp release];
}
	

/*
 if the preview needs to be updated, get the first document and make it do the updating
*/
- (void) handlePreviewNeedsUpdate:(id)sender {
	BibDocument * firstDoc = [[NSApp orderedDocuments] objectAtIndex:0];
	if (firstDoc) {
		[firstDoc updatePreviews:nil];
	}
}



#pragma mark Overridden NSDocumentController methods

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem{
	SEL act = [menuItem action];

	if (act == @selector(toggleShowingPreviewPanel:)){ 
		// menu item for toggling the preview panel
		// set the on/off state according to the panel's visibility
		if ([[NSApp delegate] isShowingPreviewPanel]) {
			[menuItem setState:NSOnState];
		}
		else {
			[menuItem setState:NSOffState];
		}
		return ([[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKUsesTeXKey] intValue] == NSOnState);
	}

	return [super validateMenuItem:menuItem];
}


- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem {

	if ([[toolbarItem itemIdentifier] isEqualToString:PrvDocToolbarItemIdentifier]) {
		return ([[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKUsesTeXKey] intValue] == NSOnState);
	}
	
    return [super validateToolbarItem:toolbarItem];
}

- (IBAction)openDocument:(id)sender{
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAccessoryView:openTextEncodingAccessoryView];
		
	NSArray *types = [NSArray arrayWithObjects:@"bib", @"fcgi", @"ris", @"bdsk", nil];
	
	int result = [oPanel runModalForDirectory:nil
                                     file:nil
                                    types:types];
	if (result == NSOKButton) {
        NSString *fileToOpen = [oPanel filename];
        NSString *fileType = [fileToOpen pathExtension];
        
        if([fileType isEqualToString:@"bib"]){
            int index = [openTextEncodingPopupButton indexOfSelectedItem];
            NSStringEncoding encoding = [[[[self encodingDefinitionDictionary] objectForKey:@"StringEncodings"] objectAtIndex:index] intValue];
            [self openBibTeXFile:fileToOpen withEncoding:encoding];		
        }else{
            // handle other types in the usual way 
            // This ends up calling NSDocumentController makeDocumentWithContentsOfFile:ofType:
            // which calls NSDocument (here, most likely BibDocument) initWithContentsOfFile:ofType:
            [self openDocumentWithContentsOfFile:fileToOpen display:YES]; 
        }
	}
	
}

- (void)noteNewRecentDocument:(NSDocument *)aDocument{
    NSStringEncoding encoding = [(BibDocument *)aDocument documentStringEncoding];
    
    if(encoding == NSASCIIStringEncoding || encoding == [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKDefaultStringEncoding]){
        // NSLog(@"adding to recents list");
        [super noteNewRecentDocument:aDocument]; // only add it to the list of recent documents if it can be opened without manually selecting an encoding
    }
}
        

#pragma mark -

- (IBAction)openUsingFilter:(id)sender
{
    int result;
    NSString *fileToOpen = nil;
    NSString *shellCommand = nil;
    NSString *filterOutput = nil;
    BibDocument *bibDoc = nil;
    NSString *fileInputString = nil;
    
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAccessoryView:openUsingFilterAccessoryView];
    [oPanel setAllowsMultipleSelection:NO];
    result = [oPanel runModalForDirectory:nil
                                     file:nil
                                    types:nil];
    if (result == NSOKButton) {
        fileToOpen = [oPanel filename];
        shellCommand = [openUsingFilterTextField stringValue];
        fileInputString = [NSString stringWithContentsOfFile:fileToOpen];
        if (!fileInputString || [shellCommand isEqualToString:@""]){
            NSRunCriticalAlertPanel(NSLocalizedString(@"Problems Opening with Filter",@""),
                                    NSLocalizedString(@"Either we couldn't load the file or there was no shell command. Please try again.",@""),
                                    NSLocalizedString(@"OK",@""),
                                    nil, nil, nil, nil);
        }else{
			filterOutput = [[BDSKShellTask shellTask] runShellCommand:shellCommand
													  withInputString:fileInputString];
			// @@ REFACTOR:
			// I suppose in the future, bibTeX database won't be the default? 
			bibDoc = [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"bibTeX database" display:YES]; // #retain?
			[bibDoc loadDataRepresentation:[filterOutput dataUsingEncoding:NSUTF8StringEncoding] ofType:@"bibTeX database"];
			//[bibDoc updateChangeCount:NSChangeDone];
			[bibDoc updateUI];
		}
    }
}


- (void)openBibTeXFile:(NSString *)filePath withEncoding:(NSStringEncoding)encoding{
	
	NSData *data = [NSData dataWithContentsOfFile:filePath];
	BibDocument *doc = nil;
	
    // make a fresh document, and don't display it until we can set its name.
	doc = [self openUntitledDocumentOfType:@"bibTeX database" display:NO];
    [doc setFileName:filePath]; // this effectively makes it not an untitled document anymore.
    [doc showWindows];
    [doc loadBibTeXDataRepresentation:data encoding:encoding];
    [doc updateUI];  
    
}



#pragma mark Auto generation format stuff

- (NSArray *)requiredFieldsForCiteKey{
	return requiredFieldsForCiteKey;
}

- (NSArray *)setRequiredFieldsForCiteKey:(NSArray *)newFields{
	[requiredFieldsForCiteKey autorelease];
	requiredFieldsForCiteKey = [newFields retain];
}

- (NSArray *)requiredFieldsForLocalUrl{
	return requiredFieldsForLocalUrl;
}

- (NSArray *)setRequiredFieldsForLocalUrl:(NSArray *)newFields{
	[requiredFieldsForLocalUrl autorelease];
	requiredFieldsForLocalUrl = [newFields retain];
}


#pragma mark Auto-completion stuff

- (NSCharacterSet *)autoCompletePunctuationCharacterSet{
    return _autocompletePunctuationCharacterSet;
}

- (void)addString:(NSString *)string forCompletionEntry:(NSString *)entry{
    NSMutableArray *completionArray = nil;
    BOOL keyExists = [[_autoCompletionDict allKeys] containsObject:entry];
    // NSLog(@"got string %@ for entry %@", string, entry);
    
    if(string == nil) return; // shouldn't happen
    
    if (!keyExists) {
        completionArray = [NSMutableArray arrayWithCapacity:5];
        [_autoCompletionDict setObject:completionArray forKey:entry];
    }

    completionArray = [_autoCompletionDict objectForKey:entry];
    
    if([entry isEqualToString:@"Local-Url"] || [entry isEqualToString:@"Url"] || 
       [entry isEqualToString:@"Abstract"] || [entry isEqualToString:@"Annote"] ||
       [entry rangeOfString:@"Date"].location != NSNotFound ) return; // don't add these

    if([entry isEqualToString:@"Title"] || 
       [entry isEqualToString:@"Booktitle"] || 
       [entry isEqualToString:@"Publisher"]){ // add the whole string 
        [completionArray addObject:string];
        return;
    }
    if([entry isEqualToString:@"Author"]){
        [completionArray addObjectsFromArray:[string componentsSeparatedByString:@" and "]];
        return;
    }
    
    NSRange r = [string rangeOfCharacterFromSet:_autocompletePunctuationCharacterSet];
    
    if(r.location != NSNotFound){
        NSScanner *scanner = [[NSScanner alloc] initWithString:string];
        [scanner setCharactersToBeSkipped:nil];
        NSString *tmp = nil;

        while(![scanner isAtEnd]){
            [scanner scanUpToCharactersFromSet:_autocompletePunctuationCharacterSet intoString:&tmp];
            if(tmp != nil) 
		[completionArray addObject:tmp];
            [scanner scanCharactersFromSet:_autocompletePunctuationCharacterSet intoString:nil];
            [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
        }
        [scanner release];
    } else {
        [completionArray addObject:string];
    }
    
    // NSLog(@"completionArray is %@", [completionArray description]);
}

- (NSFormatter *)formatterForEntry:(NSString *)entry{
    BDSKFormCellFormatter *formatter = nil;
    formatter = [_formatters objectForKey:entry];
    if (formatter == nil) {
        formatter = [[BDSKFormCellFormatter alloc] init];
        [formatter setEntry:entry];
        [_formatters setObject:formatter forKey:entry];
        [formatter release];
    }
    return formatter;
}

- (NSArray *)stringsForCompletionEntry:(NSString *)entry{
	NSMutableArray* autoCompleteStrings = (NSMutableArray *)[_autoCompletionDict objectForKey:entry];
	if (autoCompleteStrings)
		return autoCompleteStrings; // why sort? [autoCompleteStrings sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	else 
		return nil;
}



- (IBAction)checkForUpdates:(id)sender{
    NSString *currVersionNumber = [[[NSBundle bundleForClass:[self class]]
        infoDictionary] objectForKey:@"CFBundleVersion"];

    NSDictionary *productVersionDict = [NSDictionary dictionaryWithContentsOfURL:
        [NSURL URLWithString:@"http://bibdesk.sourceforge.net/bibdesk-versions-xml.txt"]];

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

    if([latestVersionNumber caseInsensitiveCompare: currVersionNumber] != NSOrderedDescending)
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
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://bibdesk.sourceforge.net/"]];
        }
    }
    
}

- (IBAction)visitWebSite:(id)sender{
    if(![[NSWorkspace sharedWorkspace] openURL:
        [NSURL URLWithString:@"http://bibdesk.sourceforge.net/"]]){
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
        if([[NSFileManager defaultManager] fileExistsAtPath:[[_errors objectAtIndex:row] valueForKey:@"fileName"]]){
            return [[NSString stringWithFormat:@"%@", [[_errors objectAtIndex:row] valueForKey:@"fileName"]] lastPathComponent];
        }else{
            return NSLocalizedString(@"Paste or Drag data", @"Paste or Drag data");
        }
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
	[showHideErrorsMenuItem setState:NSOffState];
	//	[showHideErrorsMenuItem setTitle:NSLocalizedString(@"Show Errors",@"show errors - should be same as menu title in nib")];
}

- (IBAction)showErrorPanel:(id)sender{
    [errorPanel makeKeyAndOrderFront:sender];
	[showHideErrorsMenuItem setState:NSOnState];
	//[showHideErrorsMenuItem setTitle:NSLocalizedString(@"Hide Errors",@"hide errors")];
}

- (void)handleErrorNotification:(NSNotification *)notification{
    id errDict = [notification object];
    NSString *errorClass = [errDict valueForKey:@"errorClassName"];

    if (errorClass) {
        [_errors addObject:errDict];
		[NSObject cancelPreviousPerformRequestsWithTarget:self 
												 selector:@selector(updateErrorPanelUI)
												   object:nil];
		
		[self performSelector:@selector(updateErrorPanelUI)];
    }
}

- (void)updateErrorPanelUI{
	[errorTableView reloadData];
	NSLog(@"err panel");
	//[errorTableView scrollRowToVisible:[_errors count]];
	if ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShowWarningsKey]) {
		[self showErrorPanel:self];
		[showHideErrorsMenuItem setTitle:NSLocalizedString(@"Hide Errors",@"hide errors")];
	}
}

- (void)removeErrorObjsForFileName:(NSString *)fileName{
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
    
    
    NSRange errorRange;
    
    if([errObj valueForKey:@"lineNumber"] == [NSNull null]){
        errorRange = [[errObj valueForKey:@"errorRange"] rangeValue];
        [sourceEditTextView setSelectedRange:errorRange];
        [sourceEditTextView scrollRangeToVisible:errorRange];
        return;
    }
    
    
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


- (IBAction)toggleShowingPreviewPanel:(id)sender{
    if(!showingPreviewPanel){
		[self showPreviewPanel:sender];
    }else{
		[self hidePreviewPanel:sender];
    }    
}


- (IBAction)showPreviewPanel:(id)sender{
	[[BDSKPreviewer sharedPreviewer] showWindow:self];
	showingPreviewPanel = YES;
	[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:@"showing" forKey:@"BDSK Showing Preview Key"];
}

- (IBAction)hidePreviewPanel:(id)sender{
	[[[BDSKPreviewer sharedPreviewer] window] close];
	showingPreviewPanel = NO; // redundant.
	[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:@"not showing" forKey:@"BDSK Showing Preview Key"];
}


- (BOOL) isShowingPreviewPanel {
	return showingPreviewPanel;
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
        [self toggleShowingPreviewPanel:self];
    }
   
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    if( ([[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKLastVersionLaunched] == nil) ||
        (![versionString isEqualToString:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKLastVersionLaunched]]) ){
	[self showReadMeFile];
    }
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:versionString forKey:BDSKLastVersionLaunched];
  
}

- (void)showReadMeFile{
    [NSBundle loadNibNamed:@"ReadMe" owner:self];
    [readmeWindow makeKeyAndOrderFront:self];
    [readmeTextView replaceCharactersInRange:[readmeTextView selectedRange]
				     withRTF:[NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"README.rtf"]]];	
} 

#pragma mark || Service code

- (NSDictionary *)_constraintsFromString:(NSString *)string{
    NSScanner *scanner;
    NSMutableDictionary *searchConstraints = [NSMutableDictionary dictionary];
    NSString *queryString;
    NSMutableString *queryKey;
    NSCharacterSet *delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@":="];
    //NSCharacterSet *emptySet =  [NSCharacterSet characterSetWithCharactersInString:@""];
    NSCharacterSet *ampersandSet =  [NSCharacterSet characterSetWithCharactersInString:@"&"];

    scanner = [NSScanner scannerWithString:string];
    
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

    }else{
        // if it was at end, we are done, and we'll scan in the title:
        // items = [_finder itemsMatchingText:queryKey inKey:@"Title"];
        [searchConstraints setObject:queryKey forKey:@"Title"];
    }
    
    return searchConstraints;
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
	OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
    NSString *startCiteBracket = [sud stringForKey:BDSKCiteStartBracketKey];
    NSString *citeString = [NSString stringWithFormat:@"\\%@%@",[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKCiteStringKey],
		startCiteBracket];
	NSString *endCiteBracket = [sud stringForKey:BDSKCiteEndBracketKey]; 
	
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

    NSDictionary *searchConstraints = [self _constraintsFromString:pboardString];
    
    items = [_finder itemsMatchingConstraints:searchConstraints];
    
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
            [keys appendString:@","];
            [keys appendString:[key citeKey]];
            [commentString appendString:@"; "];
            [commentString appendString:[key citeKey]];
            [commentString appendString:@" = "];
            [commentString appendString:[key title]];
        }
        [keys appendString:endCiteBracket];
		[keys appendString:@" "];
        //        [keys appendString:@"%% "];
        // @@ commentString in service - let people set this as a pref? 
        //        [keys appendString:commentString];
        types = [NSArray arrayWithObject:NSStringPboardType];
        [pboard declareTypes:types owner:nil];

        yn = [pboard setString:keys forType:NSStringPboardType];
    }
    return;
}

- (void)completeCiteKeyFromSelection:(NSPasteboard *)pboard
                             userData:(NSString *)userData
                                error:(NSString **)error{

    NSArray *types = [pboard types];
    if (![types containsObject:NSStringPboardType]) {
        *error = NSLocalizedString(@"Error: couldn't complete text.",
                                   @"pboard couldn't give string.");
        return;
    }
    NSString *pboardString = [pboard stringForType:NSStringPboardType];
    NSArray *items = [_finder itemsMatchingCiteKey:pboardString];
    NSDictionary *itemDict = nil;
	BibItem *item = nil;
    NSMutableString *retStr = [NSMutableString string];
    BOOL yn = NO;    
    NSEnumerator *itemE = [items objectEnumerator];
    int count = [items count];
    
    while(itemDict = [itemE nextObject]){
		item = [itemDict objectForKey:@"BibItem"];
        [retStr appendString:[item citeKey]];
        if(count > 1)
            [retStr appendString:@" "];
    }
    
    types = [NSArray arrayWithObject:NSStringPboardType];
    [pboard declareTypes:types owner:nil];
    yn = [pboard setString:retStr forType:NSStringPboardType];
}

- (void)showPubWithKey:(NSPasteboard *)pboard
			  userData:(NSString *)userData
				 error:(NSString **)error{	
    NSArray *types = [pboard types];
    if (![types containsObject:NSStringPboardType]) {
        *error = NSLocalizedString(@"Error: couldn't complete text.",
                                   @"pboard couldn't give string.");
        return;
    }
    NSString *pboardString = [pboard stringForType:NSStringPboardType];
    NSArray *items = [_finder itemsMatchingCiteKey:pboardString];
	NSDictionary *itemDict = nil;
	BibItem *item;
	BibDocument *doc = nil;
	NSEnumerator *itemE = [items objectEnumerator];
    
    while(itemDict = [itemE nextObject]){
		doc = [itemDict objectForKey:@"BibDocument"];
		item = [itemDict objectForKey:@"BibItem"];
		[doc editPub:item];
    }
    
//    types = [NSArray arrayWithObject:NSStringPboardType];
//    [pboard declareTypes:types owner:nil];
//    yn = [pboard setString:retStr forType:NSStringPboardType];
	
}

- (void)importDataFromSelection:(NSPasteboard *)pboard
	      userData:(NSString *)userData
		 error:(NSString **)error{	
    NSArray *types = [pboard types];
    if (![types containsObject:NSStringPboardType]) {
        *error = NSLocalizedString(@"Error: couldn't read data from string.",
                                   @"pboard couldn't give string.");
        return;
    }
    NSString *pboardString = [pboard stringForType:NSStringPboardType];    

    BibDocument *doc = [[[BibDocument alloc] init] autorelease];
    
    [doc loadPubMedDataRepresentation:[pboardString dataUsingEncoding:NSUTF8StringEncoding]];
    [[NSDocumentController sharedDocumentController] setShouldCreateUI:YES];
    [[NSDocumentController sharedDocumentController] addDocument:doc];
    [doc makeWindowControllers];
    [doc showWindows];
}


/* ssp: 2004-07-18
Implements service to import selection
*/
- (void)addPublicationsFromSelection:(NSPasteboard *)pboard
						   userData:(NSString *)userData
							  error:(NSString **)error{	
	
	// add to the frontmost bibliography
	BibDocument * doc = [[NSApp orderedDocuments] objectAtIndex:0];
    if (!doc) {
		// if there are no open documents, give an error. 
		// Or rather create a new document and add the entry there? Would anybody want that?
		*error = NSLocalizedString(@"Error: No open document", @"Bibdesk couldn't import the selected information because there is no open bibliography file to add it to. Please create or open a bibliography file and try again.");
		return;
	}
	
	[doc addPublicationsFromPasteboard:pboard error:error];
}

@end

@implementation NSFileManager (BibDeskAdditions)

- (NSString *)applicationSupportDirectory:(SInt16)domain{
    FSRef foundRef;
    OSStatus err = noErr;

    err = FSFindFolder(domain,
                       kApplicationSupportFolderType,
                       kCreateFolder,
                       &foundRef);
    NSAssert1( err == noErr, @"Error %d:  the system was unable to find your Application Support folder.", err);
    
    CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &foundRef);
    
    if(url != nil){
        return [(NSURL *)url path];
    } else {
        return nil; 
    }
}
                             

@end
