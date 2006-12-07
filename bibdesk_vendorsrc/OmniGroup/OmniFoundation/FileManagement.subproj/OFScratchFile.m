// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFScratchFile.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/OFDataCursor.h>
#import <OmniFoundation/NSFileManager-OFExtensions.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/FileManagement.subproj/OFScratchFile.m 68913 2005-10-03 19:36:19Z kc $")

@implementation OFScratchFile

+ (OFScratchFile *)scratchFileNamed:(NSString *)aName;
{
    return [[[self alloc] initWithFilename:
        [[NSFileManager defaultManager]
	      scratchFilenameNamed:aName]]
	    autorelease];
}

+ (OFScratchFile *)scratchDirectoryNamed:(NSString *)aName;
{
    NSFileManager *fileManager;
    NSString *scratchFilename;

    fileManager = [NSFileManager defaultManager];
    scratchFilename = [fileManager scratchFilenameNamed:aName];
    [fileManager removeFileAtPath:scratchFilename handler:nil];
    [fileManager createDirectoryAtPath:scratchFilename attributes:nil];
    return [[[self alloc] initWithFilename:scratchFilename] autorelease];
}

- initWithFilename:(NSString *)aFilename;
{
    if (![super init])
	return nil;

    filename = [aFilename retain];
    retainedObjects = [[NSMutableArray alloc] init];

    return self;
}

- (void)dealloc;
{
    [[NSFileManager defaultManager] removeFileAtPath:filename handler:nil];
    [filename release];
    [contentData release];
    [contentString release];
    [retainedObjects release];
    [super dealloc];
}

- (NSString *)filename;
{
    return filename;
}

- (NSData *)contentData;
{
    if (contentData)
	return contentData;
    contentData = [[NSData alloc] initWithContentsOfMappedFile:filename];
    return contentData;
}

- (NSString *)contentString;
{
    if (contentString)
	return contentString;
    contentString = [[NSString alloc] initWithData:[self contentData] encoding:NSISOLatin1StringEncoding];
    return contentString;
}

- (OFDataCursor *)contentDataCursor;
{
    return [[[OFDataCursor alloc]
	     initWithData:[self contentData]]
	    autorelease];
}

- (void)retainObject:anObject;
{
    [retainedObjects addObject:anObject];
}

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [super debugDictionary];

    if (filename)
	[debugDictionary setObject:filename forKey:@"filename"];

    return debugDictionary;
}


@end
