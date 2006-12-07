// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/OAFontView.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import <OmniAppKit/NSString-OAExtensions.h>
//#import <OmniAppKit/ps.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAFontView.m,v 1.21 2004/02/10 04:07:37 kc Exp $")

@implementation OAFontView

// Init and dealloc

- initWithFrame:(NSRect)frameRect
{
    if (![super initWithFrame:frameRect])
        return nil;

    [self setFont:[NSFont userFontOfSize:0]];

    return self;
}

- (void)dealloc;
{
    [font release];
    [fontDescription release];
    [super dealloc];
}

//

- (void) setDelegate: (id) aDelegate;
{
    delegate = aDelegate;
}

- (id) delegate;
{
    return delegate;
}

- (NSFont *)font;
{
    return font;
}

- (void)setFont:(NSFont *)newFont;
{
    if (font == newFont)
	return;

    [font release];
    font = [newFont retain];

    [fontDescription release];
    fontDescription = [[NSString alloc] initWithFormat:@"%@ %.1f", [font displayName], [font pointSize]];
    textSize.height = ceil(NSHeight([font boundingRectForFont]));
    textSize.width = ceil([font widthOfString:fontDescription]);
    [self setNeedsDisplay:YES];
}

- (IBAction)setFontUsingFontPanel:(id)sender;
{
    if ([[self window] makeFirstResponder:self]) {
        NSFontManager *manager;
        NSFontPanel *panel;
        
        manager = [NSFontManager sharedFontManager];
        panel = [manager fontPanel: YES];
        [panel setDelegate: self];
	[manager orderFrontFontPanel:sender];
    }
}

// NSFontManager sends -changeFont: up the responder chain

- (BOOL)fontManager:(id)sender willIncludeFont:(NSString *)fontName;
{
    if ([delegate respondsToSelector: @selector(fontView:fontManager:willIncludeFont:)])
        return [delegate fontView: self fontManager: sender willIncludeFont: fontName];
    return YES;
}

- (void)changeFont:(id)sender;
{
    if ([delegate respondsToSelector: @selector(fontView:shouldChangeToFont:)])
        if (![delegate fontView:self shouldChangeToFont:font])
            return;

    [self setFont:[sender convertFont:[sender selectedFont]]];
    
    if ([delegate respondsToSelector: @selector(fontView:didChangeToFont:)])
        [delegate fontView:self didChangeToFont:font];
}

// NSFontPanel delegate


// NSView subclass

- (void)drawRect:(NSRect)rect
{
    NSRect bounds;

    bounds = [self bounds];
    if ([NSGraphicsContext currentContextDrawingToScreen])
        [[NSColor windowBackgroundColor] set];
    else
        [[NSColor whiteColor] set];
    NSRectFill(bounds);

    [[NSColor gridColor] set];
    NSFrameRect(bounds);
    [fontDescription drawWithFont:font color:[NSColor textColor] alignment:NSCenterTextAlignment verticallyCenter:YES inRectangle:bounds];

    if ([NSGraphicsContext currentContextDrawingToScreen] && [[self window] firstResponder] == self) {
	[[NSColor keyboardFocusIndicatorColor] set];
        NSFrameRect(NSInsetRect(bounds, 1.0, 1.0));
    }
}

- (BOOL)isFlipped;
{
    return YES;
}

- (BOOL)isOpaque;
{
    return YES;
}

// NSResponder subclass

- (BOOL)acceptsFirstResponder;
{
    return YES;
}

- (BOOL)becomeFirstResponder;
{
    if ([super becomeFirstResponder]) {
	[[NSFontManager new] setSelectedFont:font isMultiple:NO];
	[self setNeedsDisplay:YES];
	return YES;
    }
    return NO;
}

- (BOOL)resignFirstResponder;
{
    if (![[self window] isKeyWindow] ||
	![super resignFirstResponder])
	return NO;
    [self setNeedsDisplay:YES];
    return YES;
}

// Debugging

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [super debugDictionary];
    if (font)
        [debugDictionary setObject:font forKey:@"font"];
    if (fontDescription)
        [debugDictionary setObject:fontDescription forKey:@"fontDescription"];
    [debugDictionary setObject:NSStringFromSize(textSize) forKey:@"textSize"];
    return debugDictionary;
}

@end
