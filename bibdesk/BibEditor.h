//  BibEditor.h

//  Created by Michael McCracken on Mon Dec 24 2001.
/*
 This software is Copyright (c) 2001,2002,2003,2004,2005,2006
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
@class BDSKFieldNameFormatter;
@class BDSKComplexStringFormatter;
@class BDSKCrossrefFormatter;
@class MacroFormWindowController;
@class BDSKImagePopUpButton;
@class BibItem;
@class BDSKStatusBar;
@class BDSKAlert;
@class BibAuthor;
@class BDSKZoomablePDFView;

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
    IBOutlet NSView* fieldsAccessoryView;
    IBOutlet NSPopUpButton* fieldsPopUpButton;
	NSTextView *currentEditedView;
    NSUndoManager *notesViewUndoManager;
    NSUndoManager *abstractViewUndoManager;
    NSUndoManager *rssDescriptionViewUndoManager;
    BOOL ignoreFieldChange;
    // for the splitview double-click handling
    float lastMatrixHeight;
	
	NSButtonCell *booleanButtonCell;
	NSButtonCell *triStateButtonCell;
	BDSKRatingButtonCell *ratingButtonCell;
    
    IBOutlet NSTextField* citeKeyField;
    IBOutlet NSTextField* citeKeyTitle;
	IBOutlet BDSKImagePopUpButton *viewLocalButton;
    IBOutlet BDSKImagePopUpButton *viewRemoteButton;
    IBOutlet BDSKImagePopUpButton *documentSnoopButton;
	IBOutlet BDSKImagePopUpButton *actionMenuButton;
	NSToolbarItem *viewLocalToolbarItem;
	NSToolbarItem *viewRemoteToolbarItem;
	NSToolbarItem *documentSnoopToolbarItem;
	NSToolbarItem *authorsToolbarItem;
	IBOutlet BDSKImagePopUpButton *actionButton;
    IBOutlet NSMenu *actionMenu;
	IBOutlet NSButton *addFieldButton;
	
    IBOutlet NSPanel *changeFieldNameSheet;
    IBOutlet NSPopUpButton *oldFieldNamePopUp;
    IBOutlet NSComboBox *newFieldNameComboBox;
    // ----------------------------------------------------------------------------------------
    BibItem *publication;
    BOOL isEditable;
// ----------------------------------------------------------------------------------------
// doc preview stuff
// ----------------------------------------------------------------------------------------
    IBOutlet NSDrawer* documentSnoopDrawer;
	int drawerState;
	int drawerButtonState;
	// doc textpreview stuff
    IBOutlet BDSKZoomablePDFView *documentSnoopPDFView;
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
	
// cite-key checking stuff:
	IBOutlet NSButton *citeKeyWarningButton;
	
// form cell formatter
    BDSKComplexStringFormatter *formCellFormatter;
    BDSKCrossrefFormatter *crossrefFormatter;
	
// Author tableView
	IBOutlet NSTableView *authorTableView;
	IBOutlet NSScrollView *authorScrollView;

    // Macro editing stuff
    MacroFormWindowController *macroTextFieldWC;

	// edit field stuff
	BOOL forceEndEditing;
    NSMutableDictionary *toolbarItems;
    BOOL windowHasSheet;

    BOOL didSetupForm;
	
	NSTextView *dragFieldEditor;
	
    NSString *promisedDragFilename;
    NSURL *promisedDragURL;
}

/*!
@method initWithPublication:
    @abstract designated Initializer
    @discussion
 @param aBib gives us a bib to edit
*/
- (id)initWithPublication:(BibItem *)aBib;

- (BibItem *)publication;

/*!
    @method     show
    @abstract   Shows the window.
    @discussion (comprehensive description)
*/
- (void)show;

/*!
    @method     chooseLocalURL:
    @abstract   Action to choose a local file using the Open dialog. 
    @discussion (comprehensive description)
*/
- (IBAction)chooseLocalURL:(id)sender;
- (void)chooseLocalURLPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (IBAction)toggleStatusBar:(id)sender;

// ----------------------------------------------------------------------------------------
// Add-field sheet support
// ----------------------------------------------------------------------------------------
- (IBAction)raiseAddField:(id)sender;

// ----------------------------------------------------------------------------------------
// Delete-field sheet support
// ----------------------------------------------------------------------------------------
- (IBAction)raiseDelField:(id)sender;

- (IBAction)raiseChangeFieldName:(id)sender;
- (IBAction)dismissChangeFieldNameSheet:(id)sender;

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
    @abstract   sets field to value in publication and does other stuff
    @discussion factored out because setting field and doing other things is done from more than one place.
    @param      fieldName (description)
    @param      value (description)
*/
- (void)recordChangingField:(NSString *)fieldName toValue:(NSString *)value;

- (void)needsToBeFiledDidChange:(NSNotification *)notification;

- (void)updateCiteKeyAutoGenerateStatus;

