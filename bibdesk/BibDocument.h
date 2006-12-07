//  BibDocument.h

//  Created by Michael McCracken on Mon Dec 17 2001.
/*
This software is Copyright (c) 2001,2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/*! @header BibDocument.h
    @discussion This defines a subclass of NSDocument that reads and writes BibTeX entries. It handles the main document window.
*/

#import <string.h>

#import <Cocoa/Cocoa.h>
#import "BibPrefController.h"
#import "BDSKPreviewer.h"
#import "BDSKDragTableView.h"
#import "BDSKCustomCiteTableView.h"
#import "BDSKConverter.h"
#import "BibTeXParser.h"
#import "PubMedParser.h"
#import <OmniAppKit/OASplitView.h>
#import "NSString+Templating.h"
#import "AvailabilityMacros.h"
#import "BibFiler.h"

#import "BDSKFileContentsFilter.h"
#import "ApplicationServices/ApplicationServices.h"
#import "BDSKPopUpButtonCell.h"
#import "RYZImagePopUpButton.h"


@class BDSKCustomCiteTableView;
@class BibItem;
@class BibEditor;

@class BibFinder;

extern NSString* LocalDragPasteboardName;

/*!
    @class BibDocument
    @abstract Controller class for .bib files
    @discussion This is the document class. It keeps an array of BibItems (called (NSMutableArray *)publications) and handles the quick search box. It delegates PDF generation to a BDSKPreviewer.
*/

@interface BibDocument : NSDocument
{
	IBOutlet NSTabView *previewTabView;
    IBOutlet NSTextView *previewField;
	IBOutlet NSImageView *PDFPreviewView;
	IBOutlet NSTextView *RTFPreviewView;
    IBOutlet NSWindow* documentWindow;
    IBOutlet NSWindow *bibListViews;
    IBOutlet BDSKDragTableView *tableView;
    IBOutlet NSMenuItem *ctxCopyBibTex;
    IBOutlet NSMenuItem *ctxCopyTex;
    IBOutlet NSMenuItem *ctxCopyPDF;
    IBOutlet OASplitView* splitView;

#pragma mark Toolbar variable declarations

    NSMutableDictionary *toolbarItems;
    NSToolbarItem *editPubButton;
    NSToolbarItem *delPubButton;
	
#pragma mark SearchField variable declarations
	
	// in nib for 10.2 compatibility
	IBOutlet NSTextField *searchFieldTextField; 
	IBOutlet NSPopUpButton *quickSearchButton;
    IBOutlet NSButton* quickSearchClearButton;
	
	id searchField; 
	IBOutlet NSBox *searchFieldBox;
	NSToolbarItem *searchFieldToolbarItem;

	IBOutlet NSTextField *infoLine;

#pragma mark Custom Cite-String drawer variable declarations:

    IBOutlet NSDrawer* customCiteDrawer;
    IBOutlet NSButton* openCustomCitePrefsButton;
    IBOutlet BDSKCustomCiteTableView* ccTableView;
    NSMutableArray* customStringArray;
	BOOL showingCustomCiteDrawer;
    
    NSMutableArray *publications;    // holds all the publications
    NSMutableArray *shownPublications;    // holds the ones we want to show.
    // All display related operations should use shownPublications
    // in aspect oriented objective c i could have coded that assertion!
	
	NSMutableArray *authors;

    NSMutableArray *bibEditors;
    NSString *quickSearchKey;
    NSMutableDictionary *quickSearchTextDict;
   
	NSMutableString *frontMatter;    // for preambles, and stuff
    BDSKPreviewer *PDFpreviewer;
    NSMutableArray *showColsArray;
    NSMutableDictionary *tableColumns;
    BOOL tableColumnsChanged;
    NSTableColumn *lastSelectedColumnForSort;
    BOOL sortDescending;

    NSPasteboard *localDragPboard;
    // ----------------------------------------------------------------------------------------
    // general dialog used for adding 'fields' (used for adding contextual menus,)
    // and for adding quicksearch sortkeys.)
    IBOutlet NSWindow *addFieldSheet;
    // and its prompt:
    IBOutlet NSTextField* addFieldPrompt;
    IBOutlet NSTextField* addFieldTextField;
	
