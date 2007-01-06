//
//  BDSKCitationFormatter.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 6/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BDSKCitationFormatter : NSFormatter {
    id delegate;
}
- (id)initWithDelegate:(id)aDelegate;
- (id)delegate;
- (void)setDelegate:(id)newDelegate;
@end


@interface NSObject (BDSKCitationFormatterDelegate)
- (BOOL)citationFormatter:(BDSKCitationFormatter *)formatter isValidKey:(NSString *)key;
@end
