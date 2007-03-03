#import <Foundation/Foundation.h>
#include <sys/xattr.h>
#import "bzlib.h"

@interface NSData (Bzip2)

- (NSData *) bzip2;
- (NSData *) bzip2WithCompressionSetting:(int)OneToNine;
- (NSData *) bunzip2;

@end

typedef UInt32 SNXattrFlags;
enum {
    kSNXattrDefault     = 0,       /* create or replace, follow symlinks, split data    */
    kSNXattrNoFollow    = 1L << 1, /* don't follow symlinks                             */
    kSNXattrCreateOnly  = 1L << 2, /* setting will fail if the attribute already exists */
    kSNXattrReplaceOnly = 1L << 3, /* setting will fail if the attribute does not exist */
    kSNXattrNoSplitData = 1L << 4  /* don't split data objects into segments            */
};

@interface NSFileManager (ExtendedAttributes)

- (NSData *)extendedAttributeNamed:(NSString *)attr atPath:(NSString *)path traverseLink:(BOOL)follow error:(int *)error;
- (BOOL)setExtendedAttributeNamed:(NSString *)attr toValue:(NSData *)value atPath:(NSString *)path options:(SNXattrFlags)options error:(int *)error;
- (BOOL)removeExtendedAttribute:(NSString *)attr atPath:(NSString *)path traverseLink:(BOOL)follow error:(int *)error;

@end


@implementation NSFileManager (ExtendedAttributes)

#define MAX_XATTR_LENGTH 2048
#define UNIQUE_VALUE [[NSProcessInfo processInfo] globallyUniqueString]
#define UNIQUE_KEY @"net_sourceforge_skim_unique_key"
#define WRAPPER_KEY @"net_sourceforge_skim_has_wrapper"
#define FRAGMENTS_KEY @"net_sourceforge_skim_number_of_fragments"

- (NSData *)extendedAttributeNamed:(NSString *)attr atPath:(NSString *)path traverseLink:(BOOL)follow error:(int *)error;
{
    const char *fsPath = [self fileSystemRepresentationWithPath:path];
    const char *attrName = [attr UTF8String];
    
    int xopts;
    
    if(follow)
        xopts = 0;
    else
        xopts = XATTR_NOFOLLOW;
    
    ssize_t bufSize;
    ssize_t status;
    status = getxattr(fsPath, attrName, NULL, 0, 0, xopts);
    
    if(status == -1){
        if (error) *error = errno;
        return nil;
    }
    
    bufSize = status;
    char *namebuf = (char *)NSZoneMalloc(NSDefaultMallocZone(), sizeof(char) * bufSize);
    NSAssert(namebuf != NULL, @"unable to allocate memory");
    status = getxattr(fsPath, attrName, namebuf, bufSize, 0, xopts);
    
    if(status == -1){
        if (error) *error = errno;
        NSZoneFree(NSDefaultMallocZone(), namebuf);
        return nil;
    }
    
    // let NSData worry about freeing the buffer
    NSData *attribute = [[NSData alloc] initWithBytesNoCopy:namebuf length:bufSize];
    
    NSPropertyListFormat format;
    NSString *errorString;
    
    // the plist parser logs annoying messages when failing to parse non-plist data, so sniff the header (this is correct for the binary plist that we use for split data)
    static NSData *plistHeaderData = nil;
    if (nil == plistHeaderData) {
        char *h = "bplist00";
        plistHeaderData = [[NSData alloc] initWithBytes:h length:strlen(h)];
    }

    id plist = nil;
    
    if ([attribute length] >= [plistHeaderData length] && [plistHeaderData isEqual:[attribute subdataWithRange:NSMakeRange(0, [plistHeaderData length])]])
        plist = [NSPropertyListSerialization propertyListFromData:attribute mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&errorString];
    
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
            subdata = [self extendedAttributeNamed:name atPath:path traverseLink:follow error:error];
            if (nil == subdata)
                success = NO;
            else
                [buffer appendData:subdata];
        }
        
        [attribute release];
        attribute = success ? [[buffer bunzip2] copy] : nil;
    }
    return [attribute autorelease];
}

