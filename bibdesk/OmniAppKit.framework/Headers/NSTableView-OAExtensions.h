// Copyright 1997-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <AppKit/NSTableView.h>

typedef enum _OATableViewRowVisibility {
    OATableViewRowVisibilityLeaveUnchanged,
    OATableViewRowVisibilityScrollToVisible,
    OATableViewRowVisibilityScrollToMiddleIfNotVisible
} OATableViewRowVisibility;

#import <OmniAppKit/OAFindControllerTargetProtocol.h>

@interface NSTableView (OAExtensions) <OAFindControllerTarget>

- (NSRect)rectOfSelectedRows;
- (void)scrollSelectedRowsToVisibility:(OATableViewRowVisibility)visibility;

- (NSFont *)font;
- (void)setFont:(NSFont *)font;

@end

@interface NSObject (NSTableViewOAExtendedDataSource)
- (BOOL)tableView:(NSTableView *)tableView itemAtRow:(int)row matchesPattern:(id <OAFindPattern>)pattern;
    // Implement this if you want find support.
@end
