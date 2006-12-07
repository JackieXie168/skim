//
//  MacroWindowController.h
//  Bibdesk
//
//  Created by Michael McCracken on 2/21/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKComplexString.h" // for BDSKMacroResolver protocol
#import "BibPrefController.h" // for notification name declarations
#import <OmniFoundation/NSUndoManager-OFExtensions.h> // for isUndoingOrRedoing
#import <OmniFoundation/NSString-OFExtensions.h>

@interface MacroWindowController : NSWindowController {
    id macroDataSource;
    NSMutableArray *macros;
    IBOutlet NSTableView *tableView;
}

- (void)setMacroDataSource:(id)newMacroDataSource;
- (id)macroDataSource;
- (void)refreshMacros;

- (IBAction)addMacro:(id)sender;
- (IBAction)removeSelectedMacros:(id)sender;
- (BOOL)addMacrosFromBibTeXString:(NSString *)aString;

@end

@interface MacroKeyFormatter : NSFormatter {

}

@end

@interface MacroDragTableView : NSTableView{
}
@end
