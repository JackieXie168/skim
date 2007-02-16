//
//  SKFindController.h
//  Skim
//
//  Created by Christiaan Hofman on 16/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BDSKFindFieldEditor;

@interface SKFindController : NSWindowController {
    IBOutlet NSTextField *findField;
    IBOutlet NSButton *ignoreCaseCheckbox;
    BOOL ignoreCase;
    BDSKFindFieldEditor *fieldEditor;
}

+ (id)sharedFindController;

- (IBAction)performFindPanelAction:(id)sender;
- (IBAction)findNext:(id)sender;
- (IBAction)findNextAndOrderOutFindPanel:(id)sender;
- (IBAction)findPrevious:(id)sender;
- (IBAction)setFindString:(id)sender;

- (BOOL)ignoreCase;
- (void)setIgnoreCase:(BOOL)newIgnoreCase;

- (int)findOptions;

- (id)target;
- (id)selectionSource;

@end


@interface NSObject (SKFindPanelTarget)
- (void)findString:(NSString *)string options:(int)options;
@end

@interface NSObject (SKFindPanelSelectionSource)
- (PDFView *)pdfView;
@end

