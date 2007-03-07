//  BibAppController.m

//  Created by Michael McCracken on Sat Jan 19 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006,2007
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
#import "BDSKOwnerProtocol.h"
#import <Carbon/Carbon.h>
#import "BibPrefController.h"
#import "BibItem.h"
#import "BibAuthor.h"
#import "BDSKPreviewer.h"
#import "NSString_BDSKExtensions.h"
#import "BibTypeManager.h"
#import "BDSKCharacterConversion.h"
#import "BDSKFindController.h"
#import "BDSKScriptMenu.h"
#import "BibDocument.h"
#import "BibDocument_Search.h"
#import "BibDocument_Actions.h"
#import "BibDocument_Groups.h"
#import "BDSKFormatParser.h"
#import "BDAlias.h"
#import "BDSKErrorObjectController.h"
#import "NSFileManager_BDSKExtensions.h"
#import "OFCharacterSet_BDSKExtensions.h"
#import "BDSKSharingBrowser.h"
#import "BDSKSharingServer.h"
#import "BDSKPreferenceController.h"
#import "BDSKTemplateParser.h"
#import "BDSKTemplate.h"
#import "BDSKTemplateObjectProxy.h"
#import "NSSet_BDSKExtensions.h"
#import "NSURL_BDSKExtensions.h"
#import "NSMenu_BDSKExtensions.h"
#import "BDSKReadMeController.h"
#import "BDSKOrphanedFilesFinder.h"
#import "NSWindowController_BDSKExtensions.h"
#import "BDSKUpdateChecker.h"
#import "BDSKPublicationsArray.h"
#import "NSArray_BDSKExtensions.h"
#import "NSObject_BDSKExtensions.h"
#import "BibDeskSearchForCommand.h"
#import "BDSKCompletionServerProtocol.h"
#import "BDSKDocumentController.h"
#import "NSError_BDSKExtensions.h"
#import "BDSKSpotlightIconController.h"
#import "NSImage+Toolbox.h"
#import <libkern/OSAtomic.h>
#import "BDSKFileMatcher.h"

@implementation BibAppController

// remove legacy comparisons of added/created/modified strings in table column code from prefs
// maybe we can support transforming these in the add field sheets, if we want to allow some 
// sort of fuzzy matching?
static NSArray *fixLegacyTableColumnIdentifiers(NSArray *tableColumnIdentifiers){
    unsigned index;
    NSMutableArray *array = [[tableColumnIdentifiers mutableCopy] autorelease];
    
    index = [array indexOfObject:@"Added"];
    if(NSNotFound != index)
        [array replaceObjectAtIndex:index withObject:BDSKDateAddedString];
    
    index = [array indexOfObject:@"Created"];
    if(NSNotFound != index)
        [array replaceObjectAtIndex:index withObject:BDSKDateAddedString];
    
    index = [array indexOfObject:@"Modified"];
    if(NSNotFound != index)
        [array replaceObjectAtIndex:index withObject:BDSKDateModifiedString];
    
    index = [array indexOfObject:@"Authors Or Editors"];
    if(NSNotFound != index)
        [array replaceObjectAtIndex:index withObject:BDSKAuthorEditorString];
    
    index = [array indexOfObject:@"Authors"];
    if(NSNotFound != index)
        [array replaceObjectAtIndex:index withObject:BDSKAuthorString];
    
    return array;
}

static NSString *temporaryBaseDirectory = nil;
static void createTemporaryDirectory()
{
    OBASSERT([NSThread inMainThread]);
    // somewhere in /var/tmp, generally; contents moved to Trash on relaunch
    NSString *temporaryPath = NSTemporaryDirectory();
    
    // chewable items are automatically cleaned up at restart
    FSRef fileRef;
    OSErr err = FSFindFolder(kUserDomain, kChewableItemsFolderType, TRUE, &fileRef);
    
    NSURL *fileURL = nil;
    if (noErr == err)
        fileURL = [(id)CFURLCreateFromFSRef(CFAllocatorGetDefault(), &fileRef) autorelease];
    
    if (NULL != fileURL)
        temporaryPath = [fileURL path];
    
    temporaryBaseDirectory = [[[NSFileManager defaultManager] uniqueFilePath:[temporaryPath stringByAppendingPathComponent:@"bibdesk"] 
    createDirectory:YES] copy];    
}

