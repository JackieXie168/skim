//
//  NSFileManager_SKNToolExtensions.h
//  SkimNotes
//
//  Created by Christiaan Hofman on 7/17/08.
/*
 This software is Copyright (c) 2008-2020
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

#import <Foundation/Foundation.h>

enum {
    SKNNonSyncable = -1,
    SKNAnySyncable = 0,
    SKNSyncable = 1
};
typedef NSInteger SKNSyncability;

@interface NSFileManager (SKNToolExtensions)

- (NSData *)SkimNotesAtPath:(NSString *)path error:(NSError **)outError;
- (NSString *)SkimTextNotesAtPath:(NSString *)path error:(NSError **)outError;
- (NSData *)SkimRTFNotesAtPath:(NSString *)path error:(NSError **)outError;

- (BOOL)writeSkimNotes:(NSData *)notesData textNotes:(NSString *)textNotes RTFNotes:(NSData *)rtfNotesData atPath:(NSString *)path syncable:(BOOL)syncable error:(NSError **)outError;

- (BOOL)removeSkimNotesAtPath:(NSString *)path error:(NSError **)outError;

- (BOOL)hasSkimNotesAtPath:(NSString *)path syncable:(SKNSyncability)syncable;

@end
