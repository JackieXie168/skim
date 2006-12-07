// Copyright 2000-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSBezierPath-OAExtensions.h"

#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSBezierPath-OAExtensions.m 78619 2006-08-24 00:54:02Z wiml $")


@interface NSBezierPath (PrivateOAExtensions)

struct intersectionInfo {
    double leftParameter, rightParameter;
    double leftParameterDistance, rightParameterDistance;
};

NSString *_roundedStringForPoint(NSPoint point);
static NSRect _parameterizedCurveBounds(const NSPoint *curve);
// wants 4 coefficients and 3 roots
// returns the number of solutions
static int _solveCubic(double *c, double *roots);
static void _parameterizeLine(NSPoint *coefficients, NSPoint startPoint, NSPoint endPoint);
static void _parameterizeCurve(NSPoint *coefficients, NSPoint startPoint, NSPoint endPoint, NSPoint controlPoint1, NSPoint controlPoint2);
static int intersectionsBetweenCurveAndLine(const NSPoint *c, const NSPoint *a, struct intersectionInfo *results);

- (BOOL)_curvedIntersection:(float *)length time:(float *)time curve:(NSPoint *)c line:(NSPoint *)a;

static BOOL _straightLineIntersectsRect(const NSPoint *a, NSRect rect);
static void _splitCurve(const NSPoint *c, NSPoint *left, NSPoint *right); 
static BOOL _curvedLineIntersectsRect(const NSPoint *c, NSRect rect, float tolerance);

- (BOOL)_curvedLineHit:(NSPoint)point startPoint:(NSPoint)startPoint endPoint:(NSPoint)endPoint controlPoint1:(NSPoint)controlPoint1 controlPoint2:(NSPoint)controlPoint2 position:(float *)position padding:(float)padding;
- (BOOL)_straightLineIntersection:(float *)length time:(float *)time segment:(NSPoint *)s line:(NSPoint *)l;
- (BOOL)_straightLineHit:(NSPoint)startPoint :(NSPoint)endPoint :(NSPoint)point  :(float *)position padding:(float)padding;
- (int)_segmentHitByPoint:(NSPoint)point position:(float *)position padding:(float)padding;
- (NSPoint)_endPointForSegment:(int)i;

@end

//

struct pointInfo {
    NSPoint pt;
    double tangentX, tangentY;
};

// Returns a point offset to the left (in an increasing-Y-upwards coordinate system, if up==NO) or towards increasing Y (if up==YES)
static NSPoint offsetPoint(struct pointInfo pi, float offset, BOOL up)
{
    double length = hypot(pi.tangentX, pi.tangentY);
    if (length < 1e-15)
        return pi.pt;  // sigh
    
    if (up && pi.tangentX < 0) {
        pi.tangentX = -pi.tangentX;
        pi.tangentY = -pi.tangentY;
    }
    
    return (NSPoint){
        .x = pi.pt.x - pi.tangentY * offset / length,
        .y = pi.pt.y + pi.tangentX * offset / length
    };
}

static struct pointInfo getCurvePoint(const NSPoint *c, float u) {
    // Coefficients c[4]
    // Position u
    struct pointInfo i;
    i.pt.x = c[0].x + u * (c[1].x + u * (c[2].x + u * c[3].x));
    i.pt.y = c[0].y + u * (c[1].y + u * (c[2].y + u * c[3].y));
    i.tangentX = c[1].x + u * (2.0 * c[2].x  + u * 3.0 * c[3].x);
    i.tangentY = c[1].y + u * (2.0 * c[2].y  + u * 3.0 * c[3].y);
    return i;
}

static struct pointInfo getLinePoint(const NSPoint *a, float position) {
    // Coefficients a[2] (not endpoints!)
    return (struct pointInfo){
        .pt = {a[0].x + position * a[1].x, a[0].y + position * a[1].y},
        .tangentX = a[1].x,
        .tangentY = a[1].y
    };
}

@implementation NSBezierPath (OAExtensions)

- (BOOL)strokesSimilarlyIgnoringEndcapsToPath:(NSBezierPath *)otherPath;
{
    return [[self countedSetOfEncodedStrokeSegments] isEqual:[otherPath countedSetOfEncodedStrokeSegments]];
}

- (NSCountedSet *)countedSetOfEncodedStrokeSegments;
{
    NSPoint unlikelyPoint = {-10275847.33894, -10275847.33894};
    NSPoint firstPoint = unlikelyPoint, currentPoint = NSZeroPoint;

    NSCountedSet *countedSetOfEncodedStrokeSegments = [NSCountedSet set];
    int elementIndex, elementCount = [self elementCount];
    for(elementIndex=0; elementIndex<elementCount; elementIndex++) {
        NSPoint points[3];
        NSBezierPathElement element = [self elementAtIndex:elementIndex associatedPoints:points];
        NSString *currentSegmentString = nil;

        switch(element) {
            case NSMoveToBezierPathElement:
                currentPoint = points[0];
                if (NSEqualPoints(firstPoint, unlikelyPoint))
                    firstPoint = currentPoint;
                break;
            case NSClosePathBezierPathElement:
            case NSLineToBezierPathElement: {
                NSString *firstPointString, *lastPointString;

                NSPoint lineToPoint;
                if (element == NSClosePathBezierPathElement)
                    lineToPoint = firstPoint;
                else
                    lineToPoint = points[0];

                if (NSEqualPoints(currentPoint, lineToPoint))
                    break;
                firstPointString = _roundedStringForPoint(currentPoint);
                lastPointString = _roundedStringForPoint(lineToPoint);
                if ([firstPointString compare:lastPointString] == NSOrderedDescending)
                    SWAP(firstPointString, lastPointString);
                currentSegmentString = [NSString stringWithFormat:@"%@%@", firstPointString, lastPointString];
                currentPoint = lineToPoint;
                break;
            }
            case NSCurveToBezierPathElement: {
                NSString *firstPointString, *lastPointString;
                NSString *controlPoint1String, *controlPoint2String;
                NSComparisonResult comparisonResult;

                firstPointString = _roundedStringForPoint(currentPoint);
                controlPoint1String = _roundedStringForPoint(points[0]);
                controlPoint2String = _roundedStringForPoint(points[1]);
                lastPointString = _roundedStringForPoint(points[2]);
                comparisonResult = [firstPointString compare:lastPointString];
                if (comparisonResult == NSOrderedDescending || (comparisonResult == NSOrderedSame && [controlPoint1String compare:controlPoint2String] == NSOrderedDescending)) {
                    SWAP(firstPointString, lastPointString);
                    SWAP(controlPoint1String, controlPoint2String);
                }
                [countedSetOfEncodedStrokeSegments addObject:[NSString stringWithFormat:@"%@%@%@%@", firstPointString, controlPoint1String, controlPoint2String, lastPointString]];
                currentPoint = points[2];
                break;
            }
        }
        if (currentSegmentString != nil)
            [countedSetOfEncodedStrokeSegments addObject:currentSegmentString];
    }

    return countedSetOfEncodedStrokeSegments;
}


//

- (BOOL)intersectsRect:(NSRect)rect
{
    int count = [self elementCount];
    int i;
    NSPoint points[3];
    NSPoint startPoint;
    NSPoint currentPoint;
    NSPoint line[2];
    NSPoint curve[4];
    int element;
    BOOL needANewStartPoint;

    if (count == 0)
        return NO;

    element = [self elementAtIndex:0 associatedPoints:points];
    if (element != NSMoveToBezierPathElement) {
        return NO;  // must start with a moveTo
    }

    startPoint = currentPoint = points[0];
    needANewStartPoint = NO;
    
    for(i=1;i<count;i++) {
        element = [self elementAtIndex:i associatedPoints:points];
        switch(element) {
            case NSMoveToBezierPathElement:
                currentPoint = points[0];
                if (needANewStartPoint) {
                    startPoint = currentPoint;
                    needANewStartPoint = NO;
                }
                break;
            case NSClosePathBezierPathElement:
                _parameterizeLine(line, currentPoint,startPoint);
                if (_straightLineIntersectsRect(line, rect)) {
                    return YES;
                }
                currentPoint = startPoint;
                needANewStartPoint = YES;
                break;
            case NSLineToBezierPathElement:
                _parameterizeLine(line, currentPoint,points[0]);
                if (_straightLineIntersectsRect(line, rect)){
                    return YES;
                }
                currentPoint = points[0];
                break;
            case NSCurveToBezierPathElement: {
                _parameterizeCurve(curve, currentPoint, points[2], points[0], points[1]);
                if (_curvedLineIntersectsRect(curve, rect, [self lineWidth]+1)) {
                    return YES;
                }
                currentPoint = points[2];
                break;
            }
        }
    }

    return NO;
}

- (BOOL)intersectionWithLine:(NSPoint *)result lineStart:(NSPoint)lineStart lineEnd:(NSPoint)lineEnd
{
    NSPoint curveCoefficients[4];
    NSPoint points[3];
    NSPoint segmentCoefficients[2];
    NSPoint lineCoefficients[2];
    NSPoint startPoint;
    NSPoint currentPoint;
    float minimumLength = 1.0;
    int element;
    int count = [self elementCount];
    int i;
    BOOL needANewStartPoint;

    if (count == 0)
        return NO;
        
    element = [self elementAtIndex:0 associatedPoints:points];

    if (element != NSMoveToBezierPathElement) 
        return NO;  // must start with a moveTo

    _parameterizeLine(lineCoefficients,lineStart,lineEnd);
    
    startPoint = currentPoint = points[0];
    needANewStartPoint = NO;
    
    for(i=1;i<count;i++) {
        float ignored, currentLength = 1.0;

        element = [self elementAtIndex:i associatedPoints:points];
        switch(element) {
            case NSMoveToBezierPathElement:
                currentPoint = points[0];
                if (needANewStartPoint) {
                    startPoint = currentPoint;
                    needANewStartPoint = NO;
                }
                break;
            case NSClosePathBezierPathElement:
                _parameterizeLine(segmentCoefficients,currentPoint,startPoint);
                if ([self _straightLineIntersection:&currentLength time:&ignored segment:segmentCoefficients line:lineCoefficients]) {
                    if (currentLength < minimumLength) {
                        minimumLength = currentLength;
                    }
                }
                currentPoint = startPoint;
                needANewStartPoint = YES;
                break;
            case NSLineToBezierPathElement:
                _parameterizeLine(segmentCoefficients, currentPoint, points[0]);
                if ([self _straightLineIntersection:&currentLength time:&ignored segment:segmentCoefficients line:lineCoefficients]) {
                    if (currentLength < minimumLength) {
                        minimumLength = currentLength;
                    }
                }
                currentPoint = points[0];
                break;
            case NSCurveToBezierPathElement:
                _parameterizeCurve(curveCoefficients, currentPoint, points[2], points[0], points[1]);
                if ([self _curvedIntersection:&currentLength time:&ignored curve:curveCoefficients line:lineCoefficients]) {
                    if (currentLength < minimumLength) {
                        minimumLength = currentLength;
                    }
                }
                currentPoint = points[2];
                break;
        }
    }

    if (minimumLength < 1.0) {
        result->x = lineCoefficients[0].x + minimumLength * lineCoefficients[1].x;
        result->y = lineCoefficients[0].y + minimumLength * lineCoefficients[1].y;
        return YES;
    }
    return NO;
}

