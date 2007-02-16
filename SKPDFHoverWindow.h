//
//  SKPDFHoverWindow.h
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SKPDFHoverWindow : NSPanel {
    NSImageView *imageView;
    PDFDestination *destination;
    NSViewAnimation *animation;
}

+ (id)sharedHoverWindow;

- (void)showWithDestination:(PDFDestination *)dest atPoint:(NSPoint)point fromView:(PDFView *)srcView;
- (void)hide;

@end
