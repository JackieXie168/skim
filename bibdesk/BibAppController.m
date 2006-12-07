//  BibAppController.m

//  Created by Michael McCracken on Sat Jan 19 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006
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

#import "BibAppController.h"
#import <Carbon/Carbon.h>
#import <OmniBase/OmniBase.h>
#import "BibPrefController.h"
#import "BibItem.h"
#import "BDSKPreviewer.h"
#import "BibDocument.h"
#import "BibDocumentView_Toolbar.h"
#import "NSTextView_BDSKExtensions.h"
#import "NSString_BDSKExtensions.h"
#import "BDSKConverter.h"
#import "BDSKTypeInfoEditor.h"
#import "BDSKCharacterConversion.h"
#import "BDSKFindController.h"
#import <OmniFoundation/OFVersionNumber.h>
#import "BDSKFileContentSearchController.h"
#import "BDSKScriptMenuItem.h"
#import "BibDocument_Search.h"
#import "BDSKPathIconTransformer.h"
#import "BDSKFormatParser.h"
#import "BDAlias.h"
#import "BDSKErrorObjectController.h"
#import <OmniAppKit/OAScriptMenuItem.h>
#import <ILCrashReporter/ILCrashReporter.h>
#import "NSMutableArray+ThreadSafety.h"
#import "NSMutableDictionary+ThreadSafety.h"
#import "NSFileManager_BDSKExtensions.h"
#import "OFCharacterSet_BDSKExtensions.h"
#import "BibDocument_Groups.h"
#import "NSArray_BDSKExtensions.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "BDSKSharingBrowser.h"
#import "BDSKSharingServer.h"
#import "BDSKPreferenceController.h"
#import "BDSKTemplateParser.h"
#import "BDSKTemplate.h"
#import "NSSet_BDSKExtensions.h"

@implementation BibAppController

+ (void)initialize
{
    OBINITIALIZE;
    
    // since Quartz.framework doesn't exist on < 10.4, we can't link against it
    // http://www.cocoabuilder.com/archive/message/cocoa/2004/1/31/99969
    if(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3)
        [[NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"Tiger" ofType:@"bundle"]] load];
    
    // make sure we use Spotlight's plugins on 10.4 and later
    SKLoadDefaultExtractorPlugIns();

#ifdef USECRASHREPORTER
    [[ILCrashReporter defaultReporter] launchReporterForCompany:@"BibDesk Project" reportAddr:@"bibdesk-crashes@lists.sourceforge.net"];
#endif
        
    // register services
    [NSApp registerServicesMenuSendTypes:[NSArray arrayWithObjects:NSStringPboardType,nil] returnTypes:[NSArray arrayWithObjects:NSStringPboardType,nil]];
        	
	// register transformer class
	[NSValueTransformer setValueTransformer:[[[BDSKPathIconTransformer alloc] init] autorelease]
									forName:@"BDSKPathIconTransformer"];
}

- (id)init
{
    if(self = [super init]){
        autoCompletionDict = [[NSMutableDictionary alloc] initWithCapacity:15]; // arbitrary
        requiredFieldsForCiteKey = nil;
        requiredFieldsForLocalUrl = nil;
        
        metadataCacheLock = [[NSLock alloc] init];
        metadataMessageQueue = [[OFMessageQueue alloc] init];
        [metadataMessageQueue startBackgroundProcessors:1];
        canWriteMetadata = YES;
				
		NSString *formatString = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKCiteKeyFormatKey];
		NSString *error = nil;
		int button = 0;
		
		if ([BDSKFormatParser validateFormat:&formatString forField:BDSKCiteKeyString inFileType:BDSKBibtexString error:&error]) {
			[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:formatString forKey:BDSKCiteKeyFormatKey];
			[self setRequiredFieldsForCiteKey: [BDSKFormatParser requiredFieldsForFormat:formatString]];
		}else{
			button = NSRunCriticalAlertPanel(NSLocalizedString(@"The autogeneration format for Cite Key is invalid.", @""), 
											 @"%@",
											 NSLocalizedString(@"Go to Preferences", @""), 
											 NSLocalizedString(@"Revert to Default", @""), 
											 nil, error, nil);
			if (button == NSAlertAlternateReturn){
				formatString = [[[OFPreferenceWrapper sharedPreferenceWrapper] preferenceForKey:BDSKCiteKeyFormatKey] defaultObjectValue];
                [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:formatString forKey:BDSKCiteKeyFormatKey];
				[self setRequiredFieldsForCiteKey: [BDSKFormatParser requiredFieldsForFormat:formatString]];
			}else{
				[[BDSKPreferenceController sharedPreferenceController] showPreferencesPanel:self];
				[[BDSKPreferenceController sharedPreferenceController] setCurrentClientByClassName:@"BibPref_CiteKey"];
			}
		}
		
		formatString = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKLocalUrlFormatKey];
		error = nil;
		
		if ([BDSKFormatParser validateFormat:&formatString forField:BDSKLocalUrlString inFileType:BDSKBibtexString error:&error]) {
			[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:formatString forKey:BDSKLocalUrlFormatKey];
			[self setRequiredFieldsForLocalUrl: [BDSKFormatParser requiredFieldsForFormat:formatString]];
		}else{
			button = NSRunCriticalAlertPanel(NSLocalizedString(@"The autogeneration format for Local-Url is invalid.", @""), 
											 @"%@",
											 NSLocalizedString(@"Go to Preferences", @""), 
											 NSLocalizedString(@"Revert to Default", @""), 
											 nil, error, nil);
			if (button == NSAlertAlternateReturn){
				formatString = [[[OFPreferenceWrapper sharedPreferenceWrapper] preferenceForKey:BDSKLocalUrlFormatKey] defaultObjectValue];			
				[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:formatString forKey:BDSKLocalUrlFormatKey];
				[self setRequiredFieldsForLocalUrl: [BDSKFormatParser requiredFieldsForFormat:formatString]];
			}else{
				[[BDSKPreferenceController sharedPreferenceController] showPreferencesPanel:self];
				[[BDSKPreferenceController sharedPreferenceController] setCurrentClientByClassName:@"BibPref_AutoFile"];
			}
		}
		
		NSMutableArray *defaultFields = [[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKDefaultFieldsKey] mutableCopy];
		if(![defaultFields containsObject:BDSKUrlString]){
			[defaultFields insertObject:BDSKUrlString atIndex:0];
			[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:defaultFields forKey:BDSKDefaultFieldsKey];
		}
		if(![defaultFields containsObject:BDSKLocalUrlString]){
			[defaultFields insertObject:BDSKLocalUrlString atIndex:0];
			[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:defaultFields forKey:BDSKDefaultFieldsKey];
		}
        [defaultFields release];
		
		NSMutableArray *localFileFields = [[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKLocalFileFieldsKey] mutableCopy];
		if(![localFileFields containsObject:BDSKLocalUrlString]){
			[localFileFields insertObject:BDSKLocalUrlString atIndex:0];
			[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:localFileFields forKey:BDSKLocalFileFieldsKey];
		}
        [localFileFields release];

        NSMutableArray *remoteURLFields = [[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKRemoteURLFieldsKey] mutableCopy];
		if(![remoteURLFields containsObject:BDSKUrlString]){
			[remoteURLFields insertObject:BDSKUrlString atIndex:0];
			[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:remoteURLFields forKey:BDSKRemoteURLFieldsKey];
		}
		[remoteURLFields release];
        
        NSMutableArray *ratingFields = [[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKRatingFieldsKey] mutableCopy];
		if(![ratingFields containsObject:BDSKRatingString]){
			[ratingFields insertObject:BDSKRatingString atIndex:0];
			[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:ratingFields forKey:BDSKRatingFieldsKey];
		}
		[ratingFields release];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [autoCompletionDict release];
	[requiredFieldsForCiteKey release];
    [metadataCacheLock release];
    [metadataMessageQueue release];
	[readmeWindow release];
    [super dealloc];
}


