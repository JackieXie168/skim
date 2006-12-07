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

enum {
	BDSKNoErrorMask = 0,
	BDSKOldFileDoesNotExistMask = 1,
	BDSKGeneratedFileExistsMask = 2,
	BDSKIncompleteFieldsMask = 4,
	BDSKMoveErrorMask = 8
};

@interface BibFiler : NSObject {
	NSMutableArray *_fileInfoDicts;
	
	IBOutlet NSWindow *window;
	IBOutlet NSTableView *tv;
	IBOutlet NSTextField *infoTextField;
	IBOutlet NSImageView *iconView;
	
	NSArray *_currentPapers;
	BibDocument *_currentDocument;
	NSString *_errorString;
	int _moveCount;
	int _movableCount;
	int _deletedCount;
	int _cleanupChangeCount;
}

+ (BibFiler *)sharedFiler;

/*!
	@method		filePapers:fromDocument:doc:ask:
	@abstract	Main auto-file routine to file papers in the Papers folder according to a generated location.
	@param		papers The BibItemsfor which linked files should be moved.
	@param		doc The parent document of the papers. 
	@param		ask Boolean determines whether to ask the user to proceed or to move only entries with all necessary fields set. 
	@discussion	-
*/
- (void)filePapers:(NSArray *)papers fromDocument:(BibDocument *)doc ask:(BOOL)ask;

/*!
	@method		movePath:toPath:forPaper:fromDocument:moveAll:
	@abstract	Tries to move a file 
	@param		path The original path of the linked file.
	@param		newPath The path where to move the file to. 
	@param		paper The BibItem for the linked file.
	@param		doc The parent document of the paper. 
	@param		ask Boolean determines to move irrespective of whether all necessary bibliography fields are set.
	@discussion -
*/
- (void)movePath:(NSString *)path toPath:(NSString *)newPath forPaper:(BibItem *)paper fromDocument:(BibDocument *)doc moveAll:(BOOL)moveAll;

/*!
	@method		prepareMoveForDocument:
	@abstract	Prepares a move of several linked files, mainly initializing variables. 
	@param		doc The parent document. 
	@discussion -
*/
- (void)prepareMoveForDocument:(BibDocument *)doc;

/*!
	@method		finishMoveForDocument:
	@abstract	Finishes the move of several linked files.
	@param		doc The parent document. 
	@discussion -
*/
- (void)finishMoveForDocument:(BibDocument *)doc;

/*!
	@method		showProblems
	@abstract	Shows a dialog with information on files that had problems moving. 
	@discussion -
*/
- (void)showProblems;

/*!
	@method		done:
	@abstract	Action for the problems view button, cleans up. 
	@discussion -
*/
- (IBAction)done:(id)sender;

/*!
	@method		doCleanup
	@abstract	Cleans up after finishing.
	@discussion -
*/
- (void)doCleanup;

/*!
	@method		fileManager:shouldProceedAfterError:
	@abstract	NSFileManager delegate method.
	@discussion -
*/
- (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo;

/*!
	@method		showFile:
	@abstract	Double click action of the problems view tableview, shows the linked file or the status message.
	@discussion -
*/
- (IBAction)showFile:(id)sender;

@end
