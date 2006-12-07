// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/OFForwardObject.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFForwardObject.m,v 1.10 2003/01/15 22:51:50 kc Exp $")

@implementation OFForwardObject

static IMP nsObjectForward = NULL;

+ (void)initialize
{
    Method method;

    method = class_getInstanceMethod([NSObject class], @selector(forward::));
    nsObjectForward = method->method_imp;
    return;
}

- forward:(SEL)sel :(marg_list)args
{
    return nsObjectForward(self, _cmd, sel, args);
}

- (void)forwardInvocation:(NSInvocation *)invocation;
{
    [NSException raise:@"subclassResponsibility" format:@"%@ does not implement -%@", [(Class)(self->isa) description], NSStringFromSelector([invocation selector])];
}

@end

