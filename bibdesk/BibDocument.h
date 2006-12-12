//  BibDocument.h

//  Created by Michael McCracken on Mon Dec 17 2001.
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

/*! @header BibDocument.h
    @discussion This defines a subclass of NSDocument that reads and writes BibTeX entries. It handles the main document window.
*/

#import <Cocoa/Cocoa.h>
#import "BDSKGroupTableView.h"
#import "BDSKFileContentSearchController.h"
#import "BDSKTemplateParser.h"
#import "BDSKOwnerProtocol.h"

@class BibItem, BibAuthor, BDSKGroup, BDSKStaticGroup, BDSKSmartGroup, BDSKTemplate, BDSKPublicationsArray, BDSKGroupsArray;
@class AGRegex, BDSKTeXTask, BDSKMacroResolver, BDSKItemPasteboardHelper;
@class BibEditor, MacroWindowController, BDSKDocumentInfoWindowController, BDSKPreviewer, BDSKFileContentSearchController, BDSKCustomCiteDrawerController;
@class BDSKAlert, BDSKStatusBar, BDSKMainTableView, BDSKGroupTableView, BDSKGradientView, BDSKSplitView, BDSKCollapsibleView, BDSKImagePopUpButton, BDSKColoredBox, BDSKSearchField, BDSKEncodingPopUpButton;

enum {
	BDSKOperationIgnore = NSAlertDefaultReturn, // 1
	BDSKOperationSet = NSAlertAlternateReturn, // 0
	BDSKOperationAppend = NSAlertOtherReturn, // -1
	BDSKOperationAsk = NSAlertErrorReturn, // -2
};

// these should correspond to the tags of copy-as menu items, as well as the default drag/copy type
enum {
	BDSKBibTeXDragCopyType, 
	BDSKCiteDragCopyType, 
	BDSKPDFDragCopyType, 
	BDSKRTFDragCopyType, 
	BDSKLaTeXDragCopyType, 
	BDSKLTBDragCopyType, 
	BDSKMinimalBibTeXDragCopyType, 
	BDSKRISDragCopyType,
    BDSKTemplateDragCopyType
};

enum {
    BDSKDetailsPreviewDisplay = 0,
    BDSKNotesPreviewDisplay = 1,
    BDSKAbstractPreviewDisplay = 2,
    BDSKTemplatePreviewDisplay = 3,
    BDSKPDFPreviewDisplay = 4,
    BDSKRTFPreviewDisplay = 5
};

// our main document types
extern NSString *BDSKBibTeXDocumentType;
extern NSString *BDSKRISDocumentType;
extern NSString *BDSKMinimalBibTeXDocumentType;
extern NSString *BDSKLTBDocumentType;
extern NSString *BDSKEndNoteDocumentType;
extern NSString *BDSKMODSDocumentType;
extern NSString *BDSKAtomDocumentType;

// Some pasteboard types used by the document for dragging and copying.
extern NSString* BDSKReferenceMinerStringPboardType; // pasteboard type from Reference Miner, determined using Pasteboard Peeker
extern NSString *BDSKBibItemPboardType;
extern NSString* BDSKWeblocFilePboardType; // core pasteboard type for webloc files

/*!
    @class BibDocument
    @abstract Controller class for .bib files
    @discussion This is the document class. It keeps an array of BibItems (called (NSMutableArray *)publications) and handles the quick search box. It delegates PDF generation to a BDSKPreviewer.
*/

@interface BibDocument : NSDocument <BDSKGroupTableDelegate, BDSKSearchContentView, BDSKOwner>
{
#pragma mark Main tableview pane variables

    IBOutlet NSWindow* documentWindow;
    IBOutlet BDSKMainTableView *tableView;
    IBOutlet BDSKSplitView* splitView;
    IBOutlet BDSKColoredBox* mainBox;
    
    IBOutlet BDSKStatusBar *statusBar;
    
    BDSKFileContentSearchController *fileSearchController;
    
#pragma mark Group pane variables

