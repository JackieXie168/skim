//
//  SKCompatibility.h
//  Skim
//
//  Created by Christiaan Hofman on 9/9/09.
/*
 This software is Copyright (c) 2009-2017
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

#import <Cocoa/Cocoa.h>

#ifndef NSAppKitVersionNumber10_6
    #define NSAppKitVersionNumber10_6 1038
#endif
#ifndef NSAppKitVersionNumber10_7
    #define NSAppKitVersionNumber10_7 1138
#endif
#ifndef NSAppKitVersionNumber10_8
    #define NSAppKitVersionNumber10_8 1187
#endif
#ifndef NSAppKitVersionNumber10_9
    #define NSAppKitVersionNumber10_9 1265
#endif
#ifndef NSAppKitVersionNumber10_10
    #define NSAppKitVersionNumber10_10 1343
#endif
#ifndef NSAppKitVersionNumber10_10_Max
    #define NSAppKitVersionNumber10_10_Max 1349
#endif
#ifndef NSAppKitVersionNumber10_11
    #define NSAppKitVersionNumber10_11 1404
#endif
#ifndef NSAppKitVersionNumber10_12
    #define NSAppKitVersionNumber10_12 1504
#endif

#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif

#ifndef NS_OPTIONS
#define NS_OPTIONS(_type, _name) enum _name : _type _name; enum _name : _type
#endif

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_6

@protocol NSURLDownloadDelegate <NSObject> @end

typedef NS_ENUM(NSInteger, NSWindowAnimationBehavior) {
    NSWindowAnimationBehaviorDefault = 0,
    NSWindowAnimationBehaviorNone = 2,
    NSWindowAnimationBehaviorDocumentWindow = 3,
    NSWindowAnimationBehaviorUtilityWindow = 4,
    NSWindowAnimationBehaviorAlertPanel = 5
};

enum {
    NSWindowDocumentVersionsButton = 6,
    NSWindowFullScreenButton,
};

enum {
    NSWindowCollectionBehaviorFullScreenPrimary = 1 << 7,
    NSWindowCollectionBehaviorFullScreenAuxiliary = 1 << 8
};

enum {
    NSFullScreenWindowMask = 1 << 14;
};

@interface NSWindow (SKLionDeclarations)
- (NSWindowAnimationBehavior)animationBehavior;
- (void)setAnimationBehavior:(NSWindowAnimationBehavior)newAnimationBehavior;
- (void)toggleFullScreen:(id)sender;
@end

typedef NS_OPTIONS(NSUInteger, NSEventPhase) {
    NSEventPhaseNone = 0,
    NSEventPhaseBegan = 0x1 << 0,
    NSEventPhaseStationary = 0x1 << 1,
    NSEventPhaseChanged = 0x1 << 2,
    NSEventPhaseEnded = 0x1 << 3,
    NSEventPhaseCancelled = 0x1 << 4,
    NSEventPhaseMayBegin = 0x1 << 5,
};

@interface NSEvent (SKLionDeclarations)
- (NSEventPhase)phase;
@end

#endif

#if !defined(MAC_OS_X_VERSION_10_10) || MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_10

typedef NSUInteger NSCellHitResult;

enum {
    NSWindowStyleMaskFullSizeContentView = 1 << 15;
};

@interface NSWindow (SKYosemiteDeclarations)
- (NSRect)contentLayoutRect;
@end

#endif

#if !defined(MAC_OS_X_VERSION_10_12) || MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_12

typedef NSUInteger NSWindowStyleMask;

typedef NS_ENUM(NSInteger, NSWindowTabbingMode) {
    NSWindowTabbingModeAutomatic,
    NSWindowTabbingModePreferred,
    NSWindowTabbingModeDisallowed
};

@interface NSWindow (SKSierraDeclarations)
- (NSArray *)tabbedWindows;
- (NSWindowTabbingMode)tabbingMode;
- (void)setTabbingMode:(NSWindowTabbingMode)mode;
@end

@protocol PDFViewDelegate <NSObject> @end

#endif
