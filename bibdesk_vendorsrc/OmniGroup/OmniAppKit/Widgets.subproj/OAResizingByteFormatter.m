// Copyright 2000-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OAResizingByteFormatter.h"

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <OmniFoundation/OmniFoundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAResizingByteFormatter.m 68913 2005-10-03 19:36:19Z kc $")

@implementation OAResizingByteFormatter

static NSString *thousandsFormats[6];

+ (void)initialize;
{
    NSBundle *thisBundle;
    
    OBINITIALIZE;
    
    thisBundle = [OAResizingByteFormatter bundle];
    
    thousandsFormats[0] = NSLocalizedStringFromTableInBundle(@"#,##0", @"OmniAppKit", thisBundle, "resizing bytes formatter bytes format");
    thousandsFormats[1] = NSLocalizedStringFromTableInBundle(@"#,##0.0 kB", @"OmniAppKit", thisBundle, "resizing bytes formatter kilobytes format");
    thousandsFormats[2] = NSLocalizedStringFromTableInBundle(@"#,##0.0 MB", @"OmniAppKit", thisBundle, "resizing bytes formatter megabytes format");
    thousandsFormats[3] = NSLocalizedStringFromTableInBundle(@"#,##0.0 GB", @"OmniAppKit", thisBundle, "resizing bytes formatter gigabytes format");
    thousandsFormats[4] = NSLocalizedStringFromTableInBundle(@"#,##0.0 TB", @"OmniAppKit", thisBundle, "resizing bytes formatter terabytes format");
    thousandsFormats[5] = NSLocalizedStringFromTableInBundle(@"#,##0.0 PB", @"OmniAppKit", thisBundle, "resizing bytes formatter petabytes format");
}

- initWithNonretainedTableColumn:(NSTableColumn *)tableColumn;
{
    if (![super init])
        return nil;
        
    nonretainedTableColumn = tableColumn;
    return self;
}

// NSFormatter

- (NSString *)stringForObjectValue:(id)obj;
{
    unsigned int thousandsIndex;
    NSString *bytesString = @"";
    double scaledBytes;
    NSCell *dataCell = [nonretainedTableColumn dataCell];
    
    scaledBytes = [obj doubleValue];
    for (thousandsIndex = 0; thousandsIndex < sizeof(thousandsFormats); thousandsIndex++) {
        [self setFormat:thousandsFormats[thousandsIndex]];
        
        if (thousandsIndex == 0) {
            // Sadly, you can't include an 'e' in a NSNumberFormatter's format string
            bytesString = [[super stringForObjectValue:obj] stringByAppendingString:NSLocalizedStringFromTableInBundle(@" bytes", @"OmniAppKit", [OAResizingByteFormatter bundle], "resizing byte formatter - this word is separate because of a bug in NSNumberFormatter")];
        } else {
            bytesString = [super stringForObjectValue:[NSNumber numberWithDouble:scaledBytes]];
        }
        
        if (scaledBytes < (1024 / 10)) // if our new value < (1024 / 10), we aren't going to get any skinnier
            return bytesString;
        
        if ([[dataCell font] widthOfString:bytesString] + 5.0 <= NSWidth([dataCell titleRectForBounds:NSMakeRect(0.0, 0.0, [nonretainedTableColumn width], 30.0)]))
            return bytesString;
            
        scaledBytes /= 1024.0;
    }
    
    return bytesString;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)obj withDefaultAttributes:(NSDictionary *)attrs;
{
    return [[[NSAttributedString alloc] initWithString:[self stringForObjectValue:obj] attributes:attrs] autorelease];
}


- (NSString *)editingStringForObjectValue:(id)obj;
{
    return [obj stringValue];
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error;
{
    *obj = [NSNumber numberWithInt:[string intValue]];
    return YES;
}

//- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error;


@end
