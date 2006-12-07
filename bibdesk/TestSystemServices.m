//
//  TestSystemServices.m
//  Bibdesk
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
    
    should1(([self _constraintsFromString:@"Optimizing"
                          isEqualToDict:[NSDictionary dictionaryWithObjectsAndKeys:@"Optimizing", @"Title", nil]]), @"Title-only constraint parsing");

    should1(([self _constraintsFromString:@"Author: Foo"
                            isEqualToDict:[NSDictionary dictionaryWithObjectsAndKeys:@"Foo", @"Author", nil]]), @"Author: Foo constraint parsing");
    
}



@end
