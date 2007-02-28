// Copyright 2002-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSFileManager-OAExtensions.h"

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import "OAOSAScript.h"
#import "IconFamily.h"
#import "NSImage-OAExtensions.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSFileManager-OAExtensions.m 77583 2006-07-18 23:32:27Z wiml $")

@interface NSAppleEventDescriptor (JaguarAPI)
+ (NSAppleEventDescriptor *)descriptorWithString:(NSString *)string;
+ (NSAppleEventDescriptor *)descriptorWithDescriptorType:(DescType)descriptorType bytes:(const void *)bytes length:(unsigned int)byteCount;
- (const AEDesc *)aeDesc;
@end

@implementation NSFileManager (OAExtensions)

- (void)setIconImage:(NSImage *)newImage forPath:(NSString *)path;
{
    IconFamily *iconFamily;
    BOOL isDirectory;

    if (![self fileExistsAtPath:path isDirectory:&isDirectory])
        return;
        
    if (newImage == nil) {
        if (!isDirectory) // IconFamily doesn't remove icons from directories
            [IconFamily removeCustomIconFromFile:path];
        return;
    }
    iconFamily = [[IconFamily alloc] initWithRepresentationsOfImage:newImage];

    if (isDirectory)
        [iconFamily setAsCustomIconForDirectory:path];
    else
        [iconFamily setAsCustomIconForFile:path];
    
    [iconFamily release];

    [[NSWorkspace sharedWorkspace] noteFileSystemChanged:path];
}

static BOOL fillAEDescFromPath(AEDesc *fileRefDesc, NSString *path)
{
    FSRef fileRef;
    OSErr err;

    bzero(&fileRef, sizeof(fileRef));
    err = FSPathMakeRef((UInt8 *)[path fileSystemRepresentation], &fileRef, NULL);
    if (err == fnfErr || err == dirNFErr || err == notAFileErr) {
        return NO;
    } else if (err != noErr) {
        [NSException raise:NSInvalidArgumentException format:@"Unable to convert path to an FSRef (%d): %@", err, path];
    }

    AEInitializeDesc(fileRefDesc);
    err = AECoercePtr(typeFSRef, &fileRef, sizeof(fileRef), typeAlias, fileRefDesc);
    if (err != noErr) {
        [NSException raise:NSInternalInconsistencyException format:@"Unable to coerce FSRef to Alias: %d", err];
    }
    
    return YES;
}

#if 0
static void fillAEDescFromURL(AEDesc *fileRefDesc, NSURL *url)
{
    if ([url isFileURL]) {
        if (fillAEDescFromPath(fileRefDesc, [url path]))
            return;
    }
    
    /* See http://developer.apple.com/technotes/tn/tn2022.html */
    /* Nobody seems to actually accept typeFileURL, but maybe they will in the future */
    
    CFDataRef urlBytes = CFURLCreateData(kCFAllocatorDefault, (CFURLRef)url, kCFStringEncodingUTF8, true);
    if (urlBytes == NULL) {
        [NSException raise:NSInternalInconsistencyException format:@"Unable to extract bytes of URL (%@)", url];
    }
        
    OSErr err;
    
    err = AECreateDesc(typeFileURL, CFDataGetBytePtr(urlBytes), CFDataGetLength(urlBytes), fileRefDesc);
    CFRelease(urlBytes);
    
    if (err != noErr) {
        [NSException raise:NSGenericException format:@"Unable to create AEDesc in fillAEDescFromURL()"];
    }
}
#endif

/* function doSetFileComment():

 Does the actual work of consing up an AppleEvent to set a file comment. If an error occurs, it raises an exception. It does not request a response from the finder, or even check whether the event was successfully received.
 
 For details see:
 
 http://developer.apple.com/technotes/tn/tn2045.html
 http://developer.apple.com/samplecode/Sample_Code/Interapplication_Comm/MoreAppleEvents.htm

*/

static OSType finderSignatureBytes = 'MACS';

