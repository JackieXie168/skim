// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFEnrichedTextReader.h,v 1.13 2004/02/10 04:07:40 kc Exp $

#import <OmniFoundation/OFObject.h>

@class NSData;
@class OFDataCursor, OFRTFGenerator;

@interface OFEnrichedTextReader : OFObject
{
    OFDataCursor *cursor;
    OFRTFGenerator *rtfGenerator;
    BOOL noFill;
}

+ (NSData *)rtfDataFromEnrichedTextCursor:(OFDataCursor *)aCursor;

- initWithDataCursor:(OFDataCursor *)aCursor;
- (OFRTFGenerator *)rtfGenerator;

@end
