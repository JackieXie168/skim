//
//  SKFindController.m
//  Skim
//
//  Created by Christiaan Hofman on 16/2/07.
/*
 This software is Copyright (c) 2007-2011
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

#import "SKFindController.h"
#import "SKFindFieldEditor.h"
#import "SKStringConstants.h"
#import "SKGradientView.h"
#import "NSGeometry_SKExtensions.h"
#import "NSSegmentedControl_SKExtensions.h"
#import "NSMenu_SKExtensions.h"


@implementation SKFindController

@synthesize delegate, findField, messageField, doneButton, navigationButton, ownerController, findString;
@dynamic fieldEditor;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SKDESTROY(findString);
    SKDESTROY(fieldEditor);
    SKDESTROY(findField);
    SKDESTROY(messageField);
    SKDESTROY(ownerController);
    SKDESTROY(doneButton);
    SKDESTROY(navigationButton);
    [super dealloc];
}

- (NSString *)nibName {
    return @"FindBar";
}

- (void)loadView {
    [super loadView];
    
    SKGradientView *gradientView = (SKGradientView *)[self view];
    NSSize size = [gradientView frame].size;
    CGFloat dx1 = NSWidth([doneButton frame]);
    CGFloat dx2 = NSWidth([messageField frame]);
    [doneButton sizeToFit];
    [messageField sizeToFit];
    dx1 -= NSWidth([doneButton frame]);
    dx2 -= NSWidth([messageField frame]);
    size.width -= dx1 + dx2;
    [gradientView setFrameSize:size];
    SKShiftAndResizeViews([NSArray arrayWithObjects:doneButton, nil], dx1, 0.0);
    SKShiftAndResizeViews([NSArray arrayWithObjects:navigationButton, findField, nil], -dx2, 0.0);
    SKShiftAndResizeViews([NSArray arrayWithObjects:findField, nil], 0.0, dx1 + dx2);
    
    gradientView = (SKGradientView *)[self view];
    [gradientView setEdges:SKMinYEdgeMask];
    [gradientView setClipEdges:SKMinXEdgeMask | SKMaxYEdgeMask];
    size = [gradientView contentRect].size;
    [gradientView setMinSize:size];
    size.width = 500.0;
    [gradientView setMaxSize:size];
    [gradientView setGradient:[[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.82 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.914 alpha:1.0]] autorelease]];
    [gradientView setAlternateGradient:nil];
    
    NSMenu *menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
    [menu addItemWithTitle:NSLocalizedString(@"Ignore Case", @"Menu item title") action:@selector(toggleCaseInsensitiveFind:) target:self];
    [[findField cell] setSearchMenuTemplate:menu];
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    NSPasteboard *findPboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    if (lastChangeCount < [findPboard changeCount] && [findPboard availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]]) {
        [self setFindString:[findPboard stringForType:NSStringPboardType]];
        lastChangeCount = [findPboard changeCount];
    }
}

- (void)updateFindPboard {
    NSPasteboard *findPboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    [findPboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [findPboard setString:findString forType:NSStringPboardType];
    lastChangeCount = [findPboard changeCount];
}

- (void)endAnimation:(NSNumber *)visible {
    NSWindow *window = [[self view] window];
    if ([visible boolValue] == NO)
		[[self view] removeFromSuperview];
    [window recalculateKeyViewLoop];
    animating = NO;
}

- (void)toggleAboveView:(NSView *)view animate:(BOOL)animate {
    if (animating)
        return;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableAnimationsKey])
        animate = NO;
    
    if (view == nil) {
        NSArray *subviews = [[[self view] superview] subviews];
        if ([subviews count] == 2)
            view = [subviews objectAtIndex:([subviews objectAtIndex:0] == [self view] ? 1 : 0)];
        else
            return;
    }
    
	NSRect viewFrame = [view frame];
	NSView *contentView = [view superview];
	NSRect barRect = [view frame];
	CGFloat barHeight = NSHeight([[self view] frame]);
    BOOL visible = (nil == [[self view] superview]);
    NSTimeInterval duration;
    
	barRect.size.height = barHeight;
	
	if (visible) {
		if ([contentView isFlipped])
            barRect.origin.y -= barHeight;
		else
			barRect.origin.y = NSMaxY([contentView bounds]);
        [[self view] setFrame:barRect];
		[contentView addSubview:[self view] positioned:NSWindowBelow relativeTo:nil];
        barHeight = -barHeight;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:[[self view] window]];
        [self windowDidBecomeKey:nil];
    } else {
		if ([contentView isFlipped])
            barRect.origin.y -= barHeight;
		else
			barRect.origin.y = NSMaxY([contentView bounds]) - barHeight;
        if ([[self view] window])
            [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:[[self view] window]];
    }
    viewFrame.size.height += barHeight;
    if ([contentView isFlipped]) {
        viewFrame.origin.y -= barHeight;
        barRect.origin.y -= barHeight;
    } else {
        barRect.origin.y += barHeight;
    }
    [messageField setHidden:YES];
    if (animate) {
        animating = YES;
        [NSAnimationContext beginGrouping];
        duration = 0.5 * [[NSAnimationContext currentContext] duration];
        [[NSAnimationContext currentContext] setDuration:duration];
        [[view animator] setFrame:viewFrame];
        [[[self view] animator] setFrame:barRect];
        [NSAnimationContext endGrouping];
        [self performSelector:@selector(endAnimation:) withObject:[NSNumber numberWithBool:visible] afterDelay:duration];
    } else {
        [view setFrame:viewFrame];
        if (visible)
            [[self view] setFrame:barRect];
        else
            [[self view] removeFromSuperview];
        [[contentView window] recalculateKeyViewLoop];
    }
}

- (void)setDelegate:(id <SKFindControllerDelegate>)newDelegate {
    if (delegate && newDelegate == nil)
        [ownerController setContent:nil];
    delegate = newDelegate;
}

- (NSTextView *)fieldEditor {
    if (fieldEditor == nil) {
        fieldEditor = [[SKFindFieldEditor alloc] init];
        [fieldEditor setFieldEditor:YES];
    }
    return fieldEditor;
}

- (void)findWithOptions:(NSStringCompareOptions)backForwardOption {
    [ownerController commitEditing];
    BOOL found = NO;
    if ([findString length]) {
        NSInteger findOptions = [[NSUserDefaults standardUserDefaults] boolForKey:SKCaseInsensitiveFindKey] ? NSCaseInsensitiveSearch : 0;
        found = [delegate findString:findString options:findOptions | backForwardOption];
        [self updateFindPboard];
    }
    [messageField setHidden:found];
}

- (IBAction)find:(id)sender {
    NSStringCompareOptions options = 0;
    if ([sender respondsToSelector:@selector(selectedTag)] && [sender selectedTag] == 0)
        options |= NSBackwardsSearch;
    [self findWithOptions:options];
}

- (IBAction)remove:(id)sender {
    [ownerController commitEditing];
    if ([findString length])
        [self updateFindPboard];
    [self toggleAboveView:nil animate:YES];
}

- (IBAction)toggleCaseInsensitiveFind:(id)sender {
    BOOL caseInsensitive = [[NSUserDefaults standardUserDefaults] boolForKey:SKCaseInsensitiveFindKey];
    [[NSUserDefaults standardUserDefaults] setBool:NO == caseInsensitive forKey:SKCaseInsensitiveFindKey];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(toggleCaseInsensitiveFind:)) {
        [menuItem setState:[[NSUserDefaults standardUserDefaults] boolForKey:SKCaseInsensitiveFindKey] ? NSOnState : NSOffState];
        return YES;
    }
    return YES;
}

@end