	// dialog for removing 'fields'.
	IBOutlet NSWindow *delFieldSheet;
	IBOutlet NSTextField* delFieldPrompt;
	IBOutlet NSPopUpButton* delFieldPopupButton;
	
    // --------------------------------------------------------------------------------------
    IBOutlet NSMenu * contextualMenu;
	IBOutlet NSMenu * actionMenu;
	IBOutlet NSPopUpButton * actionMenuButton;
	IBOutlet NSMenuItem * actionMenuFirstItem;
    int fileOrderCount;
    // ----------------------------------------------------------------------------------------
    // stuff for the accessory view for the exportAsRSS
    IBOutlet NSView *rssExportAccessoryView;
    IBOutlet NSForm *rssExportForm;
    IBOutlet NSTextField* rssExportTextField;
}

- (void)awakeFromNib;
- (void)setupSearchField;
- (NSMenu *)searchFieldMenu;
- (id)init;
- (void)dealloc;
- (IBAction)exportAsRSS:(id)sender;
- (IBAction)exportAsHTML:(id)sender;
- (void)exportAsFileType:(NSString *)fileType;
- (void)saveDependentWindows; //@@bibeditor transparency - won't need this.
- (NSData *)rssDataRepresentation;
- (NSData *)bibDataRepresentation;
- (NSData *)htmlDataRepresentation;
- (NSString *)publicationsAsHTML;
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType;
- (BOOL)loadBibTeXDataRepresentation:(NSData *)data;
- (BOOL)loadRSSDataRepresentation:(NSData *)data;
- (BOOL)loadPubMedDataRepresentation:(NSData *)data;
- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType;



// Responses to UI actions
/*!
@method newPub:
    @abstract creates a new publication (BibItem)
 @discussion This is the action method for the 'new' button. It calls [self createNewBlankPubAndEdit:YES] 
    @param sender The sending object (not used, we assume it's the 'new' button.)
*/
- (IBAction)newPub:(id)sender; // new pub button pressed.

/*!
    @method delPub
    @abstract removes a publication (BibItem)
    @discussion This is the action method for the delete button. It removes the selected items of the tableview from the publications array. It assumes that there is at least one selected item -- the worst that could happen should be that the change count is wrong if it's called otherwise.
 @param sender The sending object - not used.
    
*/
- (IBAction)delPub:(id)sender;

#pragma mark searchField functions

/*!
    @method     makeSearchFieldKey:
    @abstract   action to highlight the search field
*/
- (IBAction)makeSearchFieldKey:(id)sender;

/*!
@method searchFieldChangeKey
 @abstract Changed what we look for in quicksearch
 @discussion This is called when we change what key to look for. It's the target of the nssearchfield.
 @param sender the sender. 
 
*/

- (IBAction)searchFieldChangeKey:(id)sender;

- (void)setSelectedSearchFieldKey:(NSString *)newKey;


/*!
    @method quickSearchAddField
    @abstract adds a field to the quicksearchMenu.
    @discussion 
    
*/
- (IBAction)quickSearchAddField:(id)sender;

- (void)quickSearchAddFieldSheetDidEnd:(NSWindow *)sheet
                            returnCode:(int) returnCode
                           contextInfo:(void *)contextInfo;


- (IBAction)quickSearchRemoveField:(id)sender;

- (IBAction)dismissDelFieldSheet:(id)sender;

- (void)quickSearchDelFieldSheetDidEnd:(NSWindow *)sheet
							returnCode:(int) returnCode
						   contextInfo:(void *)contextInfo;
	
- (IBAction)clearQuickSearch:(id)sender;

- (IBAction)searchFieldAction:(id)sender;

/*!
    @method     hidePublicationsWithoutSubstring:inField:
    @abstract Hides all pubs without substring in field.
    @discussion This manipulates the shownPublications array.
*/

- (void)hidePublicationsWithoutSubstring:(NSString *)substring inField:(NSString *)field;

/*!
    @method updatePreviews
    @abstract updates views because pub selection changed
    @discussion proxy for outline/tableview-selectiondidchange. - not the best name for this method, since it does more than update previews...
    
*/
- (void)updatePreviews:(NSNotification *)aNotification;



/*!
    @method displayPreviewForItems
    @abstract Handles writing the preview pane. (Not the PDF Preview)
    @discussion items is an enumerator of NSNumbers that are the row indices of the selected items.
    
*/
- (void)displayPreviewForItems:(NSEnumerator *)enumerator;

