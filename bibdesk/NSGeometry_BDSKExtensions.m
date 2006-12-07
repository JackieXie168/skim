//
//  NSGeometry_BDSKExtensions.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 5/14/06.
/*
 This software is Copyright (c) 2006
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

#import "NSGeometry_BDSKExtensions.h"

NSRect BDSKCenterRect(NSRect rect, NSSize size, BOOL flipped)
{
    rect.origin.x += 0.5f * (NSWidth(rect) - size.width);
    rect.origin.y += 0.5f * (NSHeight(rect) - size.height);
    rect.origin.y = flipped ? ceilf(rect.origin.y)  : floorf(rect.origin.y);
    rect.size = size;
    return rect;
}

NSRect BDSKCenterRectVertically(NSRect rect, float height, BOOL flipped)
{
    rect.origin.y += 0.5f * (NSHeight(rect) - height);
    rect.origin.y = flipped ? ceilf(rect.origin.y)  : floorf(rect.origin.y);
    rect.size.height = height;
    return rect;
}

NSRect BDSKCenterRectHorizontally(NSRect rect, float width)
{
    rect.origin.x += floorf(0.5f * (NSWidth(rect) - width));
    rect.size.width = width;
    return rect;
}
