//
//  SKNExtendedAttributeManager.m
//
//  Created by Adam R. Maxwell on 05/12/05.
//  Copyright 2005-2008 Adam R. Maxwell. All rights reserved.
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

#import "SKNExtendedAttributeManager.h"
#include <sys/xattr.h>
#import <bzlib.h>

#define MAX_XATTR_LENGTH        2048
#define UNIQUE_VALUE            [[NSProcessInfo processInfo] globallyUniqueString]
#define PREFIX                  @"net_sourceforge_skim-app"

static NSString *SKNErrorDomain = @"SKNErrorDomain";

@interface SKNExtendedAttributeManager (SKNPrivate)
// private methods to (un)compress data
- (NSData *)bzipData:(NSData *)data;
- (NSData *)bunzipData:(NSData *)data;
- (BOOL)isBzipData:(NSData *)data;
- (BOOL)isPlistData:(NSData *)data;
// private method to print error messages
- (NSError *)xattrError:(NSInteger)err forPath:(NSString *)path;
@end


@implementation SKNExtendedAttributeManager

static id sharedManager = nil;
static id sharedNoSplitManager = nil;

+ (id)sharedManager;
{
    if (sharedManager == nil)
        sharedManager = [[[self class] alloc] init];
    return sharedManager;
}

+ (id)sharedNoSplitManager;
{
    if (sharedNoSplitManager == nil)
        sharedNoSplitManager = [[[self class] alloc] initWithPrefix:nil];
    return sharedNoSplitManager;
}

- (id)init;
{
    self = [self initWithPrefix:PREFIX];
    if (sharedManager) {
        [self release];
        self = [sharedManager retain];
    } else {
        sharedManager = [self retain]; // we don't care about overretaining a shared object, but we care about overreleasing
    }
    return self;
}

- (id)initWithPrefix:(NSString *)prefix;
{
    if (self = [super init]) {
        if (prefix) {
            namePrefix = [[prefix stringByAppendingString:@"_"] retain];
            uniqueKey = [[prefix stringByAppendingString:@"_unique_key"] retain];
            wrapperKey = [[prefix stringByAppendingString:@"_has_wrapper"] retain];
            fragmentsKey = [[prefix stringByAppendingString:@"_number_of_fragments"] retain];
        } else if (sharedNoSplitManager) {
            [self release];
            self = [sharedNoSplitManager retain];
        } else {
            namePrefix = uniqueKey = wrapperKey = fragmentsKey = nil;
            sharedNoSplitManager = [self retain]; // we don't care about overretaining a shared object, but we care about overreleasing
        }
    }
    return self;
}

- (void)dealloc {
    [namePrefix release];
    [uniqueKey release];
    [wrapperKey release];
    [fragmentsKey release];
    [super dealloc];
}

- (NSArray *)extendedAttributeNamesAtPath:(NSString *)path traverseLink:(BOOL)follow includeFragments:(BOOL)fragments error:(NSError **)error;
{
    const char *fsPath = [path fileSystemRepresentation];
    
    int xopts;
    
    if(follow)
        xopts = 0;
    else
        xopts = XATTR_NOFOLLOW;    
    
    size_t bufSize;
    ssize_t status;
    
    // call with NULL as attr name to get the size of the returned buffer
    status = listxattr(fsPath, NULL, 0, xopts);
    
    if(status == -1){
        if(error) *error = [self xattrError:errno forPath:path];
        return nil;
    }
    
    NSZone *zone = NSDefaultMallocZone();
    bufSize = status;
    char *namebuf = (char *)NSZoneMalloc(zone, sizeof(char) * bufSize);
    NSAssert(namebuf != NULL, @"unable to allocate memory");
    status = listxattr(fsPath, namebuf, bufSize, xopts);
    
    if(status == -1){
        if(error) *error = [self xattrError:errno forPath:path];
        NSZoneFree(zone, namebuf);
        return nil;
    }
    
    NSUInteger idx, start = 0;

    NSString *attribute = nil;
    NSMutableArray *attrs = [NSMutableArray array];
    
    // the names are separated by NULL characters
    for(idx = 0; idx < bufSize; idx++){
        if(namebuf[idx] == '\0'){
            attribute = [[NSString alloc] initWithBytes:&namebuf[start] length:(idx - start) encoding:NSUTF8StringEncoding];
            // ignore fragments
            if(attribute && (fragments || namePrefix == nil || [attribute hasPrefix:namePrefix] == NO)) [attrs addObject:attribute];
            [attribute release];
            attribute = nil;
            start = idx + 1;
        }
    }
    
    NSZoneFree(zone, namebuf);
    return attrs;
}

- (NSArray *)extendedAttributeNamesAtPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;
{
    return [self extendedAttributeNamesAtPath:path traverseLink:follow includeFragments:NO error:error];
}

- (NSDictionary *)allExtendedAttributesAtPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;
{
    NSError *anError = nil;
    NSArray *attrNames = [self extendedAttributeNamesAtPath:path traverseLink:follow error:&anError];
    if(attrNames == nil){
        if(error) *error = anError;
        return nil;
    }
    
    NSEnumerator *e = [attrNames objectEnumerator];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:[attrNames count]];
    NSData *data = nil;
    NSString *attrName = nil;
    
    while(attrName = [e nextObject]){
        data = [self extendedAttributeNamed:attrName atPath:path traverseLink:follow error:&anError];
        if(data != nil){
            [attributes setObject:data forKey:attrName];
        } else {
            if(error) *error = anError;
            return nil;
        }
    }
    return attributes;
}

- (NSData *)extendedAttributeNamed:(NSString *)attr atPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;
{
    const char *fsPath = [path fileSystemRepresentation];
    const char *attrName = [attr UTF8String];
    
    int xopts;
    
    if(follow)
        xopts = 0;
    else
        xopts = XATTR_NOFOLLOW;
    
    size_t bufSize;
    ssize_t status;
    status = getxattr(fsPath, attrName, NULL, 0, 0, xopts);
    
    if(status == -1){
        if(error) *error = [self xattrError:errno forPath:path];
        return nil;
    }
    
    bufSize = status;
    char *namebuf = (char *)NSZoneMalloc(NSDefaultMallocZone(), sizeof(char) * bufSize);
    NSAssert(namebuf != NULL, @"unable to allocate memory");
    status = getxattr(fsPath, attrName, namebuf, bufSize, 0, xopts);
    
    if(status == -1){
        if(error) *error = [self xattrError:errno forPath:path];
        NSZoneFree(NSDefaultMallocZone(), namebuf);
        return nil;
    }
    
    // let NSData worry about freeing the buffer
    NSData *attribute = [[NSData alloc] initWithBytesNoCopy:namebuf length:bufSize];
    
    NSPropertyListFormat format;
    NSString *errorString;
    id plist = nil;
    
    if (namePrefix && [self isPlistData:attribute])
        plist = [NSPropertyListSerialization propertyListFromData:attribute mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&errorString];
    
    // even if it's a plist, it may not be a dictionary or have the key we're looking for
    if (plist && [plist respondsToSelector:@selector(objectForKey:)] && [[plist objectForKey:wrapperKey] boolValue]) {
        
        NSString *uniqueValue = [plist objectForKey:uniqueKey];
        NSUInteger i, numberOfFragments = [[plist objectForKey:fragmentsKey] unsignedIntValue];
        NSString *name;

        NSMutableData *buffer = [NSMutableData data];
        NSData *subdata;
        BOOL success = (nil != uniqueValue && numberOfFragments > 0);
        
        if (success == NO)
            NSLog(@"failed to read unique key %@ for %u fragments from property list.", uniqueKey, numberOfFragments);
        
        // reassemble the original data object
        for (i = 0; success && i < numberOfFragments; i++) {
            NSError *tmpError = nil;
            name = [NSString stringWithFormat:@"%@-%u", uniqueValue, i];
            subdata = [self extendedAttributeNamed:name atPath:path traverseLink:follow error:&tmpError];
            if (nil == subdata) {
                NSLog(@"failed to find subattribute %@ of %u for attribute named %@. %@", name, numberOfFragments, attr, [tmpError localizedDescription]);
                success = NO;
            } else {
                [buffer appendData:subdata];
            }
        }
        
        [attribute release];
        attribute = success ? [[self bunzipData:buffer] retain] : nil;
        
        if (success == NO && NULL != error) *error = [NSError errorWithDomain:SKNErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:path, NSFilePathErrorKey, SKNLocalizedString(@"Failed to reassemble attribute value.", @"Error description"), NSLocalizedDescriptionKey, nil]];
    }
    return [attribute autorelease];
}

