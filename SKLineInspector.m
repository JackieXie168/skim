//
//  SKLineInspector.m
//  Skim
//
//  Created by Christiaan Hofman on 6/20/07.
/*
 This software is Copyright (c) 2007-2020
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SKLineInspector.h"
#import "SKLineWell.h"
#import <SkimNotes/SkimNotes.h>
#import "NSSegmentedControl_SKExtensions.h"
#import "NSImage_SKExtensions.h"

NSString *SKLineInspectorLineAttributeDidChangeNotification = @"SKLineInspectorLineAttributeDidChangeNotification";

#define LINEWIDTH_KEY       @"lineWidth"
#define STYLE_KEY           @"style"
#define DASHPATTERN_KEY     @"dashPattern"
#define STARTLINESTYLE_KEY  @"startLineStyle"
#define ENDLINESTYLE_KEY    @"endLineStyle"
#define ACTION_KEY          @"action"

#define SKLineInspectorFrameAutosaveName @"SKLineInspector"

#define MAKE_IMAGE(control, segment, size, instructions) \
do { \
NSImage *image = [NSImage imageWithSize:size drawingHandler:^(NSRect rect){ \
instructions \
return YES; \
}]; \
[image setTemplate:YES]; \
[control setImage:image forSegment:segment]; \
} while (0)


@implementation SKLineInspector

@synthesize styleButton, startLineStyleButton, endLineStyleButton, lineWell, lineWidth, style, dashPattern, startLineStyle, endLineStyle, currentLineChangeAction;

static SKLineInspector *sharedLineInspector = nil;

+ (id)sharedLineInspector {
    if (sharedLineInspector == nil)
        sharedLineInspector = [[self alloc] init];
    return sharedLineInspector;
}

+ (BOOL)sharedLineInspectorExists {
    return sharedLineInspector != nil;
}

- (id)init {
    if (sharedLineInspector) NSLog(@"Attempt to allocate second instance of %@", [self class]);
    self = [super initWithWindowNibName:@"LineInspector"];
    if (self) {
        style = kPDFBorderStyleSolid;
        lineWidth = 1.0;
        dashPattern = nil;
        startLineStyle = kPDFLineStyleNone;
        endLineStyle = kPDFLineStyleNone;
        currentLineChangeAction = SKNoLineChangeAction;
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(dashPattern);
    SKDESTROY(styleButton);
    SKDESTROY(startLineStyleButton);
    SKDESTROY(endLineStyleButton);
    SKDESTROY(lineWell);
    [super dealloc];
}

- (void)windowDidLoad {
    [lineWell setCanActivate:NO];
    [lineWell bind:SKLineWellLineWidthKey toObject:self withKeyPath:LINEWIDTH_KEY options:nil];
    [lineWell bind:SKLineWellStyleKey toObject:self withKeyPath:STYLE_KEY options:nil];
    [lineWell bind:SKLineWellDashPatternKey toObject:self withKeyPath:DASHPATTERN_KEY options:nil];
    [lineWell bind:SKLineWellStartLineStyleKey toObject:self withKeyPath:STARTLINESTYLE_KEY options:nil];
    [lineWell bind:SKLineWellEndLineStyleKey toObject:self withKeyPath:ENDLINESTYLE_KEY options:nil];
    
    [styleButton setHelp:NSLocalizedString(@"Solid line style", @"Tool tip message") forSegment:kPDFBorderStyleSolid];
    [styleButton setHelp:NSLocalizedString(@"Dashed line style", @"Tool tip message") forSegment:kPDFBorderStyleDashed];
    [styleButton setHelp:NSLocalizedString(@"Beveled line style", @"Tool tip message") forSegment:kPDFBorderStyleBeveled];
    [styleButton setHelp:NSLocalizedString(@"Inset line style", @"Tool tip message") forSegment:kPDFBorderStyleInset];
    [styleButton setHelp:NSLocalizedString(@"Underline line style", @"Tool tip message") forSegment:kPDFBorderStyleUnderline];
    
    [startLineStyleButton setHelp:NSLocalizedString(@"No start line style", @"Tool tip message") forSegment:kPDFLineStyleNone];
    [startLineStyleButton setHelp:NSLocalizedString(@"Square start line style", @"Tool tip message") forSegment:kPDFLineStyleSquare];
    [startLineStyleButton setHelp:NSLocalizedString(@"Circle start line style", @"Tool tip message") forSegment:kPDFLineStyleCircle];
    [startLineStyleButton setHelp:NSLocalizedString(@"Diamond start line style", @"Tool tip message") forSegment:kPDFLineStyleDiamond];
    [startLineStyleButton setHelp:NSLocalizedString(@"Open arrow start line style", @"Tool tip message") forSegment:kPDFLineStyleOpenArrow];
    [startLineStyleButton setHelp:NSLocalizedString(@"Closed arrow start line style", @"Tool tip message") forSegment:kPDFLineStyleClosedArrow];
    
    [endLineStyleButton setHelp:NSLocalizedString(@"No end line style", @"Tool tip message") forSegment:kPDFLineStyleNone];
    [endLineStyleButton setHelp:NSLocalizedString(@"Square end line style", @"Tool tip message") forSegment:kPDFLineStyleSquare];
    [endLineStyleButton setHelp:NSLocalizedString(@"Circle end line style", @"Tool tip message") forSegment:kPDFLineStyleCircle];
    [endLineStyleButton setHelp:NSLocalizedString(@"Diamond end line style", @"Tool tip message") forSegment:kPDFLineStyleDiamond];
    [endLineStyleButton setHelp:NSLocalizedString(@"Open arrow end line style", @"Tool tip message") forSegment:kPDFLineStyleOpenArrow];
    [endLineStyleButton setHelp:NSLocalizedString(@"Closed arrow end line style", @"Tool tip message") forSegment:kPDFLineStyleClosedArrow];
    
    [self setWindowFrameAutosaveName:SKLineInspectorFrameAutosaveName];
    
	NSSize size = NSMakeSize(29.0, 12.0);
    
    MAKE_IMAGE(styleButton, kPDFBorderStyleSolid, size,
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 3.0, 17.0, 6.0)];
        [path setLineWidth:2.0];
        [[NSColor blackColor] setStroke];
        [path stroke];
    );
    
    MAKE_IMAGE(styleButton, kPDFBorderStyleDashed, size,
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(6.0, 5.0)];
        [path lineToPoint:NSMakePoint(6.0, 3.0)];
        [path lineToPoint:NSMakePoint(9.0, 3.0)];
        [path moveToPoint:NSMakePoint(12.0, 3.0)];
        [path lineToPoint:NSMakePoint(17.0, 3.0)];
        [path moveToPoint:NSMakePoint(20.0, 3.0)];
        [path lineToPoint:NSMakePoint(23.0, 3.0)];
        [path lineToPoint:NSMakePoint(23.0, 5.0)];
        [path moveToPoint:NSMakePoint(23.0, 7.0)];
        [path lineToPoint:NSMakePoint(23.0, 9.0)];
        [path lineToPoint:NSMakePoint(20.0, 9.0)];
        [path moveToPoint:NSMakePoint(17.0, 9.0)];
        [path lineToPoint:NSMakePoint(12.0, 9.0)];
        [path moveToPoint:NSMakePoint(9.0, 9.0)];
        [path lineToPoint:NSMakePoint(6.0, 9.0)];
        [path lineToPoint:NSMakePoint(6.0, 7.0)];
        [path setLineWidth:2.0];
        [[NSColor blackColor] setStroke];
        [path stroke];
	);
    
    MAKE_IMAGE(styleButton, kPDFBorderStyleBeveled, size,
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 3.0, 17.0, 6.0)];
        [path setLineWidth:2.0];
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.25] setStroke];
        [path stroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(7.0, 3.0)];
        [path lineToPoint:NSMakePoint(23.0, 3.0)];
        [path lineToPoint:NSMakePoint(23.0, 8.0)];
        [path setLineWidth:2.0];
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.35] set];
        [path stroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(5.0, 2.0)];
        [path lineToPoint:NSMakePoint(7.0, 4.0)];
        [path lineToPoint:NSMakePoint(7.0, 2.0)];
        [path closePath];
        [path moveToPoint:NSMakePoint(24.0, 10.0)];
        [path lineToPoint:NSMakePoint(22.0, 8.0)];
        [path lineToPoint:NSMakePoint(24.0, 8.0)];
        [path closePath];
        [path fill];
	);
    
    MAKE_IMAGE(styleButton, kPDFBorderStyleInset, size,
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(6.0, 3.0, 17.0, 6.0)];
        [path setLineWidth:2.0];
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.25] setStroke];
        [path stroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(6.0, 4.0)];
        [path lineToPoint:NSMakePoint(6.0, 9.0)];
        [path lineToPoint:NSMakePoint(22.0, 9.0)];
        [path setLineWidth:2.0];
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.35] set];
        [path stroke];
        path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(5.0, 2.0)];
        [path lineToPoint:NSMakePoint(7.0, 4.0)];
        [path lineToPoint:NSMakePoint(5.0, 4.0)];
        [path closePath];
        [path moveToPoint:NSMakePoint(24.0, 10.0)];
        [path lineToPoint:NSMakePoint(22.0, 8.0)];
        [path lineToPoint:NSMakePoint(22.0, 10.0)];
        [path closePath];
        [path fill];
    );
    
    MAKE_IMAGE(styleButton, kPDFBorderStyleUnderline, size,
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(6.0, 3.0)];
        [path lineToPoint:NSMakePoint(23.0, 3.0)];
        [path setLineWidth:2.0];
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] setStroke];
        [path stroke];
    );
	
    size = NSMakeSize(24.0, 12.0);
    
    MAKE_IMAGE(startLineStyleButton, kPDFLineStyleNone, size,
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(20.0, 6.0)];
        [path lineToPoint:NSMakePoint(8.0, 6.0)];
        [path setLineWidth:2.0];
        [[NSColor blackColor] setStroke];
        [path stroke];
	);
	
    MAKE_IMAGE(endLineStyleButton, kPDFLineStyleNone, size,
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(4.0, 6.0)];
        [path lineToPoint:NSMakePoint(16.0, 6.0)];
        [path setLineWidth:2.0];
        [[NSColor blackColor] setStroke];
        [path stroke];
	);
	
    MAKE_IMAGE(startLineStyleButton, kPDFLineStyleSquare, size,
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(20.0, 6.0)];
        [path lineToPoint:NSMakePoint(8.0, 6.0)];
        [path appendBezierPathWithRect:NSMakeRect(5.0, 3.0, 6.0, 6.0)];
        [path setLineWidth:2.0];
        [[NSColor blackColor] setStroke];
        [path stroke];
        return YES;
	);
    
    MAKE_IMAGE(endLineStyleButton, kPDFLineStyleSquare, size,
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(4.0, 6.0)];
        [path lineToPoint:NSMakePoint(16.0, 6.0)];
        [path appendBezierPathWithRect:NSMakeRect(13.0, 3.0, 6.0, 6.0)];
        [path setLineWidth:2.0];
        [[NSColor blackColor] setStroke];
        [path stroke];
	);
	
    MAKE_IMAGE(startLineStyleButton, kPDFLineStyleCircle, size,
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(20.0, 6.0)];
        [path lineToPoint:NSMakePoint(8.0, 6.0)];
        [path appendBezierPathWithOvalInRect:NSMakeRect(5.0, 3.0, 6.0, 6.0)];
        [path setLineWidth:2.0];
        [[NSColor blackColor] setStroke];
        [path stroke];
    );
	
    MAKE_IMAGE(endLineStyleButton, kPDFLineStyleCircle, size,
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(4.0, 6.0)];
        [path lineToPoint:NSMakePoint(16.0, 6.0)];
        [path appendBezierPathWithOvalInRect:NSMakeRect(13.0, 3.0, 6.0, 6.0)];
        [path setLineWidth:2.0];
        [[NSColor blackColor] setStroke];
        [path stroke];
	);
	
    MAKE_IMAGE(startLineStyleButton, kPDFLineStyleDiamond, size,
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(20.0, 6.0)];
        [path lineToPoint:NSMakePoint(8.0, 6.0)];
        [path moveToPoint:NSMakePoint(12.0, 6.0)];
        [path lineToPoint:NSMakePoint(8.0, 10.0)];
        [path lineToPoint:NSMakePoint(4.0, 6.0)];
        [path lineToPoint:NSMakePoint(8.0, 2.0)];
        [path closePath];
        [path setLineWidth:2.0];
        [path stroke];
    );
	
    MAKE_IMAGE(endLineStyleButton, kPDFLineStyleDiamond, size,
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(4.0, 6.0)];
        [path lineToPoint:NSMakePoint(16.0, 6.0)];
        [path moveToPoint:NSMakePoint(12.0, 6.0)];
        [path lineToPoint:NSMakePoint(16.0, 10.0)];
        [path lineToPoint:NSMakePoint(20.0, 6.0)];
        [path lineToPoint:NSMakePoint(16.0, 2.0)];
        [path closePath];
        [path setLineWidth:2.0];
        [path stroke];
	);
	
    MAKE_IMAGE(startLineStyleButton, kPDFLineStyleOpenArrow, size,
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(20.0, 6.0)];
        [path lineToPoint:NSMakePoint(8.0, 6.0)];
        [path moveToPoint:NSMakePoint(14.0, 3.0)];
        [path lineToPoint:NSMakePoint(8.0, 6.0)];
        [path lineToPoint:NSMakePoint(14.0, 9.0)];
        [path setLineWidth:2.0];
        [[NSColor blackColor] setStroke];
        [path stroke];
    );
	
    MAKE_IMAGE(endLineStyleButton, kPDFLineStyleOpenArrow, size,
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(4.0, 6.0)];
        [path lineToPoint:NSMakePoint(16.0, 6.0)];
        [path moveToPoint:NSMakePoint(10.0, 3.0)];
        [path lineToPoint:NSMakePoint(16.0, 6.0)];
        [path lineToPoint:NSMakePoint(10.0, 9.0)];
        [path setLineWidth:2.0];
        [[NSColor blackColor] setStroke];
        [path stroke];
	);
	
    MAKE_IMAGE(startLineStyleButton, kPDFLineStyleClosedArrow, size,
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(20.0, 6.0)];
        [path lineToPoint:NSMakePoint(8.0, 6.0)];
        [path moveToPoint:NSMakePoint(14.0, 3.0)];
        [path lineToPoint:NSMakePoint(8.0, 6.0)];
        [path lineToPoint:NSMakePoint(14.0, 9.0)];
        [path closePath];
        [path setLineWidth:2.0];
        [[NSColor blackColor] setStroke];
        [path stroke];
    );
	
    MAKE_IMAGE(endLineStyleButton, kPDFLineStyleClosedArrow, size,
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(4.0, 6.0)];
        [path lineToPoint:NSMakePoint(16.0, 6.0)];
        [path moveToPoint:NSMakePoint(10.0, 3.0)];
        [path lineToPoint:NSMakePoint(16.0, 6.0)];
        [path lineToPoint:NSMakePoint(10.0, 9.0)];
        [path closePath];
        [path setLineWidth:2.0];
        [[NSColor blackColor] setStroke];
        [path stroke];
	);
}

- (void)notifyChangeAction:(SKLineChangeAction)action {
    currentLineChangeAction = action;
    
    SEL selector = @selector(changeLineAttribute:);
    NSWindow *mainWindow = [NSApp mainWindow];
    NSResponder *responder = [mainWindow firstResponder];
    
    while (responder && [responder respondsToSelector:selector] == NO)
        responder = [responder nextResponder];
    
    [responder performSelector:selector withObject:self];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:action], ACTION_KEY, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKLineInspectorLineAttributeDidChangeNotification object:self userInfo:userInfo];
    
    currentLineChangeAction = SKNoLineChangeAction;
}

#pragma mark Accessors

- (void)setLineWidth:(CGFloat)width {
    if (fabs(lineWidth - width) > 0.00001) {
        lineWidth = width;
        [self notifyChangeAction:SKLineChangeActionLineWidth];
    }
}

- (void)setStyle:(PDFBorderStyle)newStyle {
    if (newStyle != style) {
        style = newStyle;
        [self notifyChangeAction:SKLineChangeActionStyle];
    }
}

- (void)setDashPattern:(NSArray *)pattern {
    if ([pattern isEqualToArray:dashPattern] == NO && (pattern || dashPattern)) {
        [dashPattern release];
        dashPattern = [pattern copy];
        [self notifyChangeAction:SKLineChangeActionDashPattern];
    }
}

- (void)setStartLineStyle:(PDFLineStyle)newStyle {
    if (newStyle != startLineStyle) {
        startLineStyle = newStyle;
        [self notifyChangeAction:SKLineChangeActionStartLineStyle];
    }
}

- (void)setEndLineStyle:(PDFLineStyle)newStyle {
    if (newStyle != endLineStyle) {
        endLineStyle = newStyle;
        [self notifyChangeAction:SKLineChangeActionEndLineStyle];
    }
}

- (void)setAnnotationStyle:(PDFAnnotation *)annotation {
    NSString *type = [annotation type];
    if ([type isEqualToString:SKNFreeTextString] || [type isEqualToString:SKNCircleString] || [type isEqualToString:SKNSquareString] || [type isEqualToString:SKNLineString] || [type isEqualToString:SKNInkString]) {
        [self setLineWidth:[annotation border] ? [[annotation border] lineWidth] : 0.0];
        [self setDashPattern:[[annotation border] dashPattern]];
        [self setStyle:[annotation border] ? [[annotation border] style] : 0];
    }
    if ([type isEqualToString:SKNLineString]) {
        [self setStartLineStyle:[(PDFAnnotationLine *)annotation startLineStyle]];
        [self setEndLineStyle:[(PDFAnnotationLine *)annotation endLineStyle]];
    }
}

- (void)setNilValueForKey:(NSString *)key {
    if ([key isEqualToString:LINEWIDTH_KEY]) {
        [self setValue:[NSNumber numberWithDouble:0.0] forKey:key];
    } else if ([key isEqualToString:STYLE_KEY] || [key isEqualToString:STARTLINESTYLE_KEY] || [key isEqualToString:ENDLINESTYLE_KEY]) {
        [self setValue:[NSNumber numberWithInteger:0] forKey:key];
    } else {
        [super setNilValueForKey:key];
    }
}

@end
