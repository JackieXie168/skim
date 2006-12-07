//  BibEditor.h

//  Created by Michael McCracken on Mon Dec 24 2001.
/*
 This software is Copyright (c) 2001,2002,2003,2004,2005
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

/*! @header BibEditor.h
    @discussion The class for editing BibItems. Handles the UI for the fields and notes.
*/ 

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "BDSKForm.h"

@class BDSKRatingButton;
@class BDSKRatingButtonCell;
@class PDFImageView;
@class BDSKCiteKeyFormatter;
@class BDSKFieldNameFormatter;
@class MacroTextFieldWindowController;
@class RYZImagePopUpButton;
@class BibItem;
@class BDSKStatusBar;
@class BibDocument;
@class BDSKAlert;
@class BibAuthor;

// core pasteboard type for webloc files
extern NSString* BDSKWeblocFilePboardType;

/*!
    @class BibEditor
    @abstract WindowController for the edit window
    @discussion Subclass of the NSWindowController class, This handles making, reversing and keeping track of changes to the BibItem, and displaying a nice GUI.
*/
@interface BibEditor : NSWindowController <BDSKFormDelegate> {
    IBOutlet NSPopUpButton *bibTypeButton;
    IBOutlet BDSKForm *bibFields;
    IBOutlet NSMatrix *extraBibFields;
	IBOutlet OASplitView *splitView;
    IBOutlet NSTabView *tabView;
    IBOutlet NSTextView *notesView;
    IBOutlet NSTextView *abstractView;
    IBOutlet NSTextView* rssDescriptionView;
	NSTextView *currentEditedView;
    NSUndoManager *notesViewUndoManager;
    NSUndoManager *abstractViewUndoManager;
    NSUndoManager *rssDescriptionViewUndoManager;
    // for the splitview double-click handling
    float lastMatrixHeight;
	
	NSButtonCell *booleanButtonCell;
	BDSKRatingButtonCell *ratingButtonCell;
    
    IBOutlet NSTextField* citeKeyField;
	IBOutlet RYZImagePopUpButton *viewLocalButton;
    IBOutlet RYZImagePopUpButton *viewRemoteButton;
    IBOutlet RYZImagePopUpButton *documentSnoopButton;
	NSToolbarItem *viewLocalToolbarItem;
	NSToolbarItem *viewRemoteToolbarItem;
	NSToolbarItem *documentSnoopToolbarItem;
    IBOutlet NSScrollView *fieldsScrollView;
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
    IBOutlet NSScrollView* documentSnoopScrollView;
	int drawerState;
	int drawerButtonState;
	BOOL drawerLoaded;
	// doc textpreview stuff
    IBOutlet PDFImageView *documentSnoopImageView;
    IBOutlet NSView* pdfSnoopContainerView;
	BOOL pdfSnoopViewLoaded;
	// doc textpreview stuff
    IBOutlet NSTextView *documentSnoopTextView;
    IBOutlet NSView* textSnoopContainerView;
	// remote webpreview stuff
    IBOutlet WebView *remoteSnoopWebView;
    IBOutlet NSView* webSnoopContainerView;
	BOOL webSnoopViewLoaded;
// ----------------------------------------------------------------------------------------
// status bar stuff
// ----------------------------------------------------------------------------------------
    IBOutlet BDSKStatusBar *statusBar;
    
// Autocompletion stuff
    NSDictionary *completionMatcherDict;
    NSMutableDictionary *formatters;
	
// cite-key checking stuff:
    BDSKCiteKeyFormatter *citeKeyFormatter;
	IBOutlet NSButton *citeKeyWarningButton;
	
// new field formatter
    BDSKFieldNameFormatter *fieldNameFormatter;
	
// Author tableView
	IBOutlet NSTableView *authorTableView;
	IBOutlet NSScrollView *authorScrollView;

    // Macro editing stuff
    MacroTextFieldWindowController *macroTextFieldWC;

	// edit field stuff
	BOOL forceEndEditing;
    NSMutableDictionary *toolbarItems;

    BOOL windowLoaded;
    BOOL didSetupForm;

    NSString *promisedDragFilename;
    NSURL *promisedDragURL;
}

/*!
@method initWithBibItem: document:
    @abstract designated Initializer
    @discussion
 @param aBib gives us a bib to edit
*/
- (id)initWithBibItem:(BibItem *)aBib document:(BibDocument *)doc;

- (BibItem *)currentBib;

/*!
    @method formatterForEntry
    @abstract returns the singleton formatter for a particular entry
    @discussion «discussion»
    
*/
- (NSFormatter *)formatterForEntry:(NSString *)entry;

