// Copyright 2001-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OATextWithIconCell.h,v 1.11 2004/02/10 04:07:38 kc Exp $

#import <AppKit/NSBrowserCell.h>

// NOTE: Don't depend on this remaining a subclass of NSBrowserCell!

@interface OATextWithIconCell : NSTextFieldCell 
{
    NSImage *icon;
    struct {
        unsigned int drawsHighlight:1;
        unsigned int imagePosition:3;
        unsigned int settingUpFieldEditor:1;
    } _oaFlags;
}

// API
- (NSImage *)icon;
- (void)setIcon:(NSImage *)anIcon;

- (NSCellImagePosition)imagePosition;
- (void)setImagePosition:(NSCellImagePosition)aPosition;

- (BOOL)drawsHighlight;
- (void)setDrawsHighlight:(BOOL)flag;

@end

// Use as keys into an NSDIctionary when you call -setObjectValue: on this cell, or a dictionary you build and return in a tableView dataSource's -objectValue:forItem:row: method.
OmniAppKit_EXTERN NSString *OATextWithIconCellStringKey;
OmniAppKit_EXTERN NSString *OATextWithIconCellImageKey;
