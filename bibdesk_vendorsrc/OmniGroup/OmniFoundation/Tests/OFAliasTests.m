// Copyright 2004-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFAlias.h"

#import <SenTestingKit/SenTestingKit.h>
#import <OmniBase/rcsid.h>

#import "NSData-OFExtensions.h"
#import "NSFileManager-OFExtensions.h"

RCS_ID("$Header$")

@interface OFAliasTest : SenTestCase
{
}
@end

@implementation OFAliasTest

- (void)testAlias
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *path = [fileManager tempFilenameFromHashesTemplate:@"/tmp/OFAliasTest-######"];
    [[NSData data] writeToFile:path atomically:NO];
    
    OFAlias *originalAlias = [[OFAlias alloc] initWithPath:path];
    NSString *resolvedPath = [originalAlias path];
    
    shouldBeEqual([path stringByStandardizingPath], [resolvedPath stringByStandardizingPath]);
    
    NSData *aliasData = [originalAlias data];
    OFAlias *restoredAlias = [[OFAlias alloc] initWithData:aliasData];
    
    NSString *moveToPath = [fileManager tempFilenameFromHashesTemplate:@"/tmp/OFAliasTest-######"];
    [fileManager movePath:path toPath:moveToPath handler:nil];
    
    NSString *resolvedMovedPath = [restoredAlias path];
    
    shouldBeEqual([moveToPath stringByStandardizingPath], [resolvedMovedPath stringByStandardizingPath]);
    
    moveToPath = [fileManager tempFilenameFromHashesTemplate:@"/tmp/OFAliasTest-######"];
    [fileManager movePath:path toPath:moveToPath handler:nil];
    NSData *movedAliasData = [[NSData alloc] initWithBase64String:[[restoredAlias data] base64String]];
    OFAlias *movedAliasFromData = [[OFAlias alloc] initWithData:aliasData];
    should([movedAliasFromData path] != nil);
    
    [originalAlias release];
    [restoredAlias release];
    [movedAliasData release];
    [movedAliasFromData release];
}

@end
