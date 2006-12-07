// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/FileManagement.subproj/OFCacheFile.h 68913 2005-10-03 19:36:19Z kc $

#import <Foundation/NSObject.h>
#import <Foundation/NSDate.h>
#import <OmniFoundation/OFObject.h>

@class NSData, NSString;

@interface OFCacheFile : OFObject
{
    NSString                   *filename;
    NSData                     *contentData;

    struct {
        unsigned int contentDataIsValid: 1;
        unsigned int contentDataIsDirty: 1;
    } flags;
}

// API
+ (OFCacheFile *)cacheFileNamed:(NSString *)aName;
+ (OFCacheFile *)cacheFileNamed:(NSString *)aName inDirectory:(NSString *)cacheFileDirectory;

+ (NSString *)userCacheDirectory;
+ (NSString *)applicationCacheDirectory;

- (NSString *)filename;

- (NSData *)contentData;
- (void)setContentData:(NSData *)newData;

- (id)propertyList;
- (void)setPropertyList:(id)newPlist;

// You must call this method in order to write any changes back to disk. 
// If a failure occurs, the OFCacheFile remains "dirty". Currently there's no way to check whether it's dirty, but if you want one, you know how to add it.
- (void)writeIfNecessary;

// TODO: Allow writes to occur automatically when the cache is modified.
// - (void)setWritesAfterDelay:(NSTimeInterval)autoWriteDelay;

/*
 TODO: Allow to configure contention mechanisms:
    no locking (the current behavior)
    atomic writes / last-change-wins
    lockfiles, etc.
*/

/* TODO: Allow to set the attributes of the file on disk (e.g. permissions) */

@end
