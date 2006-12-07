//  BibEditor.h

//  Created by Michael McCracken on Mon Dec 24 2001.
/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/*! @header BibEditor.h
    @discussion The class for editing BibItems. Handles the UI for the fields and notes.
*/ 

#import <Cocoa/Cocoa.h>

#import <OmniFoundation/OmniFoundation.h>

#import "BibItem.h"
#import "BibDocument.h"
#import "BDSKCiteKeyFormatter.h"
#import "BibAppController.h"
#import "PDFImageView.h"
#import "BDSKFieldNameFormatter.h"
#import "BibPersonController.h"
#import "RYZImagePopUpButton.h"
#import "RYZImagePopUpButtonCell.h"





/*!
    @class BibEditor
    @abstract WindowController for the edit window
    @discussion Subclass of the NSWindowController class, This handles making, reversing and keeping track of changes to the BibItem, and displaying a nice GUI.
*/
@interface BibEditor : NSWindowController {
    IBOutlet NSPopUpButton *bibTypeButton;
    IBOutlet NSForm *bibFields;
    IBOutlet NSTabView *tabView;
    IBOutlet NSTextView *notesView;
    IBOutlet NSTextView *abstractView;
    IBOutlet NSTextView* rssDescriptionView;
    IBOutlet NSTextField* citeKeyField;
//    IBOutlet NSButton* viewLocalButton;
	IBOutlet RYZImagePopUpButton *viewLocalButton;
    IBOutlet NSButton* viewRemoteButton;
    IBOutlet NSScrollView* fieldsScrollView;
	IBOutlet RYZImagePopUpButton *actionMenuButton;
    // ----------------------------------------------------------------------------------------
    // New-field Sheet stuff:
    IBOutlet NSTextField *newFieldName;
    IBOutlet NSButton* newFieldButtonOK;
    IBOutlet NSButton* newFieldButtonCancel;
    IBOutlet NSWindow* newFieldWindow;
    // ----------------------------------------------------------------------------------------
	// Delete-field Sheet stuff:
    IBOutlet NSPopUpButton *delFieldPopUp;
    IBOutlet NSButton* delFieldButtonOK;
    IBOutlet NSButton* delFieldButtonCancel;
    IBOutlet NSWindow* delFieldWindow;
    // ----------------------------------------------------------------------------------------
    NSString *currentType;
    BibItem *theBib;
    BibDocument *theDocument;
    NSMutableDictionary *fieldNumbers;
// ----------------------------------------------------------------------------------------
// doc preview stuff
// ----------------------------------------------------------------------------------------
    IBOutlet NSDrawer* documentSnoopDrawer;
    IBOutlet PDFImageView *documentSnoopImageView;
    IBOutlet NSButton* documentSnoopButton;
    IBOutlet NSScrollView* documentSnoopScrollView;
    IBOutlet NSView* pdfSnoopContainerView;
    NSImage *_pdfSnoopImage;
// ----------------------------------------------------------------------------------------
// doc textpreview stuff
// ----------------------------------------------------------------------------------------
    IBOutlet NSButton* documentTextSnoopButton;
    IBOutlet NSTextView *documentSnoopTextView;
    IBOutlet NSView* textSnoopContainerView;
    NSString *_textSnoopString;
    
// Autocompletion stuff
    NSDictionary *completionMatcherDict;
	
// cite-key checking stuff:
    BDSKCiteKeyFormatter *citeKeyFormatter;
	IBOutlet NSButton *citeKeyWarningButton;
	NSImage *cautionIconImage;
	
// new field formatter
    BDSKFieldNameFormatter *fieldNameFormatter;
	
// Author tableView
	IBOutlet NSTableView *authorTableView;
	
	// add field sheet
	IBOutlet NSPanel *addAuthorSheet;
	IBOutlet NSTextView *addAuthorTextView;

}