+ (void)initialize
{
    OBINITIALIZE;
    
    // do this now to avoid race condition instead of creating it lazily and locking
    createTemporaryDirectory();    
    
    // make sure we use Spotlight's plugins on 10.4 and later
    SKLoadDefaultExtractorPlugIns();

    [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
            	
    // eliminate support for some redundant keys
    NSArray *prefsShownColNamesArray = [[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKShownColsNamesKey];
    if(prefsShownColNamesArray){
        prefsShownColNamesArray = fixLegacyTableColumnIdentifiers(prefsShownColNamesArray);
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:prefsShownColNamesArray forKey:BDSKShownColsNamesKey];
    }
    NSArray *searchKeys = [[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKQuickSearchKeys];
    if(searchKeys){
        searchKeys = fixLegacyTableColumnIdentifiers(searchKeys);
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:searchKeys forKey:BDSKQuickSearchKeys];
    }
    
    // @@ legacy pref key removed prior to release of 1.3.1 (stored path instead of alias)
    NSString *filePath = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:@"Default Bib File"];
    if(filePath) {
        BDAlias *alias = [BDAlias aliasWithPath:filePath];
        if(alias)
            [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:[alias aliasData] forKey:BDSKDefaultBibFileAliasKey];
        [[OFPreferenceWrapper sharedPreferenceWrapper] removeObjectForKey:@"Default Bib File"];
    }
    
    // name image to make it available app wide, also in IB
    static NSImage *cautionIcon = nil;
    cautionIcon = [[NSImage iconWithSize:NSMakeSize(16.0, 16.0) forToolboxCode:kAlertCautionIcon] retain];
    [cautionIcon setName:@"BDSKSmallCautionIcon"];
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
        canWriteMetadata = 1;
				
		NSString *formatString = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKCiteKeyFormatKey];
		NSString *error = nil;
		int button = 0;
		
		if ([BDSKFormatParser validateFormat:&formatString forField:BDSKCiteKeyString inFileType:BDSKBibtexString error:&error]) {
			[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:formatString forKey:BDSKCiteKeyFormatKey];
			[self setRequiredFieldsForCiteKey: [BDSKFormatParser requiredFieldsForFormat:formatString]];
		}else{
			button = NSRunCriticalAlertPanel(NSLocalizedString(@"The autogeneration format for Cite Key is invalid.", @"Message in alert dialog when detecting invalid cite key format"), 
											 @"%@",
											 NSLocalizedString(@"Go to Preferences", @"Button title"), 
											 NSLocalizedString(@"Revert to Default", @"Button title"), 
											 nil, [error safeFormatString], nil);
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
			button = NSRunCriticalAlertPanel(NSLocalizedString(@"The autogeneration format for Local-Url is invalid.", @"Message in alert dialog when detecting invalid Local-Url format"), 
											 @"%@",
											 NSLocalizedString(@"Go to Preferences", @"Button title"), 
											 NSLocalizedString(@"Revert to Default", @"Button title"), 
											 nil, [error safeFormatString], nil);
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
        
        // register server for cite key completion
        completionConnection = [[NSConnection alloc] initWithReceivePort:[NSPort port] sendPort:nil];
        NSProtocolChecker *checker = [NSProtocolChecker protocolCheckerWithTarget:self protocol:@protocol(BDSKCompletionServer)];
        [completionConnection setRootObject:checker];
        
        if ([completionConnection registerName:BIBDESK_SERVER_NAME] == NO)
            NSLog(@"failed to register completion connection %@", completionConnection);  
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
    [super dealloc];
}

- (void)awakeFromNib{   
    // Add a Scripts menu; searches in (mainbundle)/Contents/Scripts and (Library domains)/Application Support/BibDesk/Scripts
    if([BDSKScriptMenu disabled] == NO){
        [BDSKScriptMenu addScriptsToMainMenu];
    }

}

- (void)copyAllExportTemplatesToApplicationSupportAndOverwrite:(BOOL)overwrite{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupport = [fileManager currentApplicationSupportPathForCurrentUser];
    NSString *templates = @"Templates";
    NSString *templatesPath = [applicationSupport stringByAppendingPathComponent:templates];
    BOOL success = NO;
    
    if ([fileManager fileExistsAtPath:templatesPath isDirectory:&success] == NO) {
        success = [fileManager createDirectoryAtPath:templatesPath attributes:nil];
    }
    
    if (success) {
        [fileManager copyFileFromResourcesToApplicationSupport:[templates stringByAppendingPathComponent:@"htmlExportTemplate.html"] overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:[templates stringByAppendingPathComponent:@"htmlItemExportTemplate.html"] overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:[templates stringByAppendingPathComponent:@"htmlExportStyleSheet.css"] overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:[templates stringByAppendingPathComponent:@"rssExportTemplate.rss"] overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:[templates stringByAppendingPathComponent:@"rtfExportTemplate.rtf"] overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:[templates stringByAppendingPathComponent:@"rtfdExportTemplate.rtfd"] overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:[templates stringByAppendingPathComponent:@"docExportTemplate.doc"] overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:[templates stringByAppendingPathComponent:@"citeServiceTemplate.txt"] overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:[templates stringByAppendingPathComponent:@"textServiceTemplate.txt"] overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:[templates stringByAppendingPathComponent:@"rtfServiceTemplate.rtf"] overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:[templates stringByAppendingPathComponent:@"rtfServiceTemplate default item.rtf"] overwrite:overwrite];
        [fileManager copyFileFromResourcesToApplicationSupport:[templates stringByAppendingPathComponent:@"rtfServiceTemplate book.rtf"] overwrite:overwrite];
    }    
}