- (void)awakeFromNib{

	[self updateColumnsMenu];

	// register to observe when the columns change, to update the columns menu
	[[NSNotificationCenter defaultCenter] addObserver:self
			selector:@selector(handleTableColumnsChangedNotification:)
			name:BDSKTableColumnChangedNotification
			object:nil];
    
    // copy files to application support
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [self copyAllExportTemplatesToApplicationSupportAndOverwrite:NO];        
    [fileManager copyFileFromResourcesToApplicationSupport:@"previewtemplate.tex" overwrite:NO];
    [fileManager copyFileFromResourcesToApplicationSupport:@"template.txt" overwrite:NO];    
}

- (void)copyAllExportTemplatesToApplicationSupportAndOverwrite:(BOOL)overwrite{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupport = [fileManager currentApplicationSupportPathForCurrentUser];
    NSString *templatesPath = [applicationSupport stringByAppendingPathComponent:@"Templates"];
    BOOL success = NO;
    
    if ([fileManager fileExistsAtPath:templatesPath isDirectory:&success] == NO) {
        success = [fileManager createDirectoryAtPath:templatesPath attributes:nil];
    }
    
    if (success) {
        [fileManager copyFileFromResourcesToApplicationSupport:@"Templates/htmlExportTemplate.html" overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:@"Templates/htmlItemExportTemplate.html" overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:@"Templates/htmlExportStyleSheet.css" overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:@"Templates/rssExportTemplate.rss" overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:@"Templates/rtfExportTemplate.rtf" overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:@"Templates/rtfdExportTemplate.rtfd" overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:@"Templates/docExportTemplate.doc" overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:@"Templates/citeServiceTemplate.txt" overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:@"Templates/textServiceTemplate.txt" overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:@"Templates/rtfServiceTemplate.rtf" overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:@"Templates/rtfServiceTemplate default item.rtf" overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:@"Templates/rtfServiceTemplate book.rtf" overwrite:overwrite];
    }    
}

