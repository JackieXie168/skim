// Copyright 2002-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSAppleScript-OAExtensions.h 68913 2005-10-03 19:36:19Z kc $

#import <Foundation/NSObject.h> // defines MAC_OS_X_VERSION_10_2 for us if we're on 10.2.

#ifdef MAC_OS_X_VERSION_10_2

#import <Foundation/NSAppleScript.h>

@class NSAppleEventDescriptor, NSArray, NSData;
@class NSAttributedString;

@interface NSAppleScript (OAExtensions)

- (id)initWithData:(NSData *)data error:(NSDictionary **)errorInfo;
- (NSData *)compiledData;

+ (NSAttributedString *)attributedStringFromScriptResult:(NSAppleEventDescriptor *)descriptor;

// Reads AppleScript's source formatting settings; styleNumber should be one of the constants from AppleScript.h.
+ (NSDictionary *)stringAttributesForAppleScriptStyle:(int)styleNumber;
    // Only includes attributes applicable to the underlying AppleScript implementation (NSFontAttributeName, NSForegroundColorAttributeName, and NSUnderlineStyleAttributeName).

@end

#endif
