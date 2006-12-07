//
//  BDSKMacroResolver.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 3/20/06.
/*
 This software is Copyright (c) 2006
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

#import "BDSKMacroResolver.h"
#import "BDSKDocument.h"


@interface BDSKGlobalMacroResolver : BDSKMacroResolver {
    NSMutableDictionary *standardMacroDefinitions;
    NSMutableDictionary *fileMacroDefinitions;
}

- (NSDictionary *)fileMacroDefinitions;
- (void)loadMacrosFromFiles;
- (void)synchronize;
- (void)handleMacroFilesChanged:(NSNotification *)notification;

@end


@interface BDSKMacroResolver (Private)
- (void)loadMacroDefinitions;
- (void)synchronize;
- (void)addMacro:(NSString *)macroKey toArray:(NSMutableArray *)array;
@end


@implementation BDSKMacroResolver

static BDSKGlobalMacroResolver *defaultMacroResolver; 

+ (id)defaultMacroResolver{
    if(defaultMacroResolver == nil)
        defaultMacroResolver = [[BDSKGlobalMacroResolver alloc] init];
    return defaultMacroResolver;
}

- (id)init{
    self = [self initWithDocument:nil];
    return self;
}

- (id)initWithDocument:(BDSKDocument *)aDocument{
    if (self = [super init]) {
        document = aDocument;
    }
    return self;
}

- (void)dealloc {
    document = nil;
    [super dealloc];
}

- (BDSKDocument *)document{
    return document;
}

- (NSUndoManager *)undoManager{
    return [document undoManager];
}

- (NSString *)bibTeXString{
    return @"";
}

- (BOOL)macroDefinition:(NSString *)macroDef dependsOnMacro:(NSString *)macroKey{
    return NO;
}

#pragma mark BDSKMacroResolver protocol

- (NSDictionary *)macroDefinitions {
    return nil;
}

- (void)addMacroDefinitionWithoutUndo:(NSString *)macroString forMacro:(NSString *)macroKey{
}

- (void)changeMacroKey:(NSString *)oldKey to:(NSString *)newKey{
}

- (void)addMacroDefinition:(NSString *)macroString forMacro:(NSString *)macroKey{
}

- (void)setMacroDefinition:(NSString *)newDefinition forMacro:(NSString *)macroKey{
}

- (void)removeMacro:(NSString *)macroKey{
}

- (NSString *)valueOfMacro:(NSString *)macroString{
    return nil;
}

@end


@implementation BDSKMacroResolver (Private)

- (void)loadMacroDefinitions{
}

- (void)synchronize{}

- (void)addMacro:(NSString *)macroKey toArray:(NSMutableArray *)array{
}

@end


@implementation BDSKGlobalMacroResolver

- (id)initWithDocument:(BDSKDocument *)aDocument{
    if (self = [super initWithDocument:nil]) {
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)loadMacroDefinitions{
}

- (void)loadMacrosFromFiles{
}

- (void)synchronize{
}

- (void)handleMacroFilesChanged:(NSNotification *)notification{
}

- (NSDictionary *)fileMacroDefinitions{
    return nil;
}

- (NSString *)valueOfMacro:(NSString *)macroString{
    return nil;
}

@end