#pragma mark Application delegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    // register as a service provider for completecitation:
    [NSApp setServicesProvider:self];
    NSUpdateDynamicServices();
    
    // Add a Scripts menu; searches in (mainbundle)/Contents/Scripts and (Library domains)/Application Support/BibDesk/Scripts
    // ARM:  if we add this in -awakeFromNib, we get another script menu each time we show release notes or readme; whatever.
    if([BDSKScriptMenuItem disabled] == NO){
        NSString *scriptMenuTitle = @"";
        NSMenu *newMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:scriptMenuTitle];
        BDSKScriptMenuItem *scriptItem = [[BDSKScriptMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:scriptMenuTitle action:NULL keyEquivalent:@""];
        [scriptItem setSubmenu:newMenu];
        [newMenu release];
        [[NSApp mainMenu] insertItem:scriptItem atIndex:[[NSApp mainMenu] indexOfItemWithTitle:@"Help"]];
        [scriptItem release];
    }
    
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    if([[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKLastVersionLaunchedKey] == nil) // show new users the readme file; others just see the release notes
        [self showReadMeFile:nil];
    if(![versionString isEqualToString:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKLastVersionLaunchedKey]])
        [self showRelNotes:nil];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:versionString forKey:BDSKLastVersionLaunchedKey];
    
    if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKAutoCheckForUpdatesKey])
		[NSThread detachNewThreadSelector:@selector(checkForUpdatesInBackground) toTarget:self withObject:nil];
    
    BOOL inputManagerIsCurrent;
    if([self isInputManagerInstalledAndCurrent:&inputManagerIsCurrent] && inputManagerIsCurrent == NO)
        [self showInputManagerUpdateAlert];
    
    // Ensure the previewer and TeX task get created now in order to avoid a spurious "unable to copy helper file" warning when quit->document window closes->first call to [BDSKPreviewer sharedPreviewer]
    if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKUsesTeXKey])
        [BDSKPreviewer sharedPreviewer];
	
	if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShowingPreviewKey])
		[[BDSKPreviewer sharedPreviewer] showPreviewPanel:self];
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *tmpDirPath = [self temporaryBaseDirectoryCreating:NO];
	if(tmpDirPath && [fm fileExistsAtPath:tmpDirPath])
		[fm removeFileAtPath:tmpDirPath handler:nil];
	
    [metadataCacheLock lock];
    canWriteMetadata = NO;
    [metadataCacheLock unlock];
    
    NSArray *fileNames = [[[NSDocumentController sharedDocumentController] documents] valueForKeyPath:@"@distinctUnionOfObjects.fileName"];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[fileNames count]];
    NSEnumerator *fEnum = [fileNames objectEnumerator];
    NSString *fileName;
    while(fileName = [fEnum nextObject]){
        NSData *data = [[BDAlias aliasWithPath:fileName] aliasData];
        if(data)
            [array addObject:[NSDictionary dictionaryWithObjectsAndKeys:fileName, @"fileName", data, @"_BDAlias", nil]];
        else
            [array addObject:[NSDictionary dictionaryWithObjectsAndKeys:fileName, @"fileName", nil]];
    }
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:array forKey:BDSKLastOpenFileNamesKey];
    [[BDSKSharingServer defaultServer] disableSharing];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    int flag = [[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKStartupBehaviorKey] intValue];
    switch(flag){
        case 0:
            return YES;
        case 1:
            return NO;
        case 2:
            [[NSDocumentController sharedDocumentController] openDocument:nil];   
            return NO;
        case 3:
            [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:
                [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKDefaultBibFilePathKey] display:YES];
            return NO;
        case 4:
            do{
                NSArray *files = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKLastOpenFileNamesKey];
                NSEnumerator *fileEnum = [files objectEnumerator];
                NSDictionary *dict;
                NSString *file;
                while (dict = [fileEnum nextObject]){ 
                    file = [[BDAlias aliasWithData:[dict objectForKey:@"_BDAlias"]] fullPath];
                    if(file == nil)
                        file = [dict objectForKey:@"fileName"];
                    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:file display:YES];
                }
            }while(0);
            return NO;
        default:
            return NO;
    }
}

- (void)openRecentItemFromDock:(id)sender{
    OBASSERT([sender isKindOfClass:[NSMenuItem class]]);
    NSURL *url = [sender representedObject];
    if(url == nil) 
        return NSBeep();
    
    // open... methods automatically call addDocument, so we don't have to
    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3){
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES];
    } else {
        NSError *error;
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES error:&error];
    }
}    

- (NSMenu *)applicationDockMenu:(NSApplication *)sender{
    NSMenu *menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
    NSMenu *submenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];

    NSArray *urls = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
    NSURL *url;
    NSMenuItem *anItem;
    NSEnumerator *urlE = [urls objectEnumerator];

    anItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Open Recent",  @"Recent Documents dock menu title") action:nil keyEquivalent:@""];
    [anItem setSubmenu:submenu];
	[menu addItem:anItem];
    [anItem release];
    
    while(url = [urlE nextObject]){
        anItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[[url path] lastPathComponent] action:@selector(openRecentItemFromDock:) keyEquivalent:@""];
        [anItem setTarget:self];
        [anItem setRepresentedObject:url];
        
        // Supposed to be able to set the image this way according to a post from jcr on cocoadev, but all I get is a weird [obj] image on 10.4.  Apparently this is possible with Carbon <http://developer.apple.com/documentation/Carbon/Conceptual/customizing_docktile/index.html> but it involves event handlers and other nasty things, even more painful than adding an image to an attributed string.
#if 0
        NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] init];
        NSTextAttachmentCell *attachmentCell = [[NSTextAttachmentCell alloc] init];
        [attachmentCell setImage:[NSImage imageForURL:url]];
        
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        [attachment setAttachmentCell:attachmentCell];
        [attachmentCell release];
        [attrTitle appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
        [attachment release];
        
        [attrTitle appendString:@" " attributes:nil];
        [attrTitle appendString:[anItem title]];
        [anItem setAttributedTitle:attrTitle];
        [attrTitle release];
#endif        
        [submenu addItem:anItem];
        [anItem release];
    }
    
    return menu;
}

#pragma mark Temporary files and directories

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

#pragma mark Menu stuff

- (NSMenuItem*) columnsMenuItem {
	return columnsMenuItem;
}

- (NSMenuItem*) groupSortMenuItem {
	return groupSortMenuItem;
}

- (void)updateColumnsMenu{
	NSArray *prefsShownColNamesArray = [[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKShownColsNamesKey];
    NSEnumerator *shownColNamesE = [prefsShownColNamesArray reverseObjectEnumerator];
	NSString *colName;
    NSMenu *columnsMenu = [columnsMenuItem submenu];
	NSMenuItem *item = nil;
	
	
	// remove the add-items, and remember the extra ones, corrsponding to removed columns
	while(![[columnsMenu itemAtIndex:0] isSeparatorItem]){
		[columnsMenu removeItemAtIndex:0];
	}
	
	// next add all the shown columns in the order they are shown
	while(colName = [shownColNamesE nextObject]){
        item = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:colName 
                                           action:@selector(columnsMenuSelectTableColumn:)
                                    keyEquivalent:@""] autorelease];
		[item setState:NSOnState];
		[columnsMenu insertItem:item atIndex:0];
	}
}
	
- (void)handleTableColumnsChangedNotification:(NSNotification *)notification {
	[self updateColumnsMenu];
}

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
    else

	return YES;
}


- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem {

	if ([[toolbarItem itemIdentifier] isEqualToString:BibDocumentToolbarPreviewItemIdentifier]) {
		return ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKUsesTeXKey]);
	}
	
    return [super validateToolbarItem:toolbarItem];
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSArray *styles = [BDSKTemplate allStyleNames];
    int i = [menu numberOfItems];
    while (i--) {
        if ([[menu itemAtIndex:i] tag] < BDSKTemplateDragCopyType)
            break;
        [menu removeItemAtIndex:i];
    }
    
    NSMenuItem *item;
    int count = [styles count];
    for (i = 0; i < count; i++) {
        item = [menu addItemWithTitle:[styles objectAtIndex:i] action:@selector(copyAsAction:) keyEquivalent:@""];
        [item setTag:BDSKTemplateDragCopyType + i];
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

- (NSString *)folderPathForFilingPapersFromDocument:(BibDocument *)document {
	NSString *papersFolderPath = [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKPapersFolderPathKey];
	if ([NSString isEmptyString:papersFolderPath])
		papersFolderPath = [[document fileName] stringByDeletingLastPathComponent];
	if ([NSString isEmptyString:papersFolderPath])
		papersFolderPath = NSHomeDirectory();
	return [papersFolderPath stringByExpandingTildeInPath];
}

#pragma mark Auto-completion stuff

- (void)addString:(NSString *)string forCompletionEntry:(NSString *)entry{
    // adding complex strings can lead to a crash after the containing document closes, and it is rather meaningless anyway
    if ([string isComplex])
        return;
    
    // @@ could move this to the type manager and union all excluded fields
    static NSSet *numericFields = nil;
	if (numericFields == nil)
		numericFields = [[NSSet alloc] initWithObjects:BDSKYearString, BDSKVolumeString, BDSKNumberString, BDSKPagesString, nil];

    BibTypeManager *typeMan = [BibTypeManager sharedManager];

	if(BDIsEmptyString((CFStringRef)entry) || [numericFields containsObject:entry] || [typeMan isURLField:entry])	
		return;
	if([entry isEqualToString:BDSKEditorString])	
		entry = BDSKAuthorString;
	else if([entry isEqualToString:BDSKBooktitleString])	
		entry = BDSKTitleString;
	
	NSMutableSet *completionSet = [autoCompletionDict objectForKey:entry];
	
    if (completionSet == nil) {
        completionSet = [[NSMutableSet alloc] initWithCapacity:500];
        [autoCompletionDict setObject:completionSet forKey:entry];
        [completionSet release];
    }

    if([[typeMan invalidGroupFields] containsObject:entry] ||
	   [[typeMan singleValuedGroupFields] containsObject:entry]){ // add the whole string 
        [completionSet addObject:[string fastStringByCollapsingWhitespaceAndRemovingSurroundingWhitespace]];
        return;
    }
    
    // more efficient for the splitting functions
    if([string isComplex]) string = [NSString stringWithString:string];
    
    if([entry isEqualToString:BDSKAuthorString]){
        [completionSet addObjectsFromArray:[[string componentsSeparatedByString:@" and "] arrayByPerformingSelector:@selector(fastStringByCollapsingWhitespaceAndRemovingSurroundingWhitespace)]];
        return;
    }
    
    NSCharacterSet *acSet = [NSCharacterSet autocompletePunctuationCharacterSet];
    if([string rangeOfCharacterFromSet:acSet].location != NSNotFound){
        [completionSet addObjectsFromArray:[string componentsSeparatedByCharactersInSet:acSet trimWhitespace:YES]];
    } else if([entry isEqualToString:BDSKKeywordsString]){
        // if it wasn't punctuated, try this; Elsevier uses "and" as a separator, and it's annoying to have the whole string autocomplete on you
        [completionSet addObjectsFromArray:[[string componentsSeparatedByString:@" and "] arrayByPerformingSelector:@selector(fastStringByCollapsingWhitespaceAndRemovingSurroundingWhitespace)]];
    } else {
        [completionSet addObject:[string fastStringByCollapsingWhitespaceAndRemovingSurroundingWhitespace]];
    }
}

- (NSSet *)stringsForCompletionEntry:(NSString *)entry{
    NSSet* autoCompleteStrings = [autoCompletionDict objectForKey:entry];
	if (autoCompleteStrings)
		return autoCompleteStrings;
	else 
		return [NSSet set];
}

- (NSRange)entry:(NSString *)entry rangeForUserCompletion:(NSRange)charRange ofString:(NSString *)fullString {
    OFCharacterSet *wsCharSet = [OFCharacterSet whitespaceCharacterSet];

	if ([entry isEqualToString:BDSKEditorString])	
		entry = BDSKAuthorString;
	else if ([entry isEqualToString:BDSKBooktitleString])	
		entry = BDSKTitleString;
	
	// find a string to match, be consistent with addString:forCompletionEntry:
	BibTypeManager *typeMan = [BibTypeManager sharedManager];
	NSRange searchRange = NSMakeRange(0, charRange.location);
	// find the first separator preceding the current word being entered
    NSRange punctuationRange = [fullString rangeOfCharacterFromSet:[NSCharacterSet autocompletePunctuationCharacterSet]
														   options:NSBackwardsSearch
															 range:searchRange]; // check to see if this is a keyword-type
    NSRange andRange = [fullString rangeOfString:@" and "
										 options:NSBackwardsSearch | NSLiteralSearch
										   range:searchRange]; // check to see if it's an author (not robust)
	unsigned matchStart = 0;
	// now find the beginning of the match, reflecting addString:forCompletionEntry:. We might be more sofisticated, like in groups
    if ([entry isEqualToString:BDSKAuthorString]) {
		// these are delimited by "and"
		if (andRange.location != NSNotFound)
			matchStart = NSMaxRange(andRange);
    } else if([[typeMan invalidGroupFields] containsObject:entry] || [[typeMan singleValuedGroupFields] containsObject:entry]){
		// these are added as the whole string. Shouldn't there be more?
	} else if (punctuationRange.location != NSNotFound) {
		// should we delimited by these punctuations by default?
		matchStart = NSMaxRange(punctuationRange);
	} else if ([entry isEqualToString:BDSKKeywordsString] && andRange.location != NSNotFound) {
		// keywords can be delimited also by "and"
		matchStart = NSMaxRange(andRange);
    }
	// ignore leading spaces
	while (matchStart < charRange.location && [wsCharSet characterIsMember:[fullString characterAtIndex:matchStart]])
		matchStart++;
	return NSMakeRange(matchStart, NSMaxRange(charRange) - matchStart);
}

- (NSArray *)entry:(NSString *)entry completions:(NSArray *)words forPartialWordRange:(NSRange)charRange ofString:(NSString *)fullString indexOfSelectedItem:(int *)index{
	if ([entry isEqualToString:BDSKEditorString])	
		entry = BDSKAuthorString;
	else if ([entry isEqualToString:BDSKBooktitleString])	
		entry = BDSKTitleString;
	
	NSString *matchString = [[fullString substringWithRange:charRange] stringByRemovingCurlyBraces];
    
    // in case this is only a brace, return an empty array to avoid returning every value in the file
    if([matchString isEqualToString:@""])
        return [NSArray array];
    
    NSSet *strings = [self stringsForCompletionEntry:entry];
    NSEnumerator *stringE = [strings objectEnumerator];
    NSString *string = nil;
    NSMutableArray *completions = [NSMutableArray arrayWithCapacity:[strings count]];

    while (string = [stringE nextObject]) {
        if ([[string stringByRemovingCurlyBraces] hasCaseInsensitivePrefix:matchString])
            [completions addObject:string];
    }
    
    [completions sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
	int i, count = [completions count];
	for (i = 0; i < count; i++) {
        string = [completions objectAtIndex:i];
		if ([[string stringByRemovingCurlyBraces] caseInsensitiveCompare:matchString]) {
            *index = i;
			break;
		}
    }
    
    return completions;
}

- (NSRange)rangeForUserCompletion:(NSRange)charRange forBibTeXStringString:(NSString *)fullString {
    static NSCharacterSet *punctuationCharSet = nil;
	if (punctuationCharSet == nil) {
		NSMutableCharacterSet *tmpSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
		[tmpSet addCharactersInString:@"#"];
		punctuationCharSet = [tmpSet copy];
		[tmpSet release];
	}
	// we extend, as we use a different set of punctuation characters as Apple does
	int prefixLength = 0;
	while (charRange.location > prefixLength && ![punctuationCharSet characterIsMember:[fullString characterAtIndex:charRange.location - prefixLength - 1]]) 
		prefixLength++;
	if (prefixLength > 0) {
		charRange.location -= prefixLength;
		charRange.length += prefixLength;
	}
	return charRange;
}

- (NSArray *)possibleMatches:(NSDictionary *)definitions forBibTeXStringString:(NSString *)fullString partialWordRange:(NSRange)charRange indexOfBestMatch:(int *)index{
    // Add the definitions from preferences, if any exist; presumably the user can remember the month definitions/
    NSDictionary *globalDefs = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKBibStyleMacroDefinitionsKey];
	NSMutableDictionary *macroDefs = [[NSMutableDictionary alloc] initWithCapacity:[definitions count] + [globalDefs count]];
    if (globalDefs != nil)
        [macroDefs addEntriesFromDictionary:globalDefs];
	[macroDefs addEntriesFromDictionary:definitions]; // add the definitions at the end, so they override global macros
	
    NSString *partialString = [fullString substringWithRange:charRange];
    NSMutableArray *matches = [NSMutableArray arrayWithCapacity:[macroDefs count]];
    NSEnumerator *keyE = [macroDefs keyEnumerator];
    NSString *key = nil;
    
    // Search the definitions case-insensitively; we match on key or value, but only return keys.
    while (key = [keyE nextObject]) {
        if ([key rangeOfString:partialString options:NSCaseInsensitiveSearch].location != NSNotFound ||
			[[macroDefs valueForKey:key] rangeOfString:partialString options:NSCaseInsensitiveSearch].location != NSNotFound)
            [matches addObject:key];
    }
    [macroDefs release];
    [matches sortUsingSelector:@selector(caseInsensitiveCompare:)];

    int i, count = [matches count];
    for (i = 0; i < count; i++) {
        key = [matches objectAtIndex:i];
        if ([key hasPrefix:partialString]) {
            // If the key has the entire partialString as prefix, it's a good match, so we'll select it by default.
            *index = i;
			break;
        }
    }

    return matches;
}

#pragma mark Version checking

- (BOOL)checkForNetworkAvailability:(NSError **)error{
    
    BOOL result = NO;
    SCNetworkConnectionFlags flags;
    const char *hostName = "bibdesk.sourceforge.net";
        
    if( SCNetworkCheckReachabilityByName(hostName, &flags) ){
        result = !(flags & kSCNetworkFlagsConnectionRequired) && (flags & kSCNetworkFlagsReachable);
    }
    
    if(result == NO){
        if(error)
            OFError(error, BDSKNetworkError, NSLocalizedDescriptionKey, NSLocalizedString(@"Network Unavailable", @""), NSLocalizedRecoverySuggestionErrorKey, NSLocalizedString(@"BibDesk is unable to establish a network connection, possibly because your network is down or a firewall is blocking the connection.", @""), nil);
        else
            NSLog(@"Unable to contact %s, possibly because your network is down or a firewall is prevening the connection.", hostName);
    }
    
    return result;
}

- (OFVersionNumber *)latestReleasedVersionNumber:(NSError **)error{
    
    NSError *downloadError;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://bibdesk.sourceforge.net/bibdesk-versions-xml.txt"]];
    NSURLResponse *response;
    
    // load it synchronously; either the user requested this on the main thread, or this is the update thread
    NSData *theData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&downloadError];
    NSDictionary *versionDictionary = nil;
    OFVersionNumber *remoteVersion = nil;
    
    if(nil != theData){
        NSString *err = nil;
        versionDictionary = [NSPropertyListSerialization propertyListFromData:(NSData *)theData
                                                             mutabilityOption:NSPropertyListImmutable
                                                                       format:NULL
                                                             errorDescription:&err];
        if(nil != err){
            // add the parsing error as underlying error, if the retrieval actually succeeded
            OFError(&downloadError, BDSKNetworkError, NSLocalizedDescriptionKey, NSLocalizedString(@"Unable to create property list from update check download", @""), NSUnderlyingErrorKey, err, nil);
            [err release];
        } else {
            remoteVersion = [[[OFVersionNumber alloc] initWithVersionString:[versionDictionary valueForKey:@"BibDesk"]] autorelease];
        }
    }
    if(error) 
        *error = downloadError;    
    
    return remoteVersion;
}

