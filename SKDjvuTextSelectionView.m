//
//  SKDjvuTextSelectionView.m
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-06-14.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import "SKDjvuTextSelectionView.h"
#import "SKTextArea.h"

@implementation SKDjvuTextSelectionView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];

        wordsBoundingBoxes = [NSMutableArray array];
        selectedWordsBoundingBoxes = [NSMutableArray array];
        
        UILongPressGestureRecognizer *longPressGesture =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self addGestureRecognizer:longPressGesture];
    }
    return self;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Draw word bounding boxes at selected location
    if(selectedWordsBoundingBoxes.count > 0)
    {
        UIColor* selectionColor = [UIColor colorWithRed:0.8 green:0.87 blue:0.99 alpha:0.6];
        [selectionColor setFill];

        for(SKTextArea* aTextArea in selectedWordsBoundingBoxes)
        {
            UIBezierPath* selectionPath = [UIBezierPath bezierPathWithRect:aTextArea.boundingRect];
            [selectionPath fill];
        }
    }
}

- (void)drawTextBoundingRects:(NSMutableArray *)textAreas
{
    [wordsBoundingBoxes removeAllObjects];
    [wordsBoundingBoxes addObjectsFromArray:textAreas];
    
    // TODO: Test code to remove!!
    [selectedWordsBoundingBoxes removeAllObjects];
    [selectedWordsBoundingBoxes addObjectsFromArray:wordsBoundingBoxes];
    [self setNeedsDisplay];

//    NSLog(@"Word areas count: %u", wordsBoundingBoxes.count);
}

- (void)clearSelections
{
//    [selectedWordsBoundingBoxes removeAllObjects];
//    [self setNeedsDisplay];
}


#pragma mark -
#pragma mark Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    selectionBegin = [touch locationInView:self];
    selectionEnd = selectionBegin;

//    NSLog(@"Touches Began coordinates: (%f, %f)", selectionBegin.x, selectionBegin.y);    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    selectionEnd = [touch locationInView:self];

//    NSLog(@"Touches Moved coordinates: (%f, %f)", selectionEnd.x, selectionEnd.y);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *theTouch = [touches anyObject];
    
//    NSLog(@"Touches Ended coordinates: (%f, %f)", theTouch.x, theTouch.y);
    
    // If this is a single tap, and the menu is visible, hide it.
	UIMenuController *menuController = [UIMenuController sharedMenuController];
	if([theTouch tapCount] == 1 && [menuController isMenuVisible])
    {
		[menuController setMenuVisible:NO animated:YES];
        [selectedWordsBoundingBoxes removeAllObjects];
        [self setNeedsDisplay];
	}
}


#pragma mark -
#pragma mark Long Press Gesture

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPressGesture
{
    if(longPressGesture.state == UIGestureRecognizerStateBegan)
    {
        CGPoint tapPoint = [longPressGesture locationInView:self];
        
        [self highlightSelectionAt:tapPoint];
        [self setNeedsDisplay];
    }
}


#pragma mark -
#pragma mark Private

- (void)highlightSelectionAt:(CGPoint)tapPoint
{
    // Determine which word is located at selected location
    NSMutableArray* selectedAreas = [NSMutableArray array];
    for(int i = 0; i < wordsBoundingBoxes.count; i++)
    {
        SKTextArea* aTextArea = [wordsBoundingBoxes objectAtIndex:i];
        if(CGRectContainsPoint(aTextArea.boundingRect, tapPoint))
        {
            [selectedAreas addObject:aTextArea];
        }
    }
    
    // Draw text bounding boxes for selected word
    if(selectedAreas.count > 0)
    {
        [selectedWordsBoundingBoxes removeAllObjects];
        [selectedWordsBoundingBoxes addObjectsFromArray:selectedAreas];
        
        if([self becomeFirstResponder])
        {
            CGRect drawRect = CGRectMake(tapPoint.x, tapPoint.y, 2, 2);
            UIMenuController *theMenu = [UIMenuController sharedMenuController];
                        
            [theMenu setTargetRect:drawRect inView:self];
            [theMenu setMenuVisible:YES animated:YES];
        }
        
        [self setNeedsDisplay];
    }
}


- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if(action == @selector(copy:))
    {
        return YES;
    }
    
    return NO;
}

/*
 These methods are declared by the UIResponderStandardEditActions informal protocol.
 */
- (void)copy:(id)sender
{
	
}

@end
