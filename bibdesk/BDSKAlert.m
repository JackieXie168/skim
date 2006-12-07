//
//  BDSKAlert.m
//  BibDesk
//
//  Created by Christiaan Hofman on 24/11/05.
/*
 This software is Copyright (c) 2005,2006
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

#import "BDSKAlert.h"
#import "NSImage+Toolbox.h"
#import "NSAttributedString_BDSKExtensions.h"


@implementation BDSKAlert

+ (BDSKAlert *)alertWithMessageText:(NSString *)messageTitle defaultButton:(NSString *)defaultButtonTitle alternateButton:(NSString *)alternateButtonTitle otherButton:(NSString *)otherButtonTitle informativeTextWithFormat:(NSString *)format, ... {
	BDSKAlert *alert = [[[self class] alloc] init];
	NSString *informativeText;
	va_list args;
	
	[alert setMessageText:messageTitle];
	va_start(args, format);
	informativeText = [[NSString alloc] initWithFormat:format arguments:args];
	va_end(args);
	[alert setInformativeText:informativeText];
	[informativeText release];
	
	if (defaultButtonTitle == nil) 
		defaultButtonTitle = NSLocalizedString(@"OK", @"Button title");
	[[alert addButtonWithTitle:defaultButtonTitle] setTag:NSAlertDefaultReturn];
	if (otherButtonTitle != nil) 
		[[alert addButtonWithTitle:otherButtonTitle] setTag:NSAlertOtherReturn];
	if (alternateButtonTitle != nil) 
		[[alert addButtonWithTitle:alternateButtonTitle] setTag:NSAlertAlternateReturn];
	
	return [alert autorelease];
}

- (id)init {
    if (self = [super init]) {
		alertStyle = NSWarningAlertStyle;
		hasCheckButton = NO;
		minButtonSize = NSMakeSize(90.0, 32.0);
        buttons = [[NSMutableArray alloc] initWithCapacity:3];
        unbadgedImage = [[NSImage imageNamed:@"NSApplicationIcon"] retain];
    }
    return self;
}

- (void)dealloc {
    [buttons release];
    [unbadgedImage release];
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"BDSKAlert";
}

- (void)setMessageText:(NSString *)messageText {
    [self window]; // force the nib to be loaded
	[messageField setStringValue:messageText];
}

- (NSString *)messageText {
    [self window]; // force the nib to be loaded
	return [messageField stringValue];
}

- (void)setInformativeText:(NSString *)informativeText {
    [self window]; // force the nib to be loaded
	[informationField setStringValue:informativeText];
}

- (NSString *)informativeText {
    [self window]; // force the nib to be loaded
	return [informationField stringValue];
}

- (void)setCheckText:(NSString *)checkText {
    [self window]; // force the nib to be loaded
	[checkButton setTitle:checkText];
}

- (NSString *)checkText {
    [self window]; // force the nib to be loaded
	return [checkButton title];
}

- (void)setIcon:(NSImage *)icon {
	if (unbadgedImage != icon) {
		[unbadgedImage release];
		unbadgedImage = [icon retain];
	}
}

- (BOOL)hasCheckButton {
    return hasCheckButton;
}

- (void)setHasCheckButton:(BOOL)flag {
    if (hasCheckButton != flag) {
        hasCheckButton = flag;
    }
}

- (void)setCheckValue:(BOOL)flag {
    [self window]; // force the nib to be loaded
	[checkButton setState:flag ? NSOnState : NSOffState];
}

- (BOOL)checkValue {
    [self window]; // force the nib to be loaded
	return ([checkButton state] == NSOnState);
}

- (NSImage *)icon {
	return unbadgedImage;
}

- (void)setAlertStyle:(NSAlertStyle)style {
	alertStyle = style;
}

- (NSAlertStyle)alertStyle {
	return alertStyle;
}

- (NSButton *)addButtonWithTitle:(NSString *)aTitle {
	int numButtons = [buttons count];
	NSRect buttonRect = NSMakeRect(318.0, 12.0, 90.0, 32.0);
	NSButton *button = [[NSButton alloc] initWithFrame:buttonRect];
	[button setBezelStyle:NSRoundedBezelStyle];
	[button setButtonType:NSMomentaryPushInButton];
	[button setTitle:aTitle];
	[button setTag:NSAlertFirstButtonReturn + numButtons];
	[button setTarget:self];
	[button setAction:@selector(dismiss:)];
    
    // buttons created in code use the wrong font
    id cell = [button cell];
    [cell setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:[cell controlSize]]]];
    
	if (numButtons == 0) {
		[button setKeyEquivalent:@"\r"];
	} else if ([aTitle isEqualToString:NSLocalizedString(@"Cancel", @"Button title")]) {
		[button setKeyEquivalent:@"\e"];
	} else if ([aTitle isEqualToString:NSLocalizedString(@"Don't Save", @"Button title")]) {
		[button setKeyEquivalent:@"d"];
		[button setKeyEquivalentModifierMask:NSCommandKeyMask];
	}
	[button sizeToFit];
	buttonRect = [button frame];
	if (NSWidth(buttonRect) < minButtonSize.width) 
		buttonRect.size.width = minButtonSize.width;
	if (numButtons == 0)
		buttonRect.origin.x = NSMaxX([[[self window] contentView] bounds]) - NSWidth(buttonRect) - 14.0;
	else
		buttonRect.origin.x = NSMinX([[buttons lastObject] frame]) - NSWidth(buttonRect);
	[button setFrame:buttonRect];
	[button setAutoresizingMask:NSViewMinXMargin | NSViewMaxXMargin];
	[[[self window] contentView] addSubview:button];
	[buttons addObject:button];
	[button release];
	return button;
}

- (NSArray *)buttons {
	return buttons;
}

- (NSButton *)checkButton {
    [self window]; // force the nib to be loaded
	return checkButton;
}

- (void)prepare {
	NSString *title;
	int numButtons = [buttons count];
	NSRect buttonRect;
	int i;
	NSButton *button = nil;
	float x;
	
	switch (alertStyle) {
		case NSCriticalAlertStyle: 
			title = NSLocalizedString(@"Critical", @"Alert dialog window title");
			break;
		case NSInformationalAlertStyle: 
			title = NSLocalizedString(@"Information", @"Alert dialog window title");
			break;
		case NSWarningAlertStyle:
		default:
			title = NSLocalizedString(@"Alert", @"Alert dialog window title");
	}
	[[self window] setTitle: title];
	
    // see if we should resize the message text
    NSRect frame = [[self window] frame];
    NSRect infoRect = [informationField frame];
    NSRect textRect = [[informationField attributedStringValue] boundingRectForDrawingInViewWithSize:NSMakeSize(NSWidth(infoRect), 200.0)];
    float extraHeight = NSHeight(textRect) - NSHeight(infoRect);

    if (extraHeight > 0) {
        frame.size.height += extraHeight;
        infoRect.size.height += extraHeight;
        infoRect.origin.y -= extraHeight;
        [informationField setFrame:infoRect];
		[[self window] setFrame:frame display:NO];
    }
    
	if (hasCheckButton == NO) {
		frame.size.height -= 22.0;
		[checkButton removeFromSuperview];
		[[self window] setFrame:frame display:NO];
	}
	
	if (numButtons == 0)
		[self addButtonWithTitle:NSLocalizedString(@"OK", @"Button title")];
	x = NSMinX([[buttons lastObject] frame]);
	if (numButtons > 2 && x > 98.0) {
		x = 98.0;
		i = numButtons;
		while (--i > 1) {
			button = [buttons objectAtIndex:i];
			buttonRect = [button frame];
			buttonRect.origin.x = x;
			[button setFrame:buttonRect];
			x += NSWidth(buttonRect) + 12.0;
		}
	}
	
	NSImage *image = unbadgedImage;
	
	if (alertStyle == NSCriticalAlertStyle) {
		NSRect imageRect = NSZeroRect;
		NSRect badgeRect;
		
		imageRect.size = [unbadgedImage size];
        badgeRect = NSMakeRect(floorf(NSMidX(imageRect)), 1.0, ceilf(0.5 * NSWidth(imageRect)), ceilf(0.5 * NSHeight(imageRect)));
        
		NSImage *image = [NSImage iconWithSize:imageRect.size forToolboxCode:kAlertCautionIcon];
		
		[image lockFocus]; 
		[unbadgedImage drawInRect:badgeRect fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];
		[image unlockFocus]; 
	}
	
	[imageView setImage:image];
}

@end
