//
//  BDSKBibTeXImporter.h
//  bd2xtest
//
//  Created by Michael McCracken on 1/18/06.
//  Copyright 2006 Michael McCracken. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKImporters.h"

@class BDSKDragImageView;

@interface BDSKBibTeXImporter : NSObject <BDSKImporter> {
    IBOutlet NSView *view;
    IBOutlet BDSKDragImageView *imageView;
    NSString *fileName;
}

#pragma mark UI actions
- (IBAction)chooseFileName:(id)sender;

#pragma mark UI KVO stuff

- (NSImage *)fileIcon;

@end
