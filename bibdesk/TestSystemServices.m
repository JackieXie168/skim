//
//  TestSystemServices.m
//  BibDesk
//
//  Created by Michael McCracken on Sat Jun 14 2003.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "TestSystemServices.h"
#import "BibAppController.h"

@implementation TestSystemServices


- (BOOL)_constraintsFromString:(NSString *)string isEqualToDict:(NSDictionary *)result{
    BibAppController *ac = [NSApp delegate];

    NSDictionary *dict = [ac _constraintsFromString:string];

    return [result isEqual:dict]; 

}


- (void)testConstraintsFromString{
    
    UKEqual([NSDictionary dictionaryWithObjectsAndKeys:@"Optimizing", BDSKTitleString, nil], [self _constraintsFromString:@"Optimizing"]);

    UKEqual([NSDictionary dictionaryWithObjectsAndKeys:@"Foo", BDSKAuthorString, nil],
            [self _constraintsFromString:@"Author: Foo"]);
    
}



@end
