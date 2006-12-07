//
//  BDSKZoomImageView.h
//  Bibdesk
//
//  Created by Michael McCracken on Mon Jul 22 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface BDSKZoomImageView : NSImageView {
    double currentZoom;
    int currentPage;
    NSPDFImageRep *imageRep;
    double oldWidth;
    double oldHeight;
}
- (void)setImageRep:(NSImageRep *)rep;
- (void) setMagnification: (double)magSize;
@end
