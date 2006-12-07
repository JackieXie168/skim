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
#import "RYZImagePopUpButton.h"

#import "MacroWindowController.h"
#import "BDSKTextImportController.h"

@class BDSKCustomCiteTableView;
@class BibItem;
@class BibEditor;
@class BibAuthor;
@class AGRegex;

// Local drag pasteboard currently stores bibtex string data to drag between open docs
// and pointer data to drag within a doc. 
// It might be a good idea sometime to replace cross-doc dragging with archived BibItems
// due to encoding issues.
extern NSString* LocalDragPasteboardName;
extern NSString* BDSKBibTeXStringPboardType;
extern NSString *BDSKBibItemLocalDragPboardType;

/*!
    @class BibDocument
    @abstract Controller class for .bib files
    @discussion This is the document class. It keeps an array of BibItems (called (NSMutableArray *)publications) and handles the quick search box. It delegates PDF generation to a BDSKPreviewer.
*/

@interface BibDocument : NSDocument <BDSKMacroResolver>
{
    IBOutlet NSTextView *previewField;
    IBOutlet NSWindow* documentWindow;
    IBOutlet BDSKDragTableView *tableView;
    IBOutlet NSMenuItem *ctxCopyBibTex;
    IBOutlet NSMenuItem *ctxCopyTex;
    IBOutlet NSMenuItem *ctxCopyPDF;
    IBOutlet OASplitView* splitView;
    // for the splitview double-click handling
    float lastPreviewHeight;

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
	IBOutlet NSView *searchFieldView; 
	NSToolbarItem *searchFieldToolbarItem;
        AGRegex *tipRegex;
        AGRegex *andRegex;
        AGRegex *orRegex;

	IBOutlet NSTextField *infoLine;

#pragma mark Custom Cite-String drawer variable declarations:

    IBOutlet NSDrawer* customCiteDrawer;
    IBOutlet BDSKCustomCiteTableView* ccTableView;
    IBOutlet NSButton *addCustomCiteStringButton;
    IBOutlet NSButton *removeCustomCiteStringButton;
    NSMutableArray* customStringArray;
	BOOL showingCustomCiteDrawer;
    
    NSMutableArray *publications;    // holds all the publications
    NSMutableArray *shownPublications;    // holds the ones we want to show.
    // All display related operations should use shownPublications
    // in aspect oriented objective c i could have coded that assertion!
    NSLock *pubsLock;
	
	NSMutableSet *authors;

    NSString *quickSearchKey;
    NSMutableDictionary *quickSearchTextDict;
   
	NSMutableString *frontMatter;    // for preambles, and stuff
    BDSKPreviewer *PDFpreviewer;
    NSTableColumn *lastSelectedColumnForSort;
    BOOL sortDescending;
	BOOL showStatus;
    NSMutableArray *BD_windowControllers; // private ivar for maintaining relationship with the docs windowcontrollers

    NSPasteboard *localDragPboard;
    // ----------------------------------------------------------------------------------------
    // general dialog used for adding 'fields' (used for adding contextual menus,)
    // and for adding quicksearch sortkeys.)
    IBOutlet NSWindow *addFieldSheet;
    // and its prompt:
    IBOutlet NSTextField* addFieldPrompt;
	IBOutlet NSComboBox* addFieldComboBox;
	
	// dialog for removing 'fields'.
	IBOutlet NSWindow *delFieldSheet;
	IBOutlet NSTextField* delFieldPrompt;
	IBOutlet NSPopUpButton* delFieldPopupButton;
	
    // --------------------------------------------------------------------------------------
    IBOutlet NSMenu * columnsMenu;
	IBOutlet NSMenu * actionMenu;
	IBOutlet RYZImagePopUpButton * actionMenuButton;
	IBOutlet NSMenuItem * actionMenuFirstItem;
	IBOutlet NSView * actionMenuView;

    // ----------------------------------------------------------------------------------------
    // stuff for the accessory view for the exportAsRSS
    IBOutlet NSView *rssExportAccessoryView;
    IBOutlet NSForm *rssExportForm;
    IBOutlet NSTextField* rssExportTextField;
    
    IBOutlet NSView *SaveEncodingAccessoryView;
    IBOutlet NSPopUpButton *saveTextEncodingPopupButton;
    NSStringEncoding documentStringEncoding;
    
    // stuff for the Source List for .bdsk type files.
    // Note: the outlets should migrate to a window controller.
    IBOutlet NSOutlineView *sourceList;
    IBOutlet NSButton *addSourceListItemButton;
    IBOutlet NSMenu *sourceListActionMenu;
    