#pragma mark Application delegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    
    // register services
    [NSApp setServicesProvider:self];
    [NSApp registerServicesMenuSendTypes:[NSArray arrayWithObject:NSStringPboardType] returnTypes:[NSArray arrayWithObject:NSStringPboardType]];
    
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    if(![versionString isEqualToString:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKLastVersionLaunchedKey]])
        [self showRelNotes:nil];
    if([[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKLastVersionLaunchedKey] == nil) // show new users the readme file; others just see the release notes
        [self showReadMeFile:nil];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:versionString forKey:BDSKLastVersionLaunchedKey];
    
    [[BDSKUpdateChecker sharedChecker] scheduleUpdateCheckIfNeeded];
    
    BOOL inputManagerIsCurrent;
    if([self isInputManagerInstalledAndCurrent:&inputManagerIsCurrent] && inputManagerIsCurrent == NO)
        [self showInputManagerUpdateAlert];
    
    // Ensure the previewer and TeX task get created now in order to avoid a spurious "unable to copy helper file" warning when quit->document window closes->first call to [BDSKPreviewer sharedPreviewer]
    if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKUsesTeXKey])
        [BDSKPreviewer sharedPreviewer];
	
	if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShowingPreviewKey])
		[[BDSKPreviewer sharedPreviewer] showWindow:self];
    
    // copy files to application support
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [self copyAllExportTemplatesToApplicationSupportAndOverwrite:NO];        
    [fileManager copyFileFromResourcesToApplicationSupport:@"previewtemplate.tex" overwrite:NO];
    [fileManager copyFileFromResourcesToApplicationSupport:@"template.txt" overwrite:NO];   
    
    [self doSpotlightImportIfNeeded];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification{
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&canWriteMetadata);
    
    [[BDSKSharingServer defaultServer] disableSharing];
    
    [completionConnection registerName:nil];
    [[completionConnection receivePort] invalidate];
    [[completionConnection sendPort] invalidate];
    [completionConnection invalidate];
    [completionConnection release];
    
}

static BOOL fileIsInTrash(NSURL *fileURL)
{
    NSCParameterAssert([fileURL isFileURL]);    
    FSRef parentRef;
    if (CFURLGetFSRef((CFURLRef)[fileURL URLByDeletingLastPathComponent], &parentRef)) {
        OSStatus err;
        FSRef fsRef;
        err = FSFindFolder(kUserDomain, kTrashFolderType, TRUE, &fsRef);
        if (noErr == err && noErr == FSCompareFSRefs(&fsRef, &parentRef))
            return YES;
        
        err = FSFindFolder(kOnAppropriateDisk, kSystemTrashFolderType, TRUE, &fsRef);
        if (noErr == err && noErr == FSCompareFSRefs(&fsRef, &parentRef))
            return YES;
    }
    return NO;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    OFPreferenceWrapper *defaults = [OFPreferenceWrapper sharedPreferenceWrapper];
    int flag = [[defaults objectForKey:BDSKStartupBehaviorKey] intValue];
    switch(flag){
        case 0:
            return YES;
        case 1:
            return NO;
        case 2:
            {
                // this will be called each time the dock icon is clicked, but we only want to show the open dialog once
                static BOOL isOpening = NO;
                if(NO == isOpening){
                    isOpening = YES;
                    [[NSDocumentController sharedDocumentController] openDocument:nil];
                    isOpening = NO;
                }
            }
            return NO;
        case 3:
            {
                NSData *data = [defaults objectForKey:BDSKDefaultBibFileAliasKey];
                BDAlias *alias = nil;
                if([data length])
                    alias = [BDAlias aliasWithData:data];
                NSURL *fileURL = [alias fileURL];
                if(fileURL && NO == fileIsInTrash(fileURL))
                    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL display:YES error:NULL];
            }
            return NO;
        case 4:
            {
                NSArray *files = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKLastOpenFileNamesKey];
                NSEnumerator *fileEnum = [files objectEnumerator];
                NSDictionary *dict;
                NSURL *fileURL;
                while (dict = [fileEnum nextObject]){ 
                    fileURL = [[BDAlias aliasWithData:[dict objectForKey:@"_BDAlias"]] fileURL];
                    if(fileURL == nil)
                        fileURL = [NSURL fileURLWithPath:[dict objectForKey:@"fileName"]];
                    if(fileURL)
                        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL display:YES error:NULL];
                }
            }
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
    NSError *error;
    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES error:&error];
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
        anItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[url lastPathComponent] action:@selector(openRecentItemFromDock:) keyEquivalent:@""];
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

- (void)applicationDidBecomeActive:(NSNotification *)aNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:OAFlagsChangedNotification object:[NSApp currentEvent]];
}

#pragma mark Temporary files and directories

