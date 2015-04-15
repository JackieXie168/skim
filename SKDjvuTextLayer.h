//
//  SKDjvuTextLayer.h
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-07-03.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface SKDjvuTextLayer : CALayer
{
    // Bounding boxes for all words in the document
    NSMutableArray* wordsBoundingBoxes;
    
    CGRect selectionRectangle;
}

- (void)drawBoundingRects:(NSMutableArray *)textAreas;
- (void)drawSelectionRect:(CGRect)selectionRect;

@end