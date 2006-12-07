// Copyright 2001-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSUndoManager-OFExtensions.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSUndoManager-OFExtensions.m,v 1.7 2004/02/10 04:07:46 kc Exp $");

@implementation NSUndoManager (OFExtensions)

- (BOOL)isUndoingOrRedoing;
{
    return [self isUndoing] || [self isRedoing];
}

@end



#ifdef DEBUG

BOOL OFUndoManagerLogging = NO;

static unsigned int indentLevel = 0;

static void _log(BOOL indent, NSString *format, ...)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    va_list args;
    va_start(args, format);
    NSString *string = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    if (indent) {
        unsigned int i;
        for (i = 0; i < indentLevel; i++)
            fputs("  ", stderr);
    }

    fprintf(stderr, "%s", [string UTF8String]);
    [string release];
    [pool release];
}

void _OFUndoManagerPushCallSite(NSUndoManager *undoManager, id self, SEL _cmd)
{
    if (OFUndoManagerLogging && [undoManager isUndoRegistrationEnabled])
        _log(YES, @"%@ %s {\n", OBShortObjectDescription(self), _cmd);
    indentLevel++;
}

void _OFUndoManagerPopCallSite(NSUndoManager *undoManager)
{
    indentLevel--;
    if (OFUndoManagerLogging && [undoManager isUndoRegistrationEnabled])
        _log(YES, @"}\n");
}

@interface NSUndoManager (Private)
- (id)getInvocationTargetTarget;
@end
@implementation NSUndoManager (Private)
- (id)getInvocationTargetTarget;
{
    return _target;
}
@end

@interface _OFUndoManager : NSUndoManager
@end

@implementation _OFUndoManager

+ (void)performPosing;
{
    class_poseAs((Class)self, ((Class)self)->super_class);
}

- (void)registerUndoWithTarget:(id)target selector:(SEL)selector object:(id)anObject;
{
    if (OFUndoManagerLogging && [self isUndoRegistrationEnabled]) {
        _log(YES, @">> target=%@ selector=%s object=%@\n", target, selector, anObject);
    }
    [super registerUndoWithTarget:target selector:selector object:anObject];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation;
{
    if (OFUndoManagerLogging && [self isUndoRegistrationEnabled]) {
        _log(YES, @">> %@ %s ", [[self getInvocationTargetTarget] shortDescription], [anInvocation selector]);

        NSMethodSignature *signature = [anInvocation methodSignature];
        unsigned int argIndex, argCount;

        // Arg0 is the receiver, arg1 is the selector.  Skip those here.
        argCount = [signature numberOfArguments];
        for (argIndex = 2; argIndex < argCount; argIndex++) {
            const char *type = [signature getArgumentTypeAtIndex:argIndex];
            _log(NO, @" arg%d(%s):", argIndex - 2, type);
            if (strcmp(type, "@") == 0) {
                id arg = nil;
                [anInvocation getArgument:&arg atIndex:argIndex];
                _log(NO, @"%@", [arg shortDescription]);
            } else if (strcmp(type, ":") == 0) {
                SEL sel;
                [anInvocation getArgument:&sel atIndex:argIndex];
                _log(NO, @"%s", sel);
            } else if (strcmp(type, @encode(NSRange)) == 0) {
                NSRange range;
                [anInvocation getArgument:&range atIndex:argIndex];
                _log(NO, @"%@", NSStringFromRange(range));
            } else {
                _log(NO, @"UNKNOWN ARG TYPE");
            }
        }
        _log(NO, @"\n");
    }
    
    // Call this last since it resets _target and doesn't stick it on the NSInvocation (so we have to access _target directly, sadly).
    [super forwardInvocation:anInvocation];
}

- (void)undo;
{
    if (OFUndoManagerLogging)
        fprintf(stderr, "UNDO:\n");
    indentLevel++;
    [super undo];
    indentLevel--;
}

- (void)redo;
{
    if (OFUndoManagerLogging)
        fprintf(stderr, "REDO:\n");
    indentLevel++;
    [super redo];
    indentLevel--;
}

@end

#endif