- (void)setupTypePopUp;
/*!
    @method setupForm
    @abstract handles making the NSForm
    @discussion <ul> <li>This method is kind of hairy.
 <li>could be more efficient, maybe.
 <li>And is probably being called in the wrong place (windowDidBecomeMain).
 </ul>
    
*/
- (void)setupForm;
- (void)setCurrentType:(NSString *)type;
/*!
    @method     show
    @abstract   Shows the window.
    @discussion (comprehensive description)
*/
- (void)show;

/*!
    @method     setDocument:
    @discussion   overrides the default impl. to just save a ref to the doc and not mess with the title.
*/
- (void)setDocument:(NSDocument *)d;
//- (NSDocument *)document; is intentionally unimplemented.

/*!
    @method     fixURLs
    @abstract   Updates the views for changes in either local or remote URLs. Updates the popup buttons and the drawer contents, if necessary. 
    @discussion (comprehensive description)
*/
- (void)fixURLs;

/*!
    @method     chooseLocalURL:
    @abstract   Action to choose a local file using the Open dialog. 
    @discussion (comprehensive description)
*/
- (IBAction)chooseLocalURL:(id)sender;

- (IBAction)toggleStatusBar:(id)sender;

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

/*!
    @method     editSelectedFieldAsRawBibTeX:
    @abstract   edits the current field as a macro.
    @discussion This is not necessary if the field is already a macro.
    @param      sender (description)
    @result     (description)
*/
- (IBAction)editSelectedFieldAsRawBibTeX:(id)sender;

/*!
    @method     recordChangingField:toValue:
    @abstract   sets field to value in theBib and does other stuff
    @discussion factored out because setting field and doing other things is done from more than one place.
    @param      fieldName (description)
    @param      value (description)
*/
- (void)recordChangingField:(NSString *)fieldName toValue:(NSString *)value;

- (NSString *)status;
- (void)setStatus:(NSString *)status;

/*!
    @method     finalizeChanges:
    @abstract   Makes sure that edits of fields are submitted.
    @discussion (comprehensive description)
    @param      aNotification Unused
*/
- (void)finalizeChanges:(NSNotification *)aNotification;

/*!
    @method     viewLocal
    @abstract   Action to view the local file in the default viewer.
    @discussion (comprehensive description)
*/
- (IBAction)viewLocal:(id)sender;

/*!
    @method     getSafariRecentDownloadsMenu
    @abstract   Returns a menu of items for local paths of recent downloads from Safari. Returns nil if there are no valid items.
    @discussion (comprehensive description)
*/
- (NSMenu *)getSafariRecentDownloadsMenu;

/*!
    @method     getSafariRecentURLsMenu
    @abstract   Returns a menu of items for remote URLs of recent downloads from Safari. Returns nil if there are no valid items.
    @discussion (comprehensive description)
*/
- (NSMenu *)getSafariRecentURLsMenu;

/*!
    @method     getSafariRecentURLsMenu
    @abstract   Returns a menu of items for local paths of recent documents from Preview. Returns nil if there are no valid items.
    @discussion (comprehensive description)
*/
- (NSMenu *)getPreviewRecentDocumentsMenu;

/*!
    @method     setLocalURLPathFromMenuItem
    @abstract   Action to select a local file path from a menu item.
    @discussion (comprehensive description)
*/
- (void)setLocalURLPathFromMenuItem:(NSMenuItem *)sender;
- (void)chooseLocalURLPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

/*!
    @method     setRemoteURLFromMenuItem
    @abstract   Action to select a remote URL from a menu item.
    @discussion (comprehensive description)
*/
- (void)setRemoteURLFromMenuItem:(NSMenuItem *)sender;

/*!
    @method     viewRemote
    @abstract   Action to view the remote URL in the default browser.
    @discussion (comprehensive description)
*/
- (IBAction)viewRemote:(id)sender;

/*!
    @method     showCiteKeyWarning:
    @abstract   Action of the cite-key warning button. Shows the error string in an alert panel.
    @discussion (comprehensive description)
*/
- (IBAction)showCiteKeyWarning:(id)sender;

/*!
    @method     citeKeyDidChange:
    @abstract   Action of the cite-key field to set a new cite-key.
    @discussion (comprehensive description)
*/
- (IBAction)citeKeyDidChange:(id)sender;

/*!
    @method     setCiteKeyDuplicateWarning
    @abstract   Method to (un)set a warning to the user that the cite-key is a duplicate in te document. 
    @discussion (comprehensive description)
*/
- (void)setCiteKeyDuplicateWarning:(BOOL)set;

