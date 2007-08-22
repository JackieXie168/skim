//
//  SKFindTableView.h
//  Skim
//
//  Created by Christiaan Hofman on 28/7/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import "SKTableView.h"


@interface SKFindTableView : SKTableView {
    CFMutableArrayRef trackingRects;
}
@end


@interface NSObject (SKFindTableViewDelegate)
- (BOOL)tableView:(NSTableView *)aTableView shouldTrackTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)tableView:(NSTableView *)aTableView mouseEnteredTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)tableView:(NSTableView *)aTableView mouseExitedTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
@end
