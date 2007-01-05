//
//  BDSKItemPasteboardHelper.m
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

#import "BDSKItemPasteboardHelper.h"
#import "BDSKTeXTask.h"
#import "BibDocument.h"
#import "NSArray_BDSKExtensions.h"
#import "NSObject_BDSKExtensions.h"
#import <OmniBase/assertions.h>


@implementation BDSKItemPasteboardHelper

- (id)init{
    if(self = [super init]){
		promisedPboardTypes = [[NSMutableDictionary alloc] initWithCapacity:2];
		texTask = [[BDSKTeXTask alloc] initWithFileName:@"bibcopy"];
		[texTask setDelegate:self];
        delegate = nil;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillTerminateNotification:) name:NSApplicationWillTerminateNotification object:nil];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [texTask terminate];
    [texTask release];
    [promisedPboardTypes release];
    [super dealloc];
}

- (void)handleApplicationWillTerminateNotification:(NSNotification *)aNotification{
    // the built-in AppKit variant of this comes too late, when the temporary workingDir of the texTask is already removed
    [self provideAllPromisedTypes];
}

- (id)delegate{
    return delegate;
}

- (void)setDelegate:(id)newDelegate{
    OBASSERT(newDelegate == nil || [newDelegate respondsToSelector:@selector(pasteboardHelper:bibTeXStringForItems:)]);
    delegate = newDelegate;
}

#pragma mark Promising and adding data

- (void)declareType:(NSString *)type dragCopyType:(int)dragCopyType forItems:(NSArray *)items forPasteboard:(NSPasteboard *)pboard{
	NSArray *types = [NSArray arrayWithObjects:type, BDSKBibItemPboardType, nil];
    [self clearPromisedTypesForPasteboard:pboard];
    [pboard declareTypes:types owner:self];
	[self setPromisedItems:items types:types dragCopyType:dragCopyType forPasteboard:pboard];
}

- (void)addTypes:(NSArray *)newTypes forPasteboard:(NSPasteboard *)pboard{
    [pboard addTypes:newTypes owner:self];
	NSMutableArray *types = [[promisedPboardTypes objectForKey:[pboard name]] objectForKey:@"types"];
    [types addObjectsFromArray:newTypes];
}

- (BOOL)setString:(NSString *)string forType:(NSString *)type forPasteboard:(NSPasteboard *)pboard{
    [self removePromisedType:type forPasteboard:pboard];
    return [pboard setString:string forType:type];
}

- (BOOL)setData:(NSData *)data forType:(NSString *)type forPasteboard:(NSPasteboard *)pboard{
    [self removePromisedType:type forPasteboard:pboard];
    return [pboard setData:data forType:type];
}

- (BOOL)setPropertyList:(id)propertyList forType:(NSString *)type forPasteboard:(NSPasteboard *)pboard{
    [self removePromisedType:type forPasteboard:pboard];
    return [pboard setPropertyList:propertyList forType:type];
}

- (void)absolveDelegateResponsibility{
    if(delegate == nil)
        return;
    
	NSEnumerator *nameEnum = [promisedPboardTypes keyEnumerator];
	NSString *name;
    
	while(name = [nameEnum nextObject]){
        NSPasteboard *pboard = [NSPasteboard pasteboardWithName:name];
        NSArray *types = [self promisedTypesForPasteboard:pboard];
        
        if([types containsObject:BDSKBibItemPboardType])
            [self pasteboard:pboard provideDataForType:BDSKBibItemPboardType];
        
        if([[self promisedTypesForPasteboard:pboard] count]){
            NSArray *items = [self promisedItemsForPasteboard:pboard];
            NSString *bibString = nil;
            if(items != nil)
                bibString = [delegate pasteboardHelper:self bibTeXStringForItems:items];
            if(bibString != nil){
                NSMutableDictionary *dict = [promisedPboardTypes objectForKey:[pboard name]];
                [dict removeObjectForKey:@"items"];
                [dict setObject:bibString forKey:@"bibTeXString"];
            }else{
                [pboard performSelector:@selector(setData:forType:) withObject:nil withObjectsFromArray:[self promisedTypesForPasteboard:pboard]];
                [self clearPromisedTypesForPasteboard:pboard];
            }
        }
    }
    [self setDelegate:nil];
    [self retain]; // we should stay around as pboard owner
    if([promisedPboardTypes count] == 0)
        [self absolveResponsibility];
}

#pragma mark NSPasteboard delegate methods

