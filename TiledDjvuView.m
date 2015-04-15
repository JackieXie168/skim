//
//  TiledDjvuView.m
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-06-12.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import "TiledDjvuView.h"
#import "SKDjvuTextLayer.h"
#import <QuartzCore/QuartzCore.h>

@implementation TiledDjvuView
{
    CGImageRef djvuPage;
}

@synthesize textLayer = _textLayer, scale = _scale;

// Create a new TiledDjvuView with the desired frame and scale.
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
        /*
         levelsOfDetail and levelsOfDetailBias determine how the layer is rendered at different zoom levels. This only matters while the view is zooming, because once the the view is done zooming a new TiledDjvuView is created at the correct size and scale.
         */
        tiledLayer.levelsOfDetail = 4;
        tiledLayer.levelsOfDetailBias = 3;
        tiledLayer.tileSize = CGSizeMake(512.0, 512.0);
        
        // Create a layer to display text selection
        _textLayer = [SKDjvuTextLayer layer];
        _textLayer.frame = [[UIScreen mainScreen] bounds];

        [tiledLayer insertSublayer:_textLayer above:tiledLayer];
        
        self.scale = 1.0;        
    }
    return self;
}

// The layer's class should be CATiledLayer.
+ (Class)layerClass
{
    return [CATiledLayer class];
}

// Set the CGImageRef for the view.
- (void)setPage:(CGImageRef)newPage
{
    CGImageRelease(self->djvuPage);
    self->djvuPage = CGImageRetain(newPage);
    
    [self setNeedsDisplay];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

// Draw the CGPDFPageRef into the layer at the correct scale.
-(void)drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
    // Fill the background with white.
    CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
    CGContextFillRect(context, self.bounds);
    
    CGContextSaveGState(context);
    
    // Flip the context so that the page is rendered right side up.
    CGContextTranslateCTM(context, 0.0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    // Draw image on layer
    CGContextDrawImage(context, self.bounds, djvuPage);
    
    CGContextRestoreGState(context);
}

// Clean up.
- (void)dealloc
{
    CGImageRelease(djvuPage);
}

@end