    IBOutlet NSWindow *editExportSettingsWindow;
    IBOutlet NSPopUpButton *exporterSelectionPopUp;
    IBOutlet NSButton *exporterEnabledCheckButton;
    IBOutlet NSView *exporterSubView;
    
    // view:
    NSMutableArray *draggedItems; // an array to temporarily hold references to dragged items used locally.
    
    NSMutableDictionary *macroDefinitions;	
    MacroWindowController *macroWC;
}


/*!
@method     init
 @abstract   initializer
 @discussion Sets up initial values. Note that this is called before IBOutlet ivars are connected.
 If you need to set up initial values for those, use awakeFromNib instead.
 @result     A BibDocument, or nil if some serious problem is encountered.
 */
- (id)init;


/*!
    @method     awakeFromNib
    @abstract   Called when the document's nib is finished loading. Don't call this directly.
    @discussion Put things here that need to be done once, as soon as the window is loaded but before it is shown.
*/
- (void)awakeFromNib;

/*!
    @method     dealloc
    @abstract   Releases memory reserved by the BibDocument. 
 @discussion Don't call this. 
 It will be called automatically at the end of the object's lifetime.

*/
- (void)dealloc;

/*!
    @method     setupSearchField
    @abstract   Sets up quick search field.
    @discussion This method is called from awakeFromNib. 
 It either sets up an existing NSTextField and NSButton from the nib, or 
 creates an NSSearchField if you're running >10.2. It uses the global macro BDSK_USING_JAGUAR to tell.
 It also used to load saved search keys from preferences, but this is commented out now and may soon go away.
*/
- (void)setupSearchField;

/*!
    @method     searchFieldMenu
    @abstract   builds the quick search menu template for the NSSearchField
    @discussion this is only used in setupSearchField if not BDSK_USING_JAGUAR. 
 It is for the NSSearchField only, and it's only the template. 
 It shouldn't get called more than once, really.
    @result     An NSMenu for the NSSearchField to use as the template.
*/
- (NSMenu *)searchFieldMenu;

/*!
    @method     publicationsForAuthor:
    @abstract   Returns publications that an author is connected to
    @discussion ...
    @param      anAuthor A BibAuthor that may be connected to a pub in this document.
    @result     An array of BibItems that the author is connected to.
*/
- (NSArray *)publicationsForAuthor:(BibAuthor *)anAuthor;

/*!
    @method     exportAsRSS:
    @abstract   Action method to export RSS XML
    @discussion  This calls exportAsFileType:@"rss" droppingInternal:NO.
    @param      sender anything
*/
- (IBAction)exportAsRSS:(id)sender;

/*!
@method     exportAsHTML:
     @abstract   Action method to export HTML
     @discussion  This calls exportAsFileType:@"html" droppingInternal:NO.
     @param      sender anything
*/
- (IBAction)exportAsHTML:(id)sender;

/*!
@method     exportAsMODS:
     @abstract   Action method to export MODS XML. 
     @discussion  This calls exportAsFileType:@"mods" droppingInternal:NO.
 It should not be considered robust currently.
     @param      sender anything
*/
- (IBAction)exportAsMODS:(id)sender;

/*!
@method     exportAsAtom:
     @abstract   Action method to export ATOM XML for syndication.
     @discussion  This calls exportAsFileType:@"mods" droppingInternal:NO.
     It should not be considered robust currently.
     @param      sender anything
*/
- (IBAction)exportAsAtom:(id)sender;

/*!
    @method     exportEncodedBib:
    @abstract   Action method to export BibTex data
    @discussion This calls exportAsFileType:@"bib" droppingInternal:NO.
    @param      sender anything
*/
- (IBAction)exportEncodedBib:(id)sender;

/*!
    @method     exportEncodedBib:
    @abstract   Action method to export BibTex data without internal fields
    @discussion This calls exportAsFileType:@"bib" droppingInternal:YES.
    @param      sender anything
*/
- (IBAction)exportEncodedPublicBib:(id)sender;

/*!
    @method     exportRIS:
    @abstract   Action method to export RIS
    @discussion This calls exportAsFileType:@"ris" droppingInternal:NO.
    @param      sender anything
*/
- (IBAction)exportRIS:(id)sender;