- (void)autoFilePaper;

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
    @method     openLinkedFile
    @abstract   Action to view the local file in the default viewer.
    @discussion (comprehensive description)
*/
- (IBAction)openLinkedFile:(id)sender;

/*!
    @method     revealLinkedFile
    @abstract   Action to reveal the local file in the Finder.
    @discussion (comprehensive description)
*/
- (IBAction)revealLinkedFile:(id)sender;

/*!
    @method     moveLocalURL:
    @abstract   Action to move a local file using the Save dialog. 
    @discussion (comprehensive description)
*/
- (IBAction)moveLinkedFile:(id)sender;
- (void)moveLinkedFilePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)updateMenu:(NSMenu *)menu forImagePopUpButton:(BDSKImagePopUpButton *)view;

/*!
    @method     updateSafariRecentDownloadsMenu:
    @abstract   Updates the menu of items for local paths of recent downloads from Safari.
    @discussion (comprehensive description)
*/
- (void)updateSafariRecentDownloadsMenu:(NSMenu *)menu;

/*!
    @method     updateSafariRecentURLsMenu:
    @abstract   Updates the menu off items for remote URLs of recent downloads from Safari.
    @discussion (comprehensive description)
*/
- (void)updateSafariRecentURLsMenu:(NSMenu *)menu;

/*!
    @method     updatePreviewRecentDocumentsMenu:
    @abstract   Updates the menu of items for local paths of recent documents from Preview.
    @discussion (comprehensive description)
*/
- (void)updatePreviewRecentDocumentsMenu:(NSMenu *)menu;

/*!
    @method     recentDownloadsMenu
    @abstract   Returns a menu of modified files in the system download directory using Spotlight.
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSMenu *)recentDownloadsMenu;

/*!
    @method     updateRecentDownloadsMenu:
    @abstract   Updates the menu of recently modified files in the system download directory using Spotlight.
    @discussion (comprehensive description)
    @result     (description)
*/
- (void)updateRecentDownloadsMenu:(NSMenu *)menu;


/*!
    @method     updateAuthorsToolbarMenu:
    @abstract   Updates the menu representatino of the Authors toolbar item.
    @discussion (comprehensive description)
    @result     (description)
*/
- (void)updateAuthorsToolbarMenu:(NSMenu *)menu;

/*!
    @method     setLocalURLPathFromMenuItem
    @abstract   Action to select a local file path from a menu item.
    @discussion (comprehensive description)
*/
- (void)setLocalURLPathFromMenuItem:(NSMenuItem *)sender;

/*!
    @method     setRemoteURLFromMenuItem
    @abstract   Action to select a remote URL from a menu item.
    @discussion (comprehensive description)
*/
- (void)setRemoteURLFromMenuItem:(NSMenuItem *)sender;

/*!
    @method     openRemoteURL
    @abstract   Action to view the remote URL in the default browser.
    @discussion (comprehensive description)
*/
- (IBAction)openRemoteURL:(id)sender;

/*!
    @method     showCiteKeyWarning:
    @abstract   Action of the cite-key warning button. Shows the error string in an alert panel.
    @discussion (comprehensive description)
*/
- (IBAction)showCiteKeyWarning:(id)sender;

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
    @method     generateCiteKey:
    @abstract   Action to generate a cite-key for the bibitem, using the cite-key format string. 
    @discussion (comprehensive description)
*/
- (IBAction)generateCiteKey:(id)sender;

/*!
    @method     consolidateLinkedFiles:
    @abstract   Action to auto file the linked paper, using the local-url format string. 
    @discussion (comprehensive description)
*/
- (IBAction)consolidateLinkedFiles:(id)sender;

/*!
    @method     duplicateTitleToBooktitle:
    @abstract   Action to copy the title field to the booktitle field. Overwrites the booktitle field.
    @discussion (comprehensive description)
*/
- (IBAction)duplicateTitleToBooktitle:(id)sender;

- (NSString *)keyField;
- (void)setKeyField:(NSString *)fieldName;

- (void)bibDidChange:(NSNotification *)notification;
- (void)typeInfoDidChange:(NSNotification *)aNotification;
- (void)customFieldsDidChange:(NSNotification *)aNotification;

- (void)bibWillBeRemoved:(NSNotification *)notification;
- (void)groupWillBeRemoved:(NSNotification *)notification;

/*!
	@method     openParentItemForField:
	@abstract   opens an editor for the crossref parent item.
	@discussion (description)
*/
- (void)openParentItemForField:(NSString *)field;

- (IBAction)selectCrossrefParentAction:(id)sender;
- (IBAction)createNewPubUsingCrossrefAction:(id)sender;

- (IBAction)deletePub:(id)sender;

- (IBAction)editPreviousPub:(id)sender;
- (IBAction)editNextPub:(id)sender;

- (void)editInheritedAlertDidEnd:(BDSKAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (NSUndoManager *)undoManager;

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

@end


@interface BDSKTabView : NSTabView {}
@end

