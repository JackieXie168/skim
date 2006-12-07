// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAGroupedInspectorProtocol.h,v 1.5 2003/02/17 22:19:42 toon Exp $

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

@class NSView, NSArray;
@class OAInspectorController;

// We call them "inspectors" in code for historical reasons... but the preferred Aqua UI is to call them "info windows" or "info panels".

@protocol OAGroupedInspector <NSObject>

- (NSString *)inspectorName;
    // Will be used as window and menu title

- (unsigned int)defaultDisplayGroupNumber;
    // Which group inspector view to start in the first time the program is run

- (unsigned int)defaultDisplayOrderInGroup;
    // How to order vertically the above group
    
- (BOOL)defaultGroupVisibility;
    // Whether the group should be on screen or not the first time the program is run
    
- (NSString *)keyEquivalent;
- (unsigned int)keyEquivalentModifierMask;
    // The key equivalent to display in the header and use in dynamic menu

- (NSString *)imageName;
    // Tiny image displayed in header button for each inspector

- (NSView *)inspectorView;
    // Returns the view which will be placed into a grouped Info window

- (void)inspectObjects:(NSArray *)objects;
    // This method is called whenever the selection changes
    
- (Class)inspectsClass;
    // Return the class of objects that this inspector expects to receive in its -inspectObjects: method

@end

@interface NSObject (OptionalInspectorMethods)
- (void)setInspectorController:(OAInspectorController *)aController;
	// If the inspector has any need to know its controller, it can implement this method
- (NSSize)inspectorWillResizeToSize:(NSSize)aSize;
- (NSSize)inspectorMinimumSize;
@end