/*!
    @method     exportAsFileType:droppingInternal:
    @abstract   Export the document's contents.
    @discussion Exports the entire document to one of many file types. 
 This method just opens a save panel, with the appropriate accessory view.
 On return from the save panel, Cocoa calls our method savePanelDidEnd:returnCode:contextInfo:
 @param      fileType A string representing the type to export.
 @param      drop A boolean specifying whether internal fields should be dropped. 
*/
- (void)exportAsFileType:(NSString *)fileType droppingInternal:(BOOL)drop;

/*!
    @method     savePanelDidEnd:returnCode:contextInfo:
 @abstract   Called after a save panel is closed.
 @discussion If the user chose to save, this calls the appropriate *DataRepresentation 
 method to get the data to save. Otherwise, it just returns without doing anything.

    @param      sheet The save panel
    @param      returnCode what happened
    @param      contextInfo ...
*/
- (void)savePanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (NSData *)rssDataRepresentation;
/*!
    @method     bibDataRepresentation
    @abstract   BibTeX representation of the entire document.
    @discussion Uses the document's string encoding as returned by -[BibDocument documentStringEncoding], which is the encoding used when opening the document.
    @param      drop Boolean determines whether internal fields should be dropped from the bibtex strings.
	@result     (description)
*/
- (NSData *)bibDataRepresentationDroppingInternal:(BOOL)drop;

/*!
    @method     htmlDataRepresentation
    @abstract   (description)
    @discussion (description)
    @result     (description)
*/
- (NSData *)htmlDataRepresentation;

/*!
    @method     publicationsAsHTML
    @abstract   (description)
    @discussion (description)
    @result     (description)
*/
- (NSString *)publicationsAsHTML;

- (NSData *)atomDataRepresentation;
- (NSData *)MODSDataRepresentation;
/*!
    @method     bibTeXDataWithEncoding:
    @abstract   Returns all of the BibItems as BibTeX with the specified string encoding.
    @discussion Used for export operations (saving with a specified string encoding, which is not necessarily the document's string encoding).
    @param      encoding (description)
    @param      drop (description)
    @result     (description)
*/
- (NSData *)bibTeXDataWithEncoding:(NSStringEncoding)encoding droppingInternal:(BOOL)drop;

/*!
    @method     RISDataWithEncoding:
    @abstract   Returns document contents in RIS form as NSData, in the specified string encoding.
    @discussion (comprehensive description)
    @param      encoding (description)
    @result     (description)
*/
- (NSData *)RISDataWithEncoding:(NSStringEncoding)encoding;
/*!
    @method     RISDataRepresentation
    @abstract   Returns document contents in RIS form as NSData, using the document's specified string encoding.
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSData *)RISDataRepresentation;

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType;
- (BOOL)loadBibTeXDataRepresentation:(NSData *)data encoding:(NSStringEncoding)encoding;
- (BOOL)loadRSSDataRepresentation:(NSData *)data;
- (BOOL)loadRISDataRepresentation:(NSData *)data encoding:(NSStringEncoding)encoding;

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

- (IBAction)selectDuplicates:(id)sender;

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
    @method     publicationsWithSubstring:inField:forArray:
    @abstract   Returns an array of publications matching the search term in the given field and array of BibItems.
    @discussion This method does all of the work in searching through a publications array for BibItems with a given
                substring, in a particular field or all fields.  A Boolean-type search is possible, by using AND and OR
                keywords (all caps), although it appears to be flaky under some conditions.
    @param      substring The string to search for.
    @param      field The BibItem field to search in (e.g. Author).
    @param      arrayToSearch The array of BibItems to search in, typically the documents publications ivar.
    @result     Returns an array of BibItems which matched the given search terms.
*/
- (NSArray *)publicationsWithSubstring:(NSString *)substring inField:(NSString *)field forArray:(NSArray *)arrayToSearch;

/*!
    @method     cacheQuickSearchRegexes
    @abstract   Cache AGRegex ivars used in the quicksearch field
    @discussion (comprehensive description)
*/
- (void)cacheQuickSearchRegexes;

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
 @discussion Creates a bibeditor if one doesn't exist, and tells it to show itself. 
 @param pub The BibItem that should be edited.
*/
- (void)editPub:(BibItem *)pub;

/*!
    @method cut
    @abstract delete and copy according to the preference
    @discussion deletes the currently selected publications and uses copy to put a representation on the general pasteboard. Does not call the delete sheet; you can paste them back. 
    @param sender The sender. Not used.
*/
- (IBAction)cut:(id)sender;

