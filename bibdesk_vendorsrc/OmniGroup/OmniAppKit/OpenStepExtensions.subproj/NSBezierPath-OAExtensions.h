// Copyright 2000-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSBezierPath-OAExtensions.h,v 1.6 2003/01/16 19:57:43 kevin Exp $

#import <AppKit/NSBezierPath.h>

@class NSCountedSet, NSDictionary, NSMutableDictionary;

@interface NSBezierPath (OAExtensions)

- (BOOL)strokesSimilarlyIgnoringEndcapsToPath:(NSBezierPath *)otherPath;
- (NSCountedSet *)countedSetOfEncodedStrokeSegments;

- (BOOL)intersectsRect:(NSRect)rect;
- (BOOL)intersectionWithLine:(NSPoint *)result lineStart:(NSPoint)lineStart lineEnd:(NSPoint)lineEnd;
- (int)segmentHitByPoint:(NSPoint)point padding:(float)padding;
- (int)segmentHitByPoint:(NSPoint)point;  // 0 == no hit, padding == 5
- (BOOL)isStrokeHitByPoint:(NSPoint)point padding:(float)padding;
- (BOOL)isStrokeHitByPoint:(NSPoint)point; // padding == 5

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
