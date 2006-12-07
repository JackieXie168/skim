// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Carbon/OAOSAScript.h,v 1.10 2003/01/15 22:51:33 kc Exp $

#import <Foundation/NSObject.h>
#import <AppKit/NSNibDeclarations.h> // For IBOutlet

@class NSString, NSData, NSAttributedString, NSArray;
@class NSWindow, NSProgressIndicator;

@interface OAOSAScript : NSObject 
{
    IBOutlet NSWindow *scriptSheet;
    IBOutlet NSProgressIndicator *progressIndicator;
    NSWindow *runAttachedWindow;

    unsigned long int scriptID;           /* The OSAID of our compiled script */
    unsigned long int scriptContextID;    /* The OSAID of the script execution context */
}

+ (NSString *)executeScriptString:(NSString *)scriptString;
+ (OAOSAScript *)runningScript;

- init;
- initWithPath:(NSString *)scriptPath;
- initWithData:(NSData *)compiledData;
- initWithSourceCode:(NSString *)sourceText;

- (BOOL)isValid;

- (NSString *)sourceCode;
- (void)setSourceCode:(NSString *)someSource;

- (void)setProperty:(NSString *)propName toString:(NSString *)value;
- valueOfProperty:(NSString *)propName;

- (NSString *)execute;
- (NSString *)executeWithInterfaceOnWindow:(NSWindow *)aWindow;

- (IBAction)stopScript:(id)sender;

- (NSData *)compiledData;


@end

extern NSString *OSAScriptException;
extern NSString *OSAScriptExceptionSourceRangeKey;
