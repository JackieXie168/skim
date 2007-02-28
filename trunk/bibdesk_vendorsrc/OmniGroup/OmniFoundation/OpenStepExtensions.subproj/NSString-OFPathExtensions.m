// Copyright 1999-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSString-OFPathExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/NSString-OFExtensions.h>
#import <OmniFoundation/OFCharacterSet.h>


RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSString-OFPathExtensions.m 79079 2006-09-07 22:35:32Z kc $")

@implementation NSString (OFPathExtensions)

/*" Reformats a path as 'lastComponent emdash stringByByRemovingLastPathComponent' "*/
- (NSString *) prettyPathString;
{
    NSString *last, *prefix;
    
    last = [self lastPathComponent];
    prefix = [self stringByDeletingLastPathComponent];
    
    if (![last length] || ![prefix length])
        // was a single component?
        return self;
    
    return [NSString stringWithFormat: @"%@ %@ %@", last, [NSString emdashString], prefix];
}

+ (NSString *)pathSeparator;
{
    return [NSOpenStepRootDirectory() substringToIndex:1];
}

NSArray *OFCommonRootPathComponents(NSString *filename, NSString *otherFilename, NSArray **componentsLeft, NSArray **componentsRight)
{
    int minLength, i;
    NSArray *filenameArray, *otherArray;
    NSMutableArray *resultArray;

    filenameArray = [filename pathComponents];
    otherArray = [[otherFilename stringByStandardizingPath] pathComponents];
    minLength = MIN([filenameArray count], [otherArray count]);
    resultArray = [NSMutableArray arrayWithCapacity:minLength];

    for (i = 0; i < minLength; i++) {
        if ([[filenameArray objectAtIndex:i] isEqualToString:[otherArray objectAtIndex:i]])
            [resultArray addObject:[filenameArray objectAtIndex:i]];
        else
            break;
    }
        
    if ([resultArray count] == 0)
        return nil;

    if (componentsLeft)
        *componentsLeft = [filenameArray subarrayWithRange:(NSRange){i, [filenameArray count] - i}];
    if (componentsRight)
        *componentsRight = [otherArray subarrayWithRange:(NSRange){i, [otherArray count] - i}];
    
    return resultArray;
}

+ (NSString *)commonRootPathOfFilename:(NSString *)filename andFilename:(NSString *)otherFilename;
{
    NSArray *components = OFCommonRootPathComponents(filename, otherFilename, NULL, NULL);
    return components? [NSString pathWithComponents:components] : nil;
}

- (NSString *)relativePathToFilename:(NSString *)otherFilename;
{
    NSArray *commonRoot, *myUniquePart, *otherUniquePart;
    int numberOfStepsUp, i;

    otherFilename = [otherFilename stringByStandardizingPath];
    commonRoot = OFCommonRootPathComponents([self stringByStandardizingPath], otherFilename, &myUniquePart, &otherUniquePart);
    if (commonRoot == nil || [commonRoot count] == 0)
        return otherFilename;
    
    numberOfStepsUp = [myUniquePart count];
    if (numberOfStepsUp == 0)
        return [NSString pathWithComponents:otherUniquePart];
    if ([[myUniquePart lastObject] isEqualToString:@""])
        numberOfStepsUp --;
    if (numberOfStepsUp == 0)
        return [NSString pathWithComponents:otherUniquePart];
    
    NSMutableArray *stepsUpArray = [[otherUniquePart mutableCopy] autorelease];
    for (i = 0; i < numberOfStepsUp; i++) {
        NSString *steppingUpPast = [myUniquePart objectAtIndex:i];
        if ([steppingUpPast isEqualToString:@".."]) {
            if ([[stepsUpArray objectAtIndex:0] isEqualToString:@".."])
                [stepsUpArray removeObjectAtIndex:0];
            else {
                // Gack! Just give up.
                return nil;
            }
        } else
            [stepsUpArray insertObject:@".." atIndex:0];
    }

    return [[NSString pathWithComponents:stepsUpArray] stringByStandardizingPath];
}

@end
