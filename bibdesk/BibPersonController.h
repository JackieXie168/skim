//
//  BibPersonController.h
//  Bibdesk
//
//  Created by Michael McCracken on Thu Mar 18 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "BibAuthor.h"
#import "BibItem.h"


@interface BibPersonController : NSWindowController {
    BibAuthor *_person;
    NSArray *publications;
	BibDocument *document;
    IBOutlet NSTextField *nameTextField;
    IBOutlet NSImageView *imageView;
    IBOutlet NSTableView *pubsTableView;
}

#pragma mark initialization
- (id)initWithPerson:(BibAuthor *)person document:(BibDocument *)doc;
- (void)awakeFromNib;

#pragma mark accessors
- (BibAuthor *)person;
- (void)setPerson:(BibAuthor *)newPerson;

#pragma mark actions
- (void)show;
- (void)_updateUI;
- (void)handlePubListChanged:(NSNotification *)notification;

#pragma mark table view datasource methods
// those methods are overridden in the implementation file

@end
