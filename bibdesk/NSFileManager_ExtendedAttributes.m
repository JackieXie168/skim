//
//  NSFileManager_ExtendedAttributes.m
//
//  Created by Adam R. Maxwell on 05/12/05.
//  Copyright 2005, 2006, 2007 Adam R. Maxwell. All rights reserved.
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
        if(error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:[NSDictionary dictionaryWithObjectsAndKeys:path, NSFilePathErrorKey, errMsg, NSLocalizedDescriptionKey, nil]];
        return nil;
    }
    
    NSZone *zone = NSDefaultMallocZone();
    bufSize = status;
    char *namebuf = (char *)NSZoneMalloc(zone, sizeof(char) * bufSize);
    NSAssert(namebuf != NULL, @"unable to allocate memory");
    status = listxattr(fsPath, namebuf, bufSize, xopts);
    
    if(status == -1){
        errMsg = xattrError(errno, fsPath);
        if(error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:[NSDictionary dictionaryWithObjectsAndKeys:path, NSFilePathErrorKey, errMsg, NSLocalizedDescriptionKey, nil]];
        NSZoneFree(zone, namebuf);
        return nil;
    }
    
    int idx, start = 0;

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
            if(error) *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:path, NSFilePathErrorKey, [NSNumber numberWithInt:NSUTF8StringEncoding], NSStringEncodingErrorKey, NSLocalizedString(@"unable to convert to a string", @"Error description"), NSLocalizedDescriptionKey, nil]]; 
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
        if(error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:[NSDictionary dictionaryWithObjectsAndKeys:path, NSFilePathErrorKey, errMsg, NSLocalizedDescriptionKey, nil]];
        return nil;
    }
    
    bufSize = status;
    char *namebuf = (char *)NSZoneMalloc(NSDefaultMallocZone(), sizeof(char) * bufSize);
    NSAssert(namebuf != NULL, @"unable to allocate memory");
    status = getxattr(fsPath, attrName, namebuf, bufSize, 0, xopts);
    
    if(status == -1){
        errMsg = xattrError(errno, fsPath);
        if(error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:[NSDictionary dictionaryWithObjectsAndKeys:path, NSFilePathErrorKey, errMsg, NSLocalizedDescriptionKey, nil]];
        NSZoneFree(NSDefaultMallocZone(), namebuf);
        return nil;
    }
    
    NSData *attribute = [[NSData alloc] initWithBytes:namebuf length:bufSize];
    NSZoneFree(NSDefaultMallocZone(), namebuf);
    
    return [attribute autorelease];
}

- (id)propertyListFromExtendedAttributeNamed:(NSString *)attr atPath:(NSString *)path traverseLink:(BOOL)traverse error:(NSError **)outError;
{
    NSError *error;
    NSData *data = [self extendedAttributeNamed:attr atPath:path traverseLink:traverse error:&error];
    id plist = nil;
    if (nil == data) {
        if (outError) *outError = [NSError errorWithDomain:@"BDSKErrorDomain" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:path, NSFilePathErrorKey, error, NSUnderlyingErrorKey, nil]];
    } else {
        // we compress plist types, but check just in case...
        NSData *decompressedData = data;
        if ([decompressedData mightBeCompressed]) {
            @try {
                decompressedData = [data decompressedBzip2Data];
            }
            @catch(id exception) {
                NSLog(@"property list for extended attribute %@ at path %@ couldn't be decompressed", attr, path);
                decompressedData = data;
            }
        }
        NSString *errorString;
        plist = [NSPropertyListSerialization propertyListFromData:decompressedData 
                                                 mutabilityOption:NSPropertyListImmutable 
                                                           format:NULL 
                                                 errorDescription:&errorString];
        if (nil == plist) {
            if (outError) *outError = [NSError errorWithDomain:@"BDSKErrorDomain" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:path, NSFilePathErrorKey, errorString, NSLocalizedDescriptionKey, nil]];
            [errorString release];
        }
    }
    return plist;
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
        noFollow = [[options objectForKey:@"NoFollowLinks"] boolValue];
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
        if(error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:[NSDictionary dictionaryWithObjectsAndKeys:path, NSFilePathErrorKey, errMsg, NSLocalizedDescriptionKey, nil]];
        return NO;
    } else 
        return YES;
}

