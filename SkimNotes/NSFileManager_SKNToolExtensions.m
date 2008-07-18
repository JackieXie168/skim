//
//  NSFileManager_SKNToolExtensions.m
//  SkimNotes
//
//  Created by Christiaan Hofman on 7/17/08.
/*
 This software is Copyright (c) 2008
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

#import "NSFileManager_SKNToolExtensions.h"
#import "SKNExtendedAttributeManager.h"
#import "SKNUtilities.h"

#define BUNDLE_DATA_FILENAME @"data"

@implementation NSFileManager (SKNToolExtensions)

- (NSString *)notesFileWithExtension:(NSString *)extension atPath:(NSString *)path error:(NSError **)error {
    NSString *filePath = nil;
    
    path = [path stringByStandardizingPath];
    if ([extension caseInsensitiveCompare:SKIM_EXTENSION] == NSOrderedSame) {
        NSArray *files = [self subpathsAtPath:path];
        NSString *filename = [[[path lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:SKIM_EXTENSION];
        if ([files containsObject:filename] == NO) {
            NSUInteger idx = [[files valueForKeyPath:@"pathExtension.lowercaseString"] indexOfObject:SKIM_EXTENSION];
            filename = idx == NSNotFound ? nil : [files objectAtIndex:idx];
        }
        if (filename)
            filePath = [path stringByAppendingPathComponent:filename];
    } else {
        NSString *skimFile = [self notesFileWithExtension:SKIM_EXTENSION atPath:path error:error];
        if (skimFile) {
            filePath = [[skimFile stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] == NO)
                filePath = nil;
        }
    }
    if (filePath == nil && error) 
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Notes file note found", NSLocalizedDescriptionKey, nil]];
    return filePath;
}

- (NSData *)SkimNotesAtPath:(NSString *)path error:(NSError **)outError {
    NSError *error;
    NSData *data = nil;
    NSString *extension = [path pathExtension];
    
    path = [path stringByStandardizingPath];
    if ([extension caseInsensitiveCompare:PDFD_EXTENSION] == NSOrderedSame) {
        NSString *notePath = [self notesFileWithExtension:SKIM_EXTENSION atPath:path error:&error];
        if (notePath)
            data = [NSData dataWithContentsOfFile:notePath options:0 error:&error];
        if (nil == data && outError)
            *outError = error;
    } else if ([extension caseInsensitiveCompare:SKIM_EXTENSION] == NSOrderedSame) {
        data = [NSData dataWithContentsOfFile:path options:0 error:&error];
        if (nil == data && outError)
            *outError = error;
    } else {
        data = [[SKNExtendedAttributeManager sharedManager] extendedAttributeNamed:SKIM_NOTES_KEY atPath:path traverseLink:YES error:&error];
        if (nil == data) {
            if ([error code] == ENOATTR)
                data = [NSData data];
            else if (outError)
                *outError = error;
        }
    }
    return data;
}

- (NSString *)SkimTextNotesAtPath:(NSString *)path error:(NSError **)outError {
    NSError *error;
    NSString *string = nil;
    NSString *extension = [path pathExtension];
    
    path = [path stringByStandardizingPath];
    if ([extension caseInsensitiveCompare:PDFD_EXTENSION] == NSOrderedSame) {
        NSString *notePath = [self notesFileWithExtension:TXT_EXTENSION atPath:path error:&error];
        if (notePath)
            string = [NSString stringWithContentsOfFile:notePath encoding:NSUTF8StringEncoding error:&error];
        if (nil == string && outError)
            *outError = error;
    } else {
        string = [[SKNExtendedAttributeManager sharedManager] propertyListFromExtendedAttributeNamed:SKIM_TEXT_NOTES_KEY atPath:path traverseLink:YES error:&error];
        if (nil == string) {
            if ([error code] == ENOATTR)
                string = @"";
            else if (outError)
                *outError = error;
        }
    }
    return string;
}

- (NSData *)SkimRTFNotesAtPath:(NSString *)path error:(NSError **)outError {
    NSError *error;
    NSData *data = nil;
    NSString *extension = [path pathExtension];
    
    path = [path stringByStandardizingPath];
    if ([extension caseInsensitiveCompare:PDFD_EXTENSION] == NSOrderedSame) {
        NSString *notePath = [self notesFileWithExtension:RTF_EXTENSION atPath:path error:&error];
        if (notePath)
            data = [NSData dataWithContentsOfFile:notePath options:0 error:&error];
        if (nil == data && outError)
            *outError = error;
    } else {
        data = [[SKNExtendedAttributeManager sharedManager] extendedAttributeNamed:SKIM_RTF_NOTES_KEY atPath:path traverseLink:YES error:&error];
        if (nil == data) {
            if ([error code] == ENOATTR)
                data = [NSData data];
            else if (outError)
                *outError = error;
        }
    }
    return data;
}

- (BOOL)writeSkimNotes:(NSData *)notesData textNotes:(NSString *)textNotes RTFNotes:(NSData *)rtfNotesData atPath:(NSString *)path error:(NSError **)outError {
    BOOL success = YES;
    NSError *error = nil;
    NSString *extension = [path pathExtension];
    
    [self removeSkimNotesAtPath:path error:NULL];
    if ([notesData length]) {
        NSArray *notes = [NSKeyedUnarchiver unarchiveObjectWithData:notesData];
        if ([notes count]) {
            if (textNotes == nil)
                textNotes = SKNTextNotes(notes);
            if (rtfNotesData == nil)
                rtfNotesData = SKNRTFNotes(notes);
        }
        NSData *textNotesData = [textNotes dataUsingEncoding:NSUTF8StringEncoding];
        if ([extension caseInsensitiveCompare:PDFD_EXTENSION] == NSOrderedSame) {
            NSString *name = [[path lastPathComponent] stringByDeletingPathExtension];
            if ([name caseInsensitiveCompare:BUNDLE_DATA_FILENAME] == NSOrderedSame)
                name = [name stringByAppendingString:@"1"];
            NSString *notePath = [[path stringByAppendingPathComponent:name] stringByAppendingPathExtension:SKIM_EXTENSION];
            success = [notesData writeToFile:notePath options:0 error:&error];
            if (textNotesData) {
                notePath = [[path stringByAppendingPathComponent:name] stringByAppendingPathExtension:TXT_EXTENSION];
                [textNotesData writeToFile:notePath options:0 error:NULL];
            }
            if (rtfNotesData) {
                notePath = [[path stringByAppendingPathComponent:name] stringByAppendingPathExtension:TXT_EXTENSION];
                [rtfNotesData writeToFile:notePath options:0 error:NULL];
            }
        } else {
            SKNExtendedAttributeManager *eam = [SKNExtendedAttributeManager sharedManager];
            success = [eam setExtendedAttributeNamed:SKIM_NOTES_KEY toValue:notesData atPath:path options:0 error:&error];
            if (textNotesData)
                [eam setExtendedAttributeNamed:SKIM_TEXT_NOTES_KEY toValue:textNotesData atPath:path options:0 error:NULL];
            if (rtfNotesData)
                [eam setExtendedAttributeNamed:SKIM_RTF_NOTES_KEY toValue:rtfNotesData atPath:path options:0 error:NULL];
        }
    }
    return success;
}

- (BOOL)removeSkimNotesAtPath:(NSString *)path error:(NSError **)outError {
    BOOL success1 = YES, success2 = YES, success3 = YES;
    NSError *error1 = nil, *error2 = nil, *error3 = nil;
    NSString *extension = [path pathExtension];
    
    if ([extension caseInsensitiveCompare:PDFD_EXTENSION] == NSOrderedSame) {
        NSString *notePath;
        if (notePath = [self notesFileWithExtension:SKIM_EXTENSION atPath:path error:NULL])
            success1 = [self removeFileAtPath:notePath handler:nil];
        if (notePath = [self notesFileWithExtension:TXT_EXTENSION atPath:path error:NULL])
            success2 = [self removeFileAtPath:notePath handler:nil];
        if (notePath = [self notesFileWithExtension:RTF_EXTENSION atPath:path error:NULL])
            success3 = [self removeFileAtPath:notePath handler:nil];
        if (notePath = [self notesFileWithExtension:FDF_EXTENSION atPath:path error:NULL])
            [self removeFileAtPath:notePath handler:nil];
        if (success1 == NO || success2 == NO || success3 == NO)
            error1 = error2 = error3 = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not remove notes file", NSLocalizedDescriptionKey, nil]];
    } else {
        SKNExtendedAttributeManager *eam = [SKNExtendedAttributeManager sharedManager];
        success1 = [eam removeExtendedAttribute:SKIM_NOTES_KEY atPath:path traverseLink:YES error:&error1];
        if (success1 == NO && [error1 code] == ENOATTR)
            success1 = YES;
        success2 = [eam removeExtendedAttribute:SKIM_RTF_NOTES_KEY atPath:path traverseLink:YES error:&error2];
        if (success2 == NO && [error2 code] == ENOATTR)
            success2 = YES;
        success3 = [eam removeExtendedAttribute:SKIM_TEXT_NOTES_KEY atPath:path traverseLink:YES error:&error3];
        if (success3 == NO && [error3 code] == ENOATTR)
            success3 = YES;
    }
    if (success1 == NO && outError)
        *outError = error1;
    else if (success2 == NO && outError)
        *outError = error2;
    else if (success3 == NO && outError)
        *outError = error3;
    return success1 && success2 && success3;
}

@end
