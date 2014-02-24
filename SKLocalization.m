//
//  SKLocalization.m
//  Skim
//
//  Created by Christiaan Hofman on 3/13/10.
/*
 This software is Copyright (c) 2010-2014
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

static NSString *localizedStringFromTable(NSString *string, NSString *table) {
    if ([string length] == 0)
        return nil;
    // we may want to check for missing localized strings when DEBUG
    return [[NSBundle mainBundle] localizedStringForKey:string value:@"" table:table];
}

#define LOCALIZE_PROPERTY_FROM_TABLE(property, table) \
do { \
    NSString *value = localizedStringFromTable(property, table); \
    if (value) property = value; \
} while (0)

#define localizeTitleForObjectFromTable(object, table)             LOCALIZE_PROPERTY_FROM_TABLE(object.title, table)
#define localizeAlternateTitleForObjectFromTable(object, table)    LOCALIZE_PROPERTY_FROM_TABLE(object.alternateTitle, table)
#define localizeStringValueForObjectFromTable(object, table)       LOCALIZE_PROPERTY_FROM_TABLE(object.stringValue, table)
#define localizePlaceholderStringForObjectFromTable(object, table) LOCALIZE_PROPERTY_FROM_TABLE(object.placeholderString, table)
#define localizeLabelForObjectFromTable(object, table)             LOCALIZE_PROPERTY_FROM_TABLE(object.label, table)
#define localizeToolTipForObjectFromTable(object, table)           LOCALIZE_PROPERTY_FROM_TABLE(object.toolTip, table)

@implementation NSObject (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {}

@end


@implementation NSArray (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    [self makeObjectsPerformSelector:_cmd withObject:table];
}

@end


@implementation NSButtonCell (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    localizeTitleForObjectFromTable(self, table);
    localizeAlternateTitleForObjectFromTable(self, table);
}

@end


@implementation NSPopUpButtonCell (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    // don't call super because the title is taken from the menu
    [[self menu] localizeStringsFromTable:table];
}

@end


@implementation NSSegmentedCell (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    NSUInteger i, iMax = [self segmentCount];
    NSString *string;
    for (i = 0; i < iMax; i++) {
        if ((string = localizedStringFromTable([self labelForSegment:i], table)))
            [self setLabel:string forSegment:i];
        if ((string = localizedStringFromTable([self toolTipForSegment:i], table)))
            [self setToolTip:string forSegment:i];
        [[self menuForSegment:i] localizeStringsFromTable:table];
    }
}

@end


@implementation NSTextFieldCell (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    localizeStringValueForObjectFromTable(self, table);
    localizePlaceholderStringForObjectFromTable(self, table);
}

@end


@implementation NSView (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    localizeToolTipForObjectFromTable(self, table);
    [[self subviews] localizeStringsFromTable:table];
}

@end


@implementation NSBox (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    [super localizeStringsFromTable:table];
    localizeTitleForObjectFromTable(self, table);
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
    for (id cell in cells) {
        if ((toolTip = localizedStringFromTable([self toolTipForCell:cell], table)))
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
    localizeLabelForObjectFromTable(self, table);
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
    localizeTitleForObjectFromTable(self, table);
    [[self itemArray] localizeStringsFromTable:table];
}

@end


@implementation NSMenuItem (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    localizeTitleForObjectFromTable(self, table);
    [[self submenu] localizeStringsFromTable:table];
}

@end


@implementation NSWindow (SKLocalization)

- (void)localizeStringsFromTable:(NSString *)table {
    localizeTitleForObjectFromTable(self, table);
    [[self contentView] localizeStringsFromTable:table];
}

@end