/*!
@method emailPubCmd
 
*/
- (IBAction)emailPubCmd:(id)sender;

    /*!
    @method editPubCmd
    @abstract an action to edit a publication has happened. 
    @discussion This is the tableview's doubleaction and the action of the edit pub button. It calls editPub with the tableview's selected publication.
    @param sender Not Used!
*/
- (IBAction)editPubCmd:(id)sender;


/*!
    @method multipleEditSheetDidEnd:retrunCode:contextInfo:
	@abstract evaluates answer to the sheet whether we want to open many editor windows 
	@discussion only opens the windows when NSAlertAlternateReturn is passed, we also call this for cases with few open windows to do the opening
	@param sheet (not used), returnCode (used to evaluate answer), contextInfo (not used)
*/
-(void) multipleEditSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;


/*!
    @method editPub
 @abstract Opens the edit window
 @discussion Creates a bibeditor if one doesn't exist, and tells it to show itself. calls editpub:forcechange = NO
 @param pub The BibItem that should be edited.
*/
- (void)editPub:(BibItem *)pub;

/*!
@method editPub:forceChange:
 @abstract Opens the edit window
 @discussion Creates a bibeditor if one doesn't exist, and tells it to show itself. 
 @param pub The BibItem that should be edited.
 @param force forces the bib to be marked as changed (useful for drag ins) <em> This method is not neccessarily permanent - this interface might be changed!</em>
 */
- (void)editPub:(BibItem *)pub forceChange:(BOOL)force;

/*!
    @method copyAsBibTex
    @abstract copy as bibtex source
    @discussion puts the bibtex source of the currently selected publications onto the general pasteboard.
    @param sender The sender. Not used.
*/
- (IBAction)copyAsBibTex:(id)sender;

/*!
    @method copyAsTex
 @abstract copy as tex citation (\\cite{})
 @discussion puts the appropriate citations of the currently selected publications onto the general pasteboard.
 @param sender The sender. Not used.
*/
- (IBAction)copyAsTex:(id)sender;

/*!
    @method citeStringForSelection
	 @abstract auxiliary method for generating cite string
	 @discussion generates appropriate cite command from the document's current selection 
*/
-(NSString*) citeStringForSelection;

/*!
    @method copyAsPDF
 @abstract copy as PDF typeset image
 @discussion puts the typeset image of the currently selected publications onto the general pasteboard rendered using tex and bibtex and the user's selected style file.
 @param sender The sender. Not used.
 */
- (IBAction)copyAsPDF:(id)sender;

/*!
@method copyAsRTF
@abstract copy as RTF typeset image
@discussion puts the typeset image of the currently selected publications onto the general pasteboard rendered using tex and bibtex and the user's selected style file.
@param sender The sender. Not used.
*/
- (IBAction)copyAsRTF:(id)sender;

/*!
    @method setPublications
    @abstract Sets the publications array
    @discussion Simply replaces the publications array
    @param newPubs The new array.
*/
- (void)setPublications:(NSMutableArray *)newPubs;

/*!
    @method publications
    @discussion Returns the publications array.
    
*/
- (NSMutableArray *)publications;

- (void)addPublication:(BibItem *)pub lastRequest:(BOOL)last;

- (void)removePublication:(BibItem *)pub lastRequest:(BOOL)last;

- (void)addPublication:(BibItem *)pub;

- (void)removePublication:(BibItem *)pub;


    /*!
@method citeKeyIsUsed:byItemOtherThan
     @abstract tells whether aCiteKey is in the dict.
     @discussion ...

     */
- (BOOL)citeKeyIsUsed:(NSString *)aCiteKey byItemOtherThan:(BibItem *)anItem;


// Private methods
/*!
    @method createNewBlankPub
    @abstract Action method for the new pub button.
 @discussion calls [createNewBlankPubAndEdit:YES]
    
*/
- (void)createNewBlankPub;

/*!
    @method createNewBlankPubAndEdit
    @abstract Supports creating new publications
    @discussion adds a new publication and may edit it.
    @param yn A boolean -- whether or not to tell the new pub to open an editor window.
*/
- (void)createNewBlankPubAndEdit:(BOOL)yn;

