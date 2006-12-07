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


@interface BDSKAlert (Private)

- (void)prepare;
- (void)buttonPressed:(id)sender;
- (void)didEndAlert:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

@end

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
		defaultButtonTitle = NSLocalizedString(@"OK", @"OK");
	[[alert addButtonWithTitle:defaultButtonTitle] setTag:NSAlertDefaultReturn];
	if (otherButtonTitle != nil) 
		[[alert addButtonWithTitle:otherButtonTitle] setTag:NSAlertOtherReturn];
	if (alternateButtonTitle != nil) 
		[[alert addButtonWithTitle:alternateButtonTitle] setTag:NSAlertAlternateReturn];
	
	return [alert autorelease];
}

- (id)init {
    if (self = [super init]) {
		BOOL success = [NSBundle loadNibNamed:@"BDSKAlert" owner:self];
		if (!success) {
			[self release];
			return (self = nil);
		}
		alertStyle = NSWarningAlertStyle;
		hasCheckButton = NO;
		minButtonSize = NSMakeSize(90.0, 32.0);
        buttons = [[NSMutableArray alloc] initWithCapacity:3];
        unbadgedImage = [[NSImage imageNamed:@"NSApplicationIcon"] retain];
        modalDelegate = nil;
        docWindow = nil;
        didEndSelector = NULL;
        didDismissSelector = NULL;
    }
    return self;
}

- (void)dealloc {
    [buttons release];
    [unbadgedImage release];
    [panel release];
    [super dealloc];
}

- (int)runModal {
	[self prepare];
	
	runAppModal = YES;
	
	[panel makeKeyAndOrderFront:self];
	int returnCode = [NSApp runModalForWindow:panel];
	[panel orderOut:self];
	
	return returnCode;
}

- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)aDelegate didEndSelector:(SEL)aDidEndSelector contextInfo:(void *)contextInfo {
	[self prepare];
	
	runAppModal = NO;
    modalDelegate = aDelegate;
	didEndSelector = aDidEndSelector;
	
	[self retain]; // make sure we stay around long enough
	
	[NSApp beginSheet:panel
	   modalForWindow:window
		modalDelegate:self
	   didEndSelector:@selector(didEndAlert:returnCode:contextInfo:)
		  contextInfo:contextInfo];
}

- (int)runSheetModalForWindow:(NSWindow *)window modalDelegate:(id)aDelegate didEndSelector:(SEL)aDidEndSelector didDismissSelector:(SEL)aDidDismissSelector contextInfo:(void *)contextInfo {
	[self prepare];
	
	runAppModal = YES;
    modalDelegate = aDelegate;
	didEndSelector = aDidEndSelector;
	didDismissSelector = aDidDismissSelector;
	
	[NSApp beginSheet:panel
	   modalForWindow:window
		modalDelegate:self
	   didEndSelector:@selector(didEndAlert:returnCode:contextInfo:)
		  contextInfo:contextInfo];
	int returnCode = [NSApp runModalForWindow:panel];
	
	[NSApp endSheet:panel returnCode:returnCode];
	[panel orderOut:self];
	
	if(modalDelegate != nil && didDismissSelector != NULL){
		NSMethodSignature *signature = [modalDelegate methodSignatureForSelector:didDismissSelector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:didDismissSelector];
		[invocation setArgument:&self atIndex:2];
		[invocation setArgument:&returnCode atIndex:3];
		[invocation setArgument:&contextInfo atIndex:4];
		[invocation invokeWithTarget:modalDelegate];
	}
	
    modalDelegate = nil;
	didEndSelector = NULL;
	didDismissSelector = NULL;
	
	return returnCode;
}

- (void)setMessageText:(NSString *)messageText {
	[messageField setStringValue:messageText];
}

- (NSString *)messageText {
	return [messageField stringValue];
}

- (void)setInformativeText:(NSString *)informativeText {
	[informationField setStringValue:informativeText];
}

- (NSString *)informativeText {
	return [informationField stringValue];
}

- (void)setCheckText:(NSString *)checkText {
	[checkButton setTitle:checkText];
}

- (NSString *)checkText {
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
	[checkButton setState:flag ? NSOnState : NSOffState];
}

- (BOOL)checkValue {
	return ([checkButton state] == NSOnState);
}

- (NSImage *)icon {
	return unbadgedImage;
}