- (void)addIntersectionsWithLineStart:(NSPoint)lineStart lineEnd:(NSPoint)lineEnd toArray:(NSMutableArray *)array;
{
    NSPoint points[3];
    NSPoint segmentCoefficients[2];
    NSPoint curveCoefficients[4];
    NSPoint lineCoefficients[2];
    NSPoint startPoint;
    NSPoint currentPoint;
    int element;
    int count = [self elementCount];
    int i;
    BOOL needANewStartPoint;
    float ignored, time;
    float positionPerSegment = 1.0 / (float)(count - 1);
    
    if (count == 0)
        return;
        
    element = [self elementAtIndex:0 associatedPoints:points];

    if (element != NSMoveToBezierPathElement)
        return;  // must start with a moveTo

    _parameterizeLine(lineCoefficients,lineStart,lineEnd);
    
    startPoint = currentPoint = points[0];
    needANewStartPoint = NO;
    
    for(i=1;i<count;i++) {
        element = [self elementAtIndex:i associatedPoints:points];
        switch(element) {
            case NSMoveToBezierPathElement:
                currentPoint = points[0];
                if (needANewStartPoint) {
                    startPoint = currentPoint;
                    needANewStartPoint = NO;
                }
                break;
            case NSClosePathBezierPathElement:
                _parameterizeLine(segmentCoefficients,currentPoint,startPoint);
                if ([self _straightLineIntersection:&ignored time:&time segment:segmentCoefficients line:lineCoefficients]) {
                    float position = positionPerSegment * ((float)i - 1 + time);
                    if (position >= 0.0 && position <= 1.0)
                        [array addObject:[NSNumber numberWithFloat:position]];
                }
                currentPoint = startPoint;
                needANewStartPoint = YES;
                break;
            case NSLineToBezierPathElement:
                _parameterizeLine(segmentCoefficients, currentPoint, points[0]);
                if ([self _straightLineIntersection:&ignored time:&time segment:segmentCoefficients line:lineCoefficients]) {
                    float position = positionPerSegment * ((float)i - 1 + time);
                    if (position >= 0.0 && position <= 1.0)
                        [array addObject:[NSNumber numberWithFloat:position]];
                }
                currentPoint = points[0];
                break;
            case NSCurveToBezierPathElement:
                _parameterizeCurve(curveCoefficients, currentPoint, points[2], points[0], points[1]);
                if ([self _curvedIntersection:&ignored time:&time curve:curveCoefficients line:lineCoefficients]) {
                    float position = positionPerSegment * ((float)i - 1 + time);
                    if (position >= 0.0 && position <= 1.0)
                        [array addObject:[NSNumber numberWithFloat:position]];
                }
                currentPoint = points[2];
                break;
        }
    }
}

void splitBezierCurveTo(const NSPoint *c, float t, NSPoint *l, NSPoint *r)
{
    NSPoint mid;
    float oneMinusT = 1.0 - t;
    
    l[0] = c[0];
    r[3] = c[3];
    l[1].x = c[0].x * oneMinusT + c[1].x * t;
    l[1].y = c[0].y * oneMinusT + c[1].y * t;
    r[2].x = c[2].x * oneMinusT + c[3].x * t;
    r[2].y = c[2].y * oneMinusT + c[3].y * t;
    mid.x = c[1].x * oneMinusT + c[2].x * t;
    mid.y = c[1].y * oneMinusT + c[2].y * t;
    l[2].x = l[1].x * oneMinusT + mid.x * t;
    l[2].y = l[1].y * oneMinusT + mid.y * t;
    r[1].x = mid.x * oneMinusT + r[2].x * t;
    r[1].y = mid.y * oneMinusT + r[2].y * t;
    l[3].x = l[2].x * oneMinusT + r[1].x * t;
    l[3].y = l[2].y * oneMinusT + r[1].y * t;
    r[0] = l[3];
}

NSRect _bezierCurveToBounds(const NSPoint *c)
{
    NSPoint low, high;
    
    low.x = MIN(MIN(c[0].x, c[1].x), MIN(c[2].x, c[3].x));
    low.y = MIN(MIN(c[0].y, c[1].y), MIN(c[2].y, c[3].y));
    high.x = MAX(MAX(c[0].x, c[1].x), MAX(c[2].x, c[3].x));
    high.y = MAX(MAX(c[0].y, c[1].y), MAX(c[2].y, c[3].y));
    
    return NSMakeRect(low.x, low.y, high.x - low.x, high.y - low.y);
}

- (void)_addCurveToCurveIntersections:(NSMutableArray *)array onCurve:(const NSPoint *)c otherCurve:(const NSPoint *)o bezierLowPosition:(float)low bezierInterval:(float)interval cubicLowPosition:(float)cubicLow cubicInterval:(float)cubicInterval originalCubic:(const NSPoint *)originalCurve;
{
    float ignored, time;
    NSPoint lineCoefficients[2];
    NSPoint curveCoefficients[4];

    if (!NSIntersectsRect(_bezierCurveToBounds(c), _bezierCurveToBounds(o)))
        return;
    if ([self _straightLineHit:o[0] :o[3] :o[1] :&ignored padding:1.0] && [self _straightLineHit:o[0] :o[3] :o[2] :&ignored padding:1.0]) {
        // other is close enough to being a line
        _parameterizeLine(lineCoefficients, o[0], o[3]);
        _parameterizeCurve(curveCoefficients, c[0], c[3], c[1], c[2]);
        if ([self _curvedIntersection:&ignored time:&time curve:curveCoefficients line:lineCoefficients]) {
            float position = low + time * interval;
            if (position >= 0.0 && position <= 1.0)
                [array addObject:[NSNumber numberWithFloat:position]];
        }
    } else {
        NSPoint cl[4], cr[4], ol[4], or[4];
        
        splitBezierCurveTo(c, 0.5, cl, cr);
        splitBezierCurveTo(o, 0.5, ol, or);
        interval /= 2.0;
        [self _addCurveToCurveIntersections:array onCurve:cl otherCurve:ol bezierLowPosition:low bezierInterval:interval cubicLowPosition:cubicLow cubicInterval:cubicInterval originalCubic:originalCurve];
        [self _addCurveToCurveIntersections:array onCurve:cl otherCurve:or bezierLowPosition:low bezierInterval:interval cubicLowPosition:cubicLow cubicInterval:cubicInterval originalCubic:originalCurve];
        low += interval;
        [self _addCurveToCurveIntersections:array onCurve:cr otherCurve:ol bezierLowPosition:low bezierInterval:interval cubicLowPosition:cubicLow cubicInterval:cubicInterval originalCubic:originalCurve];
        [self _addCurveToCurveIntersections:array onCurve:cr otherCurve:or bezierLowPosition:low bezierInterval:interval cubicLowPosition:cubicLow cubicInterval:cubicInterval originalCubic:originalCurve];
    }    
}

- (void)addIntersectionsWithCurveTo:(const NSPoint *)curve toArray:(NSMutableArray *)array;
{
    NSPoint points[3];
    NSPoint segmentCoefficients[2];
    NSPoint curveCoefficients[4];
    NSPoint startPoint;
    NSPoint currentPoint;
    NSPoint intersectionPoint;
    int element;
    int count = [self elementCount];
    int i;
    BOOL needANewStartPoint;
    float ignored, time;
    float positionPerSegment = 1.0 / (float)(count - 1);
    
    if (count == 0)
        return;
        
    element = [self elementAtIndex:0 associatedPoints:points];

    if (element != NSMoveToBezierPathElement)
        return;  // must start with a moveTo

    startPoint = currentPoint = points[0];
    needANewStartPoint = NO;
    _parameterizeCurve(curveCoefficients, curve[0], curve[3], curve[1], curve[2]);
    
    for(i=1;i<count;i++) {
        element = [self elementAtIndex:i associatedPoints:points];
        switch(element) {
            case NSMoveToBezierPathElement:
                currentPoint = points[0];
                if (needANewStartPoint) {
                    startPoint = currentPoint;
                    needANewStartPoint = NO;
                }
                break;
            case NSClosePathBezierPathElement:
                _parameterizeLine(segmentCoefficients,currentPoint,startPoint);
                if ([self _curvedIntersection:&ignored time:&time curve:curveCoefficients line:segmentCoefficients]) {
                    intersectionPoint = getCurvePoint(curveCoefficients, time).pt;
                    if ([self _straightLineHit:currentPoint :startPoint :intersectionPoint :&time padding:1.0]) {
                        float position = positionPerSegment * ((float)i - 1 + time);
                        if (position >= 0.0 && position <= 1.0)
                            [array addObject:[NSNumber numberWithFloat:position]];
                    }
                }
                currentPoint = startPoint;
                needANewStartPoint = YES;
                break;
            case NSLineToBezierPathElement:
                _parameterizeLine(segmentCoefficients, currentPoint, points[0]);
                if ([self _curvedIntersection:&ignored time:&time curve:curveCoefficients line:segmentCoefficients]) {
                    intersectionPoint = getCurvePoint(curveCoefficients, time).pt;
                    if ([self _straightLineHit:currentPoint :points[0] :intersectionPoint :&time padding:1.0]) {
                        float position = positionPerSegment * ((float)i - 1 + time);
                        if (position >= 0.0 && position <= 1.0)
                            [array addObject:[NSNumber numberWithFloat:position]];
                    }
                }
                currentPoint = points[0];
                break;
            case NSCurveToBezierPathElement: {
                NSPoint thisCurve[4];
                float lowPosition = positionPerSegment * ((float)i - 1);
                thisCurve[0] = currentPoint;
                thisCurve[1] = points[0];
                thisCurve[2] = points[1];
                thisCurve[3] = points[2];
                [self _addCurveToCurveIntersections:array onCurve:thisCurve otherCurve:curve bezierLowPosition:lowPosition bezierInterval:positionPerSegment cubicLowPosition:lowPosition cubicInterval:positionPerSegment originalCubic:thisCurve];
                currentPoint = points[2];
                break;
            }
        }
    }
}

- (NSArray *)intersectionsWithPath:(NSBezierPath *)other;
{    
    NSMutableArray *array = [NSMutableArray array];
    NSPoint points[3];
    NSPoint startPoint;
    NSPoint currentPoint;
    int element;
    int count = [other elementCount];
    int i;
    BOOL needANewStartPoint;

    if (count == 0)
        return NO;

    element = [other elementAtIndex:0 associatedPoints:points];

    if (element != NSMoveToBezierPathElement) 
        return nil;  // must start with a moveTo

    startPoint = currentPoint = points[0];
    needANewStartPoint = NO;
    
    for(i=1;i<count;i++) {
        element = [other elementAtIndex:i associatedPoints:points];
        switch(element) {
            case NSMoveToBezierPathElement:
                currentPoint = points[0];
                if (needANewStartPoint) {
                    startPoint = currentPoint;
                    needANewStartPoint = NO;
                }
                    break;
            case NSClosePathBezierPathElement:
                [self addIntersectionsWithLineStart:currentPoint lineEnd:startPoint toArray:array];
                currentPoint = startPoint;
                needANewStartPoint = YES;
                break;
            case NSLineToBezierPathElement:
                [self addIntersectionsWithLineStart:currentPoint lineEnd:points[0] toArray:array];
                currentPoint = points[0];
                break;
            case NSCurveToBezierPathElement: {
                NSPoint curve[4];
                
                curve[0] = currentPoint;
                curve[1] = points[0];
                curve[2] = points[1];
                curve[3] = points[2];
                [self addIntersectionsWithCurveTo:curve toArray:array];
                currentPoint = points[2];
                break;
            }
        }
    }
    
    // sort and unique the results
    [array sortUsingSelector:@selector(compare:)];
    i = [array count] - 1;
    float last = [[array lastObject] floatValue];
    while (i-- > 0) {
        float this = [[array objectAtIndex:i] floatValue];
        if (ABS(this-last) < 0.005)
            [array removeObjectAtIndex:i];
        last = this;
    }
    if ([array count] >= 2 && [[array objectAtIndex:0] floatValue] < 0.0025 && [[array lastObject] floatValue] > 0.9975)
        [array removeLastObject];
    return array;
}

