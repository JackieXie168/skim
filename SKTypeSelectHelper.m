//
//  SKTypeSelectHelper.m
//  Skim
//
//  Created by Christiaan Hofman on 8/21/07.
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

#import "SKTypeSelectHelper.h"
#import "SKRuntime.h"
#import "NSString_SKExtensions.h"
#import "NSEvent_SKExtensions.h"

#define SKWindowDidChangeFirstResponderNotification @"SKWindowDidChangeFirstResponderNotification"

#define REPEAT_CHARACTER (unichar)0x2F
#define CANCEL_CHARACTER (unichar)0x1B

@interface NSString (SKTypeAheadHelperExtensions)
- (BOOL)containsStringStartingAtWord:(NSString *)string options:(NSInteger)mask range:(NSRange)range;
@end

#pragma mark -

@interface SKTypeSelectHelper (SKPrivate)
- (void)searchWithEvent:(NSEvent *)keyEvent;
- (void)repeatSearch;
- (void)cancelSearch;
- (BOOL)isSearchEvent:(NSEvent *)keyEvent;
- (BOOL)isRepeatEvent:(NSEvent *)keyEvent;
- (BOOL)isCancelEvent:(NSEvent *)keyEvent;
- (NSTimeInterval)timeoutInterval;
- (NSArray *)searchCache;
- (void)searchWithStickyMatch:(BOOL)allowUpdate;
- (void)stopTimer;
- (void)startTimerForSelector:(SEL)selector;
- (void)typeSelectSearchTimeout:(id)sender;
- (void)typeSelectCleanTimeout:(id)sender;
- (NSUInteger)indexOfMatchedItemAfterIndex:(NSUInteger)selectedIndex;
@end

@implementation SKTypeSelectHelper

@synthesize delegate, matchOption;

static NSCharacterSet *nonAlphanumericCharacterSet = nil;

+ (void)initialize {
    SKINITIALIZE;
    nonAlphanumericCharacterSet = [[[NSCharacterSet alphanumericCharacterSet] invertedSet] copy];
}

+ (id)typeSelectHelper {
    return [[[self alloc] init] autorelease];
}

+ (id)typeSelectHelperWithMatchOption:(SKTypeSelectMatchOption)aMatchOption {
    return [[[self alloc] initWithMatchOption:aMatchOption] autorelease];
}

- (id)initWithMatchOption:(SKTypeSelectMatchOption)aMatchOption {
    self = [super init];
    if (self){
        delegate = nil;
        searchCache = nil;
        searchString = nil;
        matchOption = aMatchOption;
        isProcessing = NO;
        timer = nil;
    }
    return self;
}

- (id)init {
    return [self initWithMatchOption:SKPrefixMatch];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopTimer];
    SKDESTROY(searchString);
    SKDESTROY(searchCache);
    [super dealloc];
}

#pragma mark Accessors

- (void)setDelegate:(id)newDelegate {
    if (delegate != newDelegate) {
        delegate = newDelegate;
        [self rebuildTypeSelectSearchCache];
    }
}

#pragma mark API

- (void)rebuildTypeSelectSearchCache {    
    SKDESTROY(searchCache);
}

- (BOOL)handleEvent:(NSEvent *)keyEvent {
    if ([keyEvent type] != NSKeyDown) {
        return NO;
    } else if ([self isSearchEvent:keyEvent]) {
        [self searchWithEvent:keyEvent];
        return YES;
    } else if ([self isRepeatEvent:keyEvent]) {
        [self repeatSearch];
        return YES;
    } else if ([self isCancelEvent:keyEvent]) {
        [self cancelSearch];
        return YES;
    }
    return NO;
}

#pragma mark Private methods

- (void)searchWithEvent:(NSEvent *)keyEvent {
    NSWindow *keyWin = [NSApp keyWindow];
    NSText *fieldEditor = [keyWin fieldEditor:YES forObject:self];
    
    if (isProcessing == NO) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(typeSelectCleanTimeout:) name:SKWindowDidChangeFirstResponderNotification object:keyWin];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(typeSelectCleanTimeout:) name:NSWindowDidResignKeyNotification object:keyWin];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(typeSelectCleanTimeout:) name:NSWindowWillCloseNotification object:keyWin];
        [fieldEditor setDelegate:self];
        [fieldEditor setString:@""];
    }
    
    // Append the new character to the search string
    [fieldEditor interpretKeyEvents:[NSArray arrayWithObject:keyEvent]];
    [searchString release];
    searchString = [[fieldEditor string] retain];
    
    if ([delegate respondsToSelector:@selector(typeSelectHelper:updateSearchString:)])
        [delegate typeSelectHelper:self updateSearchString:searchString];
    
    // Reset the timer if it hasn't expired yet
    [self startTimerForSelector:@selector(typeSelectSearchTimeout:)];
    
    if (matchOption != SKFullStringMatch)
        [self searchWithStickyMatch:isProcessing];
    
    isProcessing = YES;
}