- (BOOL)setExtendedAttributeNamed:(NSString *)attr toPropertyListValue:(id)plist atPath:(NSString *)path options:(NSDictionary *)options error:(NSError **)error;
{
    NSString *errorString;
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:plist 
                                                              format:NSPropertyListBinaryFormat_v1_0 
                                                    errorDescription:&errorString];
    BOOL success;
    if (nil == data) {
        if (error) *error = [NSError errorWithDomain:@"BDSKErrorDomain" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:path, NSFilePathErrorKey, errorString, NSLocalizedDescriptionKey, nil]];
        [errorString release];
        success = NO;
    } else {
        // try to compress; this saves significant space under some conditions and avoids the size error
        NSData *compressedData;
        @try {
            compressedData = [data compressedBzip2Data];
        }
        @catch(id exception) {
            compressedData = data;
            NSLog(@"property list could not be compressed for attribute %@ at path %@", attr, path);
        }
        success = [self setExtendedAttributeNamed:attr toValue:compressedData atPath:path options:options error:error];
    }
    return success;
}

- (BOOL)removeExtendedAttribute:(NSString *)attr atPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;
{
    NSParameterAssert(path != nil);
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
        if(error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:[NSDictionary dictionaryWithObjectsAndKeys:path, NSFilePathErrorKey, errMsg, NSLocalizedDescriptionKey, nil]];
        return NO;
    } else 
        return YES;    
    
}

- (BOOL)removeAllExtendedAttributesAtPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;
{
    NSArray *allAttributes = [self extendedAttributeNamesAtPath:path traverseLink:follow error:error];
    if  (nil == allAttributes)
        return NO;
    
    NSEnumerator *e = [allAttributes objectEnumerator];
    NSString *attrName;
    while (attrName = [e nextObject]) {
        
        // return NO as soon as any single removal fails
        if ([self removeExtendedAttribute:attrName atPath:path traverseLink:follow error:error] == NO)
            return NO;
    }
    return YES;
}

// guaranteed to return non-nil
static NSString *xattrError(int err, const char *myPath)
{
    NSString *errMsg = nil;
    switch (err)
    {
        case ENOTSUP:
            errMsg = NSLocalizedString(@"File system does not support extended attributes or they are disabled.", @"Error description");
            break;
        case ERANGE:
            errMsg = NSLocalizedString(@"Buffer too small for attribute names.", @"Error description");
            break;
        case EPERM:
            errMsg = NSLocalizedString(@"This file system object does not support extended attributes.", @"Error description");
            break;
        case ENOTDIR:
            errMsg = NSLocalizedString(@"A component of the path is not a directory.", @"Error description");
            break;
        case ENAMETOOLONG:
            errMsg = NSLocalizedString(@"File name too long.", @"Error description");
            break;
        case EACCES:
            errMsg = NSLocalizedString(@"Search permission denied for this path.", @"Error description");
            break;
        case ELOOP:
            errMsg = NSLocalizedString(@"Too many symlinks encountered resolving path.", @"Error description");
            break;
        case EIO:
            errMsg = NSLocalizedString(@"I/O error occurred.", @"Error description");
            break;
        case EINVAL:
            errMsg = NSLocalizedString(@"Options not recognized.", @"Error description");
            break;
        case EEXIST:
            errMsg = NSLocalizedString(@"Options contained XATTR_CREATE but the named attribute exists.", @"Error description");
            break;
        case ENOATTR:
            errMsg = NSLocalizedString(@"The named attribute does not exist.", @"Error description");
            break;
        case EROFS:
            errMsg = NSLocalizedString(@"Read-only file system.  Unable to change attributes.", @"Error description");
            break;
        case EFAULT:
            errMsg = NSLocalizedString(@"Path or name points to an invalid address.", @"Error description");
            break;
        case E2BIG:
            errMsg = NSLocalizedString(@"The data size of the extended attribute is too large.", @"Error description");
            break;
        case ENOSPC:
            errMsg = NSLocalizedString(@"No space left on file system.", @"Error description");
            break;
        default:
            errMsg = NSLocalizedString(@"Unknown error occurred.", @"Error description");
            break;
    }
    return errMsg;
}
    
@end


@implementation NSFileManager (BDSKSkimNotesExtensions)

#define MAX_XATTR_LENGTH 2048
#define UNIQUE_VALUE [[NSProcessInfo processInfo] globallyUniqueString]
#define UNIQUE_KEY @"net_sourceforge_skim_unique_key"
#define WRAPPER_KEY @"net_sourceforge_skim_has_wrapper"
#define FRAGMENTS_KEY @"net_sourceforge_skim_number_of_fragments"
#define NOTES_NAME @"net_sourceforge_skim_notes"

