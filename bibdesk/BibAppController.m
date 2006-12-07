//  BibAppController.m

//  Created by Michael McCracken on Sat Jan 19 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005
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

#import "BibItem.h"
#import "BibAppController.h"
#import "BibPrefController.h"
#import "BDSKPreviewer.h"
#import "BibDocument.h"
#import "BibDocumentView_Toolbar.h"
#import "NSTextView_BDSKExtensions.h"
#import "NSString_BDSKExtensions.h"
#import "BDSKConverter.h"
#import "BDSKTypeInfoEditor.h"
#import "BDSKCharacterConversion.h"
#import "BDSKFindController.h"
#import "BDSKFormCellFormatter.h"
#import "BDSKCiteKeyFormatter.h"
#import "OFVersionNumber.h"

#import <Carbon/Carbon.h>

@implementation BibAppController

+ (void)initialize
{
    BOOL isDir;
    NSString *applicationSupportPath;
    NSFileManager *DFM = [NSFileManager defaultManager];
    
    // since Quartz.framework doesn't exist on < 10.4, we can't link against it
    // http://www.cocoabuilder.com/archive/message/cocoa/2004/1/31/99969
    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3){}
    else
        [[NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"Tiger" ofType:@"bundle"]] load];

#ifdef USECRASHREPORTER
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
    if(![DFM fileExistsAtPath:[applicationSupportPath stringByAppendingPathComponent:@"previewtemplate.tex"]]){
        // copy previewtemplate.tex file (user-modifiable):
        [DFM copyPath:[[NSBundle mainBundle] pathForResource:@"previewtemplate" ofType:@"tex"]
               toPath:[applicationSupportPath stringByAppendingPathComponent:@"previewtemplate.tex"] handler:nil];
    }else{
		// make sure we use the <<File>> template for the filename
		NSMutableString *texTemplate = [[NSMutableString alloc] initWithContentsOfFile:[applicationSupportPath stringByAppendingPathComponent:@"previewtemplate.tex"]];
		[texTemplate replaceOccurrencesOfString:@"\\bibliography{bibpreview}" withString:@"\\bibliography{<<File>>}" options:NSCaseInsensitiveSearch range:NSMakeRange(0,[texTemplate length])];
		[[texTemplate dataUsingEncoding:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKTeXPreviewFileEncodingKey]] writeToFile:[applicationSupportPath stringByAppendingPathComponent:@"previewtemplate.tex"] atomically:YES];
		[texTemplate release];
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
    }if(![DFM fileExistsAtPath:[applicationSupportPath stringByAppendingPathComponent:@"BD Test.scpt"]]){
        // copy test script:
        [DFM copyPath:[[NSBundle mainBundle] pathForResource:@"BD Test" ofType:@"scpt"]
               toPath:[applicationSupportPath stringByAppendingPathComponent:@"BD Test.scpt"] handler:nil];
    }

    [NSApp registerServicesMenuSendTypes:[NSArray arrayWithObjects:NSStringPboardType,nil] returnTypes:[NSArray arrayWithObjects:NSStringPboardType,nil]];
    if([[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:@"NSToolbar Configuration OAPreferences"] != nil){
	[[OFPreferenceWrapper sharedPreferenceWrapper] removeObjectForKey:@"NSToolbar Configuration OAPreferences"];
    }
    
    const char *bundlePath = [[[NSBundle mainBundle] bundlePath] fileSystemRepresentation];
    FSRef bundleRef;
    OSStatus err = FSPathMakeRef((const UInt8 *)bundlePath, &bundleRef, NULL);
    if(err){
        NSLog(@"error %d occurred while trying to find bundle %s", err, bundlePath);
    } else {
        err = AHRegisterHelpBook(&bundleRef);
        if(err) NSLog(@"error %d occurred while trying to register help book for %s", err, bundlePath);
    }
    
    // removed this functionality in 0.99
    [[OFPreferenceWrapper sharedPreferenceWrapper] setBool:NO forKey:BDSKUseUnicodeBibTeXParserKey];
}

