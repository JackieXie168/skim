// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectableControllerProtocol.h,v 1.9 2003/01/15 22:51:33 kc Exp $

@class NSArray;

@protocol OAComplexInspectableController <NSObject>

- (NSArray *)inspectedObjects;
    // The shared OAInspector instance will call this method on your inspectable controller to determine which set of objects are currently inspectable. If your controller doesn't implement this method, the simpler -inspectedObject method (below) gets called instead.
    
@end

@protocol OAInspectableController <NSObject>

- (id)inspectedObject;
    // The shared OAInspector instance will call this method on your inspectable controller to determine which object it should be inspecting.
    
@end
