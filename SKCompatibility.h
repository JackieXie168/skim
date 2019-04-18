//
//  SKCompatibility.h
//  Skim
//
//  Created by Christiaan Hofman on 9/9/09.
/*
 This software is Copyright (c) 2009-2019
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

#define SDK_BEFORE(_version) (!defined(MAC_OS_X_VERSION_ ## _version) || MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_ ## _version)
#define DEPLOYMENT_BEFORE(_version) (!defined(MAC_OS_X_VERSION_ ## _version) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_ ## _version)

#if SDK_BEFORE(10_13)

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
#ifndef NSAppKitVersionNumber10_13
    #define NSAppKitVersionNumber10_13 1561
#endif
#ifndef NSAppKitVersionNumber10_14
    #define NSAppKitVersionNumber10_14 1671
#endif

#elif SDK_BEFORE(10_14)

static const NSAppKitVersion NSAppKitVersionNumber10_13 = 1561;
static const NSAppKitVersion NSAppKitVersionNumber10_14 = 1671;

#elif SDK_BEFORE(10_15)

static const NSAppKitVersion NSAppKitVersionNumber10_14 = 1671;

#endif

#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif

#ifndef NS_OPTIONS
#define NS_OPTIONS(_type, _name) enum _name : _type _name; enum _name : _type
#endif

#if SDK_BEFORE(10_10)

enum {
    NSWindowStyleMaskFullSizeContentView = 1 << 15;
};

typedef NS_ENUM(NSInteger, NSWindowTitleVisibility) {
    NSWindowTitleVisible = 0,
    NSWindowTitleHidden = 1,
};

static const NSTimeInterval NSEventDurationForever = DBL_MAX;

typedef NS_ENUM(NSInteger, NSWindowUserTabbingPreference) {
    NSWindowUserTabbingPreferenceManual,
    NSWindowUserTabbingPreferenceAlways,
    NSWindowUserTabbingPreferenceInFullScreen,
} NS_ENUM_AVAILABLE_MAC(10_12);

typedef NS_ENUM(NSInteger, NSWindowTabbingMode) {
    NSWindowTabbingModeAutomatic, // The system automatically prefers to tab this window when appropriate
    NSWindowTabbingModePreferred, // The window explicitly should prefer to tab when shown
    NSWindowTabbingModeDisallowed // The window explicitly should not prefer to tab when shown
}  NS_ENUM_AVAILABLE_MAC(10_12);


typedef NSString * NSWindowFrameAutosaveName NS_SWIFT_BRIDGED_TYPEDEF;
typedef NSString * NSWindowPersistableFrameDescriptor NS_SWIFT_BRIDGED_TYPEDEF;
typedef NSString * NSWindowTabbingIdentifier NS_SWIFT_BRIDGED_TYPEDEF;

@interface NSWindow : NSResponder <NSAnimatablePropertyContainer, NSMenuItemValidation,
@interface NSWindow (SKYosemiteDeclarations)
- (NSRect)contentLayoutRect;
- (NSWindowTitleVisibility)titleVisibility;
- (void)setTitleVisibility:(NSWindowTitleVisibility)flag;
@end

#endif

#if SDK_BEFORE(10_12)

typedef NS_ENUM(NSInteger, NSWindowTabbingMode) {
    NSWindowTabbingModeAutomatic,
    NSWindowTabbingModePreferred,
    NSWindowTabbingModeDisallowed
};

@interface NSWindow (SKSierraDeclarations)
- (NSArray *)tabbedWindows;
- (void)addTabbedWindow:(NSWindow *)window ordered:(NSWindowOrderingMode)ordered;
- (NSWindowTabbingMode)tabbingMode;
- (void)setTabbingMode:(NSWindowTabbingMode)mode;
@end

@interface NSOutlineView (SKSierraDeclarations)
- (BOOL)stronglyReferencesItems;
- (void)setStronglyReferencesItems:(BOOL)flag;
@end

@protocol PDFViewDelegate <NSObject> @end

#endif

#if SDK_BEFORE(10_13)

@protocol PDFDocumentDelegate <NSObject> @end

#endif
