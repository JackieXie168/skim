//
//  BibFinder.h
//  Bibdesk
//
//  Created by Michael McCracken on Tue Jan 22 2002.
//  Copyright (c) 2001 Michael McCracken. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKDragTableView.h"
#import "BDSKPreviewer.h"

/*!
    @class BibFinder
    @abstract The global search object
    @discussion Looks through all open bibs and finds appropriate results.
*/
@interface BibFinder : NSWindowController {
    IBOutlet BDSKDragTableView* tableView;
    IBOutlet NSTextField* searchTextField;
    IBOutlet NSComboBox* keySelectButton;
    IBOutlet NSButton* searchButton;
    IBOutlet NSTextField* resultsField;
    IBOutlet NSMenuItem *ctxCopyBibTex;
    IBOutlet NSMenuItem *ctxCopyTex;
    IBOutlet NSMenuItem *ctxCopyPDF;
    BDSKPreviewer *PDFpreviewer;
    NSMutableArray *foundBibs;
    NSMutableArray *foundBibDocs;
    NSMutableArray *bibKeys;    // stores the keys that show in the combobox.
}

+ (BibFinder *)sharedFinder;

- (IBAction)editPub:(id)sender;
- (IBAction)search:(id)sender;


/*!
    @method itemsMatchingConstraints
    @abstract Finds items that match a set of constraints
 @param constraints A Dictionary where keys are entry titles and values are text to search for in that key.
    
*/
- (NSMutableArray *)itemsMatchingConstraints:(NSDictionary *)constraints;
- (NSMutableArray *)itemsMatchingText:(NSString *)s inKey:(NSString *)key;
- (BOOL)searchForText:(NSString *)s inKey:(NSString *)key;
- (id)init;
- (void)addKey:(NSString *)key;
- (IBAction)copyAsBibTex:(id)sender;
- (IBAction)copyAsTex:(id)sender;
- (IBAction)copyAsPDF:(id)sender;
- (int)numberOfSelectedPubs;
- (NSEnumerator *)selectedPubEnumerator;
@end