/*!
    @method     bibTypeDidChange:
    @abstract   Action of a form field to set a new value for a bibliography field.
    @discussion (comprehensive description)
*/
- (IBAction)bibTypeDidChange:(id)sender;
/*!
    @method     updateTypePopup
    @abstract   Update the type popup menu based on the current bibitem's type.  Needed for dragging support (see BDSKDragWindow.m).
    @discussion (comprehensive description)
*/
- (void)updateTypePopup;
- (void)bibWasAddedOrRemoved:(NSNotification *)notification;

- (IBAction)changeRating:(id)sender;
- (IBAction)changeFlag:(id)sender;

/*!
    @method     updateDocumentSnoopButton
    @abstract   Updates the icon for the document snoop button. 
    @discussion (comprehensive description)
*/
- (void)updateDocumentSnoopButton;

/*!
    @method     updateSnoopDrawerContent
    @abstract   Updates the content of the document snoop drawer. This should be called just before opening the drawer. 
    @discussion (comprehensive description)
*/
- (void)updateSnoopDrawerContent;

/*!
    @method     toggleSnoopDrawer:
    @abstract   Action to toggle the state or contents of the document snoop drawer. The content view is taken from the represented object of the sender menu item.
    @discussion (comprehensive description)
*/
- (void)toggleSnoopDrawer:(id)sender;

/*!
    @method     saveFileAsLocalUrl:
    @abstract   Action to save the current file in the web drawer and set the Local-Url to the saved location. 
    @discussion (comprehensive description)
*/
- (void)saveFileAsLocalUrl:(id)sender;

/*!
    @method     downloadLinkedFileAsLocalUrl:
    @abstract   Action to download a file linked in the web drawer and set the Local-Url to the saved location. 
    @discussion (comprehensive description)
*/
- (void)downloadLinkedFileAsLocalUrl:(id)sender;

/*!
    @method     citeKeyIsValid:
    @abstract   Checkes whether the proposed cite key is valid, i.e. unique. It just calls the one of the document.
    @discussion (comprehensive description)
*/
- (BOOL)citeKeyIsValid:(NSString *)proposedCiteKey;

/*!
    @method     generateCiteKey:
    @abstract   Action to generate a cite-key for the bibitem, using the cite-key format string. 
    @discussion (comprehensive description)
*/
- (IBAction)generateCiteKey:(id)sender;

/*!
    @method     generateLocalUrl:
    @abstract   Action to auto file the linked paper, using the local-url format string. 
    @discussion (comprehensive description)
*/
- (IBAction)generateLocalUrl:(id)sender;

/*!
    @method     duplicateTitleToBooktitle:
    @abstract   Action to copy the title field to the booktitle field. Overwrites the booktitle field.
    @discussion (comprehensive description)
*/
- (IBAction)duplicateTitleToBooktitle:(id)sender;

/*!
    @method     makeKeyField:
    @abstract   Selects the field and makes it key. 
    @discussion (comprehensive description)
*/
- (void)makeKeyField:(NSString *)fieldName;

- (void)bibDidChange:(NSNotification *)notification;
- (void)typeInfoDidChange:(NSNotification *)aNotification;
- (void)customFieldsDidChange:(NSNotification *)aNotification;
- (void)shouldCloseSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)bibWillBeRemoved:(NSNotification *)notification;
- (void)docWindowWillClose:(NSNotification *)notification;

/*!
	@method     openParentItem:
	@abstract   opens an editor for the crossref parent item.
	@discussion (description)
*/
- (void)openParentItem:(id)sender;
- (void)editInheritedAlertDidEnd:(BDSKAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;

#pragma mark Person controller

/*!
    @method     showPersonDetail:
	 @abstract   opens a BibPersonController to show details of a pub
	 @discussion (description)
*/
- (IBAction)showPersonDetailCmd:(id)sender;
- (void)showPersonDetail:(BibAuthor *)person;

#pragma mark Drag and drop

- (void)setPromisedDragURL:(NSURL *)theURL;
- (void)setPromisedDragFilename:(NSString *)theFilename;

#pragma mark Macro support
    
/*!
    @method     editSelectedFormCellAsMacro
    @abstract   pops up a window above the form cell with extra info about a macro.
    @discussion (description)
*/
- (BOOL)editSelectedFormCellAsMacro;
- (void)macrosDidChange:(NSNotification *)aNotification;
- (BOOL)macroEditorShouldEndEditing:(NSControl *)control withValue:(NSString *)value contextInfo:(void *)contextInfo;
- (void)macroEditorDidEndEditing:(NSControl *)control withValue:(NSString *)value contextInfo:(void *)contextInfo;

@end