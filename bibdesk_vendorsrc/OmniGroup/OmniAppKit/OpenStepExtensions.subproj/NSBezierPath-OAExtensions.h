// Copyright 2000-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSBezierPath-OAExtensions.h,v 1.12 2004/02/10 04:07:33 kc Exp $

#import <AppKit/NSBezierPath.h>

@class NSCountedSet, NSDictionary, NSMutableDictionary;

extern void splitBezierCurveTo(NSPoint *c, float t, NSPoint *l, NSPoint *r);

@interface NSBezierPath (OAExtensions)

- (BOOL)strokesSimilarlyIgnoringEndcapsToPath:(NSBezierPath *)otherPath;
- (NSCountedSet *)countedSetOfEncodedStrokeSegments;

- (BOOL)intersectsRect:(NSRect)rect;
- (BOOL)intersectionWithLine:(NSPoint *)result lineStart:(NSPoint)lineStart lineEnd:(NSPoint)lineEnd;
- (NSArray *)intersectionsWithPath:(NSBezierPath *)other; // returns array of positions
- (int)segmentHitByPoint:(NSPoint)point padding:(float)padding;
- (int)segmentHitByPoint:(NSPoint)point;  // 0 == no hit, padding == 5
- (BOOL)isStrokeHitByPoint:(NSPoint)point padding:(float)padding;
- (BOOL)isStrokeHitByPoint:(NSPoint)point; // padding == 5

//
- (void)appendBezierPathWithRoundedRectangle:(NSRect)aRect withRadius:(float)radius;

//
- (NSPoint)getPointForPosition:(float)position andOffset:(float)offset;
- (float)getPositionForPoint:(NSPoint)point;
- (float)getNormalForPosition:(float)position;

// load and save
- (NSMutableDictionary *)propertyListRepresentation;
- (void)loadPropertyListRepresentation:(NSDictionary *)dict;

// NSObject overrides
- (BOOL)isEqual:(NSBezierPath *)otherBezierPath;
- (unsigned int)hash;

@end
