// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OASearchField.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>
#import "NSImage-OAExtensions.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OASearchField.m 66852 2005-08-13 03:14:45Z kc $");

@interface OASearchField (Private)
- (NSRect)_textRectForBounds:(NSRect)bounds;
- (NSRect)_leftImageRectForBounds:(NSRect)bounds;
- (void)_drawLeftImageForBounds:(NSRect)bounds;
- (NSRect)_middleImageRectForBounds:(NSRect)bounds;
- (void)_drawMiddleImageForBounds:(NSRect)bounds;
- (NSRect)_rightImageRectForBounds:(NSRect)bounds;
- (void)_drawRightImageForBounds:(NSRect)bounds;
- (NSRect)_closeBoxRectForBounds:(NSRect)bounds;
- (void)_drawCloseBoxForBounds:(NSRect)bounds;
- (void)_clickOnSearchMenu;
- (void)_clickOnCloseBox;
- (BOOL)_closeBoxVisible;
- (void)_setCloseBoxVisible:(BOOL)flag;
- (void)_searchFieldBecameFirstResponder;
- (void)_showSearchModeString;
- (void)_clearSearchModeString;
- (void)_chooseSearchMode:(id)sender;
- (void)_performSearch;
- (void)_performSearch:(id)sender;
- (BOOL)_userIsEditingSearchField;

- (void)_destroyPartialStringActionDelayTimer;
- (void)_partialStringActionDelayTimerFired:(NSTimer *)timer;
@end

static NSImage *OASearchFieldLeftImage = nil;
static NSImage *OASearchFieldLeftWithArrowImage = nil;
static NSSize OASearchFieldLeftImageSize;
static NSImage *OASearchFieldMiddleImage = nil;
static NSSize OASearchFieldMiddleImageSize;
static NSImage *OASearchFieldRightImage = nil;
static NSSize OASearchFieldRightImageSize;
static NSImage *OASearchFieldCloseImage = nil;
static NSSize OASearchFieldCloseImageSize;
static NSImage *OASearchFieldCloseDownImage = nil;

//
// OASearchTextField - custom NSTextField class to help OASearchField clear the "search mode" from the text field when it becomes the first responder.
//

@interface OASearchTextField : NSTextField {}
@end

@implementation OASearchTextField

- (BOOL)becomeFirstResponder;
{
    BOOL result = [super becomeFirstResponder];

    [(OASearchField *)[self superview] _searchFieldBecameFirstResponder];
        
    return result;
}

//
// End OASearchTextField
//

@end

@implementation OASearchField

+ (void)initialize;
{
    NSBundle *bundle;
    
    OBINITIALIZE;
    
    bundle = [self bundle];

    OBPRECONDITION(OASearchFieldLeftImage == nil);
    OBPRECONDITION(OASearchFieldLeftWithArrowImage == nil);
    OBPRECONDITION(OASearchFieldMiddleImage == nil);
    OBPRECONDITION(OASearchFieldRightImage == nil);
    OBPRECONDITION(OASearchFieldCloseImage == nil);
    OBPRECONDITION(OASearchFieldCloseDownImage == nil);

    OASearchFieldLeftImage = [[NSImage imageNamed:@"OASearchFieldLeft" inBundle:bundle] retain];
    OASearchFieldLeftImageSize = [OASearchFieldLeftImage size];
    OASearchFieldLeftWithArrowImage = [[NSImage imageNamed:@"OASearchFieldLeftWithArrow" inBundle:bundle] retain];
    OBASSERT((OASearchFieldLeftImageSize.width == [OASearchFieldLeftWithArrowImage size].width) && (OASearchFieldLeftImageSize.height == [OASearchFieldLeftWithArrowImage size].height));
    OASearchFieldMiddleImage = [[NSImage imageNamed:@"OASearchFieldMiddle" inBundle:bundle] retain];
    OASearchFieldMiddleImageSize = [OASearchFieldMiddleImage size];
    OASearchFieldRightImage = [[NSImage imageNamed:@"OASearchFieldRight" inBundle:bundle] retain];
    OASearchFieldRightImageSize = [OASearchFieldRightImage size];
    OASearchFieldCloseImage = [[NSImage imageNamed:@"OASearchFieldClose" inBundle:bundle] retain];
    OASearchFieldCloseImageSize = [OASearchFieldCloseImage size];
    OASearchFieldCloseDownImage = [[NSImage imageNamed:@"OASearchFieldCloseDown" inBundle:bundle] retain];

    OBPOSTCONDITION(OASearchFieldLeftImage != nil);
    OBPOSTCONDITION(OASearchFieldLeftWithArrowImage != nil);
    OBPOSTCONDITION(OASearchFieldMiddleImage != nil);
    OBPOSTCONDITION(OASearchFieldRightImage != nil);
    OBPOSTCONDITION(OASearchFieldCloseImage != nil);
    OBPOSTCONDITION(OASearchFieldCloseDownImage != nil);
}