- (id)propertyListFromExtendedAttributeNamed:(NSString *)attr atPath:(NSString *)path traverseLink:(BOOL)traverse error:(NSError **)error;
{
    NSError *anError = nil;
    NSData *data = [self extendedAttributeNamed:attr atPath:path traverseLink:traverse error:&anError];
    id plist = nil;
    if (nil == data) {
        if (error) *error = anError;
    } else {
        // decompress the data if necessary, we may have compressed when setting
        if ([self isBzipData:data]) 
            data = [self bunzipData:data];
        
        NSString *errorString;
        plist = [NSPropertyListSerialization propertyListFromData:data 
                                                 mutabilityOption:NSPropertyListImmutable 
                                                           format:NULL 
                                                 errorDescription:&errorString];
        if (nil == plist) {
            if (error) *error = [NSError errorWithDomain:SKNErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:path, NSFilePathErrorKey, errorString, NSLocalizedDescriptionKey, nil]];
            [errorString release];
        }
    }
    return plist;
}

- (BOOL)setExtendedAttributeNamed:(NSString *)attr toValue:(NSData *)value atPath:(NSString *)path options:(SKNXattrFlags)options error:(NSError **)error;
{

    const char *fsPath = [path fileSystemRepresentation];
    const void *data = [value bytes];
    size_t dataSize = [value length];
    const char *attrName = [attr UTF8String];
        
    // options passed to xattr functions
    int xopts = 0;
    if(options & kSKNXattrNoFollow)
        xopts = xopts | XATTR_NOFOLLOW;
    if(options & kSKNXattrCreateOnly)
        xopts = xopts | XATTR_CREATE;
    if(options & kSKNXattrReplaceOnly)
        xopts = xopts | XATTR_REPLACE;
    
    BOOL success;

    if ((options & kSKNXattrNoSplitData) == 0 && namePrefix && [value length] > MAX_XATTR_LENGTH) {
                    
        // compress to save space, and so we don't identify this as a plist when reading it (in case it really is plist data)
        value = [self bzipData:value];
        
        // this will be a unique identifier for the set of keys we're about to write (appending a counter to the UUID)
        NSString *uniqueValue = [namePrefix stringByAppendingString:UNIQUE_VALUE];
        NSUInteger numberOfFragments = ([value length] / MAX_XATTR_LENGTH) + ([value length] % MAX_XATTR_LENGTH ? 1 : 0);
        NSDictionary *wrapper = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], wrapperKey, uniqueValue, uniqueKey, [NSNumber numberWithUnsignedInt:numberOfFragments], fragmentsKey, nil];
        NSData *wrapperData = [NSPropertyListSerialization dataFromPropertyList:wrapper format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
        NSParameterAssert([wrapperData length] < MAX_XATTR_LENGTH && [wrapperData length] > 0);
        
        // we don't want to split this dictionary (or compress it)
        if (setxattr(fsPath, attrName, [wrapperData bytes], [wrapperData length], 0, xopts))
            success = NO;
        else
            success = YES;
        
        // now split the original data value into multiple segments
        NSString *name;
        NSUInteger j;
        const char *valuePtr = [value bytes];
        
        for (j = 0; success && j < numberOfFragments; j++) {
            name = [[NSString alloc] initWithFormat:@"%@-%u", uniqueValue, j];
            
            char *subdataPtr = (char *)&valuePtr[j * MAX_XATTR_LENGTH];
            size_t subdataLen = j == numberOfFragments - 1 ? ([value length] - j * MAX_XATTR_LENGTH) : MAX_XATTR_LENGTH;
            
            // could recurse here, but it's more efficient to use the variables we already have
            if (setxattr(fsPath, [name UTF8String], subdataPtr, subdataLen, 0, xopts)) {
                NSLog(@"full data length of note named %@ was %d, subdata length was %d (failed on pass %d)", name, [value length], subdataLen, j);
            }
            [name release];
        }
        
    } else {
        int status = setxattr(fsPath, attrName, data, dataSize, 0, xopts);
        if(status == -1){
            if(error) *error = [self xattrError:errno forPath:path];
            success = NO;
        } else {
            success = YES;
        }
    }
    return success;
}

