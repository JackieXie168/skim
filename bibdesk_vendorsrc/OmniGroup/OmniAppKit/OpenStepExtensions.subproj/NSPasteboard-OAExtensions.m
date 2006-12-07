// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniAppKit/NSPasteboard-OAExtensions.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSPasteboard-OAExtensions.m,v 1.8 2003/01/15 22:51:37 kc Exp $")

@implementation NSPasteboard (OAExtensions)

- (NSData *)dataForType:(NSString *)dataType stripTrailingNull:(BOOL)stripNull;
{
    NSData                     *data;

    if (!dataType)
	return nil;
    if (!(data = [self dataForType:dataType]))
	return nil;
    if (stripNull) {
        const char *bytes;
        int length;

	length = [data length];
	bytes = (const char *)[data bytes];
	if (bytes[length - 1] == '\0')
		data = [data subdataWithRange: NSMakeRange(0, length - 1)];
    }	       

    return data;
}

@end
