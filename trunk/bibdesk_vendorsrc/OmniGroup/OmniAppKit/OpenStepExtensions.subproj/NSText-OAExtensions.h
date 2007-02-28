// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSText-OAExtensions.h 68913 2005-10-03 19:36:19Z kc $

#import <AppKit/NSText.h>

#import <AppKit/NSNibDeclarations.h> // For IBAction

@class OFScratchFile;

#import <OmniAppKit/OAFindControllerTargetProtocol.h>

@interface NSText (OAExtensions) <OAFindControllerTarget, OASearchableContent>
- (IBAction)jumpToSelection:(id)sender;
- (unsigned int)textLength;
- (void)appendTextString:(NSString *)string;
- (void)appendRTFData:(NSData *)data;
- (void)appendRTFDData:(NSData *)data;
- (void)appendRTFString:(NSString *)string;
- (NSData *)textData;
- (NSData *)rtfData;
- (NSData *)rtfdData;
- (void)setRTFData:(NSData *)rtfData;
- (void)setRTFDData:(NSData *)rtfdData;
- (void)setRTFString:(NSString *)string;
- (void)setTextFromString:(NSString *)aString;
- (NSString *)substringWithRange:(NSRange)aRange;
@end