- (BOOL)setExtendedAttributeNamed:(NSString *)attr toPropertyListValue:(id)plist atPath:(NSString *)path options:(SKNXattrFlags)options error:(NSError **)error;
{
    NSString *errorString;
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:plist 
                                                              format:NSPropertyListBinaryFormat_v1_0 
                                                    errorDescription:&errorString];
    BOOL success;
    if (nil == data) {
        if (error) *error = [NSError errorWithDomain:SKNErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:path, NSFilePathErrorKey, errorString, NSLocalizedDescriptionKey, nil]];
        [errorString release];
        success = NO;
    } else {
        // if we don't split and the data is too long, compress the data using bzip to save space
        if (((options & kSKNXattrNoSplitData) != 0 || namePrefix == nil) && [data length] > MAX_XATTR_LENGTH)
            data = [self bzipData:data];
        
        success = [self setExtendedAttributeNamed:attr toValue:data atPath:path options:options error:error];
    }
    return success;
}

- (BOOL)removeExtendedAttribute:(NSString *)attr atPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;
{
    NSParameterAssert(path != nil);
    const char *fsPath = [path fileSystemRepresentation];
    const char *attrName = [attr UTF8String];
    
    int xopts;
    
    if(follow)
        xopts = 0;
    else
        xopts = XATTR_NOFOLLOW;
    
    size_t bufSize;
    ssize_t status;
    status = getxattr(fsPath, attrName, NULL, 0, 0, xopts);
    
    if(status != -1){
        bufSize = status;
        char *namebuf = (char *)NSZoneMalloc(NSDefaultMallocZone(), sizeof(char) * bufSize);
        NSAssert(namebuf != NULL, @"unable to allocate memory");
        status = getxattr(fsPath, attrName, namebuf, bufSize, 0, xopts);
        
        if(status != -1){
            
            // let NSData worry about freeing the buffer
            NSData *attribute = [[NSData alloc] initWithBytesNoCopy:namebuf length:bufSize];
            
            NSPropertyListFormat format;
            NSString *errorString;
            id plist = nil;
            
            if (namePrefix && [self isPlistData:attribute])
                plist = [NSPropertyListSerialization propertyListFromData:attribute mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&errorString];
            
            // even if it's a plist, it may not be a dictionary or have the key we're looking for
            if (plist && [plist respondsToSelector:@selector(objectForKey:)] && [[plist objectForKey:wrapperKey] boolValue]) {
                
                NSString *uniqueValue = [plist objectForKey:uniqueKey];
                NSUInteger i, numberOfFragments = [[plist objectForKey:fragmentsKey] unsignedIntValue];
                NSString *name;
                
                // remove the sub attributes
                for (i = 0; i < numberOfFragments; i++) {
                    name = [NSString stringWithFormat:@"%@-%u", uniqueValue, i];
                    const char *subAttrName = [name UTF8String];
                    status = removexattr(fsPath, subAttrName, xopts);
                    if (status == -1) {
                        NSLog(@"failed to remove subattribute %@ of attribute named %@", name, attr);
                    }
                }
            }
        }
    }
    
    status = removexattr(fsPath, attrName, xopts);
    
    if(status == -1){
        if(error) *error = [self xattrError:errno forPath:path];
        return NO;
    } else 
        return YES;    
}

