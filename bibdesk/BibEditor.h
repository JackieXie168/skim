//
//  BibEditor.h
//  Bibdesk
//
//  Created by Michael McCracken on Mon Dec 24 2001.
//  Copyright (c) 2001 Michael McCracken. All rights reserved.
//
/*! @header BibEditor.h
    @discussion The class for editing BibItems. Handles the UI for the fields and notes.
*/

#import <Cocoa/Cocoa.h>

#import <OmniFoundation/OmniFoundation.h>

#import "BibItem.h"
#import "BibDocument.h"
#import "BDSKCiteKeyFormatter.h"

extern NSString *BDSKAnnoteString;
extern NSString *BDSKAbstractString;
extern NSString *BDSKRssDescriptionString;
extern NSString *BDSKLocalUrlString;
extern NSString *BDSKUrlString;


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
    IBOutlet NSButton* viewLocalButton;
    IBOutlet NSButton* viewRemoteButton;
    IBOutlet NSScrollView* fieldsScrollView;
    // ----------------------------------------------------------------------------------------
    // New-field Sheet stuff:
    IBOutlet NSTextField *newFieldName;
    IBOutlet NSButton* newFieldButtonOK;
    IBOutlet NSButton* newFieldButtonCancel;
    IBOutlet NSWindow* newFieldWindow;
    // ----------------------------------------------------------------------------------------
    // change count stuff:
    int changeCount;
    // ----------------------------------------------------------------------------------------
    // Delete-field Sheet stuff:
    IBOutlet NSPopUpButton *delFieldPopUp;
    IBOutlet NSButton* delFieldButtonOK;
    IBOutlet NSButton* delFieldButtonCancel;
    IBOutlet NSWindow* delFieldWindow;
    // ----------------------------------------------------------------------------------------
    BibType currentType;
    BibItem *theBib;
    BibItem *tmpBib;
    BibDocument *theDoc;
    NSEnumerator *e;
    NSMutableDictionary *fieldNumbers;
    BOOL needsRefresh;
// ----------------------------------------------------------------------------------------
// doc preview stuff
// ----------------------------------------------------------------------------------------
    IBOutlet NSDrawer* documentSnoopDrawer;
    IBOutlet NSImageView *documentSnoopImageView;
    IBOutlet NSButton* documentSnoopButton;
    IBOutlet NSScrollView* documentSnoopScrollView;
// Autocompletion stuff
    NSDictionary *completionMatcherDict;
// cite string formatter
    BDSKCiteKeyFormatter *citeKeyFormatter;
}

/*!
@method initWithBibItem:andBibDocument:
    @abstract designated Initializer
    @discussion
 @param aBib gives us a bib to edit
 @param aDoc the document to notify of changes
*/
- (id)initWithBibItem:(BibItem *)aBib andBibDocument:(BibDocument *)aDoc;

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

- (void)fixURLs;
- (void)fixEditedStatus;
- (void)updateChangeCount:(NSDocumentChangeType)changeType;
- (BOOL)isEdited;


// ----------------------------------------------------------------------------------------
// Add field sheet support
// ----------------------------------------------------------------------------------------
- (IBAction)raiseAddField:(id)sender;
- (IBAction)dismissAddField:(id)sender;
- (void)addFieldSheetDidEnd:(NSWindow *)sheet
                 returnCode:(int) returnCode
                contextInfo:(void *)contextInfo;

    // ----------------------------------------------------------------------------------------
    // Add field sheet support
    // ----------------------------------------------------------------------------------------
- (IBAction)raiseDelField:(id)sender;
- (IBAction)dismissDelField:(id)sender;
- (void)delFieldSheetDidEnd:(NSWindow *)sheet
                 returnCode:(int) returnCode
                contextInfo:(void *)contextInfo;

- (IBAction)revert:(id)sender;
- (IBAction)saveDocument:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

- (IBAction)viewLocal:(id)sender;
- (IBAction)viewRemote:(id)sender;
- (IBAction)citeKeyDidChange:(id)sender;

- (IBAction)bibTypeDidChange:(id)sender;
- (IBAction)textFieldDidChange:(id)sender;
- (IBAction)textFieldDidEndEditing:(id)sender;

- (void)closeSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end
