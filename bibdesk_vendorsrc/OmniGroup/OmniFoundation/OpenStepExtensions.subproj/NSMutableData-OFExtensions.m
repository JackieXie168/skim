// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSMutableData-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSMutableData-OFExtensions.m 66170 2005-07-28 17:40:10Z kc $")

@implementation NSMutableData (OFExtensions)

/* TODO: These should really use word operators as much as possible */

- (void) andWithData: (NSData *) aData;
{
    unsigned char              *bytes;
    const unsigned char        *otherBytes;
    unsigned long               length;

    OBPRECONDITION(aData);
    OBPRECONDITION([self length] == [aData length]);

    length = [self length];
    bytes = (unsigned char *)[self mutableBytes];
    otherBytes = (const unsigned char *)[aData bytes];

    while (length--)
	*bytes++ &= *otherBytes++;
}


- (void) orWithData: (NSData *) aData;
{
    unsigned char              *bytes;
    const unsigned char        *otherBytes;
    unsigned long               length;

    OBPRECONDITION(aData);
    OBPRECONDITION([self length] == [aData length]);

    length = [self length];
    bytes = (unsigned char *)[self mutableBytes];
    otherBytes = (const unsigned char *)[aData bytes];

    while (length--)
	*bytes++ |= *otherBytes++;
}


- (void) xorWithData: (NSData *) aData;
{
    unsigned char              *bytes;
    const unsigned char        *otherBytes;
    unsigned long               length;

    OBPRECONDITION(aData);
    OBPRECONDITION([self length] == [aData length]);

    length = [self length];
    bytes = (unsigned char *)[self mutableBytes];
    otherBytes = (const unsigned char *)[aData bytes];

    while (length--)
	*bytes++ ^= *otherBytes++;
}

- (void)appendString:(NSString *)aString encoding:(NSStringEncoding)anEncoding;
{
    CFStringRef cfString = (CFStringRef)aString;
    CFStringEncoding cfEncoding = CFStringConvertNSStringEncodingToEncoding(anEncoding);
    
    const char *encoded = CFStringGetCStringPtr(cfString, cfEncoding);
    if (encoded) {
        [self appendBytes:encoded length:strlen(encoded)];
        return;
    } else {
        CFDataRef block = CFStringCreateExternalRepresentation(kCFAllocatorDefault, cfString, cfEncoding, 0);
        if (block) {
            [self appendData:(NSData *)block];
            CFRelease(block);
            return;
        }
    }
    
    [NSException raise:NSInvalidArgumentException format:@"Cannot convert string to bytes with specified encoding"];
}

@end
