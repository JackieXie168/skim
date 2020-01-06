//
//  NSWindow_SKExtensions.m
//  Skim
//
//  Created by Christiaan on 17/11/2018.
/*
 This software is Copyright (c) 2019-2020
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

#import "NSWindow_SKExtensions.h"
#import "NSDocument_SKExtensions.h"
#import "NSString_SKExtensions.h"

@implementation NSWindow (SKExtensions)

+ (void)addTabs:(NSArray *)tabInfos forWindows:(NSArray *)windows {
    if (RUNNING_BEFORE(10_12) || [windows count] < 2)
        return;
    // if windows are opened tabbed, first untab them
    for (NSWindow *window in windows) {
        if ([window respondsToSelector:@selector(moveTabToNewWindow:)] &&
            [[window tabbedWindows] count] > 1)
            [window moveTabToNewWindow:nil];
    }
    if ([windows count] == [tabInfos count])
        return;
    // each item is an array of numbers for the tab windows and a number for the selected window
    for (NSArray *tabInfo in tabInfos) {
        // order is the index in windows
        // index is the index in the tabbed windows
        NSString *tabOrders = [tabInfo firstObject];
        
        if ([tabOrders isKindOfClass:[NSArray class]])
            tabOrders = [[tabOrders description] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
        
        if ([tabOrders isKindOfClass:[NSString class]] == NO || [tabOrders length] < 3) continue;
        
        NSArray *orderStrings = [[tabOrders substringWithRange:NSMakeRange(1, [tabOrders length] - 2)] componentsSeparatedByString:@","];
        
        if ([orderStrings count] < 2) continue;
        
        NSUInteger frontOrder = [[tabInfo lastObject] unsignedIntegerValue];
        NSUInteger frontIndex = NSNotFound, lowestOrder = NSNotFound, lowestIndex = NSNotFound;
        NSWindow *frontWindow = nil;
        NSWindow *window = nil;
        NSPointerArray *tabbedWindows = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality];
        
        for (NSString *orderString in orderStrings) {
            NSUInteger order = (NSUInteger)[orderString integerValue];
            window = order < [windows count] ? [windows objectAtIndex:order] : nil;
            if ([window isEqual:[NSNull null]])
                window = nil;
            if (order == frontOrder) {
                frontIndex = [tabbedWindows count];
                frontWindow = window;
            }
            if (window && order < lowestOrder) {
                lowestOrder = order;
                lowestIndex = [tabbedWindows count];
            }
            [tabbedWindows addPointer:window];
        }
        
        if (frontWindow == nil && frontIndex != NSNotFound) {
            frontIndex = lowestIndex;
            frontWindow = (id)[tabbedWindows pointerAtIndex:frontIndex];
        }
        
        if (frontWindow) {
            NSUInteger i;
            for (i = 0; i < frontIndex; i++) {
                if ((window = (id)[tabbedWindows pointerAtIndex:i]))
                    [frontWindow addTabbedWindow:window ordered:NSWindowBelow];
            }
            for (i = [tabbedWindows count] - 1; i > frontIndex; i--) {
                if ((window = (id)[tabbedWindows pointerAtIndex:i]))
                    [frontWindow addTabbedWindow:window ordered:NSWindowAbove];
            }
            // make sure we select the frontWindow, addTabbedWindow:ordered: sometimes changes it
            if (RUNNING_AFTER(10_12))
                [frontWindow setValue:frontWindow forKeyPath:@"tabGroup.selectedWindow"];
        }
        
        [tabbedWindows release];
    }
}

static inline BOOL isWindowTabSelected(NSWindow *window, NSArray *tabbedWindows) {
    if (RUNNING_AFTER(10_12))
        return [window valueForKeyPath:@"tabGroup.selectedWindow"] == window;
    if ([tabbedWindows count] > 1) {
        NSArray *orderedWindows = [NSApp orderedWindows];
        NSUInteger i = [orderedWindows indexOfObjectIdenticalTo:window];
        for (NSWindow *tabbedWindow in tabbedWindows) {
            NSUInteger j = [orderedWindows indexOfObjectIdenticalTo:tabbedWindow];
            if (i > j)
                return NO;
        }
    }
    return YES;
}

- (NSString *)tabIndexesInWindows:(NSArray *)windows {
    if (RUNNING_AFTER(10_11)) {
        NSArray *tabbedWindows = [self tabbedWindows];
        if ([tabbedWindows count] < 2) {
            return [NSString stringWithFormat:@"(%lu)", (unsigned long)[windows indexOfObjectIdenticalTo:self]];
        } else if (isWindowTabSelected(self, tabbedWindows)) {
            NSMutableString *tabs = [NSMutableString string];
            for (NSWindow *win in tabbedWindows) {
                [tabs appendString:[tabs length] > 0 ? @", " : @"("];
                [tabs appendFormat:@"%lu", (unsigned long)[windows indexOfObjectIdenticalTo:win]];
            }
            [tabs appendString:@")"];
            return tabs;
        }
    }
    return nil;
}

- (void)handleRevertScriptCommand:(NSScriptCommand *)command {
    id document = [[self windowController] document];
    if (document == nil) {
        [command setScriptErrorNumber:NSArgumentsWrongScriptError];
        [command setScriptErrorString:@"Window does not have a document."];
    } else {
        [document handleRevertScriptCommand:command];
    }
}

@end
