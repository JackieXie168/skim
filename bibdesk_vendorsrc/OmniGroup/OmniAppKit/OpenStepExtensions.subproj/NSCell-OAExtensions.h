// Copyright 1998-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSCell-OAExtensions.h,v 1.9 2004/02/10 04:07:33 kc Exp $

#import <AppKit/NSCell.h>

@interface NSCell (OAExtensions)

- (void) applySettingsToCell: (NSCell *) cell;
/*" Copies the settings from the receiver to the argument.  The argument is typically a subclass of the receiver that has been allocated to replace the receiver in a control.  This method should be implemented on subclasses of cells to copy over subclass-specific settings. "*/

@end