- (void)repeatSearch {
    [self searchWithStickyMatch:NO];
    
    if ([searchString length] && [delegate respondsToSelector:@selector(typeSelectHelper:updateSearchString:)])
        [delegate typeSelectHelper:self updateSearchString:searchString];
    
    [self startTimerForSelector:@selector(typeSelectCleanTimeout:)];
    
    isProcessing = NO;
}

- (void)cancelSearch {
    if (timer)
        [self typeSelectCleanTimeout:timer];
}

- (BOOL)isSearchEvent:(NSEvent *)keyEvent {
    if ([keyEvent deviceIndependentModifierFlags] & ~NSShiftKeyMask & ~NSAlternateKeyMask & ~NSAlphaShiftKeyMask & ~NSNumericPadKeyMask)
        return NO;
    
    NSCharacterSet *invalidCharacters = isProcessing ? [NSCharacterSet controlCharacterSet] : nonAlphanumericCharacterSet;
    
    return [[keyEvent characters] rangeOfCharacterFromSet:invalidCharacters].location == NSNotFound;
}

- (BOOL)isRepeatEvent:(NSEvent *)keyEvent {
    return [keyEvent deviceIndependentModifierFlags] == 0 && [keyEvent firstCharacter] == REPEAT_CHARACTER;
}

- (BOOL)isCancelEvent:(NSEvent *)keyEvent {
    return isProcessing && [keyEvent deviceIndependentModifierFlags] == 0 && [keyEvent firstCharacter] == CANCEL_CHARACTER;
}

// See http://www.mactech.com/articles/mactech/Vol.18/18.10/1810TableTechniques/index.html
- (NSTimeInterval)timeoutInterval {
    NSInteger keyThreshTicks = [[NSUserDefaults standardUserDefaults] integerForKey:@"InitialKeyRepeat"];
    if (0 == keyThreshTicks)
        keyThreshTicks = 35;	// apparent default value, translates to 1.17 sec timeout.
    
    return fmin(2.0 / 60.0 * keyThreshTicks, 2.0);
}

- (NSArray *)searchCache {
    if (searchCache == nil)
        searchCache = [[delegate typeSelectHelperSelectionStrings:self] retain];
    return searchCache;
}

- (void)stopTimer {
    [timer invalidate];
    [timer release];
    timer = nil;
}

- (void)startTimerForSelector:(SEL)selector {
    [self stopTimer];
    timer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:[self timeoutInterval]] interval:0 target:self selector:selector userInfo:NULL repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)typeSelectSearchTimeout:(id)sender {
    if (matchOption == SKFullStringMatch)
        [self searchWithStickyMatch:NO];
    [self typeSelectCleanTimeout:sender];
}

- (void)typeSelectCleanTimeout:(id)sender {
    if ([delegate respondsToSelector:@selector(typeSelectHelper:updateSearchString:)])
        [delegate typeSelectHelper:self updateSearchString:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopTimer];
    isProcessing = NO;
    
    NSWindow *keyWin = [NSApp keyWindow];
    NSText *fieldEditor = [keyWin fieldEditor:YES forObject:self];
    if ([fieldEditor delegate] == self) {
        // we pass a dummy key event to the field editor to clear any hanging dead keys (marked text)
        NSEvent *keyEvent = [NSEvent keyEventWithType:NSKeyDown
                                             location:NSZeroPoint
                                        modifierFlags:0
                                            timestamp:0
                                         windowNumber:0
                                              context:nil
                                           characters:@""
                          charactersIgnoringModifiers:@""
                                            isARepeat:NO
                                              keyCode:0];
        [fieldEditor interpretKeyEvents:[NSArray arrayWithObject:keyEvent]];
        [fieldEditor setDelegate:nil];
    }
}