/*!
    @method handleUpdateUINotification
    @abstract listens for notification telling us to update UI.
    @discussion \253discussion\273
    
*/

- (void)handleUpdateUINotification:(NSNotification *)notification;

/*!
    @method updateUI
    @abstract Updates user interface elements
    @discussion Mainly, tells tableview to reload data and calls tableviewselectiondidchange.
*/
- (void)updateUI;

/*!
    @method setupTableColumns
    @abstract \253Abstract\273
    @discussion \253discussion\273
    
*/
- (void)setupTableColumns;

int generalBibItemCompareFunc(id item1, id item2, void *context);

/*!
	@method menuForTableColumn:row:
 @abstract \253Abstract\273
 @discussion \253discussion\273
 
*/
- (NSMenu *)menuForTableColumn:(NSTableColumn *)tc row:(int)row;

/*!
@method contextualMenuAddTableColumnName:enabled:
    @abstract \253Abstract\273
    @discussion \253discussion\273
    
*/
- (void)contextualMenuAddTableColumnName:(NSString *)name enabled:(BOOL)yn;

/*!
    @method contextualMenuSelectTableColumn
    @abstract handles when we choose an already-existing tablecolumn name in the menu
    @discussion \253discussion\273
    
*/
- (IBAction)contextualMenuSelectTableColumn:(id)sender;
- (void)contextualMenuSelectTableColumn:(id)sender post:(BOOL)yn;
/*!
    @method contextualMenuAddTableColumn
    @abstract called by the "add other..." menu item
    @discussion \253discussion\273
    
*/
- (IBAction)contextualMenuAddTableColumn:(id)sender;
/*!
    @method dismissAddFieldSheet
    @abstract called when OK or Cancel is pressed on the sheet
    @discussion \253discussion\273
    
*/
- (IBAction)dismissAddFieldSheet:(id)sender;

/*!
    @method addTableColumnSheetDidEnd...
    @abstract called after sheet ended to incorporate changes
    @discussion \253discussion\273
    
*/
- (void)addTableColumnSheetDidEnd:(NSWindow *)sheet
                       returnCode:(int) returnCode
                      contextInfo:(void *)contextInfo;

/*!
    @method menuForSelection...
	@abstract called when an action/contextual menu is needed
	@discussion uses the menu wired up as actionMenu and removes every item that doesn't validate.
*/
- (NSMenu*) menuForSelection;


/*!
	@method updateActionMenu:
	@abstract makes sure the action menu is up to date and in place
	@ uses menuForSelection to rebuild the action menu
*/
- (void) updateActionMenu:(id) aNotification;


/*!
    @method handleTableColumnChangedNotification
    @abstract incorporates changes from other windows.
    @discussion 
    
*/
- (void)handleTableColumnChangedNotification:(NSNotification *)notification;

/*!
    @method handleFontChangedNotification
    @abstract responds to font change notification by calling setTableFont
    @discussion
    
*/
- (void)handleFontChangedNotification:(NSNotification *)notification;


	/*!
    @method setTableFont
	 @abstract sets the font of the tableView.
	 @discussion 
	 
	 */
- (void)setTableFont;

	
/*!
    @method handleBibItemChangedNotification
	 @abstract responds to changing bib data
	 @discussion 
*/
- (void)handleBibItemChangedNotification:(NSNotification *)notification;

- (int)numberOfSelectedPubs;
- (NSEnumerator *)selectedPubEnumerator;

- (void)highlightBib:(BibItem *)bib;

- (void)highlightBib:(BibItem *)bib byExtendingSelection:(BOOL)yn;


- (IBAction)openCustomCitePrefPane:(id)sender;
- (IBAction)toggleShowingCustomCiteDrawer:(id)sender;

- (NSArray*) authors;
- (void)refreshAuthors;

/*!
    @method splitViewDoubleClick:
    @abstract A delegate method of the OASplitView. Handles doubleClicking.
    @discussion \253discussion\273
    
*/
- (void)splitViewDoubleClick:(OASplitView *)sender;

/*!
    @method     consolidateLinkedFiles:
    @abstract   invokes autofile. see BibFiler.h,m for info
    
*/

- (IBAction)consolidateLinkedFiles:(id)sender;

- (IBAction)postItemToWeblog:(id)sender;

@end
