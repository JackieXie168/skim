//
//  NSTouchBar_SKForwardDeclarations.h
//  Skim
//
//  Created by Christiaan Hofman on 06/05/2019.
/*
 This software is Copyright (c) 2019
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

#import <Cocoa/Cocoa.h>

#if SDK_BEFORE(10_12)

@class NSTouchBar;
@class NSTouchBarItem;
@class NSCustomTouchBarItem;
@class NSPopoverTouchBarItem;
@class NSColorPickerTouchBarItem;

@protocol NSTouchBarDelegate;

@interface NSTouchBar : NSObject <NSCoding>

- (id)init;
- (id)initWithCoder:(NSCoder *)aDecoder;

@property (copy) NSString *customizationIdentifier;
@property (copy) NSArray *customizationAllowedItemIdentifiers;
@property (copy) NSArray *customizationRequiredItemIdentifiers;
@property (copy) NSArray *defaultItemIdentifiers;
@property (copy, readonly) NSArray *itemIdentifiers;
@property (copy) NSString *principalItemIdentifier;
@property (copy) NSString *escapeKeyReplacementItemIdentifier;
@property (copy) NSSet *templateItems;
@property (weak) id <NSTouchBarDelegate> delegate;
- (NSTouchBarItem *)itemForIdentifier:(NSString *)identifier;
@property (readonly, getter=isVisible) BOOL visible;

@end

@protocol NSTouchBarDelegate<NSObject>
@optional
- (NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSString *)identifier;
@end

typedef float NSTouchBarItemPriority;

@interface NSTouchBarItem : NSObject <NSCoding>

- (id)initWithIdentifier:(NSString *)identifier;
- (id)initWithCoder:(NSCoder *)coder;

@property (readonly, copy) NSString *identifier;
@property NSTouchBarItemPriority visibilityPriority;
@property (readonly) NSView *view;
@property (readonly) NSViewController *viewController;
@property (readonly, copy) NSString *customizationLabel;
@property (readonly, getter=isVisible) BOOL visible;

@end

@interface NSCustomTouchBarItem : NSTouchBarItem

@property (strong) NSView *view;
@property (strong) NSViewController *viewController;
@property (copy) NSString *customizationLabel;

@end

@class NSGestureRecognizer;

@interface NSPopoverTouchBarItem : NSTouchBarItem

@property (strong) NSTouchBar *popoverTouchBar;
@property (copy) NSString *customizationLabel;
@property (strong) NSView *collapsedRepresentation;
@property (strong) NSImage *collapsedRepresentationImage;
@property (strong) NSString *collapsedRepresentationLabel;
@property (strong) NSTouchBar *pressAndHoldTouchBar;
@property BOOL showsCloseButton;

- (void)showPopover:(id)sender;
- (void)dismissPopover:(id)sender;

- (NSGestureRecognizer *)makeStandardActivatePopoverGestureRecognizer;

@end

@interface NSColorPickerTouchBarItem : NSTouchBarItem

+ (id)colorPickerWithIdentifier:(NSString *)identifier;
+ (id)textColorPickerWithIdentifier:(NSString *)identifier;
+ (id)strokeColorPickerWithIdentifier:(NSString *)identifier;
+ (id)colorPickerWithIdentifier:(NSString *)identifier buttonImage:(NSImage *)image;

@property (copy) NSColor *color;
@property BOOL showsAlpha;
@property (strong) NSColorList *colorList;
@property (copy) NSString *customizationLabel;
@property (weak) id target;
@property SEL action;
@property (getter=isEnabled) BOOL enabled;

@end

#else

// When compiling against the 10.12.1 SDK or later, just provide forward
// declarations to suppress the partial availability warnings.

@class NSTouchBar;
@protocol NSTouchBarDelegate;
@class NSTouchBarItem;
@class NSCustomTouchBarItem;
@class NSPopoverTouchBarItem;
@class NSColorPickerTouchBarItem;

#endif
