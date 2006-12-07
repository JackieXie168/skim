//
//  BibFiler.h
//  BibDesk
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
	BDSKMoveErrorMask = 8,
    BDSKUnableToResolveAliasMask = 16,
    BDSKUnableToCreateParentMask = 32
};

@interface BibFiler : NSObject {
	NSMutableArray *fileInfoDicts;
	
	IBOutlet NSWindow *window;
	IBOutlet NSTableView *tv;
	IBOutlet NSTextField *infoTextField;
	IBOutlet NSImageView *iconView;
	
	IBOutlet NSPanel *progressSheet;
	IBOutlet NSProgressIndicator *progressIndicator;
	
	NSArray *currentPapers;
	BibDocument *currentDocument;
	NSString *errorString;
	int moveCount;
	int movableCount;
}

+ (BibFiler *)sharedFiler;

/*!
	@method		filePapers:fromDocument:doc:ask:
	@abstract	Main auto-file routine to file papers in the Papers folder according to a generated location.
	@param		papers The BibItemsfor which linked files should be moved.
	@param		doc The parent document of the papers. 
	@param		ask Boolean determines whether to ask the user to proceed or to move only entries with all necessary fields set. 
	@discussion	This is the main method that should be used to autofile papers.
It calls the necessary methods to do the move and generates the new locations for the papers. 
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
	@discussion This is the core method to move a file. It should not be called directly, as it relies on the next two methods. 
It is separately undoable, but only moves that were succesfull are registered for undo. 
It can handle aliases and symlinks, also when they occur in the middle of the paths. 
Aliases and symlinks are moved unresolved. Relative paths in symlinks will be made absolute. 
*/
- (void)movePath:(NSString *)path toPath:(NSString *)newPath forPaper:(BibItem *)paper fromDocument:(BibDocument *)doc moveAll:(BOOL)moveAll;

/*!
	@method		prepareMoveForDocument:number:
	@abstract	Prepares a move of several linked files, mainly initializing variables. 
	@param		doc The parent document. 
	@param		number The number of papers to move. 
	@discussion -
*/
- (void)prepareMoveForDocument:(BibDocument *)doc number:(NSNumber *)number;

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