- (void)checkForUpdatesInBackground{
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if([self checkForNetworkAvailability:NULL] == NO){
        [pool release];
        return;
    }
        
    NSString *currVersionNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    OFVersionNumber *localVersion = [[[OFVersionNumber alloc] initWithVersionString:currVersionNumber] autorelease];
    
    NSError *error = nil;
    OFVersionNumber *remoteVersion = [self latestReleasedVersionNumber:&error];
    
    if(remoteVersion && [remoteVersion compareToVersionNumber:localVersion] == NSOrderedDescending){
        [[OFMessageQueue mainQueue] queueSelector:@selector(displayUpdateAvailableWindow:) forObject:self withObject:[remoteVersion cleanVersionString]];
        
    } else if(nil == remoteVersion){
        if(nil != error && [NSApplication instancesRespondToSelector:@selector(presentError:)])
            [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:YES];
        NSLog(@"Unable to contact server for version check due to error %@", error);
    }
    [pool release];
    
}

- (void)displayUpdateAvailableWindow:(NSString *)latestVersionNumber{
    int button;
    button = NSRunAlertPanel(NSLocalizedString(@"A New Version is Available", @"Alert when new version is available"),
                             NSLocalizedString(@"A new version of BibDesk is available (version %@). Would you like to download the new version now?", @"format string asking if the user would like to get the new version"),
                             nil, NSLocalizedString(@"Cancel",@"Cancel"), latestVersionNumber, nil);
    if (button == NSOKButton) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://bibdesk.sourceforge.net/"]];
    }
    
}