    IBOutlet BDSKGroupTableView *groupTableView;
    IBOutlet BDSKSplitView *groupSplitView;
    IBOutlet BDSKImagePopUpButton *groupActionButton;
    IBOutlet NSButton *groupAddButton;
    IBOutlet BDSKCollapsibleView *groupCollapsibleView;
    IBOutlet BDSKGradientView *groupGradientView;
	NSString *currentGroupField;
    
#pragma mark Preview variables

    IBOutlet NSTextView *previewTextView;
    IBOutlet NSView *currentPreviewView;
    BDSKPreviewer *previewer;
	
#pragma mark Toolbar variables
    
    NSMutableDictionary *toolbarItems;
	
	IBOutlet BDSKImagePopUpButton * actionMenuButton;
	IBOutlet BDSKImagePopUpButton * groupActionMenuButton;
		
	IBOutlet BDSKSearchField *searchField;

#pragma mark Custom Cite-String drawer variables
    
    BDSKCustomCiteDrawerController *drawerController;

#pragma mark Sorting variables

    NSString *sortKey;
    NSString *previousSortKey;
    NSString *sortGroupsKey;
    
#pragma mark Menu variables

	IBOutlet NSMenu * groupMenu;
	IBOutlet NSMenu * actionMenu;

#pragma mark Accessory view variables

    IBOutlet NSView *saveAccessoryView;
    IBOutlet NSView *exportAccessoryView;
    IBOutlet BDSKEncodingPopUpButton *saveTextEncodingPopupButton;
    IBOutlet NSButton *exportSelectionCheckButton;
    
#pragma mark Publications and Groups variables

    BDSKPublicationsArray *publications;  // holds all the publications
    NSMutableArray *groupedPublications;  // holds publications in the selected groups
    NSMutableArray *shownPublications;    // holds the ones we want to show.
    // All display related operations should use shownPublications
   
    BDSKGroupsArray *groups;
	
#pragma mark Macros, Document Info and Front Matter variables

    BDSKMacroResolver *macroResolver;
    MacroWindowController *macroWC;
	
    NSMutableDictionary *documentInfo;
    BDSKDocumentInfoWindowController *infoWC;
    
	NSMutableString *frontMatter;    // for preambles, and stuff
	
#pragma mark Copy & Drag related variables

    NSString *promiseDragColumnIdentifier;
    BDSKItemPasteboardHelper *pboardHelper;
    
#pragma mark Scalar state variables

    struct _docState {
        float               lastPreviewHeight;  // for the splitview double-click handling
        float               lastGroupViewWidth;
        NSStringEncoding    documentStringEncoding;
        NSSaveOperationType currentSaveOperationType; // used to check for autosave during writeToFile:ofType:
        BOOL                sortDescending;
        BOOL                sortGroupsDescending;
        BOOL                dragFromSharedGroups;
        BOOL                isDocumentClosed;
    } docState;
    
}


/*!
@method     init
 @abstract   initializer
 @discussion Sets up initial values. Note that this is called before IBOutlet ivars are connected.
 If you need to set up initial values for those, use awakeFromNib instead.
 @result     A BibDocument, or nil if some serious problem is encountered.
 */
- (id)init;

- (void)saveWindowSetupInExtendedAttributesAtURL:(NSURL *)anURL forSave:(BOOL)isSave;
- (NSDictionary *)mainWindowSetupDictionaryFromExtendedAttributes;
- (BOOL)isMainDocument;

/*!
    @method     clearChangeCount
    @abstract   needed because of finalize changes in BibEditor
    @discussion (comprehensive description)
*/
- (void)clearChangeCount;

- (NSFileWrapper *)fileWrapperOfType:(NSString *)aType forPublications:(NSArray *)items error:(NSError **)outError;
- (NSData *)dataOfType:(NSString *)aType forPublications:(NSArray *)items error:(NSError **)outError;

- (NSData *)stringDataForPublications:(NSArray *)items usingTemplate:(BDSKTemplate *)template;
- (NSData *)attributedStringDataForPublications:(NSArray *)items usingTemplate:(BDSKTemplate *)template;
- (NSData *)dataForPublications:(NSArray *)items usingTemplate:(BDSKTemplate *)template;
- (NSFileWrapper *)fileWrapperForPublications:(NSArray *)items usingTemplate:(BDSKTemplate *)template;