// NSView subclass

+ (Class)cellClass;
{
    // Use NSActionCell in order to get target/action behavior and fun NIB connecty stuff
    return [NSActionCell class];
}

- (id)initWithFrame:(NSRect)frame;
{    
    if ([super initWithFrame:frame] == nil)
        return nil;
    
    // Create search field
    searchField = [[OASearchTextField alloc] initWithFrame:[self _textRectForBounds:[self bounds]]];
    [searchField setDelegate:self];
    [[searchField cell] setScrollable:YES];
    [searchField setEditable:YES];
    [searchField setBordered:NO];
    [searchField setAutoresizingMask:NSViewWidthSizable];
    [searchField setTarget:self];
    [searchField setAction:@selector(_performSearch:)];
    [[searchField cell] setSendsActionOnEndEditing:NO];
    [self addSubview:searchField];
    
    [self _showSearchModeString];
    [self setSendsWholeSearchString:YES];
    
    return self;
}

- (void)dealloc;
{
    [searchField removeFromSuperviewWithoutNeedingDisplay];
    [searchField release];
    searchField = nil;
    
    [menu release];
    menu = nil;
    
    [searchMode release];
    searchMode = nil;
    
    [self _destroyPartialStringActionDelayTimer];
    
    [super dealloc];
}

// OABackgroundImageControl subclass

- (void)drawForegroundRect:(NSRect)rect;
{
    // Draw close box
    if ([self _closeBoxVisible])
        [self _drawCloseBoxForBounds:[self bounds]];
}

// NSView subclass

- (BOOL)acceptsFirstResponder;
{
    return YES;
}

- (BOOL)becomeFirstResponder;
{
    return [[self window] makeFirstResponder:searchField];
}

- (void)mouseDown:(NSEvent *)event;
{
    NSRect bounds;
    NSPoint viewPoint;
    
    bounds = [self bounds];
    viewPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    if (NSPointInRect(viewPoint, [self _leftImageRectForBounds:bounds]))
        [self _clickOnSearchMenu];
    else if (NSPointInRect(viewPoint, [self _closeBoxRectForBounds:bounds]))
        [self _clickOnCloseBox];
}

- (NSView *)hitTest:(NSPoint)aPoint;
{
    NSPoint viewPoint;
    
    viewPoint = [self convertPoint:aPoint fromView:[self superview]];
    if (NSPointInRect(viewPoint, [self bounds])) {
        if (!NSPointInRect(viewPoint, [searchField frame]))
            return self;
    }
    
    return [super hitTest:aPoint];
}

- (NSFont *)font;
{
    return [searchField font];
}

- (void)setFont:(NSFont *)font;
{
    [searchField setFont:font];
    [searchField setFrame:[self _textRectForBounds:[self bounds]]];
}

// OABackgroundImageControl subclass

- (void)drawBackgroundImageForBounds:(NSRect)bounds;
{
    [self _drawLeftImageForBounds:bounds];
    [self _drawMiddleImageForBounds:bounds];
    [self _drawRightImageForBounds:bounds];
}

// API

- (id)delegate;
{
    return delegate;
}

