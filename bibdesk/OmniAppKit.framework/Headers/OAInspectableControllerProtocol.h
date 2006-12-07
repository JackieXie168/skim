// Copyright 1997-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

@class NSArray;

@protocol OAComplexInspectableController <NSObject>

- (NSArray *)inspectedObjects;
    // The shared OAInspector instance will call this method on your inspectable controller to determine which set of objects are currently inspectable. If your controller doesn't implement this method, the simpler -inspectedObject method (below) gets called instead.
    
@end

@protocol OAInspectableController <NSObject>

- (id)inspectedObject;
    // The shared OAInspector instance will call this method on your inspectable controller to determine which object it should be inspecting.
    
@end
