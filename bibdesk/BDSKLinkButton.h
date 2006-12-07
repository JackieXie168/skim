//
//  BDSKLinkButton.h
//  
//
//  Created by Michael McCracken on Thu Jul 25 2002.
//  Copyright (c) 2002 Michael McCracken. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface  BDSKLinkButton : NSButton {
    NSString *_link;
    
}

- (void)setLink:(NSString *)link;

@end
