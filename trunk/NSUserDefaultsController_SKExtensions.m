//
//  NSUserDefaultsController_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/24/07.
/*
 This software is Copyright (c) 2007
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSUserDefaultsController_SKExtensions.h"


@implementation NSUserDefaultsController (SKExtensions)

- (void)addObserver:(NSObject *)anObserver forKey:(NSString *)key {
    [self addObserver:anObserver forKeyPath:[NSString stringWithFormat:@"values.%@", key] options:0 context:NULL];
}

- (void)removeObserver:(NSObject *)anObserver forKey:(NSString *)key {
    [self removeObserver:anObserver forKeyPath:[NSString stringWithFormat:@"values.%@", key]];
}

- (void)addObserver:(NSObject *)anObserver forKeys:(NSArray *)keys {
    int i, iMax = [keys count];
    for (i = 0; i < iMax; i++) {
        NSString *keyPath = [NSString stringWithFormat:@"values.%@", [keys objectAtIndex:i]];
        [self addObserver:anObserver forKeyPath:keyPath options:0 context:NULL];
    }
}

- (void)removeObserver:(NSObject *)anObserver forKeys:(NSArray *)keys {
    int i, iMax = [keys count];
    for (i = 0; i < iMax; i++) {
        NSString *keyPath = [NSString stringWithFormat:@"values.%@", [keys objectAtIndex:i]];
        [self removeObserver:anObserver forKeyPath:keyPath];
    }
}

- (void)revertToInitialValueForKey:(NSString *)key {
    [[self values] setValue:[[self initialValues] objectForKey:key] forKey:key];
}

- (void)revertToInitialValuesForKeys:(NSArray *)keys {
    int i, iMax = [keys count];
    for (i = 0; i < iMax; i++) {
        NSString *key = [keys objectAtIndex:i];
        [[self values] setValue:[[self initialValues] objectForKey:key] forKey:key];
    }
}

@end


@implementation NSUserDefaults (SKExtensions)

- (NSColor *)colorForKey:(NSString *)key {
    NSData *data = [self dataForKey:key];
    return data ? [NSUnarchiver unarchiveObjectWithData:data] : nil;
}

- (void)setColor:(NSColor *)color forKey:(NSString *)key {
    NSData *data = color ? [NSArchiver archivedDataWithRootObject:color] : nil;
    return [self setObject:data forKey:key];
}

@end
