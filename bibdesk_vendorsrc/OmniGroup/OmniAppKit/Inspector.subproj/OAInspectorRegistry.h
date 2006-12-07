// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspectorRegistry.h,v 1.15 2004/02/10 04:07:33 kc Exp $

#import <Foundation/NSObject.h>
#import <OmniAppKit/OAGroupedInspectorProtocol.h>
#import <AppKit/NSNibDeclarations.h>

@class NSWindow, NSWindowController, NSMenu, NSMenuItem;
@class NSArray, NSMutableArray, NSMutableDictionary;
@class NSTextField, NSTableView, NSButton;
@class OAInspectionSet;

@interface OAInspectorRegistry : NSObject
{
    BOOL isInspectionQueued;
    NSWindow *lastWindowAskedToInspect;
    NSWindow *lastMainWindowBeforeAppSwitch;

    OAInspectionSet *inspectionSet;
    
    NSMutableDictionary *workspaceDefaults;
    NSMutableArray *workspaces;
    NSMenu *workspaceMenu;
    
    IBOutlet NSTextField *newWorkspaceTextField;
    IBOutlet NSTableView *editWorkspaceTable;
    IBOutlet NSButton *deleteWorkspaceButton;
}

// API
+ (OAInspectorController *)registerInspector:(NSObject <OAGroupedInspector> *)inspector;
+ (void)registerAdditionalPanel:(NSWindowController *)additionalController;
+ (OAInspectorRegistry *)sharedInspector;
+ (void)tabShowHidePanels;
+ (BOOL)showAllInspectors;
+ (BOOL)hideAllInspectors;
+ (void)toggleAllInspectors;
+ (void)updateInspector;
+ (BOOL)hasVisibleInspector;

- (NSArray *)inspectedObjects;
- (NSArray *)inspectedObjectsOfClass:(Class)aClass;

- (OAInspectionSet *)inspectionSet;
- (void)inspectionSetChanged;

- (NSMutableDictionary *)workspaceDefaults;
- (void)defaultsDidChange;

- (NSMenu *)workspaceMenu;
- (NSMenuItem *)resetPanelsItem;

- (void)saveWorkspace:sender;
- (void)saveWorkspaceConfirmed:sender;
- (void)editWorkspace:sender;
- (void)deleteWorkspace:sender;
- (void)cancelWorkspacePanel:sender;
- (void)switchToWorkspace:sender;
- (void)switchToDefault:sender;

@end

#import <OmniAppKit/FrameworkDefines.h>

OmniAppKit_EXTERN NSString *OAInspectorSelectionDidChangeNotification;
