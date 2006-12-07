// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniAppKit/OAOutlineTextFormatter.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>

#import <OmniAppKit/OAOutlineEntry.h>
#import <OmniAppKit/OAOutlineView.h>
#import <OmniAppKit/NSString-OAExtensions.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Outline.subproj/OAOutlineTextFormatter.m,v 1.11 2003/01/15 22:51:40 kc Exp $")

@implementation OAOutlineTextFormatter

- init
{
    [super init];
    [self setFont:[NSFont userFontOfSize:12.0]];
    [self setTextColor: [NSColor controlTextColor]];
    [self setTextAlignment:NSLeftTextAlignment];
    stringValueSelector = NULL;
    stringValueSelectorArgument = nil;
    return self;
}

- (void)dealloc
{
    [font release];
    [textColor release];
    [stringValueSelectorArgument release];
    [super dealloc];
}

// Text attributes

- (void)setFont:(NSFont *)aFont;
{
    NSFont	*testFont;

    if ((testFont = [aFont screenFont]))
        font = [testFont retain];
    else
        font = [aFont retain];
}

- (void)setTextColor: (NSColor *) aColor;
{
    if (textColor != aColor) {
        [textColor release];
        textColor = [aColor retain];
    }
}

- (void)setTextAlignment:(NSTextAlignment) newAlignment;
{
    alignment = newAlignment;
}

// These methods let you specify a selector to be used for getting a displayable string value from the object we are formatting

- (void)setValueSelector:(SEL)aSelector;
{
    [self setValueSelector:aSelector withObject:nil];
}

- (void)setValueSelector:(SEL)aSelector withObject:(id <NSObject>)anObject;
{
    stringValueSelector = aSelector;
    [anObject retain];
    [stringValueSelectorArgument release];
    stringValueSelectorArgument = anObject;
}

// OAOutlineFormatter subclass

- (float)entryHeight:(OAOutlineEntry *)anEntry;
{
    float height;
    float superHeight;

    height = ceil(NSHeight([font boundingRectForFont]) + 3.0 /* 2 for inset, 1 for extra space above text */ );
    superHeight = [super entryHeight:anEntry];
    return height > superHeight ? height : superHeight;
}

- (NSString *)_stringForEntry:(OAOutlineEntry *)anEntry;
{
    return [(NSString *)[[anEntry representedObject] performSelector:stringValueSelector withObject:stringValueSelectorArgument] description];
}

- (void)drawEntry:(OAOutlineEntry *)anEntry entryRect:(NSRect)rect selected:(BOOL)selected parent:(BOOL)parent hidden:(BOOL)hidden dragging:(BOOL)dragging;
{
    NSString *string;
    NSRect newRectangle;
    float buttonWidth;

    [super drawEntry:anEntry entryRect:rect selected:selected parent:parent
	hidden:hidden dragging:dragging];

    if (dragging)
        return;

    if (!(string = [self _stringForEntry:anEntry]))
	return;

    buttonWidth = [super buttonWidth];
    newRectangle = rect;
    newRectangle.origin.x += buttonWidth;
    newRectangle.size.width -= buttonWidth;
    newRectangle = NSInsetRect(newRectangle, 2, 0);

    [string drawWithFont:font color:textColor alignment:alignment rectangle:newRectangle];
}

@end
