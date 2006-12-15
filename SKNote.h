//
//  SKNote.h

//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/13/06.
//  Copyright 2006 __Michael O. McCrackenName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SKNote : NSObject {
    NSString *quotation;
    NSAttributedString *attributedQuotation;
    NSImage *image;
    NSAttributedString *attributedString;
    
    // location in page:
    unsigned int pageIndex;
    NSString *pageLabel;
    NSPoint locationInPageSpace;
        
}


- (id)initWithPageIndex:(int)newPageIndex locationInPageSpace:(NSPoint)newLocationInPageSpace;

- (id)initWithPageIndex:(int)newPageIndex pageLabel:(NSString *)newPageLabel locationInPageSpace:(NSPoint)newLocationInPageSpace quotation:(NSString *)newQuotation;
    
- (NSString *)quotation;
- (void)setQuotation:(NSString *)newQuotation;
- (NSAttributedString *)attributedQuotation;
- (void)setAttributedQuotation:(NSAttributedString *)newAttributedQuotation;
- (NSAttributedString *)attributedString;
- (void)setAttributedString:(NSAttributedString *)newAttributedString;

- (unsigned int)pageIndex;
- (NSString *)pageLabel;
- (NSPoint)locationInPageSpace;

@end
