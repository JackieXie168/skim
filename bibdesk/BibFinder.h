//  BibFinder.h

//  Created by Michael McCracken on Tue Jan 22 2002.
//  Copyright (c) 2001 Michael McCracken. All rights reserved.
/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

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
/*!
    @method    itemsMatchingCiteKey 
    @abstract   gives an array of dictionaries of items matching key.
 @discussion the dictionaries have @"BibItem" = the matching item and @"BibDocument" = the matching item's owner document
*/

- (NSMutableArray *)itemsMatchingCiteKey:(NSString *)key;
- (BOOL)searchForText:(NSString *)s inKey:(NSString *)key;
- (id)init;
- (void)addKey:(NSString *)key;
- (IBAction)copyAsBibTex:(id)sender;
- (IBAction)copyAsTex:(id)sender;
- (IBAction)copyAsPDF:(id)sender;
- (int)numberOfSelectedPubs;
- (NSEnumerator *)selectedPubEnumerator;
- (IBAction)copyAsRTF:(id)sender;
@end
