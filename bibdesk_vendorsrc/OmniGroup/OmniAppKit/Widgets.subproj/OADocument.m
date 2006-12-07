// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/OADocument.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OADocument.m,v 1.4 2004/02/10 04:07:37 kc Exp $");

@implementation OADocument

- (void)setFileName:(NSString *)fileName;
{
    [super setFileName:fileName];

    if (fileName) {
        // NSDocument doesn't call -[NSWorkspace noteFileSystemChanged:] when saving a file via AppleScript.  This means that Finder doesn't flush its cache of aliases and if you then try to get an alias to the file you just accessed (assuming you've looked in the containing directory before), it will fail.  If you save via the UI, NSSavePanel sends this.  Logged as Radar #3441895
        [[NSWorkspace sharedWorkspace] noteFileSystemChanged:fileName];
    }
}

@end
