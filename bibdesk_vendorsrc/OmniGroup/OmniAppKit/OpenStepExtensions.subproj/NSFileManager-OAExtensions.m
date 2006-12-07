// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "NSFileManager-OAExtensions.h"

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import "OAOSAScript.h"
#import "IconFamily.h"
#import "NSImage-OAExtensions.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSFileManager-OAExtensions.m,v 1.11 2003/03/24 23:06:54 neo Exp $")

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

/* function doSetFileComment():

 Does the actual work of consing up an AppleEvent to set a file comment. If an error occurs, it raises an exception. It does not request a response from the finder, or even check whether the event was successfully received.
 
 For details see:
 
 http://developer.apple.com/technotes/tn/tn2045.html
 http://developer.apple.com/samplecode/Sample_Code/Interapplication_Comm/MoreAppleEvents.htm

*/
static void doSetFileComment(FSRef *fileRef,
                             NSAppleEventDescriptor *finderApp,
                             NSString *newComment)
{
    const AEDesc *commentTextAEDesc;
    OSErr err;
    AEDesc fileRefDesc, builtEvent, replyEvent;
    NSData *finderAppDescData;
    const char *eventFormat =
        "'----': 'obj '{ "         // Direct object is the file comment we want to modify
        "  form: enum(prop), "     //  ... the comment is an object's property...
        "  seld: type(comt), "     //  ... selected by the 'comt' 4CC ...
        "  want: type(prop), "     //  ... which we want to interpret as a property (not as e.g. text).
        "  from: 'obj '{ "         // It's the property of an object...
        "      form: enum(indx), "
        "      want: type(file), " //  ... of type 'file' ...
        "      seld: @,"           //  ... selected by an FSSpec ...
        "      from: null() "      //  ... according to the receiving application.
        "              }"
        "             }, "
        "data: @";                 // The data is what we want to set the direct object to.

    if (![[NSAppleEventDescriptor class] respondsToSelector:@selector(descriptorWithString:)])
        return;

    commentTextAEDesc = [[NSAppleEventDescriptor descriptorWithString:newComment] aeDesc];
    finderAppDescData = [finderApp data];

    if (!commentTextAEDesc || !finderAppDescData)
        [NSException raise:NSInvalidArgumentException format:@"Null or invalid argument passed to doSetFileComment()"];

    AEInitializeDesc(&fileRefDesc);
    AEReplaceDescData (typeFSRef, fileRef, sizeof(*fileRef), &fileRefDesc);

    /* The Finder isn't very good at coercions, so we have to do this ourselves */
    err = AECoerceDesc(&fileRefDesc, typeFSS, &fileRefDesc);
    if (err != noErr) {
        AEDisposeDesc(&fileRefDesc);
        [NSException raise:NSInternalInconsistencyException format:@"Unable to coerce FSRef to FSSpec: %d", err];
    }

    AEInitializeDesc(&builtEvent);
    AEInitializeDesc(&replyEvent);
    err = AEBuildAppleEvent(kAECoreSuite, kAESetData,
                            [finderApp descriptorType], [finderAppDescData bytes], [finderAppDescData length],
                            kAutoGenerateReturnID, kAnyTransactionID,
                            &builtEvent, NULL,
                            eventFormat,
                            &fileRefDesc, commentTextAEDesc);

    AEDisposeDesc(&fileRefDesc);
    
    if (err != noErr) {
        [NSException raise:NSInternalInconsistencyException format:@"Unable to create AppleEvent: AEBuildAppleEvent() returns %d", err];
    }
    
    err = AESend(&builtEvent, &replyEvent,
                 kAENoReply, kAENormalPriority, kAEDefaultTimeout,
                 NULL, NULL);

    AEDisposeDesc(&builtEvent);
    AEDisposeDesc(&replyEvent);

    if (err != noErr) {
        NSLog(@"AESend() --> %d", err);
    }
}

- (void)setComment:(NSString *)aComment forPath:(NSString *)path;
{
    FSRef fileRef;
    OSErr err;
    NSAppleEventDescriptor *finderApplication;
    static OSType finderSignature = 'MACS';

    bzero(&fileRef, sizeof(fileRef));
    err = FSPathMakeRef([path fileSystemRepresentation], &fileRef, NULL);
    if (err != noErr) {
        [NSException raise:NSInvalidArgumentException format:@"Unable to convert path to an FSRef (%d): %@", err, path];
    }

    /* Prior to OS 10.2.x, this next line will raise a NSInvalidArgumentException, which the caller must be prepared to handle. */
    finderApplication = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature bytes:&finderSignature length:sizeof(finderSignature)];
    
    doSetFileComment(&fileRef, finderApplication, aComment);
}


@end
