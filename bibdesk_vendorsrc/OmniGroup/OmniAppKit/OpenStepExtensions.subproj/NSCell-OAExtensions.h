// Copyright 1998-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSCell-OAExtensions.h,v 1.6 2003/01/15 22:51:35 kc Exp $

#import <AppKit/NSCell.h>

@interface NSCell (OAExtensions)

- (void) applySettingsToCell: (NSCell *) cell;
/*.doc.
Copies the settings from the receiver to the argument.  The argument is typically a subclass of the receiver that has been allocated to replace the receiver in a control.  This method should be implemented on subclasses of cells to copy over subclass-specific settings.
*/

@end