- (NSData *)atomDataForPublications:(NSArray *)items;
- (NSData *)MODSDataForPublications:(NSArray *)items;
- (NSData *)endNoteDataForPublications:(NSArray *)items;
- (NSData *)bibTeXDataForPublications:(NSArray *)items encoding:(NSStringEncoding)encoding droppingInternal:(BOOL)drop error:(NSError **)outError;
- (NSData *)RISDataForPublications:(NSArray *)items encoding:(NSStringEncoding)encoding error:(NSError **)error;
- (NSData *)LTBDataForPublications:(NSArray *)items encoding:(NSStringEncoding)encoding error:(NSError **)error;

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)aType encoding:(NSStringEncoding)encoding error:(NSError **)outError;

- (BOOL)readFromBibTeXData:(NSData *)data fromURL:(NSURL *)absoluteURL encoding:(NSStringEncoding)encoding error:(NSError **)outError;
- (BOOL)readFromData:(NSData *)data ofStringType:(int)type fromURL:(NSURL *)absoluteURL encoding:(NSStringEncoding)encoding error:(NSError **)outError;

- (void)reportTemporaryCiteKeys:(NSString *)tmpKey forNewDocument:(BOOL)isNewFile;

// Responses to UI actions

/*!
    @method updatePreviews
    @abstract Updates the document and/or shared previewer if needed. 
    @discussion The actual messages are queued and coalesced, so bulk actions will only update the previews once.
    
*/
- (void)updatePreviews;

/*!
    @method updatePreviewer:
    @abstract Handles updating a previewer.
    @discussion -
    @param aPreviewer The previewer to update
    
*/
- (void)updatePreviewer:(BDSKPreviewer *)aPreviewer;

/*!
    @method updatePreviewPane
    @abstract Handles writing the preview pane. (Not the PDF Preview)
    @discussion -
    
*/
- (void)updatePreviewPane;

/*!
	@method bibTeXStringForPublications
	@abstract auxiliary method for generating bibtex string for publication items
	@discussion generates appropriate bibtex string from the document's current selection by calling bibTeXStringDroppingInternal:droppingInternal:.
*/
- (NSString *)bibTeXStringForPublications:(NSArray *)items;

/*!
	@method bibTeXStringDroppingInternal:forPublications:
	@abstract auxiliary method for generating bibtex string for publication items
	@discussion generates appropriate bibtex string from given items.
*/
- (NSString *)bibTeXStringDroppingInternal:(BOOL)drop forPublications:(NSArray *)items;

/*!
	@method previewBibTeXStringForPublications:
	@abstract auxiliary method for generating bibtex string for publication items to use for generating RTF or PDF data
	@discussion generates appropriate bibtex string from given items.
*/
- (NSString *)previewBibTeXStringForPublications:(NSArray *)items;

/*!
	@method RISStringForPublications:
	@abstract auxiliary method for generating RIS string for publication items
	@discussion generates appropriate RIS string from given items.
*/
- (NSString *)RISStringForPublications:(NSArray *)items;

/*!
	@method citeStringForPublications:citeString:
	@abstract  method for generating cite string
	@discussion generates appropriate cite command from the given items 
*/

- (NSString *)citeStringForPublications:(NSArray *)items citeString:(NSString *)citeString;

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
- (BDSKPublicationsArray *)publications;
- (BDSKGroupsArray *)groups;
- (void)getCopyOfPublicationsOnMainThread:(NSMutableArray *)dstArray;
- (void)getCopyOfMacrosOnMainThread:(NSMutableDictionary *)dstDict;
- (void)insertPublications:(NSArray *)pubs atIndexes:(NSIndexSet *)indexes;
- (void)insertPublication:(BibItem *)pub atIndex:(unsigned int)index;

- (void)addPublications:(NSArray *)pubArray;
- (void)addPublication:(BibItem *)pub;

