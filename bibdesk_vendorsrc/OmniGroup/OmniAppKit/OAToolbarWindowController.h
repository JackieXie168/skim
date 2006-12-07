// Copyright 2002-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniAppKit/OAToolbarWindowController.h 68913 2005-10-03 19:36:19Z kc $

#import <AppKit/NSWindowController.h>

@class NSDictionary;
@class NSToolbar, NSToolbarItem;

@protocol OAToolbarHelper
- (NSString *)itemIdentifierExtension;
- (NSString *)templateItemIdentifier;
- (NSArray *)allowedItems;
- (void)finishSetupForItem:(NSToolbarItem *)item;
@end

@interface OAToolbarWindowController : NSWindowController 
{
    NSToolbar *toolbar;
}

+ (void)registerToolbarHelper:(NSObject <OAToolbarHelper> *)helperObject;
+ (Class)toolbarClass;
+ (Class)toolbarItemClass;

- (NSDictionary *)toolbarInfoForItem:(NSString *)identifier;

// implement in subclasses to control toolbar
- (NSString *)toolbarConfigurationName; // file name to lookup .toolbar plist
- (NSString *)toolbarIdentifier; // identifier used for preferences - defaults to configurationName if unimplemented

@end