- (int)segmentHitByPoint:(NSPoint)point padding:(float)padding {
    float position = 0;
    return [self _segmentHitByPoint:point position:&position padding:padding];
}

- (int)segmentHitByPoint:(NSPoint)point  {
    float position = 0;
    return [self _segmentHitByPoint:point position:&position padding:5.0];
}

- (BOOL)isStrokeHitByPoint:(NSPoint)point padding:(float)padding
{
    int segment = [self segmentHitByPoint:point padding:padding];
    return (segment != 0);
}

- (BOOL)isStrokeHitByPoint:(NSPoint)point
{
    int segment = [self segmentHitByPoint:point padding:5.0];
    return (segment != 0);
}

//

// From Scott Anguish's Cocoa book, I believe.
- (void)appendBezierPathWithRoundedRectangle:(NSRect)aRect withRadius:(float)radius;
{
    NSPoint topMid = NSMakePoint(NSMidX(aRect), NSMaxY(aRect));
    NSPoint topLeft = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
    NSPoint topRight = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
    NSPoint bottomRight = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));

    [self moveToPoint:topMid];
    [self appendBezierPathWithArcFromPoint:topLeft toPoint:aRect.origin radius:radius];
    [self appendBezierPathWithArcFromPoint:aRect.origin toPoint:bottomRight radius:radius];
    [self appendBezierPathWithArcFromPoint:bottomRight toPoint:topRight radius:radius];
    [self appendBezierPathWithArcFromPoint:topRight toPoint:topLeft radius:radius];
    [self closePath];
}

- (void)appendBezierPathWithLeftRoundedRectangle:(NSRect)aRect withRadius:(float)radius;
{
    NSPoint topMid = NSMakePoint(NSMidX(aRect), NSMaxY(aRect));
    NSPoint topLeft = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
    NSPoint topRight = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
    NSPoint bottomRight = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));
    
    [self moveToPoint:topMid];
    [self appendBezierPathWithArcFromPoint:topLeft toPoint:aRect.origin radius:radius];
    [self appendBezierPathWithArcFromPoint:aRect.origin toPoint:bottomRight radius:radius];
    [self lineToPoint:bottomRight];
    [self lineToPoint:topRight];
    [self closePath];
}

- (void)appendBezierPathWithRightRoundedRectangle:(NSRect)aRect withRadius:(float)radius;
{
    NSPoint topMid = NSMakePoint(NSMidX(aRect), NSMaxY(aRect));
    NSPoint topLeft = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
    NSPoint topRight = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
    NSPoint bottomRight = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));
    
    [self moveToPoint:topMid];
    [self lineToPoint:topLeft];
    [self lineToPoint:aRect.origin];
    [self appendBezierPathWithArcFromPoint:bottomRight toPoint:topRight radius:radius];
    [self appendBezierPathWithArcFromPoint:topRight toPoint:topLeft radius:radius];
    [self closePath];
}

//

- (struct pointInfo)_getPointInfoForPosition:(float)position {
    NSPoint coefficients[4];
    NSPoint points[3];
    int segment;
    float segmentPosition;
    int segmentCount = [self elementCount] - 1;
    NSPoint startPoint;
    int element;

    if (position < 0)
        position = 0;
    if (position > 1)
        position = 1;
    if (position == 1) {
        segment = segmentCount-1;
        segmentPosition = 1;
    } else {
        segment = (int) floor(position*segmentCount);
        segmentPosition = position * segmentCount - segment;
    }

    startPoint = [self _endPointForSegment:segment];
    element = [self elementAtIndex:segment+1 associatedPoints:points];
    switch(element) {
        case NSClosePathBezierPathElement:
        {
            int past = segment;
            [self elementAtIndex:0 associatedPoints:points];
            NSPoint bezierEndPoint = points[0];
            while(past--) {
                // Back up until we find the last closepath
                // then step forward to hopefully find a moveto
                element = [self elementAtIndex:past associatedPoints:points];
                if (element == NSClosePathBezierPathElement) {
                    element = [self elementAtIndex:past+1 associatedPoints:points];
                    if (element == NSMoveToBezierPathElement)
                        bezierEndPoint = points[0];
                    break;
                }
            }
            _parameterizeLine(coefficients,startPoint,bezierEndPoint);
            return getLinePoint(coefficients, segmentPosition);
        }
        case NSMoveToBezierPathElement:// PENDING: should probably skip this one
        case NSLineToBezierPathElement: {
            _parameterizeLine(coefficients,startPoint,points[0]);
            return getLinePoint(coefficients, segmentPosition);
        }
        case NSCurveToBezierPathElement: {
            _parameterizeCurve(coefficients, startPoint, points[2], points[0], points[1]);
            return getCurvePoint(coefficients, segmentPosition);
        }
    }
    return (struct pointInfo){ startPoint, 0, 0 }; // ack
}

- (NSPoint)getPointForPosition:(float)position andOffset:(float)offset {
    return offsetPoint([self _getPointInfoForPosition:position], offset, YES);
}

- (float)getPositionForPoint:(NSPoint)point {
    float position =0;
    int segment = [self _segmentHitByPoint:point position:&position padding:5.0];
    if (segment) {
        position = position + (segment - 1);
        position /= ([self elementCount] - 1);
        return (position);
    }
    return 0.5; // EEK!
}

// NOTE: Graffle used to rely on this method always returning the "upwards" normal for the line; it no longer does (Graffle performs the upwards constraint itself).
// So this method has been changed to return the "left" normal, since that provides more information to the caller.
- (float)getNormalForPosition:(float)position {
    struct pointInfo pi = [self _getPointInfoForPosition:position];
    return atan2(pi.tangentX, - pi.tangentY) * 180.0/M_PI;
}


// load and save

- (NSMutableDictionary *)propertyListRepresentation;
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSMutableArray *segments = [NSMutableArray array];
    NSPoint points[3];
    NSBezierPathElement element;
    int count = [self elementCount];
    int i;

    for(i=0;i<count;i++) {
        NSMutableDictionary *segment = [NSMutableDictionary dictionary];
        element = [self elementAtIndex:i associatedPoints:points];
        
        switch(element) {
            case NSMoveToBezierPathElement:
                [segment setObject:NSStringFromPoint(points[0]) forKey:@"point"];
                [segment setObject:@"MOVETO" forKey:@"element"];
                break;
            case NSClosePathBezierPathElement:
                [segment setObject:@"CLOSE" forKey:@"element"];
                break;
            case NSLineToBezierPathElement:
                [segment setObject:NSStringFromPoint(points[0]) forKey:@"point"];
                [segment setObject:@"LINETO" forKey:@"element"];
                break;
            case NSCurveToBezierPathElement:
                [segment setObject:NSStringFromPoint(points[2]) forKey:@"point"];
                [segment setObject:NSStringFromPoint(points[0]) forKey:@"control1"];
                [segment setObject:NSStringFromPoint(points[1]) forKey:@"control2"];
                [segment setObject:@"CURVETO" forKey:@"element"];
                break;
        }
        [segments addObject:segment];
    }
    [dict setObject:segments forKey:@"elements"];
    
    return dict;
}

- (void)loadPropertyListRepresentation:(NSDictionary *)dict {
    NSArray *segments = [dict objectForKey:@"elements"];
    int count = [segments count];
    int i;
    for(i=0;i<count;i++) {
        NSDictionary *segment = [segments objectAtIndex:i];
        NSString *element = [segment objectForKey:@"element"];
        if ([element isEqualToString:@"CURVETO"]) {
            NSString *pointString = [segment objectForKey:@"point"];
            NSString *control1String = [segment objectForKey:@"control1"];
            NSString *control2String = [segment objectForKey:@"control2"];
            if (pointString && control1String && control2String) {
                [self curveToPoint:NSPointFromString(pointString) 
                       controlPoint1:NSPointFromString(control1String)
                       controlPoint2:NSPointFromString(control2String)];
            }
        } else if ([element isEqualToString:@"LINETO"]) {
            NSString *pointString = [segment objectForKey:@"point"];
            if (pointString) {
                [self lineToPoint:NSPointFromString(pointString)];
            }
        } else if ([element isEqualToString:@"MOVETO"]) {
            NSString *pointString = [segment objectForKey:@"point"];
            if (pointString) {
                [self moveToPoint:NSPointFromString(pointString)];
            }
        } else if ([element isEqualToString:@"CLOSE"]) {
            [self closePath];
        }
    }
}


// NSObject overrides

- (BOOL)isEqual:(NSBezierPath *)otherBezierPath;
{
    unsigned int elementIndex, elementCount = [self elementCount];

    if (self == otherBezierPath)
        return YES;
    
    if (![otherBezierPath isMemberOfClass:[self class]])
        return NO;

    if ((unsigned)[otherBezierPath elementCount] != elementCount)
        return NO;
    
    for(elementIndex=0; elementIndex<elementCount; elementIndex++) {
        NSPoint points[3];
        NSBezierPathElement element = [self elementAtIndex:elementIndex associatedPoints:points];
        NSPoint otherPoints[3];
        NSBezierPathElement otherElement = [otherBezierPath elementAtIndex:elementIndex associatedPoints:otherPoints];

        if (element != otherElement)
            return NO;
        
        switch (element) {
            case NSMoveToBezierPathElement:
                if (!NSEqualPoints(points[0], otherPoints[0]))
                     return NO;
                break;
            case NSLineToBezierPathElement:
                if (!NSEqualPoints(points[0], otherPoints[0]))
                    return NO;
                break;
            case NSCurveToBezierPathElement:
                if (!NSEqualPoints(points[0], otherPoints[0]) || !NSEqualPoints(points[1], otherPoints[1]) || !NSEqualPoints(points[2], otherPoints[2]))
                    return NO;
                break;
            case NSClosePathBezierPathElement:
                break;
        }
    }

    return YES;
}

static inline unsigned int _spinLeft(unsigned int number, unsigned int spinLeftBitCount)
{
    const unsigned int bitsPerUnsignedInt = sizeof(unsigned int) * 8;
    unsigned int leftmostBits = number >> (bitsPerUnsignedInt - spinLeftBitCount);
    return (number << spinLeftBitCount) | leftmostBits;
}

static inline unsigned int _threeBitsForPoint(NSPoint point)
{
    float bothAxes = ABS(point.x) + ABS(point.y);
    return ((unsigned int)(bothAxes / pow(10.0, floor(log10(bothAxes))))) & 0x7;
}

