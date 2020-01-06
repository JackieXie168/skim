//
//  SKFontWell.m
//  Skim
//
//  Created by Christiaan Hofman on 4/13/08.
/*
 This software is Copyright (c) 2008-2020
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
#import "NSGraphics_SKExtensions.h"
#import "NSColor_SKExtensions.h"

#define SKNSFontPanelDescriptorsPboardType @"NSFontPanelDescriptorsPboardType"
#define SKNSFontPanelFamiliesPboardType @"NSFontPanelFamiliesPboardType"
#define SKNSFontCollectionFontDescriptors @"NSFontCollectionFontDescriptors"

#define SKFontWellWillBecomeActiveNotification @"SKFontWellWillBecomeActiveNotification"

#define FONTNAME_KEY     @"fontName"
#define FONTSIZE_KEY     @"fontSize"
#define TEXTCOLOR_KEY    @"textColor"
#define HASTEXTCOLOR_KEY @"hasTextColor"

#define FONT_KEY         @"font"
#define ACTION_KEY       @"action"
#define TARGET_KEY       @"target"

static char SKFontWellFontNameObservationContext;
static char SKFontWellFontSizeObservationContext;


@interface SKFontWell (SKPrivate)
- (void)changeActive:(id)sender;
- (void)fontChanged;
@end


@implementation SKFontWell

@dynamic active, fontName, fontSize, textColor, hasTextColor;

+ (void)initialize {
    SKINITIALIZE;
    
    [self exposeBinding:FONTNAME_KEY];
    [self exposeBinding:FONTSIZE_KEY];
    [self exposeBinding:TEXTCOLOR_KEY];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:FONTNAME_KEY] || [key isEqualToString:FONTSIZE_KEY])
        keyPaths = [keyPaths setByAddingObjectsFromSet:[NSSet setWithObjects:FONT_KEY, nil]];
    return keyPaths;
}

+ (Class)cellClass {
    return [SKFontWellCell class];
}

- (Class)valueClassForBinding:(NSString *)binding {
    if ([binding isEqualToString:FONTNAME_KEY])
        return [NSString class];
    else if ([binding isEqualToString:FONTNAME_KEY])
        return [NSNumber class];
    else if ([binding isEqualToString:TEXTCOLOR_KEY])
        return [NSColor class];
    else
        return [super valueClassForBinding:binding];
}

- (void)commonInit {
    if ([self font] == nil)
        [self setFont:[NSFont systemFontOfSize:0.0]];
    [self fontChanged];
    [[self cell] setShowsStateBy:NSNoCellMask];
    [super setAction:@selector(changeActive:)];
    [super setTarget:self];
    bindingInfo = [[NSMutableDictionary alloc] init];
    [self registerForDraggedTypes:[NSArray arrayWithObjects:SKNSFontPanelDescriptorsPboardType, SKNSFontPanelFamiliesPboardType, NSPasteboardTypeColor, nil]];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
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
        action = NSSelectorFromString([decoder decodeObjectForKey:ACTION_KEY]);
        target = [decoder decodeObjectForKey:TARGET_KEY];
        [self commonInit];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:NSStringFromSelector(action) forKey:ACTION_KEY];
    [coder encodeConditionalObject:target forKey:TARGET_KEY];
}

- (void)dealloc {
    SKENSURE_MAIN_THREAD(
        [self unbind:FONTNAME_KEY];
        [self unbind:FONTSIZE_KEY];
    );
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SKDESTROY(bindingInfo);
    [super dealloc];
}

- (BOOL)isOpaque{ return NO; }

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

- (void)dirty {
    [self setNeedsDisplay:YES];
}

- (void)notifyFontBinding {
    NSDictionary *info = [self infoForBinding:FONTNAME_KEY];
    [[info objectForKey:NSObservedObjectKey] setValue:[self fontName] forKeyPath:[info objectForKey:NSObservedKeyPathKey]];
    info = [self infoForBinding:FONTSIZE_KEY];
    [[info objectForKey:NSObservedObjectKey] setValue:[NSNumber numberWithDouble:[self fontSize]] forKeyPath:[info objectForKey:NSObservedKeyPathKey]];
}

- (void)notifyTextColorBinding {
    NSDictionary *info = [self infoForBinding:TEXTCOLOR_KEY];
    if (info) {
        id value = [self textColor];
        NSString *transformerName = [[info objectForKey:NSOptionsKey] objectForKey:NSValueTransformerNameBindingOption];
        if (transformerName && [transformerName isEqual:[NSNull null]] == NO) {
            NSValueTransformer *valueTransformer = [NSValueTransformer valueTransformerForName:transformerName];
            value = [valueTransformer reverseTransformedValue:value]; 
        }
        [[info objectForKey:NSObservedObjectKey] setValue:value forKeyPath:[info objectForKey:NSObservedKeyPathKey]];
    }
}

- (void)changeFontFromFontManager:(id)sender {
    if ([self isActive]) {
        [self setFont:[sender convertFont:[self font]]];
        [self notifyFontBinding];
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
    [self dirty];
    [self setNeedsDisplay:YES];
}

- (void)deactivate {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setState:NSOffState];
    [self dirty];
    [self setNeedsDisplay:YES];
}

- (void)fontChanged {
    if ([self isActive])
        [[NSFontManager sharedFontManager] setSelectedFont:[self font] isMultiple:NO];
    [self setTitle:[NSString stringWithFormat:@"%@ %li", [[self font] displayName], (long)[self fontSize]]];
    [self setNeedsDisplay:YES];
}

#pragma mark Accessors

- (SEL)action { return action; }

- (void)setAction:(SEL)newAction { action = newAction; }

- (id)target { return target; }

- (void)setTarget:(id)newTarget { target = newTarget; }

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

- (CGFloat)fontSize {
    return [[self font] pointSize];
}

- (void)setFontSize:(CGFloat)pointSize {
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
    if ([bindingName isEqualToString:FONTNAME_KEY] || [bindingName isEqualToString:FONTSIZE_KEY]) {
        
        if ([bindingInfo objectForKey:bindingName])
            [self unbind:bindingName];
		
        NSDictionary *bindingsData = [NSDictionary dictionaryWithObjectsAndKeys:observableController, NSObservedObjectKey, [[keyPath copy] autorelease], NSObservedKeyPathKey, [[options copy] autorelease], NSOptionsKey, nil];
		[bindingInfo setObject:bindingsData forKey:bindingName];
        
        void *context = NULL;
        if ([bindingName isEqualToString:FONTNAME_KEY])
            context = &SKFontWellFontNameObservationContext;
        else if ([bindingName isEqualToString:FONTSIZE_KEY])
            context = &SKFontWellFontSizeObservationContext;
        
        [observableController addObserver:self forKeyPath:keyPath options:0 context:context];
        [self observeValueForKeyPath:keyPath ofObject:observableController change:nil context:context];
    } else {
        [super bind:bindingName toObject:observableController withKeyPath:keyPath options:options];
    }
	[self setNeedsDisplay:YES];
}

- (void)unbind:(NSString *)bindingName {
    if ([bindingName isEqualToString:FONTNAME_KEY] || [bindingName isEqualToString:FONTSIZE_KEY]) {
        
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
    if (context == &SKFontWellFontNameObservationContext)
        key = FONTNAME_KEY;
    else if (context == &SKFontWellFontSizeObservationContext)
        key = FONTSIZE_KEY;
    
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
    if ([self isEnabled] && [sender draggingSource] != self && [[sender draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:SKNSFontPanelDescriptorsPboardType, SKNSFontPanelFamiliesPboardType, ([self hasTextColor] ? NSPasteboardTypeColor : nil), nil]]) {
        [[self cell] setHighlighted:YES];
        [self dirty];
        [self setNeedsDisplay:YES];
        return NSDragOperationGeneric;
    } else
        return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    if ([self isEnabled] && [sender draggingSource] != self && [[sender draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:SKNSFontPanelDescriptorsPboardType, SKNSFontPanelFamiliesPboardType, ([self hasTextColor] ? NSPasteboardTypeColor : nil), nil]]) {
        [[self cell] setHighlighted:NO];
        [self dirty];
        [self setNeedsDisplay:YES];
    }
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    return [self isEnabled] && [sender draggingSource] != self && [[sender draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:SKNSFontPanelDescriptorsPboardType, SKNSFontPanelFamiliesPboardType, ([self hasTextColor] ? NSPasteboardTypeColor : nil), nil]];
} 

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender{
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:SKNSFontPanelDescriptorsPboardType, SKNSFontPanelFamiliesPboardType, ([self hasTextColor] ? NSPasteboardTypeColor : nil), nil]];
    NSFont *droppedFont = nil;
    NSColor *droppedColor = nil;
    
    @try {
        if ([type isEqualToString:SKNSFontPanelDescriptorsPboardType]) {
            NSData *data = [pboard dataForType:type];
            NSDictionary *dict = [data isKindOfClass:[NSData class]] ? [NSKeyedUnarchiver unarchiveObjectWithData:data] : nil;
            if ([dict isKindOfClass:[NSDictionary class]]) {
                NSArray *fontDescriptors = [dict objectForKey:SKNSFontCollectionFontDescriptors];
                NSFontDescriptor *fontDescriptor = ([fontDescriptors isKindOfClass:[NSArray class]] && [fontDescriptors count]) ? [fontDescriptors objectAtIndex:0] : nil;
                if ([fontDescriptor isKindOfClass:[NSFontDescriptor class]]) {
                    NSNumber *size = [[fontDescriptor fontAttributes] objectForKey:NSFontSizeAttribute] ?: [dict objectForKey:NSFontSizeAttribute];
                    CGFloat fontSize = [size respondsToSelector:@selector(doubleValue)] ? [size doubleValue] : [self fontSize];
                    droppedFont = [NSFont fontWithDescriptor:fontDescriptor size:fontSize];
                }
            }
        } else if ([type isEqualToString:SKNSFontPanelFamiliesPboardType]) {
            NSArray *families = [pboard propertyListForType:type];
            NSString *family = ([families isKindOfClass:[NSArray class]] && [families count]) ? [families objectAtIndex:0] : nil;
            if ([family isKindOfClass:[NSString class]])
                droppedFont = [[NSFontManager sharedFontManager] convertFont:[self font] toFamily:family];
        } else if ([type isEqualToString:NSPasteboardTypeColor]) {
            droppedColor = [NSColor colorFromPasteboard:pboard];
        }
    }
    @catch (id exception) {
        NSLog(@"Ignoring exception %@ when dropping on SKFontWell failed", exception);
    }
    
    if (droppedFont) {
        [self setFont:droppedFont];
        [self notifyFontBinding];
        [self sendAction:[self action] to:[self target]];
    }
    if (droppedColor) {
        [self setTextColor:droppedColor];
        [self notifyTextColorBinding];
        [self sendAction:[self action] to:[self target]];
    }
    
    [[self cell] setHighlighted:NO];
    [self dirty];
    [self setNeedsDisplay:YES];
    
	return droppedFont != nil || droppedColor != nil;
}

@end


@implementation SKFontWellCell

@synthesize textColor, hasTextColor;

- (void)commonInit {
    if (textColor == nil)
        [self setTextColor:[NSColor controlTextColor]];
    [self setBezelStyle:NSShadowlessSquareBezelStyle]; // this is mainly to make it selectable
    [self setButtonType:NSPushOnPushOffButton];
    [self setState:NSOffState];
}
 
- (id)initTextCell:(NSString *)aString {
	self = [super initTextCell:aString];
    if (self) {
		[self commonInit];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
    if (self) {
        [self setTextColor:[decoder decodeObjectForKey:TEXTCOLOR_KEY]];
        [self setHasTextColor:[decoder decodeBoolForKey:HASTEXTCOLOR_KEY]];
        [self commonInit];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeConditionalObject:textColor forKey:TEXTCOLOR_KEY];
    [coder encodeObject:textColor forKey:HASTEXTCOLOR_KEY];
}

- (id)copyWithZone:(NSZone *)zone {
    SKFontWellCell *copy = [super copyWithZone:zone];
    copy->textColor = [textColor copyWithZone:zone];
    copy->hasTextColor = hasTextColor;
    return copy;
}

- (void)dealloc {
    SKDESTROY(textColor);
    [super dealloc];
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView {
    SKDrawTextFieldBezel(frame, controlView);
    
    if ([self state] == NSOnState) {
        [NSGraphicsContext saveGraphicsState];
        [[NSColor selectedControlColor] setFill];
        [NSBezierPath fillRect:NSInsetRect(frame, 1.0, 1.0)];
        [NSGraphicsContext restoreGraphicsState];
    }
    if ([self isHighlighted]) {
        [NSGraphicsContext saveGraphicsState];
        // @@ Dark mode
        [[[NSColor controlTextColor] colorWithAlphaComponent:0.3] setStroke];
        [NSBezierPath strokeRect:NSInsetRect(frame, 0.5, 0.5)];
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (NSRect)focusRingMaskBoundsForFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    return cellFrame;
}

- (void)drawFocusRingMaskWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRectFill(cellFrame);
}

- (NSAttributedString *)attributedTitle {
    if ([self hasTextColor]) {
        NSMutableAttributedString *attrString = [[[super attributedTitle] mutableCopy] autorelease];
        [attrString addAttribute:NSForegroundColorAttributeName value:[self textColor] range:NSMakeRange(0, [attrString length])];
        // @@ Dark mode
        CGFloat textLuminance = [[self textColor] luminance];
        CGFloat backgroundLuminance = [[self backgroundColor] luminance];
        if ((fmax(textLuminance, backgroundLuminance) + 0.05) / (fmin(textLuminance, backgroundLuminance) + 0.05) < 4.5) {
            NSShadow *shade = [[[NSShadow alloc] init] autorelease];
            [shade setShadowColor:backgroundLuminance < 0.5 ? [NSColor whiteColor] : [NSColor blackColor]];
            [shade setShadowBlurRadius:1.0];
            [attrString addAttribute:NSShadowAttributeName value:shade range:NSMakeRange(0, [attrString length])];
        }
        return attrString;
    } else {
        return [super attributedTitle];
    }
}

@end
