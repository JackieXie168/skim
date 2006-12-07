// Copyright 1998-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAPopUpButton.h 68913 2005-10-03 19:36:19Z kc $

#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSNibDeclarations.h> // For IBOutlet

@class NSTextField;
@class OATypeAheadSelectionHelper;

// This class adds two features to NSPopUpButton.
// The first, also found in other OmniAppKit controls, adds a label outlet, intended to be hooked up to a TextField which contains an explanatory label for the control. As per Aqua HIG, OAPopUpButton will change the text color of its associated label field to reflect its own enabled/disabled state.
// Also, OAPopUpButton will allow users to select items in its menu by typing the first few letters. It's a lot easier to tab to the popup (with keyboard UI enabled) and type "wa" than to manually select which state you live in. 

@interface OAPopUpButton : NSPopUpButton
{
    IBOutlet NSTextField *label;
    
    OATypeAheadSelectionHelper *typeAheadHelper;
}

@end