- (BOOL)removeAllExtendedAttributesAtPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;
{
    NSArray *allAttributes = [self extendedAttributeNamesAtPath:path traverseLink:follow includeFragments:YES error:error];
    if  (nil == allAttributes)
        return NO;
    
    const char *fsPath;
    ssize_t status;
    int xopts;
    
    if(follow)
        xopts = 0;
    else
        xopts = XATTR_NOFOLLOW;
    
    NSEnumerator *e = [allAttributes objectEnumerator];
    NSString *attrName;
    while (attrName = [e nextObject]) {
        
        fsPath = [path fileSystemRepresentation];
        status = removexattr(fsPath, [attrName UTF8String], xopts);
        
        // return NO as soon as any single removal fails
        if (status == -1){
            if(error) *error = [self xattrError:errno forPath:path];
            return NO;
        }
    }
    return YES;
}

// guaranteed to return non-nil
- (NSError *)xattrError:(NSInteger)err forPath:(NSString *)path;
{
    NSString *errMsg = nil;
    switch (err)
    {
        case ENOTSUP:
            errMsg = SKNLocalizedString(@"File system does not support extended attributes or they are disabled.", @"Error description");
            break;
        case ERANGE:
            errMsg = SKNLocalizedString(@"Buffer too small for attribute names.", @"Error description");
            break;
        case EPERM:
            errMsg = SKNLocalizedString(@"This file system object does not support extended attributes.", @"Error description");
            break;
        case ENOTDIR:
            errMsg = SKNLocalizedString(@"A component of the path is not a directory.", @"Error description");
            break;
        case ENAMETOOLONG:
            errMsg = SKNLocalizedString(@"File name too long.", @"Error description");
            break;
        case EACCES:
            errMsg = SKNLocalizedString(@"Search permission denied for this path.", @"Error description");
            break;
        case ELOOP:
            errMsg = SKNLocalizedString(@"Too many symlinks encountered resolving path.", @"Error description");
            break;
        case EIO:
            errMsg = SKNLocalizedString(@"I/O error occurred.", @"Error description");
            break;
        case EINVAL:
            errMsg = SKNLocalizedString(@"Options not recognized.", @"Error description");
            break;
        case EEXIST:
            errMsg = SKNLocalizedString(@"Options contained XATTR_CREATE but the named attribute exists.", @"Error description");
            break;
        case ENOATTR:
            errMsg = SKNLocalizedString(@"The named attribute does not exist.", @"Error description");
            break;
        case EROFS:
            errMsg = SKNLocalizedString(@"Read-only file system.  Unable to change attributes.", @"Error description");
            break;
        case EFAULT:
            errMsg = SKNLocalizedString(@"Path or name points to an invalid address.", @"Error description");
            break;
        case E2BIG:
            errMsg = SKNLocalizedString(@"The data size of the extended attribute is too large.", @"Error description");
            break;
        case ENOSPC:
            errMsg = SKNLocalizedString(@"No space left on file system.", @"Error description");
            break;
        default:
            errMsg = SKNLocalizedString(@"Unknown error occurred.", @"Error description");
            break;
    }
    return [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:[NSDictionary dictionaryWithObjectsAndKeys:path, NSFilePathErrorKey, errMsg, NSLocalizedDescriptionKey, nil]];
}