- (void)setDelegate:(id)newValue;
{
    delegate = newValue;
    
    delegateRespondsTo.searchFieldDidEndEditing = [delegate respondsToSelector:@selector(searchFieldDidEndEditing:)];
    delegateRespondsTo.searchField_didChooseSearchMode = [delegate respondsToSelector:@selector(searchField:didChooseSearchMode:)];
    delegateRespondsTo.searchField_validateMenuItem = [delegate respondsToSelector:@selector(searchField:validateMenuItem:)];
    delegateRespondsTo.control_textView_doCommandBySelector = [delegate respondsToSelector:@selector(control:textView:doCommandBySelector:)];
}

- (NSMenu *)menu;
{
    return menu;
}

- (void)setMenu:(NSMenu *)aMenu;
{
    NSArray *items;
    unsigned int itemCount, itemIndex;
    id newSearchMode = nil, firstSearchMode = nil;

    // If we didn't have a menu and now we do, or we did and now we don't, we need to redisplay because we want to draw a different search icon.
    if ((menu != aMenu) && ((menu == nil) || (aMenu == nil)))
        [self setNeedsDisplay];
    
    [menu release];
    menu = [aMenu retain];
    items = [menu itemArray];
    itemCount = [items count];
    for (itemIndex = 0; itemIndex < itemCount; itemIndex++) {
        NSMenuItem *item;
        id aSearchMode;
        
        item = [items objectAtIndex:itemIndex];
        if ([item target] != nil)
            [item setTarget:self];
        if ([item action] == NULL)
            [item setAction:@selector(_chooseSearchMode:)];
        
        // Find the first non-nil search mode in case we can't preserve the previously selected search mode
        aSearchMode = [item representedObject];
        if (firstSearchMode == nil && aSearchMode != nil)
            firstSearchMode = aSearchMode;
        
        // Try to preserve the previously selected search mode
        if ([aSearchMode isEqual:searchMode])
            newSearchMode = aSearchMode;
    }
        
    // If the previously selected search mode is no longer in the menu, use the first one found
    if (newSearchMode == nil)
        newSearchMode = firstSearchMode;
        
    // Restore the previously selected search mode
    [self setSearchMode:newSearchMode];
}

- (void)selectText:(id)sender;
{
    flags.isSelectingText = YES;
    
    [searchField selectText:sender];
    // maybe shouldn't ideally try to change the first responder, but otherwise it's a pain for the caller, since they can't simply make _us_ the first responder in order to get the search field as the first responder
    [[self window] makeFirstResponder:searchField];
    
    flags.isSelectingText = NO;
}

- (NSString *)stringValue;
{
    if (flags.isShowingSearchModeString) {
        return @"";
    }
    return [searchField stringValue];
}

- (void)setStringValue:(NSString *)newValue;
{
    [self _clearSearchModeString];
    if ([NSString isEmptyString:newValue]) {
        [self _setCloseBoxVisible:NO];
        [self _showSearchModeString];
    } else {
        [self _setCloseBoxVisible:YES];
        [searchField setStringValue:newValue];
    }
}

- (id)searchMode;
{
    return searchMode;
}

- (void)setSearchMode:(id)newSearchMode;
{
    int selectedItemIndex;
    NSArray *items;
    unsigned int itemCount, itemIndex;
    id oldSearchMode;

    selectedItemIndex = [menu indexOfItemWithRepresentedObject:newSearchMode];
    if (selectedItemIndex == NSNotFound)
        return;
        
    oldSearchMode = [searchMode retain];
        
    items = [menu itemArray];
    itemCount = [items count];
    for (itemIndex = 0; itemIndex < itemCount; itemIndex++) {
        [[items objectAtIndex:itemIndex] setState:((int)itemIndex == selectedItemIndex)];
    }
    
    [searchMode release];
    searchMode = [newSearchMode retain];
    
    // If the old search mode is no longer in the menu, and the user is not editing the search field, update its search mode string
    if (oldSearchMode == nil || ![searchMode isEqual:oldSearchMode]) {
        // Never show the search mode when the user is typing in the field -- we can't check for this in -_showSearchModeString because it's called by -controlTextDidEndEditing:, which is called before the text field loses first-responder status.
        if (![self _userIsEditingSearchField]) {
            [self _clearSearchModeString];
            [self _setCloseBoxVisible:NO];
            [self _showSearchModeString];
        }
    }
    
    [oldSearchMode release];
}

