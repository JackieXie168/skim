//
//  BibFiler.h
//  Bibdesk
//
//  Created by Michael McCracken on Fri Apr 30 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BibPrefController.h"
#import "BibItem.h"
@class BibDocument;

@interface BibFiler : NSObject {
	NSMutableArray *_fileInfoDicts;
	
	IBOutlet NSWindow *window;
	IBOutlet NSTableView *tv;
	IBOutlet NSButton *actionButton;
	IBOutlet NSButton *cancelButton;
	IBOutlet NSTextField *infoTextField;
	IBOutlet NSButton *cleanupCheckBox;
	IBOutlet NSButton *deleteCheckBox;
	
	NSArray *_currentPapers;
	BibDocument *_currentDocument;
	NSString *_errorString;
	int _moveCount;
	int _movableCount;
	int _deletedCount;
	int _cleanupChangeCount;
}

+ (BibFiler *)sharedFiler;

- (void)showPreviewForPapers:(NSArray *)papers fromDocument:(BibDocument *)doc;
- (void)doMoveAction:(id)sender;
- (IBAction)cancelFromPreview:(id)sender;
- (void)doCleanup;
- (void)file:(BOOL)doFile papers:(NSArray *)papers fromDocument:(BibDocument *)doc;

- (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo;

- (IBAction)handleCleanupLinksAction:(id)sender;


@end
