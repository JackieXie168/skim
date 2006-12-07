//
//  BibEditor_Toolbar.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 2/4/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BibEditor.h"
#import "NSImage+Toolbox.h"


extern NSString* 	BibEditorToolbarIdentifier;
extern NSString*	ViewLocalEditorToolbarItemIdentifier;
extern NSString*	ViewRemoteEditorToolbarItemIdentifier;
extern NSString*	ToggleSnoopDrawerToolbarItemIdentifier;
extern NSString*	AuthorTableToolbarItemIdentifier;

@interface BibEditor (Toolbar)

/*!
@method setupToolbar
 @abstract «Abstract»
 @discussion «discussion»
 */
- (void)setupToolbar;

@end