- (NSString *)temporaryFilePath:(NSString *)fileName createDirectory:(BOOL)create{
	if(nil == fileName) {
        // NSProcessInfo isn't thread-safe, so use CFUUID instead of globallyUniqueString
        CFAllocatorRef alloc = CFAllocatorGetDefault();
        CFUUIDRef uuid = CFUUIDCreate(alloc);
        fileName = [(id)CFUUIDCreateString(alloc, uuid) autorelease];
        CFRelease(uuid);
    }
	NSString *tmpFilePath = [temporaryBaseDirectory stringByAppendingPathComponent:fileName];
	return [[NSFileManager defaultManager] uniqueFilePath:tmpFilePath 
										  createDirectory:create];
}

#pragma mark Menu stuff

- (NSMenu *)groupSortMenu {
	return groupSortMenu;
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem{
	SEL act = [menuItem action];

	if (act == @selector(toggleShowingPreviewPanel:)){ 
		// menu item for toggling the preview panel
		// set the on/off state according to the panel's visibility
		if ([[BDSKPreviewer sharedPreviewer] isWindowVisible]) {
			[menuItem setState:NSOnState];
		}else {
			[menuItem setState:NSOffState];
		}
		return YES;
	}
	else if (act == @selector(toggleShowingErrorPanel:)){ 
		// menu item for toggling the error panel
		// set the on/off state according to the panel's visibility
		if ([[BDSKErrorObjectController sharedErrorObjectController] isWindowVisible]) {
			[menuItem setState:NSOnState];
		}else {
			[menuItem setState:NSOffState];
		}
		return YES;
	}
    else if (act == @selector(toggleShowingOrphanedFilesPanel:)){ 
                
		// menu item for toggling the orphaned files panel
		// set the on/off state according to the panel's visibility
		if ([[BDSKOrphanedFilesFinder sharedFinder] isWindowVisible]) {
			[menuItem setState:NSOnState];
		}else {
			[menuItem setState:NSOffState];
		}
		return YES;
	}
	return YES;
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem {

	if ([toolbarItem action] == @selector(toggleShowingPreviewPanel:)) {
		return ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKUsesTeXKey]);
	}
	
    return [super validateToolbarItem:toolbarItem];
}

// implemented in order to prevent the Copy As > Template menu from being updated at every key event
- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action { return NO; }

