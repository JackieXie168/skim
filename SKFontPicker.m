//
//  SKFontPicker.m
//  Skim
//
//  Created by Christiaan Hofman on 4/13/08.
/*
 This software is Copyright (c) 2008
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

#import "SKFontPicker.h"
#import "OBUtilities.h"

static NSString *SKNSFontPanelDescriptorsPboardType = @"NSFontPanelDescriptorsPboardType";
static NSString *SKNSFontPanelFamiliesPboardType = @"NSFontPanelFamiliesPboardType";
static NSString *SKNSFontCollectionFontDescriptors = @"NSFontCollectionFontDescriptors";

static NSString *SKFontPickerWillBecomeActiveNotification = @"SKFontPickerWillBecomeActiveNotification";

NSString *SKFontPickerFontNameKey = @"fontName";
NSString *SKFontPickerFontSizeKey = @"fontSize";

NSString *SKFontPickerFontKey = @"font";
NSString *SKFontPickerActionKey = @"action";
NSString *SKFontPickerTargetKey = @"target";

static NSDictionary *observationContexts = nil;


@interface SKFontPicker (SKPrivate)
- (void)changeActive:(id)sender;
- (void)updateTitle;
@end


@implementation SKFontPicker

+ (void)initialize {
    OBINITIALIZE;
    
    id keys[2] = {SKFontPickerFontNameKey, SKFontPickerFontSizeKey};
    int values[2] = {3091, 3092};
    observationContexts = (NSDictionary *)CFDictionaryCreate(NULL, (const void **)keys, (const void **)values, 2, &kCFCopyStringDictionaryKeyCallBacks, NULL);
    
    [self exposeBinding:SKFontPickerFontNameKey];
    [self exposeBinding:SKFontPickerFontSizeKey];
    
    [self setKeys:[NSArray arrayWithObjects:SKFontPickerFontKey, nil] triggerChangeNotificationsForDependentKey:SKFontPickerFontNameKey];
    [self setKeys:[NSArray arrayWithObjects:SKFontPickerFontKey, nil] triggerChangeNotificationsForDependentKey:SKFontPickerFontSizeKey];
}

- (Class)valueClassForBinding:(NSString *)binding {
    if ([binding isEqualToString:SKFontPickerFontNameKey])
        return [NSString class];
    else if ([binding isEqualToString:SKFontPickerFontNameKey])
        return [NSNumber class];
    else
        return [super valueClassForBinding:binding];
}

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setFont:[NSFont systemFontOfSize:0.0]];
        [super setAction:@selector(changeActive:)];
        [super setTarget:self];
        [self setButtonType:NSPushOnPushOffButton];
        updatingFromFontPanel = NO;
        updatingFromBinding = NO;
        bindingInfo = [[NSMutableDictionary alloc] init];
        [self registerForDraggedTypes:[NSArray arrayWithObjects:SKNSFontPanelDescriptorsPboardType, SKNSFontPanelFamiliesPboardType, nil]];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        if ([decoder allowsKeyedCoding]) {
            font = [[decoder decodeObjectForKey:SKFontPickerFontKey] retain];
            action = NSSelectorFromString([decoder decodeObjectForKey:SKFontPickerActionKey]);
            target = [decoder decodeObjectForKey:SKFontPickerTargetKey];
        } else {
            font = [[decoder decodeObject] retain];
            [decoder decodeValueOfObjCType:@encode(SEL) at:&action];
            target = [decoder decodeObject];
        }
        if (font == nil)
            [self setFont:[NSFont systemFontOfSize:0.0]];
        else
            [self updateTitle];
        [super setAction:@selector(changeActive:)];
        [super setTarget:self];
        [self setButtonType:NSPushOnPushOffButton];
        [self setState:NSOffState];
        updatingFromFontPanel = NO;
        updatingFromBinding = NO;
        bindingInfo = [[NSMutableDictionary alloc] init];
        [self registerForDraggedTypes:[NSArray arrayWithObjects:SKNSFontPanelDescriptorsPboardType, SKNSFontPanelFamiliesPboardType, nil]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    if ([coder allowsKeyedCoding]) {
        [coder encodeObject:font forKey:SKFontPickerFontKey];
        [coder encodeObject:NSStringFromSelector(action) forKey:SKFontPickerActionKey];
        [coder encodeConditionalObject:target forKey:SKFontPickerTargetKey];
    } else {
        [coder encodeObject:font];
        [coder encodeValueOfObjCType:@encode(SEL) at:action];
        [coder encodeConditionalObject:target];
    }
}

- (void)dealloc {
    [self unbind:SKFontPickerFontNameKey];
    [self unbind:SKFontPickerFontSizeKey];
    [bindingInfo release];
    if ([self isActive])
        [self deactivate];
    [font release];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect {
    [NSGraphicsContext saveGraphicsState];
    
    NSRect bounds = [self bounds];
    NSRectEdge sides[7] = {NSMinYEdge, NSMaxXEdge, NSMinXEdge, NSMaxYEdge, NSMinYEdge, NSMaxXEdge, NSMinXEdge};
    float grays[7];
    
    if ([[self cell] isHighlighted] || [self isActive]) {
        grays[0] = 0.3;
        grays[1] = grays[2] = grays[3] = 0.4;
        grays[4] = 0.65;
        grays[5] = grays[6] = 0.75;
    } else {
        grays[0] = 0.5;
        grays[1] = grays[2] = grays[3] = 0.6;
        grays[4] = 0.85;
        grays[5] = grays[6] = 0.95;
    }
    
    rect = NSDrawTiledRects(bounds, rect, sides, grays, 7);
    
    if ([self isActive])
        [[NSColor selectedControlColor] setFill];
    else
        [[NSColor controlBackgroundColor] setFill];
    NSRectFill(rect);

    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext saveGraphicsState];
    
    [[NSBezierPath bezierPathWithRect:rect] addClip];
    
    [[self cell] drawInteriorWithFrame:bounds inView:self];
    
    [NSGraphicsContext restoreGraphicsState];
    
    if ([self refusesFirstResponder] == NO && [NSApp isActive] && [[self window] isKeyWindow] && [[self window] firstResponder] == self) {
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
        NSRectFill(bounds);
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    [self deactivate];
    [super viewWillMoveToWindow:newWindow];
}

- (void)fontPickerWillBecomeActive:(NSNotification *)notification {
    id sender = [notification object];
    if (sender != self && [self isActive]) {
        [self deactivate];
    }
}

- (void)fontPanelWillClose:(NSNotification *)notification {
    [self deactivate];
}

- (void)changeActive:(id)sender {
    if ([self isEnabled]) {
        if ([self isActive])
            [self activate];
        else
            [self deactivate];
    }
}

- (void)changeFont:(id)sender {
    if ([self isActive]) {
        NSFontManager *fm = [NSFontManager sharedFontManager];
        BOOL savedUpdatingFromFontPanel = updatingFromFontPanel;
        updatingFromFontPanel = YES;
        [self setFont:[fm convertFont:[self font]]];
        [self sendAction:[self action] to:[self target]];
        updatingFromFontPanel = savedUpdatingFromFontPanel;
    }
}

- (void)activate {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSFontManager *fm = [NSFontManager sharedFontManager];
    
    [nc postNotificationName:SKFontPickerWillBecomeActiveNotification object:self];
    
    [fm setSelectedFont:[self font] isMultiple:NO];
    [fm orderFrontFontPanel:self];
    
    [fm setTarget:self];
    [nc addObserver:self selector:@selector(fontPickerWillBecomeActive:)
               name:SKFontPickerWillBecomeActiveNotification object:nil];
    [nc addObserver:self selector:@selector(fontPanelWillClose:)
               name:NSWindowWillCloseNotification object:[fm fontPanel:YES]];
    
    [self setState:NSOnState];
    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    [self setNeedsDisplay:YES];
}

- (void)deactivate {
    NSFontManager *fm = [NSFontManager sharedFontManager];
    if ([fm target] == self) [fm setTarget:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setState:NSOffState];
    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    [self setNeedsDisplay:YES];
}

- (void)updateTitle {
    [self setTitle:[[font displayName] stringByAppendingFormat:@" %i", (int)[font pointSize]]];
    NSMutableAttributedString *attrTitle = [[[self attributedTitle] mutableCopy] autorelease];
    [attrTitle addAttribute:NSFontAttributeName value:[self font] range:NSMakeRange(0, [attrTitle length])];
    [self setAttributedTitle:attrTitle];
}

- (void)updateFont {
    if (updatingFromBinding == NO) {
        NSDictionary *info = [self infoForBinding:SKFontPickerFontNameKey];
		[[info objectForKey:NSObservedObjectKey] setValue:[self fontName] forKeyPath:[info objectForKey:NSObservedKeyPathKey]];
		info = [self infoForBinding:SKFontPickerFontSizeKey];
        [[info objectForKey:NSObservedObjectKey] setValue:[NSNumber numberWithFloat:[self fontSize]] forKeyPath:[info objectForKey:NSObservedKeyPathKey]];
    }
    if ([self isActive] && updatingFromFontPanel == NO)
        [[NSFontManager sharedFontManager] setSelectedFont:[self font] isMultiple:NO];
    [self setNeedsDisplay:YES];
}

#pragma mark Accessors

- (SEL)action {
    return action;
}

- (void)setAction:(SEL)selector {
    if (selector != action) {
        action = selector;
    }
}

- (id)target {
    return target;
}

- (void)setTarget:(id)newTarget {
    if (target != newTarget) {
        target = newTarget;
    }
}

- (BOOL)isActive {
    return [self state] == NSOnState;
}

- (NSFont *)font {
    return font;
}

- (void)setFont:(NSFont *)newFont {
    if (font != newFont) {
        [font release];
        font = [newFont retain];
        [self updateTitle];
        [self updateFont];
    }
}

- (NSString *)fontName {
    return [[self font] fontName];
}

- (void)setFontName:(NSString *)fontName {
    NSFont *newFont = [NSFont fontWithName:fontName size:[[self font] pointSize]];
    if (newFont) {
        [self setFont:newFont];
        [self updateFont];
    }
}

- (float)fontSize {
    return [[self font] pointSize];
}

- (void)setFontSize:(float)pointSize {
    NSFont *newFont = [NSFont fontWithName:[[self font] fontName] size:pointSize];
    if (newFont) {
        [self setFont:newFont];
        [self updateFont];
    }
}

#pragma mark Binding support

- (void)bind:(NSString *)bindingName toObject:(id)observableController withKeyPath:(NSString *)keyPath options:(NSDictionary *)options {	
    if ([bindingName isEqualToString:SKFontPickerFontNameKey] || [bindingName isEqualToString:SKFontPickerFontSizeKey]) {
        
        if ([bindingInfo objectForKey:bindingName])
            [self unbind:bindingName];
		
        NSDictionary *bindingsData = [NSDictionary dictionaryWithObjectsAndKeys:observableController, NSObservedObjectKey, [[keyPath copy] autorelease], NSObservedKeyPathKey, [[options copy] autorelease], NSOptionsKey, nil];
		[bindingInfo setObject:bindingsData forKey:bindingName];
        
        void *context = (void *)[observationContexts objectForKey:bindingName];
        [observableController addObserver:self forKeyPath:keyPath options:0 context:context];
        [self observeValueForKeyPath:keyPath ofObject:observableController change:nil context:context];
    } else {
        [super bind:bindingName toObject:observableController withKeyPath:keyPath options:options];
    }
	[self setNeedsDisplay:YES];
}

- (void)unbind:(NSString *)bindingName {
    if ([bindingName isEqualToString:SKFontPickerFontNameKey] || [bindingName isEqualToString:SKFontPickerFontSizeKey]) {
        
        NSDictionary *info = [self infoForBinding:bindingName];
        [[info objectForKey:NSObservedObjectKey] removeObserver:self forKeyPath:[info objectForKey:NSObservedKeyPathKey]];
		[bindingInfo removeObjectForKey:bindingName];
    } else {
        [super unbind:bindingName];
    }
    [self setNeedsDisplay:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSString *key = nil;
    
    if (context == [observationContexts objectForKey:SKFontPickerFontNameKey])
        key = SKFontPickerFontNameKey;
    else if (context == [observationContexts objectForKey:SKFontPickerFontSizeKey])
        key = SKFontPickerFontSizeKey;
    
    if (key) {
        NSDictionary *info = [self infoForBinding:key];
		id value = [[info objectForKey:NSObservedObjectKey] valueForKeyPath:[info objectForKey:NSObservedKeyPathKey]];
		if (NSIsControllerMarker(value) == NO) {
            updatingFromBinding = YES;
            [self setValue:value forKey:key];
            updatingFromBinding = NO;
		}
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSDictionary *)infoForBinding:(NSString *)bindingName {
	NSDictionary *info = [bindingInfo objectForKey:bindingName];
	if (info == nil)
		info = [super infoForBinding:bindingName];
	return info;
}

#pragma mark NSDraggingDestination protocol 

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    if ([self isEnabled] && [sender draggingSource] != self && [[sender draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:SKNSFontPanelDescriptorsPboardType, SKNSFontPanelFamiliesPboardType, nil]]) {
        [[self cell] setHighlighted:YES];
        [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
        [self setNeedsDisplay:YES];
        return NSDragOperationGeneric;
    } else
        return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    if ([self isEnabled] && [sender draggingSource] != self && [[sender draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:SKNSFontPanelDescriptorsPboardType, SKNSFontPanelFamiliesPboardType, nil]]) {
        [[self cell] setHighlighted:NO];
        [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
        [self setNeedsDisplay:YES];
    }
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    return [self isEnabled] && [sender draggingSource] != self && [[sender draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:SKNSFontPanelDescriptorsPboardType, SKNSFontPanelFamiliesPboardType, nil]];
} 

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender{
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:SKNSFontPanelDescriptorsPboardType, SKNSFontPanelFamiliesPboardType, nil]];
    NSFont *droppedFont = nil;
    
    @try {
        if ([type isEqualToString:SKNSFontPanelDescriptorsPboardType]) {
            NSData *data = [pboard dataForType:type];
            NSDictionary *dict = [data isKindOfClass:[NSData class]] ? [NSKeyedUnarchiver unarchiveObjectWithData:data] : nil;
            if ([dict isKindOfClass:[NSDictionary class]]) {
                NSArray *fontDescriptors = [dict objectForKey:SKNSFontCollectionFontDescriptors];
                NSFontDescriptor *fontDescriptor = ([fontDescriptors isKindOfClass:[NSArray class]] && [fontDescriptors count]) ? [fontDescriptors objectAtIndex:0] : nil;
                if ([fontDescriptor isKindOfClass:[NSFontDescriptor class]]) {
                    NSNumber *size = [[fontDescriptor fontAttributes] objectForKey:NSFontSizeAttribute];
                    if (size == nil)
                        size = [dict objectForKey:NSFontSizeAttribute];
                    float fontSize = [size respondsToSelector:@selector(floatValue)] ? [size floatValue] : [self fontSize];
                    droppedFont = [NSFont fontWithDescriptor:fontDescriptor size:fontSize];
                }
            }
        } else if ([type isEqualToString:SKNSFontPanelFamiliesPboardType]) {
            NSArray *families = [pboard propertyListForType:type];
            NSString *family = ([families isKindOfClass:[NSArray class]] && [families count]) ? [families objectAtIndex:0] : nil;
            if ([family isKindOfClass:[NSString class]])
                droppedFont = [[NSFontManager sharedFontManager] convertFont:[self font] toFamily:family];
        }
    }
    @catch (id exception) {
        NSLog(@"Ignroing exception %@ when dropping on SKFontPicker failed", exception);
    }
    
    if (droppedFont) {
        [self setFont:droppedFont];
        [self sendAction:[self action] to:[self target]];
    }
    
    [[self cell] setHighlighted:NO];
    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    [self setNeedsDisplay:YES];
    
	return droppedFont != nil;
}

@end