- (void)updateSearchModeString;
{
    if (![self _userIsEditingSearchField]) {
        flags.isShowingSearchModeString = NO;
        [self _showSearchModeString];
    }
        
}

- (BOOL)sendsActionOnEndEditing;
{
    return [[searchField cell] sendsActionOnEndEditing];
}

- (void)setSendsActionOnEndEditing:(BOOL)newValue;
{
    [[searchField cell] setSendsActionOnEndEditing:newValue];
}

- (BOOL)sendsWholeSearchString;
{
    return flags.sendsWholeSearchString;
}

- (void)clearSearch;
{
	[searchField setStringValue:@""];
	[self _performSearch:nil];
	[self _setCloseBoxVisible:NO];
}

- (void)setSendsWholeSearchString:(BOOL)newValue;
{
    flags.sendsWholeSearchString = newValue;
    if (flags.sendsWholeSearchString) {
        // if we're only supposed to send the action at the end of editing, clear any action queued up to be sent
        [self _destroyPartialStringActionDelayTimer];
    }
}


//
// Validation
//

- (BOOL)validateMenuItem:(NSMenuItem *)item;
{
    OBPRECONDITION([item menu] == menu);
    if (delegateRespondsTo.searchField_validateMenuItem)
        return [delegate searchField:self validateMenuItem:item];
    return YES;
}

@end

@implementation OASearchField (NotificationsDelegatesDatasources)

// NSControl delegate

- (void)controlTextDidChange:(NSNotification *)notification;
{
    if ([notification object] == searchField) {
        [self _setCloseBoxVisible:![[self stringValue] isEqualToString:@""]];

        if (!flags.sendsWholeSearchString) {
            [self _destroyPartialStringActionDelayTimer];
            partialStringActionDelayTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:0.3] interval:0.0 target:self selector:@selector(_partialStringActionDelayTimerFired:) userInfo:nil repeats:NO];
            [[NSRunLoop currentRunLoop] addTimer:partialStringActionDelayTimer forMode:NSDefaultRunLoopMode];
        }
    }
}

- (void)controlTextDidEndEditing:(NSNotification *)notification;
{
    if ([notification object] == searchField)
        [self _showSearchModeString];

    if (!flags.isSelectingText && delegateRespondsTo.searchFieldDidEndEditing)
        [delegate searchFieldDidEndEditing:self];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector;
{
    if (delegateRespondsTo.control_textView_doCommandBySelector)
        return [delegate control:self textView:textView doCommandBySelector:commandSelector];
    else
        return NO;
}

@end

@implementation OASearchField (Private)

- (NSRect)_textRectForBounds:(NSRect)bounds;
{
    NSRect textRect = NSInsetRect([self _middleImageRectForBounds:bounds], 1, 3);
    
    if ([[self font] isEqual:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]])
        textRect.origin.y -= 1.0;

    return textRect;
}

- (NSRect)_leftImageRectForBounds:(NSRect)bounds;
{
    return NSMakeRect(0, 0, OASearchFieldLeftImageSize.width, NSHeight(bounds));
}

- (void)_drawLeftImageForBounds:(NSRect)bounds;
{
    NSRect imageRect = [self _leftImageRectForBounds:bounds];
    NSImage *image = (menu == nil) ? OASearchFieldLeftImage : OASearchFieldLeftWithArrowImage;
    [image drawInRect:imageRect fromRect:(NSRect){ { 0, 0 }, OASearchFieldLeftImageSize } operation:NSCompositeSourceOver fraction:1.0];
}

- (NSRect)_middleImageRectForBounds:(NSRect)bounds;
{
    return NSMakeRect(OASearchFieldLeftImageSize.width, 0, NSWidth(bounds) - OASearchFieldRightImageSize.width - OASearchFieldLeftImageSize.width, NSHeight(bounds));
}