- (unsigned int)hash;
{
    unsigned int hashValue = 0;
    unsigned int elementIndex, elementCount = [self elementCount];

    for(elementIndex=0; elementIndex<elementCount; elementIndex++) {
        NSPoint points[3];
        NSBezierPathElement element = [self elementAtIndex:elementIndex associatedPoints:points];

        switch (element) {
            case NSMoveToBezierPathElement:
                hashValue = _spinLeft(hashValue, 2);
                hashValue ^= 0;
                hashValue = _spinLeft(hashValue, 3);
                hashValue ^= _threeBitsForPoint(points[0]);
                break;
            case NSLineToBezierPathElement:
                hashValue = _spinLeft(hashValue, 2);
                hashValue ^= 1;
                hashValue = _spinLeft(hashValue, 3);
                hashValue ^= _threeBitsForPoint(points[0]);
                break;
            case NSCurveToBezierPathElement:
                hashValue = _spinLeft(hashValue, 2);
                hashValue ^= 2;
                hashValue = _spinLeft(hashValue, 3);
                hashValue ^= _threeBitsForPoint(points[0]);
                hashValue = _spinLeft(hashValue, 3);
                hashValue ^= _threeBitsForPoint(points[1]);
                hashValue = _spinLeft(hashValue, 3);
                hashValue ^= _threeBitsForPoint(points[2]);
                break;
            case NSClosePathBezierPathElement:
                hashValue = _spinLeft(hashValue, 2);
                hashValue ^= 3;
                break;
        }
    }
    return hashValue;
}


@end



@implementation NSBezierPath (PrivateOAExtensions)

NSString *_roundedStringForPoint(NSPoint point)
{
    return [NSString stringWithFormat:@"{%.5f,%.5f}", point.x, point.y];
}


//

static NSRect _parameterizedCurveBounds(const NSPoint *curve) {
    float minX = curve[0].x;
    float maxX = curve[0].x;
    float minY = curve[0].y;
    float maxY = curve[0].y;
    NSRect rect;
    NSPoint points[3];
    int i;

    points[0].x = curve[0].x + 0.3333* curve[1].x;
    points[0].y = curve[0].y + 0.3333* curve[1].y;
    points[1].x = curve[0].x + 0.3333* curve[2].x + 0.6666* curve[1].x;
    points[1].y = curve[0].y + 0.3333* curve[2].y + 0.6666* curve[1].y;
    points[2].x = curve[3].x + curve[2].x + curve[1].x + curve[0].x;
    points[2].y = curve[3].y + curve[2].y + curve[1].y + curve[0].y;
    
    for(i=0;i<3;i++) {
        NSPoint p = points[i];
        if (p.x > maxX) {
            maxX = p.x;
        } else if (p.x < minX) {
            minX = p.x;
        }
        if (p.y > maxY) {
            maxY = p.y;
        } else if (p.y < minY) {
            minY = p.y;
        }
    }
    rect.origin.x = minX;
    rect.origin.y = minY;
    rect.size.width = maxX - minX;
    if (rect.size.width < 1) {
        rect.size.width = 1;
    }
    rect.size.height = maxY - minY;
    if (rect.size.height < 1) {
        rect.size.height = 1;
    }
    return rect;
}

// Happy fun arbitrary constants.
#define EPSILON 1e-10
#define FLATNESS 1e-2

// wants 4 coefficients and 3 roots
// returns the number of solutions
static int _solveCubic(double *c, double *roots) {
    // From Graphic Gems 1
    int i, num = 0;
    double sub;
    double A,B,C;
    double sq_A, p, q;
    double cb_p, D;

    if (c[3] == 0) {
        if (c[2] == 0) {
            if (c[1] == 0) {
                num = 0;
            } else {
                num = 1;
                roots[0] = -c[0]/c[1];
            }
        } else {
            double temp;
            // x^3 coefficient is zero, so it's a quadratic
            
            A = c[2];
            B = c[1];
            C = c[0];
            
            temp = B*B - 4*A*C;
            if (fabs(temp) < EPSILON) {
                roots[0] = -B / (2*A);
                num = 1;
            } else if(temp < 0) {
                num = 0;
            } else {
                temp = sqrt(temp);
                roots[0] = (-B-temp)/(2*A);
                roots[1] = (-B+temp)/(2*A);
                num = 2;
            }
        }
        return num;
    } else {
    // Normal form: x^3 + Ax^2 + Bx + C
        A = c[2] / c[3];
        B = c[1] / c[3];
        C = c[0] / c[3];
    }
    
    // Substitute x = y - A/3 to eliminate the quadric term
    // x^3 + px + q
    // We multiply in some constant factors to avoid dividing early; this gives us less roundoff
    sq_A = A * A;
    p = 3 * B - sq_A;  // this is actually 9*p
    q = (2 * A * sq_A - 9 * A * B + 27 * C) / 2; // this is actually 27*q
    cb_p = p * p * p;  // 729 * p^3
    D = q * q + cb_p;  // 729 * (q^2 + p^3)
    // NSLog(@"Stinky cheese: A=%g (%g), B=%g (%g), C=%g (%g);   D=%g q=%g", A, A-floor(A+0.5), B, B-floor(B+0.5), C, C-floor(C+0.5), D, q);
    
    if (fabs(D)<EPSILON) {
        if (q==0) {  // one triple solution
            roots[0] = 0;
            num = 1;
        } else {     // one single and one double solution
            double u = cbrt(-q)/3.;
            roots[0] = 2 * u;
            roots[1] = -u;
            num = 2;
        }
    } else if (D < 0) { // Casus irreducibilis: three real solutions
        double phi = 1.0/3 * acos(-q / sqrt(-cb_p));  // the extra factors on p^3 and q cancel
        double t = 2 * sqrt(-p)/3.;

        roots[0] = t * cos(phi);
        roots[1] = -t * cos(phi + M_PI / 3);
        roots[2] = -t * cos(phi - M_PI / 3);
        num = 3;
    } else {  // One real solution
        double sqrt_D = sqrt(D);  // 27*sqrt(q^2 + p^3)
        double u = cbrt(sqrt_D - q);
        double v = -cbrt(sqrt_D + q);
        roots[0] = (u + v)/3.;
        num = 1;
    }

    // resubstitute

    sub = 1.0/3 * A;
    for(i=0;i<num;i++) {
        roots[i] -= sub;
    }

    return num;
}

static inline double evaluateCubic(const double *c, double x)
{
    // Horner's rule for the win.
    return  (( c[3] * x + c[2] ) * x + c[1] ) * x + c[0];
}

static void _parameterizeLine(NSPoint *coefficients, NSPoint startPoint, NSPoint endPoint) {
    coefficients[0] = startPoint;
    coefficients[1].x = endPoint.x - startPoint.x;
    coefficients[1].y = endPoint.y - startPoint.y;
}

// Given a curveto's endpoints and control points, compute the coefficients to trace out the curve as p(t) = c[0] + c[1]*t + c[2]*t^2 + c[3]*t^3
static void _parameterizeCurve(NSPoint *coefficients, NSPoint startPoint, NSPoint endPoint, NSPoint controlPoint1, NSPoint controlPoint2) {
    NSPoint tangent2;
    tangent2.x = 3.0 * (endPoint.x - controlPoint2.x);
    tangent2.y = 3.0 * (endPoint.y - controlPoint2.y);

    coefficients[0] = startPoint;
    coefficients[1].x = 3.0 * (controlPoint1.x - startPoint.x);  // 1st tangent
    coefficients[1].y = 3.0 * (controlPoint1.y - startPoint.y);  // 1st tangent
    coefficients[2].x = 3.0 * (endPoint.x - startPoint.x) - 2.0 * coefficients[1].x - tangent2.x;
    coefficients[2].y = 3.0 * (endPoint.y - startPoint.y) - 2.0 * coefficients[1].y - tangent2.y;
    coefficients[3].x = 2.0 * (startPoint.x - endPoint.x) + coefficients[1].x + tangent2.x;
    coefficients[3].y = 2.0 * (startPoint.y - endPoint.y) + coefficients[1].y + tangent2.y;
}

// Given a parameterized curve c and a parameterized line a, return up to 3 intersections.
static int intersectionsBetweenCurveAndLine(const NSPoint *c, const NSPoint *a, struct intersectionInfo *results)
{
    int i;
    double xcubic[4], ycubic[4];
    double roots[3];
    int count;
    
    // Transform the problem so that the line segment goes from (0,0) to (1,0)
    // (this simplifies the math, and gets rid of the troublesome horizontal / vertical cases)
    xcubic[0] = c[0].x - a[0].x, ycubic[0] = c[0].y - a[0].y;
    for(i = 1; i < 4; i++)
        xcubic[i] = c[i].x, ycubic[i] = c[i].y;
    double lineLengthSquared = a[1].x*a[1].x + a[1].y*a[1].y;
    OBASSERT(lineLengthSquared > 0);
    for(i = 0; i < 4; i++) {
        double x = xcubic[i] * a[1].x + ycubic[i] * a[1].y;
        double y = xcubic[i] * a[1].y - ycubic[i] * a[1].x;
        xcubic[i] = x / lineLengthSquared;
        ycubic[i] = y /* / lineLengthSquared constant factors are unimportant in y */ ;
    }
    
    // Solve for y==0
    count = _solveCubic(ycubic, roots);
    
    // Sort the results, since callers require intersections to be returned in order of increasing leftParameter
    if (count > 1) {
        if (roots[0] > roots[1]) {
            SWAP(roots[0], roots[1]);
        }
        if (count > 2) {
            if (roots[0] > roots[2]) {
                double r1 = roots[0];
                double r2 = roots[1];
                roots[0] = roots[2];
                roots[1] = r1;
                roots[2] = r2;
            } else if (roots[1] > roots[2]) {
                SWAP(roots[1], roots[2]);
            }
        }
    }
    
    int resultCount = 0;
    
    for(i=0;i<count;i++) {
        float u = roots[i];
        
        if (u < -0.0001 || u > 1.0001) {
            continue;
        }
        if (isnan(u)) {
            continue;
        }
        
        // The root indicates the cubic's parameter where it intersects. To find the line's parameter, we compute the transformed cubic's x-coordinate.
        double t = evaluateCubic(xcubic, u);
        if (t < -0.0001 || t > 1.0001)
            continue;
        
        results[resultCount].leftParameter = u;
        results[resultCount].rightParameter = t;
        results[resultCount].leftParameterDistance = 0;
        results[resultCount].rightParameterDistance = 0;
        resultCount++;
    }

    return resultCount;
}

static inline float lineSide(NSPoint p, const NSPoint *a)
{
    float x = p.x - a[0].x;
    float y = p.y - a[0].y;
    return a[1].x * y - a[1].y * x;
}

static inline double dotprod(float x, float y, NSPoint xy0, NSPoint xy1)
{
    return (x - xy0.x) * xy1.x + (y - xy0.y) * xy1.y;
}

static inline double vecmag(double a, double b)
{
    return hypot(a, b);
}

// This returns (a/b), clipping the result to 1.
// (Safely returns 1 for the (0/0) case as well.)
// Caller assures that a/b is not negative.
static inline double clip_div(double dotproduct, double vecmag)
{
    if (fabs(dotproduct) >= fabs(vecmag))
        return 1.0;
    else
        return dotproduct / vecmag;
}

