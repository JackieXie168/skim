//
//  SKDjvuView.h
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-06-11.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TiledDjvuView;

@interface SKDjvuView : UIScrollView <UIScrollViewDelegate>
{
    // Bounding boxes for all words in the document
    NSMutableArray* wordsBoundingBoxes;
    
    // Bounding boxes for selected words only
    NSMutableArray* selectedWordsBoundingBoxes;
    
    // Where tap has been initiated
    CGPoint initialTapPoint;
    
    // Where finger currently is located
    CGPoint currentTapPoint;
    
    // Rectangle delimiting the current selection
    CGRect selectionRect;
}

- (void)setDjvuPage:(CGImageRef)DjvuPage withScale:(CGSize)scale;
- (void)setTextBoundingRects:(NSMutableArray *)textAreas;
- (void)drawTextBoundingRects;
- (void)clearSelections;

@end