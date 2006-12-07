// Copyright 1999-2004 Omni Development, Inc.  All rights reserved.
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


RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSString-OFPathExtensions.m,v 1.12 2004/02/10 04:07:46 kc Exp $")

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

+ (NSString *)commonRootPathOfFilename:(NSString *)filename andFilename:(NSString *)otherFilename;
{
    int minLength, i;
    NSArray *filenameArray, *otherArray;
    NSMutableArray *resultArray;

    filenameArray = [filename pathComponents];
    otherArray = [[otherFilename stringByStandardizingPath] pathComponents];
    minLength = MIN([filenameArray count], [otherArray count]);
    resultArray = [NSMutableArray arrayWithCapacity:minLength];

    for (i = 0; i < minLength; i++)
        if ([[filenameArray objectAtIndex:i] isEqualToString:[otherArray objectAtIndex:i]])
            [resultArray addObject:[filenameArray objectAtIndex:i]];
        
    if ([resultArray count] == 0)
        return nil;

    return [NSString pathWithComponents:resultArray];
}

- (NSString *)relativePathToFilename:(NSString *)otherFilename;
{
    NSString *commonRoot, *myUniquePart, *otherUniquePart;
    int numberOfStepsUp, i;
    NSMutableString *stepsUpString;

    commonRoot = [[NSString commonRootPathOfFilename:self andFilename:otherFilename] stringByAppendingString:[NSString pathSeparator]];
    if (commonRoot == nil)
        return otherFilename;
    
    myUniquePart = [[self stringByStandardizingPath] stringByRemovingPrefix:commonRoot];
    otherUniquePart = [[otherFilename stringByStandardizingPath] stringByRemovingPrefix:commonRoot];

    numberOfStepsUp = [[myUniquePart pathComponents] count];
    if (![self hasSuffix:[NSString pathSeparator]])
        numberOfStepsUp--; // Assume we're not a directory unless we end in /. May result in incorrect paths, but we can't do much about it.

    stepsUpString = [NSMutableString stringWithCapacity:(numberOfStepsUp * 3)];
    for (i = 0; i < numberOfStepsUp; i++) {
        [stepsUpString appendString:@".."];
        [stepsUpString appendString:[NSString pathSeparator]];
    }

    return [[stepsUpString stringByAppendingString:otherUniquePart] stringByStandardizingPath];
}


@end