// Given two lines l1, l2: return zero or one intersections. May return intersections with nonzero distance.
static int intersectionsBetweenLineAndLine(const NSPoint *l1, const NSPoint *l2, struct intersectionInfo *results)
{
    double pdet, vdet, other_pdet;
        
    // NSLog(@"Line 1: (%g,%g)->(%g,%g)    Line 2: (%g,%g)->(%g,%g)", l1[0].x,l1[0].y, l1[1].x,l1[1].y, l2[0].x,l2[0].y, l2[1].x,l2[1].y); 

    pdet = ( l1[0].x - l2[0].x ) * l2[1].y - ( l1[0].y - l2[0].y ) * l2[1].x;
    vdet = l1[1].x * l2[1].y - l1[1].y * l2[1].x;
    other_pdet = ( l2[0].x - l1[0].x ) * l1[1].y - ( l2[0].y - l1[0].y ) * l1[1].x;  // pdet, with l1 and l2 swapped
    // double other_vdet = - vdet;  // vdet, with l1 and l2 swapped
    
    // NSLog(@"Determinants: %g/%g  and  %g/%g", pdet, vdet, other_pdet, -vdet);
    
    if (pdet != 0 && signbit(pdet) == signbit(vdet)) {
        // l1 diverges from l2, no intersection.
        return 0;
    } else if (other_pdet != 0 && signbit(other_pdet) != signbit(vdet)) {
        // l2 diverges from l1, no intersection.
        return 0;
    } else if (fabs(pdet) > fabs(vdet) || fabs(other_pdet) > fabs(vdet)) {
        // Either parallel (vdet==0), or convergent but not fast enough to cross within the length of l1. (or l2, in the case of other_pdet).
        return 0;
    } else if (fabs(vdet) > EPSILON) {
        // The straightforward crossing-lines case.
        results[0].leftParameter = - pdet / vdet;
        results[0].rightParameter = other_pdet / vdet;
        results[0].leftParameterDistance = 0;
        results[0].rightParameterDistance = 0;
        return 1;
    } else {
        // Parallel and collinear. Annoying case, but pretty common in actual use of Graffle.
        // (This is also where you end up if l2 is zero-length, another not unheard-of situation.)
        // The following algorithm isn't fastest, but it's well-behaved. I'll waste a few of those GHz on correctness.
        double dot0 = dotprod(l1[0].x, l1[0].y, l2[0], l2[1]);                        // Projecting start of l1 onto l2.
        double dot1 = dotprod(l1[0].x + l1[1].x, l1[0].y + l1[1].y, l2[0], l2[1]);    // Projecting end of l1 onto l2.
        if (dot0 < 0 && dot1 < 0) {
            // l1 is completely before l2.
            return 0;
        }
        double l1len2 = l1[1].x*l1[1].x + l1[1].y*l1[1].y;  // squared length of l1
        double l2len2 = l2[1].x*l2[1].x + l2[1].y*l2[1].y;  // squared length of l2
        if (dot0 > l2len2 && dot1 > l2len2) {
            // l1 is completely after l2.
            return 0;
        }
        if (l2len2 <= EPSILON*EPSILON) {
            // l2 is zero-length, but is in line with l1.
            if (l1len2 <= EPSILON*EPSILON) {
                // l1 is zero-length also. j00 suxx0r!
                if (NSEqualPoints(l1[0],l2[0])) {
                    results[0].leftParameter = 0;
                    results[0].leftParameterDistance = 1;
                    results[0].rightParameter = 0;
                    results[0].rightParameterDistance = 1;
                    return 1;  // One result in the buffer.
                } else {
                    return 0;  // No intersection.
                }
            } else {
                // Project l2 onto l1.
                double l1parameter = dotprod(l2[0].x, l2[0].y, l1[0], l1[1]);
                if (l1parameter >= 0 && l1parameter <= l1len2) {
                    results[0].leftParameter = l1parameter / l1len2;
                    results[0].leftParameterDistance = 0;
                    results[0].rightParameter = 0;
                    results[0].rightParameterDistance = 1;
                    return 1;
                } else {
                    // Past the end of the line. No intersection.
                    return 0;
                }
            }
        }
        // Okay, there's overlap. Now, compute the overlap range in terms of each line's parameters... "start" and "end" are in terms of l1, which means that they might be going backwards along l2 if the two segments are antiparallel.
        double leftParameterStart, rightParameterStart, leftParameterEnd, rightParameterEnd;
        // NSLog(@"dot0 = %g, dot1 = %g, l1len2 = %g, l2len2 = %g", dot0, dot1, l1len2, l2len2);
        if (dot0 > l2len2) {
            // <5>
            // l1[0] is past the end of l2, but l1 points back into l2. Similar to case <2>, but the lines are antiparallel.
            double dot = dotprod(l2[0].x+l2[1].x, l2[0].y+l2[1].y, l1[0], l1[1]);  // Project end of l2 onto l1.
            leftParameterStart  = clip_div(dot, l1len2);           // overlap starts here along l1
            rightParameterStart = 1;                               // overlap starts as soon as we find l2, starting at its end
        } else if (dot0 >= 0) {
            // <1>
            // l1[0] is somewhere inside the l2 line segment.
            leftParameterStart  = 0;                              // overlap starts at t=0 along l1
            rightParameterStart = clip_div(dot0, l2len2);    // overlap starts here along l2
        } else {
            // <2>
            // l1[0] is outside the l2 line segment, but l1 heads into l2, so find where l2 starts.
            // we compute the dot products in the other order:
            double dot = dotprod(l2[0].x, l2[0].y, l1[0], l1[1]);  // Project beginning of l2 onto l1.
            // note that we know that l1 and l2 are pointing in the same direction, which simplifies the logic in here.
            leftParameterStart  = clip_div(dot, l1len2);   // overlap starts here along l1
            rightParameterStart = 0;                              // overlap starts as soon as we find l2
        }
        if (dot1 >= l2len2) {
            // <6>
            // l1[end] is past the end of the l2 line segment, but they're pointing in the same direction.
            double dot = dotprod(l2[0].x+l2[1].x, l2[0].y+l2[1].y, l1[0], l1[1]);  // Project end of l2 onto l1.
            leftParameterEnd = clip_div(dot, l1len2);
            rightParameterEnd = 1;
        } else if (dot1 >= 0) {
            // <3>
            // l1[end] is somewhere inside the l2 line segment.
            leftParameterEnd = 1;                                 // overlap continues through end of l1
            rightParameterEnd = clip_div(dot1, l2len2);      // overlap ends here along l2
        } else {
            // <4>
            // l1[end] is somewhere before the l2 line segment. Since we would have already caught the case where they're both before l2, the segments must be antiparallel, with l1[start] inside (or after) l2. This is the companion to case <2>.
            double dot = dotprod(l2[0].x, l2[0].y, l1[0], l1[1]);  // Project beginning of l2 onto l1.
            leftParameterEnd = clip_div(dot, l1len2);
            rightParameterEnd = 0;
        }
        // Copy the ranges into the results buffer.
        results[0].leftParameter = leftParameterStart;
        results[0].leftParameterDistance = leftParameterEnd - leftParameterStart;
        results[0].rightParameter = rightParameterStart;
        results[0].rightParameterDistance = rightParameterEnd - rightParameterStart;
        return 1;  // One result in the buffer.
    }
}

// Unlike the other intersections functions, this one takes control points, not parameterized curves.
static int intersectionsBetweenCurveAndCurve(const NSPoint *c1, NSRect c1bounds, const NSPoint *c2, struct intersectionInfo *results, double ivlLow, double ivlSize)
{
    // Check whether c2 is close enough to a straight line for our purposes.
    // The error vector of the straight-line approximation is t * (t-1) * (p[2] + p[3]*(t+1)) for a parameterized curve p[0..3].
    // The first pair of terms can't exceed 1/4, and the magnitude of the last pair can't exceed |p[2]+p[3]|+|p[3]| over the range 0<=t<=1.
    // So we use this as an easy to compute upper bound on the error. Note that this is a vector error: a Bezier curve could be a straight line with a nonuniform 't' parameter and not count as straight by this measure. We need to use the vector error, or else we'll compute incorrect t-parameter values for the intersections (and eventually subdivide curves in the wrong places).
    double error_bound;
    {
        // TODO: Expand out _parameterizeCurve() and simplify the resulting algebra. (Or just verify that the compiler is doing it for us.)
        NSPoint p[4];
        _parameterizeCurve(p, c2[0], c2[3], c2[1], c2[2]);
        error_bound = ( vecmag(p[2].x+p[3].x, p[2].y+p[3].y) + vecmag(p[3].x, p[3].y) ) / 4;
    }
    if (error_bound < FLATNESS) {
        // Yup, looks like a line. Compute the parameterized line representation and use that.
        NSPoint l2[2];
        int found, fixup;
        l2[0] = c2[0];
        l2[1].x = c2[3].x - c2[0].x;
        l2[1].y = c2[3].y - c2[0].y;
        found = intersectionsBetweenCurveAndLine(c1, l2, results);
        for(fixup = 0; fixup < found; fixup++) {
            results[fixup].rightParameter = results[fixup].rightParameter * ivlSize + ivlLow;
            results[fixup].rightParameterDistance *= ivlSize;
        }
        return found;
    } else if (!NSIntersectsRect(c1bounds, _bezierCurveToBounds(c2))) {
        // The loose bounding boxes don't intersect.
        return 0;
    } else {
        // Subdivide c2, and find intersections with each half. Eventually we'll either find a fragment that's flat enough to treat as a line, or we'll discover it's outside of c1's bounding box.
        NSPoint left[4], right[4];
        int foundLeft, foundRight;
        _splitCurve(c2, left, right);
        foundLeft = intersectionsBetweenCurveAndCurve(c1, c1bounds, left, results, ivlLow, ivlSize/2);
        foundRight = intersectionsBetweenCurveAndCurve(c1, c1bounds, right, results + foundLeft, ivlLow + ivlSize/2, ivlSize/2);
        return foundLeft + foundRight;
    }
}

- (BOOL)_curvedIntersection:(float *)length time:(float *)time curve:(NSPoint *)c line:(NSPoint *)a {
    int i;
    double cubic[4];
    double roots[3];
    int count;
    float minT = 1.1;
    BOOL foundOne = NO;
    
    for(i=0;i<4;i++) {
        cubic[i] = c[i].x * a[1].y - c[i].y * a[1].x;
    }
    cubic[0] -= (a[0].x * a[1].y - a[0].y * a[1].x);
    
    count = _solveCubic(cubic, roots);
    
    for(i=0;i<count;i++) {
        float u = roots[i];
        float t;
        
        if (u < -0.0001 || u > 1.0001) {
            continue;
        }
        if (isnan(u)) {
            continue;
        }
        
        // Used to be (a[1].x == 0), but that caused problems if a[1].x was very close to zero.
        // Instead we use whichever is larger.
        if (fabs(a[1].x) < fabs(a[1].y)) {
            t = c[0].y + u * (c[1].y + u * (c[2].y + u * c[3].y));
            t -= a[0].y;
            t /= a[1].y;
        } else {
            t = c[0].x + u * (c[1].x + u * (c[2].x + u * c[3].x));
            t -= a[0].x;
            t /= a[1].x;
        }
        if (t < -0.0001 || t > 1.0001) {
            continue;
        }
        
        if (t < minT) {
            foundOne = YES;
            minT = t;
            *time = u;
        }
    }
    
    if (foundOne) {
        if (minT < 0)
            minT = 0;
        else if (minT > 1)
            minT = 1;
        *length = minT;
        return YES;
    }
    
    return NO;
}

