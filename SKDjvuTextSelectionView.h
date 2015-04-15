//
//  SKDjvuTextSelectionView.h
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-06-14.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SKDjvuTextSelectionView : UIView
{
    // Bounding boxes for all words in the document
    NSMutableArray* wordsBoundingBoxes;
    
    // Bounding boxes for selected words only
    NSMutableArray* selectedWordsBoundingBoxes;

    // Current selection on top view
    CGPoint selectionBegin;
    CGPoint selectionEnd;
}

-(void)drawTextBoundingRects:(NSMutableArray*)textAreas;
-(void)clearSelections;

@end