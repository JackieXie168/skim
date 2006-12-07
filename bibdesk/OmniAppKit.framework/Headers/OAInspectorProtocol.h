// Copyright 1997-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <Foundation/NSObject.h>

@class NSView;

// We call them "inspectors" in code for historical reasons... but the preferred Aqua UI is to call them "info windows" or "info panels".

@protocol OAInspector <NSObject>

- (NSString *)inspectorName;
    // Will be used as window title, with " Info" after it.

- (void)inspectObject:(id)anObject;
    // The shared OAInspector instance calls this method on your inspectable controller once your inspector view is installed to let you actually inspect the object.

- (void)redisplay;
    // Called to redisplay the inspector.

- (NSView *)inspectorView;
    // Returns the view which OAInspector will swap into the Inspector window when your object is being inspected.
    
@end

@protocol OAExtendedInspector <OAInspector>

- (int)displayOrder;
    // How to order vertically for the multi-pane inspector view.

- (BOOL)handlesMultipleSelections;
    // Return YES if your inspector is prepared to show multiple objects at once. The -inspectObject: method will then be called with an array of objects.
        
@end
