//
//  NSWindowController_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 3/21/07.
/*
 This software is Copyright (c) 2007-2014
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

#import "NSWindowController_SKExtensions.h"
#import "NSInvocation_SKExtensions.h"
#import "NSPointerArray_SKExtensions.h"


@implementation NSWindowController (SKExtensions)

- (void)setWindowFrameAutosaveNameOrCascade:(NSString *)name {
    static NSMapTable *nextWindowLocations = nil;
    if (nextWindowLocations == nil)
        nextWindowLocations = NSCreateMapTable(NSObjectMapKeyCallBacks, NSOwnedPointerMapValueCallBacks, 0);
    
    NSPointPointer pointPtr = (NSPointPointer)NSMapGet(nextWindowLocations, name);
    NSPoint point;
    
    [[self window] setFrameUsingName:name];
    [self setShouldCascadeWindows:NO];
    if ([[self window] setFrameAutosaveName:name] || pointPtr == NULL) {
        NSRect windowFrame = [[self window] frame];
        point = NSMakePoint(NSMinX(windowFrame), NSMaxY(windowFrame));
    } else {
        point = *pointPtr;
    }
    pointPtr = NSZoneMalloc(NSDefaultMallocZone(), sizeof(NSPoint));
    *pointPtr = [[self window] cascadeTopLeftFromPoint:point];
    NSMapInsert(nextWindowLocations, name, pointPtr);
}


- (BOOL)isNoteWindowController { return NO; }

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	if (contextInfo != NULL) {
        void (^handler)(NSInteger) = (void(^)(NSInteger))contextInfo;
        handler(returnCode);
        Block_release(handler);
    }
}

- (void)beginSheetModalForWindow:(NSWindow *)window completionHandler:(void (^)(NSInteger result))handler {
    
	[self retain]; // make sure we stay around long enough
	
	[NSApp beginSheet:[self window]
	   modalForWindow:window
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:handler ? Block_copy(handler) : NULL];
}

- (IBAction)dismissSheet:(id)sender {
    [NSApp endSheet:[self window] returnCode:[sender tag]];
    [[self window] orderOut:self];
    [self release];
}

@end


@implementation NSWindow (SKLionOverride)
- (BOOL)isRestorable { return NO; }
@end