- (NSWindow *)window {
	return panel;
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
	[button setAction:@selector(buttonPressed:)];
	if (numButtons == 0) {
		[button setKeyEquivalent:@"\r"];
	} else if ([aTitle isEqualToString:NSLocalizedString(@"Cancel", @"Cancel")]) {
		[button setKeyEquivalent:@"\e"];
	} else if ([aTitle isEqualToString:NSLocalizedString(@"Don't Save", @"Don't Save")]) {
		[button setKeyEquivalent:@"d"];
		[button setKeyEquivalentModifierMask:NSCommandKeyMask];
	}
	[button sizeToFit];
	buttonRect = [button frame];
	if (NSWidth(buttonRect) < minButtonSize.width) 
		buttonRect.size.width = minButtonSize.width;
	if (numButtons == 0)
		buttonRect.origin.x = NSMaxX([[panel contentView] bounds]) - NSWidth(buttonRect) - 14.0;
	else
		buttonRect.origin.x = NSMinX([[buttons lastObject] frame]) - NSWidth(buttonRect);
	[button setFrame:buttonRect];
	[button setAutoresizingMask:NSViewMinXMargin | NSViewMaxXMargin];
	[[panel contentView] addSubview:button];
	[buttons addObject:button];
	[button release];
	return button;
}

- (NSArray *)buttons {
	return buttons;
}

- (NSButton *)checkButton {
	return checkButton;
}

@end

@implementation BDSKAlert (Private)

- (void)prepare {
	NSString *title;
	int numButtons = [buttons count];
	NSRect buttonRect;
	int i;
	NSButton *button = nil;
	float x;
	
	switch (alertStyle) {
		case NSCriticalAlertStyle: 
			title = NSLocalizedString(@"Critical", @"Critical");
			break;
		case NSInformationalAlertStyle: 
			title = NSLocalizedString(@"Information", @"Information");
			break;
		case NSWarningAlertStyle:
		default:
			title = NSLocalizedString(@"Alert", @"Alert");
	}
	[panel setTitle: title];
	
    // see if we should resize the message text
    NSRect frame = [panel frame];
    NSRect infoRect = [informationField frame];
    
    NSTextStorage *textStorage = [[[NSTextStorage alloc] initWithAttributedString:[informationField attributedStringValue]] autorelease];
    NSTextContainer *textContainer = [[[NSTextContainer alloc] initWithContainerSize:NSMakeSize(NSWidth(infoRect), 100.0)] autorelease];
    NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];
    
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    [layoutManager glyphRangeForTextContainer:textContainer];
    
    int numLines = ceilf(NSHeight([layoutManager usedRectForTextContainer:textContainer]) / 13.0);

    if (numLines > 3) {
        // I don't know why it uses a different lineheight from the layoutManager...
        float extraHeight = numLines * 14.0 - NSHeight(infoRect);
        frame.size.height += extraHeight;
        infoRect.size.height += extraHeight;
        infoRect.origin.y -= extraHeight;
        [informationField setFrame:infoRect];
		[panel setFrame:frame display:NO];
    }
    
	if (hasCheckButton == NO) {
		frame.size.height -= 22.0;
		[checkButton removeFromSuperview];
		[panel setFrame:frame display:NO];
	}
	
	if (numButtons == 0)
		[self addButtonWithTitle:NSLocalizedString(@"OK", @"OK")];
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
		NSRect badgeRect = NSMakeRect(32.0, 1.0, 32.0, 32.0);
		CGRect iconRect =  CGRectMake(0.0, 0.0, 64.0, 64.0);
		IconRef iconRef;
		OSErr myErr = GetIconRef(kOnSystemDisk, kSystemIconsCreator, kAlertCautionIcon, &iconRef);
		
		imageRect.size = [unbadgedImage size];
		
		image = [[NSImage alloc] initWithSize:NSMakeSize(64.0, 64.0)]; 
		
		[image lockFocus]; 
		
		PlotIconRefInContext((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort],
							 &iconRect,
							 kAlignAbsoluteCenter, //kAlignNone,
							 kTransformNone,
							 NULL /*inLabelColor*/,
							 kPlotIconRefNormalFlags,
							 iconRef); 
		[unbadgedImage drawInRect:badgeRect fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];
		[image unlockFocus]; 
		
		myErr = ReleaseIconRef(iconRef);
		
		[image autorelease];	
	}
	
	[imageView setImage:image];
}

- (void)buttonPressed:(id)sender {
	int returnCode = [sender tag];
	if (runAppModal) {
		[NSApp stopModalWithCode:returnCode];
	} else {
		[NSApp endSheet:panel returnCode:returnCode];
	}
}

- (void)didEndAlert:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if(modalDelegate != nil && didEndSelector != NULL){
		NSMethodSignature *signature = [modalDelegate methodSignatureForSelector:didEndSelector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:didEndSelector];
		[invocation setArgument:&self atIndex:2];
		[invocation setArgument:&returnCode atIndex:3];
		[invocation setArgument:&contextInfo atIndex:4];
		[invocation invokeWithTarget:modalDelegate];
	}
	
	if (runAppModal == NO) {
		modalDelegate = nil;
		didEndSelector = NULL;
		
		[sheet orderOut:self];
		[self release];
	}
}

@end