- (void)removePublicationsAtIndexes:(NSIndexSet *)indexes;
- (void)removePublications:(NSArray *)pubs;
- (void)removePublication:(BibItem *)pub;

- (NSDictionary *)documentInfo;
- (void)setDocumentInfoWithoutUndo:(NSDictionary *)dict;
- (void)setDocumentInfo:(NSDictionary *)dict;
- (NSString *)documentInfoForKey:(NSString *)key;
- (id)valueForUndefinedKey:(NSString *)key;
- (NSString *)documentInfoString;

#pragma mark bibtex macro support

- (BDSKMacroResolver *)macroResolver;

- (void)handleMacroChangedNotification:(NSNotification *)aNotification;

/* Paste related methods */
- (BOOL)addPublicationsFromPasteboard:(NSPasteboard *)pb error:(NSError **)error;
- (BOOL)addPublicationsFromFile:(NSString *)fileName error:(NSError **)outError;
- (NSArray *)newPublicationsFromArchivedData:(NSData *)data;
- (NSArray *)newPublicationsForString:(NSString *)string type:(int)type error:(NSError **)error;
- (NSArray *)newPublicationsForFiles:(NSArray *)filenames error:(NSError **)error;
- (NSArray *)extractPublicationsFromFiles:(NSArray *)filenames unparseableFiles:(NSMutableArray *)unparseableFiles error:(NSError **)error;
- (NSArray *)newPublicationForURL:(NSURL *)url error:(NSError **)error;

// Private methods

/*!
    @method updateStatus
    @abstract Updates the status message
    @discussion -
*/
- (void)updateStatus;

/*!
    @method     sortPubsByKey:
    @abstract   Sorts the publications table by the given key.  Pass nil for the table column to re-sort the previously sorted column with the same order.
    @discussion (comprehensive description)
    @param      key (description)
*/
- (void)sortPubsByKey:(NSString *)key;

/*!
    @method     columnsMenu
    @abstract   Returnes the columns menu
    @discussion (comprehensive description)
*/
- (NSMenu *)columnsMenu;

- (void)registerForNotifications;

/*!
    @method     handlePreviewDisplayChangedNotification:
    @abstract   only supposed to handle the pretty-printed preview, /not/ the TeX preview
    @discussion (comprehensive description)
    @param      notification (description)
*/
- (void)handlePreviewDisplayChangedNotification:(NSNotification *)notification;
- (void)handleTeXPreviewNeedsUpdateNotification:(NSNotification *)notification;
- (void)handleIgnoredSortTermsChangedNotification:(NSNotification *)notification;
- (void)handleNameDisplayChangedNotification:(NSNotification *)notification;
- (void)handleFlagsChangedNotification:(NSNotification *)notification;
- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification;
- (void)handleTableSelectionChangedNotification:(NSNotification *)notification;

// notifications observed on behalf of owned BibItems for efficiency
- (void)handleTypeInfoDidChangeNotification:(NSNotification *)notification;
- (void)handleCustomFieldsDidChangeNotification:(NSNotification *)notification;
    
/*!
    @method     handleBibItemAddDelNotification:
    @abstract   this method gets called for setPublications: also
    @discussion (comprehensive description)
    @param      notification (description)
*/
- (void)handleBibItemAddDelNotification:(NSNotification *)notification;

	
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

- (BOOL)selectItemsForCiteKeys:(NSArray *)citeKeys selectLibrary:(BOOL)flag;
- (BOOL)selectItemForPartialItem:(NSDictionary *)partialItem;

- (void)selectPublication:(BibItem *)bib;

- (void)selectPublications:(NSArray *)bibArray;

- (void)setStatus:(NSString *)status;
- (void)setStatus:(NSString *)status immediate:(BOOL)now;

- (NSStringEncoding)documentStringEncoding;
- (void)setDocumentStringEncoding:(NSStringEncoding)encoding;

/*!
    @method     saveSortOrder
    @abstract   Saves current sort order to preferences, to be restored on next launch/document open.
    @discussion (comprehensive description)
*/
- (void)saveSortOrder;

@end
