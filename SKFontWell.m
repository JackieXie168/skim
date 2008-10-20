//
//  SKFontWell.m
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

#import "SKFontWell.h"
#import "SKRuntime.h"

static NSString *SKNSFontPanelDescriptorsPboardType = @"NSFontPanelDescriptorsPboardType";
static NSString *SKNSFontPanelFamiliesPboardType = @"NSFontPanelFamiliesPboardType";
static NSString *SKNSFontCollectionFontDescriptors = @"NSFontCollectionFontDescriptors";

static NSString *SKFontWellWillBecomeActiveNotification = @"SKFontWellWillBecomeActiveNotification";

NSString *SKFontWellFontNameKey = @"fontName";
NSString *SKFontWellFontSizeKey = @"fontSize";
NSString *SKFontWellTextColorKey = @"textColor";
NSString *SKFontWellHasTextColorKey = @"hasTextColor";

NSString *SKFontWellFontKey = @"font";
NSString *SKFontWellActionKey = @"action";
NSString *SKFontWellTargetKey = @"target";

static NSString *SKFontWellFontNameObservationContext = @"SKFontWellFontNameObservationContext";
static NSString *SKFontWellFontSizeObservationContext = @"SKFontWellFontSizeObservationContext";


@interface SKFontWell (SKPrivate)
- (void)changeActive:(id)sender;
- (void)fontChanged;
@end


@implementation SKFontWell

+ (void)initialize {
    [self exposeBinding:SKFontWellFontNameKey];
    [self exposeBinding:SKFontWellFontSizeKey];
    [self exposeBinding:SKFontWellTextColorKey];
    
    [self setKeys:[NSArray arrayWithObjects:SKFontWellFontKey, nil] triggerChangeNotificationsForDependentKey:SKFontWellFontNameKey];
    [self setKeys:[NSArray arrayWithObjects:SKFontWellFontKey, nil] triggerChangeNotificationsForDependentKey:SKFontWellFontSizeKey];
    
    OBINITIALIZE;
}

+ (Class)cellClass {
    return [SKFontWellCell class];
}

- (Class)valueClassForBinding:(NSString *)binding {
    if ([binding isEqualToString:SKFontWellFontNameKey])
        return [NSString class];
    else if ([binding isEqualToString:SKFontWellFontNameKey])
        return [NSNumber class];
    else if ([binding isEqualToString:SKFontWellTextColorKey])
        return [NSColor class];
    else
        return [super valueClassForBinding:binding];
}

- (void)commonInit {
    if ([self font] == nil)
        [self setFont:[NSFont systemFontOfSize:0.0]];
    [self fontChanged];
    [super setAction:@selector(changeActive:)];
    [super setTarget:self];
    bindingInfo = [[NSMutableDictionary alloc] init];
    [self registerForDraggedTypes:[NSArray arrayWithObjects:SKNSFontPanelDescriptorsPboardType, SKNSFontPanelFamiliesPboardType, nil]];
}

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
		NSButtonCell *oldCell = [self cell];
		if (NO == [oldCell isKindOfClass:[[self class] cellClass]]) {
			SKFontWellCell *newCell = [[[[self class] cellClass] alloc] init];
			[newCell setAlignment:[oldCell alignment]];
			[newCell setEditable:[oldCell isEditable]];
			[newCell setTarget:[oldCell target]];
			[newCell setAction:[oldCell action]];
			[self setCell:newCell];
			[newCell release];
		}
        if ([decoder allowsKeyedCoding]) {
            action = NSSelectorFromString([decoder decodeObjectForKey:SKFontWellActionKey]);
            target = [decoder decodeObjectForKey:SKFontWellTargetKey];
        } else {
            action = NSSelectorFromString([decoder decodeObject]);
            target = [decoder decodeObject];
        }
        [self commonInit];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    if ([coder allowsKeyedCoding]) {
        [coder encodeObject:NSStringFromSelector(action) forKey:SKFontWellActionKey];
        [coder encodeConditionalObject:target forKey:SKFontWellTargetKey];
    } else {
        [coder encodeObject:NSStringFromSelector(action)];
        [coder encodeConditionalObject:target];
    }
}

