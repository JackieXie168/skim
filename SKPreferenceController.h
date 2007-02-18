//
//  SKPreferenceController.h
//  Skim
//
//  Created by Christiaan Hofman on 2/10/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SKPreferenceController : NSWindowController {
    IBOutlet NSSlider *thumbnailSizeSlider;
    IBOutlet NSSlider *snapshotSizeSlider;
}

+ (id)sharedPrefenceController;

- (IBAction)changeDiscreteThumbnailSizes:(id)sender;

@end