- (BOOL)setExtendedAttributeNamed:(NSString *)attr toValue:(NSData *)value atPath:(NSString *)path options:(SNXattrFlags)options error:(int *)error;
{

    const char *fsPath = [self fileSystemRepresentationWithPath:path];
    const void *data = [value bytes];
    size_t dataSize = [value length];
    const char *attrName = [attr UTF8String];
        
    // options passed to xattr functions
    int xopts = 0;
    if(options & kSNXattrNoFollow)
        xopts = xopts | XATTR_NOFOLLOW;
    if(options & kSNXattrCreateOnly)
        xopts = xopts | XATTR_CREATE;
    if(options & kSNXattrReplaceOnly)
        xopts = xopts | XATTR_REPLACE;
    
    BOOL success;

    if ((options & kSNXattrNoSplitData) == 0 && [value length] > MAX_XATTR_LENGTH) {
                    
        // compress to save space, and so we don't identify this as a plist when reading it (in case it really is plist data)
        value = [value bzip2];
        
        // this will be a unique identifier for the set of keys we're about to write (appending a counter to the UUID)
        NSString *uniqueValue = UNIQUE_VALUE;
        unsigned numberOfFragments = ([value length] / MAX_XATTR_LENGTH) + ([value length] % MAX_XATTR_LENGTH ? 1 : 0);
        NSDictionary *wrapper = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], WRAPPER_KEY, uniqueValue, UNIQUE_KEY, [NSNumber numberWithUnsignedInt:numberOfFragments], FRAGMENTS_KEY, nil];
        NSData *wrapperData = [NSPropertyListSerialization dataFromPropertyList:wrapper format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
        NSParameterAssert([wrapperData length] < MAX_XATTR_LENGTH && [wrapperData length] > 0);
        
        // we don't want to split this dictionary (or compress it)
        if (setxattr(fsPath, attrName, [wrapperData bytes], [wrapperData length], 0, xopts))
            success = NO;
        else
            success = YES;
        
        // now split the original data value into multiple segments
        NSString *name;
        unsigned j;
        const char *valuePtr = [value bytes];
        
        for (j = 0; success && j < numberOfFragments; j++) {
            name = [[NSString alloc] initWithFormat:@"%@-%i", uniqueValue, j];
            
            char *subdataPtr = (char *)&valuePtr[j * MAX_XATTR_LENGTH];
            unsigned subdataLen = j == numberOfFragments - 1 ? ([value length] - j * MAX_XATTR_LENGTH) : MAX_XATTR_LENGTH;
            
            // could recurse here, but it's more efficient to use the variables we already have
            if (setxattr(fsPath, [name UTF8String], subdataPtr, subdataLen, 0, xopts)) {
                NSLog(@"full data length of note named %@ was %d, subdata length was %d (failed on pass %d)", name, [value length], subdataLen, j);
            }
            [name release];
        }
        
    } else {
        int status = setxattr(fsPath, attrName, data, dataSize, 0, xopts);
        if(status == -1){
        if (error) *error = errno;
            success = NO;
        } else {
            success = YES;
        }
    }
    return success;
}