- (void)dealloc {
    [self unbind:SKFontWellFontNameKey];
    [self unbind:SKFontWellFontSizeKey];
    [bindingInfo release];
    if ([self isActive])
        [self deactivate];
    [super dealloc];
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

- (void)notifyBinding {
    NSDictionary *info = [self infoForBinding:SKFontWellFontNameKey];
    [[info objectForKey:NSObservedObjectKey] setValue:[self fontName] forKeyPath:[info objectForKey:NSObservedKeyPathKey]];
    info = [self infoForBinding:SKFontWellFontSizeKey];
    [[info objectForKey:NSObservedObjectKey] setValue:[NSNumber numberWithFloat:[self fontSize]] forKeyPath:[info objectForKey:NSObservedKeyPathKey]];
}

- (void)notifyTextColorBinding {
    NSDictionary *info = [self infoForBinding:SKFontWellTextColorKey];
    if (info) {
        id value = [self textColor];
        NSString *transformerName = [[info objectForKey:NSOptionsKey] objectForKey:NSValueTransformerNameBindingOption];
        if (transformerName) {
            NSValueTransformer *valueTransformer = [NSValueTransformer valueTransformerForName:transformerName];
            value = [valueTransformer reverseTransformedValue:value]; 
        }
        [[info objectForKey:NSObservedObjectKey] setValue:value forKeyPath:[info objectForKey:NSObservedKeyPathKey]];
    }
}

- (void)changeFontFromFontManager:(id)sender {
    if ([self isActive]) {
        [self setFont:[sender convertFont:[self font]]];
        [self notifyBinding];
        [self sendAction:[self action] to:[self target]];
    }
}

- (void)changeAttributesFromFontManager:(id)sender {
    if ([self isActive] && [self hasTextColor]) {
        [self setTextColor:[[sender convertAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[self textColor], NSForegroundColorAttributeName, nil]] valueForKey:NSForegroundColorAttributeName]];
        [self notifyTextColorBinding];
        [self sendAction:[self action] to:[self target]];
    }
}

- (void)changeActive:(id)sender {
    if ([self isEnabled]) {
        if ([self isActive])
            [self activate];
        else
            [self deactivate];
    }
}

- (void)activate {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSFontManager *fm = [NSFontManager sharedFontManager];
    
    [nc postNotificationName:SKFontWellWillBecomeActiveNotification object:self];
    
    [fm setSelectedFont:[self font] isMultiple:NO];
    [fm orderFrontFontPanel:self];
    
    [nc addObserver:self selector:@selector(fontPickerWillBecomeActive:)
               name:SKFontWellWillBecomeActiveNotification object:nil];
    [nc addObserver:self selector:@selector(fontPanelWillClose:)
               name:NSWindowWillCloseNotification object:[fm fontPanel:YES]];
    
    [self setState:NSOnState];
    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    [self setNeedsDisplay:YES];
}

- (void)deactivate {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setState:NSOffState];
    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    [self setNeedsDisplay:YES];
}