- (void)setComment:(NSString *)newComment forPath:(NSString *)path;
{
    NSAppleEventDescriptor *commentTextDesc;
    OSErr err;
    AEDesc fileDesc, builtEvent, replyEvent;
    const char *eventFormat =
        "'----': 'obj '{ "         // Direct object is the file comment we want to modify
        "  form: enum(prop), "     //  ... the comment is an object's property...
        "  seld: type(comt), "     //  ... selected by the 'comt' 4CC ...
        "  want: type(prop), "     //  ... which we want to interpret as a property (not as e.g. text).
        "  from: 'obj '{ "         // It's the property of an object...
        "      form: enum(indx), "
        "      want: type(file), " //  ... of type 'file' ...
        "      seld: @,"           //  ... selected by an alias ...
        "      from: null() "      //  ... according to the receiving application.
        "              }"
        "             }, "
        "data: @";                 // The data is what we want to set the direct object to.

    if (![[NSAppleEventDescriptor class] respondsToSelector:@selector(descriptorWithString:)] ||
        ![[NSAppleEventDescriptor class] instancesRespondToSelector:@selector(aeDesc)])
        return;
    commentTextDesc = [NSAppleEventDescriptor descriptorWithString:newComment];

    /* This may raise, so do it first */
    if (!fillAEDescFromPath(&fileDesc, path))
        return;  // fillAEDescFromPath() returns without raising if the file doesn't exist

    AEInitializeDesc(&builtEvent);
    AEInitializeDesc(&replyEvent);
    err = AEBuildAppleEvent(kAECoreSuite, kAESetData,
                            typeApplSignature, &finderSignatureBytes, sizeof(finderSignatureBytes),
                            kAutoGenerateReturnID, kAnyTransactionID,
                            &builtEvent, NULL,
                            eventFormat,
                            &fileDesc, [commentTextDesc aeDesc]);

    AEDisposeDesc(&fileDesc);

    if (err != noErr) {
        [NSException raise:NSInternalInconsistencyException format:@"Unable to create AppleEvent: AEBuildAppleEvent() returns %d", err];
    }
    
    err = AESendMessage(&builtEvent, &replyEvent,
                        kAENoReply, kAEDefaultTimeout);

    AEDisposeDesc(&builtEvent);
    AEDisposeDesc(&replyEvent);

    if (err != noErr) {
        NSLog(@"Unable to set comment for file %@ (AESendMessage() returns %d)", path, err);
    }
}

- (void)updateForFileAtPath:(NSString *)path;
{
    AEDesc fileDesc, builtEvent, replyEvent;
    OSErr err;
    const char *eventFormat =
        "'----': 'obj '{ "         // Direct object is the file we want to sync
        "      form: enum(indx), "
        "      want: type(file), " //  ... of type 'file' ...
        "      seld: @,"           //  ... selected by an alias ...
        "      from: null() "      //  ... according to the receiving application.
        "}";

    /* This may raise, so do it first */
    if (!fillAEDescFromPath(&fileDesc, path))
        return;  // fillAEDescFromPath() returns without raising if the file doesn't exist

    AEInitializeDesc(&builtEvent);
    AEInitializeDesc(&replyEvent);
    err = AEBuildAppleEvent(kAEFinderSuite, kAESync,
                            typeApplSignature, &finderSignatureBytes, sizeof(finderSignatureBytes),
                            kAutoGenerateReturnID, kAnyTransactionID,
                            &builtEvent, NULL,
                            eventFormat,
                            &fileDesc);

    AEDisposeDesc(&fileDesc);

    if (err != noErr) {
        [NSException raise:NSInternalInconsistencyException format:@"Unable to create AppleEvent: AEBuildAppleEvent() returns %d", err];
    }

    err = AESendMessage(&builtEvent, &replyEvent,
                        kAENoReply, kAEDefaultTimeout);

    AEDisposeDesc(&builtEvent);
    AEDisposeDesc(&replyEvent);

    if (err != noErr) {
        NSLog(@"AESend() --> %d", err);
    }
}

@end