#if 0

struct pathPoint {
    unsigned elt;             // The element number of the NSBezierPath where this point lies
    double distance;          // The linear distance along the element
    double position;          // The parameter distance along the element (0..1)
    BOOL implicit;            // If true, this is actually an implicit closepath inserted after the specified elt
};

struct pathIntersection {
    struct {
        NSPoint point;
        struct pathPoint left, right;
    } start, end;
    BOOL crosses;
};

struct subpathWalkingState {
    NSBezierPath *pathBeingWalked;      // The NSBezierPath we're iterating through
    int elementCount;                   // [pathBeingWalked elementCount]
    NSPoint startPoint;                 // first point of this subpath, for closepath
    NSBezierPathElement what;           // the type of the current segment/element
    NSPoint points[4];                  // point[0] is currentPoint (derived from previous element)
    int currentElt;                     // index into pathBeingWalked of currently used element
    double currentEltPosition;          // current position along said element (t parameter, 0..1)
    
    // Note that if currentElt >= elementCount, then 'what' may be a faked-up closepath or other element not actually found in the NSBezierPath.
};

BOOL nextSubpathElement(struct subpathWalkingState *s);

BOOL firstSubpathElement(struct subpathWalkingState *s, NSBezierPath *p, int startIndex)
{
    int pathElementCount = [p elementCount];
    
    // Fail if the startIndex is past the end. Also fail if the startIndex points to the last element, because the only valid 1-element subpath is a single moveto, and we ignore those.
    if (startIndex >= (pathElementCount-1)) {
        return NO;
    }
    
    s->pathBeingWalked = p;
    s->elementCount = pathElementCount;
    s->what = [p elementAtIndex:startIndex associatedPoints:s->points];
    if (s->what != NSMoveToBezierPathElement) {
        OBASSERT_NOT_REACHED("Bezier path element should be NSMoveToBezierPathElement but isn't");
        return NO;
    }
    s->startPoint = s->points[0];
    s->currentElt = startIndex;
    s->currentEltPosition = 1.0;
    
    return nextSubpathElement(s);
}

BOOL nextSubpathElement(struct subpathWalkingState *s)
{
    switch(s->what) {
        default:
            OBASSERT_NOT_REACHED("Unknown NSBezierPathElement");
            /* FALL THROUGH */
        case NSClosePathBezierPathElement:
            return NO;
            
        case NSMoveToBezierPathElement:
            /* The first element of the path */
            break;
            
        case NSLineToBezierPathElement:
            s->points[0] = s->points[1];  // update currentpoint
            break;
        case NSCurveToBezierPathElement:
            s->points[0] = s->points[3];  // update currentpoint
            break;
    }
    
    s->currentElt ++;
    if (s->currentElt >= s->elementCount) {
        // Whoops. An unterminated path. Do the implicit closepath.
        s->what = NSClosePathBezierPathElement;
        s->points[1] = s->startPoint;
    } else {
        s->what = [s->pathBeingWalked elementAtIndex:s->currentElt associatedPoints:(s->points + 1)];    
        switch(s->what) {
            case NSClosePathBezierPathElement:
                s->elementCount = s->currentElt + 1;
                s->points[1] = s->startPoint;
                break;
                
            default:
                OBASSERT_NOT_REACHED("Unknown NSBezierPathElement");
                /* FALL THROUGH */
            case NSMoveToBezierPathElement:
                // An unterminated subpath. Do the implicit closepath.
                s->what = NSClosePathBezierPathElement;
                s->elementCount = s->currentElt; // The moveto we just extracted is part of the next subpath, not this one.
                s->points[1] = s->startPoint;
                break;
                
            case NSLineToBezierPathElement:
            case NSCurveToBezierPathElement:
                /* These require no special actions */
                break;
        }
    }
    
    s->currentEltPosition -= 1.0;
    if (s->currentEltPosition < 0)
        s->currentEltPosition = 0.0;
    return YES;
}

- (struct intersectionInfo *)_allIntersectionsWithLine:(const NSPoint *)l inRange:(NSRange)r
{
    struct subpathWalkingState iter;
    struct intersectionInfo *intersections;
    
    if (!firstSubpathElement(&iter, self, r.location))
        return NULL;
    do {
        ...;
    } while(nextSubpathElement(&iter));
}

BOOL findNextIntersection(struct pathWalkingState *left, NSBezierPath *right, NSRange rightElts)
{
    while (left->currentEltPosition > 1.0) {
        // Get the next elt.
        if (!nextSubpathElement(left))
            return NO;
        
        ...;
    }
}
#endif

static BOOL _straightLineIntersectsRect(const NSPoint *a, NSRect rect) {
    // PENDING: needs some work...
    if (NSPointInRect(a[0], rect)) {
        return YES;
    }
    if (a[1].x != 0) {
        float t = (NSMinX(rect) - a[0].x)/a[1].x;
        float y;
        if (t >= 0 && t <= 1) {
            y = t * a[1].y + a[0].y;
            if (y >= NSMinY(rect) && y < NSMaxY(rect)) {
                return YES;
            }
        }
        t = (NSMaxX(rect) - a[0].x)/a[1].x;
        if (t >= 0 && t <= 1) {
            y = t * a[1].y + a[0].y;
            if (y >= NSMinY(rect) && y < NSMaxY(rect)) {
                return YES;
            }
        }
    }
    if (a[1].y != 0) {
        float t = (NSMinY(rect) - a[0].y)/a[1].y;
        float x;
        if (t >= 0 && t <= 1) {
            x = t * a[1].x + a[0].x;
            if (x >= NSMinX(rect) && x < NSMaxX(rect)) {
                return YES;
            }
        }
        t = (NSMaxY(rect) - a[0].y)/a[1].y;
        if (t >= 0 && t <= 1) {
            x = t * a[1].x + a[0].x;
            if (x >= NSMinX(rect) && x < NSMaxX(rect)) {
                return YES;
            }
        }
    }
//    } else {
//        if (a[0].x < NSMinX(rect) || a[0].x > NSMaxX(rect)) {
//            return NO;
//        }
//        if (a[0].y < NSMinY(rect)) {
//            if ((a[0].y + a[1].y) >= NSMinY(rect)) {
//                return YES;
//            }
//        } else if (a[0].y <= NSMaxY(rect)) {
//            return YES;
//        }
//    }
    return NO;
} 

static void _splitCurve(const NSPoint *c, NSPoint *left, NSPoint *right) {
    left[0] = c[0];
    left[1].x = 0.5 * c[1].x;
    left[1].y = 0.5 * c[1].y;
    left[2].x = 0.25 * c[2].x;
    left[2].y = 0.25 * c[2].y;
    left[3].x = 0.125 * c[3].x;
    left[3].y = 0.125 * c[3].y;

    right[0].x = left[0].x + left[1].x + left[2].x + left[3].x;
    right[0].y = left[0].y + left[1].y + left[2].y + left[3].y;
    right[1].x = 3 * left[3].x + 2 * left[2].x + left[1].x;
    right[1].y = 3 * left[3].y + 2 * left[2].y + left[1].y;
    right[2].x = 3 * left[3].x + left[2].x;
    right[2].y = 3 * left[3].y + left[2].y;
    right[3] = left[3];
}

static void splitParameterizedCurveLeft(const NSPoint *c, NSPoint *left)
{
    // This is just a substitution of t' = t / 2
    left[0].x = c[0].x;
    left[0].y = c[0].y;
    left[1].x = c[1].x / 2;
    left[1].y = c[1].y / 2;
    left[2].x = c[2].x / 4;
    left[2].y = c[2].y / 4;
    left[3].x = c[3].x / 8;
    left[3].y = c[3].y / 8;
}

static void splitParameterizedCurveRight(const NSPoint *c, NSPoint *right)
{
    // This is just a substitution of t' = (t + 1) / 2
    right[0].x = c[0].x + c[1].x/2 + c[2].x/4 + c[3].x/8;
    right[0].y = c[0].y + c[1].y/2 + c[2].y/4 + c[3].y/8;
    right[1].x =          c[1].x/2 + c[2].x/2 + c[3].x*3/8;
    right[1].y =          c[1].y/2 + c[2].y/2 + c[3].y*3/8;
    right[2].x =                     c[2].x/4 + c[3].x*3/8;
    right[2].y =                     c[2].y/4 + c[3].y*3/8;
    right[3].x =                                c[3].x/8;
    right[3].y =                                c[3].y/8;
}

static BOOL _curvedLineIntersectsRect(const NSPoint *c, NSRect rect, float tolerance) {
    NSRect bounds = _parameterizedCurveBounds(c);
    if (NSIntersectsRect(rect, bounds)) {
        if (bounds.size.width <= tolerance ||
            bounds.size.height <= tolerance) {
                return YES;
        } else {
            NSPoint half[4];
            splitParameterizedCurveLeft(c, half);
            if (_curvedLineIntersectsRect(half, rect, tolerance))
                return YES;
            splitParameterizedCurveRight(c, half);
            if (_curvedLineIntersectsRect(half, rect, tolerance))
                return YES;
        }
    }
    return NO;
}