- (void)_drawMiddleImageForBounds:(NSRect)bounds;
{
    [OASearchFieldMiddleImage drawInRect:[self _middleImageRectForBounds:bounds] fromRect:(NSRect){ { 0, 0 }, OASearchFieldMiddleImageSize } operation:NSCompositeSourceOver fraction:1.0];
}

- (NSRect)_rightImageRectForBounds:(NSRect)bounds;
{
    return NSMakeRect(NSMaxX(bounds) - OASearchFieldRightImageSize.width, 0, OASearchFieldRightImageSize.width, NSHeight(bounds));
}

- (void)_drawRightImageForBounds:(NSRect)bounds;
{
    [OASearchFieldRightImage drawInRect:[self _rightImageRectForBounds:bounds] fromRect:(NSRect){ { 0, 0 }, OASearchFieldRightImageSize } operation:NSCompositeSourceOver fraction:1.0];
}

- (NSRect)_closeBoxRectForBounds:(NSRect)bounds;
{
    NSRect rightImageRect;
    NSRect closeBoxRect;
    
    rightImageRect = [self _rightImageRectForBounds:bounds];
    closeBoxRect = NSMakeRect(rint(NSMidX(rightImageRect) - (OASearchFieldCloseImageSize.width / 2.0)), rint(NSMidY(rightImageRect) - (OASearchFieldCloseImageSize.height / 2.0)), OASearchFieldCloseImageSize.width, OASearchFieldCloseImageSize.height);
    
    return closeBoxRect;
}

- (void)_drawCloseBoxForBounds:(NSRect)bounds;
{
    NSImage *closeImage;
    
    if (flags.mouseDownInCloseBox)
        closeImage = OASearchFieldCloseDownImage;
    else
        closeImage = OASearchFieldCloseImage;
        
    [closeImage drawInRect:[self _closeBoxRectForBounds:bounds] fromRect:(NSRect){ { 0, 0 }, OASearchFieldCloseImageSize } operation:NSCompositeSourceOver fraction:1.0];
}

- (void)_clickOnSearchMenu;
{
    NSEvent *event;
    NSRect bounds;
    NSPoint fakeLocation;
    NSEvent *fakeEvent;
    
    if (flags.isShowingMenu)
        return;

    flags.isShowingMenu = YES;
    
    // If we're showing the search mode, clear it (since the user is probably about to do a search)
    if (flags.isShowingSearchModeString)
        [self _clearSearchModeString];
        
    // Select what's in the search field so that the user can easily replace it after setting a search mode
    [searchField selectText:nil];
    
    // Generate a fake event so that the top of the menu sits at the bottom of the search view
    event = [NSApp currentEvent];
    bounds = [self bounds];
    fakeLocation = [self convertPoint:NSMakePoint(NSMinX(bounds) + 5.0, NSMinY(bounds) - 7.0) toView:nil];
    fakeEvent = [NSEvent mouseEventWithType:[event type] location:fakeLocation modifierFlags:[event modifierFlags] timestamp:[event timestamp] windowNumber:[event windowNumber] context:[event context] eventNumber:[event eventNumber] clickCount:[event clickCount] pressure:[event pressure]];
    
    // Show the menu
    [NSMenu popUpContextMenu:menu withEvent:fakeEvent forView:self];

    flags.isShowingMenu = NO;
}

- (void)_clickOnCloseBox;
{
    BOOL shouldClose = NO;
    NSRect closeBoxRect;
    NSDate *distantFuture = [NSDate distantFuture];
    
    // Mouse down in close box
    closeBoxRect = [self _closeBoxRectForBounds:[self bounds]];
    flags.mouseDownInCloseBox = YES;
    [self setNeedsDisplayInRect:closeBoxRect];
    
    // Track the mouse until it is released
    while (1) {
        NSEvent *event;
        NSPoint point;
        
        // Get the next mouse up/drag event and location
        event = [NSApp nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask) untilDate:distantFuture inMode:NSDefaultRunLoopMode dequeue:YES];
        point = [self convertPoint:[event locationInWindow] fromView:nil];
        
        // Highlight the button if the mouse is inside its bounds
        if (NSPointInRect(point, closeBoxRect)) {
            flags.mouseDownInCloseBox = YES;
            [self setNeedsDisplayInRect:closeBoxRect];
        } else if (flags.mouseDownInCloseBox) {
            flags.mouseDownInCloseBox = NO;
            [self setNeedsDisplayInRect:closeBoxRect];
        }
        
        if ([event type] == NSLeftMouseUp) {
            if (NSPointInRect(point, closeBoxRect))
                shouldClose = YES;
            break;
        }
    }

    // Mouse up in close box
    flags.mouseDownInCloseBox = NO;
    [self setNeedsDisplayInRect:closeBoxRect];
    
    // If the mouse was released inside the close box, clear the search field and perform a search.  The target is expected to understand that a blank search string means "Stop searching".
    if (shouldClose) {
		[self clearSearch];
        [[self window] makeFirstResponder:searchField];
    }
}

