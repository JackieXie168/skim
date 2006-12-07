// Copyright 2000-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OATableView.h,v 1.6 2003/01/15 22:51:45 kc Exp $

#import <AppKit/NSNibDeclarations.h> // For IBOutlet
#import <AppKit/NSTableView.h>

@class NSPasteboard;

@interface OATableView : NSTableView
{
    struct {
        unsigned int shouldEditNextItemWhenEditingEnds:1;
    } flags;
}

- (BOOL)shouldEditNextItemWhenEditingEnds;
- (void)setShouldEditNextItemWhenEditingEnds:(BOOL)value;

- (IBAction)copy:(id)sender;

// TODO: Implement the same stuff as in OAExtendedOutlineView for dragging in to the table view. Currently we only support dragging out, in the way required by OmniWeb (dragging whole rows). There's no point into making this completely general until we know what we need.

@end

@interface NSObject (OATableViewDataSource)

// Implement this if you want to accept dragging out
- (void)tableView:(OATableView *)tableView copyObjectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row toPasteboard:(NSPasteboard *)pasteboard;
    // Note: tableColumn may be nil (if a whole row is selected).

// Implement this if you want to provide a custom dragging image.
- (NSImage *)tableView:(OATableView *)tableView dragImageForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
    // Note: tableColumn may be nil (if a whole row is selected).

@end
