//
//  BDSKSpotlightIconController.m
//  Bibdesk
//
//  Created by Adam Maxwell on 01/25/07.
/*
 This software is Copyright (c) 2007
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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

#import "BDSKSpotlightIconController.h"

@implementation BDSKSpotlightIconController

// at present, we only have a single thread creating metadata items in order to avoid race conditions due to file naming; hence, it should be safe to use a singleton
+ (NSBitmapImageRep *)imageRepWithMetadataItem:(id)anItem
{
    static id controller = nil;
    if (nil == controller)
        controller = [[self alloc] init];
    return [controller imageRepWithMetadataItem:anItem];
}

+ (IconFamily *)iconFamilyWithMetadataItem:(id)anItem;
{
    NSImage *icon = [[NSImage alloc] init];
    [icon addRepresentation:[self imageRepWithMetadataItem:anItem]];
    IconFamily *iconFamily = [IconFamily iconFamilyWithThumbnailsOfImage:icon usingImageInterpolation:NSImageInterpolationHigh];
    [icon release];
    return iconFamily;
}

- (id)init
{
    self = [self initWithWindowNibName:[self windowNibName]];
    if (self) {
        values = [[NSMutableArray alloc] initWithCapacity:16];
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy"];
    }
    return self;
}

- (void)dealloc
{
    [values release];
    [dateFormatter release];
    [super dealloc];
}

- (NSString *)windowNibName { return @"SpotlightFileIconController"; }

- (void)awakeFromNib
{
    NSCell *cell = [[NSCell alloc] init];
    [[[tableView tableColumns] objectAtIndex:0] setHeaderCell:cell];
    [[[tableView tableColumns] objectAtIndex:1] setHeaderCell:cell];
    [cell release];
    
    [tableView setGridColor:[NSColor keyboardFocusIndicatorColor]];
}    

- (int)numberOfRowsInTableView:(NSTableView *)tv { 
    int count = [values count];
    return MIN(count, 10);
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
    return [[values objectAtIndex:row] objectForKey:[tableColumn identifier]];
}

static NSDictionary *createDictionaryWithAttributeAndValue(NSString *attribute, id value)
{
    NSDictionary *dict;
    if (nil == value)
        value = @"";
    dict = [[NSDictionary alloc] initWithObjectsAndKeys:attribute, @"attributeName", value, @"attributeValue", nil];
    return dict;
}

static NSArray *createDictionariesFromMultivaluedAttribute(NSString *attribute, NSArray *values)
{
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[values count]];
    NSEnumerator *e = [values objectEnumerator];
    id value = [e nextObject];
    
    NSDictionary *dict;
    
    if (value) {
        dict = createDictionaryWithAttributeAndValue(attribute, value);
        [array addObject:dict];
        [dict release];
    }
    
    while (value = [e nextObject]) {
        // empty attribute name for the rest
        dict = createDictionaryWithAttributeAndValue(@"", value);
        [array addObject:dict];
        [dict release];
    }
    return array;
}

- (void)loadValuesFromMetadataItem:(id)anItem;
{
    // anItem is key-value coding compliant
    NSDictionary *dict;
    [values removeAllObjects];
    
    dict = createDictionaryWithAttributeAndValue(BDSKContainerString, [anItem valueForKey:@"net_sourceforge_bibdesk_container"]);
    [values addObject:dict];
    [dict release];

    dict = createDictionaryWithAttributeAndValue(BDSKTitleString, [anItem valueForKey:(NSString *)kMDItemTitle]);
    [values addObject:dict];
    [dict release];
    
    dict = createDictionaryWithAttributeAndValue(BDSKYearString, [dateFormatter stringFromDate:[anItem valueForKey:@"net_sourceforge_bibdesk_publicationdate"]]);
    [values addObject:dict];
    [dict release];
    
    NSArray *array = createDictionariesFromMultivaluedAttribute(BDSKAuthorString, [anItem valueForKey:(NSString *)kMDItemAuthors]);
    [values addObjectsFromArray:array];
    [array release];
    
    array = createDictionariesFromMultivaluedAttribute(BDSKKeywordsString, [anItem valueForKey:(NSString *)kMDItemKeywords]);
    [values addObjectsFromArray:array];
    [array release];
}

- (NSBitmapImageRep *)imageRepWithMetadataItem:(id)anItem;
{
    [self loadValuesFromMetadataItem:anItem];
    [tableView reloadData];
    
    NSView *contentView = [[self window] contentView];
    NSBitmapImageRep *imageRep = [contentView bitmapImageRepForCachingDisplayInRect:[contentView frame]];
    [contentView cacheDisplayInRect:[contentView frame] toBitmapImageRep:imageRep];
    return imageRep;
}    

@end


@implementation BDSKSpotlightIconTableView

static NSImage *applicationIcon = nil;

+ (void)initialize
{
    if (nil == applicationIcon) {
        applicationIcon = [[NSImage imageNamed:@"FolderPenIcon"] copy];
        [applicationIcon setSize:NSMakeSize(128, 128)];
    }
}

- (void)drawRect:(NSRect)rect {
    
    [super drawRect:rect];
    
    if ([self isFlipped]) {
        CGContextRef context;
        
        context = [[NSGraphicsContext currentContext] graphicsPort];
        CGContextSaveGState(context); {
            CGContextTranslateCTM(context, 0, NSMaxY(rect));
            CGContextScaleCTM(context, 1, -1);
            
            rect.origin.y = 0; // We've translated ourselves so it's zero
            [applicationIcon drawAtPoint:NSMakePoint(10.0f, NSMaxY([self frame]) - 128) fromRect:NSZeroRect operation:NSCompositeSourceAtop fraction:1.0f];
        } CGContextRestoreGState(context);
    }
    else {
        [applicationIcon drawAtPoint:NSMakePoint(10.0f, NSMaxY([self frame]) - 128) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0f];
    }
}

@end

@implementation BDSKClearView

- (void)drawRect:(NSRect)r
{
    r = [self frame];
    [[NSColor clearColor] setFill];
    NSRectFill(r);
}

@end
