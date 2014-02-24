//
//  SKNDocument.m
//  SkimNotes
//
//  Created by Christiaan Hofman on 7/16/08.
/*
 This software is Copyright (c) 2008-2014
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

#import "SKNDocument.h"
#import <SkimNotesBase/SkimNotesBase.h>
#import "SKNSkimReader.h"

#define SKNPDFDocumentType @"com.adobe.pdf"
#define SKNPDFBundleDocumentType @"net.sourceforge.skim-app.pdfd"
#define SKNSkimNotesDocumentType @"net.sourceforge.skim-app.skimnotes"

#define SKNDocumentErrorDomain @"SKNDocumentErrorDomain"

@implementation SKNDocument

@synthesize notes;

+ (void)initialize {
    [NSValueTransformer setValueTransformer:[[[SKNPlusOneTransformer alloc] init] autorelease] forName:@"SKNPlusOne"];
}
 
- (id)init {
    if (self = [super init]) {
        notes = [[NSArray alloc] init];    
    }
    return self;
}

- (void)dealloc {
    [notes release];
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"SKNDocument";
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)docType error:(NSError **)outError {
    
#if defined(FrameworkSample)
    
    if ([[NSWorkspace sharedWorkspace] type:SKNSkimNotesDocumentType conformsToType:docType]) {
        return [[NSFileManager defaultManager] writeSkimNotes:notes toSkimFileAtURL:absoluteURL error:outError];
    } else {
        if (outError)
            *outError = [NSError errorWithDomain:SKNDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to save notes", @""), NSLocalizedDescriptionKey, nil]];
        return NO;
    }
    
#else
    
    return [super writeToURL:absoluteURL ofType:typeName error:outError];
    
#endif
    
}

- (NSData *)dataOfType:(NSString *)docType error:(NSError **)outError {
    NSData *data = nil;
    if ([[NSWorkspace sharedWorkspace] type:SKNSkimNotesDocumentType conformsToType:docType]) {
        data = [NSKeyedArchiver archivedDataWithRootObject:notes];
    }
    if (data == nil && outError)
        *outError = [NSError errorWithDomain:SKNDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to save notes", @""), NSLocalizedDescriptionKey, nil]];
    return data;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)docType error:(NSError **)outError {
    NSArray *array = nil;
    NSError *error = nil;
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSFileManager *fm = [NSFileManager defaultManager];
    
#if defined(FrameworkSample)
    
    if ([ws type:docType conformsToType:SKNPDFDocumentType]) {
        array = [fm readSkimNotesFromExtendedAttributesAtURL:absoluteURL error:&error];
    } else if ([ws type:docType conformsToType:SKNPDFBundleDocumentType]) {
        array = [fm readSkimNotesFromPDFBundleAtURL:absoluteURL error:&error];
    } else if ([ws type:docType conformsToType:SKNSkimNotesDocumentType]) {
        array = [fm readSkimNotesFromSkimFileAtURL:absoluteURL error:&error];
    }
    
#elif defined(AgentSample)
    
    if ([ws type:docType conformsToType:SKNPDFDocumentType] ||
        [ws type:docType conformsToType:SKNPDFBundleDocumentType] ||
        [ws type:docType conformsToType:SKNSkimNotesDocumentType]) {
        array = [[SKNSkimReader sharedReader] SkimNotesAtURL:absoluteURL];
    }
    
#elif defined(ToolSample)
    
    if ([ws type:docType conformsToType:SKNPDFDocumentType]) {
        NSString *path = [absoluteURL path];
        NSString *tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
        NSString *tmpPath = [tmpDir stringByAppendingPathComponent:[[[path lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"skim"]];
        NSString *binPath = [[NSBundle mainBundle] pathForResource:@"skimnotes" ofType:nil];
        NSArray *arguments = [NSArray arrayWithObjects:@"get", path, tmpPath, nil];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:tmpDir withIntermediateDirectories:YES attributes:nil error:NULL];
        
        NSTask *task = [[NSTask alloc] init];
        [task setCurrentDirectoryPath:tmpDir];
        [task setLaunchPath:binPath];
        [task setArguments:arguments];
        [task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
        [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];
            
        BOOL success = YES;
        
        @try {
            [task launch];
            [task waitUntilExit];
            array = [NSKeyedUnarchiver unarchiveObjectWithFile:tmpPath];
        }
        @catch(id exception) {
            if([task isRunning])
                [task terminate];
            NSLog(@"%@ %@ failed", [task description], [task launchPath]);
            success = NO;
        }
        
        if (success && [task terminationStatus] == 0 && array == nil)
            array = [NSArray array];
        
        [task release];
        task = nil;
        [fm removeItemAtPath:tmpDir error:NULL];
    } else if ([ws type:docType conformsToType:SKNPDFBundleDocumentType]) {
        NSString *bundlePath = [absoluteURL path];
        NSString *filename = [[[bundlePath lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathComponent:@"skim"];
        NSString *skimPath = [bundlePath stringByAppendingPathComponent:filename];
        if ([fm fileExistsAtPath:skimPath] == NO && [fm fileExistsAtPath:bundlePath]) {
            NSArray *filenames = [fm subpathsAtPath:bundlePath];
            NSUInteger idx = [[filenames valueForKey:@"pathExtension"] indexOfObject:@"skim"];
            if (idx != NSNotFound) {
                filename = [filenames objectAtIndex:idx];
                skimPath = [bundlePath stringByAppendingPathComponent:filename];
            }
        }
        array = [NSKeyedUnarchiver unarchiveObjectWithFile:skimPath];
    } else if ([ws type:docType conformsToType:SKNSkimNotesDocumentType]) {
        array = [NSKeyedUnarchiver unarchiveObjectWithFile:[absoluteURL path]];
    }
    
#endif
    
    if (array) {
        [self setNotes:array];
    } else if (outError) {
        *outError = error ? error : [NSError errorWithDomain:SKNDocumentErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to read notes", @""), NSLocalizedDescriptionKey, nil]];
    }
    
    return array != nil;
}

@end


@implementation SKNPlusOneTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
	return value == nil ? nil : [NSNumber numberWithUnsignedInteger:[value unsignedIntegerValue] + 1];
}

@end
