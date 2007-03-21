//
//  NSWindowController_BDSKExtensions.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 9/4/06.
/*
 This software is Copyright (c) 2006,2007
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

#import "NSWindowController_BDSKExtensions.h"


@interface NSWindow (BDSKExtensions)
- (void)replacementSetRepresentedFilename:(NSString *)path;
@end


@implementation NSWindowController (BDSKExtensions)

- (BOOL)isWindowVisible;
{
    return [self isWindowLoaded] && [[self window] isVisible];
}

- (IBAction)hideWindow:(id)sender{
	[[self window] close];
}

- (IBAction)toggleShowingWindow:(id)sender{
    if([self isWindowVisible]){
		[self hideWindow:sender];
    }else{
		[self showWindow:sender];
    }
}

// we should only cascade windows if we have multiple documents open; bug #1299305
// the default cascading does not reset the next location when all windows have closed, so we do cascading ourselves
- (void)setWindowFrameAutosaveNameOrCascade:(NSString *)name {
    [self setWindowFrameAutosaveNameOrCascade:name setFrame:NSZeroRect];
}

- (void)setWindowFrameAutosaveNameOrCascade:(NSString *)name setFrame:(NSRect)frameRect {
    static NSMutableDictionary *nextWindowLocations = nil;
    if (nextWindowLocations == nil)
        nextWindowLocations = [[NSMutableDictionary alloc] init];
    
    NSValue *value = [nextWindowLocations objectForKey:name];
    NSPoint point = [value pointValue];
    
    if (NSEqualRects(frameRect, NSZeroRect) == NO) {
        [[self window] setFrameAutosaveName:name];
        [[self window] setFrame:frameRect display:YES];
        [self setShouldCascadeWindows:NO];
        point = NSMakePoint(NSMinX(frameRect), NSMaxY(frameRect));
    } else {
        // Set the frame from prefs first, or setFrameAutosaveName: will overwrite the prefs with the nib values if it returns NO
        [[self window] setFrameUsingName:name];
        [self setShouldCascadeWindows:NO];
        if ([[self window] setFrameAutosaveName:name] || value == nil) {
            frameRect = [[self window] frame];
            point = NSMakePoint(NSMinX(frameRect), NSMaxY(frameRect));
        }
    }
    point = [[self window] cascadeTopLeftFromPoint:point];
    [nextWindowLocations setObject:[NSValue valueWithPoint:point] forKey:name];
}

@end


@implementation NSWindow (BDSKExtensions)

static IMP originalSetRepresentedFilename;

+ (void)didLoad;
{
    originalSetRepresentedFilename = OBReplaceMethodImplementationWithSelector(self, @selector(setRepresentedFilename:), @selector(replacementSetRepresentedFilename:));
}

// see bug #1471488; overriding representedFilename is not sufficient; apparently the window doesn't use its accessor
- (void)replacementSetRepresentedFilename:(NSString *)path;
{
    id delegate = [self delegate];
    if (delegate && [delegate respondsToSelector:@selector(representedFilenameForWindow:)]) {
        NSString *newPath = [delegate representedFilenameForWindow:self];
        // if it returns nil, use the path we were passed
        if (newPath) 
            path = newPath;
    }
    originalSetRepresentedFilename(self, _cmd, path);
}

@end
