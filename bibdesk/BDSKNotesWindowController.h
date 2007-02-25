//
//  BDSKNotesWindowController.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 25/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BDSKNotesWindowController : NSWindowController {
    NSURL *url;
    NSArray *notes;
    IBOutlet NSOutlineView *outlineView;
}

- (id)initWithURL:(NSURL *)aURL;

- (IBAction)refresh:(id)sender;
- (IBAction)openInSkim:(id)sender;

@end