- (BOOL)_closeBoxVisible;
{
    return flags.closeBoxVisible;
}

- (void)_setCloseBoxVisible:(BOOL)flag;
{
    if (flags.closeBoxVisible == flag)
        return;
        
    flags.closeBoxVisible = flag;
    [self setNeedsDisplay:YES];
}

- (void)_searchFieldBecameFirstResponder;
{
    if (flags.isShowingSearchModeString)
        [self _clearSearchModeString];
}

- (void)_showSearchModeString;
{
    NSString *searchModeName;
    
    // Don't show the search mode if the close box is visible
    if ([self _closeBoxVisible])
        return;
        
    // Don't show the search mode if the menu is visible or if the search mode is already visible
    if (flags.isShowingSearchModeString || flags.isShowingMenu)
        return;
    
    // Get the search mode from the selected menu item if possible
    if (menu != nil) {
        if (searchMode != nil) {
            int searchModeIndex;
            
            searchModeIndex = [menu indexOfItemWithRepresentedObject:searchMode];
            if (searchModeIndex == -1)
                searchModeName = NSLocalizedStringFromTableInBundle(@"Search", @"OmniAppKit", [OASearchField bundle], @"default search mode menu item");
            else {
                NSMenuItem *item = [menu itemAtIndex:searchModeIndex];
                [self validateMenuItem:item];	// Make sure the item title is up to date (but don't actually disable the menu item if validation returns NO)
                searchModeName = [item title];
            }
        } else
            searchModeName = NSLocalizedStringFromTableInBundle(@"Search", @"OmniAppKit", [OASearchField bundle], @"default search mode menu item");
    } else
        searchModeName = NSLocalizedStringFromTableInBundle(@"Search", @"OmniAppKit", [OASearchField bundle], @"default search mode menu item");
    
    [searchField setTextColor:[NSColor disabledControlTextColor]];
    [searchField setStringValue:searchModeName];
    flags.isShowingSearchModeString = YES;
}

- (void)_clearSearchModeString;
{
    [searchField setTextColor:[NSColor controlTextColor]];
    [searchField setStringValue:@""];
    flags.isShowingSearchModeString = NO;
}

- (void)_chooseSearchMode:(id)sender;
{
    [self setSearchMode:[sender representedObject]];
    if (delegateRespondsTo.searchField_didChooseSearchMode)
        [delegate searchField:self didChooseSearchMode:[self searchMode]];
}

- (void)_performSearch;
{
    [self _destroyPartialStringActionDelayTimer];
    [self sendAction:[self action] to:[self target]];
}

- (void)_performSearch:(id)sender;
{
    [self _performSearch];
}

- (BOOL)_userIsEditingSearchField;
{
    NSResponder *firstResponder;

    firstResponder = [[self window] firstResponder];
    return ([firstResponder isKindOfClass:[NSView class]] && [(NSView *)firstResponder isDescendantOf:searchField]);
}

- (void)_destroyPartialStringActionDelayTimer;
{
    if (partialStringActionDelayTimer != nil) {
        [partialStringActionDelayTimer invalidate];
        [partialStringActionDelayTimer release];
        partialStringActionDelayTimer = nil;
    }
}

- (void)_partialStringActionDelayTimerFired:(NSTimer *)timer;
{
    OBASSERT(timer == partialStringActionDelayTimer);
    [self _performSearch];
}

@end
