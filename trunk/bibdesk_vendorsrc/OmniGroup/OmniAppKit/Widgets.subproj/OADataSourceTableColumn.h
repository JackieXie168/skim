// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OADataSourceTableColumn.h 68913 2005-10-03 19:36:19Z kc $

#import <AppKit/NSTableColumn.h>

@interface OADataSourceTableColumn : NSTableColumn
@end

@interface NSObject (OADataSourceTableColumn)
// This should have been a dataSource method in the first place.
- (NSCell *)tableView:(NSTableView *)tableView column:(OADataSourceTableColumn *)tableColumn dataCellForRow:(int)row;
@end
