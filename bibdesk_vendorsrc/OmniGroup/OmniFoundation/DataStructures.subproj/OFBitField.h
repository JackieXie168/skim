// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFBitField.h 68913 2005-10-03 19:36:19Z kc $

#import <OmniFoundation/OFObject.h>

@class NSData, NSMutableData, NSNumber, NSString;

@interface OFBitField : OFObject
{
    NSMutableData *data;
    // This ivar stores the actual bitfield data (as it is returned from Sybase, for example).
}

- initWithLength:(unsigned int)newLength;
    // Initializes the newly alloc'ed instance to be of length newLength.

- initWithData:(NSData *)someData type:(NSString *)string;
    // Initializes the new instance with someData and type string. This method is used internally by EOF and should not be called externally.

- (NSData *)dataForType:(NSString *)typeString;
    // Returns an NSData representation of data in typeString format. This method is used internally by EOF and is not intended for public use.

- (NSNumber *)valueAtIndex:(unsigned int)anIndex;
    // Returns the value stored at position index in the bit field.
- (void)setValue:(NSNumber *)aBooleanNumber atIndex:(unsigned int)anIndex;
    // Sets the value of the bit field to aBooleanNumber at position index.
- (BOOL)boolValueAtIndex:(unsigned int)anIndex;
    // Returns the value stored at position index in the bit field.
- (void)setBoolValue:(BOOL)aBool atIndex:(unsigned int)anIndex;
    // Sets the value of the bit field to aBool at position index.
- (unsigned int)length;
    // Returns the number of positions in the receiver.
- (void)setLength:(unsigned)aLength;
    // Sets the number of positions in the receiver. Added positions are initially set to NO.
- copy;
    // Returns a mutable copy of the receiver.
- (BOOL)isEqual:(id)anObject;
    // Returns YES if anObject is considered equal to the receiver. anObject will be equal if its data and the receiver's data ivars are equal.
- (BOOL)isEqualToBitField:(OFBitField *)aBitField;
    // Returns YES if aBitField is considered equal to the receiver. aBitField is assumed to be an instance of OFBitField, so be sure to pass an OFBitField if you're calling this method. If you're not sure what you have, call isEqual:.

- (unsigned int) firstBitSet;
    // Returns the index of the first bit that is set.  If no bit is set, returns NSNotFound.

- (unsigned int) numberOfBitsSet;
    // Returns the total count of the bits set

- (void)resetBitsTo:(BOOL)aBool;
    // Sets the whole field to the value of aBool.

- (NSData *)deltaValue:(OFBitField *)aBitField;
    // If the receiver differs from aBitField, returns an NSData that contains the xor of the values of the two objects at each index.
    //
    // PRECONDITION(aBitField != nil);
    // PRECONDITION([aBitField isKindOfClass:[OFBitField class]]);
    // PRECONDITION([aBitField length] == [self length]);


- (void)andWithData:(NSData *)aData;
    // Changes bits i the receiver to be the logical and of bit i in the receiver and bit i of aData for all valid i.
    //
    // PRECONDITION(data && [data length] == [aData length]);

- (void)orWithData:(NSData *)data;
    // Changes bits i the receiver to be the logical or of bit i in the receiver and bit i of aData for all valid i.
    //
    // PRECONDITION(data && [data length] == [aData length]);

- (void)xorWithData:(NSData *)data;
    // Changes bits i the receiver to be the logical xor of bit i in the receiver and bit i of aData for all valid i.
    //
    // PRECONDITION(data && [data length] == [aData length]);

@end
