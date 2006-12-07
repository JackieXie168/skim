// Copyright 2001-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "NSUndoManager-OFExtensions.h"

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSUndoManager-OFExtensions.m,v 1.4 2003/01/15 22:52:01 kc Exp $");

@interface _NSUndoObject : NSObject
{
@public
   _NSUndoObject *next;
   _NSUndoObject *previous;
   id _target;
}

- (BOOL)isEndMark;

@end

@interface NSObject (Private_NSUndoStackMethod)
- (_NSUndoObject *)topUndoObject;
@end


@implementation NSUndoManager (OFExtensions)

- (BOOL)isUndoingOrRedoing;
{
    return [self isUndoing] || [self isRedoing];
}

- (id)topUndoObject;
{
    _NSUndoObject *top;
    
    top = [_undoStack topUndoObject];
     
    // we really want the top invocation, not the end mark if there is one
    if ([top isEndMark])
        top = top->next;
    return top;
}

@end