- (void)menuNeedsUpdate:(NSMenu *)menu {
    
    if ([menu isEqual:columnsMenu]) {
                
        // remove all items; then fill it with the items from the current document
        while([menu numberOfItems])
            [menu removeItemAtIndex:0];
        
        BibDocument *document = (BibDocument *)[[NSDocumentController sharedDocumentController] currentDocument];
        [menu addItemsFromMenu:[document columnsMenu]];
        
    } else if ([menu isEqual:copyAsTemplateMenu]) {
    
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

- (NSString *)folderPathForFilingPapersFromDocument:(id<BDSKOwner>)owner {
	NSString *papersFolderPath = [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKPapersFolderPathKey];
	if ([NSString isEmptyString:papersFolderPath])
		papersFolderPath = [[[owner fileURL] path] stringByDeletingLastPathComponent];
	if ([NSString isEmptyString:papersFolderPath])
		papersFolderPath = NSHomeDirectory();
	return [papersFolderPath stringByExpandingTildeInPath];
}

#pragma mark Auto-completion stuff

- (void)addNamesForCompletion:(NSArray *)names {
    NSMutableSet *nameSet = [autoCompletionDict objectForKey:BDSKAuthorString];
    if (nil == nameSet) {
        nameSet = [[NSMutableSet alloc] initWithCapacity:500];
        [autoCompletionDict setObject:nameSet forKey:BDSKAuthorString];
        [nameSet release];
    }
    [nameSet addObjectsFromArray:names];
}

- (void)addString:(NSString *)string forCompletionEntry:(NSString *)entry{
    
	if(BDIsEmptyString((CFStringRef)entry) || [entry isNumericField] || [entry isURLField] || [entry isPersonField] || [entry isCitationField])	
		return;

    if([entry isEqualToString:BDSKBooktitleString])	
		entry = BDSKTitleString;
	
	NSMutableSet *completionSet = [autoCompletionDict objectForKey:entry];
	
    if (completionSet == nil) {
        completionSet = [[NSMutableSet alloc] initWithCapacity:500];
        [autoCompletionDict setObject:completionSet forKey:entry];
        [completionSet release];
    }
    
    // more efficient for the splitting and checking functions
    // also adding complex strings can lead to a crash after the containing document closes
    if([string isComplex]) string = [NSString stringWithString:string];

    if([entry isInvalidGroupField] ||
	   [entry isSingleValuedField]){ // add the whole string 
        [completionSet addObject:[string fastStringByCollapsingWhitespaceAndRemovingSurroundingWhitespace]];
        return;
    }
    
    NSCharacterSet *acSet = [[BibTypeManager sharedManager] separatorCharacterSetForField:entry];
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
    NSCharacterSet *acSet = [[BibTypeManager sharedManager] separatorCharacterSetForField:entry];

	if ([entry isEqualToString:BDSKEditorString])	
		entry = BDSKAuthorString;
	else if ([entry isEqualToString:BDSKBooktitleString])	
		entry = BDSKTitleString;
	
	// find a string to match, be consistent with addString:forCompletionEntry:
	NSRange searchRange = NSMakeRange(0, charRange.location);
	// find the first separator preceding the current word being entered
    NSRange punctuationRange = [fullString rangeOfCharacterFromSet:acSet
														   options:NSBackwardsSearch
															 range:searchRange]; // check to see if this is a keyword-type
    NSRange andRange = [fullString rangeOfString:@" and "
										 options:NSBackwardsSearch | NSLiteralSearch
										   range:searchRange]; // check to see if it's an author (not robust)
	unsigned matchStart = 0;
	// now find the beginning of the match, reflecting addString:forCompletionEntry:. We might be more sophisticated, like in groups
    if ([entry isPersonField]) {
		// these are delimited by "and"
		if (andRange.location != NSNotFound)
			matchStart = NSMaxRange(andRange);
    } else if([entry isInvalidGroupField] || [entry isSingleValuedField]){
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
    // all persons are keyed to author
	if ([entry isPersonField])	
		entry = BDSKAuthorString;
	else if ([entry isEqualToString:BDSKBooktitleString])	
		entry = BDSKTitleString;
	else if ([entry isCitationField])	
		entry = BDSKCrossrefString;
	
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

- (NSRange)rangeForUserCompletion:(NSRange)charRange forBibTeXString:(NSString *)fullString {
    static NSCharacterSet *punctuationCharSet = nil;
	if (punctuationCharSet == nil) {
		NSMutableCharacterSet *tmpSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
		[tmpSet addCharactersInString:@"#"];
		punctuationCharSet = [tmpSet copy];
		[tmpSet release];
	}
	// we extend, as we use a different set of punctuation characters as Apple does
	unsigned int prefixLength = 0;
	while (charRange.location > prefixLength && ![punctuationCharSet characterIsMember:[fullString characterAtIndex:charRange.location - prefixLength - 1]]) 
		prefixLength++;
	if (prefixLength > 0) {
		charRange.location -= prefixLength;
		charRange.length += prefixLength;
	}
	return charRange;
}

- (NSArray *)possibleMatches:(NSDictionary *)definitions forBibTeXString:(NSString *)fullString partialWordRange:(NSRange)charRange indexOfBestMatch:(int *)index{
    NSString *partialString = [fullString substringWithRange:charRange];
    NSMutableArray *matches = [NSMutableArray arrayWithCapacity:[definitions count]];
    NSEnumerator *keyE = [definitions keyEnumerator];
    NSString *key = nil;
    
    // Search the definitions case-insensitively; we match on key or value, but only return keys.
    while (key = [keyE nextObject]) {
        if ([key rangeOfString:partialString options:NSCaseInsensitiveSearch].location != NSNotFound ||
			[[definitions valueForKey:key] rangeOfString:partialString options:NSCaseInsensitiveSearch].location != NSNotFound)
            [matches addObject:key];
    }
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

#pragma mark DO completion

- (NSArray *)completionsForString:(NSString *)searchString;
{
	NSMutableArray *results = [NSMutableArray array];

    NSEnumerator *myEnum = [[NSApp orderedDocuments] objectEnumerator];
    BibDocument *document = nil;
    
    // for empty search string, return all items

    while (document = [myEnum nextObject]) {
        
        NSArray *pubs = [NSString isEmptyString:searchString] ? [document publications] : [document findMatchesFor:searchString];
        [results addObjectsFromArray:[pubs arrayByPerformingSelector:@selector(completionObject)]];
    }
	return results;
}

- (NSArray *)orderedDocumentURLs;
{
    NSMutableArray *theURLs = [NSMutableArray array];
    NSEnumerator *docE = [[NSApp orderedDocuments] objectEnumerator];
    id aDoc;
    while (aDoc = [docE nextObject]) {
        if ([aDoc fileURL])
            [theURLs addObject:[aDoc fileURL]];
    }
    return theURLs;
}

#pragma mark Version checking

- (IBAction)checkForUpdates:(id)sender{
    [[BDSKUpdateChecker sharedChecker] checkForUpdates:sender];  
}

#pragma mark Input manager

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
    NSAlert *anAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Autocomplete Plugin Needs Update", @"Message in alert dialog when plugin version")
                                       defaultButton:[NSLocalizedString(@"Open", @"Button title") stringByAppendingString:[NSString horizontalEllipsisString]]
                                     alternateButton:NSLocalizedString(@"Cancel", @"Button title")
                                         otherButton:nil
                           informativeTextWithFormat:NSLocalizedString(@"You appear to be using the BibDesk autocompletion plugin, and a newer version is available.  Would you like to open the completion preferences so that you can update the plugin?", @"Informative text in alert dialog")];
    int rv = [anAlert runModal];
    if(rv == NSAlertDefaultReturn){
        [[BDSKPreferenceController sharedPreferenceController] showPreferencesPanel:nil];
        [[BDSKPreferenceController sharedPreferenceController] setCurrentClientByClassName:@"BibPref_InputManager"];
    }
    
}

#pragma mark Panels

- (IBAction)showReadMeFile:(id)sender{
    [[BDSKReadMeController sharedReadMeController] showWindow:self];
}

- (IBAction)showRelNotes:(id)sender{
    [[BDSKRelNotesController sharedRelNotesController] showWindow:self];
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
    [[BDSKErrorObjectController sharedErrorObjectController] toggleShowingWindow:sender];
}

- (IBAction)toggleShowingPreviewPanel:(id)sender{
    [[BDSKPreviewer sharedPreviewer] toggleShowingWindow:sender];
}

- (IBAction)toggleShowingOrphanedFilesPanel:(id)sender{
    [[BDSKOrphanedFilesFinder sharedFinder] toggleShowingWindow:sender];
}

- (IBAction)matchFiles:(id)sender{
    [[BDSKFileMatcher sharedInstance] showWindow:sender];
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
            [searchConstraints setObject:queryString forKey:[queryKey fieldName]]; // BibItem field names are capitalized
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
                                   @"Error description for Service");
        return;
    }
    pboardString = [pboard stringForType:NSStringPboardType];
    if (!pboardString) {
        *error = NSLocalizedString(@"Error: couldn't complete text.",
                                   @"Error description for Service");
        return;
    }

    NSDictionary *searchConstraints = [self constraintsFromString:pboardString];
    
    if(searchConstraints == nil){
        *error = NSLocalizedString(@"Error: invalid search constraints.",
                                   @"Error description for Service");
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
                                   @"Error description for Service");
        return;
    }
    pboardString = [pboard stringForType:NSStringPboardType];
    if (!pboardString) {
        *error = NSLocalizedString(@"Error: couldn't complete text.",
                                   @"Error description for Service");
        return;
    }

    NSDictionary *searchConstraints = [self constraintsFromString:pboardString];
    
    if(searchConstraints == nil){
        *error = NSLocalizedString(@"Error: invalid search constraints.",
                                   @"Error description for Service");
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
                                   @"Error description for Service");
        return;
    }
    pboardString = [pboard stringForType:NSStringPboardType];
    if (!pboardString) {
        *error = NSLocalizedString(@"Error: couldn't complete text.",
                                   @"Error description for Service");
        return;
    }

    NSDictionary *searchConstraints = [self constraintsFromString:pboardString];
    
    if(searchConstraints == nil){
        *error = NSLocalizedString(@"Error: invalid search constraints.",
                                   @"Error description for Service");
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

// this only should return items that belong to a document, not items from external groups
// if this is ever changed, we should also change showPubWithKey:userData:error:
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
            [itemsFound addObjectsFromArray:[aDoc publicationsMatchingSearchString:[constraints objectForKey:constraintKey] 
                                                                           inField:constraintKey 
                                                                         fromArray:[aDoc publications]]];
        }
        // we have one set per search term, so copy it to an array and we'll get the next set of matches
        [arrayOfSets addObject:[[itemsFound copy] autorelease]];
        [itemsFound removeAllObjects];
    }
    
    // sort the sets in order of increasing length indexed 0-->[arrayOfSets length]
    NSSortDescriptor *setLengthSort = [[[NSSortDescriptor alloc] initWithKey:@"self.@count" ascending:YES selector:@selector(compare:)] autorelease];
    [arrayOfSets sortUsingDescriptors:[NSArray arrayWithObject:setLengthSort]];

    [itemsFound setSet:[arrayOfSets firstObject]]; // smallest set
    [itemsFound performSelector:@selector(intersectSet:) withObjectsFromArray:arrayOfSets];
    
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
                                   @"Error description for Service");
        return;
    }
    NSString *pboardString = [pboard stringForType:NSStringPboardType];
    NSSet *items = [self itemsMatchingCiteKey:pboardString];
    
    // if no matches, we'll return the original string unchanged
    if ([items count]) {
        pboardString = [[[[items allObjects] arrayByPerformingSelector:@selector(citeKey)] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] componentsJoinedByComma];
    }
    
    types = [NSArray arrayWithObject:NSStringPboardType];
    [pboard declareTypes:types owner:nil];
    [pboard setString:pboardString forType:NSStringPboardType];
}

