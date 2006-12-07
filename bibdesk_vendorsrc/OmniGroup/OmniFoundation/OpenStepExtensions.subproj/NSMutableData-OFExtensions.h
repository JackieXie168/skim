// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSMutableData-OFExtensions.h,v 1.8 2003/01/15 22:52:00 kc Exp $

#import <Foundation/NSData.h>

@interface NSMutableData (OFExtensions)

- (void) andWithData: (NSData *) aData;
/*.doc.
Sets each byte of the receiver to be the bitwise and of that byte and the corresponding byte in aData.

PRECONDITION(aData);
PRECONDITION([self length] == [aData length]);
*/

- (void) orWithData: (NSData *) aData;
/*.doc.
Sets each byte of the receiver to be the bitwise and of that byte and the corresponding byte in aData.

PRECONDITION(aData);
PRECONDITION([self length] == [aData length]);
*/


- (void) xorWithData: (NSData *) aData;
/*.doc.
Sets each byte of the receiver to be the bitwise and of that byte and the corresponding byte in aData.

PRECONDITION(aData);
PRECONDITION([self length] == [aData length]);
*/

@end
