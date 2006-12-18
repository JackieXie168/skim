//
//  SKCollapsibleView.h
//  Skim
//
//  Created by Christiaan Hofman on 18/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum {
	SKNoEdgeMask = 0,
	SKMinXEdgeMask = 1 << NSMinXEdge,
	SKMinYEdgeMask = 1 << NSMinYEdge,
	SKMaxXEdgeMask = 1 << NSMaxXEdge,
	SKMaxYEdgeMask = 1 << NSMaxYEdge,
	SKEveryEdgeMask = SKMinXEdgeMask | SKMinYEdgeMask | SKMaxXEdgeMask | SKMaxYEdgeMask,
};

@interface SKCollapsibleView : NSView {
	id contentView;
	NSSize minSize;
	int collapseEdges;
}

- (id)contentView;
- (void)setContentView:(NSView *)aView;
- (NSSize)minSize;
- (void)setMinSize:(NSSize)size;
- (int)collapseEdges;
- (void)setCollapseEdges:(int)mask;

- (NSRect)contentRect;

@end
