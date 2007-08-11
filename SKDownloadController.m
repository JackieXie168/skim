//
//  SKDownloadController.m
//  Skim
//
//  Created by Christiaan Hofman on 8/11/07.
/*
 This software is Copyright (c) 2007
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

NSString *SKWeblocFilePboardType = @"CorePasteboardFlavorType 0x75726C20";

@implementation SKDownloadController

+ (id)sharedDownloadController {
    static SKDownloadController *sharedDownloadController = nil;
    if (sharedDownloadController == nil)
        sharedDownloadController = [[self alloc] init];
    return sharedDownloadController;
}

- (id)init {
    if (self = [super init]) {
         downloads = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [downloads release];
    [super dealloc];
}

- (NSString *)windowNibName { return @"DownloadsWindow"; }

- (void)reloadTableView {
    NSView *view;
    while (view = [[tableView subviews] lastObject])
        [view removeFromSuperview];
    [tableView reloadData];
}

- (void)updateButtons {
    BOOL enable = NO;
    NSEnumerator *downloadEnum = [downloads objectEnumerator];
    SKDownload *download;
    while (download = [downloadEnum nextObject]) {
        if ([download canCancel] == NO) {
            enable = YES;
            break;
        }
    }
    [clearButton setEnabled:enable];
}

- (void)windowDidLoad {
    [self setWindowFrameAutosaveName:@"SKDownloadsWindow"];
    [self updateButtons];
    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSURLPboardType, SKWeblocFilePboardType, nil]];
}

- (void)addDownloadForURL:(NSURL *)aURL {
    if (aURL) {
        [downloads addObject:[[[SKDownload alloc] initWithURL:aURL delegate:self] autorelease]];
        [self reloadTableView];
    }
}

#pragma mark Actions

- (IBAction)clearDownloads:(id)sender {
    int index = [downloads count];
    
    if (index) {
        while (index-- > 0) {
            SKDownload *download = [downloads objectAtIndex:index];
            if ([download status] != SKDownloadStatusDownloading)
                [downloads removeObjectAtIndex:index];
        }
        [self reloadTableView];
        [self updateButtons];
    }
}

- (IBAction)cancelDownload:(id)sender {
	int row = [tableView clickedRow];
    
    if (row != -1) {
        SKDownload *download = [downloads objectAtIndex:row];
        if ([download status] == SKDownloadStatusDownloading) {
            [download cancelDownload];
        }
    }
}

- (IBAction)removeDownload:(id)sender {
	int row = [tableView clickedRow];
    
    if (row != -1) {
        SKDownload *download = [downloads objectAtIndex:row];
        if ([download status] == SKDownloadStatusDownloading)
            [download cancelDownload];
        [downloads removeObjectAtIndex:row];
        [self reloadTableView];
        [self updateButtons];
    }
}

#pragma mark SKDownloadDelegate

- (void)downloadDidStart:(SKDownload *)download {
    [self reloadTableView];
    [self updateButtons];
}

- (void)downloadDidUpdate:(SKDownload *)download {
    [tableView reloadData];
    [self updateButtons];
}

- (void)downloadDidEnd:(SKDownload *)download {
    [self reloadTableView];
    [self updateButtons];
    
    if ([download status] == SKDownloadStatusFinished) {
        NSURL *URL = [NSURL fileURLWithPath:[download filePath]];
        NSError *error = nil;
        if (NO == [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:URL display:YES error:&error])
            [NSApp presentError:error];
    }
    
    [download cleanupDownload];
}

#pragma mark NSTableViewDataSource

- (int)numberOfRowsInTableView:(NSTableView *)tv {
    return [downloads count];
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    NSString *identifier = [tableColumn identifier];
    SKDownload *download = [downloads objectAtIndex:row];
    
    if ([identifier isEqualToString:@"progress"]) {
        return [download fileName];
    } else if ([identifier isEqualToString:@"icon"]) {
        return [download fileIcon];
    }
    return nil;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSURLPboardType, SKWeblocFilePboardType, nil]];
    
    if (type) {
        [tv setDropRow:-1 dropOperation:NSTableViewDropOn];
        return NSDragOperationEvery;
    }
    return NSDragOperationNone;
}
       
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op {
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSURLPboardType, SKWeblocFilePboardType, nil]];
    NSURL *theURL;
    
    if ([type isEqualToString:NSURLPboardType]) {
        theURL = [NSURL URLFromPasteboard:pboard];
    } else if ([type isEqualToString:SKWeblocFilePboardType]) {
        theURL = [NSURL URLWithString:[pboard stringForType:SKWeblocFilePboardType]];
    }
    if ([theURL isFileURL]) {
        if ([[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:theURL display:YES error:NULL])
            return YES;
    } else if (theURL) {
        [self addDownloadForURL:theURL];
        return YES;
    }
    return NO;
}

#pragma mark NSTableViewDelegate

- (void)tableView:(NSTableView *)tv willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    NSString *identifier = [tableColumn identifier];
    SKDownload *download = [downloads objectAtIndex:row];
    
    if ([identifier isEqualToString:@"progress"]) {
        if ([cell respondsToSelector:@selector(setProgressIndicator:)])
            [(SKProgressCell *)cell setProgressIndicator:[download progressIndicator]];
        if ([cell respondsToSelector:@selector(setStatus:)])
            [(SKProgressCell *)cell setStatus:[download status]];
    } else if ([identifier isEqualToString:@"cancel"]) {
        if ([download canCancel]) {
            [cell setImage:[NSImage imageNamed:@"Cancel"]];
            [cell setAction:@selector(cancelDownload:)];
            [cell setTarget:self];
        } else {
            [cell setImage:[NSImage imageNamed:@"Delete"]];
            [cell setAction:@selector(removeDownload:)];
            [cell setTarget:self];
        }
    }
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation {
    NSString *toolTip = nil;
    if ([[tableColumn identifier] isEqualToString:@"cancel"]) {
        if ([[downloads objectAtIndex:row] canCancel])
            toolTip = NSLocalizedString(@"Cancel download", @"");
        else
            toolTip = NSLocalizedString(@"Remove download", @"");
    }
    return toolTip;
}

@end
