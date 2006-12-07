// Copyright 2001-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSUndoManager-OFExtensions.h 79079 2006-09-07 22:35:32Z kc $

#import <Foundation/NSUndoManager.h>

@interface NSUndoManager (OFExtensions)

- (BOOL)isUndoingOrRedoing;
    // Sometimes you just don't care which it is, just that whatever is currently happening is because of the NSUndoManager.

- (void)setActionNameIfGrouped:(NSString *)newActionName;

@end

// Support for debugging undo operations
#ifdef DEBUG
    extern void _OFUndoManagerPushCallSite(NSUndoManager *undoManager, id self, SEL _cmd);
    extern void _OFUndoManagerPopCallSite(NSUndoManager *undoManager);

    #define OFUndoManagerPushCallSite(undoManager) _OFUndoManagerPushCallSite(undoManager, self, _cmd)
    #define OFUndoManagerPopCallSite(undoManager) _OFUndoManagerPopCallSite(undoManager)
#else
    #define OFUndoManagerPushCallSite(undoManager)
    #define OFUndoManagerPopCallSite(undoManager)
#endif