- (BOOL)_curvedLineHit:(NSPoint)point startPoint:(NSPoint)startPoint endPoint:(NSPoint)endPoint controlPoint1:(NSPoint)controlPoint1 controlPoint2:(NSPoint)controlPoint2 position:(float *)position padding:(float)padding
{
    // find the square of the distance between the point and a point
    // on the curve (u).
    // use newtons method to approach the minumum u.
    NSPoint a[4];     // our regular coefficients
    double c[7];  // a cubic squared gives us 7 coefficients
    double u, bestU;

    double tolerance = padding + [self lineWidth] / 2;
    double delta, minDelta;
    int i;
        
//    if (tolerance < 3) {
//        tolerance = 3;
//    }
    
    tolerance *= tolerance;

    _parameterizeCurve(a, startPoint, endPoint, controlPoint1, controlPoint2);
    
    delta = a[0].x - point.x;
    c[0] = delta * delta;
    delta = a[0].y - point.y;
    c[0] += delta * delta;
    c[1] = 2 * ((a[0].x - point.x) * a[1].x + (a[0].y - point.y) * a[1].y);
    c[2] = a[1].x * a[1].x + a[1].y * a[1].y +
        2 * (a[2].x * (a[0].x - point.x) + a[2].y * (a[0].y - point.y));
    c[3] = 2 * (a[1].x * a[2].x + (a[0].x - point.x) * a[3].x +
                a[1].y * a[2].y + (a[0].y - point.y) * a[3].y);
    c[4] = a[2].x * a[2].x + a[2].y * a[2].y +
      2 * (a[1].x * a[3].x + a[1].y * a[3].y);
    c[5] = 2.0 * (a[2].x * a[3].x + a[2].y * a[3].y);
    c[6] = a[3].x * a[3].x + a[3].y * a[3].y;


    // Estimate a starting U
    if (endPoint.x < startPoint.x) {
        u = point.x - endPoint.x;
    } else {
        u = point.x - startPoint.x;
        delta = endPoint.x - startPoint.x;
    }
    
    delta = fabs(startPoint.x - point.x) + fabs(endPoint.x - point.x);
    delta += fabs(startPoint.y - point.y) + fabs(endPoint.y - point.y);

    if (endPoint.y < startPoint.y) {
        u += point.y - endPoint.y;
        delta += startPoint.y - endPoint.y;
    } else {
        u += point.y - startPoint.y;
        delta += endPoint.y - startPoint.y;
    }

    u /= delta;
    if (u < 0) {
        u = 0;
    } else if (u > 1) {
        u = 1;
    }

    // Iterate while adjust U with our error function

    // NOTE: Sadly, Newton's method becomes unstable as we approach the solution.  Also, the farther away from the curve, the wider the oscillation will be.
    // To get around this, we're keeping track of our best result, adding a few more iterations, and damping our approach.
    minDelta = 100000;
    bestU = u;
    
    for(i=0;i< 12;i++) {
        delta = (((((c[6] * u + c[5]) * u + c[4]) * u + c[3]) * u + c[2]) * u + c[1]) * u + c[0];
        if (delta < minDelta) {
            minDelta = delta;
            *position = u;
        }

        if (i==11 && minDelta <= tolerance) {
            return YES;
        } else {
            double slope = ((((( 6 * c[6] * u + 5 * c[5]) * u + 4 * c[4]) * u + 3 * c[3]) * u + 2 * c[2]) * u + c[1]);
            double deltaU = delta/slope;

            if ((u==0 && delta > 0) || (u==1 && delta < 0)) {
                return minDelta <= tolerance;
            }
            u -= 0.75 * deltaU; // Used to be just deltaU, but we're damping it a bit
            if (u<0.0) {
                u = 0.0;
            }
            if (u>1.0) {
                u = 1.0;
            }
        }
    }

    return NO;
}

- (BOOL)_straightLineIntersection:(float *)length time:(float *)time segment:(NSPoint *)s line:(const NSPoint *)l {
    // PENDING: should optimize this for the most common cases (s[1] == 0);
    float u;
    float t;
    
    if (ABS(s[1].x) < 0.001) {
        if (ABS(s[1].y) < 0.001) {
            // This is a zero length line, currently generated by rounded rectangles
            // NOTE: should fix rounded rectangles
            return NO;
        }
        if (ABS(l[1].x) < 0.001) {
            return NO;
        }
		s[1].x = 0;
    } else if (ABS(s[1].y) < 0.001) {
        if (ABS(l[1].y) < 0.001) {
            return NO;
        }
		s[1].y = 0;
    } 
    
    u = (s[1].y * s[0].x - s[1].x * s[0].y) - (s[1].y * l[0].x - s[1].x * l[0].y);
    u /= (s[1].y * l[1].x - s[1].x * l[1].y);
    if (u < -0.0001 || u > 1.0001) {
        return NO;
    }
    if (s[1].x == 0) {
        t = (l[1].y * u + (l[0].y - s[0].y)) / s[1].y;
    } else {
        t = (l[1].x * u + (l[0].x - s[0].x)) / s[1].x;
    }
    if (t < -0.0001 || t > 1.0001 || isnan(t)) {
        return NO;
    }
    
    *length = u;
    *time = t;
    return YES;
}

- (BOOL)_straightLineHit:(NSPoint)startPoint :(NSPoint)endPoint :(NSPoint)point  :(float *)position padding:(float)padding {
    NSPoint delta;
    NSPoint vector;
    NSPoint linePoint;
    float length;
    float dotProduct;
    float distance;
    float tolerance = padding + [self lineWidth]/2;
    
//    if (tolerance < 3) {
//        tolerance = 3;
//    }
    
    delta.x = endPoint.x - startPoint.x;
    delta.y = endPoint.y - startPoint.y;
    length = sqrt(delta.x * delta.x + delta.y * delta.y);
    delta.x /=length;
    delta.y /=length;

    vector.x = point.x - startPoint.x;
    vector.y = point.y - startPoint.y;

    dotProduct = vector.x * delta.x + vector.y * delta.y;

    linePoint.x = startPoint.x + delta.x * dotProduct;
    linePoint.y = startPoint.y + delta.y * dotProduct;

    delta.x = point.x - linePoint.x;
    delta.y = point.y - linePoint.y;

    // really the distance squared
    distance = delta.x * delta.x + delta.y * delta.y;
    
    if (distance < (tolerance * tolerance)) {
        *position = dotProduct/length;
        if (*position >= 0 && *position <=1) {
            return YES;
        }
    }
    
    return NO;
}

- (int)_segmentHitByPoint:(NSPoint)point position:(float *)position padding:(float)padding
{
    int count = [self elementCount];
    int i;
    NSPoint points[3];
    NSPoint startPoint;
    NSPoint currentPoint;
    int element;
    BOOL needANewStartPoint;

    if (count == 0)
        return 0;

    element = [self elementAtIndex:0 associatedPoints:points];
    if (element != NSMoveToBezierPathElement) {
        return 0;  // must start with a moveTo
    }

    startPoint = currentPoint = points[0];
    needANewStartPoint = NO;
    
    for(i=1;i<count;i++) {
        element = [self elementAtIndex:i associatedPoints:points];
        if (NSEqualPoints(points[0], point)) {
            if (i==0) {
                i = 1;
            }
            return i;
        }
        switch(element) {
            case NSMoveToBezierPathElement:
                currentPoint = points[0];
                if (needANewStartPoint) {
                    startPoint = currentPoint;
                    needANewStartPoint = NO;
                }
                break;
            case NSClosePathBezierPathElement:
                if ([self _straightLineHit:currentPoint :startPoint :point :position padding:padding]){
                    return i;
                }
                currentPoint = startPoint;
                needANewStartPoint = YES;
                break;
            case NSLineToBezierPathElement:
                if ([self _straightLineHit:currentPoint :points[0] :point :position padding:padding]){
                    return i;
                }
                currentPoint = points[0];
                break;
            case NSCurveToBezierPathElement:
                if ([self _curvedLineHit:point startPoint:currentPoint endPoint:points[2] controlPoint1:points[0] controlPoint2:points[1] position:position padding:padding]) {
                    return i;
                }
                currentPoint = points[2];
                break;
        }
    }
    return 0;
}

- (NSPoint)_endPointForSegment:(int)i {
    NSPoint points[3];
    int element = [self elementAtIndex:i associatedPoints:points];
    switch(element) {
        case NSCurveToBezierPathElement:
            return points[2];
        case NSClosePathBezierPathElement:
            element = [self elementAtIndex:0 associatedPoints:points];
        case NSMoveToBezierPathElement:
        case NSLineToBezierPathElement:
            return points[0];
    }
    return NSZeroPoint;
}


@end

#if defined(DEBUG) || defined(COVERAGE) || defined(TEST_INTERNAL_FUNCTIONS)

#define INTERSECTION_EPSILON 1e-5

void checkAtPoint(NSPoint p0, NSPoint p1, double t, NSPoint p)
{
    double tfrom1 = 1 - t;
    
    OBASSERT(t >= 0);
    OBASSERT(t <= 1);
    
    float px = tfrom1 * p0.x + t * p1.x;
    float py = tfrom1 * p0.y + t * p1.y;
    
    if ((fabs(px - p.x) >= INTERSECTION_EPSILON) || (fabs(py - p.y) >= INTERSECTION_EPSILON))
        NSLog(@"   Intersection point t=%g  (%g,%g)   expecting (%g,%g)  delta=(%g,%g)", t, px, py, p.x, p.y, px - p.x, py - p.y);

    OBASSERT(fabs(px - p.x) < INTERSECTION_EPSILON);
    OBASSERT(fabs(py - p.y) < INTERSECTION_EPSILON);
}

void checkOneLineLineIntersection(NSPoint p00, NSPoint p01, NSPoint p10, NSPoint p11, NSPoint intersection)
{
    NSPoint l1[2], l2[2];
    struct intersectionInfo r;
    
    _parameterizeLine(l1, p00, p01);
    _parameterizeLine(l2, p10, p11);
    
    r = (struct intersectionInfo){ -1, -1, -1, -1 };
    
    OBASSERT(intersectionsBetweenLineAndLine(l1, l2, &r) == 1);    
    OBASSERT(r.leftParameterDistance == 0);
    OBASSERT(r.rightParameterDistance == 0);
    checkAtPoint(p00, p01, r.leftParameter, intersection);
    checkAtPoint(p10, p11, r.rightParameter, intersection);
}

void checkOneLineLineOverlap(NSPoint p00, NSPoint p01, NSPoint p10, NSPoint p11, NSPoint intersectionStart, NSPoint intersectionEnd)
{
    NSPoint l1[2], l2[2];
    struct intersectionInfo r;
    
    _parameterizeLine(l1, p00, p01);
    _parameterizeLine(l2, p10, p11);
    
    r = (struct intersectionInfo){ -1, -1, -1, -1 };
    
    OBASSERT(intersectionsBetweenLineAndLine(l1, l2, &r) == 1);    
    OBASSERT(r.leftParameterDistance >= 0);  // rightParameterDistance may be negative, but leftParameterDistance should always be positive the way we've defined it
    checkAtPoint(p00, p01, r.leftParameter, intersectionStart);
    checkAtPoint(p10, p11, r.rightParameter, intersectionStart);
    checkAtPoint(p00, p01, r.leftParameter + r.leftParameterDistance, intersectionEnd);
    checkAtPoint(p10, p11, r.rightParameter + r.rightParameterDistance, intersectionEnd);
}

void linesShouldNotIntersect(float x00, float y00, float x01, float y01, float x10, float y10, float x11, float y11)
{
    NSPoint l1[2], l2[2];
    struct intersectionInfo r[1];

    // Both lines forward
    _parameterizeLine(l1, (NSPoint){x00, y00}, (NSPoint){x01, y01});
    _parameterizeLine(l2, (NSPoint){x10, y10}, (NSPoint){x11, y11});
    OBASSERT(intersectionsBetweenLineAndLine(l1, l2, r) == 0);
    OBASSERT(intersectionsBetweenLineAndLine(l2, l1, r) == 0);

    // l1 forward, l2 reverse
    _parameterizeLine(l2, (NSPoint){x11, y11}, (NSPoint){x10, y10});
    OBASSERT(intersectionsBetweenLineAndLine(l1, l2, r) == 0);
    OBASSERT(intersectionsBetweenLineAndLine(l2, l1, r) == 0);

    // Both lines reverse
    _parameterizeLine(l1, (NSPoint){x01, y01}, (NSPoint){x00, y00});
    OBASSERT(intersectionsBetweenLineAndLine(l1, l2, r) == 0);
    OBASSERT(intersectionsBetweenLineAndLine(l2, l1, r) == 0);

    // l1 reverse, l2 forward
    _parameterizeLine(l2, (NSPoint){x10, y10}, (NSPoint){x11, y11});
    OBASSERT(intersectionsBetweenLineAndLine(l1, l2, r) == 0);
    OBASSERT(intersectionsBetweenLineAndLine(l2, l1, r) == 0);
}