- (void)searchWithStickyMatch:(BOOL)sticky {
    if ([searchString length]) {
        NSUInteger selectedIndex, startIndex, foundIndex;
        
        if (matchOption != SKFullStringMatch) {
            selectedIndex = [delegate typeSelectHelperCurrentlySelectedIndex:self];
            if (selectedIndex >= [[self searchCache] count])
                selectedIndex = NSNotFound;
        } else {
            selectedIndex = NSNotFound;
        }
        
        startIndex = selectedIndex;
        if (sticky && selectedIndex != NSNotFound)
            startIndex = startIndex > 0 ? startIndex - 1 : [[self searchCache] count] - 1;
        
        foundIndex = [self indexOfMatchedItemAfterIndex:startIndex];
        
        if (foundIndex == NSNotFound) {
            if ([delegate respondsToSelector:@selector(typeSelectHelper:didFailToFindMatchForSearchString:)])
                [delegate typeSelectHelper:self didFailToFindMatchForSearchString:searchString];
        } else if (foundIndex != selectedIndex) {
            // Avoid flashing a selection all over the place while you're still typing the thing you have selected
            [delegate typeSelectHelper:self selectItemAtIndex:foundIndex];
        }
    }
}

- (NSUInteger)indexOfMatchedItemAfterIndex:(NSUInteger)selectedIndex {
    NSUInteger labelCount = [[self searchCache] count];
    
    if (labelCount == NO)
        return NSNotFound;
    
    if (selectedIndex == NSNotFound)
        selectedIndex = labelCount - 1;

    NSUInteger labelIndex = selectedIndex;
    BOOL looped = NO;
    NSInteger options = NSCaseInsensitiveSearch;
    
    if (matchOption == SKPrefixMatch)
        options |= NSAnchoredSearch;
    
    while (looped == NO) {
        NSString *label;
        
        if (++labelIndex == labelCount)
            labelIndex = 0;
        if (labelIndex == selectedIndex)
            looped = YES;
        
        label = [[self searchCache] objectAtIndex:labelIndex];
        
        if (matchOption == SKFullStringMatch) {
            if ([label isCaseInsensitiveEqual:searchString])
                return labelIndex;
        } else {
            if ([label containsStringStartingAtWord:searchString options:options range:NSMakeRange(0, [label length])]) {
                return labelIndex;
            }
        }
    }
    
    return NSNotFound;
}

@end

#pragma mark -

@implementation NSString (SKTypeAheadHelperExtensions)

- (BOOL)containsStringStartingAtWord:(NSString *)string options:(NSInteger)mask range:(NSRange)range {
    NSUInteger stringLength = [string length];
    if (stringLength == 0 || stringLength > range.length)
        return NO;
    while (range.length >= stringLength) {
        NSRange r = [self rangeOfString:string options:mask range:range];
        if (r.location == NSNotFound)
            return NO;
        // see if we start at a "word boundary"
        if (r.location == 0 || [[NSCharacterSet alphanumericCharacterSet] characterIsMember:[self characterAtIndex:r.location - 1]] == NO)
            return YES;
        // if it's anchored, we only should search once
        if (mask & NSAnchoredSearch)
            return NO;
        // get the new range, shifted by one from the last match
        if (mask & NSBackwardsSearch)
            range = NSMakeRange(range.location, NSMaxRange(r) - range.location - 1);
        else
            range = NSMakeRange(r.location + 1, NSMaxRange(range) - r.location - 1);
    }
    return NO;
}

@end

#pragma mark -

@interface NSWindow (SKTypeAheadHelperExtensions)
@end

@implementation NSWindow (SKTypeAheadHelperExtensions)

static BOOL (*original_makeFirstResponder)(id, SEL, id) = NULL;

- (BOOL)replacement_makeFirstResponder:(NSResponder *)aResponder {
    id oldFirstResponder = [self firstResponder];
    BOOL success = original_makeFirstResponder(self, _cmd, aResponder);
    if (oldFirstResponder != [self firstResponder])
        [[NSNotificationCenter defaultCenter] postNotificationName:SKWindowDidChangeFirstResponderNotification object:self];
    return success;
}

+ (void)load {
    original_makeFirstResponder = (typeof(original_makeFirstResponder))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(makeFirstResponder:), @selector(replacement_makeFirstResponder:));
}

@end