- (id)init
{
    if(self = [super init]){
        acLock = [[NSLock alloc] init];
        autoCompletionDict = [[NSMutableDictionary alloc] initWithCapacity:15]; // arbitrary
	 	formatters = [[NSMutableDictionary alloc] initWithCapacity:15]; // arbitrary
        autocompletePunctuationCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@",:;"] retain];
        requiredFieldsForCiteKey = nil;
        requiredFieldsForLocalUrl = nil;
        
        metadataCacheLock = [[NSLock alloc] init];
        metadataMessageQueue = [[OFMessageQueue alloc] init];
        [metadataMessageQueue startBackgroundProcessors:1];
        canWriteMetadata = YES;
				
		NSString *formatString = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKCiteKeyFormatKey];
		NSString *error = nil;
		int button = 0;
		
		if ([[BDSKFormatParser sharedParser] validateFormat:&formatString forField:BDSKCiteKeyString inFileType:BDSKBibtexString error:&error]) {
			[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:formatString forKey:BDSKCiteKeyFormatKey];
			[self setRequiredFieldsForCiteKey: [[BDSKFormatParser sharedParser] requiredFieldsForFormat:formatString]];
		}else{
			button = NSRunCriticalAlertPanel(NSLocalizedString(@"The autogeneration format for Cite Key is invalid.", @""), 
											 @"%@",
											 NSLocalizedString(@"Go to Preferences", @""), 
											 NSLocalizedString(@"Revert to Default", @""), 
											 nil, error, nil);
			if (button == NSAlertAlternateReturn){
				formatString = [[[OFPreferenceWrapper sharedPreferenceWrapper] preferenceForKey:BDSKCiteKeyFormatKey] defaultObjectValue];
                [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:formatString forKey:BDSKCiteKeyFormatKey];
				[self setRequiredFieldsForCiteKey: [[BDSKFormatParser sharedParser] requiredFieldsForFormat:formatString]];
			}else{
				[[OAPreferenceController sharedPreferenceController] showPreferencesPanel:self];
				[[OAPreferenceController sharedPreferenceController] setCurrentClientByClassName:@"BibPref_CiteKey"];
			}
		}
		
		formatString = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKLocalUrlFormatKey];
		error = nil;
		
		if ([[BDSKFormatParser sharedParser] validateFormat:&formatString forField:BDSKLocalUrlString inFileType:BDSKBibtexString error:&error]) {
			[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:formatString forKey:BDSKLocalUrlFormatKey];
			[self setRequiredFieldsForLocalUrl: [[BDSKFormatParser sharedParser] requiredFieldsForFormat:formatString]];
		}else{
			button = NSRunCriticalAlertPanel(NSLocalizedString(@"The autogeneration format for Local-Url is invalid.", @""), 
											 @"%@",
											 NSLocalizedString(@"Go to Preferences", @""), 
											 NSLocalizedString(@"Revert to Default", @""), 
											 nil, error, nil);
			if (button == NSAlertAlternateReturn){
				formatString = [[[OFPreferenceWrapper sharedPreferenceWrapper] preferenceForKey:BDSKLocalUrlFormatKey] defaultObjectValue];			
				[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:formatString forKey:BDSKLocalUrlFormatKey];
				[self setRequiredFieldsForLocalUrl: [[BDSKFormatParser sharedParser] requiredFieldsForFormat:formatString]];
			}else{
				[[OAPreferenceController sharedPreferenceController] showPreferencesPanel:self];
				[[OAPreferenceController sharedPreferenceController] setCurrentClientByClassName:@"BibPref_AutoFile"];
			}
		}
		
		NSMutableArray *localFileFields = [[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKLocalFileFieldsKey] mutableCopy];
		NSMutableArray *remoteURLFields = [[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKRemoteURLFieldsKey] mutableCopy];
		if(![localFileFields containsObject:BDSKLocalUrlString]){
			[localFileFields insertObject:BDSKLocalUrlString atIndex:0];
			[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:localFileFields forKey:BDSKLocalFileFieldsKey];
		}
		if(![remoteURLFields containsObject:BDSKUrlString]){
			[remoteURLFields insertObject:BDSKUrlString atIndex:0];
			[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:remoteURLFields forKey:BDSKRemoteURLFieldsKey];
		}
		[localFileFields release];
		[remoteURLFields release];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [autoCompletionDict release];
	[requiredFieldsForCiteKey release];
	[formatters release];
    [autocompletePunctuationCharacterSet release];
    [acLock release];
    [metadataCacheLock release];
    [metadataMessageQueue release];
    [super dealloc];
}


#pragma mark Application launching

- (void)awakeFromNib{

    [openUsingFilterAccessoryView retain];
	[showHideCustomCiteStringsMenuItem setRepresentedObject:@"showHideCustomCiteMenuItem"];
	[self updateColumnsMenu];

	// register to observe when the columns change, to update the columns menu
	[[NSNotificationCenter defaultCenter] addObserver:self
			selector:@selector(handleTableColumnsChangedNotification:)
			name:BDSKTableColumnChangedNotification
			object:nil];
	
	[openTextEncodingPopupButton removeAllItems];
	[openTextEncodingPopupButton addItemsWithTitles:[[BDSKStringEncodingManager sharedEncodingManager] availableEncodingDisplayedNames]];

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
    
    // Add a Scripts menu; should display the script graphic on 10.3+.  Searches in (mainbundle)/Contents/Scripts and (Library domains)/Application Support/BibDesk/Scripts
    // ARM:  if we add this in -awakeFromNib, we get another script menu each time we show release notes or readme; whatever.
    NSString *scriptMenuTitle = NSLocalizedString(@"Scripts", @"title of scripts menu, which only shows on 10.2");
    NSMenu *newMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:scriptMenuTitle];
    OAScriptMenuItem *scriptItem = [[OAScriptMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:scriptMenuTitle action:NULL keyEquivalent:@""];
    [scriptItem setSubmenu:newMenu];
    [newMenu release];
    [[NSApp mainMenu] insertItem:scriptItem atIndex:[[NSApp mainMenu] indexOfItemWithTitle:@"Help"]];
    [scriptItem release];
    
    
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    if([[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKLastVersionLaunchedKey] == nil) // show new users the readme file; others just see the release notes
        [self showReadMeFile:nil];
    if(![versionString isEqualToString:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKLastVersionLaunchedKey]])
        [self showRelNotes:nil];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:versionString forKey:BDSKLastVersionLaunchedKey];
    
    if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKAutoCheckForUpdatesKey])
		[NSThread detachNewThreadSelector:@selector(checkForUpdatesInBackground) toTarget:self withObject:nil];
    
	
	if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShowingPreviewKey])
		[[BDSKPreviewer sharedPreviewer] showPreviewPanel:self];
}

- (IBAction)showReadMeFile:(id)sender{
    [NSBundle loadNibNamed:@"ReadMe" owner:self];
    [readmeWindow setTitle:NSLocalizedString(@"ReadMe", "ReadMe")];
    [readmeWindow makeKeyAndOrderFront:self];
    [readmeTextView setString:@""];
    [readmeTextView replaceCharactersInRange:[readmeTextView selectedRange]
                                     withRTF:[NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"README.rtf"]]];	
}