/*!
    @method copy
    @abstract copy according to the preference
    @discussion puts a representation of the currently selected publications onto the general pasteboard.
    @param sender The sender. Not used.
*/
- (IBAction)copy:(id)sender;

/*!
    @method copyAsBibTex
    @abstract copy as bibtex source
    @discussion puts the bibtex source of the currently selected publications onto the general pasteboard.
    @param sender The sender. Not used.
*/
- (IBAction)copyAsBibTex:(id)sender;

/*!
    @method copyAsPublicBibTex
    @abstract copy as bibtex source dropping internal fields
    @discussion puts the bibtex source of the currently selected publications onto the general pasteboard.
    @param sender The sender. Not used.
*/
- (IBAction)copyAsPublicBibTex:(id)sender;

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
	 @discussion generates appropriate cite command from the document's current selection by calling citeStringForPublication.
*/
- (NSString *)citeStringForSelection;

/*!
    @method citeStringForPublications
 @abstract  method for generating cite string
 @discussion generates appropriate cite command from the given items 
*/

- (NSString *)citeStringForPublications:(NSArray *)items;

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
- (void)setPublications:(NSArray *)newPubs;

/*!
    @method publications
 @abstract Returns the publications array.
    @discussion Returns the publications array.
    
*/
- (NSMutableArray *)publications;

- (void)insertPublication:(BibItem *)pub atIndex:(unsigned int)index lastRequest:(BOOL)last;

- (void)addPublication:(BibItem *)pub lastRequest:(BOOL)last;

- (void)removePublication:(BibItem *)pub lastRequest:(BOOL)last;

- (void)insertPublication:(BibItem *)pub atIndex:(unsigned int)index;

- (void)addPublication:(BibItem *)pub;

- (void)removePublication:(BibItem *)pub;

/*!
    @method     sortPubsByColumn:
    @abstract   Sorts the publications table by the given table column.  Pass nil for the table column to re-sort the previously sorted column with the same order.
    @discussion (comprehensive description)
    @param      tableColumn (description)
*/
- (void)sortPubsByColumn:(NSTableColumn *)tableColumn;

/*!
    @method     sortTableByDefaultColumn
    @abstract   Sorts the pubs table by the last column saved to user defaults (saved when a doc window closes).
    @discussion (comprehensive description)
*/
- (void)sortPubsByDefaultColumn;
#pragma mark bibtex macro support

- (NSMutableDictionary *)macroDefinitions;

/*!
    @method     setMacroDefinitions:
    @abstract   setter for macroDefinitions
    @discussion not to be used as part of UI - it doesn't invoke undo.
 It's intended to be used with file parsers to add many defs at once.
    @param      newMacroDefinitions (description)
*/
- (void)setMacroDefinitions:(NSMutableDictionary *)newMacroDefinitions;

/*!
    @method     addMacroDefinitionWithoutUndo:forMacro:
     @abstract   changes the definition for a macro
     @discussion overwrites an existing one if it exists. not undoable.
 for use with parsers.
     @param      macroString (description)
     @param      macroKey (description)
     */
- (void)addMacroDefinitionWithoutUndo:(NSString *)macroString forMacro:(NSString *)macroKey;

/*!
    @method     addMacroDefinition:forMacro:
    @abstract   changes the definition for a macro
    @discussion overwrites an existing one if it exists. undoable.
 sends BDSKBibDocMacroAddedNotification
    @param      macroString (description)
    @param      macroKey (description)
*/
- (void)addMacroDefinition:(NSString *)macroString forMacro:(NSString *)macroKey;

/*!
    @method     valueOfMacro:
    @abstract   returns the expanded value of a macro
    @discussion undoable.
    @param      macroString (description)
    @result     (description)
*/
- (NSString *)valueOfMacro:(NSString *)macroString;

/*!
    @method     removeMacro:
    @abstract   deletes a macro. 
    @discussion does nothing if macroKey isn't a current macro. if it does something, it's undoable.
    @param      macroKey (description)
*/
- (void)removeMacro:(NSString *)macroKey;

    /*!
    @method     showMacrosWindow:
     @abstract   shows the macro editing window
     @param      sender 
     */
- (IBAction)showMacrosWindow:(id)sender;

/*!
    @method     changeMacroKey:to:
    @abstract   changes a key but keeps the value the same.
    @discussion sends bdskbibdocmacrokeychangednotification.
    @param      oldKey (description)
    @param      newKey (description)
*/
- (void)changeMacroKey:(NSString *)oldKey to:(NSString *)newKey;

