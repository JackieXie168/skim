// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSText-OAExtensions.h,v 1.11 2003/01/15 22:51:38 kc Exp $

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
