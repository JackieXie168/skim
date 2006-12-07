//
//  BDSKZoomImageView.m
//  Bibdesk
//
//  Created by Michael McCracken on Mon Jul 22 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "BDSKZoomImageView.h"


@implementation BDSKZoomImageView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        currentZoom = 1.0;
        currentPage = 0;
    }
    return self;
}

- (void)setImageRep:(NSImageRep *)rep{
    int		pagenumber;
    NSRect	myBounds, newBounds;

    BOOL	modifiedRep = NO;
    double	newWidth, newHeight;

    NSScrollView *enclosingScrollView = [self enclosingScrollView];
    NSView *documentView = [enclosingScrollView documentView];
    

    if(rep != imageRep){
        [imageRep release];
        imageRep = [rep retain];

        myBounds = [imageRep bounds];
        newWidth = myBounds.size.width;
        newHeight = myBounds.size.height;

        if (pagenumber < 1) pagenumber = 1;
        if (pagenumber > [imageRep pageCount]) pagenumber = [imageRep pageCount];
        [imageRep setCurrentPage: (pagenumber - 1)];
        if (! modifiedRep) {
            myBounds = [imageRep bounds];
            oldWidth = myBounds.size.width;
            oldHeight = myBounds.size.height;
            newBounds.size.width = myBounds.size.width * (currentZoom);
            newBounds.size.height = myBounds.size.height * (currentZoom);
            [documentView setFrame: newBounds];
            [documentView setBounds: myBounds];
            // [self setMagnification: theMagSize];
        }
        else if ((abs(newHeight - oldHeight) > 1) || (abs(newWidth - oldWidth) > 1)) {
            oldWidth = newWidth;
            oldHeight = newHeight;
            newBounds.size.width = myBounds.size.width * (currentZoom);
            newBounds.size.height = myBounds.size.height * (currentZoom);
            [documentView setFrame: newBounds];
            [documentView setBounds: myBounds];
            [self setMagnification: currentZoom];
        }
    }
}

- (void)drawRect:(NSRect)rect {
    NSEraseRect([self bounds]);
    [imageRep draw];
}

- (void)mouseDown:(NSEvent *)theEvent{
    NSLog(@"mouseDown curpg = %d", currentPage);
    if ([theEvent modifierFlags] & NSAlternateKeyMask) {
        if (currentPage > 0) currentPage -= 1;
    }else{
        if(currentPage < [imageRep pageCount]) currentPage += 1;
    }
    [imageRep setCurrentPage:currentPage];
    [imageRep setSize:NSMakeSize([imageRep size].width + 15.0, [imageRep size].height + 15.0 )];
}

- (void) setMagnification: (double)magSize
{
    double	mag;
    NSRect	myBounds, newBounds;
    double	tempRotationAmount;

    NSScrollView *enclosingScrollView = [self enclosingScrollView];
    NSView *documentView = [enclosingScrollView documentView];

    myBounds = [self bounds];
    newBounds.size.width = myBounds.size.width * (magSize);
    newBounds.size.height = myBounds.size.height * (magSize);
    [documentView setFrame: newBounds];
    [documentView setBounds: myBounds];

    [[self superview] setNeedsDisplay:YES];
    [[self enclosingScrollView] setNeedsDisplay:YES];
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent{

    NSLog(@"event is %@", theEvent);
}


@end
