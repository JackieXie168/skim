//
//  ReferenceController.h
//  CocoaMed
//
//  Created by kmarek on Sun Mar 31 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <reference.h>

@interface ReferenceController : NSWindowController {
    IBOutlet NSTextField *referenceTitle;
    IBOutlet NSTextField *referenceAuthors;
    IBOutlet NSTextField *referenceAbstract;
    IBOutlet NSTextField *referenceJournal;
    
    reference *currentReference;
}
-(id)initWithReference:(reference *)referenceToShow;
-(IBAction) nextReference;
-(IBAction) prevReference;
-(IBAction) openReferenceButtonClicked:(id)sender;
-(reference *)currentReference;
-(void)setCurrentReference:(reference *)aReference;
-(void)openReferenceInBrowser;

@end
