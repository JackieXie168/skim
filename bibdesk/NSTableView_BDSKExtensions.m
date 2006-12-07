//
//  NSTableView_BDSKExtensions.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 10/11/05.
/*
 This software is Copyright (c) 2005
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSTableView_BDSKExtensions.h"


@implementation NSTableView (BDSKExtensions)

- (BOOL)validateDelegatedMenuItem:(id<NSMenuItem>)menuItem defaultDataSourceSelector:(SEL)dataSourceSelector{
	SEL action = [menuItem action];
	
	if ([_dataSource respondsToSelector:action]) {
		if ([_dataSource respondsToSelector:@selector(validateMenuItem:)]) {
			return [_dataSource validateMenuItem:menuItem];
		} else {
			return (action == @selector(paste:)) || ([self numberOfSelectedRows] > 0);
		}
	} else if ([_delegate respondsToSelector:action]) {
		if ([_delegate respondsToSelector:@selector(validateMenuItem:)]) {
			return [_delegate validateMenuItem:menuItem];
		} else {
			return (action == @selector(paste:)) || ([self numberOfSelectedRows] > 0);
		}
	} else if ([_dataSource respondsToSelector:dataSourceSelector]) {
		if ([_dataSource respondsToSelector:@selector(validateMenuItem:)]) {
			return [_dataSource validateMenuItem:menuItem];
		} else {
			return (action == @selector(paste:)) || ([self numberOfSelectedRows] > 0);
		}
	}else{
		// no action implemented
		return NO;
	}
}

// this is necessary as the NSTableView-OAExtensions defines these actions accordingly
- (BOOL)validateMenuItem:(id<NSMenuItem>)menuItem{
	SEL action = [menuItem action];
	if (action == @selector(delete:)) {
		return [self validateDelegatedMenuItem:menuItem defaultDataSourceSelector:@selector(tableView:deleteRows:)];
	}
	else if (action == @selector(deleteForward:)) {
		return [_dataSource respondsToSelector:@selector(tableView:deleteRows:)];
	}
	else if (action == @selector(deleteBackward:)) {
		return [_dataSource respondsToSelector:@selector(tableView:deleteRows:)];
	}
	else if (action == @selector(cut:)) {
		return [self validateDelegatedMenuItem:menuItem defaultDataSourceSelector:@selector(tableView:writeRows:toPasteboard:)];
	}
	else if (action == @selector(copy:)) {
		return [self validateDelegatedMenuItem:menuItem defaultDataSourceSelector:@selector(tableView:writeRows:toPasteboard:)];
	}
	else if (action == @selector(paste:)) {
		return [self validateDelegatedMenuItem:menuItem defaultDataSourceSelector:@selector(tableView:addItemsFromPasteboard:)];
	}
	else if (action == @selector(duplicate:)) {
		return [self validateDelegatedMenuItem:menuItem defaultDataSourceSelector:@selector(tableView:writeRows:toPasteboard:)];
	}
    return YES; // we assume that any other implemented action is always valid
}

@end
