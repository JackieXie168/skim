//
//  SKNoteWindowController.h
//  Skim
//
//  Created by Christiaan Hofman on 15/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class SKNote;

@interface SKNoteWindowController : NSWindowController {
    SKNote *note;
    
    id theModalDelegate;
    SEL theDidEndSelector;
    
    CFArrayRef editors;
}

- (id)initWithNote:(SKNote *)aNote;

- (SKNote *)note;
- (void)setNote:(SKNote *)newNote;

- (IBAction)dismissSheet:(id)sender;

- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)modalDelegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo;

- (BOOL)commitEditing;

@end
