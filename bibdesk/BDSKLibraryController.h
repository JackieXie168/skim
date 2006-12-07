//
//  BDSKLibraryController.h

#import <Cocoa/Cocoa.h>
#import "BDSKLibrary.h"
#import "BDSKItemBibTeXDisplayController.h" / /@@temporary: this is for the hard-coded testing 
#import "BDSKItemSource.h"
#import "BibCollection.h"


@interface BDSKLibraryController : NSWindowController <BDSKItemSource> {
    
    IBOutlet NSTextField *infoLine;
    IBOutlet NSOutlineView *sourceList;
    IBOutlet NSButton *addSourceListItemButton;
    IBOutlet NSMenu *sourceListActionMenu;
	
	id <BDSKItemDisplayController> *currentItemDisplayController;
	IBOutlet NSView *currentItemDisplayView;
    IBOutlet NSSplitView *mainSplitView;
	
    IBOutlet NSWindow *editExportSettingsWindow;
    IBOutlet NSPopUpButton *exporterSelectionPopUp;
    IBOutlet NSButton *exporterEnabledCheckButton;
    IBOutlet NSView *exporterSubView;
	
    BibCollection *currentCollection;
    NSArray *selectedItems; // akin to shownpublications in BibDocument

    NSMutableArray *draggedItems; // an array to temporarily hold references to dragged items used locally.
    
#pragma mark search field variable declarations
    // note: not 10.2 compatible.
    IBOutlet NSSearchField *searchField;
	
}

- (void)registerForNotifications;

/*!
    @method     reloadSourceList
    @abstract   (description)
    @discussion (description)
*/
- (void)reloadSourceList;

- (NSArray *)selectedItems;
- (void)setSelectedItems:(NSArray *)newItems;

#pragma mark UI actions

/*!
    @method     newPub:
    @abstract   creates a new pub and adds it to the currently selected collection
    @discussion (description)
    @param      sender (description)
    @result     (description)
*/
- (IBAction)newPub:(id)sender;

	/*!
    @method     makeNewPublicationCollection:
	 @abstract   creates a new empty top-level collection and adds it to the document
	 @discussion (description)
	 @param      sender anything
	 */
- (IBAction)makeNewPublicationCollection:(id)sender;

    /*!
	@method     makeNewAuthorCollection
     @abstract   creates a new collection and adds it to the document's authors collection
     @discussion (description)
     @param      sender anything
     */
- (IBAction)makeNewAuthorCollection:(id)sender;


    /*!
	@method     makeNewExternalSourceCollection
     @abstract   creates a new externalSource and adds it to the document
     @discussion (description)
     @param      sender anything
     */
- (IBAction)makeNewExternalSourceCollection:(id)sender;

    /*!
    @method     makeNewNoteCollection
     @abstract   creates a new empty notepad and adds it to the document
     @discussion (description)
     @param      sender anything
     */
- (IBAction)makeNewNoteCollection:(id)sender;

- (void)updateInfoLine;

@end
