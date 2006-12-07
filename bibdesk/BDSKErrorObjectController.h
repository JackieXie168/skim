//
//  BDSKErrorObjectController.h
//  Bibdesk
//
//  Created by Adam Maxwell on 08/12/05.
/*
 This software is Copyright (c) 2005,2006
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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
#import <BTParse/error.h>

@class BDSKFilteringArrayController;

@interface BDSKErrorObjectController : NSWindowController {
    NSMutableArray *errors;
    NSMutableArray *documents;
    
    // error-handling stuff:
    IBOutlet NSPanel* errorPanel;
    IBOutlet NSTableView *errorTableView;
    IBOutlet NSTextView *sourceEditTextView;
    IBOutlet NSWindow *sourceEditWindow;
    IBOutlet NSButton *syntaxHighlightCheckbox;
    IBOutlet BDSKFilteringArrayController *errorsController;
    NSString *currentFileName;
    NSDocument *currentDocument;
    NSDocument *currentDocumentForErrors;
    BOOL enableSyntaxHighlighting;
}

+ (BDSKErrorObjectController *)sharedErrorObjectController;

- (NSArray *)errors;
- (unsigned)countOfErrors;
- (id)objectInErrorsAtIndex:(unsigned)index;
- (void)insertObject:(id)obj inErrorsAtIndex:(unsigned)index;
- (void)removeObjectFromErrorsAtIndex:(unsigned)index;

- (NSArray *)documents;
- (unsigned)countOfDocuments;
- (id)objectInDocumentsAtIndex:(unsigned)theIndex;
- (void)insertObject:(id)obj inDocumentsAtIndex:(unsigned)theIndex;
- (void)removeObjectFromDocumentsAtIndex:(unsigned)theIndex;
- (void)replaceObjectInDocumentsAtIndex:(unsigned)theIndex withObject:(id)obj;

- (void)setCurrentFileName:(NSString *)newPath;
- (NSString *)currentFileName;

- (void)setCurrentDocument:(id)document;
- (id)currentDocument;

- (void)setDocumentForErrors:(id)document;
- (id)documentForErrors;

- (IBAction)toggleShowingErrorPanel:(id)sender;
- (IBAction)hideErrorPanel:(id)sender;
- (IBAction)showErrorPanel:(id)sender;

- (IBAction)copy:(id)sender;

- (IBAction)gotoError:(id)sender;
- (void)gotoErrorObj:(id)errObj;
- (IBAction)changeSyntaxHighlighting:(id)sender;

- (void)removeErrorObjsForDocument:(id)document;
- (void)removeErrorObjsForFileName:(NSString *)fileName;
- (void)handoverErrorObjsForDocument:(id)document;

- (void)openEditWindowWithFile:(NSString *)fileName;
- (void)openEditWindowWithFile:(NSString *)fileName forDocument:(id)document;
- (void)openEditWindowForDocument:(id)document;
- (IBAction)reopenDocument:(id)sender;

- (void)handleErrorNotification:(NSNotification *)notification;
- (void)handleEditWindowWillCloseNotification:(NSNotification *)notification;

@end


@interface BDSKErrObj (Accessors)

- (NSString *)fileName;
- (void)setFileName:(NSString *)newFileName;

- (NSDocument *)document;
- (void)setDocument:(NSDocument *)newDocument;

- (NSString *)displayFileName;

- (int)lineNumber;
- (void)setLineNumber:(int)newLineNumber;

- (NSString *)itemDescription;
- (void)setItemDescription:(NSString *)newItemDescription;

- (int)itemNumber;
- (void)setItemNumber:(int)newItemNumber;

- (NSString *)errorClassName;
- (void)setErrorClassName:(NSString *)newErrorClassName;

- (NSString *)errorMessage;
- (void)setErrorMessage:(NSString *)newErrorMessage;

@end

@interface BDSKPlaceHolderFilterItem : NSObject {
	NSString *displayName;
}
+ (BDSKPlaceHolderFilterItem *)allItemsPlaceHolderFilterItem;
+ (BDSKPlaceHolderFilterItem *)emptyItemsPlaceHolderFilterItem;
- (id)initWithDisplayName:(NSString *)name;
@end

@interface BDSKFilteringArrayController : NSArrayController {
    id filterValue;
	NSString *filterKey;
}

- (id)filterValue;
- (void)setFilterValue:(id)newValue;
- (NSString *)filterKey;
- (void)setFilterKey:(NSString *)newKey;

@end

