// Copyright 2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <Foundation/NSObject.h>
#import <AppKit/NSNibDeclarations.h> // For IBOutlet

@class NSString, NSData, NSAttributedString, NSArray;
@class NSWindow, NSProgressIndicator;

@interface OAOSAScript : NSObject 
{
    IBOutlet NSWindow *scriptSheet;
    IBOutlet NSProgressIndicator *progressIndicator;

    long int scriptID;
    NSWindow *runAttachedWindow;
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

// Returns the script's source code as formatted by AppleScript's rules (a la Script Editor)
- (NSAttributedString *)formattedSourceCode;
    // Ugly! Works by writing and reading a temp file, so be aware of potential performance penalties.

- (NSString *)execute;
- (NSString *)executeWithInterfaceOnWindow:(NSWindow *)aWindow;

// Uses the same dirty trick as -formattedSourceCode to return nicely formatted results.
- (NSAttributedString *)executeWithRichResult;
- (NSAttributedString *)executeWithRichResultAndInterfaceOnWindow:(NSWindow *)aWindow;

- (IBAction)stopScript:(id)sender;

- (NSData *)compiledData;


@end

@interface OAOSAScript (OAAppleScriptFormattingStyles)

/* Reads and writes AppleScript's source formatting settings.
   The array indices can be accessed via these handy constants from AppleScript.h:
      kASSourceStyleUncompiledText     = 0,
      kASSourceStyleNormalText         = 1,
      kASSourceStyleLanguageKeyword    = 2,
      kASSourceStyleApplicationKeyword = 3,
      kASSourceStyleComment            = 4,
      kASSourceStyleLiteral            = 5,
      kASSourceStyleUserSymbol         = 6,
      kASSourceStyleObjectSpecifier    = 7
*/

// Not yet implemented
+ (NSArray *)appleScriptStyles;
+ (void)setAppleScriptStyles:(NSArray *)newStyles;
// each array element is an NSDictionary appropriate for use with NSAttributedString. Only attributes applicable to the underlying AppleScript implementation (NSFontAttributeName, NSForegroundColorAttributeName, and NSUnderlineStyleAttributeName) are preserved. 
+ (NSArray *)appleScriptStyleNames;
// An array of plain-text strings describing each style.

@end

extern NSString *OSAScriptException;
extern NSString *OSAScriptExceptionSourceRangeKey;