- (BOOL)removeExtendedAttribute:(NSString *)attr atPath:(NSString *)path traverseLink:(BOOL)follow error:(int *)error;
{
    NSParameterAssert(path != nil);
    const char *fsPath = [self fileSystemRepresentationWithPath:path];
    const char *attrName = [attr UTF8String];
    
    int xopts;
    
    if(follow)
        xopts = 0;
    else
        xopts = XATTR_NOFOLLOW;
    
    ssize_t bufSize;
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
            
            // the plist parser logs annoying messages when failing to parse non-plist data, so sniff the header (this is correct for the binary plist that we use for split data)
            static NSData *plistHeaderData = nil;
            if (nil == plistHeaderData) {
                char *h = "bplist00";
                plistHeaderData = [[NSData alloc] initWithBytes:h length:strlen(h)];
            }

            id plist = nil;
            
            if ([attribute length] >= [plistHeaderData length] && [plistHeaderData isEqual:[attribute subdataWithRange:NSMakeRange(0, [plistHeaderData length])]])
                plist = [NSPropertyListSerialization propertyListFromData:attribute mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&errorString];
            
            // even if it's a plist, it may not be a dictionary or have the key we're looking for
            if (plist && [plist respondsToSelector:@selector(objectForKey:)] && [[plist objectForKey:WRAPPER_KEY] boolValue]) {
                
                NSString *uniqueValue = [plist objectForKey:UNIQUE_KEY];
                unsigned int i, numberOfFragments = [[plist objectForKey:FRAGMENTS_KEY] unsignedIntValue];
                NSString *name;
                
                // remove the sub attributes
                for (i = 0; i < numberOfFragments; i++) {
                    name = [NSString stringWithFormat:@"%@-%i", uniqueValue, i];
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
        if (error) *error = errno;
        return NO;
    } else 
        return YES;    
}

@end

// 
// implementation modified after http://www.cocoadev.com/index.pl?NSDataPlusBzip (removed exceptions)
//

@implementation NSData (Bzip2)

- (NSData *)bzip2 { return [self bzip2WithCompressionSetting:5]; }

- (NSData *)bzip2WithCompressionSetting:(int)compression
{
	int bzret, buffer_size = 1000000;
	bz_stream stream = { 0 };
	stream.next_in = (char *)[self bytes];
	stream.avail_in = [self length];
	
	NSMutableData *buffer = [[NSMutableData alloc] initWithLength:buffer_size];
	stream.next_out = [buffer mutableBytes];
	stream.avail_out = buffer_size;
	
	NSMutableData *compressed = [NSMutableData dataWithCapacity:[self length]];
	
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

- (NSData *)bunzip2
{
	int bzret;
	bz_stream stream = { 0 };
	stream.next_in = (char *)[self bytes];
	stream.avail_in = [self length];
	
	const int buffer_size = 10000;
	NSMutableData *buffer = [[NSMutableData alloc] initWithLength:buffer_size];
	stream.next_out = [buffer mutableBytes];
	stream.avail_out = buffer_size;
	
	NSMutableData *decompressed = [NSMutableData dataWithCapacity:[self length]];
	
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
    
    BZ2_bzCompressEnd(&stream);
    [buffer release];

	return decompressed;
}

@end


static char *usageStr = "Usage: skimnotes get|set file.pdf file.skim";
static char *versionStr = "SkimNotes command-line client, version 0.1.";

int main (int argc, const char * argv[]) {
	BOOL get = YES; 
    const char *pdfFilePath = 0;
    const char *notesFilePath = 0;
    
    if (argc == 2 &&  (strcmp("-h", argv[1]) == 0 || strcmp("-help", argv[1]) == 0)) {
        fprintf (stderr, "%s\n%s\n", usageStr, versionStr);
        exit (0);
    } else if (argc < 4 ) {
        fprintf (stderr, "%s\n%s\n", usageStr, versionStr);
        exit (1);
    } else if (strcmp("get", argv[1]) == 0) {
        get = YES;
    } else if (strcmp("set", argv[1]) == 0) {
        get = NO;
    } else {
        fprintf (stderr, "%s\n%s\n", usageStr, versionStr);
        exit (1);
    }
    
    pdfFilePath = argv[2];
    notesFilePath = argv[3];
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL success = NO;
    NSString *pdfPath = [NSString stringWithCString:pdfFilePath encoding:[NSString defaultCStringEncoding]];
    NSString *notesPath = [NSString stringWithCString:notesFilePath encoding:[NSString defaultCStringEncoding]];
    BOOL isDir = NO;
    int error = 0;
    
    if ([fm fileExistsAtPath:pdfPath isDirectory:&isDir] == NO || isDir) {
    } else if (get) {
        NSData *data = [fm extendedAttributeNamed:@"net_sourceforge_skim_notes" atPath:pdfPath traverseLink:YES error:&error];
        if (data)
            success = [data writeToFile:notesPath atomically:YES];
    } else if (notesPath && [fm fileExistsAtPath:notesPath isDirectory:&isDir] && isDir == NO) {
        NSData *data = [NSData dataWithContentsOfFile:notesPath];
        if (data)
            success = [fm setExtendedAttributeNamed:@"net_sourceforge_skim_notes" toValue:data atPath:pdfPath options:0 error:&error];
    }
    
    [pool release];
    
    return success ? 0 : 1;
}
