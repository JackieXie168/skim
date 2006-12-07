//  BDSKZoomImageView.m

//  Created by Michael McCracken on Mon Jul 22 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
    int		pagenumber = 0;
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
    NSRect	myBounds, newBounds;

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
