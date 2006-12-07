//
//  BibDocument.h
//  Bibdesk
//
//  Created by Michael McCracken on Mon Dec 17 2001.
//  Copyright (c) 2001 Michael McCracken. All rights reserved.
//
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
    NSToolbarItem *editPubButton;
    NSToolbarItem *delPubButton;
    IBOutlet NSPopUpButton *sortKeyButton;
    IBOutlet NSTextView *previewField;
    IBOutlet NSWindow* documentWindow;
    IBOutlet NSWindow *bibListViews;
    IBOutlet NSBox *dummyView;
    IBOutlet NSView *outlineBox;
    IBOutlet NSOutlineView *outlineView;
    IBOutlet NSView *tableBox;
    IBOutlet BDSKDragTableView *tableView;
    IBOutlet NSMenuItem *ctxCopyBibTex;
    IBOutlet NSMenuItem *ctxCopyTex;
    IBOutlet NSMenuItem *ctxCopyPDF;
    IBOutlet NSTextField *quickSearchTextField;
    IBOutlet NSBox* quickSearchBox;    // encompasses the qstxtfield and the qs button.
    IBOutlet NSPopUpButton *quickSearchButton;
    NSToolbarItem *quickSearchToolbarItem;
    NSToolbarItem *sortKeyToolbarItem;

    IBOutlet NSTextField *infoLine;
    IBOutlet NSButton* quickSearchClearButton;
// ----------------------------------------------------------------------------------------
// custom cite-String drawer stuff:
// ----------------------------------------------------------------------------------------
    IBOutlet NSDrawer* customCiteDrawer;
    IBOutlet NSButton* openCustomCitePrefsButton;
    IBOutlet BDSKCustomCiteTableView* ccTableView;
    NSMutableArray* customStringArray;
    
    NSMutableArray *publications;    // holds all the publications
    NSMutableArray *shownPublications;    // holds the ones we want to show.
    // All display related operations should use shownPublications
    // in aspect oriented objective c i could have coded that assertion!

    NSMutableArray *bibEditors;
    NSString *currentSortKey;
    NSString *quickSearchKey;
    NSMutableDictionary *quickSearchTextDict;
    NSMutableArray *allAuthors;
    NSMutableString *frontMatter;    // for preambles, and stuff
    BDSKPreviewer *PDFpreviewer;
    NSMutableArray *showColsArray;
    NSMutableDictionary *tableColumns;
    BOOL tableColumnsChanged;
    NSPasteboard *localDragPboard;
    // ----------------------------------------------------------------------------------------
    // general dialog used for adding 'fields' (used for adding contextual menus,)
    // and for adding quicksearch sortkeys.)

    IBOutlet NSWindow *addFieldSheet;
    //and its prompt:
    IBOutlet NSTextField* addFieldPrompt;
    IBOutlet NSTextField* addFieldTextField;
    // --------------------------------------------------------------------------------------
    IBOutlet NSMenu *contextualMenu;
    int fileOrderCount;

    // ----------------------------------------------------------------------------------------
    // stuff for the accessory view for the exportAsRSS
    IBOutlet NSView *rssExportAccessoryView;
    IBOutlet NSForm *rssExportForm;
    IBOutlet NSTextField* rssExportTextField;
}
- (void)awakeFromNib;
- (id)init;
- (void)dealloc;
- (IBAction)exportAsRSS:(id)sender;
- (void)saveDependentWindows;
- (NSData *)rssDataRepresentation;
- (NSData *)bibDataRepresentation;
- (BOOL)loadBibTeXDataRepresentation:(NSData *)data;
- (BOOL)loadRSSDataRepresentation:(NSData *)data;


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

/*!
@method didChangeQuickSearchKey
 @abstract Changed what we look for in quicksearch
 @discussion This is called when we change what key to look for. It's the target of the popupbutton.
 @param sender the sender. not used
 
*/
- (IBAction)didChangeQuickSearchKey:(id)sender;

/*!
    @method quickSearchAddField
    @abstract \253Abstract\273
    @discussion \253discussion\273
    
*/
- (IBAction)quickSearchAddField:(id)sender;

- (void)quickSearchAddFieldSheetDidEnd:(NSWindow *)sheet
                            returnCode:(int) returnCode
                           contextInfo:(void *)contextInfo;

/*!
    @method clearQuickSearch
    @abstract \253Abstract\273
    @discussion \253discussion\273
    
*/
- (IBAction)clearQuickSearch:(id)sender;

/*!
    @method updatePreviews
    @abstract updates views because pub selection changed
    @discussion proxy for outline/tableview-selectiondidchange. - not the best name for this method, since it does more than update previews...
    
*/
- (void)updatePreviews:(NSNotification *)aNotification;

/*!
    @method didChangeSortKey
    @abstract state of sort key pulldown has changed
    @discussion Not used right now, but intended to support switching to an outline view sorted by authors.
    @param sender the sender. not used.
*/
- (IBAction)didChangeSortKey:(id)sender;

/*!
    @method displayPreviewForItems
    @abstract Handles writing the preview pane. (Not the PDF Preview)
    @discussion items is an enumerator of NSNumbers that are the row indices of the selected items.
    
*/
- (void)displayPreviewForItems:(NSEnumerator *)enumerator;

/*!
    @method sortPubsByColumn   
    @abstract \253Abstract\273
    @discussion \253discussion\273
    
*/
- (IBAction)sortPubsByColumn:(id)sender;


/*!
    @method editPubCmd
    @abstract an action to edit a publication has happened. 
    @discussion This is the tableview's doubleaction and the action of the edit pub button. It calls editPub with the tableview's selected publication.
    @param sender Not Used!
*/
- (IBAction)editPubCmd:(id)sender;

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
    @method copyAsPDF
 @abstract copy as PDF typeset image
 @discussion puts the typeset image of the currently selected publications onto the general pasteboard rendered using tex and bibtex and the user's selected style file.
 @param sender The sender. Not used.
 */
- (IBAction)copyAsPDF:(id)sender;

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

/*!
@method allAuthors
    @abstract returns the allAuthors array
    @discussion \253discussion\273
    
*/
- (NSArray *)allAuthors;

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
    @method updateUIAndRefreshOutline
    @abstract no different from updateUI, yet.
    @discussion 
    
*/
- (void)updateUIAndRefreshOutline:(BOOL)yn;

/*!
    @method setupTableColumns
    @abstract \253Abstract\273
    @discussion \253discussion\273
    
*/
- (void)setupTableColumns;

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
    @method handleTableColumnChangedNotification
    @abstract incorporates changes from other windows.
    @discussion \253discussion\273
    
*/
- (void)handleTableColumnChangedNotification:(NSNotification *)notification;

/*!
    @method handleFontChangedNotification
    @abstract sets the font of the table/outlineView.
    @discussion \253discussion\273
    
*/
- (void)handleFontChangedNotification:(NSNotification *)notification;

- (int)numberOfSelectedPubs;
- (NSEnumerator *)selectedPubEnumerator;

- (void)highlightBib:(BibItem *)bib;

- (void)highlightBib:(BibItem *)bib byExtendingSelection:(BOOL)yn;


- (IBAction)openCustomCitePrefPane:(id)sender;
- (IBAction)toggleShowingCustomCiteDrawer:(id)sender;

/*!
    @method currentView
    @abstract returns which table/outlineview we're currently seeing.
    @discussion \253discussion\273
    
*/
- (id)currentView;
@end