// 
// implementation modified after http://www.cocoadev.com/index.pl?NSDataPlusBzip (removed exceptions)
//

- (NSData *)bzipData:(NSData *)data;
{
	NSInteger compression = 5;
    NSInteger bzret, buffer_size = 1000000;
	bz_stream stream = { 0 };
	stream.next_in = (char *)[data bytes];
	stream.avail_in = [data length];
	
	NSMutableData *buffer = [[NSMutableData alloc] initWithLength:buffer_size];
	stream.next_out = [buffer mutableBytes];
	stream.avail_out = buffer_size;
	
	NSMutableData *compressed = [NSMutableData dataWithCapacity:[data length]];
	
	BZ2_bzCompressInit(&stream, compression, 0, 0);
    BOOL hadError = NO;
    do {
        bzret = BZ2_bzCompress(&stream, (stream.avail_in) ? BZ_RUN : BZ_FINISH);
        if (bzret != BZ_RUN_OK && bzret != BZ_STREAM_END) {
            hadError = YES;
            compressed = nil;
        } else {        
            [compressed appendBytes:[buffer bytes] length:(buffer_size - stream.avail_out)];
            stream.next_out = [buffer mutableBytes];
            stream.avail_out = buffer_size;
        }
    } while(bzret != BZ_STREAM_END && NO == hadError);
    
    BZ2_bzCompressEnd(&stream);
	[buffer release];
    
	return compressed;
}

- (NSData *)bunzipData:(NSData *)data;
{
	NSInteger bzret;
	bz_stream stream = { 0 };
	stream.next_in = (char *)[data bytes];
	stream.avail_in = [data length];
	
	const NSInteger buffer_size = 10000;
	NSMutableData *buffer = [[NSMutableData alloc] initWithLength:buffer_size];
	stream.next_out = [buffer mutableBytes];
	stream.avail_out = buffer_size;
	
	NSMutableData *decompressed = [NSMutableData dataWithCapacity:[data length]];
	
	BZ2_bzDecompressInit(&stream, 0, NO);
    BOOL hadError = NO;
    do {
        bzret = BZ2_bzDecompress(&stream);
        if (bzret != BZ_OK && bzret != BZ_STREAM_END) {
            hadError = YES;
            decompressed = nil;
        } else {        
            [decompressed appendBytes:[buffer bytes] length:(buffer_size - stream.avail_out)];
            stream.next_out = [buffer mutableBytes];
            stream.avail_out = buffer_size;
        }
    } while(bzret != BZ_STREAM_END && NO == hadError);
    
    BZ2_bzDecompressEnd(&stream);
    [buffer release];

	return decompressed;
}

- (BOOL)isBzipData:(NSData *)data;
{
    static NSData *bzipHeaderData = nil;
    static NSUInteger bzipHeaderDataLength = 0;
    if (nil == bzipHeaderData) {
        char *h = "BZh";
        bzipHeaderData = [[NSData alloc] initWithBytes:h length:strlen(h)];
        bzipHeaderDataLength = [bzipHeaderData length];
    }

    return [data length] >= bzipHeaderDataLength && [bzipHeaderData isEqual:[data subdataWithRange:NSMakeRange(0, bzipHeaderDataLength)]];
}

- (BOOL)isPlistData:(NSData *)data;
{
    static NSData *plistHeaderData = nil;
    static NSUInteger plistHeaderDataLength = 0;
    if (nil == plistHeaderData) {
        char *h = "bplist00";
        plistHeaderData = [[NSData alloc] initWithBytes:h length:strlen(h)];
        plistHeaderDataLength = [plistHeaderData length];
    }

    return [data length] >= plistHeaderDataLength && [plistHeaderData isEqual:[data subdataWithRange:NSMakeRange(0, plistHeaderDataLength)]];
}

@end