- (IBAction)checkForUpdates:(id)sender{
    
    // check for network availability and display a warning if it's down
    NSError *error = nil;
    if([self checkForNetworkAvailability:&error] == NO){
        [[NSDocumentController sharedDocumentController] presentError:error];
    } else {
        [self checkForUpdatesInBackground];
    }
    
    OFVersionNumber *remoteVersion = [self latestReleasedVersionNumber:&error];
    if(nil == remoteVersion){
        NSRunAlertPanel(NSLocalizedString(@"Error", @"Title of alert when an error happens"),
                        NSLocalizedString(@"There was an error checking for updates.", @"Alert text when the error happens."),
                        NSLocalizedString(@"Give up", @"Accept & give up"), nil, nil);
        return;
    }
        
    NSString *currVersionNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    OFVersionNumber *localVersion = [[[OFVersionNumber alloc] initWithVersionString:currVersionNumber] autorelease];
    
    if([remoteVersion compareToVersionNumber:localVersion] == NSOrderedDescending){
        [self displayUpdateAvailableWindow:[remoteVersion cleanVersionString]];
    } else {
        // tell user software is up to date
        NSRunAlertPanel(NSLocalizedString(@"BibDesk is up to date", @"Title of alert when a the user's software is up to date."),
                        NSLocalizedString(@"You have the most recent version of BibDesk.", @"Alert text when the user's software is up to date."),
                        nil, nil, nil);                
    }
    
}

#pragma mark | Input manager