- (IBAction)showRelNotes:(id)sender{
    [NSBundle loadNibNamed:@"ReadMe" owner:self];
    [readmeWindow setTitle:NSLocalizedString(@"Release Notes", "Release Notes")];
    [readmeWindow makeKeyAndOrderFront:self];
    [readmeTextView setString:@""];
    [readmeTextView replaceCharactersInRange:[readmeTextView selectedRange]
                                     withRTF:[NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"RelNotes.rtf"]]];
}

#pragma mark -

- (NSString *)temporaryBaseDirectoryCreating:(BOOL)create{
	static NSString *temporaryDirectory = nil;
	
	if (!temporaryDirectory && create) {
		temporaryDirectory = [[[NSFileManager defaultManager] uniqueFilePath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"bibdesk"] 
															 createDirectory:YES] retain];
	}
	return temporaryDirectory;
}

- (NSString *)temporaryFilePath:(NSString *)fileName createDirectory:(BOOL)create{
	if(!fileName)
		fileName = [[NSProcessInfo processInfo] globallyUniqueString];
	NSString *tmpFilePath = [[self temporaryBaseDirectoryCreating:YES] stringByAppendingPathComponent:fileName];
	return [[NSFileManager defaultManager] uniqueFilePath:tmpFilePath 
										  createDirectory:create];
}

- (NSMenuItem*) displayMenuItem {
	return displayMenuItem;
}

- (IBAction)showFindPanel:(id)sender{
    [[BDSKFindController sharedFindController] showWindow:self];
}

- (void)updateColumnsMenu{
	NSArray *prefsShownColNamesArray = [[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKShownColsNamesKey];
    NSEnumerator *shownColNamesE = [prefsShownColNamesArray reverseObjectEnumerator];
	NSString *colName;
    NSMenu *columnsMenu = [displayMenuItem submenu];
	NSMenuItem *item = nil;
	
	
	// remove the add-items, and remember the extra ones, corrsponding to removed columns
	while(![[columnsMenu itemAtIndex:0] isSeparatorItem]){
		[columnsMenu removeItemAtIndex:0];
	}
	
	// next add all the shown columns in the order they are shown
	while(colName = [shownColNamesE nextObject]){
        item = [[[NSMenuItem alloc] initWithTitle:colName 
                                           action:@selector(columnsMenuSelectTableColumn:)
                                    keyEquivalent:@""] autorelease];
		[item setState:NSOnState];
		[columnsMenu insertItem:item atIndex:0];
	}
}
	
- (void)handleTableColumnsChangedNotification:(NSNotification *)notification {
	[self updateColumnsMenu];
}


#pragma mark Overridden NSDocumentController methods

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem{
	SEL act = [menuItem action];

	if (act == @selector(toggleShowingPreviewPanel:)){ 
		// menu item for toggling the preview panel
		// set the on/off state according to the panel's visibility
		if ([[[BDSKPreviewer sharedPreviewer] window] isVisible]) {
			[menuItem setState:NSOnState];
		}else {
			[menuItem setState:NSOffState];
		}
		return YES;
	}
	else if (act == @selector(toggleShowingErrorPanel:)){ 
		// menu item for toggling the error panel
		// set the on/off state according to the panel's visibility
		if ([[[BDSKErrorObjectController sharedErrorObjectController] window] isVisible]) {
			[menuItem setState:NSOnState];
		}else {
			[menuItem setState:NSOffState];
		}
		return YES;
	}

	return [super validateMenuItem:menuItem];
}


- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem {

	if ([[toolbarItem itemIdentifier] isEqualToString:PrvDocToolbarItemIdentifier]) {
		return ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKUsesTeXKey]);
	}
	
    return [super validateToolbarItem:toolbarItem];
}

- (IBAction)newBDSKLibrary:(id)sender{
	id doc = [self openUntitledDocumentOfType:@"BibDesk Library" display:YES];
}

- (void)openDocumentUsingPhonyCiteKeys:(BOOL)phony{
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAccessoryView:openTextEncodingAccessoryView];
    NSString *defaultEncName = [[BDSKStringEncodingManager sharedEncodingManager] displayedNameForStringEncoding:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKDefaultStringEncodingKey]];
    [openTextEncodingPopupButton selectItemWithTitle:defaultEncName];
		
	NSArray *types = [NSArray arrayWithObjects:@"bib", @"fcgi", @"ris", @"bdsk", nil];
	
	int result = [oPanel runModalForDirectory:nil
                                     file:nil
                                    types:types];
	if (result == NSOKButton) {
        NSString *fileToOpen = [oPanel filename];
        NSString *fileType = [fileToOpen pathExtension];
        NSStringEncoding encoding = [[BDSKStringEncodingManager sharedEncodingManager] stringEncodingForDisplayedName:[openTextEncodingPopupButton titleOfSelectedItem]];

        if([fileType isEqualToString:@"bib"] && !phony){
            [self openBibTeXFile:fileToOpen withEncoding:encoding];		
        } else if([fileType isEqualToString:@"ris"] || [fileType isEqualToString:@"fcgi"]){
            [self openRISFile:fileToOpen withEncoding:encoding];
        } else if([fileType isEqualToString:@"bib"] && phony){
            [self openBibTeXFileUsingPhonyCiteKeys:fileToOpen withEncoding:encoding];
        } else {
            // handle other types in the usual way 
            // This ends up calling NSDocumentController makeDocumentWithContentsOfFile:ofType:
            // which calls NSDocument (here, most likely BibDocument) initWithContentsOfFile:ofType:
            [self openDocumentWithContentsOfFile:fileToOpen display:YES]; 
        }
	}
	
}

