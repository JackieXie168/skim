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
    IconFamily *iconFamily = [IconFamily iconFamilyWithThumbnailsOfLargeImage:icon smallImage:[NSImage imageNamed:@"cacheDoc"] usingImageInterpolation:NSImageInterpolationHigh];
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

@interface IconFamily (BDSKInternals)

// this is defined privately in OA
+ (NSImage*) resampleImage:(NSImage*)image toIconWidth:(int)width usingImageInterpolation:(NSImageInterpolation)imageInterpolation;

@end

@implementation IconFamily (BDSKExtensions)

// Copied and modified from OAAppKit/IconFamily

+ (IconFamily *)iconFamilyWithThumbnailsOfLargeImage:(NSImage *)largeImage smallImage:(NSImage *)smallImage usingImageInterpolation:(NSImageInterpolation)imageInterpolation;
{
    return [[[IconFamily alloc] initWithThumbnailsOfLargeImage:(NSImage *)largeImage smallImage:(NSImage *)smallImage usingImageInterpolation:imageInterpolation] autorelease];
}

- (id)initWithThumbnailsOfLargeImage:(NSImage *)largeImage smallImage:(NSImage *)smallImage usingImageInterpolation:(NSImageInterpolation)imageInterpolation;
{
    NSImage* iconImage128x128;
    NSImage* iconImage32x32;
    NSImage* iconImage16x16;
    NSBitmapImageRep* iconBitmap128x128;
    NSBitmapImageRep* iconBitmap32x32;
    NSBitmapImageRep* iconBitmap16x16;
    NSImage* bitmappedIconImage32x32;
    
    // Start with a new, empty IconFamily.
    self = [self init];
    if (self == nil)
        return nil;
    
    // Resample the given image to create a 128x128 pixel, 32-bit RGBA
    // version, and use that as our "thumbnail" (128x128) icon and mask.
    //
    // Our +resampleImage:toIconWidth:... method, in its present form,
    // returns an NSImage that contains an NSCacheImageRep, rather than
    // an NSBitmapImageRep.  We convert to an NSBitmapImageRep, so that
	// our methods can scan the image data, using initWithFocusedViewRect:.
    iconImage128x128 = [IconFamily resampleImage:largeImage toIconWidth:128 usingImageInterpolation:imageInterpolation];
	[iconImage128x128 lockFocus];
	iconBitmap128x128 = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, 128, 128)];
	[iconImage128x128 unlockFocus];
    if (iconBitmap128x128) {
        [self setIconFamilyElement:kThumbnail32BitData fromBitmapImageRep:iconBitmap128x128];
        [self setIconFamilyElement:kThumbnail8BitMask  fromBitmapImageRep:iconBitmap128x128];
    }
   
    // Resample the 128x128 image to create a 32x32 pixel, 32-bit RGBA version,
    // and use that as our "large" (32x32) icon and 8-bit mask.
    iconImage32x32 = [IconFamily resampleImage:smallImage toIconWidth:32 usingImageInterpolation:imageInterpolation];
	[iconImage32x32 lockFocus];
	iconBitmap32x32 = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, 32, 32)];
	[iconImage32x32 unlockFocus];
    if (iconBitmap32x32) {
        [self setIconFamilyElement:kLarge32BitData fromBitmapImageRep:iconBitmap32x32];
        [self setIconFamilyElement:kLarge8BitData fromBitmapImageRep:iconBitmap32x32];
        [self setIconFamilyElement:kLarge8BitMask fromBitmapImageRep:iconBitmap32x32];
        [self setIconFamilyElement:kLarge1BitMask fromBitmapImageRep:iconBitmap32x32];
    }

    // Create an NSImage with the iconBitmap32x32 NSBitmapImageRep, that we
    // can resample to create the smaller icon family elements.  (This is
    // most likely more efficient than resampling from the original image again,
    // particularly if it is large.  It produces a slightly different result, but
    // the difference is minor and should not be objectionable...)
    bitmappedIconImage32x32 = [[NSImage alloc] initWithSize:NSMakeSize(32,32)];
    [bitmappedIconImage32x32 addRepresentation:iconBitmap32x32];

    // Resample the 128x128 image to create a 16x16 pixel, 32-bit RGBA version,
    // and use that as our "small" (16x16) icon and 8-bit mask.
    iconImage16x16 = [IconFamily resampleImage:bitmappedIconImage32x32 toIconWidth:16 usingImageInterpolation:imageInterpolation];
	[iconImage16x16 lockFocus];
	iconBitmap16x16 = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, 16, 16)];
	[iconImage16x16 unlockFocus];
    if (iconBitmap16x16) {
        [self setIconFamilyElement:kSmall32BitData fromBitmapImageRep:iconBitmap16x16];
        [self setIconFamilyElement:kSmall8BitData fromBitmapImageRep:iconBitmap16x16];
        [self setIconFamilyElement:kSmall8BitMask fromBitmapImageRep:iconBitmap16x16];
        [self setIconFamilyElement:kSmall1BitMask fromBitmapImageRep:iconBitmap16x16];
    }

    // Release all of the images that we created and no longer need.
    [bitmappedIconImage32x32 release];
    [iconBitmap128x128 release];
    [iconBitmap32x32 release];
    [iconBitmap16x16 release];

    // Return the new icon family!
    return self;
}

@end
