// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFMatrix.h,v 1.9 2003/01/15 22:51:54 kc Exp $

#import <OmniFoundation/OFObject.h>

@class NSMutableArray;

@interface OFMatrix : OFObject
{
    NSMutableArray *rows;
    unsigned int rowCount, columnCount;
    NSMutableArray *rowTemplate;
}

- (id)objectAtRowIndex:(unsigned int)rowIndex columnIndex:(unsigned int)columnIndex;
- (void)setObject:(id)anObject atRowIndex:(unsigned int)rowIndex columnIndex:(unsigned int)columnIndex;
- (void)setObject:(id)anObject atRowIndex:(unsigned int)rowIndex span:(unsigned int)rowSpan columnIndex:(unsigned int)columnIndex span:(unsigned int)columnSpan;
- (unsigned int)rowCount;
- (unsigned int)columnCount;
- (void)expandColumnsToCount:(unsigned int)count;
- (void)expandRowsToCount:(unsigned int)count;

@end
