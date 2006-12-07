// Copyright 1997-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>

@class NSView;
@class NSString;
@class OFRegularExpression;

@protocol OAFindPattern <NSObject>
- (BOOL)findInString:(NSString *)aString foundRange:(NSRangePointer)rangePtr;
- (BOOL)findInRange:(NSRange)range ofString:(NSString *)aString foundRange:(NSRangePointer)rangePtr;

- (void)setReplacementString:(NSString *)aString;
- (NSString *)replacementStringForLastFind;
@end

@protocol OAFindControllerTarget
- (BOOL)findPattern:(id <OAFindPattern>)pattern backwards:(BOOL)backwards wrap:(BOOL)wrap;
@end

@interface NSObject (OAOptionalSelectedStringForFinding)
- (NSString *)selectedString;
@end

@interface NSObject (OAOptionalReplacement)
- (void)replaceSelectionWithString:(NSString *)aString;
- (void)replaceAllOfPattern:(id <OAFindPattern>)pattern;
@end

@interface NSObject (OAFindControllerAware)
- (id <OAFindControllerTarget>)omniFindControllerTarget;
@end

@protocol OASearchableContent
- (BOOL)findPattern:(id <OAFindPattern>)pattern backwards:(BOOL)backwards ignoreSelection:(BOOL)ignoreSelection;
@end

@interface NSObject (OAOptionalSearchableCellProtocol)
- (NSView <OASearchableContent> *)searchableContentView;
@end
