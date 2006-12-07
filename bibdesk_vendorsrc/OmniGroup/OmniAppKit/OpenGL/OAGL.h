// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenGL/OAGL.h,v 1.4 2003/01/15 22:51:34 kc Exp $

#import <AppKit/NSOpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

#import <Foundation/NSString.h>

static inline void OAGLCheckError(NSString *message)
{
    GLenum        error;

    error = glGetError();
    if (error != GL_NO_ERROR) {
        NSLog(@"OpenGL Error(%@): 0x%04x -- %s\n", message, (int)error,  gluErrorString(error));
    }
}
