//
//  NSFileManager_SKNExtensions.m
//  SkimNotes
//
//  Created by Christiaan Hofman on 6/15/08.
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

#import "NSFileManager_SKNExtensions.h"
#import "SKNExtendedAttributeManager.h"
#import "SKNUtilities.h"


@implementation NSFileManager (SKNExtensions)

- (BOOL)writeSkimNotes:(NSArray *)notes toExtendedAttributesAtURL:(NSURL *)aURL error:(NSError **)outError {
    return [self writeSkimNotes:notes textNotes:nil richTextNotes:nil toExtendedAttributesAtURL:aURL error:outError];
}

- (BOOL)writeSkimNotes:(NSArray *)notes textNotes:(NSString *)notesString richTextNotes:(NSData *)notesRTFData toExtendedAttributesAtURL:(NSURL *)aURL error:(NSError **)outError {
    BOOL success = YES;
    
    if ([aURL isFileURL]) {
        NSString *path = [aURL path];
        NSData *data = notes ? [NSKeyedArchiver archivedDataWithRootObject:notes] : nil;
        NSError *error = nil;
        SKNExtendedAttributeManager *eam = [SKNExtendedAttributeManager sharedManager];
        
        // first remove all old notes
        if ([eam removeExtendedAttribute:SKIM_NOTES_KEY atPath:path traverseLink:YES error:&error] == NO) {
            // should we set success to NO and return an error?
            //NSLog(@"%@: %@", self, error);
        }
        [eam removeExtendedAttribute:SKIM_TEXT_NOTES_KEY atPath:path traverseLink:YES error:NULL];
        [eam removeExtendedAttribute:SKIM_RTF_NOTES_KEY atPath:path traverseLink:YES error:NULL];
        
        if ([notes count]) {
            if ([eam setExtendedAttributeNamed:SKIM_NOTES_KEY toValue:data atPath:path options:kSKNXattrDefault error:&error] == NO) {
                success = NO;
                if (outError) *outError = error;
                //NSLog(@"%@: %@", self, error);
            } else {
                if (notesString == nil)
                    notesString = SKNSkimTextNotes(notes);
                if (notesRTFData == nil)
                    notesRTFData = SKNSkimRTFNotes(notes);
                [eam setExtendedAttributeNamed:SKIM_TEXT_NOTES_KEY toPropertyListValue:notesString atPath:path options:0 error:NULL];
                [eam setExtendedAttributeNamed:SKIM_RTF_NOTES_KEY toValue:notesRTFData atPath:path options:0 error:NULL];
            }
        }
    }
    return success;
}

- (BOOL)writeSkimNotes:(NSArray *)notes toSkimFileAtURL:(NSURL *)aURL error:(NSError **)outError {
    BOOL success = YES;
    
    if ([aURL isFileURL]) {
        NSData *data = notes ? [NSKeyedArchiver archivedDataWithRootObject:notes] : nil;
        success = [data writeToURL:aURL options:NSAtomicWrite error:outError];
    }
    return success;
}

- (NSArray *)readSkimNotesFromExtendedAttributesAtURL:(NSURL *)aURL error:(NSError **)outError {
    NSArray *notes = nil;
    NSError *error = nil;
    
    if ([aURL isFileURL]) {
        NSData *data = [[SKNExtendedAttributeManager sharedManager] extendedAttributeNamed:SKIM_NOTES_KEY atPath:[aURL path] traverseLink:YES error:&error];
        
        if ([data length]) {
            @try { notes = [NSKeyedUnarchiver unarchiveObjectWithData:data]; }
            @catch (id e) {}
        } else if (data || [error code] == ENOATTR) {
            notes = [NSArray array];
        }
    }
    if (notes == nil && outError) 
        *outError = error ? error : [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKNLocalizedString(@"The file does not exist or is not a file.", @"Error description"), NSLocalizedDescriptionKey, nil]];
    return notes;
}

- (NSString *)readSkimTextNotesFromExtendedAttributesAtURL:(NSURL *)aURL error:(NSError **)outError {
    NSString *string = nil;
    NSError *error = nil;
    
    if ([aURL isFileURL]) {
        string = [[SKNExtendedAttributeManager sharedManager] propertyListFromExtendedAttributeNamed:SKIM_TEXT_NOTES_KEY atPath:[aURL path] traverseLink:YES error:&error];
        
        if (string == nil && [error code] == ENOATTR)
            string = [NSString string];
    }
    if (string == nil && outError) 
        *outError = error ? error : [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKNLocalizedString(@"The file does not exist or is not a file.", @"Error description"), NSLocalizedDescriptionKey, nil]];
    return string;
}

- (NSData *)readSkimRTFNotesFromExtendedAttributesAtURL:(NSURL *)aURL error:(NSError **)outError {
    NSData *data = nil;
    NSError *error = nil;
    
    if ([aURL isFileURL]) {
        data = [[SKNExtendedAttributeManager sharedManager] extendedAttributeNamed:SKIM_RTF_NOTES_KEY atPath:[aURL path] traverseLink:YES error:&error];
        
        if (data == nil && [error code] == ENOATTR)
            data = [NSData data];
    }
    if(data == nil && outError) 
        *outError = error ? error : [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKNLocalizedString(@"The file does not exist or is not a file.", @"Error description"), NSLocalizedDescriptionKey, nil]];
    return data;
}