- (IBAction)openDocument:(id)sender{
    [self openDocumentUsingPhonyCiteKeys:NO];
}

- (IBAction)importDocumentUsingPhonyCiteKeys:(id)sender{
    [self openDocumentUsingPhonyCiteKeys:YES];
}

- (void)noteNewRecentDocument:(NSDocument *)aDocument{
    
    if(! [aDocument isKindOfClass:[BibDocument class]]){
        // we don't worry about string encodings for BibLibrary files.
        return;
    }
    
    NSStringEncoding encoding = [(BibDocument *)aDocument documentStringEncoding];
    
    if(encoding == NSASCIIStringEncoding || encoding == [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKDefaultStringEncodingKey]){
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
    NSMutableArray *commandHistory = [NSMutableArray arrayWithArray:[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKFilterFieldHistoryKey]];
    [openUsingFilterComboBox addItemsWithObjectValues:commandHistory];
    if([commandHistory count]){
        [openUsingFilterComboBox selectItemAtIndex:0];
        [openUsingFilterComboBox setObjectValue:[openUsingFilterComboBox objectValueOfSelectedItem]];
    }
    result = [oPanel runModalForDirectory:nil
                                     file:nil
                                    types:nil];
    if (result == NSOKButton) {
        fileToOpen = [oPanel filename];
        shellCommand = [openUsingFilterComboBox stringValue];
        // this is for command history reordering in the combo box; bumps the current command to the top of the stack and limits the history size to 7
        BOOL reorder = NO;
        int previousIndex = 0;
        
        if([[openUsingFilterComboBox objectValues] containsObject:shellCommand]){
            reorder = YES;
            previousIndex = [openUsingFilterComboBox indexOfItemWithObjectValue:shellCommand];
        }
        
        [openUsingFilterComboBox insertItemWithObjectValue:shellCommand atIndex:0];
        if(reorder){
            [openUsingFilterComboBox removeItemAtIndex:(previousIndex + 1)];
        }
        if([[openUsingFilterComboBox objectValues] count] >= 7){
            [openUsingFilterComboBox removeItemAtIndex:6];
        }
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:[openUsingFilterComboBox objectValues] forKey:BDSKFilterFieldHistoryKey];
        
        fileInputString = [NSString stringWithContentsOfFile:fileToOpen];
        if ([NSString isEmptyString:fileInputString]){
            NSRunCriticalAlertPanel(NSLocalizedString(@"Problems Opening with Filter",@""),
                                    NSLocalizedString(@"Either we couldn't load the file or there was no shell command. Please try again.",@""),
                                    NSLocalizedString(@"OK",@""),
                                    nil, nil, nil, nil);
        }else{
			filterOutput = [[BDSKShellTask shellTask] runShellCommand:shellCommand
													  withInputString:fileInputString];
			// @@ REFACTOR:
			// I suppose in the future, bibTeX database won't be the default? 
			bibDoc = [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"bibTeX database" display:YES];
			[bibDoc loadDataRepresentation:[filterOutput dataUsingEncoding:NSUTF8StringEncoding] ofType:@"bibTeX database"];
            [bibDoc updateChangeCount:NSChangeDone]; // imported files are unsaved
		}
    }
}


- (void)openBibTeXFile:(NSString *)filePath withEncoding:(NSStringEncoding)encoding{
	
	NSData *data = [NSData dataWithContentsOfFile:filePath];
	BibDocument *doc = nil;
	
    // make a fresh document, and don't display it until we can set its name.
    doc = [self openUntitledDocumentOfType:@"bibTeX database" display:NO];
    [doc setFileName:filePath]; // this effectively makes it not an untitled document anymore.
    [doc setFileType:@"bibTeX database"];  // this looks redundant, but it's necessary to enable saving the file (at least on AppKit == 10.3)
    [doc loadBibTeXDataRepresentation:data encoding:encoding];
    [doc showWindows];
    
}

- (void)openRISFile:(NSString *)filePath withEncoding:(NSStringEncoding)encoding{
	
	NSData *data = [NSData dataWithContentsOfFile:filePath];
	BibDocument *doc = nil;
	
    // make a fresh document, and don't display it until we can set its name.
    doc = [self openUntitledDocumentOfType:@"RIS/Medline File" display:NO];
    [doc setFileName:filePath]; // this effectively makes it not an untitled document anymore.
    [doc setFileType:@"RIS/Medline File"];  // this looks redundant, but it's necessary to enable saving the file (at least on AppKit == 10.3)
    [doc loadRISDataRepresentation:data encoding:encoding];
    [doc showWindows];
    
}

- (void)openBibTeXFileUsingPhonyCiteKeys:(NSString *)filePath withEncoding:(NSStringEncoding)encoding{
	NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSString *stringFromFile = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];

    // (@[a-z]+{),?([[:cntrl:]]) will grab either "@type{,eol" or "@type{eol", which is what we get
    // from Bookends and EndNote, respectively.
    AGRegex *theRegex = [AGRegex regexWithPattern:@"(@[a-z]+{),?([[:cntrl:]])" options:AGRegexCaseInsensitive];

    // replace with "@type{FixMe,eol" (add the comma in, since we remove it if present)
    stringFromFile = [theRegex replaceWithString:@"$1FixMe,$2" inString:stringFromFile];
    data = [stringFromFile dataUsingEncoding:encoding];
    
	BibDocument *doc = nil;
	
    // make a fresh document, and don't display it until we can set its name.
    doc = [self openUntitledDocumentOfType:@"bibTeX database" display:NO];
    [doc setFileName:nil]; // untitled document
    [doc setFileType:@"bibTeX database"];  // this looks redundant, but it's necessary to enable saving the file (at least on AppKit == 10.3)
    BOOL success = [doc loadBibTeXDataRepresentation:data encoding:encoding];
    [doc showWindows];
    
    if(success){
        // search so we only see the ones that have the temporary key
        [doc performSelector:@selector(setSelectedSearchFieldKey:) withObject:BDSKCiteKeyString];
        [doc performSelector:@selector(setFilterField:) withObject:@"FixMe"];
        NSBeginAlertSheet(NSLocalizedString(@"Temporary Cite Keys.",@""), 
                          nil, nil, nil, // buttons
                          [[[doc windowControllers] objectAtIndex:0] window],
                          nil,
                          nil,
                          nil,
                          nil,
                          NSLocalizedString(@"This document was opened using a temporary cite key for the publications shown.  In order to use your file with BibTeX, you should generate valid cite keys for all of the items in this file.", @""));
    }
    
}

    

