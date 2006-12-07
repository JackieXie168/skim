// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorRegistry.h,v 1.7 2003/03/10 17:32:11 toon Exp $

#import <Foundation/NSObject.h>
#import <OmniAppKit/OAGroupedInspectorProtocol.h>
#import <AppKit/NSNibDeclarations.h>

@class NSWindow, NSWindowController, NSMenu, NSMenuItem;
@class NSArray, NSMutableArray, NSMutableDictionary;
@class NSTextField, NSPopUpButton;

@interface OAInspectorRegistry : NSObject
{
    BOOL isInspectionQueued;
    NSWindow *lastWindowAskedToInspect;
    
    NSArray *inspectedObjects;
    NSMutableDictionary *objectsByClass;
    
    NSMutableDictionary *workspaceDefaults;
    NSMutableArray *workspaces;
    NSMenu *workspaceMenu;
    
    IBOutlet NSTextField *newWorkspaceTextField;
    IBOutlet NSPopUpButton *deleteWorkspacePopup;
}

// API
+ (OAInspectorController *)registerInspector:(NSObject <OAGroupedInspector> *)inspector;
+ (void)registerAdditionalPanel:(NSWindowController *)additionalController;
+ (OAInspectorRegistry *)sharedInspector;
+ (void)tabShowHidePanels;
+ (BOOL)showAllInspectors;
+ (void)toggleAllInspectors;
+ (void)updateInspector;

- (NSArray *)inspectedObjects;
- (NSArray *)inspectedObjectsOfClass:(Class)aClass;

- (NSMutableDictionary *)workspaceDefaults;
- (void)defaultsDidChange;

- (NSMenu *)workspaceMenu;
- (NSMenuItem *)resetPanelsItem;

- (void)saveWorkspace:sender;
- (void)saveWorkspaceConfirmed:sender;
- (void)deleteWorkspace:sender;
- (void)deleteWorkspaceConfirmed:sender;
- (void)cancelWorkspacePanel:sender;
- (void)switchToWorkspace:sender;
- (void)switchToDefault:sender;

@end

#import <OmniAppKit/FrameworkDefines.h>

OmniAppKit_EXTERN NSString *OAInspectorSelectionDidChangeNotification;