- (void)showPubWithKey:(NSPasteboard *)pboard
			  userData:(NSString *)userData
				 error:(NSString **)error{	
    NSArray *types = [pboard types];
    if (![types containsObject:NSStringPboardType]) {
        *error = NSLocalizedString(@"Error: couldn't complete text.",
                                   @"Error description for Service");
        return;
    }
    NSString *pboardString = [pboard stringForType:NSStringPboardType];

    NSSet *items = [self itemsMatchingCiteKey:pboardString];
	BibItem *item;
	NSEnumerator *itemE = [items objectEnumerator];
    
    while(item = [itemE nextObject]){   
        // these should all be items belonging to a BibDocument, see remark before itemsMatchingSearchConstraints:
		[(BibDocument *)[item owner] editPub:item];
    }

}

- (void)newDocumentFromSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error{	

    id doc = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:NULL];
    NSError *nsError = nil;
    
    if([doc addPublicationsFromPasteboard:pboard selectLibrary:YES error:&nsError] == NO){
        if(error)
            *error = [nsError localizedDescription];
        [doc presentError:nsError];
    }
}

- (void)addPublicationsFromSelection:(NSPasteboard *)pboard
						   userData:(NSString *)userData
							  error:(NSString **)error{	
	
	// add to the frontmost bibliography
	BibDocument * doc = [[NSDocumentController sharedDocumentController] mainDocument];
    if (nil == doc) {
        // create a new document if we don't have one, or else this method appears to fail mysteriosly (since the error isn't displayed)
        [self newDocumentFromSelection:pboard userData:userData error:error];
	} else {
        NSError *addError = nil;
        if([doc addPublicationsFromPasteboard:pboard selectLibrary:YES error:&addError] == NO || addError != nil)
        if(error) *error = [addError localizedDescription];
    }
}

