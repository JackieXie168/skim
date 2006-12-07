//
//  BDSKRemoteSource.m
//  Bibdesk
//
//  Created by Michael McCracken on 2/11/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKRemoteSource.h"


@implementation BDSKRemoteSource

// init
- (id)init {
    if (self = [super init]) {
        [self setData:nil];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:[self data] forKey:@"data"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self setData:[coder decodeObjectForKey:@"data"]];
    }
    return self;
}

- (NSMutableDictionary *)data { return [[data retain] autorelease]; }

- (void)setData:(NSMutableDictionary *)aData {
    //NSLog(@"in -setData:, old value of data: %@, changed to: %@", data, aData);
	
    [data release];
    data = [aData copy];
}

- (NSView *)settingsView{
    [NSException raise:NSInternalInconsistencyException format:@"Must implement a complete subclass."];
    return nil;
}

- (void)dealloc {
    [data release];
    [super dealloc];
}

- (void)refresh {
	// unimplemented
}

@end
