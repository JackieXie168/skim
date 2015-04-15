//
//  SKDjvuView.m
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-06-11.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import "SKDjvuView.h"
#import "SKTextArea.h"
#import "TiledDjvuView.h"

@interface SKDjvuView()

// The TiledDjvuView that is currently front most.
@property (nonatomic, strong) TiledDjvuView *tiledDjvuView;

// The old TiledDjvuView that we draw on top of when the zooming stops.
@property (nonatomic, weak) TiledDjvuView *oldTiledDjvuView;

- (CGRect)computeFrameDimensions;

@end

@implementation SKDjvuView
{
    CGImageRef _djvuPage;
    CGSize _djvuScale;
}

@synthesize tiledDjvuView = _tiledDjvuView, oldTiledDjvuView = _oldTiledDjvuView;

- (id)initWithCoder:(NSCoder *)coder
{    
    self = [super initWithCoder:coder];
    if (self) {
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;
        
        wordsBoundingBoxes = [NSMutableArray array];
        selectedWordsBoundingBoxes = [NSMutableArray array];
        
        // Create the TiledDjvuView based on the size of the DJVU page and scale it to fit the view.
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        self.tiledDjvuView = [[TiledDjvuView alloc] initWithFrame:screenRect];
        [self addSubview:self.tiledDjvuView];
        
        // Install long-press gesture for text selection
        UILongPressGestureRecognizer *longPressGesture =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self addGestureRecognizer:longPressGesture];
        
        // Install a single-tap gesture to cancel current text selection
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        singleTap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleTap];
    }
    return self;
}

- (void)setDjvuPage:(CGImageRef)djvuPage withScale:(CGSize)scale
{
    CGImageRetain(djvuPage);
    CGImageRelease(_djvuPage);
    
    _djvuPage = djvuPage;
    _djvuScale = scale;
    
    [self.tiledDjvuView setPage:_djvuPage];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Center the image as it becomes smaller than the size of the screen.
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.tiledDjvuView.frame;
    
    // Center horizontally.
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // Center vertically.
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    self.tiledDjvuView.frame = frameToCenter;
    
    /*
     To handle the interaction between CATiledLayer and high resolution screens, set the tiling view's contentScaleFactor to 1.0.
     If this step were omitted, the content scale factor would be 2.0 on high resolution screens, which would cause the CATiledLayer to ask for tiles of the wrong scale.
     */
    self.tiledDjvuView.contentScaleFactor = 1.0;
}

- (void)dealloc
{
    // Clean up.
    CGImageRelease(_djvuPage);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)setTextBoundingRects:(NSMutableArray *)textAreas
{
    [wordsBoundingBoxes removeAllObjects];
    [wordsBoundingBoxes addObjectsFromArray:textAreas];    
}

- (void)drawTextBoundingRects
{
    SKDjvuTextLayer* textLayer = self.tiledDjvuView.textLayer;
    [textLayer drawBoundingRects:selectedWordsBoundingBoxes];
}

- (void)clearSelections
{
    [selectedWordsBoundingBoxes removeAllObjects];
    [self drawTextBoundingRects];
}


#pragma mark -
#pragma mark UIResponder

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)canPerformAction:(SEL)selector withSender:(id) sender
{
    if (selector == @selector(menuItemClicked:) || selector == @selector(copy:))
    {
        return YES;
    }
    return NO;
}

- (void)copy:(id)sender
{
    NSLog(@"Copy item has been tapped");
    SKTextArea* aTextArea = [selectedWordsBoundingBoxes objectAtIndex:0];
    NSLog(@"Text selected: %@", aTextArea.textContent);
}


#pragma mark -
#pragma mark Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint tapPoint = [touch locationInView:self];
    
    initialTapPoint = tapPoint;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint tapPoint = [touch locationInView:_tiledDjvuView];
    
    //NSLog(@"Touches Moved coordinates: (%f, %f)", tapPoint.x, tapPoint.y);
    
    currentTapPoint = tapPoint;    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint tapPoint = [touch locationInView:self];

//    NSLog(@"Touches Ended coordinates: (%f, %f)", tapPoint.x, tapPoint.y);
    
    selectionRect = CGRectMake(initialTapPoint.x, initialTapPoint.y,
                                      tapPoint.x - initialTapPoint.x, tapPoint.y - initialTapPoint.y);
    
    [self highlightAllWordsIn:selectionRect];
    //[self.tiledDjvuView.textLayer drawSelectionRect:selectionRect];
}


#pragma mark -
#pragma mark Gestures

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPressGesture
{
    if(longPressGesture.state == UIGestureRecognizerStateBegan)
    {
        CGPoint tapPoint = [longPressGesture locationInView:_tiledDjvuView];
        
        [self highlightSelectionAt:tapPoint];
    }
}

- (void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer
{
    [self clearSelections];
}


#pragma mark -
#pragma mark UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.tiledDjvuView;
}


#pragma mark -
#pragma mark private

- (CGRect)computeFrameDimensions
{
    // Calculate the new frame for the new TiledDjvuView.
    CGRect pageRect = CGRectMake(0, 0, CGImageGetWidth(_djvuPage), CGImageGetHeight(_djvuPage));
    pageRect.size = CGSizeMake(pageRect.size.width*_djvuScale.width, pageRect.size.height*_djvuScale.height);
    
    return pageRect;
}

- (void)highlightSelectionAt:(CGPoint)tapPoint
{
    // Determine which word can be found at tapped location
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
            
            [theMenu setTargetRect:drawRect inView:_tiledDjvuView];
            [theMenu setMenuVisible:YES animated:YES];
        }
        
        [self drawTextBoundingRects];
    }
}

- (void)highlightAllWordsIn:(CGRect)selRect
{
    BOOL hitWordFound = false;
    
    // Determine which word can be found at tapped location
    NSMutableArray* selectedAreas = [NSMutableArray array];
    for(int i = 0; i < wordsBoundingBoxes.count; i++)
    {
        SKTextArea* aTextArea = [wordsBoundingBoxes objectAtIndex:i];
        
        if(!hitWordFound)
        {
            if(CGRectIntersectsRect(aTextArea.boundingRect, selRect))
            {
                [selectedAreas addObject:aTextArea];
                hitWordFound = true;
            }
        }
        else
        {
            int lowerRightAreaY = aTextArea.boundingRect.origin.y + aTextArea.boundingRect.size.height;
            int lowerRightSelY = selRect.origin.y + selRect.size.height;
            
            if(lowerRightAreaY < lowerRightSelY)
            {
                [selectedAreas addObject:aTextArea];
            }
        }
    }
    
    // Draw text bounding boxes for selected word
    if(selectedAreas.count > 0)
    {
        [selectedWordsBoundingBoxes removeAllObjects];
        [selectedWordsBoundingBoxes addObjectsFromArray:selectedAreas];
        
        if([self becomeFirstResponder])
        {
            CGRect drawRect = CGRectMake(selRect.origin.x, selRect.origin.y, 2, 2);
            UIMenuController *theMenu = [UIMenuController sharedMenuController];
            
            [theMenu setTargetRect:drawRect inView:_tiledDjvuView];
            [theMenu setMenuVisible:YES animated:YES];
        }
        
        [self drawTextBoundingRects];
    }
}

@end