#pragma mark Spotlight support

OFWeakRetainConcreteImplementation_NULL_IMPLEMENTATION

- (void)rebuildMetadataCache:(id)userInfo{        
    [metadataMessageQueue queueSelector:@selector(privateRebuildMetadataCache:) forObject:self withObject:userInfo];
}

- (void)privateRebuildMetadataCache:(id)userInfo{
    
    OBPRECONDITION([NSThread inMainThread] == NO);
    
    // we could unlock after checking the flag, but we don't want multiple threads writing to the cache directory at the same time, in case files have identical items
    [metadataCacheLock lock];
    if(canWriteMetadata == 0){
        NSLog(@"Application will quit without writing metadata cache.");
        [metadataCacheLock unlock];
        return;
    }

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [userInfo retain];
    
    NSArray *publications = [userInfo valueForKey:@"publications"];
    NSMutableDictionary *metadata = nil;
    NSMutableArray *entries = nil;
    NSAutoreleasePool *innerPool = nil;
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    @try{

        // hidden option to use XML plists for easier debugging, but the binary plists are more efficient
        BOOL useXMLFormat = [[NSUserDefaults standardUserDefaults] boolForKey:@"BDSKUseXMLSpotlightCache"];
        NSPropertyListFormat plistFormat = useXMLFormat ? NSPropertyListXMLFormat_v1_0 : NSPropertyListBinaryFormat_v1_0;

        NSString *cachePath = [fileManager spotlightCacheFolderPathByCreating:&error];
        if(cachePath == nil){
            OFErrorWithInfo(&error, NSCocoaErrorDomain, NSLocalizedDescriptionKey, NSLocalizedString(@"Unable to create the cache folder for Spotlight metadata.", @"Error description"), nil);
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Unable to build metadata cache at path \"%@\"", cachePath] userInfo:nil];
        }
        
        NSURL *documentURL = [userInfo valueForKey:@"fileURL"];
        NSString *docPath = [documentURL path];
        
        // After this point, there should be no underlying NSError, so we'll create one from scratch
        
        if([fileManager objectExistsAtFileURL:documentURL] == NO){
            error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to find the file associated with this item.", @"Error description"), NSLocalizedDescriptionKey, docPath, NSFilePathErrorKey, nil]];
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Unable to build metadata cache for document at path \"%@\"", docPath] userInfo:nil];
        }
        
        NSString *path;
        NSString *citeKey;
        NSDictionary *anItem;
        
        BDAlias *alias = [[BDAlias alloc] initWithURL:documentURL];
        if(alias == nil){
            error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to create an alias for this document.", @"Error description"), NSLocalizedDescriptionKey, docPath, NSFilePathErrorKey, nil]];
            @throw [NSException exceptionWithName:NSObjectNotAvailableException reason:[NSString stringWithFormat:@"Unable to get an alias for file %@", docPath] userInfo:nil];
        }
        
        NSData *aliasData = [alias aliasData];
        [alias autorelease];
    
        NSEnumerator *entryEnum = [publications objectEnumerator];
        
        innerPool = [NSAutoreleasePool new];
        
        NSDictionary *dict;
        
        entries = [[NSMutableArray alloc] initWithCapacity:[publications count]];
        
        while(anItem = [entryEnum nextObject]){
            
            if(canWriteMetadata == 0){
                NSLog(@"Application will quit without finishing writing metadata cache.");
                break;
            }
            
            [innerPool release];
            innerPool = [NSAutoreleasePool new];
            
            citeKey = [anItem objectForKey:@"net_sourceforge_bibdesk_citekey"];
            if(citeKey == nil)
                continue;
            
            metadata = [[NSMutableDictionary alloc] initWithCapacity:10];
            
            // we won't index this, but it's needed to reopen the parent file
            [metadata setObject:aliasData forKey:@"FileAlias"];
            [metadata setObject:docPath forKey:@"net_sourceforge_bibdesk_owningfilepath"]; // use as a backup in case the alias fails
            
            [metadata addEntriesFromDictionary:anItem];
			
            path = [fileManager spotlightCacheFilePathWithCiteKey:citeKey];

            // Save the plist; we can get an error if these are not plist objects, or the file couldn't be written.  The first case is a programmer error, and the second should have been caught much earlier in this code.
            if(path) {
                
                NSString *errString = nil;
                NSData *data = [NSPropertyListSerialization dataFromPropertyList:metadata format:plistFormat errorDescription:&errString];
                if(nil == data) {
                    error = [NSError mutableLocalErrorWithCode:kBDSKPropertyListSerializationFailed localizedDescription:[NSString stringWithFormat:NSLocalizedString(@"Unable to save metadata cache file for item with cite key \"%@\".  The error was \"%@\"", @"Error description"), citeKey, errString]];
                    [errString release];
                    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Unable to create cache file for %@", [anItem description]] userInfo:nil];
                } else {
                    if(NO == [data writeToFile:path options:NSAtomicWrite error:&error])
                        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Unable to create cache file for %@", [anItem description]] userInfo:nil];
                    else {
                        dict =[[NSDictionary alloc] initWithObjectsAndKeys:metadata, @"metadata", path, @"path", nil];
                        [entries addObject:dict];
                        [dict release];
                    }
                }
            }
            
            [metadata release];
            metadata = nil;
        }
        
        [innerPool release];
        innerPool = nil;
        
        long version;
        OSStatus err = Gestalt(gestaltSystemVersion, &version);
        
        if (noErr == err && version < 0x00001050) {
            entryEnum = [entries objectEnumerator];
            
            innerPool = [NSAutoreleasePool new];
            
            while(anItem = [entryEnum nextObject]){
                
                if(canWriteMetadata == 0){
                    NSLog(@"Application will quit without finishing metadata cache icons.");
                    break;
                }
                
                [innerPool release];
                innerPool = [NSAutoreleasePool new];
                
                if ((metadata = [anItem objectForKey:@"metadata"]) && (path = [anItem objectForKey:@"path"]))
                    [[BDSKSpotlightIconController iconFamilyWithMetadataItem:metadata] setAsCustomIconForFile:path];
            }
            
            [innerPool release];
            innerPool = nil;
        }
        
        [entries release];
        entries = nil;
    }    
    @catch (id localException){
        NSLog(@"-[%@ %@] discarding exception %@", [self class], NSStringFromSelector(_cmd), [localException description]);
        // log the error since presentError: only gives minimum info
        NSLog(@"%@", [error description]);
        [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
        // if these are non-nil, they should be released
        [metadata release];
        [entries release];
        [innerPool release];
    }
    @finally{
        [userInfo release];
        [metadataCacheLock unlock];
        [pool release];
    }
}

