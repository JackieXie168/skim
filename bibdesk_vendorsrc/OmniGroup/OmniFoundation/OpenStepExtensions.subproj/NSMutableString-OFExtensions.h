// Copyright 1997-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSMutableString-OFExtensions.h 79079 2006-09-07 22:35:32Z kc $

#import <Foundation/NSString.h>

@interface NSMutableString (OFExtensions)
- (void)replaceAllOccurrencesOfCharactersInSet:(NSCharacterSet *)set withString:(NSString *)replaceString;
- (void)collapseAllOccurrencesOfCharactersInSet:(NSCharacterSet *)set toString:(NSString *)replaceString;

- (BOOL)replaceAllOccurrencesOfString:(NSString *)oldString withString:(NSString *)newString;
- (void)replaceAllLineEndingsWithString:(NSString *)newString;

- (void)appendCharacter:(unsigned int)aCharacter;
- (void)appendStrings: (NSString *)first, ...;

- (void)removeSurroundingWhitespace;

@end
