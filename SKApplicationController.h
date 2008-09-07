//
//  SKApplicationController.h
//  Skim
//
//  Created by Michael McCracken on 12/6/06.
/*
 This software is Copyright (c) 2006-2008
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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

@class SUUpdater, SKLine, SKDownloadController;

@class RemoteControlContainer;

@interface SKApplicationController : NSObject {
    RemoteControlContainer *remoteControl;
    BOOL remoteScrolling;
}

+ (id)sharedApplicationController;

- (IBAction)orderFrontLineInspector:(id)sender;
- (IBAction)orderFrontNotesPanel:(id)sender;

- (IBAction)visitWebSite:(id)sender;
- (IBAction)visitWiki:(id)sender;
- (IBAction)showPreferencePanel:(id)sender;
- (IBAction)showReleaseNotes:(id)sender;
- (IBAction)showDownloads:(id)sender;

- (IBAction)editBookmarks:(id)sender;
- (IBAction)openBookmark:(id)sender;

- (void)doSpotlightImportIfNeeded;

- (NSArray *)applicationSupportDirectories;
- (NSString *)pathForApplicationSupportFile:(NSString *)file ofType:(NSString *)extension;
- (NSString *)pathForApplicationSupportFile:(NSString *)file ofType:(NSString *)extension inDirectory:(NSString *)subpath;

- (NSDictionary *)defaultPdfViewSettings;
- (void)setDefaultPdfViewSettings:(NSDictionary *)settings;
- (NSDictionary *)defaultFullScreenPdfViewSettings;
- (void)setDefaultFullScreenPdfViewSettings:(NSDictionary *)settings;
- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)fullScreenBackgroundColor;
- (void)setFullScreenBackgroundColor:(NSColor *)color;
- (NSDictionary *)defaultNoteColors;
- (void)setDefaultNoteColors:(NSDictionary *)colorDict;
- (NSDictionary *)defaultLineWidths;
- (void)setDefaultLineWidth:(NSDictionary *)dict;
- (NSDictionary *)defaultLineStyles;
- (void)setDefaultLineStyles:(NSDictionary *)dict;
- (NSDictionary *)defaultDashPatterns;
- (void)setDefaultDashPattern:(NSDictionary *)dict;
- (FourCharCode)defaultStartLineStyle;
- (void)setDefaultStartLineStyle:(FourCharCode)style;
- (FourCharCode)defaultEndLineStyle;
- (void)setDefaultEndLineStyle:(FourCharCode)style;
- (FourCharCode)defaultIconType;
- (void)setDefaultIconType:(FourCharCode)type;
- (unsigned int)countOfLines;
- (SKLine *)objectInLinesAtIndex:(unsigned int)index;

@end