void linesDoIntersect(float x00, float y00, float x01, float y01, float x10, float y10, float x11, float y11, float xi, float yi)
{
    NSPoint p00 = { x00, y00 };
    NSPoint p01 = { x01, y01 };
    NSPoint p10 = { x10, y10 };
    NSPoint p11 = { x11, y11 };
    NSPoint i = { xi, yi };

    checkOneLineLineIntersection(p00, p01, p10, p11, i); 
    checkOneLineLineIntersection(p00, p01, p11, p10, i); 
    checkOneLineLineIntersection(p01, p00, p10, p11, i); 
    checkOneLineLineIntersection(p01, p00, p11, p10, i); 
}

void linesDoOverlap(float x00, float y00, float x01, float y01, float x10, float y10, float x11, float y11, float xi0, float yi0, float xi1, float yi1)
{
    NSPoint p00 = { x00, y00 };
    NSPoint p01 = { x01, y01 };
    NSPoint p10 = { x10, y10 };
    NSPoint p11 = { x11, y11 };
    NSPoint i0  = { xi0, yi0 };
    NSPoint i1  = { xi1, yi1 };
    
    checkOneLineLineOverlap(p00, p01, p10, p11, i0, i1); 
    checkOneLineLineOverlap(p00, p01, p11, p10, i0, i1); 
    checkOneLineLineOverlap(p01, p00, p10, p11, i1, i0); 
    checkOneLineLineOverlap(p01, p00, p11, p10, i1, i0); 
}

void testLineLineIntersections(void)
{
    // Oblique misses, all permutations of pdet/vdet/p'det
    linesShouldNotIntersect(2, 2, 4, 4, 0, 3.5, 3,   3.9);
    linesShouldNotIntersect(2, 2, 4, 4, 0, 3.5, 4.7, 4.2);
    linesShouldNotIntersect(2, 2, 4, 4, 0, 3.5, 1.7, 1.9);
    linesShouldNotIntersect(2, 2, 4, 4, 0, 3.5, 2.3, 0.6);
    linesShouldNotIntersect(2, 2, 4, 4, 4.7, 4.2, 5.8, 5.0);
    linesShouldNotIntersect(2, 2, 4, 4, 2.3, 0.6, 3.1, -0.8);
    
    // Parallel and collinear nonintersecting lines
    linesShouldNotIntersect(2, 2, 4, 4, 3, 2, 5, 4);
    linesShouldNotIntersect(2, 2, 4, 4, 5, 5, 6, 6);

    // Zero-length lines (that don't intersect)
    linesShouldNotIntersect(2, 2, 4, 4, 3, 3.5, 3, 3.5);
    linesShouldNotIntersect(2, 2, 4, 4, 5, 5, 5, 5);
    linesShouldNotIntersect(2, 2, 2, 2, 5, 5, 5, 5);

    // Intersection
    linesDoIntersect(2, 2, 4, 4, 2, 4, 4, 2, 3, 3);               // X-shape
    linesDoIntersect(2, 2, 4, 4, 2, 4, 4, 4, 4, 4);               // V-shape (touching at one end)
    linesDoIntersect(2, 2, 4, 6, 3, 4, 4, 2, 3, 4);               // T-shape
    // Again, with less-round numbers
    linesDoIntersect(1.2, 3.9, -1.16, 17.3, 0, 0, -0.001, 25, -0.000428564,10.716);  // X-shape
    linesDoIntersect(0, 0, 0, 1, 0, 0.01, 1, 0, 0, 0.01); // T-ish shape
    linesDoIntersect(0, 0, 1, 100, 0.01, 1, 10, 1, 0.01, 1);
    linesDoIntersect(0, 0, 1, 100, -1, 1, 10, 1, 0.01, 1);
    
    // Collinear intersecting lines
    linesDoOverlap(2, 2, 4, 6, 3, 4, 5, 8, 3, 4, 4, 6);           // two lines with an overlap in the middle
    linesDoOverlap(4, 6, 2, 2, 3, 4, 3.5, 5, 3.5, 5, 3, 4);       // one line fully contained by the other
    linesDoOverlap(1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4);           // same line
    
    // A line touching a zero-length line
    linesDoOverlap(1, 2, 3, 4, 2, 3, 2, 3, 2, 3, 2, 3);
    // A point and its dog^H^H^H^Helf
    linesDoOverlap(8, 3, 8, 3, 8, 3, 8, 3, 8, 3, 8, 3);
}

#define CURVEMATCH_EPSILON INTERSECTION_EPSILON
void checkOneLineCurve(const NSPoint *cparams, const NSPoint *lparams, int count, const NSPoint *i)
{
    struct intersectionInfo r[3];
    int ix;
    
    for(ix = 0; ix < 3; ix++) {
        r[ix] = (struct intersectionInfo){ -1, -1, -1, -1 };
    }
    
    ix = intersectionsBetweenCurveAndLine(cparams, lparams, r);
    OBASSERT(ix == count);
    
    for(ix = 0; ix < count; ix++) {
        OBASSERT(r[ix].leftParameter >= -EPSILON);
        OBASSERT(r[ix].leftParameter <= 1+EPSILON);
        OBASSERT(r[ix].rightParameter >= -EPSILON);
        OBASSERT(r[ix].rightParameter <= 1+EPSILON);
        OBASSERT(r[ix].leftParameterDistance == 0);
        OBASSERT(r[ix].rightParameterDistance == 0);
        NSPoint curvepos, linepos;
        double t = r[ix].leftParameter;
        curvepos.x = cparams[0].x + cparams[1].x * t + cparams[2].x * t * t + cparams[3].x * t * t * t;
        curvepos.y = cparams[0].y + cparams[1].y * t + cparams[2].y * t * t + cparams[3].y * t * t * t;
        linepos.x = lparams[0].x + r[ix].rightParameter * lparams[1].x;
        linepos.y = lparams[0].y + r[ix].rightParameter * lparams[1].y;
        
        if (fabs(i[ix].x - curvepos.x) > CURVEMATCH_EPSILON ||
            fabs(i[ix].y - curvepos.y) > CURVEMATCH_EPSILON ||
            fabs(i[ix].x - linepos.x) > CURVEMATCH_EPSILON ||
            fabs(i[ix].y - linepos.y) > CURVEMATCH_EPSILON ||
            fabs(linepos.x - curvepos.x) > CURVEMATCH_EPSILON ||
            fabs(linepos.y - curvepos.y) > CURVEMATCH_EPSILON) {
            NSLog(@"  Target point (%g,%g)   Curve t=%g (%g,%g)    Line t=%g (%g,%g)",
                  i[ix].x, i[ix].y, r[ix].leftParameter, curvepos.x, curvepos.y, r[ix].rightParameter, linepos.x, linepos.y);
            OBASSERT(0);
        }
    }
}

void checkLineCurve(const NSPoint *c, const NSPoint *l, int count, NSPoint i1, NSPoint i2, NSPoint i3)
{
    NSPoint cparams[4];
    NSPoint lparams[2];
    NSPoint intersections[3], rev_intersections[3];
    
    intersections[0] = i1;
    intersections[1] = i2;
    intersections[2] = i3;
    
    // NSLog(@"Expecting %d intersections...", count);
    
    if (count > 0)
        rev_intersections[0] = intersections[count - 1];
    if (count > 1)
        rev_intersections[1] = intersections[count - 2];
    if (count > 2)
        rev_intersections[2] = intersections[count - 3];
    
    _parameterizeCurve(cparams, c[0], c[3], c[1], c[2]);
    _parameterizeLine(lparams, l[0], l[1]);
    checkOneLineCurve(cparams, lparams, count, intersections);
    
    _parameterizeLine(lparams, l[1], l[0]);
    checkOneLineCurve(cparams, lparams, count, intersections);

    _parameterizeCurve(cparams, c[3], c[0], c[2], c[1]);
    checkOneLineCurve(cparams, lparams, count, rev_intersections);
    
    _parameterizeLine(lparams, l[0], l[1]);
    checkOneLineCurve(cparams, lparams, count, rev_intersections);
}

void testLineCurveIntersections(void)
{
    NSPoint l1[2] = { {1, 2}, {2, 6} };
    NSPoint l2[2] = { {1, 2}, {-1, -1} };
    NSPoint l3[2] = { {1, -1}, {1, 1} };
    NSPoint l4[2] = { {1.1, 2.4}, {1.9, 5.6} };
    NSPoint l5[2] = { {1.1, 2.4}, {2.1, 6.4} };
    NSPoint l6[2] = { {-1024, 0}, {1024, 0} };
    NSPoint l7[2] = { {1.5, -2}, {1.5, 0.2} };
    
    // Nonintersecting squiggle
    NSPoint c1[4] = { {1, 3}, {1.5, 4}, {1, 4}, {2, 6.5} };
    checkLineCurve(c1, l1, 0, NSZeroPoint, NSZeroPoint, NSZeroPoint);
    checkLineCurve(c1, l2, 0, NSZeroPoint, NSZeroPoint, NSZeroPoint);
    
    // Bow whose endpoints touch the line's endpoints
    NSPoint c2[4] = { {1,2}, {2,2}, {3,6}, {2,6} };
    checkLineCurve(c2, l1, 2, (NSPoint){1,2}, (NSPoint){2,6}, NSZeroPoint);
    
    // S whose endpoints match the line's endpoints
    NSPoint c3[4] = { {1,2}, {2,2}, {1,6}, {2,6} };
    checkLineCurve(c3, l1, 3, (NSPoint){1,2}, (NSPoint){1.5, 4}, (NSPoint){2,6});
    checkLineCurve(c3, l4, 1, (NSPoint){1.5, 4}, NSZeroPoint, NSZeroPoint);
    checkLineCurve(c3, l5, 2, (NSPoint){1.5, 4}, (NSPoint){2,6}, NSZeroPoint);
    
    // Self-intersecting curve
    NSPoint c4[4] = { {0, 1}, {2, -2}, {2, 2}, {0, -1} };
    checkLineCurve(c4, l3, 2, (NSPoint){1, -0.0962251}, (NSPoint){1, 0.0962251}, NSZeroPoint);
    checkLineCurve(c4, l6, 3, (NSPoint){0.857143, 0}, (NSPoint){1.5, 0}, (NSPoint){0.857143, 0});
    checkLineCurve(c4, l7, 1, (NSPoint){1.5, 0}, NSZeroPoint, NSZeroPoint);  // Osculation (a double root in solveCubic())
    
    // Another S, with carefully-contrived coordinates
    NSPoint c5[4] = { {0,0}, {0,3}, {125,-4}, {125,4} };
    checkLineCurve(c5, l6, 2, (NSPoint){0,0}, (NSPoint){81, 0}, NSZeroPoint);  // One crossing and an osculation (1 single and 1 double root)
    
    NSPoint c6[4] = { {0,0}, {1,0}, {1,0}, {1,1} };
    checkLineCurve(c6, l6, 1, (NSPoint){0,0}, NSZeroPoint, NSZeroPoint);  // A triple root in solveCubic()
}

#endif

void useSymbols(void **a) {
    a[0] = intersectionsBetweenLineAndLine;
    a[1] = intersectionsBetweenCurveAndLine;
    a[2] = intersectionsBetweenCurveAndCurve;
}