#pragma mark Auto generation format stuff

- (NSArray *)requiredFieldsForCiteKey{
	return requiredFieldsForCiteKey;
}

- (void)setRequiredFieldsForCiteKey:(NSArray *)newFields{
	[requiredFieldsForCiteKey autorelease];
	requiredFieldsForCiteKey = [newFields retain];
}

- (NSArray *)requiredFieldsForLocalUrl{
	return requiredFieldsForLocalUrl;
}

- (void)setRequiredFieldsForLocalUrl:(NSArray *)newFields{
	[requiredFieldsForLocalUrl autorelease];
	requiredFieldsForLocalUrl = [newFields retain];
}


#pragma mark Auto-completion stuff

- (NSCharacterSet *)autoCompletePunctuationCharacterSet{
    return autocompletePunctuationCharacterSet;
}

- (void)addString:(NSString *)string forCompletionEntry:(NSString *)entry{
    OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];
	NSMutableArray *completionArray = nil;
    BOOL keyExists = [(NSMutableArray *)[autoCompletionDict allKeysUsingLock:acLock] containsObject:entry usingLock:acLock];
    // NSLog(@"got string %@ for entry %@", string, entry);
    
    if(string == nil) return; // shouldn't happen
    
    if (!keyExists) {
        completionArray = [NSMutableArray arrayWithCapacity:5];
        [autoCompletionDict setObject:completionArray forKey:entry usingLock:acLock];
    }

    completionArray = [autoCompletionDict objectForKey:entry usingLock:acLock];
    
    if([entry isEqualToString:BDSKAbstractString] || [entry isEqualToString:BDSKAnnoteString] ||
       [entry isEqualToString:BDSKVolumeString] || [entry isEqualToString:BDSKPagesString] ||
       [entry isEqualToString:BDSKYearString] || [entry isEqualToString:BDSKNumberString] ||
       [[pw stringArrayForKey:BDSKLocalFileFieldsKey] containsObject:entry] || 
	   [[pw stringArrayForKey:BDSKRemoteURLFieldsKey] containsObject:entry] || 
       [entry rangeOfString:BDSKDateString].location != NSNotFound ) return; // don't add these

    if([entry isEqualToString:BDSKTitleString] || 
       [entry isEqualToString:BDSKBooktitleString] || 
       [entry isEqualToString:BDSKPublisherString]){ // add the whole string 
        [completionArray addObject:string usingLock:acLock];
        return;
    }
    if([entry isEqualToString:BDSKAuthorString]){
        [completionArray addObjectsFromArray:[string componentsSeparatedByString:@" and "] usingLock:acLock];
        return;
    }
    
    // NSScanner is very slow with complex strings, so we'll copy the expanded value
    if([string isComplex])
        string = [NSString stringWithString:string];
    
    NSRange r = [string rangeOfCharacterFromSet:autocompletePunctuationCharacterSet];
    static NSCharacterSet *wsCharSet = nil;
    if(wsCharSet == nil)
        wsCharSet = [[NSCharacterSet whitespaceCharacterSet] retain];
    static NSCharacterSet *invertedPunctuationSet = nil;
    if(invertedPunctuationSet == nil)
        invertedPunctuationSet = [[autocompletePunctuationCharacterSet invertedSet] retain];
    
    if(r.location != NSNotFound){
        [acLock lock];
        NSScanner *scanner = [[NSScanner alloc] initWithString:string];
        [scanner setCharactersToBeSkipped:nil];
        NSString *tmp = nil;

        while(![scanner isAtEnd]){
            [scanner scanUpToCharactersFromSet:autocompletePunctuationCharacterSet intoString:&tmp];
            if(tmp != nil) 
                [completionArray addObject:tmp]; // we have the lock, so don't use the locking method here
            [scanner scanUpToCharactersFromSet:invertedPunctuationSet intoString:nil];
            [scanner scanCharactersFromSet:wsCharSet intoString:nil];
        }
        [scanner release];
        [acLock unlock];
    } 
    else if([entry isEqualToString:BDSKKeywordsString]){
        // if it wasn't punctuated, try this; Elsevier uses "and" as a separator, and it's annoying to have the whole string autocomplete on you
        [completionArray addObjectsFromArray:[string componentsSeparatedByString:@" and "]];
    } 
    else {
        [completionArray addObject:string usingLock:acLock];
    }
    
    // NSLog(@"completionArray is %@", [completionArray description]);
}

- (NSFormatter *)formatterForEntry:(NSString *)entry{
    NSFormatter *formatter = [formatters objectForKey:entry];
    if (formatter == nil) {
		if ([entry isEqualToString:BDSKCrossrefString]) {
			formatter = [[BDSKCiteKeyFormatter alloc] init]; // a crossref field is a cite key
		} else {
			formatter = [[BDSKFormCellFormatter alloc] initWithEntry:entry];
        }
		[formatters setObject:formatter forKey:entry];
        [formatter release];
    }
    return formatter;
}

