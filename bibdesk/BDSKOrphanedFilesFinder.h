//
//  BDSKOrphanedFilesFinder.h
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

#import <Cocoa/Cocoa.h>

@class BDSKOrphanedFileServer, BDSKOrphanedFilesArrayController;

@interface BDSKOrphanedFilesFinder : NSWindowController  {
    IBOutlet NSTableView *tableView;
    IBOutlet NSButton *refreshButton;
    IBOutlet BDSKOrphanedFilesArrayController *arrayController;
    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet NSTextField *statusField;
    IBOutlet NSMenu *contextMenu;
    NSMutableArray *orphanedFiles;
    BOOL wasLaunched;
    BDSKOrphanedFileServer *server;
    
    IBOutlet NSButton *matchButton;
}

+ (id)sharedFinder;

// shows the panel and refreshes
- (IBAction)showOrphanedFiles:(id)sender;
- (IBAction)refreshOrphanedFiles:(id)sender;
- (IBAction)stopRefreshing:(id)sender;

- (IBAction)matchFilesWithPubs:(id)sender;

- (IBAction)showFile:(id)sender;
- (IBAction)search:(id)sender;

- (NSArray *)orphanedFiles;
- (unsigned)countOfOrphanedFiles;
- (id)objectInOrphanedFilesAtIndex:(unsigned)theIndex;
- (void)insertObject:(id)obj inOrphanedFilesAtIndex:(unsigned)theIndex;
- (void)removeObjectFromOrphanedFilesAtIndex:(unsigned)theIndex;

@end

@interface BDSKOrphanedFilesArrayController : NSArrayController
{
    NSString *searchString;
    BOOL showsMatches;
    IBOutlet NSSearchField *searchField;
    NSString *statusMessage;
}

- (void)setSearchString:(NSString *)aString;
- (NSString *)searchString;
- (IBAction)showMatches:(id)sender;
- (IBAction)hideMatches:(id)sender;

@end