- (NSArray *)readSkimNotesFromPDFBundleAtURL:(NSURL *)aURL error:(NSError **)outError {
    NSArray *notes = nil;
    NSError *error = nil;
    NSString *path = [aURL path];
    BOOL isDir;
    
    if ([aURL isFileURL] && [self fileExistsAtPath:path isDirectory:&isDir] && isDir) {
        NSString *skimFile = [self bundledFileWithExtension:SKIM_EXTENSION inPDFBundleAtPath:path error:&error];
        NSData *data = skimFile ? [NSData dataWithContentsOfFile:skimFile options:0 error:&error] : nil;
        
        if ([data length]) {
            @try { notes = [NSKeyedUnarchiver unarchiveObjectWithData:data]; }
            @catch (id e) {}
        } else if (data || skimFile == nil) {
            notes = [NSArray array];
        }
    }
    if (notes == nil && outError) 
        *outError = error ? error : [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKNLocalizedString(@"The file does not exist or is not a package.", @"Error description"), NSLocalizedDescriptionKey, nil]];
    return notes;
}

- (NSString *)readSkimTextNotesFromPDFBundleAtURL:(NSURL *)aURL error:(NSError **)outError {
    NSString *string = nil;
    NSError *error = nil;
    NSString *path = [aURL path];
    BOOL isDir;
    
    if ([aURL isFileURL] && [self fileExistsAtPath:path isDirectory:&isDir] && isDir) {
        NSString *notesFile = [self bundledFileWithExtension:TXT_EXTENSION inPDFBundleAtPath:path error:&error];
        
        if (notesFile)
            string = [NSString stringWithContentsOfFile:notesFile encoding:NSUTF8StringEncoding error:&error];
        
        if (string == nil)
            string = [NSString string];
    }
    if (string == nil && outError) 
        *outError = error ? error : [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKNLocalizedString(@"The file does not exist or is not a package.", @"Error description"), NSLocalizedDescriptionKey, nil]];
    return string;
}

- (NSData *)readSkimRTFNotesFromPDFBundleAtURL:(NSURL *)aURL error:(NSError **)outError {
    NSData *data = nil;
    NSError *error = nil;
    NSString *path = [aURL path];
    BOOL isDir;
    
    if ([aURL isFileURL] && [self fileExistsAtPath:path isDirectory:&isDir] && isDir) {
        NSString *notesFile = [self bundledFileWithExtension:RTF_EXTENSION inPDFBundleAtPath:path error:&error];
        
        if (notesFile)
            data = [NSData dataWithContentsOfFile:notesFile options:0 error:&error];
        
        if (data == nil)
            data = [NSData data];
    }
    if (data == nil && outError) 
        *outError = error ? error : [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKNLocalizedString(@"The file does not exist or is not a package.", @"Error description"), NSLocalizedDescriptionKey, nil]];
    return data;
}

- (NSArray *)readSkimNotesFromSkimFileAtURL:(NSURL *)aURL error:(NSError **)outError {
    NSArray *notes = nil;
    NSError *error = nil;
    NSString *path = [aURL path];
    
    if ([aURL isFileURL] && [self fileExistsAtPath:path]) {
        NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
        
        if ([data length]) {
            @try { notes = [NSKeyedUnarchiver unarchiveObjectWithData:data]; }
            @catch (id e) {}
        } else if (data) {
            notes = [NSArray array];
        }
    }
    if (notes == nil && outError) 
        *outError = error ? error : [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKNLocalizedString(@"The file does not exist or is not a file.", @"Error description"), NSLocalizedDescriptionKey, nil]];
    return notes;
}

- (NSString *)bundledFileWithExtension:(NSString *)extension inPDFBundleAtPath:(NSString *)path error:(NSError **)outError {
    NSString *filePath = nil;
    
    extension = [extension lowercaseString];
    if ([extension isEqualToString:SKIM_EXTENSION] || [extension isEqualToString:PDF_EXTENSION]) {
        NSArray *files = [self subpathsAtPath:path];
        NSString *filename = [[[path lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
        if ([files containsObject:filename] == NO) {
            filename = [[[path lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
            if ([files containsObject:filename] == NO) {
                NSUInteger idx = [[files valueForKeyPath:@"pathExtension.lowercaseString"] indexOfObject:extension];
                filename = idx == NSNotFound ? nil : [files objectAtIndex:idx];
            }
        }
        if (filename)
            filePath = [path stringByAppendingPathComponent:filename];
    } else {
        NSString *skimFile = [self bundledFileWithExtension:SKIM_EXTENSION inPDFBundleAtPath:path error:outError];
        if (skimFile) {
            filePath = [[skimFile stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
            if ([self fileExistsAtPath:filePath] == NO)
                filePath = nil;
        }
    }
    if (filePath == nil && outError) 
        *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:SKNLocalizedString(@"Notes file not found.", @"Error description"), NSLocalizedDescriptionKey, nil]];
    return filePath;
}

@end
