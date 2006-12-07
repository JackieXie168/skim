// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/FileManagement.subproj/OFFile.h,v 1.12 2004/02/10 04:07:44 kc Exp $

#import <OmniFoundation/OFObject.h>

@class NSCalendarDate, NSNumber, NSLock;
@class OFDirectory;

extern NSLock *fileOpsLock;

@interface OFFile : OFObject
{
    OFDirectory *directory;
    NSString *name;
    NSString *path;
}

+ fileWithDirectory:(OFDirectory *)aDirectory name:(NSString *)aName;
+ fileWithPath:(NSString *)aPath;

- initWithDirectory:(OFDirectory *)aDirectory name:(NSString *)aName;
- initWithPath:(NSString *)aPath;

- (NSString *)name;
- (NSString *)path;

- (BOOL)isDirectory;
- (BOOL)isShortcut;
- (NSNumber *)size;
- (NSCalendarDate *)lastChanged;

@end

@interface OFMutableFile : OFFile
{
    struct {
        unsigned int isDirectory:1;
        unsigned int isShortcut:1;
    } flags;
    NSNumber *size;
    NSCalendarDate *lastChanged;
}

- (void)setIsDirectory:(BOOL)shouldBeDirectory;
- (void)setIsShortcut:(BOOL)shouldBeShortcut;
- (void)setSize:(NSNumber *)aSize;
- (void)setLastChanged:(NSCalendarDate *)aDate;
- (void)setPath:(NSString *)aPath;

@end
