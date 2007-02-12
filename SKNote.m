//
//  SKNote.m


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/13/06.
//  Copyright 2006 __Michael O. McCrackenName__. All rights reserved.
//

#import "SKNote.h"


@implementation SKNote

// Legacy support for unarchiving old style notes

- (id)initWithCoder:(NSCoder *)coder{
    [[super init] release];
    NSPoint point = [coder decodePointForKey:@"SKNoteLocationInPageSpace"];
    NSRect bounds = NSMakeRect(point.x, point.y, 16.0, 16.0);
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:7];
    [dict setValue:@"Note" forKey:@"type"];
    [dict setValue:[coder decodeObjectForKey:@"SKNoteQuotation"] forKey:@"contents"];
    [dict setValue:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:0.7 alpha:1.0] forKey:@"color"];
    [dict setValue:NSStringFromRect(bounds) forKey:@"bounds"];
    [dict setValue:[NSNumber numberWithUnsignedInt:[coder decodeIntForKey:@"SKNotePageIndex"]] forKey:@"pageIndex"];
    [dict setValue:[coder decodeObjectForKey:@"SKNoteAttributedString"] forKey:@"text"];
    [dict setValue:[coder decodeObjectForKey:@"SKNoteImage"] forKey:@"image"];
    return dict;
}

@end
