// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniAppKit/OAGL.h>

#import <OmniBase/OmniBase.h>
#import <stdio.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenGL/OAGL.m,v 1.5 2003/01/15 22:51:34 kc Exp $")

@interface __OAGLSetup
@end

@implementation __OAGLSetup

+ (void) didLoad;
{
#if 0
    fprintf(stderr, "Retaining renderers.\n");
    // Once we have loaded a renderer, don't ever unload it
    NSOpenGLSetOption(NSOpenGLGORetainRenderers, 1);
    
#warning Remove this hack once NSOpenGLGORetainRenderers actually works
    // For some reason the code above doesn't seem to work.  Instead, we'll create
    // a context and keep it forever.
    {
        NSOpenGLPixelFormatAttribute attributes[128], *attr = attributes;
        NSOpenGLPixelFormat *pixelFormat;

        *attr++ = NSOpenGLPFAAccelerated;
        *attr++ = NSOpenGLPFADoubleBuffer;
        *attr++ = 0;

        pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes: attributes];
        if (pixelFormat) {
            [[NSOpenGLContext alloc] initWithFormat: pixelFormat shareContext: nil];
            [pixelFormat release];
        }
    }
#endif    
}

@end
