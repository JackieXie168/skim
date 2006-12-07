//
//  NSFileManager_ExtendedAttributes.m
//
//  Created by Adam R. Maxwell on 05/12/05.
//  Copyright 2005 Adam R. Maxwell. All rights reserved.
//
/*
 
 Redistribution and use in source and binary forms, with or without modification, 
 are permitted provided that the following conditions are met:
 - Redistributions of source code must retain the above copyright notice, this 
 list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or 
 other materials provided with the distribution.
 - Neither the name of Adam R. Maxwell nor the names of any contributors may be
 used to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSFileManager_ExtendedAttributes.h"
#include <sys/xattr.h>

// private function to print error messages
static NSString *xattrError(int err, const char *path);

@implementation NSFileManager (ExtendedAttributes)

- (NSArray *)extendedAttributeNamesAtPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;
{
    const char *fsPath = [self fileSystemRepresentationWithPath:path];
    NSString *errMsg;
    
    int xopts;
    
    if(follow)
        xopts = 0;
    else
        xopts = XATTR_NOFOLLOW;    
    
    ssize_t bufSize;
    ssize_t status;
    
    // call with NULL as attr name to get the size of the returned buffer
    status = listxattr(fsPath, NULL, 0, xopts);
    
    if(status == -1){
        errMsg = xattrError(errno, fsPath);
        if(error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSFilePathErrorKey, path, NSLocalizedDescriptionKey, errMsg, nil]];
        return nil;
    }
    
    NSZone *zone = NSDefaultMallocZone();
    bufSize = status;
    char *namebuf = NSZoneMalloc(zone, sizeof(char) * bufSize);
    NSAssert(namebuf != NULL, @"unable to allocate memory");
    status = listxattr(fsPath, namebuf, bufSize, xopts);
    
    if(status == -1){
        errMsg = xattrError(errno, fsPath);
        if(error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSFilePathErrorKey, path, NSLocalizedDescriptionKey, errMsg, nil]];
        NSZoneFree(zone, namebuf);
        return nil;
    }
    
    unsigned idx, start = 0;

    NSString *attribute = nil;
    NSMutableArray *attrs = [NSMutableArray array];
    
    // the names are separated by NULL characters
    for(idx = 0; idx < bufSize; idx++){
        if(namebuf[idx] == '\0'){
            attribute = [[NSString alloc] initWithBytes:&namebuf[start] length:(idx - start) encoding:NSUTF8StringEncoding];
            if(attribute) [attrs addObject:attribute];
            [attribute release];
            attribute = nil;
            start = idx + 1;
        }
    }
    
    NSZoneFree(zone, namebuf);
    return attrs;
}

- (NSArray *)allExtendedAttributesAsStringsAtPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;
{
    NSError *anError = nil;
    NSArray *dataAttrs = [self allExtendedAttributesAtPath:path traverseLink:follow error:&anError];
    if(dataAttrs == nil){
        if(error) *error = anError;
        return nil;
    }
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[dataAttrs count]];
    NSEnumerator *e = [dataAttrs objectEnumerator];
    NSData *data = nil;
    NSString *string = nil;
    
    while(data = [e nextObject]){
        string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if(string != nil){
            [array addObject:string];
            [string release];
        } else {
            if(error) *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSFilePathErrorKey, path, NSStringEncodingErrorKey, @"Unable to convert to a string", nil]]; 
            return nil;
        }
    }
    
    return array;
}

- (NSArray *)allExtendedAttributesAtPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;
{
    NSError *anError = nil;
    NSArray *attrNames = [self extendedAttributeNamesAtPath:path traverseLink:follow error:&anError];
    if(attrNames == nil){
        if(error) *error = anError;
        return nil;
    }
    
    NSEnumerator *e = [attrNames objectEnumerator];
    NSMutableArray *attributes = [NSMutableArray arrayWithCapacity:[attrNames count]];
    NSData *data = nil;
    NSString *attrName = nil;
    
    while(attrName = [e nextObject]){
        data = [self extendedAttributeNamed:attrName atPath:path traverseLink:follow error:&anError];
        if(data != nil){
            [attributes addObject:data];
        } else {
            if(error) *error = anError;
            return nil;
        }
    }
    return attributes;
}

- (NSData *)extendedAttributeNamed:(NSString *)attr atPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;
{
    const char *fsPath = [self fileSystemRepresentationWithPath:path];
    const char *attrName = [attr UTF8String];
    NSString *errMsg;
    
    int xopts;
    
    if(follow)
        xopts = 0;
    else
        xopts = XATTR_NOFOLLOW;
    
    ssize_t bufSize;
    ssize_t status;
    status = getxattr(fsPath, attrName, NULL, 0, 0, xopts);
    
    if(status == -1){
        errMsg = xattrError(errno, fsPath);
        if(error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSFilePathErrorKey, path, NSLocalizedDescriptionKey, errMsg, nil]];
        return nil;
    }
    
    bufSize = status;
    char *namebuf = NSZoneMalloc(NSDefaultMallocZone(), sizeof(char) * bufSize);
    NSAssert(namebuf != NULL, @"unable to allocate memory");
    status = getxattr(fsPath, attrName, namebuf, bufSize, 0, xopts);
    
    if(status == -1){
        errMsg = xattrError(errno, fsPath);
        if(error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSFilePathErrorKey, path, NSLocalizedDescriptionKey, errMsg, nil]];
        NSZoneFree(NSDefaultMallocZone(), namebuf);
        return nil;
    }
    
    NSData *attribute = [[NSData alloc] initWithBytes:namebuf length:bufSize];
    NSZoneFree(NSDefaultMallocZone(), namebuf);
    
    return [attribute autorelease];
}

- (BOOL)addExtendedAttributeNamed:(NSString *)attr withStringValue:(NSString *)value atPath:(NSString *)path error:(NSError **)error;
{
    return [self setExtendedAttributeNamed:attr toValue:[value dataUsingEncoding:NSUTF8StringEncoding] atPath:path options:nil error:error];
}

- (BOOL)addExtendedAttributeNamed:(NSString *)attr withValue:(NSData *)value atPath:(NSString *)path error:(NSError **)error;
{
    return [self setExtendedAttributeNamed:attr toValue:value atPath:path options:nil error:error];
}

- (BOOL)replaceExtendedAttributeNamed:(NSString *)attr withStringValue:(NSString *)value atPath:(NSString *)path error:(NSError **)error;
{
    return [self setExtendedAttributeNamed:attr toValue:[value dataUsingEncoding:NSUTF8StringEncoding] atPath:path options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"ReplaceOnly", nil] error:error];
}

- (BOOL)replaceExtendedAttributeNamed:(NSString *)attr withValue:(NSData *)value atPath:(NSString *)path error:(NSError **)error;
{
    return [self setExtendedAttributeNamed:attr toValue:value atPath:path options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"ReplaceOnly", nil] error:error];
}

- (BOOL)setExtendedAttributeNamed:(NSString *)attr toValue:(NSData *)value atPath:(NSString *)path options:(NSDictionary *)options error:(NSError **)error;
{

    const char *fsPath = [self fileSystemRepresentationWithPath:path];
    const void *data = [value bytes];
    size_t dataSize = [value length];
    const char *attrName = [attr UTF8String];
    NSString *errMsg;
    
    BOOL noFollow = NO;    // default setting of NO will prevent following symlinks
    BOOL createOnly = NO;  // YES will only allow creation (it will fail if the attr already exists)
    BOOL replaceOnly = NO; // YES will only allow replacement (it will fail if the attr does not exist)
    
    if(options != nil){
        noFollow = [[options objectForKey:@"FollowLinks"] boolValue];
        createOnly = [[options objectForKey:@"CreateOnly"] boolValue];
        replaceOnly = [[options objectForKey:@"ReplaceOnly"] boolValue];
    }
    
    int xopts = 0;
    
    if(noFollow)
        xopts = xopts | XATTR_NOFOLLOW;
    if(createOnly)
        xopts = xopts | XATTR_CREATE;
    if(replaceOnly)
        xopts = xopts | XATTR_REPLACE;
    
    int status = setxattr(fsPath, attrName, data, dataSize, 0, xopts);
    
    if(status == -1){
        errMsg = xattrError(errno, fsPath);
        if(error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSFilePathErrorKey, path, NSLocalizedDescriptionKey, errMsg, nil]];
        return NO;
    } else 
        return YES;
}

- (BOOL)removeExtendedAttribute:(NSString *)attr atPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;
{

    const char *fsPath = [self fileSystemRepresentationWithPath:path];
    const char *attrName = [attr UTF8String];
    NSString *errMsg;
    
    int xopts;
    
    if(follow)
        xopts = 0;
    else
        xopts = XATTR_NOFOLLOW;
    
    int status = removexattr(fsPath, attrName, xopts);
    
    if(status == -1){
        errMsg = xattrError(errno, fsPath);
        if(error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSFilePathErrorKey, path, NSLocalizedDescriptionKey, errMsg, nil]];
        return NO;
    } else 
        return YES;    
    
}

// guaranteed to return non-nil
NSString *xattrError(int err, const char *myPath)
{
    char *errMsg = NULL;
    switch (err)
    {
        case ENOTSUP:
            errMsg = "file system does not support extended attributes or they are disabled.";
            break;
        case ERANGE:
            errMsg = "buffer too small for attribute names.";
            break;
        case EPERM:
            errMsg = "this file system object does not support extended attributes";
            break;
        case ENOTDIR:
            errMsg = "a component of the path is not a directory";
            break;
        case ENAMETOOLONG:
            errMsg = "name too long";
            break;
        case EACCES:
            errMsg = "search permission denied for this path";
            break;
        case ELOOP:
            errMsg = "too many symlinks encountered resolving path";
            break;
        case EIO:
            errMsg = "I/O error occurred";
            break;
        case EINVAL:
            errMsg = "options not recognized";
            break;
        case EEXIST:
            errMsg = "options contained XATTR_CREATE but the named attribute exists";
            break;
        case ENOATTR:
            errMsg = "options contained XATTR_REPLACE but the named attributed does not exist";
            break;
        case EROFS:
            errMsg = "read-only file system.  Unable to change attributes";
            break;
        case EFAULT:
            errMsg = "path or name points to an invalid address";
            break;
        case E2BIG:
            errMsg = "the data size of the extended attributed is too large";
            break;
        case ENOSPC:
            errMsg = "no space left on file system";
            break;
        default:
            errMsg = "unknown error occurred";
            break;
    }
    return [NSString stringWithCString:errMsg encoding:NSASCIIStringEncoding];
}
    

@end

#import "NSURL_BDSKExtensions.h"
#import <Quartz/Quartz.h>
#import "PDFMetadata.h"

@implementation NSFileManager (PDFMetadata)

- (id)PDFMetadataForURL:(NSURL *)fileURL error:(NSError **)outError;
{
    
    NSParameterAssert(fileURL != nil);

    PDFMetadata *metadata = nil;
    // check file type first?
    NSError *error = nil;
    NSString *errMsg = @"";
    NSString *privateException = NSStringFromSelector(_cmd);
    PDFDocument *document = nil;
    
    @try {
        
        fileURL = [fileURL fileURLByResolvingAliases];
        if(fileURL == nil){
            errMsg = NSLocalizedString(@"File does not exist.", @"");
            @throw privateException;
        }
        
        document = [[PDFDocument alloc] initWithURL:fileURL];
        if(document == nil){
            errMsg = NSLocalizedString(@"Unable to read as PDF file.", @"");
            @throw privateException;
        }
        
        NSDictionary *attributes = [document documentAttributes];
        
        if(attributes){
            // have to use NSClassFromString unless we link with PDFMetadata
            metadata = [[[NSClassFromString(@"PDFMetadata") alloc] init] autorelease];
            [metadata setDictionary:attributes];
        } else {
            errMsg = NSLocalizedString(@"No PDF document attributes for file.", @"");
            @throw privateException;
        }
        
    }
    @catch(id exception){
        
        if([exception isEqual:privateException]){
            [NSError errorWithDomain:NSCocoaErrorDomain code:errno userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSFilePathErrorKey, [fileURL path], NSLocalizedDescriptionKey, errMsg, nil]];
        } else @throw;
    }
    
    @finally {
        [document release];
    }
    
    if(outError) *outError = error;
    return metadata; // may be nil
}

// -[PDFDocument writeToURL:] can be really slow; since PDFDocument isn't thread safe, we're out of luck on this one
- (BOOL)addPDFMetadata:(PDFMetadata *)attributes toURL:(NSURL *)fileURL error:(NSError **)outError;
{
    NSParameterAssert(attributes != nil);
    NSParameterAssert(fileURL != nil);
    
    // check file type first?
    NSError *error = nil;
    NSString *errMsg = @"";
    NSString *privateException = NSStringFromSelector(_cmd);
    
    @try {
        
        fileURL = [fileURL fileURLByResolvingAliases];
        if(fileURL == nil){
            errMsg = NSLocalizedString(@"File does not exist.", @"");
            @throw privateException;
        }
        
        PDFDocument *document = [[PDFDocument alloc] initWithURL:fileURL];
        if(document == nil){
            errMsg = NSLocalizedString(@"Unable to read as PDF file.", @"");
            @throw privateException;
        }
        
        [document setDocumentAttributes:[attributes dictionary]];
        
        if([document writeToURL:fileURL] == NO){
            errMsg = NSLocalizedString(@"Unable to save PDF file.", @"");
            [document release];
            @throw privateException;
        }
        
        [document release];
    }
    @catch(id exception){
        
        if([exception isEqual:privateException]){
            [NSError errorWithDomain:NSCocoaErrorDomain code:errno userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSFilePathErrorKey, [fileURL path], NSLocalizedDescriptionKey, errMsg, nil]];
            if(outError) *outError = error;
            return NO;
        } else @throw;
    }
    
    return YES;
}


@end
