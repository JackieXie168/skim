//
//  Files_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 8/18/07.
/*
 This software is Copyright (c) 2007
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

#import "Files_SKExtensions.h"
#import <Carbon/Carbon.h>


BOOL SKFileIsInTrash(NSURL *fileURL) {
    NSCParameterAssert([fileURL isFileURL]);    
    FSRef parentRef;
    CFURLRef parentURL = CFURLCreateCopyDeletingLastPathComponent(CFGetAllocator((CFURLRef)fileURL), (CFURLRef)fileURL);
    [(id)parentURL autorelease];
    if (CFURLGetFSRef(parentURL, &parentRef)) {
        OSStatus err;
        FSRef fsRef;
        err = FSFindFolder(kUserDomain, kTrashFolderType, TRUE, &fsRef);
        if (noErr == err && noErr == FSCompareFSRefs(&fsRef, &parentRef))
            return YES;
        
        err = FSFindFolder(kOnAppropriateDisk, kSystemTrashFolderType, TRUE, &fsRef);
        if (noErr == err && noErr == FSCompareFSRefs(&fsRef, &parentRef))
            return YES;
    }
    return NO;
}

BOOL SKFileExistsAtPath(NSString *path) {
    FSRef fileRef;
    
    if (path && noErr == FSPathMakeRef((UInt8 *)[path fileSystemRepresentation], &fileRef, NULL))
        return YES;
    else
        return NO;
}

NSDate *SKFileModificationDateAtPath(NSString *path) {
    FSRef fileRef;
    FSCatalogInfo info;
    CFAbsoluteTime absoluteTime;
    
    if (CFURLGetFSRef((CFURLRef)[NSURL fileURLWithPath:path], &fileRef) &&
        noErr == FSGetCatalogInfo(&fileRef, kFSCatInfoContentMod, &info, NULL, NULL, NULL) &&
        noErr == UCConvertUTCDateTimeToCFAbsoluteTime(&info.contentModDate, &absoluteTime))
        return [NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)absoluteTime];
    else
        return nil;
}

NSString *SKUniqueDirectoryCreating(NSString *basePath, BOOL create) {
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *tmpDirName = [(NSString *)CFUUIDCreateString(NULL, uuid) autorelease];
    CFRelease(uuid);
    
    BOOL success = YES;
    
    if (create) {
        FSRef tmpRef;
        success = noErr == FSPathMakeRef((UInt8 *)[basePath fileSystemRepresentation], &tmpRef, NULL) &&
                  noErr == FSCreateDirectoryUnicode(&tmpRef, [tmpDirName length], (const UniChar *)[tmpDirName cStringUsingEncoding:NSUnicodeStringEncoding], kFSCatInfoNone, NULL, NULL, NULL, NULL);
    }
    
    return success ? [basePath stringByAppendingPathComponent:tmpDirName] : nil;
}

// These are taken from MoreFilesX

struct FSDeleteContainerGlobals
{
	OSErr							result;			/* result */
	ItemCount						actualObjects;	/* number of objects returned */
	FSCatalogInfo					catalogInfo;	/* FSCatalogInfo */
};
typedef struct FSDeleteContainerGlobals FSDeleteContainerGlobals;

static
void
FSDeleteContainerLevel(
	const FSRef *container,
	FSDeleteContainerGlobals *theGlobals)
{
	/* level locals */
	FSIterator					iterator;
	FSRef						itemToDelete;
	UInt16						nodeFlags;
	
	/* Open FSIterator for flat access and give delete optimization hint */
	theGlobals->result = FSOpenIterator(container, kFSIterateFlat + kFSIterateDelete, &iterator);
	require_noerr(theGlobals->result, FSOpenIterator);
	
	/* delete the contents of the directory */
	do
	{
		/* get 1 item to delete */
		theGlobals->result = FSGetCatalogInfoBulk(iterator, 1, &theGlobals->actualObjects,
								NULL, kFSCatInfoNodeFlags, &theGlobals->catalogInfo,
								&itemToDelete, NULL, NULL);
		if ( (noErr == theGlobals->result) && (1 == theGlobals->actualObjects) )
		{
			/* save node flags in local in case we have to recurse */
			nodeFlags = theGlobals->catalogInfo.nodeFlags;
			
			/* is it a file or directory? */
			if ( 0 != (nodeFlags & kFSNodeIsDirectoryMask) )
			{
				/* it's a directory -- delete its contents before attempting to delete it */
				FSDeleteContainerLevel(&itemToDelete, theGlobals);
			}
			/* are we still OK to delete? */
			if ( noErr == theGlobals->result )
			{
				/* is item locked? */
				if ( 0 != (nodeFlags & kFSNodeLockedMask) )
				{
					/* then attempt to unlock it (ignore result since FSDeleteObject will set it correctly) */
					theGlobals->catalogInfo.nodeFlags = nodeFlags & ~kFSNodeLockedMask;
					(void) FSSetCatalogInfo(&itemToDelete, kFSCatInfoNodeFlags, &theGlobals->catalogInfo);
				}
				/* delete the item */
				theGlobals->result = FSDeleteObject(&itemToDelete);
			}
		}
	} while ( noErr == theGlobals->result );
	
	/* we found the end of the items normally, so return noErr */
	if ( errFSNoMoreItems == theGlobals->result )
	{
		theGlobals->result = noErr;
	}
	
	/* close the FSIterator (closing an open iterator should never fail) */
	verify_noerr(FSCloseIterator(iterator));

FSOpenIterator:

	return;
}

OSErr
FSDeleteContainerContents(
	const FSRef *container)
{
	FSDeleteContainerGlobals	theGlobals;
	
	/* delete container's contents */
	FSDeleteContainerLevel(container, &theGlobals);
	
	return ( theGlobals.result );
}

OSErr
FSDeleteContainer(
	const FSRef *container)
{
	OSErr			result;
	FSCatalogInfo	catalogInfo;
	
	/* get nodeFlags for container */
	result = FSGetCatalogInfo(container, kFSCatInfoNodeFlags, &catalogInfo, NULL, NULL,NULL);
	require_noerr(result, FSGetCatalogInfo);
	
	/* make sure container is a directory */
	require_action(0 != (catalogInfo.nodeFlags & kFSNodeIsDirectoryMask), ContainerNotDirectory, result = dirNFErr);
	
	/* delete container's contents */
	result = FSDeleteContainerContents(container);
	require_noerr(result, FSDeleteContainerContents);
	
	/* is container locked? */
	if ( 0 != (catalogInfo.nodeFlags & kFSNodeLockedMask) )
	{
		/* then attempt to unlock container (ignore result since FSDeleteObject will set it correctly) */
		catalogInfo.nodeFlags &= ~kFSNodeLockedMask;
		(void) FSSetCatalogInfo(container, kFSCatInfoNodeFlags, &catalogInfo);
	}
	
	/* delete the container */
	result = FSDeleteObject(container);
	
FSDeleteContainerContents:
ContainerNotDirectory:
FSGetCatalogInfo:

	return ( result );
}

OSErr
FSPathDeleteContainer(
	const UInt8 *containerPath)
{
	OSErr			result;
	FSRef			container;
    Boolean         isDirectory;
    
	/* get FSRef for container */
    result = FSPathMakeRef(containerPath, &container, &isDirectory);
	require_noerr(result, FSPathMakeRef);
	
	/* make sure container is a directory */
	require_action(isDirectory == true, ContainerNotDirectory, result = dirNFErr);
    
	/* delete the container recursively  */
    result = FSDeleteContainer(&container);
    
ContainerNotDirectory:
FSPathMakeRef:

	return ( result );
}
