// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSMutableString-OFExtensions.h 68913 2005-10-03 19:36:19Z kc $

#import <Foundation/NSString.h>

@interface NSMutableString (OFExtensions)
- (void)replaceAllOccurrencesOfCharactersInSet:(NSCharacterSet *)set withString:(NSString *)replaceString;
- (void)collapseAllOccurrencesOfCharactersInSet:(NSCharacterSet *)set toString:(NSString *)replaceString;

- (BOOL)replaceAllOccurrencesOfString:(NSString *)oldString withString:(NSString *)newString;
- (void)replaceAllLineEndingsWithString:(NSString *)newString;

- (void)appendCharacter:(unichar)aCharacter;
- (void)appendStrings: (NSString *)first, ...;

- (void)removeSurroundingWhitespace;

@end
