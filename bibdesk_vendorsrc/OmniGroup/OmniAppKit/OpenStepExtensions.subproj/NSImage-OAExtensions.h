// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSImage-OAExtensions.h,v 1.20 2003/02/26 00:48:10 rick Exp $

#import <AppKit/NSImage.h>

@class NSMutableSet;

@interface NSImage (OAImageExtensions)
+ (NSImage *)imageInClassBundleNamed:(NSString *)imageName;
@end

@interface NSImage (OAExtensions)

+ (NSImage *)imageNamed:(NSString *)imageName inBundleForClass:(Class)aClass;
+ (NSImage *)imageNamed:(NSString *)imageName inBundle:(NSBundle *)aBundle;
+ (NSImage *)imageForFileType:(NSString *)fileType;
    // Caching wrapper for -[NSWorkspace iconForFileType:].  This method is not thread-safe at the moment.
+ (NSImage *)draggingIconWithTitle:(NSString *)title andImage:(NSImage *)image;

- (void)drawFlippedInRect:(NSRect)rect operation:(NSCompositingOperation)op fraction:(float)delta;
- (void)drawFlippedInRect:(NSRect)rect operation:(NSCompositingOperation)op;

    // Puts the image on the pasteboard as TIFF, and also supplies data from any PDF, EPS, or PICT representations available. Returns the number of types added to the pasteboard and adds their names to notThese. This routine uses -addTypes:owner:, so the pasteboard must have previously been set up using -declareTypes:owner.
- (int)addDataToPasteboard:(NSPasteboard *)aPasteboard exceptTypes:(NSMutableSet *)notThese;

//

- (NSImageRep *)imageRepOfClass:(Class)imageRepClass;
- (NSImageRep *)imageRepOfSize:(NSSize)aSize; // uses -[NSImageRep size], not pixelsWide and pixelsHigh. maybe we need -imageRepOfPixelSize: too?

#ifdef MAC_OS_X_VERSION_10_2
- (NSData *)bmpData;
- (NSData *)bmpDataWithBackgroundColor:(NSColor *)backgroundColor;
#endif

// icon utilties

// Creates a document-preview style icon. All images supplied should have reps at 128x128, 32x32, and 16x16 for best results. Caller is responsible for positioning content appropriately within the icon frame (i.e. so it appears in the right place composited on the icon).
+ (NSImage *)documentIconWithContent:(NSImage *)contentImage;
    // Assumes images named "DocumentIconTemplate" and "DocumentIconMask" exist in your app wrapper.
+ (NSImage *)documentIconWithTemplate:(NSImage *)templateImage content:(NSImage *)contentImage contentMask:(NSImage *)contentMask;
    // Lets you provide your own template images.

@end