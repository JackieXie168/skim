// Copyright 1997-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <OmniBase/OBObject.h>

@class NSBox, NSView, NSWindow;
@class NSMutableArray, NSSet, NSMutableSet;
@class OAStackView;

#import <AppKit/NSNibDeclarations.h> // For IBOutlet
#import <OmniAppKit/OAInspectableControllerProtocol.h>
#import <OmniAppKit/OAInspectorProtocol.h>

// We call them "inspectors" in code for historical reasons... but the preferred Aqua UI is to call them "info windows" or "info panels".

@interface OAInspector : OBObject
{
    IBOutlet NSWindow *inspectorWindow;
    IBOutlet NSBox *noInspectorBox;
    IBOutlet NSBox *multiInspectorBox;

    NSMutableDictionary *buttonsForInspectors;
    NSMutableArray *inspectorViews;
    id <OAInspector> activeInspector;
    NSMutableSet *expandedInspectors;
    NSMutableSet *originallyExpandedInspectors;

    BOOL isOnScreen;
    BOOL isMorphingViews;
    BOOL isInspectionQueued;
    NSWindow *lastWindowAskedToInspect;

    id <OAInspectableController, NSObject> currentInspectableController;
    NSArray *inspectedObjects;
    NSMutableDictionary *objectsByClass;
}

+ (void)setSimpleInspectorMode:(BOOL)yn;

+ (void)registerInspector:(id <OAInspector>)anInspector forClass:(Class)aClass;
+ (OAInspector *) sharedInspector;
+ (void)showInspector;
+ (void)updateInspector;

+ (id)multipleSelectionObject;


- (id <OAInspectableController, NSObject>)currentInspectableController;
- (id)inspectedObject;
- (NSArray *)inspectedObjects;
- (BOOL)isInspectorVisible;

@end

#import <OmniAppKit/FrameworkDefines.h>

OmniAppKit_EXTERN NSString *OAInspectorSelectionDidChangeNotification;
OmniAppKit_EXTERN NSString *OAInspectorShowInspectorDefaultKey;
