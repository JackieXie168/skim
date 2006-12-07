//
//  ImageBackgroundBox.h
//  bd2xtest
//
//  Created by Michael McCracken on 7/26/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ImageBackgroundBox : NSBox {
    NSImage *backgroundImage;
}

- (NSImage *)backgroundImage;
- (void)setBackgroundImage:(NSImage *)image;

@end
