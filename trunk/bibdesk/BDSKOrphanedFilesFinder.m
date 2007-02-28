//
//  BDSKOrphanedFilesFinder.m
//  BibDesk
//
//  Created by Christiaan Hofman on 8/11/06.
/*
 This software is Copyright (c) 2005,2006,2007
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

#import "BDSKOrphanedFilesFinder.h"
#import "BibPrefController.h"
#import "BibTypeManager.h"
#import "BibAppController.h"
#import "BibDocument.h"
#import "BibItem.h"
#import "NSString_BDSKExtensions.h"
#import "NSURL_BDSKExtensions.h"
#import "NSImage+Toolbox.h"
#import "NSBezierPath_BDSKExtensions.h"
#import "BDSKOrphanedFileServer.h"
#import "NSTableView_BDSKExtensions.h"
#import "BDSKFile.h"
#import "NSWindowController_BDSKExtensions.h"
#import "NSIndexSet_BDSKExtensions.h"
#import "BDSKFileMatcher.h"

@interface BDSKOrphanedFilesFinder (Private)
- (void)refreshOrphanedFiles;
- (void)findAlertDidEnd:(BDSKAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)restartServer;
- (void)startAnimationWithStatusMessage:(NSString *)message;
- (void)stopAnimationWithStatusMessage:(NSString *)message;
@end

@implementation BDSKOrphanedFilesFinder

static BDSKOrphanedFilesFinder *sharedFinder = nil;

+ (id)sharedFinder {
    if (sharedFinder == nil)
        sharedFinder = [[[self class] alloc] init];
    return sharedFinder;
}

- (id)init {
    if (self = [super init]) {
        orphanedFiles = [[NSMutableArray alloc] init];
        wasLaunched = NO;
    }
    return self;
}

- (void)dealloc {
    [server stopDOServer];
    [server release];
    [orphanedFiles release];
    [super dealloc];
}

- (void)awakeFromNib{
    [tableView setDoubleAction:@selector(showFile:)];
    [progressIndicator setUsesThreadedAnimation:YES];
}

- (NSString *)windowNibName{
    return @"BDSKOrphanedFilesFinder";
}

- (IBAction)showWindow:(id)sender{
    [super showWindow:sender];
    if (wasLaunched == NO) {
        wasLaunched = YES;
        [self refreshOrphanedFiles:sender];
    }
}

- (void)windowWillClose:(NSNotification *)aNotification{
    [self stopRefreshing:nil];
}

- (IBAction)showOrphanedFiles:(id)sender{
    [super showWindow:sender];
    [self refreshOrphanedFiles:nil];
    wasLaunched = YES;
}

- (IBAction)matchFilesWithPubs:(id)sender;
{
    [self close];
    [(BDSKFileMatcher *)[BDSKFileMatcher sharedInstance] matchFiles:[self orphanedFiles] withPublications:nil];
}

- (NSURL *)baseURL
{
    NSString *papersFolderPath = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKPapersFolderPathKey];
    
    // old prefs may not have a standarized path
    papersFolderPath = [papersFolderPath stringByStandardizingPath];
    
    if ([NSString isEmptyString:papersFolderPath]) {
        NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
        if ([documents count] == 1) {
            papersFolderPath = [[NSApp delegate] folderPathForFilingPapersFromDocument:[documents objectAtIndex:0]];
        } else {
            return nil;
        }
    }

    return [NSURL fileURLWithPath:papersFolderPath];
}

- (NSSet *)knownFiles
{
    NSSet *localFileFields = [[BibTypeManager sharedManager] localFileFieldsSet];
    NSEnumerator *docEnum = [[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
    BibDocument *doc;
    NSEnumerator *pubEnum;
    BibItem *pub;
    NSEnumerator *fieldEnum;
    NSString *field;
    NSURL *fileURL;
    
    NSMutableSet *knownFiles = [NSMutableSet set];
    
    while (doc = [docEnum nextObject]) {
        fileURL = [doc fileURL];
        if (fileURL)
            [knownFiles addObject:[BDSKFile fileWithURL:fileURL]];;
        pubEnum = [[doc publications] objectEnumerator];
        while (pub = [pubEnum nextObject]) {
            fieldEnum = [localFileFields objectEnumerator];
            while (field = [fieldEnum nextObject]) {
                fileURL = [pub localFileURLForField:field];
                if (fileURL)
                    [knownFiles addObject:[BDSKFile fileWithURL:fileURL]];
            }
        }
    }
    return knownFiles;
}

- (IBAction)refreshOrphanedFiles:(id)sender{
    
    NSString *papersFolderPath = [[self baseURL] path];
    
    if ([NSHomeDirectory() isEqualToString:papersFolderPath]) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Find Orphaned Files", @"Message in alert dialog when trying to find orphaned files in Home folder")
                                         defaultButton:NSLocalizedString(@"Find", @"Button title: find orphaned files")
                                       alternateButton:NSLocalizedString(@"Don't Find", @"Button title: don't find orphaned files")
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"You have chosen your Home Folder as your Papers Folder. Finding all orphaned files in this folder could take a long time. Do you want to proceed?", @"Informative text in alert dialog")];
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:self
                         didEndSelector:@selector(findAlertDidEnd:returnCode:contextInfo:)
                            contextInfo:NULL];
    } else {
        [self refreshOrphanedFiles];
    }

}

- (IBAction)stopRefreshing:(id)sender{
    [server stopEnumerating];
}

- (IBAction)search:(id)sender{
    [arrayController setSearchString:[sender stringValue]];
    [arrayController rearrangeObjects];
    unsigned int count = [[arrayController arrangedObjects] count];
    NSString *message = count == 1 ? [NSString stringWithFormat:NSLocalizedString(@"%d orphaned file found", @"Status message"), count] : [NSString stringWithFormat:NSLocalizedString(@"%d orphaned files found", @"Status message"), count];
    [statusField setStringValue:message];
}    

#pragma mark Accessors
 
- (NSArray *)orphanedFiles {
    return [[orphanedFiles retain] autorelease];
}

- (unsigned)countOfOrphanedFiles {
    return [orphanedFiles count];
}

- (id)objectInOrphanedFilesAtIndex:(unsigned)theIndex {
    return [orphanedFiles objectAtIndex:theIndex];
}

- (void)insertObject:(id)obj inOrphanedFilesAtIndex:(unsigned)theIndex {
    [orphanedFiles insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromOrphanedFilesAtIndex:(unsigned)theIndex {
    [orphanedFiles removeObjectAtIndex:theIndex];
}

#pragma mark TableView stuff

// dummy dataSource implementation
- (int)numberOfRowsInTableView:(NSTableView *)tView{ return 0; }
- (id)tableView:(NSTableView *)tView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{ return nil; }

- (NSString *)tableView:(NSTableView *)tv toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation{
    return [[[arrayController arrangedObjects] objectAtIndex:row] path];
}

- (NSMenu *)tableView:(NSTableView *)tableView contextMenuForRow:(int)row column:(int)column{
    return contextMenu;
}

- (IBAction)showFile:(id)sender{
    NSArray *paths = [[arrayController selectedObjects] valueForKey:@"path"];
    if ([paths count] == 0)
        return;
    
    int type = -1;
    
    if(sender == tableView){
        if([tableView clickedColumn] == -1)
            return;
        type = 0;
    }else if([sender isKindOfClass:[NSMenuItem class]]){
        type = [sender tag];
    }
    
    NSString *path;
    NSEnumerator *pathEnum = [paths objectEnumerator];
    
    while (path = [pathEnum nextObject]) {
        if(type == 1)
            [[NSWorkspace sharedWorkspace] openFile:path];
        else
            [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil];
    }
}   

// for 10.3 compatibility and OmniAppKit dataSource methods
- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard{
	NSIndexSet *rowIndexes = [NSIndexSet indexSetWithIndexesInArray:rows];
	return [self tableView:tv writeRowsWithIndexes:rowIndexes toPasteboard:pboard];
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard{
    NSArray *filePaths = [[[arrayController arrangedObjects] objectsAtIndexes:rowIndexes] valueForKey:@"path"];
    [pboard declareTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil] owner:nil];
    [pboard setPropertyList:filePaths forType:NSFilenamesPboardType];
    return YES;
}

#pragma mark table dragimage

- (NSImage *)tableView:(NSTableView *)aTableView dragImageForRowsWithIndexes:(NSIndexSet *)dragRows{
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    NSString *dragType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
    NSImage *image = nil;
    int count = 0;
    
    if ([dragType isEqualToString:NSFilenamesPboardType]) {
		NSArray *fileNames = [pboard propertyListForType:NSFilenamesPboardType];
        count = [fileNames count];
		if (count)
            image = [[NSWorkspace sharedWorkspace] iconForFiles:fileNames];
    }
    
    return image ? [image dragImageWithCount:count] : nil;
}

#pragma mark table font

- (NSString *)tableViewFontNamePreferenceKey:(NSTableView *)tv {
    return BDSKOrphanedFilesTableViewFontNameKey;
}

- (NSString *)tableViewFontSizePreferenceKey:(NSTableView *)tv {
    return BDSKOrphanedFilesTableViewFontSizeKey;
}

@end


@implementation BDSKOrphanedFilesFinder (Private)

- (void)findAlertDidEnd:(BDSKAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    if (returnCode == NSAlertDefaultReturn)
        [self refreshOrphanedFiles];
}

- (void)refreshOrphanedFiles{
    [self startAnimationWithStatusMessage:[NSLocalizedString(@"Looking for orphaned files", @"Status message") stringByAppendingEllipsis]];
    // do the actual work with a zero delay to let the UI update 
    [self performSelector:@selector(restartServer) withObject:nil afterDelay:0.0];
}

- (void)restartServer{
    [[self mutableArrayValueForKey:@"orphanedFiles"] removeAllObjects];
    
    NSURL *baseURL = [self baseURL];
    
    if(baseURL){
        if(nil == server){
            server = [[BDSKOrphanedFileServer alloc] init];
            [server setDelegate:self];
        }
        
        id proxy = [server serverOnServerThread];
        if(nil == proxy){
            [self performSelector:_cmd withObject:nil afterDelay:0.1];
        } else {
            [proxy checkForOrphansWithKnownFiles:[self knownFiles] baseURL:baseURL];
        }
        
    } else {
        NSBeep();
        [self stopAnimationWithStatusMessage:NSLocalizedString(@"Unknown papers folder.", @"Status message")];
    }
}

- (void)startAnimationWithStatusMessage:(NSString *)message{
    [progressIndicator startAnimation:nil];
    [refreshButton setTitle:NSLocalizedString(@"Stop", @"Button title")];
    [refreshButton setAction:@selector(stopRefreshing:)];
    [refreshButton setToolTip:NSLocalizedString(@"Stop looking for orphaned files", @"Tool tip message")];
    [statusField setStringValue:message];
}

- (void)stopAnimationWithStatusMessage:(NSString *)message{
    [progressIndicator stopAnimation:nil];
    [refreshButton setTitle:NSLocalizedString(@"Refresh", @"Button title")];
    [refreshButton setAction:@selector(refreshOrphanedFiles:)];
    [refreshButton setToolTip:NSLocalizedString(@"Refresh the list of orphaned files", @"Tool tip message")];
    [statusField setStringValue:message];
}

// server delegate methods
- (void)orphanedFileServer:(BDSKOrphanedFileServer *)aServer foundFiles:(NSArray *)newFiles{
    NSMutableArray *mutableArray = [self mutableArrayValueForKey:@"orphanedFiles"];
    [mutableArray addObjectsFromArray:newFiles];
    unsigned int count = [[arrayController arrangedObjects] count];
    NSString *message = count == 1 ? [NSString stringWithFormat:NSLocalizedString(@"%d orphaned file found", @"Status message"), count] : [NSString stringWithFormat:NSLocalizedString(@"%d orphaned files found", @"Status message"), count];
    [statusField setStringValue:[message stringByAppendingEllipsis]];
}

- (void)orphanedFileServerDidFinish:(BDSKOrphanedFileServer *)aServer{
    unsigned int count = [[arrayController arrangedObjects] count];
    NSString *message = count == 1 ? [NSString stringWithFormat:NSLocalizedString(@"%d orphaned file found", @"Status message"), count] : [NSString stringWithFormat:NSLocalizedString(@"%d orphaned files found", @"Status message"), count];
    if ([server allFilesEnumerated] == NO)
        message = [NSString stringWithFormat:@"%@. %@", NSLocalizedString(@"Stopped", @"Partial status message"), message];
    [self stopAnimationWithStatusMessage:message];
}

@end

#pragma mark -
#pragma mark Array controller subclass for searching

@interface NSURL (BDSKPathSearch)
- (BOOL)pathContainsSubstring:(NSString *)aString;
@end

@implementation NSURL (BDSKPathSearch)

// compare case-insensitive and non-literal
- (BOOL)pathContainsSubstring:(NSString *)aString;
{
    CFURLRef theURL = (CFURLRef)self;
    CFStringRef path = CFURLCopyFileSystemPath(theURL, kCFURLPOSIXPathStyle);
    BOOL found = NO;
    if(path){
        found = CFStringFindWithOptions(path, (CFStringRef)aString, CFRangeMake(0, CFStringGetLength(path)), kCFCompareNonliteral | kCFCompareCaseInsensitive, NULL);
        CFRelease(path);
    }
    return found;
}

@end

@implementation BDSKOrphanedFilesArrayController

- (void)updateTemplateMenu
{
    NSMenu *menu = [[[searchField cell] searchMenuTemplate] copyWithZone:[NSMenu menuZone]];
    [[menu itemAtIndex:0] setState:(showsMatches ? NSOnState : NSOffState)];
    [[menu itemAtIndex:1] setState:(showsMatches ? NSOffState : NSOnState)];
    [[searchField cell] setSearchMenuTemplate:menu];
    [menu release];
}

- (void)awakeFromNib
{
    showsMatches = YES;
    [self updateTemplateMenu];   
}

- (void)dealloc
{
    [self setSearchString:nil];
    [super dealloc];
}

- (void)setSearchString:(NSString *)aString;
{
    [searchString autorelease];
    searchString = [aString copy];
}

- (NSString *)searchString { return searchString; }

- (IBAction)showMatches:(id)sender;
{
    showsMatches = YES;
    [self updateTemplateMenu];
    [self rearrangeObjects];
}

- (IBAction)hideMatches:(id)sender;
{
    showsMatches = NO;
    [self updateTemplateMenu];
    [self rearrangeObjects];
}

- (NSArray *)arrangeObjects:(NSArray *)objects
{
    if([NSString isEmptyString:searchString])
        return [super arrangeObjects:objects];
    
    NSMutableArray *array = [[objects mutableCopy] autorelease];
    unsigned i = [array count];
    BOOL itemMatches;
    while(i--){
        itemMatches = [[array objectAtIndex:i] pathContainsSubstring:searchString];
        if((itemMatches && showsMatches == NO) || (itemMatches == NO && showsMatches))
            [array removeObjectAtIndex:i];
    }
    
    return [super arrangeObjects:array];
}

@end
