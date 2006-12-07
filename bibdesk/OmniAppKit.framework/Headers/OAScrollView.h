// Copyright 1997-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <AppKit/NSScrollView.h>

@class NSButton, NSMenuItem, NSPopUpButton, NSTextField;

typedef enum { YES_SCROLL, NO_SCROLL, AUTO_SCROLL } ScrollingBehavior;

#import <Foundation/NSString.h> // For unichar

@interface OAScrollView : NSScrollView
{
    NSView *horizontalWidgetsBox;
    NSPopUpButton *scalePopUpButton;
    NSButton *pageUpButton;
    NSButton *pageDownButton;
    NSTextField *pagePromptTextField;
    NSTextField *pageNumberTextField;
    NSTextField *pagesCountTextField;
    float zoomFactor;
    ScrollingBehavior scrollBehavior;
    id delegate;
    struct {
        unsigned int tiling:1;
        unsigned int smoothScrollDisabled;
    } flags;
}


- (void)zoomToScale:(double)newZoomFactor;
- (void)zoomFromSender:(NSMenuItem *)sender;
- (float)zoomFactor;
- (void)setDelegate:(id)newDelegate;
- (void)setScrollBehavior:(ScrollingBehavior)behavior;
- (void)showingPageNumber:(int)pageNumber of:(unsigned int)pagesCount;
- (void)gotoPage:(id)sender;
- (BOOL)processKeyDownCharacter:(unichar)character modifierFlags:(unsigned int)modifierFlags;

- (void)setSmoothScrollEnabled:(BOOL)smoothScrollEnabled;
- (BOOL)smoothScrollEnabled;

- (NSSize)idealSizeForAvailableSize:(NSSize)availableSize;
    // Returns the largest size which would actually be useful in displaying the content view, given a particular availableSize (which determines whether scrollers would be necessary, but doesn't actually limit the return value).

@end