/*!
@method initWithBibItem: document:
    @abstract designated Initializer
    @discussion
 @param aBib gives us a bib to edit
*/
- (id)initWithBibItem:(BibItem *)aBib document:(BibDocument *)doc;

/*!
    @method setupForm
    @abstract handles making the NSForm
    @discussion <ul> <li>This method is kind of hairy.
 <li>could be more efficient, maybe.
 <li>And is probably being called in the wrong place (windowDidBecomeMain).
 </ul>
    
*/

- (BibItem *)currentBib;
- (void)setupForm;
- (void)show;
/*!
    @method     setDocument:
    @discussion   overrides the default impl. to just save a ref to the doc and not mess with the title.
*/

- (void)setDocument:(NSDocument *)d;
//- (NSDocument *)document; is intentionally unimplemented.

- (void)fixURLs;
- (IBAction)chooseLocalURL:(id)sender;


// ----------------------------------------------------------------------------------------
// Add-field sheet support
// ----------------------------------------------------------------------------------------
- (IBAction)raiseAddField:(id)sender;
- (IBAction)dismissAddField:(id)sender;
- (void)addFieldSheetDidEnd:(NSWindow *)sheet
                 returnCode:(int) returnCode
                contextInfo:(void *)contextInfo;

// ----------------------------------------------------------------------------------------
// Delete-field sheet support
// ----------------------------------------------------------------------------------------
- (IBAction)raiseDelField:(id)sender;
- (IBAction)dismissDelField:(id)sender;
- (void)delFieldSheetDidEnd:(NSWindow *)sheet
                 returnCode:(int) returnCode
                contextInfo:(void *)contextInfo;


- (void)finalizeChanges;

- (IBAction)viewLocal:(id)sender;
- (NSMenu *)menuForImagePopUpButton;
- (NSArray *)getSafariRecentDownloadsMenu;
- (NSArray *)getPreviewRecentDocumentsMenu;
- (void)setLocalURLPathFromMenuItem:(NSMenuItem *)sender;


- (IBAction)viewRemote:(id)sender;

- (void)setupCautionIcon;
- (IBAction)showCiteKeyWarning:(id)sender;
- (IBAction)citeKeyDidChange:(id)sender;
- (void)setCiteKeyDuplicateWarning:(BOOL)set;


- (IBAction)bibTypeDidChange:(id)sender;
/*!
    @method     updateTypePopup
    @abstract   Update the type popup menu based on the current bibitem's type.  Needed for dragging support (see BDSKDragWindow.m).
    @discussion (comprehensive description)
*/
- (void)updateTypePopup;
//- (IBAction)textFieldDidChange:(id)sender;
- (IBAction)textFieldDidEndEditing:(id)sender;
//- (void)closeSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;

- (void)toggleSnoopDrawer:(id)sender;
- (BOOL)citeKeyIsValid:(NSString *)proposedCiteKey;
- (IBAction)generateCiteKey:(id)sender;
- (void)makeKeyField:(NSString *)fieldName;
- (void)bibDidChange:(NSNotification *)notification;

- (void)docWillSave:(NSNotification *)notification;
- (void)bibWillBeRemoved:(NSNotification *)notification;
- (void)docWindowWillClose:(NSNotification *)notification;

/*!
    @method     showPersonDetail:
	 @abstract   opens a BibPersonController to show details of a pub
	 @discussion (description)
*/
- (IBAction)showPersonDetailCmd:(id)sender;

- (void)showPersonDetail:(BibAuthor *)person;

/*!
    @method     addAuthors:
    @abstract   pops up a sheet to add more than one author at a time.
    @discussion (description)
*/

- (IBAction)addAuthors:(id)sender;
- (IBAction)dismissAddAuthorSheet:(id)sender;
- (void)addAuthorSheetDidEnd:(NSWindow *)sheet
				  returnCode:(int) returnCode
				 contextInfo:(void *)contextInfo;

@end
