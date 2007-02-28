// Copyright 2001-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSUndoManager-OFExtensions.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSUndoManager-OFExtensions.m 79079 2006-09-07 22:35:32Z kc $");

@implementation NSUndoManager (OFExtensions)

- (BOOL)isUndoingOrRedoing;
{
    return [self isUndoing] || [self isRedoing];
}

// Use this instead of the regular -setActionName:.  This won't create an undo group if there's not one there already.
- (void)setActionNameIfGrouped:(NSString *)newActionName;
{
    if (newActionName != nil && [self groupingLevel] > 0)
        [self setActionName:newActionName];
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
    if (OFUndoManagerLogging && [undoManager isUndoRegistrationEnabled]) {
        Class cls = [self class];
        _log(YES, @"<%s:0x%08x> %s {\n", cls->name, self, _cmd);
    }
    indentLevel++;
}

void _OFUndoManagerPopCallSite(NSUndoManager *undoManager)
{
    indentLevel--;
    if (OFUndoManagerLogging && [undoManager isUndoRegistrationEnabled])
        _log(YES, @"}\n");
}

@interface NSUndoManager (Private)
- (id)getInvocationTarget;
@end
@implementation NSUndoManager (Private)
- (id)getInvocationTarget;
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

- (void)removeAllActions;
{
    if (OFUndoManagerLogging)
        _log(NO, @"REMOVE ALL ACTIONS\n");
    [super removeAllActions];
}

- (void)removeAllActionsWithTarget:(id)target;
{
    if (OFUndoManagerLogging) {
        Class cls = [target class];
        _log(NO, @"%p REMOVE ACTIONS target=<%s:0x%08x>\n", self, cls->name, target);
    }
    [super removeAllActionsWithTarget:target];
}

- (void)registerUndoWithTarget:(id)target selector:(SEL)selector object:(id)anObject;
{
    // Do this before logging so that the 'BEGIN' log happens first (probably in auto-group creation mode)
    [super registerUndoWithTarget:target selector:selector object:anObject];

    if (OFUndoManagerLogging && [self isUndoRegistrationEnabled]) {
        Class cls = [target class];
        _log(YES, @">> target=<%s:0x%08x> selector=%s object=%@\n", cls->name, target, selector, anObject);
    }
}

- (void)forwardInvocation:(NSInvocation *)anInvocation;
{
    // Grab this first since super resets _target and doesn't stick it on the NSInvocation (so we have to access _target directly, sadly).
    id target = [[self getInvocationTarget] retain];

    // Do this before logging so that the 'BEGIN' log happens first (probably in auto-group creation mode)
    [super forwardInvocation:anInvocation];

    if (OFUndoManagerLogging && [self isUndoRegistrationEnabled]) {
        Class cls = [target class];
        _log(YES, @">> <%s:0x%08x> %s ", cls->name, target, [anInvocation selector]);

        NSMethodSignature *signature = [anInvocation methodSignature];
        unsigned int argIndex, argCount;

        // Arg0 is the receiver, arg1 is the selector.  Skip those here.
        argCount = [signature numberOfArguments];
        for (argIndex = 2; argIndex < argCount; argIndex++) {
            const char *type = [signature getArgumentTypeAtIndex:argIndex];
            _log(NO, @" arg%d(%s):", argIndex - 2, type);
            if (strcmp(type, @encode(id)) == 0) {
                id arg = nil;
                [anInvocation getArgument:&arg atIndex:argIndex];
                _log(NO, @"%@", arg? [arg shortDescription] : @"nil");
            } else if (strcmp(type, @encode(Class)) == 0) {
                Class arg = Nil;
                [anInvocation getArgument:&arg atIndex:argIndex];
                _log(NO, @"<Class:%@>", NSStringFromClass(arg));
            } else if (strcmp(type, @encode(int)) == 0) {
                int arg = -1;
                [anInvocation getArgument:&arg atIndex:argIndex];
                _log(NO, @"%d", arg);
            } else if (strcmp(type, @encode(unsigned int)) == 0) {
                unsigned int arg = -1;
                [anInvocation getArgument:&arg atIndex:argIndex];
                _log(NO, @"%u", arg);
            } else if (strcmp(type, @encode(float)) == 0) {
                float arg = -1;
                [anInvocation getArgument:&arg atIndex:argIndex];
                _log(NO, @"%g", arg);
            } else if (strcmp(type, @encode(SEL)) == 0) {
                SEL sel;
                [anInvocation getArgument:&sel atIndex:argIndex];
                _log(NO, @"%s", sel);
            } else if (strcmp(type, @encode(BOOL)) == 0) {
                BOOL arg;
                [anInvocation getArgument:&arg atIndex:argIndex];
                _log(NO, @"%u", (unsigned int)arg);
            } else if (strcmp(type, @encode(NSRange)) == 0) {
                NSRange range;
                [anInvocation getArgument:&range atIndex:argIndex];
                _log(NO, @"%@", NSStringFromRange(range));
            } else if (strcmp(type, @encode(NSPoint)) == 0) {
                NSPoint pt;
                [anInvocation getArgument:&pt atIndex:argIndex];
                _log(NO, @"<Point %g,%g>", pt.x, pt.y);
            } else if (strcmp(type, @encode(NSRect)) == 0) {
                NSRect rect;
                [anInvocation getArgument:&rect atIndex:argIndex];
                _log(NO, @"<Rect %gx%g at %g,%g>", rect.size.width, rect.size.height, rect.origin.x, rect.origin.y);
            } else if (strcmp(type, @encode(NSSize)) == 0) {
                NSSize size;
                [anInvocation getArgument:&size atIndex:argIndex];
                _log(NO, @"<Size %gx%g>", size.width, size.height);
            } else {
                _log(NO, @"UNKNOWN ARG TYPE");
            }
        }
        _log(NO, @"\n");
    }

    [target release];
}

- (void)undo;
{
    if (OFUndoManagerLogging)
        _log(YES, @"UNDO {\n");
    indentLevel++;
    [super undo];
    indentLevel--;
    if (OFUndoManagerLogging)
        _log(YES, @"} UNDO\n");
}

- (void)redo;
{
    if (OFUndoManagerLogging)
        _log(YES, @"REDO {\n");
    indentLevel++;
    [super redo];
    indentLevel--;
    if (OFUndoManagerLogging)
        _log(YES, @"} REDO\n");
}

- (void)beginUndoGrouping;
{
    if (OFUndoManagerLogging)
        _log(YES, @"BEGIN GROUPING(%08x) {\n", self);
    indentLevel++;
    [super beginUndoGrouping];
}

- (void)endUndoGrouping;
{
    [super endUndoGrouping];
    indentLevel--;
    if (OFUndoManagerLogging)
        _log(YES, @"} (%08x)END GROUPING\n", self);
}

@end

#endif