- (NSArray *)stringsForCompletionEntry:(NSString *)entry{
    NSMutableArray* autoCompleteStrings = (NSMutableArray *)[autoCompletionDict objectForKey:entry usingLock:acLock];
	if (autoCompleteStrings)
		return autoCompleteStrings; // why sort? [autoCompleteStrings sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	else 
		return nil;
}

#pragma mark Panels

- (void)checkForUpdatesInBackground{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if(![NSThread setThreadPriority:0])
        NSLog(@"failed to set update check thread priority");
    
    NSString *currVersionNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        
    NSURL *theURL = [NSURL URLWithString:@"http://bibdesk.sourceforge.net/bibdesk-versions-xml.txt"];
    CFDataRef theData = NULL;
    SInt32 status;
    
    if(CFURLCreateDataAndPropertiesFromResource(kCFAllocatorDefault,
                                                (CFURLRef)theURL,
                                                &theData,
                                                NULL,
                                                NULL,
                                                &status))
    {
        NSString *err = nil;
        NSDictionary *prodVersionDict = [NSPropertyListSerialization propertyListFromData:(NSData *)theData
                                                                         mutabilityOption:NSPropertyListImmutable
                                                                                   format:NULL
                                                                         errorDescription:&err];
        if(theData != NULL) CFRelease(theData);
        
        NSString *latestVersionNumber = [prodVersionDict valueForKey:@"BibDesk"];
        if(prodVersionDict != nil){
            OFVersionNumber *remoteVersion = [[OFVersionNumber alloc] initWithVersionString:latestVersionNumber];
            OFVersionNumber *localVersion = [[OFVersionNumber alloc] initWithVersionString:currVersionNumber];
            
            if([remoteVersion compareToVersionNumber:localVersion] == NSOrderedDescending)
                [[OFMessageQueue mainQueue] queueSelector:@selector(displayUpdateAvailableWindow:) forObject:self withObject:latestVersionNumber];
            
            [remoteVersion release];
            [localVersion release];
        }
    }
    [pool release];
    
}

- (void)displayUpdateAvailableWindow:(NSString *)latestVersionNumber{
    int button;
    button = NSRunAlertPanel(NSLocalizedString(@"A New Version is Available",
                                               @"Alert when new version is available"),
                             [NSString stringWithFormat:
                                 NSLocalizedString(@"A new version of BibDesk is available (version %@). Would you like to download the new version now?",
                                                   @"format string asking if the user would like to get the new version"), latestVersionNumber],
                             NSLocalizedString(@"OK",@"OK"), 
                             NSLocalizedString(@"Cancel",@"Cancel"), nil);
    if (button == NSOKButton) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://bibdesk.sourceforge.net/"]];
    }
    
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
    
    OFVersionNumber *remoteVersion = [[OFVersionNumber alloc] initWithVersionString:latestVersionNumber];
    OFVersionNumber *localVersion = [[OFVersionNumber alloc] initWithVersionString:currVersionNumber];
    
    if([remoteVersion compareToVersionNumber:localVersion] == NSOrderedDescending)
    {
        // tell user to download a new version
        [self displayUpdateAvailableWindow:latestVersionNumber];
    }
    else
    {
        // tell user software is up to date
        NSRunAlertPanel(NSLocalizedString(@"BibDesk is up-to-date",
                                          @"Title of alert when a the user's software is up to date."),
                        NSLocalizedString(@"You have the most recent version of BibDesk.",
                                          @"Alert text when the user's software is up to date."),
                        NSLocalizedString(@"OK", @"OK"), nil, nil);                
    }
    [remoteVersion release];
    [localVersion release];
    
}

- (IBAction)visitWebSite:(id)sender{
    if(![[NSWorkspace sharedWorkspace] openURL:
        [NSURL URLWithString:@"http://bibdesk.sourceforge.net/"]]){
        NSBeep();
    }
}

- (IBAction)showPreferencePanel:(id)sender{
    [[OAPreferenceController sharedPreferenceController] showPreferencesPanel:sender];
}

- (IBAction)toggleShowingErrorPanel:(id)sender{
    [[BDSKErrorObjectController sharedErrorObjectController] toggleShowingErrorPanel:sender];
}

- (IBAction)toggleShowingPreviewPanel:(id)sender{
    [[BDSKPreviewer sharedPreviewer] toggleShowingPreviewPanel:sender];
}

#pragma mark Service code

