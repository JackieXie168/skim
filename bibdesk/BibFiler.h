//
//  BibFiler.h
//  BibDesk
//
//  Created by Michael McCracken on Fri Apr 30 2004.
/*
 This software is Copyright (c) 2004,2005,2006
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

#import <Foundation/Foundation.h>
#import "BibPrefController.h"
#import "BibItem.h"
@class BibDocument;

enum {
	BDSKNoError = 0,
	BDSKSourceFileDoesNotExistErrorMask = 1,
	BDSKTargetFileExistsErrorMask = 2,
	BDSKCannotMoveFileErrorMask = 4,
	BDSKCannotRemoveFileErrorMask = 8,
    BDSKCannotResolveAliasErrorMask = 16,
    BDSKCannotCreateParentErrorMask = 32,
	BDSKIncompleteFieldsErrorMask = 64
};

enum {
    BDSKInitialAutoFileOptionMask = 1,
    BDSKCheckCompleteAutoFileOptionMask = 2,
    BDSKForceAutoFileOptionMask = 4
};

@interface BibFiler : NSObject {
	IBOutlet NSWindow *window;
	IBOutlet NSTableView *tv;
	IBOutlet NSTextField *infoTextField;
	IBOutlet NSImageView *iconView;
	IBOutlet NSButton *forceCheckButton;
	IBOutlet NSMenu *contextMenu;
	
	IBOutlet NSPanel *progressSheet;
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSButton *progressCloseButton;
	
    BibDocument *document;
    NSString *fieldName;
    int options;
    
	NSMutableArray *errorInfoDicts;
}

+ (BibFiler *)sharedFiler;

/*!
	@method		filePapers:fromDocument:doc:check:
	@abstract	Main auto-file routine to file papers in the Papers folder according to a generated location.
	@param		papers The BibItemsfor which linked files should be moved.
	@param		doc The parent document of the papers. 
	@param		check Boolean determines whether to move only entries with all necessary fields set. 
	@discussion	This is the main method that should be used to autofile papers.
It calls the necessary methods to do the move and generates the new locations for the papers. 
*/
- (void)filePapers:(NSArray *)papers fromDocument:(BibDocument *)doc check:(BOOL)check;

/*!
	@method		movePapers:forField:fromDocument:options:
	@abstract	Tries to move list of papers from a document.
	@param		paperInfos A list of BibItems or a info dictionaries containing a BibItem and file paths to move between.
	@param		field The field for which to move the linked files.
	@param		doc The parent document of the papers. 
	@param		mask Integer, see the AutoFileOptionMask enum for options. 
	@discussion This is the core method to move files. 
It is undoable, but only moves that were succesfull are registered for undo. 
It can handle aliases and symlinks, also when they occur in the middle of the paths. 
Aliases and symlinks are moved unresolved. Relative paths in symlinks will be made absolute. 
BDSKInitialAutoFileOptionMask should be used for initial autofile moves, the new path will be generated. 
BDSKCheckCompleteAutoFileOptionMask indicates that for initial moves a check will be done whether all required fields are set. 
BDSKForceAutoFileOptionMask forces AutoFiling, even if there may be problems moving the file. 
*/
- (void)movePapers:(NSArray *)paperInfos forField:(NSString *)field fromDocument:(BibDocument *)doc options:(int)masks;

/*!
	@method		closeProgress:
	@abstract	Action to close the progress sheet
	@discussion -
*/
- (IBAction)closeProgress:(id)sender;

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
	@method		tryAgain:
	@abstract	Action for the problems view button, cleans up, and tries to move again.
	@discussion If the sender's tag is 1, it files with the BDSKForceAutoFileOptionMask set. 
*/
- (IBAction)tryAgain:(id)sender;

/*!
	@method		dump:
	@abstract	Action for the problems view button, dumps the errors on the desktop. 
	@discussion -
*/
- (IBAction)dump:(id)sender;

/*!
	@method		showFile:
	@abstract	Double click action of the problems view tableview, shows the linked file or the status message.
	@discussion -
*/
- (IBAction)showFile:(id)sender;

- (NSArray *)errorInfoDicts;
- (unsigned)countOfErrorInfoDicts;
- (id)objectInErrorInfoDictsAtIndex:(unsigned)index;
- (void)insertObject:(id)obj inErrorInfoDictsAtIndex:(unsigned)index;
- (void)removeObjectFromErrorInfoDictsAtIndex:(unsigned)index;

@end


@interface NSFileManager (BibFilerExtensions)

/*!
	@method		movePath:toPath:force:error:
	@abstract	Extension to movePath:toPath:handler: which can handle symlinks and aliases, and allows for forcing a move when otherwise move errors occur.
	@param		path The path to the file to move. 
	@param		newPath The pathwhere the file should move to. 
	@param		force Boolean. If YES, overwrite an existing file or copy a non-removable file. 
	@param		error An NSError object set when an error occurs.
	@discussion -
*/
- (BOOL)movePath:(NSString *)path toPath:(NSString *)newPath force:(BOOL)force error:(NSError **)error;

@end
