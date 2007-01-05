//
//  BDSKItemPasteboardHelper.h
//
//  Created by Christiaan Hofman on 13/10/06.
/*
 This software is Copyright (c) 2006,2007
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

@class BDSKTeXTask;

@interface BDSKItemPasteboardHelper : NSObject {
    NSMutableDictionary *promisedPboardTypes;
    BDSKTeXTask *texTask;
    id delegate;
}

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (void)declareType:(NSString *)type dragCopyType:(int)dragCopyType forItems:(NSArray *)items forPasteboard:(NSPasteboard *)pboard;
- (void)addTypes:(NSArray *)newTypes forPasteboard:(NSPasteboard *)pboard;
- (BOOL)setString:(NSString *)string forType:(NSString *)type forPasteboard:(NSPasteboard *)pboard;
- (BOOL)setData:(NSData *)data forType:(NSString *)type forPasteboard:(NSPasteboard *)pboard;
- (BOOL)setPropertyList:(id)propertyList forType:(NSString *)type forPasteboard:(NSPasteboard *)pboard;
- (void)absolveDelegateResponsibility;

- (void)setPromisedItems:(NSArray *)items types:(NSArray *)types dragCopyType:(int)dragCopyType forPasteboard:(NSPasteboard *)pboard;
- (NSArray *)promisedTypesForPasteboard:(NSPasteboard *)pboard;
- (NSArray *)promisedItemsForPasteboard:(NSPasteboard *)pboard;
- (int)promisedDragCopyTypeForPasteboard:(NSPasteboard *)pboard;
- (NSString *)promisedBibTeXStringForPasteboard:(NSPasteboard *)pboard;
- (void)removePromisedType:(NSString *)type forPasteboard:(NSPasteboard *)pboard;
- (void)removePromisedTypesForPasteboard:(NSPasteboard *)pboard;
- (void)clearPromisedTypesForPasteboard:(NSPasteboard *)pboard;
- (void)provideAllPromisedTypes;
- (void)absolveResponsibility;

- (void)handleApplicationWillTerminateNotification:(NSNotification *)aNotification;

@end


@interface NSObject (BDSKItemPasteboardHelperDelegate)
// this one is compulsory
- (NSString *)pasteboardHelper:(BDSKItemPasteboardHelper *)pboardHelper bibTeXStringForItems:(NSArray *)items;
- (NSString *)pasteboardHelperWillBeginGenerating:(BDSKItemPasteboardHelper *)pboardHelper;
- (NSString *)pasteboardHelperDidEndGenerating:(BDSKItemPasteboardHelper *)pboardHelper;
@end