- (NSDictionary *)constraintsFromString:(NSString *)string{
    NSScanner *scanner;
    NSMutableDictionary *searchConstraints = [NSMutableDictionary dictionary];
    NSString *queryString = nil;
    NSString *queryKey = nil;
    NSCharacterSet *delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@":="];
    NSCharacterSet *ampersandSet =  [NSCharacterSet characterSetWithCharactersInString:@"&"];

    if([string rangeOfCharacterFromSet:delimiterSet].location == NSNotFound){
        [searchConstraints setObject:[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] forKey:BDSKTitleString];
        return searchConstraints;
    }
    
    
    scanner = [NSScanner scannerWithString:string];
    
    // Now split the string into a key and value pair by looking for a delimiter
    // (we'll use a bunch of handy delimiters, including the first space, so it's flexible.)
    // alternatively we can just type the title, like we used to.
    [scanner setCharactersToBeSkipped:nil];
    
    while(![scanner isAtEnd]){
        // set these to nil explicitly, since we check for that later
        queryKey = nil;
        queryString = nil;
        [scanner scanUpToCharactersFromSet:delimiterSet intoString:&queryKey];
        [scanner scanCharactersFromSet:delimiterSet intoString:nil]; // scan the delimiters away
        [scanner scanUpToCharactersFromSet:ampersandSet intoString:&queryString]; // scan to either the end, or the next query key.
        [scanner scanCharactersFromSet:ampersandSet intoString:nil]; // scan the ampersands away.
        
        // lose the whitespace, if any
        queryString = [queryString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        queryKey = [queryKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if(queryKey && queryString) // make sure we have both a key and a value
            [searchConstraints setObject:queryString forKey:[queryKey capitalizedString]]; // BibItem field names are capitalized
    }
    
    return searchConstraints;
}

- (void)completeCitationFromSelection:(NSPasteboard *)pboard
                             userData:(NSString *)userData
                                error:(NSString **)error{
    NSString *pboardString;
    NSArray *types;
    NSSet *items;
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

    NSDictionary *searchConstraints = [self constraintsFromString:pboardString];
    
    if(searchConstraints == nil){
        *error = NSLocalizedString(@"Error: invalid search constraints.",
                                   @"search constraints not valid.");
        return;
    }        

    items = [self itemsMatchingSearchConstraints:searchConstraints];
    
    e = [items objectEnumerator];
    if([items count] > 0){
        if(key = [e nextObject]){
            [keys appendString:citeString];
            [keys appendString:[key citeKey]];
            [commentString appendString:[key citeKey]];
            [commentString appendString:@" = "];
            [commentString appendString:[key displayTitle]];
        }
        while(key = [e nextObject]){
            [keys appendString:@","];
            [keys appendString:[key citeKey]];
            [commentString appendString:@"; "];
            [commentString appendString:[key citeKey]];
            [commentString appendString:@" = "];
            [commentString appendString:[key displayTitle]];
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

- (NSSet *)itemsMatchingSearchConstraints:(NSDictionary *)constraints{
    NSArray *docs = [self documents];
    if([docs count] == 0)
        return nil;

    NSMutableSet *itemsFound = [NSMutableSet set];
    NSMutableArray *arrayOfSets = [NSMutableArray array];
    
    NSEnumerator *constraintsKeyEnum = [constraints keyEnumerator];
    NSString *constraintKey = nil;
    BibDocument *aDoc = nil;

    while(constraintKey = [constraintsKeyEnum nextObject]){
        
        NSEnumerator *docEnum = [docs objectEnumerator];
        
        while(aDoc = [docEnum nextObject]){ 
	    // this is an array of objects matching this particular set of search constraints; add them to the set
            [itemsFound addObjectsFromArray:[aDoc publicationsWithSubstring:[constraints objectForKey:constraintKey] 
                                                                    inField:constraintKey 
                                                                   forArray:[aDoc publications]]];
        }
	// we have one set per search term, so copy it to an array and we'll get the next set of matches
	[arrayOfSets addObject:[[itemsFound copy] autorelease]];
	[itemsFound removeAllObjects];
    }
    
    // sort the sets in order of increasing length indexed 0-->[arrayOfSets length]
    [arrayOfSets sortUsingFunction:compareSetLengths context:nil];

    NSEnumerator *e = [arrayOfSets objectEnumerator];
    [itemsFound setSet:[e nextObject]]; // smallest set

    NSSet *aSet = nil;
    while(aSet = [e nextObject]){
	[itemsFound intersectSet:aSet];
    }
    return itemsFound;
}

- (NSSet *)itemsMatchingCiteKey:(NSString *)citeKeyString{
    NSDictionary *constraints = [NSDictionary dictionaryWithObject:citeKeyString forKey:BDSKCiteKeyString];
    return [self itemsMatchingSearchConstraints:constraints];
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

    NSSet *items = [self itemsMatchingCiteKey:pboardString];
	BibItem *item = nil;
    NSMutableString *retStr = [NSMutableString string];
    BOOL yn = NO;    
    NSEnumerator *itemE = [items objectEnumerator];
    int count = [items count];
    
    while(item = [itemE nextObject]){
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

    NSSet *items = [self itemsMatchingCiteKey:pboardString];
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

- (void)newRISDocumentFromSelection:(NSPasteboard *)pboard
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
    
    [doc loadRISDataRepresentation:[pboardString dataUsingEncoding:NSUTF8StringEncoding] encoding:NSUTF8StringEncoding];
    [[NSDocumentController sharedDocumentController] setShouldCreateUI:YES];
    [[NSDocumentController sharedDocumentController] addDocument:doc];
    [doc makeWindowControllers];
    [doc showWindows];
}

- (void)addPublicationsFromSelection:(NSPasteboard *)pboard
						   userData:(NSString *)userData
							  error:(NSString **)error{	
	
	// add to the frontmost bibliography
	BibDocument * doc = [[NSApp orderedDocuments] objectAtIndex:0];
    if (!doc) {
		// if there are no open documents, give an error. 
		// Or rather create a new document and add the entry there? Would anybody want that?
		*error = NSLocalizedString(@"Error: No open document", @"BibDesk couldn't import the selected information because there is no open bibliography file to add it to. Please create or open a bibliography file and try again.");
		return;
	}
	
	[doc addPublicationsFromPasteboard:pboard error:error];
}

#pragma mark Spotlight support

OFWeakRetainConcreteImplementation_NULL_IMPLEMENTATION

- (void)applicationWillTerminate:(NSNotification *)aNotification{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *tmpDirPath = [self temporaryBaseDirectoryCreating:NO];
	if(tmpDirPath && [fm fileExistsAtPath:tmpDirPath])
		[fm removeFileAtPath:tmpDirPath handler:nil];
	
    [metadataCacheLock lock];
    canWriteMetadata = NO;
    [metadataCacheLock unlock];
}

- (id)openDocumentWithContentsOfURL:(NSURL *)absoluteURL display:(BOOL)displayDocument error:(NSError **)outError{
    
    if(![[[absoluteURL path] pathExtension] isEqualToString:@"bdskcache"])
        return [super openDocumentWithContentsOfURL:absoluteURL display:displayDocument error:outError];
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfURL:absoluteURL];
    BDAlias *fileAlias = [BDAlias aliasWithData:[dictionary valueForKey:@"FileAlias"]];
    NSString *fullPath = [fileAlias fullPath];
    
    if(fullPath == nil) // if the alias didn't work, let's see if we have a filepath key...
        fullPath = [dictionary valueForKey:@"FilePath"];
    
    if(fullPath == nil){
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to find the file associated with this item.", @""), NSLocalizedDescriptionKey]];
        return nil;
    }
        
    NSURL *fileURL = [NSURL fileURLWithPath:[fileAlias fullPath]];
    
    *outError = nil; // this is a garbage pointer if the document is already open
    BibDocument *document = [super openDocumentWithContentsOfURL:fileURL display:YES error:outError];
    
    if(document == nil || *outError != nil)
        NSLog(@"document at URL %@ failed to open for reason: %@", fileURL, [*outError localizedFailureReason]);
    else
        if(![document highlightItemForPartialItem:dictionary])
            NSBeep();
    
    return document;
}

- (void)rebuildMetadataCache:(id)userInfo{
        
    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3)
        return;
    
    [metadataMessageQueue queueSelector:@selector(privateRebuildMetadataCache:) forObject:self withObject:userInfo];
}

#ifdef BDSK_USING_TIGER 

- (void)privateRebuildMetadataCache:(id)userInfo{
    
    OBPRECONDITION([NSThread inMainThread] == NO);
    
    // we could unlock after checking the flag, but we don't want multiple threads writing to the cache directory at the same time, in case files have identical items
    [metadataCacheLock lock];
    if(canWriteMetadata == NO){
        NSLog(@"Application will quit without writing metadata cache.");
        [metadataCacheLock unlock];
        return;
    }

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [userInfo retain];
    
    NSArray *publications = [userInfo valueForKey:@"publications"];
    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    inline void _returnAndCleanUpFromMetadataCaching(){
        [userInfo release];
        [metadata release];
        [metadataCacheLock unlock];
        [pool release];
    }        

    NS_DURING{
        NSError *error = nil;
        NSString *cachePath = [[NSFileManager defaultManager] spotlightCacheFolderPathByCreating:&error];
        
        NSString *docPath = [userInfo valueForKey:@"fileName"];
        
        if(error != nil || docPath == nil){
            NSLog(@"unable to build metadata cache for document at path \"%@\"", docPath);
            _returnAndCleanUpFromMetadataCaching();
            return;
        }
        
        NSString *tmpPath;
        NSString *citeKey;
        BibItem *anItem;
        NSDate *dateModified;
        
        BDAlias *alias = [[BDAlias alloc] initWithPath:docPath];
        if(alias == nil)
            [NSException raise:NSObjectNotAvailableException format:@"Unable to get an alias for file %@", docPath];
        
        NSData *aliasData = [alias aliasData];
        [alias release];
    
        NSEnumerator *entryEnum = [publications objectEnumerator];
        NSString *mdValue = nil;
        
        while(anItem = [entryEnum nextObject]){
            citeKey = [anItem citeKey];
            
            if(citeKey == nil)
                continue;

            [metadata setObject:aliasData forKey:@"FileAlias"];
            [metadata setObject:docPath forKey:@"FilePath"]; // use as a backup in case the alias fails

            [metadata setObject:citeKey forKey:BDSKCiteKeyString];
            
            // A given item is not guaranteed to have all of these, so make sure they are non-nil
            mdValue = [anItem displayTitle];
            if(mdValue != nil){
                [metadata setObject:mdValue forKey:(NSString *)kMDItemTitle];
                
                // this is what shows up in search results
                [metadata setObject:mdValue forKey:(NSString *)kMDItemDisplayName];
            } else {
                [metadata setObject:@"Unknown" forKey:(NSString *)kMDItemDisplayName];
            }
            
            [metadata setObject:([anItem pubAuthorsAsStrings] != nil ? [anItem pubAuthorsAsStrings] : [NSArray array]) forKey:(NSString *)kMDItemAuthors];
            
            mdValue = [[anItem valueOfField:BDSKAbstractString] stringByRemovingTeX];
            if(mdValue != nil)
                [metadata setObject:mdValue forKey:(NSString *)kMDItemDescription];
            
            if( (dateModified = [anItem dateModified]) != nil)
                [metadata setObject:[anItem dateModified] forKey:(NSString *)kMDItemContentModificationDate];
            
            mdValue = [anItem valueOfField:BDSKKeywordsString];
            if(mdValue != nil)
                [metadata setObject:mdValue forKey:(NSString *)kMDItemKeywords];
            
            tmpPath = [cachePath stringByAppendingPathComponent:[citeKey stringByAppendingString:@".bdskcache"]];
            [metadata writeToFile:tmpPath atomically:NO];
            [metadata removeAllObjects];
        }
    }
    NS_HANDLER{
        NSLog(@"%@ discarding %@ %@", NSStringFromSelector(_cmd), [localException name], [localException reason]);
    }
    NS_ENDHANDLER
    
    _returnAndCleanUpFromMetadataCaching();
   
}

#endif

@end