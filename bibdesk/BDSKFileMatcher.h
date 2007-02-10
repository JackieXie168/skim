//
//  BDSKFileMatcher.h
//  Bibdesk
//
//  Created by Adam Maxwell on 02/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BDSKFileMatcher : NSWindowController
{
    IBOutlet NSOutlineView *outlineView;
    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet NSTextField *statusField;
    NSMutableArray *matches;
    SKIndexRef searchIndex;
}

+ (id)sharedInstance;
- (void)matchFiles:(NSArray *)absoluteURLs;
- (IBAction)openAction:(id)sender;

@end
