//
//  SKDownloadController.m
//  Skim
//
//  Created by Christiaan Hofman on 8/11/07.
/*
 This software is Copyright (c) 2007-2018
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

#import "SKDownloadController.h"
#import "SKDownload.h"
#import "SKProgressCell.h"
#import "NSURL_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKTableView.h"
#import "SKTypeSelectHelper.h"
#import "NSString_SKExtensions.h"
#import "NSMenu_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSWindowController_SKExtensions.h"
#import "SKDownloadPreferenceController.h"
#import "NSError_SKExtensions.h"
#import "NSEvent_SKExtensions.h"
#import "NSFileManager_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import "NSView_SKExtensions.h"
#import "SKToolbarItem.h"
#import "SKLocalization.h"

#define SKDownloadsToolbarIdentifier                @"SKDownloadsToolbarIdentifier"
#define SKDownloadsToolbarPreferencesItemIdentifier @"SKDownloadsToolbarPreferencesItemIdentifier"
#define SKDownloadsToolbarClearItemIdentifier       @"SKDownloadsToolbarClearItemIdentifier"

#define PROGRESS_COLUMN 1
#define RESUME_COLUMN   2
#define CANCEL_COLUMN   3

#define ICON_COLUMNID     @"icon"
#define PROGRESS_COLUMNID @"progress"
#define RESUME_COLUMNID   @"resume"
#define CANCEL_COLUMNID   @"cancel"

#define DOWNLOADS_KEY @"downloads"

#define SKDownloadsWindowFrameAutosaveName @"SKDownloadsWindow"

static char SKDownloadPropertiesObservationContext;

static NSString *SKDownloadsIdentifier = nil;

#if SDK_BEFORE(10_7)
@interface NSView (SKLionDeclarations)
- (NSString *)identifier;
- (void)setIdentifier:(NSString *)newIdentifier;
@end

@interface NSTableView (SKLionDeclarations)
- (NSView *)makeViewWithIdentifier:(NSString *)identifier owner:(id)owner;
- (NSInteger)rowForView;
@end
#endif

@interface SKDownloadController (SKPrivate)
- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification;
- (void)startObservingDownloads:(NSArray *)newDownloads;
- (void)endObservingDownloads:(NSArray *)oldDownloads;
- (void)removeObjectFromDownloads:(SKDownload *)download;
- (void)updateClearButton;
@end

@implementation SKDownloadController

@synthesize tableView, clearButton;

+ (void)initialize {
    SKINITIALIZE;
    
    SKDownloadsIdentifier = [[[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@".downloads"] retain];
}

static SKDownloadController *sharedDownloadController = nil;

+ (id)sharedDownloadController {
    if (sharedDownloadController == nil)
        sharedDownloadController = [[self alloc] init];
    return sharedDownloadController;
}

- (id)init {
    if (sharedDownloadController) NSLog(@"Attempt to allocate second instance of %@", [self class]);
    self = [super initWithWindowNibName:@"DownloadsWindow"];
    if (self) {
        downloads = [[NSMutableArray alloc] init];
        
        NSDictionary *downloadsDictionary = [[NSUserDefaults standardUserDefaults] persistentDomainForName:SKDownloadsIdentifier];
        for (NSDictionary *properties in [downloadsDictionary objectForKey:DOWNLOADS_KEY]) {
            SKDownload *download = [[SKDownload alloc] initWithProperties:properties];
            [downloads addObject:download];
            [download release];
        }
        
        [self startObservingDownloads:downloads];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleApplicationWillTerminateNotification:)
                                                     name:NSApplicationWillTerminateNotification
                                                   object:NSApp];
    }
    return self;
}

- (void)dealloc {
    [self endObservingDownloads:downloads];
    SKDESTROY(downloads);
    SKDESTROY(tableView);
    SKDESTROY(clearButton);
    [super dealloc];
}

- (void)windowDidLoad {
    // this isn't done by the superclass because it is not part of the window
    [clearButton localizeStringsFromTable:[self windowNibName]];
    [clearButton sizeToFit];
    
    [self setupToolbar];
    
    if ([[self window] respondsToSelector:@selector(setTitleVisibility:)])
        [[self window] setTitleVisibility:NSWindowTitleHidden];
    
    if ([[self window] respondsToSelector:@selector(setTabbingMode:)])
        [[self window] setTabbingMode:NSWindowTabbingModeDisallowed];
    
    [self updateClearButton];
    
    [self setWindowFrameAutosaveName:SKDownloadsWindowFrameAutosaveName];
    
    [[self window] setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
    [[self window] setContentBorderThickness:24.0 forEdge:NSMinYEdge];
    
    [tableView setTypeSelectHelper:[SKTypeSelectHelper typeSelectHelper]];
    
    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:(NSString *)kUTTypeURL, (NSString *)kUTTypeFileURL, NSURLPboardType, NSFilenamesPboardType, NSPasteboardTypeString, nil]];
    
    [tableView setSupportsQuickLook:YES];
}

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification  {
    [downloads makeObjectsPerformSelector:@selector(cancel) withObject:nil];
    NSDictionary *downloadsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[downloads valueForKey:@"properties"], DOWNLOADS_KEY, nil];
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:downloadsDictionary forName:SKDownloadsIdentifier];
}

- (void)updateClearButton {
    [clearButton setEnabled:[[self downloads] valueForKeyPath:@"@max.canRemove"]];
}

- (SKDownload *)addDownloadForURL:(NSURL *)aURL showWindow:(BOOL)flag {
    SKDownload *download = nil;
    if (aURL) {
        download = [[[SKDownload alloc] initWithURL:aURL] autorelease];
        NSInteger row = [self countOfDownloads];
        [self insertObject:download inDownloadsAtIndex:row];
        if (flag)
            [self showWindow:nil];
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        [tableView scrollRowToVisible:row];
    }
    return download;
}

- (SKDownload *)addDownloadForURL:(NSURL *)aURL {
    return [self addDownloadForURL:aURL showWindow:[[NSUserDefaults standardUserDefaults] boolForKey:SKAutoOpenDownloadsWindowKey]];
}

- (BOOL)pasteFromPasteboard:(NSPasteboard *)pboard {
    NSArray *theURLs = [NSURL readURLsFromPasteboard:pboard];
    for (NSURL *theURL in theURLs) {
        if ([theURL isFileURL]) {
            [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:theURL display:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error){}];
        } else {
            [self addDownloadForURL:theURL showWindow:NO];
        }
    }
    return [theURLs count] > 0;
}

- (void)openDownload:(SKDownload *)download {
    if ([download status] == SKDownloadStatusFinished) {
        NSURL *URL = [download fileURL];
        NSString *fragment = [[download URL] fragment];
        if ([fragment length] > 0)
            URL = [NSURL URLWithString:[[URL absoluteString] stringByAppendingFormat:@"#%@", fragment]];
        
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:URL display:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error){
            if (document == nil && [error isUserCancelledError] == NO)
                [self presentError:error];
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoRemoveFinishedDownloadsKey]) {
                [[download retain] autorelease];
                [self removeObjectFromDownloads:download];
                // for the document to note that the file has been deleted
                [document setFileURL:[download fileURL]];
                if ([self countOfDownloads] == 0 && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoCloseDownloadsWindowKey])
                    [[self window] close];
            }
        }];
    }
}

#pragma mark Images

+ (NSImage *)cancelImage {
    static NSImage *cancelImage = nil;
    if (cancelImage == nil) {    
        cancelImage = [[NSImage imageWithSize:NSMakeSize(16.0, 16.0) drawingHandler:^(NSRect rect){
            [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kToolbarDeleteIcon)] drawInRect:NSMakeRect(-2.0, -1.0, 20.0, 20.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
            return YES;
        }] retain];
    }
    return cancelImage;
}

+ (NSImage *)deleteImage {
    static NSImage *deleteImage = nil;
    if (deleteImage == nil) {
        deleteImage = [[NSImage imageWithSize:NSMakeSize(16.0, 16.0) drawingHandler:^(NSRect rect){
            if (RUNNING_AFTER(10_9)) {
                [[NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate] drawInRect:NSInsetRect(rect, 1.0, 1.0) fromRect:NSZeroRect operation:NSCompositeDestinationAtop fraction:1.0];
            } else {
                [[NSColor lightGrayColor] setFill];
                [[NSBezierPath bezierPathWithRect:NSInsetRect(rect, 1.0, 1.0)] fill];
                [[NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate] drawInRect:NSInsetRect(rect, 1.0, 1.0) fromRect:NSZeroRect operation:NSCompositeDestinationAtop fraction:1.0];
                [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositeDestinationOver];
                [[NSColor whiteColor] setFill];
                [[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(rect, 2.0, 2.0)] fill];
            }
            return YES;
        }] retain];
        if (RUNNING_AFTER(10_9))
            [deleteImage setTemplate:YES];
    }
    return deleteImage;
}

+ (NSImage *)resumeImage {
    static NSImage *resumeImage = nil;
    if (resumeImage == nil) {
        resumeImage = [[NSImage imageWithSize:NSMakeSize(16.0, 16.0) drawingHandler:^(NSRect rect){
            if (RUNNING_AFTER(10_9)) {
                [[NSImage imageNamed:NSImageNameRefreshFreestandingTemplate] drawInRect:NSInsetRect(rect, 1.0, 1.0) fromRect:NSZeroRect operation:NSCompositeDestinationAtop fraction:1.0];
            } else {
                [[NSColor lightGrayColor] setFill];
                [[NSBezierPath bezierPathWithRect:NSInsetRect(rect, 1.0, 1.0)] fill];
                [[NSImage imageNamed:NSImageNameRefreshFreestandingTemplate] drawInRect:NSInsetRect(rect, 1.0, 1.0) fromRect:NSZeroRect operation:NSCompositeDestinationAtop fraction:1.0];
                [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositeDestinationOver];
                [[NSColor whiteColor] setFill];
                [[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(rect, 2.0, 2.0)] fill];
            }
            return YES;
        }] retain];
        if (RUNNING_AFTER(10_9))
            [resumeImage setTemplate:YES];
    }
    return resumeImage;
}

#pragma mark Accessors

- (NSArray *)downloads {
    return [[downloads copy] autorelease];
}

- (NSUInteger)countOfDownloads {
    return [downloads count];
}

- (SKDownload *)objectInDownloadsAtIndex:(NSUInteger)anIndex {
    return [downloads objectAtIndex:anIndex];
}

- (void)insertObject:(SKDownload *)download inDownloadsAtIndex:(NSUInteger)anIndex {
    [downloads insertObject:download atIndex:anIndex];
    [self startObservingDownloads:[NSArray arrayWithObject:download]];
    [download start];
    if (RUNNING_BEFORE(10_7))
        [downloads makeObjectsPerformSelector:@selector(removeProgressIndicatorFromSuperview)];
    [tableView reloadData];
    [self updateClearButton];
}

- (void)removeObjectFromDownloadsAtIndex:(NSUInteger)anIndex {
    SKDownload *download = [downloads objectAtIndex:anIndex];
    [self endObservingDownloads:[NSArray arrayWithObject:download]];
    [download cancel];
    [downloads removeObjectAtIndex:anIndex];
    if (RUNNING_BEFORE(10_7))
        [downloads makeObjectsPerformSelector:@selector(removeProgressIndicatorFromSuperview)];
    [tableView reloadData];
    [self updateClearButton];
}

- (void)removeObjectFromDownloads:(SKDownload *)download {
    NSUInteger idx = [downloads indexOfObject:download];
    if (idx != NSNotFound)
        [self removeObjectFromDownloadsAtIndex:idx];
}

#pragma mark Actions

- (IBAction)showDownloadPreferences:(id)sender {
    SKDownloadPreferenceController *prefController = [[[SKDownloadPreferenceController alloc] init] autorelease];
    [prefController beginSheetModalForWindow:[self window] completionHandler:NULL];
}

- (IBAction)clearDownloads:(id)sender {
    NSInteger i = [self countOfDownloads];
    
    while (i-- > 0) {
        SKDownload *download = [self objectInDownloadsAtIndex:i];
        if ([download canRemove])
            [self removeObjectFromDownloadsAtIndex:i];
    }
}

- (IBAction)moveToTrash:(id)sender {
    SKDownload *download = nil;
    NSInteger row = [tableView selectedRow];
    if (row != -1)
        download = [self objectInDownloadsAtIndex:row];
    if ([download canRemove]) {
        if ([download status] == SKDownloadStatusFinished)
            [download moveToTrash];
        [self removeObjectFromDownloads:download];
    } else {
        NSBeep();
    }
}

- (SKDownload *)downloadForSender:(id)sender {
    SKDownload *download = nil;
    
    if ([sender respondsToSelector:@selector(representedObject)])
        download = [sender representedObject];
    
    if (download == nil) {
        NSInteger row = -1;
        if (sender == tableView)
            row = [tableView clickedRow];
        else
            row = [tableView rowForView:sender];
        if (row != -1)
            download = [self objectInDownloadsAtIndex:row];
    }
    
    return download;
}

- (void)cancelDownload:(id)sender {
    SKDownload *download = [self downloadForSender:sender];
    if ([download canCancel])
        [download cancel];
}

- (void)resumeDownload:(id)sender {
    SKDownload *download = [self downloadForSender:sender];
    if ([download canResume])
        [download resume];
}

- (void)removeDownload:(id)sender {
    SKDownload *download = [self downloadForSender:sender];
    if (download)
        [self removeObjectFromDownloads:download];
}

- (void)openDownloadedFile:(id)sender {
    SKDownload *download = [sender representedObject];
    
    if (download && [download status] != SKDownloadStatusFinished) {
        NSBeep();
    } else {
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[download fileURL] display:YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error){
            if (document == nil && [error isUserCancelledError] == NO)
                [self presentError:error];
        }];
    }
}

- (void)previewDownloadedFile:(id)sender {
    SKDownload *download = [sender representedObject];
    
    if (download && [download status] != SKDownloadStatusFinished) {
        NSBeep();
    } else if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
        [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
    } else {
        NSUInteger row = [downloads indexOfObject:download];
        if (row != NSNotFound)
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
    }
}

- (void)revealDownloadedFile:(id)sender {
    SKDownload *download = [sender representedObject];
    
    if (download && [download status] != SKDownloadStatusFinished) {
        NSBeep();
    } else {
        [[NSWorkspace sharedWorkspace] selectFile:[[download fileURL] path] inFileViewerRootedAtPath:@""];
    }
}

- (void)trashDownloadedFile:(id)sender {
    SKDownload *download = [sender representedObject];
    
    if (download && [download status] != SKDownloadStatusFinished)
        NSBeep();
    else
        [download moveToTrash];
}

#pragma mark Menu validation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(moveToTrash:)) {
        NSInteger row = [tableView selectedRow];
        return (row != -1 && [[self objectInDownloadsAtIndex:row] canRemove]);
    }
    return YES;
}

#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv {
    return [self countOfDownloads];
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    SKDownload *download = [self objectInDownloadsAtIndex:row];
    NSString *identifier = [tableColumn identifier];
    if ([identifier isEqualToString:ICON_COLUMNID])
        return [download fileIcon];
    else if ([identifier isEqualToString:PROGRESS_COLUMNID])
        return [download info];
    else
        return nil;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
    NSPasteboard *pboard = [info draggingPasteboard];
    if ([NSURL canReadURLFromPasteboard:pboard]) {
        [tv setDropRow:-1 dropOperation:NSTableViewDropOn];
        return NSDragOperationEvery;
    }
    return NSDragOperationNone;
}
       
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op {
    return [self pasteFromPasteboard:[info draggingPasteboard]];
}

#pragma mark NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tv viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    SKDownload *download = [self objectInDownloadsAtIndex:row];
    NSString *identifier = [tableColumn identifier];
    NSView *view = [tv makeViewWithIdentifier:identifier owner:nil];
    if (view == nil) {
        NSCell *cell = [[tableColumn dataCell] copy];
        if ([cell isKindOfClass:[NSImageCell class]])
            view = [[[NSImageView alloc] init] autorelease];
        else if ([cell isKindOfClass:[NSTextFieldCell class]])
            view = [[[NSTextField alloc] init] autorelease];
        else if ([cell isKindOfClass:[NSButtonCell class]])
            view = [[[NSButton alloc] init] autorelease];
        [(NSControl *)view setCell:cell];
        [cell release];
        [view setIdentifier:identifier];
    }
    if ([identifier isEqualToString:ICON_COLUMNID]) {
        if ([view isKindOfClass:[NSImageView class]])
            [(NSImageView *)view setImage:[download fileIcon]];
    } else if ([identifier isEqualToString:PROGRESS_COLUMNID]) {
        NSArray *subviews = [view subviews];
        if ([subviews count] && [subviews isEqualToArray:[NSArray arrayWithObjects:[download progressIndicator], nil]] == NO)
            [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        if ([view isKindOfClass:[NSTextField class]])
            [(NSTextField *)view setObjectValue:[download info]];
    } else {
        NSImage *image = nil;
        SEL action = NULL;
        if ([identifier isEqualToString:CANCEL_COLUMNID]) {
            if ([download canCancel]) {
                image = [[self class] cancelImage];
                action = @selector(cancelDownload:);
            } else if ([download canRemove]) {
                image = [[self class] deleteImage];
                action = @selector(removeDownload:);
            }
        } else if ([identifier isEqualToString:RESUME_COLUMNID]) {
            if ([download canResume]) {
                image = [[self class] resumeImage];
                action = @selector(resumeDownload:);
            }
        }
        if ([view isKindOfClass:[NSButton class]]) {
            [(NSButton *)view setImage:image];
            [(NSButton *)view setAction:action];
            [(NSButton *)view setTarget:action ? self : nil];
        }
    }
    return view;
}

- (void)tableView:(NSTableView *)tv willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *identifier = [tableColumn identifier];
    SKDownload *download = [self objectInDownloadsAtIndex:row];
    
    if ([identifier isEqualToString:CANCEL_COLUMNID]) {
        if ([download canCancel]) {
            [cell setImage:[[self class] cancelImage]];
            [cell setAction:@selector(cancelDownload:)];
            [cell setTarget:self];
        } else if ([download canRemove]) {
            [cell setImage:[[self class] deleteImage]];
            [cell setAction:@selector(removeDownload:)];
            [cell setTarget:self];
        } else {
            [cell setImage:nil];
            [cell setAction:NULL];
            [cell setTarget:nil];
        }
    } else if ([identifier isEqualToString:RESUME_COLUMNID]) {
        if ([download canResume]) {
            [cell setImage:[[self class] resumeImage]];
            [cell setAction:@selector(resumeDownload:)];
            [cell setTarget:self];
        } else {
            [cell setImage:nil];
            [cell setAction:NULL];
            [cell setTarget:nil];
        }
    }
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {
    NSString *toolTip = @"";
    if ([[tableColumn identifier] isEqualToString:CANCEL_COLUMNID]) {
        if ([[self objectInDownloadsAtIndex:row] canCancel])
            toolTip = NSLocalizedString(@"Cancel download", @"Tool tip message");
        else if ([[self objectInDownloadsAtIndex:row] canRemove])
            toolTip = NSLocalizedString(@"Remove download", @"Tool tip message");
    } else if ([[tableColumn identifier] isEqualToString:RESUME_COLUMNID]) {
        if ([[self objectInDownloadsAtIndex:row] canResume])
            toolTip = NSLocalizedString(@"Resume download", @"Tool tip message");
    }
    return toolTip;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible] && [[QLPreviewPanel sharedPreviewPanel] dataSource] == self)
        [[QLPreviewPanel sharedPreviewPanel] reloadData];
}

- (void)tableView:(NSTableView *)aTableView deleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    NSUInteger row = [rowIndexes firstIndex];
    SKDownload *download = [self objectInDownloadsAtIndex:row];
    
    if ([download canCancel])
        [download cancel];
    else if ([download canRemove])
        [self removeObjectFromDownloadsAtIndex:row];
}

- (BOOL)tableView:(NSTableView *)aTableView canDeleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    return YES;
}

- (void)tableView:(NSTableView *)tv pasteFromPasteboard:(NSPasteboard *)pboard {
    if (NO == [self pasteFromPasteboard:pboard])
        NSBeep();
}

- (BOOL)tableView:(NSTableView *)tv canPasteFromPasteboard:(NSPasteboard *)pboard {
    return [NSURL canReadURLFromPasteboard:pboard];
}

- (NSArray *)tableView:(NSTableView *)aTableView typeSelectHelperSelectionStrings:(SKTypeSelectHelper *)typeSelectHelper {
    return [downloads valueForKey:SKDownloadFileNameKey];
}

#pragma mark Contextual menu

- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSMenuItem *menuItem;
    NSInteger row = [tableView clickedRow];
    [menu removeAllItems];
    if (row != -1) {
        SKDownload *download = [self objectInDownloadsAtIndex:row];
        
        if ([download canCancel]) {
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"Cancel", @"Menu item title") action:@selector(cancelDownload:) target:self];
            [menuItem setRepresentedObject:download];
        } else if ([download canRemove]) {
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"Remove", @"Menu item title") action:@selector(removeDownload:) target:self];
            [menuItem setRepresentedObject:download];
        }
        if ([download canResume]) {
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"Resume", @"Menu item title") action:@selector(resumeDownload:) target:self];
            [menuItem setRepresentedObject:download];
        }
        if ([download status] == SKDownloadStatusFinished && [[download fileURL] checkResourceIsReachableAndReturnError:NULL]) {
            menuItem = [menu addItemWithTitle:[NSLocalizedString(@"Open", @"Menu item title") stringByAppendingEllipsis] action:@selector(openDownloadedFile:) target:self];
            [menuItem setRepresentedObject:download];
            
            menuItem = [menu addItemWithTitle:[NSLocalizedString(@"Quick Look", @"Menu item title") stringByAppendingEllipsis] action:@selector(previewDownloadedFile:) target:self];
            [menuItem setRepresentedObject:download];
            
            menuItem = [menu addItemWithTitle:[NSLocalizedString(@"Reveal", @"Menu item title") stringByAppendingEllipsis] action:@selector(revealDownloadedFile:) target:self];
            [menuItem setRepresentedObject:download];
            
            menuItem = [menu addItemWithTitle:NSLocalizedString(@"Move to Trash", @"Menu item title") action:@selector(trashDownloadedFile:) target:self];
            [menuItem setRepresentedObject:download];
        }
    }
}

#pragma mark KVO

- (void)startObservingDownloads:(NSArray *)newDownloads {
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [newDownloads count])];
    [newDownloads addObserver:self toObjectsAtIndexes:indexes forKeyPath:SKDownloadFileURLKey options:0 context:&SKDownloadPropertiesObservationContext];
    [newDownloads addObserver:self toObjectsAtIndexes:indexes forKeyPath:SKDownloadStatusKey options:0 context:&SKDownloadPropertiesObservationContext];
}

- (void)endObservingDownloads:(NSArray *)oldDownloads {
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [oldDownloads count])];
    [oldDownloads removeObserver:self fromObjectsAtIndexes:indexes forKeyPath:SKDownloadFileURLKey];
    [oldDownloads removeObserver:self fromObjectsAtIndexes:indexes forKeyPath:SKDownloadStatusKey];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKDownloadPropertiesObservationContext) {
        NSUInteger row = [downloads indexOfObject:object];
        if (row != NSNotFound) {
            NSRange columns = NSMakeRange(0, 0);
            if ([keyPath isEqualToString:SKDownloadFileURLKey]) {
                columns = NSMakeRange(0, 2);
                [[tableView typeSelectHelper] rebuildTypeSelectSearchCache];
            } else if ([keyPath isEqualToString:SKDownloadStatusKey]) {
                columns = NSMakeRange(1, 3);
                [self updateClearButton];
                if ([object status] == SKDownloadStatusFinished) {
                    [self openDownload:object];
                    if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible] && [[QLPreviewPanel sharedPreviewPanel] dataSource] == self && [tableView isRowSelected:row])
                        [[QLPreviewPanel sharedPreviewPanel] reloadData];
                }
            }
            [tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:columns]];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Toolbar

- (void)setupToolbar {
    // Create a new toolbar instance, and attach it to our window
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:SKDownloadsToolbarIdentifier] autorelease];
    
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
    [toolbar setSizeMode:NSToolbarSizeModeSmall];

    // We are the delegate
    [toolbar setDelegate:self];
    
    // Attach the toolbar to the window
    [[self window] setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted {
    NSToolbarItem *item = nil;
    if ([itemIdent isEqualToString:SKDownloadsToolbarPreferencesItemIdentifier]) {
        item = [[[NSToolbarItem alloc] initWithItemIdentifier:SKDownloadsToolbarPreferencesItemIdentifier] autorelease];
        [item setToolTip:NSLocalizedString(@"Download preferences", @"Tool tip message")];
        [item setImage:[NSImage imageNamed:NSImageNamePreferencesGeneral]];
        [item setTarget:self];
        [item setAction:@selector(showDownloadPreferences:)];
    } else if ([itemIdent isEqualToString:SKDownloadsToolbarClearItemIdentifier]) {
        item = [[[NSToolbarItem alloc] initWithItemIdentifier:SKDownloadsToolbarClearItemIdentifier] autorelease];
        [item setView:clearButton];
        [item setMinSize:[clearButton bounds].size];
        [item setMaxSize:[clearButton bounds].size];
    }
    return item;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
            SKDownloadsToolbarClearItemIdentifier,
            NSToolbarFlexibleSpaceItemIdentifier,
            SKDownloadsToolbarPreferencesItemIdentifier, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
            SKDownloadsToolbarPreferencesItemIdentifier,
            NSToolbarFlexibleSpaceItemIdentifier,
            SKDownloadsToolbarClearItemIdentifier, nil];
}

#pragma mark Quick Look Panel Support

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel {
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel {
    [panel setDelegate:self];
    [panel setDataSource:self];
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel {
}

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel {
    NSUInteger row = [[tableView selectedRowIndexes] lastIndex];
    SKDownload *download = nil;
    if (row != NSNotFound) {
        download = [self objectInDownloadsAtIndex:row];
        if ([download status] == SKDownloadStatusFinished && [[download fileURL] checkResourceIsReachableAndReturnError:NULL])
            return 1;
    }
    return 0;
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)anIndex {
    NSUInteger row = [[tableView selectedRowIndexes] lastIndex];
    SKDownload *download = nil;
    if (row != NSNotFound)
        download = [self objectInDownloadsAtIndex:row];
    return download;
}

- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item {
    NSUInteger row = [downloads indexOfObject:item];
    NSRect iconRect = NSZeroRect;
    if (row != NSNotFound) {
        iconRect = [tableView frameOfCellAtColumn:0 row:row];
        if (NSIntersectsRect([tableView visibleRect], iconRect)) {
            iconRect = [tableView convertRectToScreen:iconRect];
        } else {
            iconRect = NSZeroRect;
        }
    }
    return iconRect;
}

- (NSImage *)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id <QLPreviewItem>)item contentRect:(NSRect *)contentRect {
    return [(SKDownload *)item fileIcon];
}

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event {
    if ([event type] == NSKeyDown) {
        [tableView keyDown:event];
        return YES;
    }
    return NO;
}

@end