- (BOOL)setSkimNotes:(NSArray *)notes inExtendedAttributesAtPath:(NSString *)path error:(NSError **)outError {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:notes];
    NSError *error = nil;
    BOOL success;
    
    
    if ([data length] > MAX_XATTR_LENGTH) {
                    
        // compress to save space, and so we don't identify this as a plist when reading it (in case it really is plist data)
        data = [data compressedBzip2Data];
        
        // this will be a unique identifier for the set of keys we're about to write (appending a counter to the UUID)
        NSString *uniqueValue = UNIQUE_VALUE;
        unsigned numberOfFragments = ([data length] / MAX_XATTR_LENGTH) + ([data length] % MAX_XATTR_LENGTH ? 1 : 0);
        NSDictionary *wrapper = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], WRAPPER_KEY, uniqueValue, UNIQUE_KEY, [NSNumber numberWithUnsignedInt:numberOfFragments], FRAGMENTS_KEY, nil];
        NSData *wrapperData = [NSPropertyListSerialization dataFromPropertyList:wrapper format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
        NSParameterAssert([wrapperData length] < MAX_XATTR_LENGTH && [wrapperData length] > 0);
        
        success = [self setExtendedAttributeNamed:NOTES_NAME toValue:wrapperData atPath:path options:0 error:&error];
        
        // now split the original data value into multiple segments
        NSString *name;
        unsigned j;
        const char *valuePtr = [data bytes];
        
        for (j = 0; success && j < numberOfFragments; j++) {
            name = [[NSString alloc] initWithFormat:@"%@-%i", uniqueValue, j];
            
            char *subdataPtr = (char *)&valuePtr[j * MAX_XATTR_LENGTH];
            unsigned subdataLen = j == numberOfFragments - 1 ? ([data length] - j * MAX_XATTR_LENGTH) : MAX_XATTR_LENGTH;
            NSData *subdata = [[NSData alloc] initWithBytes:subdataPtr length:subdataLen];
            
            success = [self setExtendedAttributeNamed:name toValue:subdata atPath:path options:0 error:&error];
            [subdata release];
            [name release];
        }
        
    } else {
        success = [self setExtendedAttributeNamed:NOTES_NAME toValue:data atPath:path options:0 error:&error];
    }
    
    if (success == NO && outError)
        *outError = error;
    
    return success;
}

- (NSArray *)skimNotesFromExtendedAttributesAtPath:(NSString *)path error:(NSError **)outError {
    NSArray *notes = nil;
    NSData *data = [self extendedAttributeNamed:NOTES_NAME atPath:path traverseLink:YES error:outError];
    NSPropertyListFormat format;
    NSString *errorString;
    
    // the plist parser logs annoying messages when failing to parse non-plist data, so sniff the header (this is correct for the binary plist that we use for split data)
    static NSData *plistHeaderData = nil;
    if (nil == plistHeaderData) {
        char *h = "bplist00";
        plistHeaderData = [[NSData alloc] initWithBytes:h length:strlen(h)];
    }

    id plist = nil;
    
    if ([data length] >= [plistHeaderData length] && [plistHeaderData isEqual:[data subdataWithRange:NSMakeRange(0, [plistHeaderData length])]])
        plist = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&errorString];
    
    // even if it's a plist, it may not be a dictionary or have the key we're looking for
    if (plist && [plist respondsToSelector:@selector(objectForKey:)] && [[plist objectForKey:WRAPPER_KEY] boolValue]) {
        
        NSString *uniqueValue = [plist objectForKey:UNIQUE_KEY];
        unsigned int i, numberOfFragments = [[plist objectForKey:FRAGMENTS_KEY] unsignedIntValue];
        NSString *name;

        NSMutableData *buffer = [NSMutableData data];
        NSData *subdata;
        BOOL success = (nil != uniqueValue && numberOfFragments > 0);
        
        // reassemble the original data object
        for (i = 0; success && i < numberOfFragments; i++) {
            name = [NSString stringWithFormat:@"%@-%i", uniqueValue, i];
            subdata = [self extendedAttributeNamed:name atPath:path traverseLink:YES error:outError];
            if (nil == subdata)
                success = NO;
            else
                [buffer appendData:subdata];
        }
        
        data = success ? [buffer decompressedBzip2Data] : nil;
    }
    
    if (data)
        notes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    return notes;
}

@end
