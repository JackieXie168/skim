// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSMutableData-OFExtensions.h,v 1.10 2004/02/10 04:07:45 kc Exp $

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
