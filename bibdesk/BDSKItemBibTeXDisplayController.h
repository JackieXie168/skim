//
//  BDSKItemBibTeXDisplayController.h
//  Bibdesk
//
//  Created by Michael McCracken on 2/11/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKItemDisplayController.h"
#import "BibItem.h"

@interface BDSKItemBibTeXDisplayController : NSObject <BDSKItemDisplayController> {
	IBOutlet NSView *enclosingView;
	IBOutlet NSTextView *textView;
	id itemSource;
}

- (void)setItemSource:(id)source;
- (id)itemSource;

- (void)registerForNotifications;

- (void)handleSelectedItemsChangedNotification:(NSNotification *)notification;

- (void)updateUI;
@end
