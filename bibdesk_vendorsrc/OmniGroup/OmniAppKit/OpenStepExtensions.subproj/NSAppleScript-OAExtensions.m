// Copyright 2002-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSAppleScript-OAExtensions.h"

#ifdef MAC_OS_X_VERSION_10_2

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import "NSAppleEventDescriptor-OAExtensions.h"
#import "OAFontCache.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSAppleScript-OAExtensions.m 68913 2005-10-03 19:36:19Z kc $");

@interface NSAppleScript (ApplePrivateMethods)
// Foundation
- _initWithData:(NSData *)data error:(NSDictionary **)errorInfo;
+ (ComponentInstance)_defaultScriptingComponent;
- (OSAID)_compiledScriptID;
// AppKit
+ (NSAttributedString *)_attributedStringFromDescriptor:(NSAppleEventDescriptor *)descriptor;
@end
                    
@interface NSAppleScript (OAExtensionsPrivate)
@end

@implementation NSAppleScript (OAExtensions)

- (id)initWithData:(NSData *)data error:(NSDictionary **)errorInfo;
{
    return [self _initWithData:data error:errorInfo];
}

- (NSData *)compiledData;
{
    AEDesc descriptor;
    OSErr error;

    error = OSAStore([isa _defaultScriptingComponent], [self _compiledScriptID], typeOSAGenericStorage, kOSAModeNull, &descriptor);
    if (error != noErr)
        return nil;
    return [[NSAppleEventDescriptor descriptorWithAEDescNoCopy:(&descriptor)] data];
}

+ (NSAttributedString *)attributedStringFromScriptResult:(NSAppleEventDescriptor *)descriptor;
{
    AEDesc sourceTextDesc;
    OSStatus err;
    OSAID scriptID;

    // Yeah, this is pretty stupid. Go Apple!
    err = OSACoerceFromDesc([self _defaultScriptingComponent], [descriptor aeDesc], kOSAModeNull, &scriptID);
    if (err != noErr)
        return nil;
    err = OSAGetSource([self _defaultScriptingComponent], scriptID, typeStyledText, &sourceTextDesc);
    if (err != noErr)
        return nil;
    return [self _attributedStringFromDescriptor:[NSAppleEventDescriptor descriptorWithAEDescNoCopy:&sourceTextDesc]];
}


+ (NSDictionary *)stringAttributesForAppleScriptStyle:(int)styleNumber;
{
    OSStatus err;
    ComponentInstance appleScriptComponent;
    STHandle stylesHandle;
    int fontID, pointSize, underlineStyle;
    Style style;
    RGBColor color;
    NSFont *myFont;
    NSColor *myColor;
    NSDictionary *attributes;

    appleScriptComponent = OpenDefaultComponent(kOSAComponentType, kAppleScriptSubtype);
    err = ASGetSourceStyles(appleScriptComponent, &stylesHandle);
    if (err != noErr)
        [NSException raise:NSInternalInconsistencyException format:@"Cryptic error from ASGetSourceStyles: %d", err];
    CloseComponent(appleScriptComponent);
    
    fontID = (*stylesHandle)[styleNumber].stFont;
    pointSize = (*stylesHandle)[styleNumber].stSize;
    style = (*stylesHandle)[styleNumber].stFace;
    color = (*stylesHandle)[styleNumber].stColor;

    CFStringRef fontName;
    ATSFontFamilyGetName(fontID, kATSOptionFlagsDefault, &fontName);
    myFont = [OAFontCache fontWithFamily:(NSString *)fontName size:pointSize bold:((style & bold) != 0) italic:((style & italic) != 0)];
    CFRelease(fontName);

    if ((style & underline) != 0)
        underlineStyle = NSSingleUnderlineStyle;
    else
        underlineStyle = NSNoUnderlineStyle;

    myColor = [NSColor colorWithCalibratedRed:(color.red / 65535.0) green:(color.green / 65535.0) blue:(color.blue / 65535.0) alpha:1.0];

    attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        myFont, NSFontAttributeName,
        myColor, NSForegroundColorAttributeName,
        [NSNumber numberWithInt:underlineStyle], NSUnderlineStyleAttributeName, nil];

    return attributes;
}


@end

@implementation NSAppleScript (OAExtensionsPrivate)
@end

#endif
