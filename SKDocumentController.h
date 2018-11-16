//
//  SKDocumentController.h
//  Skim
//
//  Created by Christiaan Hofman on 5/21/07.
/*
 This software is Copyright (c) 2007-2018
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

extern NSString *SKPDFDocumentType;
extern NSString *SKPDFBundleDocumentType;
extern NSString *SKNotesDocumentType;
extern NSString *SKNotesTextDocumentType;
extern NSString *SKNotesRTFDocumentType;
extern NSString *SKNotesRTFDDocumentType;
extern NSString *SKNotesFDFDocumentType;
extern NSString *SKPostScriptDocumentType;
extern NSString *SKEncapsulatedPostScriptDocumentType;
extern NSString *SKDVIDocumentType;
extern NSString *SKXDVDocumentType;
extern NSString *SKFolderDocumentType;

extern NSString *SKDocumentSetupAliasKey;
extern NSString *SKDocumentSetupFileNameKey;
extern NSString *SKDocumentSetupTabsKey;

extern NSString *SKDocumentControllerWillRemoveDocumentNotification;
extern NSString *SKDocumentControllerDidRemoveDocumentNotification;
extern NSString *SKDocumentDidShowNotification;

extern NSString *SKDocumentControllerDocumentKey;

#if SDK_BEFORE(10_7)
@interface NSDocumentController (SKLionDeclarations)
// 10.7+ method, always defined
- (void)openDocumentWithContentsOfURL:(NSURL *)absoluteURL display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler;
@end
#endif

@interface SKDocumentController : NSDocumentController

- (IBAction)newDocumentFromClipboard:(id)sender;

- (void)openDocumentWithImageFromPasteboard:(NSPasteboard *)pboard completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler;
// this method may return an SKDownload instance
- (void)openDocumentWithURLFromPasteboard:(NSPasteboard *)pboard showNotes:(BOOL)showNotes completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler;

- (void)openDocumentWithSetup:(NSDictionary *)setup completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler;
- (void)openDocumentWithSetups:(NSArray *)setups completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler;

- (Class)documentClassForContentsOfURL:(NSURL *)inAbsoluteURL;

@end