- (void)doSpotlightImportIfNeeded {
    
    // This code finds the spotlight importer and re-runs it if the importer or app version has changed since the last time we launched.
    NSArray *pathComponents = [NSArray arrayWithObjects:[[NSBundle mainBundle] bundlePath], @"Contents", @"Library", @"Spotlight", @"BibImporter", nil];
    NSString *importerPath = [[NSString pathWithComponents:pathComponents] stringByAppendingPathExtension:@"mdimporter"];
    
    NSBundle *importerBundle = [NSBundle bundleWithPath:importerPath];
    NSString *importerVersion = [importerBundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    if (importerVersion) {
        OFVersionNumber *importerVersionNumber = [[[OFVersionNumber alloc] initWithVersionString:importerVersion] autorelease];
        NSDictionary *versionInfo = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKSpotlightVersionInfo];
        
        long sysVersion;
        OSStatus err = Gestalt(gestaltSystemVersion, &sysVersion);
        
        BOOL runImporter = NO;
        if ([versionInfo count] == 0) {
            runImporter = YES;
        } else {
            NSString *lastImporterVersion = [versionInfo objectForKey:@"lastImporterVersion"];
            OFVersionNumber *lastImporterVersionNumber = [[[OFVersionNumber alloc] initWithVersionString:lastImporterVersion] autorelease];
            
            long lastSysVersion = [[versionInfo objectForKey:@"lastSysVersion"] longValue];
            
            runImporter = noErr == err ? ([lastImporterVersionNumber compareToVersionNumber:importerVersionNumber] == NSOrderedAscending || sysVersion > lastSysVersion) : YES;
        }
        if (runImporter) {
            NSString *mdimportPath = @"/usr/bin/mdimport";
            if ([[NSFileManager defaultManager] isExecutableFileAtPath:mdimportPath]) {
                NSTask *importerTask = [[[NSTask alloc] init] autorelease];
                [importerTask setLaunchPath:mdimportPath];
                [importerTask setArguments:[NSArray arrayWithObjects:@"-r", importerPath, nil]];
                [importerTask launch];
                
                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:sysVersion], @"lastSysVersion", importerVersion, @"lastImporterVersion", nil];
                [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:info forKey:BDSKSpotlightVersionInfo];
                
            }
            else NSLog(@"/usr/bin/mdimport not found!");
        }
    }
}

@end
