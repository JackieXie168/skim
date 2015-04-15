//
//  SKDjvuTextLayer.m
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-07-03.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import "SKDjvuTextLayer.h"
#import "SKTextArea.h"

@implementation SKDjvuTextLayer

-(id)init
{
    self = [super init];
    if(self)
    {
        wordsBoundingBoxes = [NSMutableArray array];
    }
    return self;
}

- (void)drawInContext:(CGContextRef)context
{
    UIGraphicsPushContext(context);
    
    // Draw word bounding boxes at selected location
    if(wordsBoundingBoxes.count > 0)
    {
        UIColor* selectionColor = [UIColor colorWithRed:0.8 green:0.87 blue:0.99 alpha:0.6];
        [selectionColor setFill];
        
        for(SKTextArea* aTextArea in wordsBoundingBoxes)
        {
            CGRect aRect = aTextArea.boundingRect;
            UIBezierPath* selectionPath = [UIBezierPath bezierPathWithRect:aRect];
            [selectionPath fill];
        }
        
        SKTextArea* firstArea = [wordsBoundingBoxes objectAtIndex:0];
        CGRect firstAreaRect = firstArea.boundingRect;
        SKTextArea* lastArea = [wordsBoundingBoxes lastObject];
        CGRect lastAreaRect = lastArea.boundingRect;
        
        // Draw delimiting lines at each end
        CGContextSaveGState(context);
        CGContextSetLineWidth(context, 1);
        CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
        CGContextMoveToPoint(context, firstAreaRect.origin.x, firstAreaRect.origin.y);
        CGContextAddLineToPoint(context, firstAreaRect.origin.x, firstAreaRect.origin.y + firstAreaRect.size.height);
        CGContextMoveToPoint(context, lastAreaRect.origin.x + lastAreaRect.size.width, lastAreaRect.origin.y);
        CGContextAddLineToPoint(context, lastAreaRect.origin.x + lastAreaRect.size.width, lastAreaRect.origin.y + lastAreaRect.size.height);
        CGContextStrokePath(context);
        CGContextRestoreGState(context);
        
        // Draw lollipop grab-point circles
        [self drawCircleAt:CGPointMake(firstAreaRect.origin.x, firstAreaRect.origin.y - 5.0) inContext:context];
        [self drawCircleAt:CGPointMake(lastAreaRect.origin.x + lastAreaRect.size.width, lastAreaRect.origin.y + lastAreaRect.size.height + 5.0) inContext:context];
    }
    
    UIGraphicsPopContext();
}

- (void)drawCircleAt:(CGPoint)location inContext:(CGContextRef)context
{
    CGContextSaveGState(context);
    
    CGSize circleSize = CGSizeMake(10, 10);
        
    // Create an underlying circle to be able to attach a shadow and a contour
    CGContextSetLineWidth(context, 4.0);
    CGContextSetStrokeColorWithColor(context,[UIColor whiteColor].CGColor);
    
    UIColor *theFillColor = [UIColor blueColor];
    CGContextSetFillColor(context, CGColorGetComponents(theFillColor.CGColor));
    CGContextSetShadow(context, CGSizeMake(0.0f, 2.5f), 5.0f);
    
    CGRect rectangle = CGRectMake(location.x - circleSize.width/2, location.y - circleSize.height/2,
                                  circleSize.width, circleSize.height);
    
    CGContextAddEllipseInRect(context, rectangle);
    CGContextStrokePath(context);
    CGContextFillEllipseInRect(context, rectangle);
    
    CGContextRestoreGState(context);
}

- (void)drawGrabPointAt:(CGPoint)location inContext:(CGContextRef)context
{
    CGSize circleSize = CGSizeMake(10, 10);
    
    UIGraphicsPushContext(context);
    
    // Create an underlying circle to be able to attach a shadow and a contour
    CGContextSetLineWidth(context, 4.0);
    CGContextSetStrokeColorWithColor(context,[UIColor whiteColor].CGColor);
    
    UIColor *theFillColor = [UIColor blueColor];
    CGContextSetFillColor(context, CGColorGetComponents(theFillColor.CGColor));
    CGContextSetShadow(context, CGSizeMake(5.0f, 5.0f), 10.0f);
    
    CGRect rectangle = CGRectMake(location.x - circleSize.width/2, location.y - circleSize.height/2,
                                  circleSize.width, circleSize.height);
    
    CGContextAddEllipseInRect(context, rectangle);
    CGContextStrokePath(context);
    CGContextFillEllipseInRect(context, rectangle);
        
    // Superpose a second circle with a gradient over the first circle
    CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    
    CGFloat *kBlue = (CGFloat *)CGColorGetComponents(theFillColor.CGColor);
    CGFloat components[8] = { kBlue[0], kBlue[1], kBlue[2], 1.0, 0.0, 0.0, 0.0, 1.0 };
    
    CGGradientRef gradient = CGGradientCreateWithColorComponents(myColorspace, components,
                                                                 locations, num_locations);
    
    CGPoint startPoint = CGPointMake(location.x, location.y - circleSize.height/2);
    CGPoint endPoint = CGPointMake(location.x, location.y + circleSize.height/2);
    
    CGContextBeginPath(context);
    CGContextAddArc(context, location.x, location.y, circleSize.width/2, 0, 6.28318531, 0);
    CGContextClosePath(context);
    
    CGContextClip(context);
    CGContextFillPath(context);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    
    UIGraphicsPopContext();
}

- (void)drawBoundingRects:(NSMutableArray *)textAreas
{
    [wordsBoundingBoxes removeAllObjects];
    [wordsBoundingBoxes addObjectsFromArray:textAreas];
    
    [self setNeedsDisplay];
    
    //    NSLog(@"Word areas count: %u", wordsBoundingBoxes.count);
}

- (void)drawSelectionRect:(CGRect)selectionRect
{
    selectionRectangle = selectionRect;
    
    [self setNeedsDisplay];
}

@end