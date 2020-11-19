//
//  NSURL_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 8/13/07.
/*
 This software is Copyright (c) 2007-2020
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

#import "NSURL_SKExtensions.h"
#import "SKRuntime.h"

#if SDK_BEFORE(10_10)

typedef NS_ENUM(NSInteger, NSURLRelationship) {
    NSURLRelationshipContains,
    NSURLRelationshipSame,
    NSURLRelationshipOther
};

@interface NSFileManager (SKYosemiteDeclarations)
- (BOOL)getRelationship:(NSURLRelationship *)outRelationship ofDirectory:(NSSearchPathDirectory)directory inDomain:(NSSearchPathDomainMask)domainMask toItemAtURL:(NSURL *)url error:(NSError **)error;
@end

enum {
    NSTrashDirectory = 102;
};

#endif

// Dummy subclass for reading from pasteboard
// Reads public.url before public.file-url, unlike NSURL, so it gets the target URL for webloc/fileloc files rather than its file location
// Also tries to interpret a plain string as a URL
// Don't use for anything else
@interface SKURL : NSURL
@end

#pragma mark -

@implementation NSURL (SKExtensions)

static id (*original_initFileURLWithPath)(id, SEL, id) = NULL;
static id (*original_initWithString)(id, SEL, id) = NULL;

- (id)replacement_initFileURLWithPath:(NSString *)path {
    return path == nil ? nil : original_initFileURLWithPath(self, _cmd, path);
}

- (id)replacement_initWithString:(NSString *)URLString {
    return URLString == nil ? nil : original_initWithString(self, _cmd, URLString);
}

+ (void)load {
    original_initFileURLWithPath = (id (*)(id, SEL, id))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(initFileURLWithPath:), @selector(replacement_initFileURLWithPath:));
    original_initWithString = (id (*)(id, SEL, id))SKReplaceInstanceMethodImplementationFromSelector(self, @selector(initWithString:), @selector(replacement_initWithString:));
}

+ (BOOL)canReadURLFromPasteboard:(NSPasteboard *)pboard {
    return [pboard canReadObjectForClasses:[NSArray arrayWithObject:[SKURL class]] options:[NSDictionary dictionary]] ||
           [pboard canReadItemWithDataConformingToTypes:[NSArray arrayWithObjects:NSURLPboardType, NSFilenamesPboardType, nil]];
}

+ (NSArray *)readURLsFromPasteboard:(NSPasteboard *)pboard {
    NSArray *URLs = [pboard readObjectsForClasses:[NSArray arrayWithObject:[SKURL class]] options:[NSDictionary dictionary]];
    if ([URLs count] == 0) {
        NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSURLPboardType, NSFilenamesPboardType, nil]];
        if ([type isEqualToString:NSURLPboardType]) {
            URLs = [NSArray arrayWithObjects:[NSURL URLFromPasteboard:pboard], nil];
        } else if ([type isEqualToString:NSFilenamesPboardType]) {
            NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
            if ([filenames count]  > 0) {
                NSMutableArray *files = [NSMutableArray array];
                for (NSString *filename in filenames)
                    [files addObject:[NSURL fileURLWithPath:[filename stringByExpandingTildeInPath]]];
                URLs = files;
            }
        }
    }
    return URLs;
}

+ (BOOL)canReadFileURLFromPasteboard:(NSPasteboard *)pboard {
    return [pboard canReadObjectForClasses:[NSArray arrayWithObject:[NSURL class]] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSPasteboardURLReadingFileURLsOnlyKey, nil]] ||
           [pboard canReadItemWithDataConformingToTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
}

+ (NSArray *)readFileURLsFromPasteboard:(NSPasteboard *)pboard {
    NSArray *fileURLs = [pboard readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSPasteboardURLReadingFileURLsOnlyKey, nil]];
    if ([fileURLs count] == 0 && [[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
        if ([filenames count]  > 0) {
            NSMutableArray *files = [NSMutableArray array];
            for (NSString *filename in filenames)
                [files addObject:[NSURL fileURLWithPath:[filename stringByExpandingTildeInPath]]];
            fileURLs = files;
        }
    }
    return fileURLs;
}

- (NSURL *)URLReplacingPathExtension:(NSString *)ext {
    return [[self URLByDeletingPathExtension] URLByAppendingPathExtension:ext];
}

- (NSString *)lastPathComponentReplacingPathExtension:(NSString *)ext {
    return [[self URLReplacingPathExtension:ext] lastPathComponent];
}

- (NSURL *)uniqueFileURL {
    NSURL *uniqueFileURL = self;
    NSURL *baseURL = [self URLByDeletingLastPathComponent];
    NSString *baseName = [[self lastPathComponent] stringByDeletingPathExtension];
    NSString *extension = [self pathExtension];
    NSInteger i = 0;
    while ([uniqueFileURL checkResourceIsReachableAndReturnError:NULL])
        uniqueFileURL = [baseURL URLByAppendingPathComponent:[[baseName stringByAppendingFormat:@"-%ld", (long)++i] stringByAppendingPathExtension:extension]];
    return uniqueFileURL;
}

- (BOOL)isTrashedFileURL {
    NSCParameterAssert([self isFileURL]);    
    if ([[NSFileManager defaultManager] respondsToSelector:@selector(getRelationship:ofDirectory:inDomain:toItemAtURL:error:)]) {
        NSURLRelationship relationship;
        if ([[NSFileManager defaultManager] getRelationship:&relationship ofDirectory:NSTrashDirectory inDomain:0 toItemAtURL:self error:NULL])
            return relationship == NSURLRelationshipContains;
    }
    FSRef fileRef;
    Boolean result = false;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (CFURLGetFSRef((CFURLRef)self, &fileRef)) {
        FSDetermineIfRefIsEnclosedByFolder(0, kTrashFolderType, &fileRef, &result);
        if (result == false)
            FSDetermineIfRefIsEnclosedByFolder(0, kSystemTrashFolderType, &fileRef, &result);
    }
#pragma clang diagnostic pop
    return result;
}

- (BOOL)isSkimURL {
    NSString *scheme = [self scheme];
    return scheme && [scheme caseInsensitiveCompare:@"skim"] == NSOrderedSame;
}

- (BOOL)isSkimBookmarkURL {
    if ([self isSkimURL] == NO)
        return NO;
    NSString *host = [self host];
    return host && [host caseInsensitiveCompare:@"bookmarks"] == NSOrderedSame;
}

- (BOOL)isSkimFileURL {
    if ([self isSkimURL] == NO)
        return NO;
    NSString *host = [self host];
    return host == nil || [host caseInsensitiveCompare:@"bookmarks"] != NSOrderedSame;
}

- (NSURL *)skimFileURL {
    if ([self isFileURL])
        return self;
    if ([self isSkimFileURL] == NO)
        return nil;
    NSString *fileURLString = [@"file" stringByAppendingString:[[self absoluteString] substringFromIndex:4]];
    return [NSURL URLWithString:fileURLString];
}

static NSString *fileTypeOfURL(NSURL *url) {
    NSString *type = nil;
    if ([url isFileURL]) {
        type = [[NSWorkspace sharedWorkspace] typeOfFile:[url path] error:NULL];
    } else {
        type = [(NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)[url pathExtension], NULL) autorelease];
    }
    return type ?: @"";
}

static NSFileWrapper *fileWrapperForFileType(NSString *type) {
    static NSMutableDictionary *typeIconWrappers = nil;
    NSFileWrapper *wrapper = [typeIconWrappers objectForKey:type];
    if (wrapper == nil) {
        NSImage *image = [[NSWorkspace sharedWorkspace] iconForFileType:type];
        if (image == nil)
            image = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericDocumentIcon)];
        if (typeIconWrappers == nil)
            typeIconWrappers = [[NSMutableDictionary alloc] init];
        NSString *name = [type stringByAppendingPathExtension:@"tiff"];
        wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[image TIFFRepresentation]];
        [wrapper setFilename:name];
        [wrapper setPreferredFilename:name];
        [typeIconWrappers setObject:wrapper forKey:type];
        [wrapper release];
    }
    return wrapper;
}

static NSFileWrapper *smallFileWrapperForFileType(NSString *type) {
    static NSMutableDictionary *typeIconWrappers = nil;
    NSFileWrapper *wrapper = [typeIconWrappers objectForKey:type];
    if (wrapper == nil) {
        NSImage *fileImage = [[NSWorkspace sharedWorkspace] iconForFileType:type];
        if (fileImage == nil)
            fileImage = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericDocumentIcon)];
        NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(16.0, 16.0)];
        [image lockFocus];
        [fileImage drawInRect:NSMakeRect(0.0, 0.0, 16.0, 16.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
        [image unlockFocus];
        if (typeIconWrappers == nil)
            typeIconWrappers = [[NSMutableDictionary alloc] init];
        NSString *name = [type stringByAppendingPathExtension:@"tiff"];
        wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[image TIFFRepresentation]];
        [wrapper setFilename:name];
        [wrapper setPreferredFilename:name];
        [typeIconWrappers setObject:wrapper forKey:type];
        [wrapper release];
        [image release];
    }
    return wrapper;
}

- (NSAttributedString *)icon {
    NSAttributedString *attrString = nil;
    NSFileWrapper *wrapper = fileWrapperForFileType(fileTypeOfURL(self));
    if (wrapper) {
        NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithFileWrapper:wrapper];
        [wrapper release];
        attrString = [NSAttributedString attributedStringWithAttachment:attachment];
        [attachment release];
        
    }
    return attrString;
}

- (NSAttributedString *)smallIcon {
    NSAttributedString *attrString = nil;
    NSFileWrapper *wrapper = smallFileWrapperForFileType(fileTypeOfURL(self));
    if (wrapper) {
        NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithFileWrapper:wrapper];
        [wrapper release];
        attrString = [NSAttributedString attributedStringWithAttachment:attachment];
        [attachment release];
        
    }
    return attrString;
}

- (NSAttributedString *)linkedIcon {
    NSMutableAttributedString *attrString = nil;
    NSFileWrapper *wrapper = fileWrapperForFileType(fileTypeOfURL(self));
    if (wrapper) {
        NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithFileWrapper:wrapper];
        [wrapper release];
        attrString = [[NSAttributedString attributedStringWithAttachment:attachment] mutableCopy];
        [attachment release];
        [attrString addAttribute:NSLinkAttributeName value:self range:NSMakeRange(0, [attrString length])];
    }
    return [attrString autorelease];
}

- (NSAttributedString *)linkedSmallIcon {
    NSMutableAttributedString *attrString = nil;
    NSFileWrapper *wrapper = smallFileWrapperForFileType(fileTypeOfURL(self));
    if (wrapper) {
        NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithFileWrapper:wrapper];
        [wrapper release];
        attrString = [[NSAttributedString attributedStringWithAttachment:attachment] mutableCopy];
        [attachment release];
        [attrString addAttribute:NSLinkAttributeName value:self range:NSMakeRange(0, [attrString length])];
    }
    return [attrString autorelease];
}

- (NSAttributedString *)linkedText {
    return [[[NSAttributedString alloc] initWithString:[self absoluteString] attributes:[NSDictionary dictionaryWithObject:self forKey:NSLinkAttributeName]] autorelease];
}

- (NSAttributedString *)linkedFileName {
    NSString *fileName = [self absoluteString];
    if ([self isFileURL]) {
        fileName = [[NSFileManager defaultManager] displayNameAtPath:[self path]];
    } else if ([self isSkimURL]) {
        fileName = [self path];
        if ([self isSkimBookmarkURL])
            fileName = [fileName lastPathComponent];
        else
            fileName = [[NSFileManager defaultManager] displayNameAtPath:fileName];
    }
    return [[[NSAttributedString alloc] initWithString:([self isFileURL] ? [[NSFileManager defaultManager] displayNameAtPath:[self path]] : [self absoluteString]) attributes:[NSDictionary dictionaryWithObject:self forKey:NSLinkAttributeName]] autorelease];
}

@end

#pragma mark -

@implementation SKURL

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
    return [NSArray arrayWithObjects:(NSString *)kUTTypeURL, (NSString *)kUTTypeFileURL, NSPasteboardTypeString, nil];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
    if ([type isEqualToString:(NSString *)kUTTypeURL] || [type isEqualToString:(NSString *)kUTTypeFileURL] || [type isEqualToString:NSPasteboardTypeString])
        return NSPasteboardReadingAsString;
    return NSPasteboardReadingAsData;
}

- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type {
    [self release];
    self = nil;
    if ([propertyList isKindOfClass:[NSString class]]) {
        NSString *string = propertyList;
        if ([type isEqualToString:(NSString *)kUTTypeURL] || [type isEqualToString:(NSString *)kUTTypeFileURL]) {
            self = (id)[[NSURL alloc] initWithString:string];
        } else if ([type isEqualToString:NSPasteboardTypeString]) {
            if ([string rangeOfString:@"://"].length) {
                if ([string hasPrefix:@"<"] && [string hasSuffix:@">"])
                    string = [string substringWithRange:NSMakeRange(1, [string length] - 2)];
                self = (id)[[NSURL alloc] initWithString:string];
                if (self == nil)
                    self = (id)[[NSURL alloc] initWithString:[string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            }
            if (self == nil) {
                if ([string hasPrefix:@"~"])
                    string = [string stringByExpandingTildeInPath];
                if ([[NSFileManager defaultManager] fileExistsAtPath:string])
                    self = (id)[[NSURL alloc] initFileURLWithPath:string];
            }
        }
    }
    return self;
}

@end
