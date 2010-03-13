//
//  SKLocalization.m
//  Skim
//
//  Created by Christiaan on 3/13/10.
/*
 This software is Copyright (c) 2010
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

#import "SKLocalization.h"

#define TITLE_KEY               @"title"
#define ALTERNATETITLE_KEY      @"alternateTitle"
#define STRINGVALUE_KEY         @"stringValue"
#define PLACEHOLDERSTRING_KEY   @"placeholderString"
#define LABEL_KEY               @"label"
#define TOOLTIP_KEY             @"toolTip"

static NSString *localizedStringFromTable(NSString *string, NSString *table) {
    if ([string length] == 0)
        return nil;
    // we may want to check for missing localized strings when DEBUG
    return [[NSBundle mainBundle] localizedStringForKey:string value:string table:table];
}

static void localizeStringForObjectFromTable(id object, NSString *key, NSString *table) {
    NSString *value = localizedStringFromTable([object valueForKey:key], table);
    if (value)
        [object setValue:value forKey:key];
}

@implementation NSObject (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {}

@end


@implementation NSArray (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    [self makeObjectsPerformSelector:_cmd withObject:table];
}

@end


@implementation NSCell (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    if ([self type] == NSTextCellType)
        localizeStringForObjectFromTable(self, STRINGVALUE_KEY, table);
}

@end


@implementation NSButtonCell (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    [super localizeStringsFromTable:table];
    if ([self imagePosition] != NSImageOnly) {
        localizeStringForObjectFromTable(self, TITLE_KEY, table);
        localizeStringForObjectFromTable(self, ALTERNATETITLE_KEY, table);
    }
}

@end


@implementation NSPopUpButtonCell (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    [super localizeStringsFromTable:table];
    [[self menu] localizeStringsFromTable:table];
}

@end


@implementation NSSegmentedCell (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    [super localizeStringsFromTable:table];
    NSUInteger i, iMax = [self segmentCount];
    for (i = 0; i < iMax; i++) {
        NSString *label = localizedStringFromTable([self labelForSegment:i], table);
        if (label)
            [self setLabel:label forSegment:i];
        [[self menuForSegment:i] localizeStringsFromTable:table];
    }
}

@end


@implementation NSTextFieldCell (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    [super localizeStringsFromTable:table];
    localizeStringForObjectFromTable(self, PLACEHOLDERSTRING_KEY, table);
}

@end


@implementation NSView (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    localizeStringForObjectFromTable(self, TOOLTIP_KEY, table);
    [[self subviews] localizeStringsFromTable:table];
}

@end


@implementation NSBox (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    [super localizeStringsFromTable:table];
    localizeStringForObjectFromTable(self, TITLE_KEY, table);
}

@end


@implementation NSControl (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    [super localizeStringsFromTable:table];
    [[self cell] localizeStringsFromTable:table];
}

@end


@implementation NSMatrix (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    [super localizeStringsFromTable:table];
    NSArray *cells = [self cells];
    NSString *toolTip;
    [cells localizeStringsFromTable:table];
    for (id cell in [self cells]) {
        if (toolTip = localizedStringFromTable([self toolTipForCell:cell], table))
            [self setToolTip:toolTip forCell:cell];
    }
}

@end


@implementation NSTabView (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    [super localizeStringsFromTable:table];
    [[self tabViewItems] localizeStringsFromTable:table];
}

@end


@implementation NSTabViewItem (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    localizeStringForObjectFromTable(self, LABEL_KEY, table);
    localizeStringForObjectFromTable(self, TOOLTIP_KEY, table);
    [[self view] localizeStringsFromTable:table];
}

@end


@implementation NSTableView (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    [super localizeStringsFromTable:table];
    [[self tableColumns] localizeStringsFromTable:table];
    [[self cornerView] localizeStringsFromTable:table];
}

@end


@implementation NSTableColumn (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    [[self dataCell] localizeStringsFromTable:table];
    [[self headerCell] localizeStringsFromTable:table];
}

@end


@implementation NSMenu (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    localizeStringForObjectFromTable(self, TITLE_KEY, table);
    [[self itemArray] localizeStringsFromTable:table];
}

@end


@implementation NSMenuItem (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    localizeStringForObjectFromTable(self, TITLE_KEY, table);
    [[self submenu] localizeStringsFromTable:table];
}

@end


@implementation NSWindow (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    localizeStringForObjectFromTable(self, TITLE_KEY, table);
    [[self contentView] localizeStringsFromTable:table];
}

@end