- (void)fontChanged {
    if ([self isActive])
        [[NSFontManager sharedFontManager] setSelectedFont:[self font] isMultiple:NO];
    [self setTitle:[NSString stringWithFormat:@"%@ %i", [[self font] displayName], (int)[self fontSize]]];
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

- (void)setFont:(NSFont *)newFont {
    BOOL didChange = [[self font] isEqual:newFont] == NO;
    [super setFont:newFont];
    if (didChange)
        [self fontChanged];
}

- (NSString *)fontName {
    return [[self font] fontName];
}

- (void)setFontName:(NSString *)fontName {
    NSFont *newFont = [NSFont fontWithName:fontName size:[[self font] pointSize]];
    if (newFont)
        [self setFont:newFont];
}

- (float)fontSize {
    return [[self font] pointSize];
}

- (void)setFontSize:(float)pointSize {
    NSFont *newFont = [NSFont fontWithName:[[self font] fontName] size:pointSize];
    if (newFont)
        [self setFont:newFont];
}

- (NSColor *)textColor {
    return [[self cell] textColor];
}

- (void)setTextColor:(NSColor *)newTextColor {
    BOOL didChange = [[self textColor] isEqual:newTextColor] == NO;
    [[self cell] setTextColor:newTextColor];
    if (didChange)
        [self setNeedsDisplay:YES];
}

- (BOOL)hasTextColor {
    return [[self cell] hasTextColor];
}

- (void)setHasTextColor:(BOOL)newHasTextColor {
    if ([self hasTextColor] != newHasTextColor) {
        [[self cell] setHasTextColor:newHasTextColor];
        [self setNeedsDisplay:YES];
    }
}

#pragma mark Binding support

- (void)bind:(NSString *)bindingName toObject:(id)observableController withKeyPath:(NSString *)keyPath options:(NSDictionary *)options {	
    if ([bindingName isEqualToString:SKFontWellFontNameKey] || [bindingName isEqualToString:SKFontWellFontSizeKey]) {
        
        if ([bindingInfo objectForKey:bindingName])
            [self unbind:bindingName];
		
        NSDictionary *bindingsData = [NSDictionary dictionaryWithObjectsAndKeys:observableController, NSObservedObjectKey, [[keyPath copy] autorelease], NSObservedKeyPathKey, [[options copy] autorelease], NSOptionsKey, nil];
		[bindingInfo setObject:bindingsData forKey:bindingName];
        
        void *context = NULL;
        if ([bindingName isEqualToString:SKFontWellFontNameKey])
            context = SKFontWellFontNameObservationContext;
        else if ([bindingName isEqualToString:SKFontWellFontSizeKey])
            context = SKFontWellFontSizeObservationContext;
        
        [observableController addObserver:self forKeyPath:keyPath options:0 context:context];
        [self observeValueForKeyPath:keyPath ofObject:observableController change:nil context:context];
    } else {
        [super bind:bindingName toObject:observableController withKeyPath:keyPath options:options];
    }
	[self setNeedsDisplay:YES];
}

- (void)unbind:(NSString *)bindingName {
    if ([bindingName isEqualToString:SKFontWellFontNameKey] || [bindingName isEqualToString:SKFontWellFontSizeKey]) {
        
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
    if (context == SKFontWellFontNameObservationContext)
        key = SKFontWellFontNameKey;
    else if (context == SKFontWellFontSizeObservationContext)
        key = SKFontWellFontSizeKey;
    
    if (key) {
        NSDictionary *info = [self infoForBinding:key];
		id value = [[info objectForKey:NSObservedObjectKey] valueForKeyPath:[info objectForKey:NSObservedKeyPathKey]];
		if (NSIsControllerMarker(value) == NO)
            [self setValue:value forKey:key];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSDictionary *)infoForBinding:(NSString *)bindingName {
	return [bindingInfo objectForKey:bindingName] ?: [super infoForBinding:bindingName];
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
                    NSNumber *size = [[fontDescriptor fontAttributes] objectForKey:NSFontSizeAttribute] ?: [dict objectForKey:NSFontSizeAttribute];
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
        NSLog(@"Ignroing exception %@ when dropping on SKFontWell failed", exception);
    }
    
    if (droppedFont) {
        [self setFont:droppedFont];
        [self notifyBinding];
        [self sendAction:[self action] to:[self target]];
    }
    
    [[self cell] setHighlighted:NO];
    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    [self setNeedsDisplay:YES];
    
	return droppedFont != nil;
}

@end


@implementation SKFontWellCell

- (void)commonInit {
    if (textColor == nil)
        [self setTextColor:[NSColor blackColor]];
    [self setBezelStyle:NSShadowlessSquareBezelStyle]; // this is mainly to make it selectable
    [self setButtonType:NSPushOnPushOffButton];
    [self setState:NSOffState];
}
 
- (id)initTextCell:(NSString *)aString {
	if (self = [super initTextCell:aString]) {
		[self commonInit];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super initWithCoder:decoder]) {
        if ([decoder allowsKeyedCoding]) {
            [self setTextColor:[decoder decodeObjectForKey:SKFontWellTextColorKey]];
            [self setHasTextColor:[decoder decodeBoolForKey:SKFontWellHasTextColorKey]];
        } else {
            [self setTextColor:[decoder decodeObject]];
            [decoder decodeValueOfObjCType:@encode(BOOL) at:&hasTextColor];
		}
        [self commonInit];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    if ([coder allowsKeyedCoding]) {
        [coder encodeConditionalObject:textColor forKey:SKFontWellTextColorKey];
        [coder encodeObject:textColor forKey:SKFontWellHasTextColorKey];
    } else {
        [coder encodeObject:textColor];
        [coder encodeValueOfObjCType:@encode(BOOL) at:&hasTextColor];
    }
}

- (void)dealloc {
    [textColor release];
    [super dealloc];
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView {
    [NSGraphicsContext saveGraphicsState];
    
    NSColor *bgColor = [self state] == NSOnState ? [NSColor selectedControlColor] : [NSColor controlBackgroundColor];
    NSColor *edgeColor = [NSColor colorWithCalibratedWhite:0 alpha:[self isHighlighted] ? 0.33 : .11];
    
    [bgColor setFill];
    NSRectFill(frame);
    
    [edgeColor setStroke];
    [[NSBezierPath bezierPathWithRect:NSInsetRect(frame, 0.5, 0.5)] stroke];
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:frame];
    [path appendBezierPathWithRect:NSInsetRect(frame, -2.0, -2.0)];
    [path setWindingRule:NSEvenOddWindingRule];
    NSShadow *shadow1 = [[NSShadow new] autorelease];
    [shadow1 setShadowBlurRadius:2.0];
    [shadow1 setShadowOffset:NSMakeSize(0.0, -1.0)];
    [shadow1 setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.7]];
    [shadow1 set];
    [[NSColor blackColor] setFill];
    [path fill];
    
    [NSGraphicsContext restoreGraphicsState];
    
    if ([self refusesFirstResponder] == NO && [NSApp isActive] && [[controlView window] isKeyWindow] && [[controlView window] firstResponder] == controlView) {
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
        NSRectFill(frame);
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (NSAttributedString *)attributedTitle {
    if ([self hasTextColor]) {
        NSMutableAttributedString *attrString = [[[super attributedTitle] mutableCopy] autorelease];
        [attrString addAttribute:NSForegroundColorAttributeName value:[self textColor] range:NSMakeRange(0, [attrString length])];
        return attrString;
    } else {
        return [super attributedTitle];
    }
}

- (NSColor *)textColor {
    return textColor;
}

- (void)setTextColor:(NSColor *)newTextColor {
    if (textColor != newTextColor) {
        [textColor release];
        textColor = [newTextColor copy];
    }
}

- (BOOL)hasTextColor {
    return hasTextColor;
}

- (void)setHasTextColor:(BOOL)newHasTextColor {
    if (hasTextColor != newHasTextColor) {
        hasTextColor = newHasTextColor;
    }
}

@end