// we generate PDF, RTF, LaTeX, LTB, and archived items data only when they are dropped or pasted
- (void)pasteboard:(NSPasteboard *)pboard provideDataForType:(NSString *)type{
	NSArray *items = [self promisedItemsForPasteboard:pboard];
    
    if([type isEqualToString:BDSKBibItemPboardType]){
        NSMutableData *data = [NSMutableData data];
        
        if(items != nil){
            NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
            [archiver encodeObject:items forKey:@"publications"];
            [archiver finishEncoding];
            [archiver release];
        }else NSBeep();
        
        [pboard setData:data forType:BDSKBibItemPboardType];
    }else{
        NSString *bibString = nil;
        if(items != nil)
            bibString = [delegate pasteboardHelper:self bibTeXStringForItems:items];
        else
            bibString = [self promisedBibTeXStringForPasteboard:pboard];
        if(bibString != nil){
            if([type isEqualToString:NSPDFPboardType]){
                [texTask runWithBibTeXString:bibString generatedTypes:BDSKGeneratePDF];
                [pboard setData:[texTask PDFData] forType:NSPDFPboardType];
            }else if([type isEqualToString:NSRTFPboardType]){
                [texTask runWithBibTeXString:bibString generatedTypes:BDSKGenerateRTF];
                [pboard setData:[texTask RTFData] forType:NSRTFPboardType];
            }else if([type isEqualToString:NSStringPboardType]){
                // this must be LaTeX or amsrefs LTB
                int dragCopyType = [self promisedDragCopyTypeForPasteboard:pboard];
                NSString *string = nil;
                if(dragCopyType == BDSKLTBDragCopyType){
                    if([texTask runWithBibTeXString:bibString generatedTypes:BDSKGenerateLTB])
                        string = [texTask LTBString];
                }else{
                    if([texTask runWithBibTeXString:bibString generatedTypes:BDSKGenerateLaTeX])
                        string = [texTask LaTeXString];
                }
                [pboard setString:string forType:NSStringPboardType];
                if(string == nil) NSBeep();
            }
        }else{
            [pboard setData:nil forType:type];
            NSBeep();
        }
    }
	[self removePromisedType:type forPasteboard:pboard];
}

// NSPasteboard delegate method for the owner
- (void)pasteboardChangedOwner:(NSPasteboard *)pboard {
	[self removePromisedTypesForPasteboard:pboard];
}

#pragma mark Promised items and types

- (void)setPromisedItems:(NSArray *)items types:(NSArray *)types dragCopyType:(int)dragCopyType forPasteboard:(NSPasteboard *)pboard {
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:items, @"items", [[types mutableCopy] autorelease], @"types", [NSNumber numberWithInt:dragCopyType], @"dragCopyType", nil];
	[promisedPboardTypes setObject:dict forKey:[pboard name]];
}

- (NSArray *)promisedTypesForPasteboard:(NSPasteboard *)pboard {
	return [[promisedPboardTypes objectForKey:[pboard name]] objectForKey:@"types"];
}

- (int)promisedDragCopyTypeForPasteboard:(NSPasteboard *)pboard {
	return [[[promisedPboardTypes objectForKey:[pboard name]] objectForKey:@"dragCopyType"] intValue];
}

- (NSArray *)promisedItemsForPasteboard:(NSPasteboard *)pboard {
	return [[promisedPboardTypes objectForKey:[pboard name]] objectForKey:@"items"];
}

- (NSString *)promisedBibTeXStringForPasteboard:(NSPasteboard *)pboard {
	return [[promisedPboardTypes objectForKey:[pboard name]] objectForKey:@"bibTeXString"];
}

- (void)removePromisedType:(NSString *)type forPasteboard:(NSPasteboard *)pboard {
	NSMutableArray *types = [[promisedPboardTypes objectForKey:[pboard name]] objectForKey:@"types"];
	[types removeObject:type];
	if([types count] == 0)
		[self removePromisedTypesForPasteboard:pboard];
}

- (void)removePromisedTypesForPasteboard:(NSPasteboard *)pboard {
	[promisedPboardTypes removeObjectForKey:[pboard name]];
    if([promisedPboardTypes count] == 0 && promisedPboardTypes != nil && delegate == nil)   
        [self absolveResponsibility];
}

- (void)clearPromisedTypesForPasteboard:(NSPasteboard *)pboard {
	[pboard performSelector:@selector(setData:forType:) withObject:nil withObjectsFromArray:[self promisedTypesForPasteboard:pboard]];
    [self removePromisedTypesForPasteboard:pboard];
}

- (void)provideAllPromisedTypes {
	NSEnumerator *nameEnum = [[promisedPboardTypes allKeys] objectEnumerator];
	NSString *name;
    
	while(name = [nameEnum nextObject]){
        NSPasteboard *pboard = [NSPasteboard pasteboardWithName:name];
        NSArray *types = [[self promisedTypesForPasteboard:pboard] copy]; // we need to copy as types can be removed
        if(types == nil) continue;
        [self performSelector:@selector(pasteboard:provideDataForType:) withObject:pboard withObjectsFromArray:types];
        [types release];
    }
}

- (void)absolveResponsibility {
    if([promisedPboardTypes count])
        [self provideAllPromisedTypes];
    if(promisedPboardTypes != nil && delegate == nil){
        [promisedPboardTypes release];
        promisedPboardTypes = nil; // this is a sign that we have released ourselves
        [texTask terminate];
        [texTask release];
        texTask = nil;
        [self autorelease]; // using release leads to a crash
    }
}

#pragma mark TeXTask delegate

- (BOOL)texTaskShouldStartRunning:(BDSKTeXTask *)aTexTask{
    if([delegate respondsToSelector:@selector(pasteboardHelperWillBeginGenerating:)])
        [delegate pasteboardHelperWillBeginGenerating:self];
	return YES;
}

- (void)texTask:(BDSKTeXTask *)aTexTask finishedWithResult:(BOOL)success{
    if([delegate respondsToSelector:@selector(pasteboardHelperDidEndGenerating:)])
        [delegate pasteboardHelperDidEndGenerating:self];
}

@end
