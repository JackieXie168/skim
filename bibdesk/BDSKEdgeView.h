//
//  BDSKEdgeView.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 1/11/05.
/*
 This software is Copyright (c) 2005,2006
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

#import <Cocoa/Cocoa.h>
#import "BDSKContainerView.h"


enum {
	BDSKNoEdgeMask = 0,
	BDSKMinXEdgeMask = 1 << NSMinXEdge,
	BDSKMinYEdgeMask = 1 << NSMinYEdge,
	BDSKMaxXEdgeMask = 1 << NSMaxXEdge,
	BDSKMaxYEdgeMask = 1 << NSMaxYEdge,
	BDSKEveryEdgeMask = BDSKMinXEdgeMask | BDSKMinYEdgeMask | BDSKMaxXEdgeMask | BDSKMaxYEdgeMask,
};

@interface BDSKEdgeView : BDSKContainerView {
	int edges;
	NSMutableArray *edgeColors;
}

/*!
	@method edges
	@abstract Returns the mask for the edges that the view should draw
	@discussion (discussion)
*/
- (int)edges;

/*!
	@method setEdges:
	@abstract Sets the mask for the edges to draw. Valid values are given in the enum in the header. 
		You can combine edges using the bitwise | operator. 
	@discussion (discussion)
	@param mask The mask to set
*/
- (void)setEdges:(int)mask;

/*!
	@method setEdgeColor
	@abstract Sets the color of all the edges to aColor.
	@discussion (discussion)
	@param aColor The color to set.
*/
- (void)setEdgeColor:(NSColor *)aColor;

/*!
	@method edgeColors
	@abstract Returns the array of colors to use for the edges. 
	@discussion (discussion)
*/
- (NSArray *)edgeColors;

/*!
	@method setEdgeColors:
	@abstract Sets the array of colors to use for the edges. This should be an array of length 4, indexed by the NSRectEdge enum. 
	@discussion (discussion)
	@param colors The array of colors to set.
*/
- (void)setEdgeColors:(NSArray *)colors;

/*!
	@method colorForEdge:
	@abstract Returns the color used for the edge. 
	@discussion (discussion)
	@param edge The edge for which you want the color.
*/
- (NSColor *)colorForEdge:(NSRectEdge)edge;

/*!
	@method setColor:forEdge:
	@abstract Sets the color used for the edge.
	@discussion (discussion)
	@param aColor The color to set.
	@param edge The edge for which you want set the color.
*/
- (void)setColor:(NSColor *)aColor forEdge:(NSRectEdge)edge;

/*!
	@method adjustSubviews
	@abstract Adjusts the frames of the subviews of the contentView so they fit in the contentView.
	@discussion (discussion)
*/
- (void)adjustSubviews;

@end