- (BOOL)isInputManagerInstalledAndCurrent:(BOOL *)current{
    NSParameterAssert(current != NULL);
    
    // someone may be mad enough to install this in NSLocalDomain or NSNetworkDomain, but we don't support that
    NSString *inputManagerBundlePath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"/InputManagers/BibDeskInputManager/BibDeskInputManager.bundle"];

    NSString *bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"BibDeskInputManager/BibDeskInputManager.bundle"];
    NSString *bundledVersion = [[[NSBundle bundleWithPath:bundlePath] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    NSString *installedVersion = [[[NSBundle bundleWithPath:inputManagerBundlePath] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    
    *current = [bundledVersion isEqualToString:installedVersion];
    return installedVersion == nil ? NO : YES;
}

- (void)showInputManagerUpdateAlert{
    NSAlert *anAlert = [NSAlert alertWithMessageText:@"Autocomplete Plugin Needs Update"
                                       defaultButton:[NSLocalizedString(@"Open", @"Open") stringByAppendingString:[NSString horizontalEllipsisString]]
                                     alternateButton:NSLocalizedString(@"Cancel", @"Cancel the update")
                                         otherButton:nil
                           informativeTextWithFormat:NSLocalizedString(@"You appear to be using the BibDesk autocompletion plugin, and a newer version is available.  Would you like to open the completion preferences so that you can update the plugin?",@"")];
    int rv = [anAlert runModal];
    if(rv == NSAlertDefaultReturn){
        [[BDSKPreferenceController sharedPreferenceController] showPreferencesPanel:nil];
        [[BDSKPreferenceController sharedPreferenceController] setCurrentClientByClassName:@"BibPref_InputManager"];
    }
    
}

#pragma mark Panels

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

- (IBAction)showFindPanel:(id)sender{
    [[BDSKFindController sharedFindController] showWindow:self];
}

- (IBAction)visitWebSite:(id)sender{
    if(![[NSWorkspace sharedWorkspace] openURL:
        [NSURL URLWithString:@"http://bibdesk.sourceforge.net/"]]){
        NSBeep();
    }
}

- (IBAction)showPreferencePanel:(id)sender{
    [[BDSKPreferenceController sharedPreferenceController] showPreferencesPanel:sender];
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
    NSSet *citeKeyStrings = [NSSet caseInsensitiveStringSetWithObjects:@"cite key", @"citekey", @"cite-key", @"key", nil];
    
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
        
        // allow some additional leeway with citekey
        if([citeKeyStrings containsObject:queryKey])
            queryKey = BDSKCiteKeyString;
        
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
    BDSKTemplate *template = [BDSKTemplate templateForCiteService];
    OBPRECONDITION(nil != template && ([template templateFormat] & BDSKTextTemplateFormat));
    
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
    
    if([items count] > 0){
        NSString *fileTemplate = [BDSKTemplateObjectProxy stringByParsingTemplate:template withObject:self publications:[items allObjects]];
        
        types = [NSArray arrayWithObject:NSStringPboardType];
        [pboard declareTypes:types owner:nil];

        [pboard setString:fileTemplate forType:NSStringPboardType];
    }
    return;
}

- (void)completeTextBibliographyFromSelection:(NSPasteboard *)pboard
                                     userData:(NSString *)userData
                                        error:(NSString **)error{
    NSString *pboardString;
    NSArray *types;
    NSSet *items;
    BDSKTemplate *template = [BDSKTemplate templateForTextService];
    OBPRECONDITION(nil != template && ([template templateFormat] & BDSKTextTemplateFormat));
    
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
    
    if([items count] > 0){
        NSString *fileTemplate = [BDSKTemplateObjectProxy stringByParsingTemplate:template withObject:self publications:[items allObjects]];
        
        types = [NSArray arrayWithObject:NSStringPboardType];
        [pboard declareTypes:types owner:nil];

        [pboard setString:fileTemplate forType:NSStringPboardType];
    }
    return;
}

- (void)completeRichBibliographyFromSelection:(NSPasteboard *)pboard
                                     userData:(NSString *)userData
                                        error:(NSString **)error{
    NSString *pboardString;
    NSArray *types;
    NSSet *items;
    BDSKTemplate *template = [BDSKTemplate templateForRTFService];
    OBPRECONDITION(nil != template && [template templateFormat] == BDSKRTFTemplateFormat);
    
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
    
    if([items count] > 0){
        NSDictionary *docAttributes = nil;
        NSAttributedString *fileTemplate = [BDSKTemplateObjectProxy attributedStringByParsingTemplate:template withObject:self publications:[items allObjects] documentAttributes:&docAttributes];
        NSData *pboardData = [fileTemplate RTFFromRange:NSMakeRange(0, [fileTemplate length]) documentAttributes:docAttributes];
        
        types = [NSArray arrayWithObject:NSRTFPboardType];
        [pboard declareTypes:types owner:nil];

        [pboard setData:pboardData forType:NSRTFPboardType];
    }
    return;
}

- (NSSet *)itemsMatchingSearchConstraints:(NSDictionary *)constraints{
    NSArray *docs = [[NSDocumentController sharedDocumentController] documents];
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
    NSSortDescriptor *setLengthSort = [[[NSSortDescriptor alloc] initWithKey:@"self.@count" ascending:YES selector:@selector(compare:)] autorelease];
    [arrayOfSets sortUsingDescriptors:[NSArray arrayWithObject:setLengthSort]];

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

}

// this gets called when text is dropped on the dock icon
- (void)newDocumentFromSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error{	

    BibDocument *doc = [[[BibDocument alloc] init] autorelease];
    NSError *nsError = nil;
    
    if([doc addPublicationsFromPasteboard:pboard error:&nsError]){
        [[NSDocumentController sharedDocumentController] setShouldCreateUI:YES];
        [[NSDocumentController sharedDocumentController] addDocument:doc];
        [doc makeWindowControllers];
        [doc showWindows];
    } else {
        if(error)
            *error = nsError == nil ? NSLocalizedString(@"Unable to interpret text as bibliography data.", @"") : [nsError localizedDescription];
        // @@ 10.3 compatibility
        if([self respondsToSelector:@selector(presentError:)])
            [[NSDocumentController sharedDocumentController] presentError:nsError];
    }
}

- (void)addPublicationsFromSelection:(NSPasteboard *)pboard
						   userData:(NSString *)userData
							  error:(NSString **)error{	
	
	// add to the frontmost bibliography
	BibDocument * doc = [[NSApp orderedDocuments] firstObject];
    if (!doc) {
		// if there are no open documents, give an error. 
		// Or rather create a new document and add the entry there? Would anybody want that?
		*error = NSLocalizedString(@"Error: No open document", @"BibDesk couldn't import the selected information because there is no open bibliography file to add it to. Please create or open a bibliography file and try again.");
		return;
	}
	NSError *addError = nil;
	if([doc addPublicationsFromPasteboard:pboard error:&addError] == NO || addError != nil)
        if(error) *error = [addError localizedDescription];
}

#pragma mark Spotlight support

OFWeakRetainConcreteImplementation_NULL_IMPLEMENTATION

- (void)rebuildMetadataCache:(id)userInfo{
        
    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3)
        return;
    
    [metadataMessageQueue queueSelector:@selector(privateRebuildMetadataCache:) forObject:self withObject:userInfo];
}

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
    NSError *error = nil;
    
    @try{
        
        NSString *cachePath = [[NSFileManager defaultManager] spotlightCacheFolderPathByCreating:&error];
        if(cachePath == nil){
            OFError(&error, NSCocoaErrorDomain, NSLocalizedDescriptionKey, NSLocalizedString(@"Unable to create the cache folder for Spotlight metadata.", @""), nil);
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Unable to build metadata cache at path \"%@\"", cachePath] userInfo:nil];
        }
        
        NSString *docPath = [userInfo valueForKey:@"fileName"];
        
        // After this point, there should be no underlying NSError, so we'll create one from scratch
        
        if([[NSFileManager defaultManager] fileExistsAtPath:docPath] == NO){
            error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to find the file associated with this item.", @""), NSLocalizedDescriptionKey, docPath, NSFilePathErrorKey, nil]];
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Unable to build metadata cache for document at path \"%@\"", docPath] userInfo:nil];
        }
        
        NSString *path;
        NSString *citeKey;
        BibItem *anItem;
        NSDate *dateModified;
        
        BDAlias *alias = [[BDAlias alloc] initWithPath:docPath];
        if(alias == nil){
            error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to create an alias for this document.", @""), NSLocalizedDescriptionKey, docPath, NSFilePathErrorKey, nil]];
            @throw [NSException exceptionWithName:NSObjectNotAvailableException reason:[NSString stringWithFormat:@"Unable to get an alias for file %@", docPath] userInfo:nil];
        }
        
        NSData *aliasData = [alias aliasData];
        [alias release];
    
        NSEnumerator *entryEnum = [publications objectEnumerator];
        NSString *mdValue = nil;
        unsigned int rating;
        id array = nil;
        
        BOOL readFieldIsTristate = [[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKTriStateFieldsKey] containsObject:BDSKReadString];
        
        while(anItem = [entryEnum nextObject]){
            citeKey = [anItem citeKey];
            
            if(citeKey == nil)
                continue;

            // we won't index this, but it's needed to reopen the parent file
            [metadata setObject:aliasData forKey:@"FileAlias"];
            [metadata setObject:docPath forKey:@"net_sourceforge_bibdesk_owningfilepath"]; // use as a backup in case the alias fails

            [metadata setObject:citeKey forKey:@"net_sourceforge_bibdesk_citekey"];
            
            // A given item is not guaranteed to have all of these, so make sure they are non-nil
            mdValue = [anItem displayTitle];
            if(mdValue != nil){
                [metadata setObject:mdValue forKey:(NSString *)kMDItemTitle];
                
                // this is what shows up in search results
                [metadata setObject:mdValue forKey:(NSString *)kMDItemDisplayName];
            } else {
                [metadata setObject:@"Unknown" forKey:(NSString *)kMDItemDisplayName];
            }
            
            array = [anItem pubAuthorsAsStrings];
            [metadata setObject:(array ? array : [NSArray array]) forKey:(NSString *)kMDItemAuthors];
            
            mdValue = [[anItem valueOfField:BDSKAbstractString] stringByRemovingTeX];
            if(mdValue != nil)
                [metadata setObject:mdValue forKey:(NSString *)kMDItemDescription];
            
            if( (dateModified = [anItem dateModified]) != nil)
                [metadata setObject:dateModified forKey:(NSString *)kMDItemContentModificationDate];
            
            // keywords is supposed to be a CFArray type, so we'll use the group splitting code
            array = [anItem valueForKey:@"keywordsArray"];
            if(array != nil)
                [metadata setObject:array forKey:(NSString *)kMDItemKeywords];
            
            if((rating = [anItem rating]))
                [metadata setObject:[NSNumber numberWithInt:rating] forKey:(NSString *)kMDItemStarRating];
            
            // supporting tri-state fields will need a new key of type CFNumber; it will only show up as a number in get info, though, which is not particularly useful
			if(readFieldIsTristate == NO)
                [metadata setValue:(id)([anItem boolValueOfField:BDSKReadString] ? kCFBooleanTrue : kCFBooleanFalse) forKey:@"net_sourceforge_bibdesk_itemreadstatus"];
            
            // kMDItemWhereFroms is the closest we get to a URL field, so add our standard fields if available
            array = [[NSMutableArray alloc] initWithCapacity:2];
            
            mdValue = [[anItem URLForField:BDSKUrlString] absoluteString];
            if(mdValue) [array addObject:mdValue];
            
            // calling one of the BibItem URL wrapper methods is unsafe since they call -[NSDocument fileName]
            mdValue = [[anItem localFileURLForField:BDSKLocalUrlString relativeTo:docPath inherit:YES] absoluteString];
            mdValue = [[anItem URLForField:BDSKLocalUrlString] absoluteString];
            if(mdValue) [array addObject:mdValue];
            
            [metadata setValue:array forKey:(NSString *)kMDItemWhereFroms];
            [array release];
			
            // We use citeKey as the file's name, since it needs to be unique and static (relatively speaking), so we can overwrite the old cache content with newer content when saving the document.  We replace pathSeparator in paths, as we can't create subdirectories with -[NSDictionary writeToFile:] (currently this is the POSIX path separator).
            path = citeKey;
            NSString *pathSeparator = [NSString pathSeparator];
            if([path rangeOfString:pathSeparator].length){
                NSMutableString *mutablePath = [[path mutableCopy] autorelease];
                // replace with % as it can't occur in a cite key, so will still be unique
                [mutablePath replaceOccurrencesOfString:pathSeparator withString:@"%" options:0 range:NSMakeRange(0, [path length])];
                path = mutablePath;
            }
            path = [cachePath stringByAppendingPathComponent:[path stringByAppendingPathExtension:@"bdskcache"]];
            
            // Save the plist; we can get an error if these are not plist objects, or the file couldn't be written.  The first case is a programmer error, and the second should have been caught much earlier in this code.
            if([metadata writeToFile:path atomically:YES] == NO){
                error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to save metadata cache file.", @""), NSLocalizedDescriptionKey, path, NSFilePathErrorKey, nil]];
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Unable to create file %@", path] userInfo:nil];
            }                
            [metadata removeAllObjects];
        }
    }    
    @catch (NSException *localException){
        NSLog(@"%@ discarding %@ %@", NSStringFromSelector(_cmd), [localException name], [localException reason]);
        NSLog(@"The error was: \"%@\"", [error description]);
        [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
    }
    @finally{
        [userInfo release];
        [metadata release];
        [metadataCacheLock unlock];
        [pool release];
    }
}

@end
