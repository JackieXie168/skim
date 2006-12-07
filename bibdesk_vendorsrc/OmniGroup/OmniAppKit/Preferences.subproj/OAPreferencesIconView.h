// Copyright 2000-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniAppKit/Preferences.subproj/OAPreferencesIconView.h 68913 2005-10-03 19:36:19Z kc $

#import <AppKit/NSView.h>

#import <AppKit/NSNibDeclarations.h> // For IBOutlet

@class OAPreferenceClientRecord, OAPreferenceController;

@interface OAPreferencesIconView : NSView
{
    IBOutlet OAPreferenceController *preferenceController;

    unsigned int pressedIconIndex;
    OAPreferenceClientRecord *selectedClientRecord;
    
    NSArray *preferenceClientRecords;
    NSTextFieldCell *preferenceTitleCell;
}

// API
- (void)setPreferenceController:(OAPreferenceController *)newPreferenceController;
- (void)setPreferenceClientRecords:(NSArray *)newPreferenceClientRecords;
- (NSArray *)preferenceClientRecords;

- (void)setSelectedClientRecord:(OAPreferenceClientRecord *)newSelectedClientRecord;

@end

@interface OAPreferencesIconView (Subclasses)
- (unsigned int)_iconsWide;
- (unsigned int)_numberOfIcons;
- (BOOL)_isIconSelectedAtIndex:(unsigned int)index;
- (BOOL)_column:(unsigned int *)column andRow:(unsigned int *)row forIndex:(unsigned int)index;
- (NSRect)_boundsForIndex:(unsigned int)index;
- (BOOL)_iconImage:(NSImage **)image andName:(NSString **)name forIndex:(unsigned int)index;
- (BOOL)_iconImage:(NSImage **)image andName:(NSString **)name andIdentifier:(NSString **)identifier forIndex:(unsigned int)index;
- (void)_drawIconAtIndex:(unsigned int)index drawRect:(NSRect)drawRect;
- (void)_drawBackgroundForRect:(NSRect)rect;
- (void)_sizeToFit;
- (BOOL)_dragIconIndex:(unsigned int)index event:(NSEvent *)event;
- (BOOL)_dragIconImage:(NSImage *)iconImage andName:(NSString *)name event:(NSEvent *)event;
- (BOOL)_dragIconImage:(NSImage *)iconImage andName:(NSString *)name andIdentifier:(NSString *)identifier event:(NSEvent *)event;
@end


#import <OmniAppKit/FrameworkDefines.h>

OmniAppKit_EXTERN const NSSize buttonSize, iconSize;
OmniAppKit_EXTERN const unsigned int titleBaseline, iconBaseline;