/*!
    @method     setMacroDefinition:forMacro:
    @abstract   sets the value of an existing macro.
    @discussion sends BDSKBibDocMacroDefinitionChangedNotification.
    @param      newDefinition (description)
    @param      macroKey (description)
*/
- (void)setMacroDefinition:(NSString *)newDefinition forMacro:(NSString *)macroKey;

    /*!
@method citeKeyIsUsed:byItemOtherThan
     @abstract tells whether aCiteKey is in the dict.
     @discussion ...

     */
- (BOOL)citeKeyIsUsed:(NSString *)aCiteKey byItemOtherThan:(BibItem *)anItem;

- (IBAction)generateCiteKey:(id)sender;

/* Paste related methods */
- (BOOL) addPublicationsFromPasteboard:(NSPasteboard*) pb error:(NSString**) error;
- (BOOL) addPublicationsForString:(NSString*) string error:(NSString**) error;
- (BOOL) addPublicationsForData:(NSData*) data error:(NSString**) error;
- (BOOL) addPublicationsForFiles:(NSArray*) filenames error:(NSString**) error;
- (IBAction)paste:(id)sender;



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
    @method columnsMenuSelectTableColumn
    @abstract handles when we choose an already-existing tablecolumn name in the menu
    @discussion \253discussion\273
    
*/
- (IBAction)columnsMenuSelectTableColumn:(id)sender;
/*!
    @method columnsMenuAddTableColumn
    @abstract called by the "add other..." menu item
    @discussion \253discussion\273
    
*/
- (IBAction)columnsMenuAddTableColumn:(id)sender;
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
    @method menuForTableViewSelection...
	@abstract called when an action/contextual menu is needed for a particular tableView
	@discussion uses the menu wired up as actionMenu and removes every item that doesn't validate.
Uses the tableview argument to determine which actionMenu it should validate.
 */
- (NSMenu *)menuForTableViewSelection:(NSTableView *)theTableView;



/*!
	@method updateActionMenus:
	@abstract makes sure the action menus are up to date and in place
	@ uses menuForTableViewSelection to rebuild the action menus
*/
- (void)updateActionMenus:(id) aNotification;


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

/*!
    @method     numberOfSelectedPubs
    @abstract   (description)
    @discussion (description)
    @result     the number of currently selected pubs in the doc
*/
- (int)numberOfSelectedPubs;

/*!
    @method     selectedPublications
    @abstract   (description)
    @discussion (description)
    @result     an array of the currently selected pubs in the doc
*/
- (NSArray *)selectedPublications;


/*!
    @method     selectedPubEnumerator
    @abstract   (description)
    @discussion (description)
    @result     an enumerator of the selected pubs in the doc
*/
- (NSEnumerator *)selectedPubEnumerator;

- (void)highlightBib:(BibItem *)bib;

- (void)highlightBib:(BibItem *)bib byExtendingSelection:(BOOL)yn;

- (IBAction)toggleStatusBar:(id)sender;

- (IBAction)toggleShowingCustomCiteDrawer:(id)sender;

- (IBAction)addCustomCiteString:(id)sender;
- (IBAction)removeCustomCiteString:(id)sender;

- (NSArray*) authors;
- (void)refreshAuthors;

/*!
    @method     pageDownInPreview:
    @abstract   Page down in the lower pane of the splitview using spacebar.
    @discussion Currently sent by the tableview, which gets keyDown: events.
    @param      sender (description)
*/
- (void)pageDownInPreview:(id)sender;

/*!
    @method     pageUpInPreview:
    @abstract   Page up in the lower pane of the splitview using spacebar.
    @discussion Currently sent by the tableview, which gets keyDown: events.
    @param      sender (description)
*/
- (void)pageUpInPreview:(id)sender;
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

/*!
    @function   compareSetLengths
    @abstract   Comparison function for sorting a mutable array of NSSets according to length
    @discussion (description)
    @param      (name) (description)
    @result     NSComparisonResult
*/
NSComparisonResult compareSetLengths(NSSet *set1, NSSet *set2, void *context);

- (IBAction)exportEncodedBib:(id)sender;
- (NSStringEncoding)documentStringEncoding;
- (void)setDocumentStringEncoding:(NSStringEncoding)encoding;

- (IBAction)importFromPasteboardAction:(id)sender;
- (IBAction)importFromFileAction:(id)sender;
- (IBAction)importFromWebAction:(id)sender;

@end
