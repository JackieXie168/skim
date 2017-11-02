//
//  PDFAnnotation_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/1/08.
/*
 This software is Copyright (c) 2008-2017
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

#import "PDFAnnotation_SKExtensions.h"
#import "PDFAnnotationCircle_SKExtensions.h"
#import "PDFAnnotationSquare_SKExtensions.h"
#import "PDFAnnotationLine_SKExtensions.h"
#import "PDFAnnotationMarkup_SKExtensions.h"
#import "PDFAnnotationFreeText_SKExtensions.h"
#import "PDFAnnotationText_SKExtensions.h"
#import "PDFAnnotationInk_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import "SKNPDFAnnotationNote_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "PDFPage_SKExtensions.h"
#import "PDFSelection_SKExtensions.h"
#import "SKPDFView.h"
#import "NSGraphics_SKExtensions.h"
#import "NSData_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "NSBezierPath_SKExtensions.h"
#import "SKVersionNumber.h"
#import "NSColor_SKExtensions.h"
#import "NSResponder_SKExtensions.h"
#import "NSUserDefaults_SKExtensions.h"
#import "SKMainDocument.h"
#import "NSView_SKExtensions.h"
#import "SKNoteText.h"
#import "PDFView_SKExtensions.h"
#import "SKRuntime.h"

#define SKUseUserNameKey @"SKUseUserName"
#define SKUserNameKey @"SKUserName"


NSString *SKPDFAnnotationScriptingBorderStyleKey = @"scriptingBorderStyle";
NSString *SKPDFAnnotationScriptingColorKey = @"scriptingColor";
NSString *SKPDFAnnotationScriptingModificationDateKey = @"scriptingModificationDate";
NSString *SKPDFAnnotationScriptingUserNameKey = @"scriptingUserName";
NSString *SKPDFAnnotationScriptingTextContentsKey = @"textContents";

NSString *SKPDFAnnotationBoundsOrderKey = @"boundsOrder";

NSString *SKPasteboardTypeSkimNote = @"net.sourceforge.skim-app.pasteboard.skimnote";


#if !defined(MAC_OS_X_VERSION_10_12) || MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_12
@interface PDFAnnotation (SKSierraDeclarations)
- (id)valueForAnnotationKey:(NSString *)key;
@end
#endif

@implementation PDFAnnotation (SKExtensions)

- (PDFTextAnnotationIconType)replacement_iconType { return kPDFTextAnnotationIconNote; }

+ (void)load {
    SKAddInstanceMethodImplementationFromSelector(self, @selector(iconType), @selector(replacement_iconType));
}

static PDFAnnotation *currentActiveAnnotation = nil;

+ (PDFAnnotation *)currentActiveAnnotation {
    PDFAnnotation *annotation = nil;
    @synchronized (self) {
        annotation = [currentActiveAnnotation retain];
    }
    return [annotation autorelease];
}

+ (void)setCurrentActiveAnnotation:(PDFAnnotation *)annotation {
    @synchronized (self) {
        if (currentActiveAnnotation != annotation) {
            [currentActiveAnnotation release];
            currentActiveAnnotation = [annotation retain];
        }
    }
}

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
    return [NSArray arrayWithObjects:SKPasteboardTypeSkimNote, nil];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
    return NSPasteboardReadingAsData;
}

- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type {
    if ([type isEqualToString:SKPasteboardTypeSkimNote] &&
        [propertyList isKindOfClass:[NSData class]]) {
        self = [self initSkimNoteWithProperties:[NSKeyedUnarchiver unarchiveObjectWithData:propertyList]];
    } else {
        [[self initWithBounds:NSZeroRect] release];
        self = nil;
    }
    return self;
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
    return [NSArray arrayWithObjects:SKPasteboardTypeSkimNote, nil];
}

- (id)pasteboardPropertyListForType:(NSString *)type {
    if ([type isEqualToString:SKPasteboardTypeSkimNote])
        return [NSKeyedArchiver archivedDataWithRootObject:[self SkimNoteProperties]];
    return nil;
}

- (NSString *)fdfString {
    NSMutableString *fdfString = [NSMutableString string];
    NSRect bounds = [self bounds];
    CGFloat r, g, b, a = 0.0;
    PDFBorder *border = [self border];
    NSString *contents = [self contents];
    NSDate *modDate = [self modificationDate];
    NSString *userName = [self userName];
    [[[self color] colorUsingColorSpaceName:NSDeviceRGBColorSpace] getRed:&r green:&g blue:&b alpha:&a];
    [fdfString appendFDFName:SKFDFTypeKey];
    [fdfString appendFDFName:SKFDFAnnotation];
    [fdfString appendFDFName:SKFDFAnnotationTypeKey];
    [fdfString appendFormat:@"/%@", [self isNote] ? SKNTextString : [self type]];
    [fdfString appendFDFName:SKFDFAnnotationBoundsKey];
    [fdfString appendFormat:@"[%f %f %f %f]", NSMinX(bounds), NSMinY(bounds), NSMaxX(bounds), NSMaxY(bounds)];
    [fdfString appendFDFName:SKFDFAnnotationPageIndexKey];
    [fdfString appendFormat:@" %lu", (unsigned long)[self pageIndex]];
    [fdfString appendFDFName:SKFDFAnnotationFlagsKey];
    [fdfString appendString:@" 4"];
    if (a > 0.0) {
        [fdfString appendFDFName:SKFDFAnnotationColorKey];
        [fdfString appendFormat:@"[%f %f %f]", r, g, b];
    }
    [fdfString appendFDFName:SKFDFAnnotationBorderStylesKey];
    [fdfString appendString:@"<<"];
    if (border && [border lineWidth] > 0.0) {
        [fdfString appendFDFName:SKFDFAnnotationLineWidthKey];
        [fdfString appendFormat:@" %f", [border lineWidth]];
        [fdfString appendFDFName:SKFDFAnnotationBorderStyleKey];
        [fdfString appendFDFName:SKFDFBorderStyleFromPDFBorderStyle([border style])];
        [fdfString appendFDFName:SKFDFAnnotationDashPatternKey];
        [fdfString appendFormat:@"[%@]", [[[border dashPattern] valueForKey:@"stringValue"] componentsJoinedByString:@" "]];
    } else {
        [fdfString appendFDFName:SKFDFAnnotationLineWidthKey];
        [fdfString appendString:@" 0.0"];
    }
    [fdfString appendString:@">>"];
    [fdfString appendFDFName:SKFDFAnnotationContentsKey];
    [fdfString appendString:@"("];
    if (contents)
        [fdfString appendString:[[contents lossyStringUsingEncoding:NSISOLatin1StringEncoding] stringByEscapingParenthesis]];
    [fdfString appendString:@")"];
    if (modDate) {
        [fdfString appendFDFName:SKFDFAnnotationModificationDateKey];
        [fdfString appendFormat:@"(%@)", SKFDFStringFromDate(modDate)];
    }
    if (userName) {
        [fdfString appendFDFName:SKFDFAnnotationUserNameKey];
        [fdfString appendFormat:@"(%@)", [[userName lossyStringUsingEncoding:NSISOLatin1StringEncoding] stringByEscapingParenthesis]];
    }
    return fdfString;
}

- (PDFDestination *)linkDestination {
    if ([self respondsToSelector:@selector(destination)]) {
        return [(PDFAnnotationLink *)self destination];
    } else if ([self isLink] && [self respondsToSelector:@selector(valueForAnnotationKey:)]) {
        id dest = nil;
        id action = [self valueForAnnotationKey:@"/A"];
        if ([action isKindOfClass:[PDFActionGoTo class]]) {
            dest = [(PDFActionGoTo *)action destination];
        } else if ([action isKindOfClass:[NSDictionary class]]) {
            if ([[action objectForKey:@"/S"] isEqualToString:@"/GoTo"])
                dest = [action objectForKey:@"/D"];
        } else {
            dest = [self valueForAnnotationKey:@"/Dest"];
        }
        if ([dest isKindOfClass:[PDFDestination class]]) {
            return dest;
        } else if ([dest isKindOfClass:[NSArray class]] && [dest count] > 1) {
            PDFPage *page = [dest objectAtIndex:0];
            if ([page isKindOfClass:[PDFPage class]]) {
                NSPoint point;
                NSString *type = [dest objectAtIndex:1];
                if ([type isEqualToString:@"/XYZ"] && [dest count] > 3)
                    point = NSMakePoint([[dest objectAtIndex:2] doubleValue], [[dest objectAtIndex:3] doubleValue]);
                else if ([page rotation] == 0)
                    point = SKTopLeftPoint([page boundsForBox:kPDFDisplayBoxCropBox]);
                else if ([page rotation] == 90)
                    point = SKBottomLeftPoint([page boundsForBox:kPDFDisplayBoxCropBox]);
                else if ([page rotation] == 180)
                    point = SKBottomRightPoint([page boundsForBox:kPDFDisplayBoxCropBox]);
                else
                    point = SKTopRightPoint([page boundsForBox:kPDFDisplayBoxCropBox]);
                return [[[PDFDestination alloc] initWithPage:page atPoint:point] autorelease];
            }
        }
    }
    return nil;
}

- (NSURL *)linkURL {
    if ([self respondsToSelector:@selector(URL)]) {
        return [(PDFAnnotationLink *)self URL];
    } else if ([self isLink] && [self respondsToSelector:@selector(valueForAnnotationKey:)]) {
        id action = [self valueForAnnotationKey:@"/A"];
        if ([action isKindOfClass:[PDFActionURL class]]) {
            return [(PDFActionURL *)action URL];
        } else if ([action isKindOfClass:[PDFActionRemoteGoTo class]]) {
            return [(PDFActionRemoteGoTo *)action URL];
        } else if ([action isKindOfClass:[NSDictionary class]]) {
            NSString *type = [action objectForKey:@"/S"];
            if ([type isEqualToString:@"/URI"]) {
                id uri = [action objectForKey:@"/URI"];
                if ([uri isKindOfClass:[NSURL class]])
                    return (NSURL *)uri;
                else if ([uri isKindOfClass:[NSString class]])
                    return [NSURL URLWithString:(NSString *)uri];
            } else if ([type isEqualToString:@"/GoToR"]) {
                id file = [action objectForKey:@"/F"];
                if ([file isKindOfClass:[NSDictionary class]])
                    file = [(NSDictionary *)file objectForKey:@"/Unix"] ?: [(NSDictionary *)file objectForKey:@"/F"];
                if ([file isKindOfClass:[NSURL class]]) {
                    return (NSURL *)file;
                } else if ([file isKindOfClass:[NSString class]]) {
                    if ([file rangeOfString:@"://"].location != NSNotFound)
                        return [NSURL URLWithString:file];
                    else if ([file isAbsolutePath])
                        return [NSURL fileURLWithPath:file];
                    else
                        return [NSURL URLWithString:file relativeToURL:[[[[self page] document] documentURL] URLByDeletingLastPathComponent]];
                }
            }
        }
    }
    return nil;
}

- (NSUInteger)pageIndex {
    PDFPage *page = [self page];
    return page ? [page pageIndex] : NSNotFound;
}

- (PDFBorderStyle)borderStyle {
    return [[self border] style];
}

- (void)setBorderStyle:(PDFBorderStyle)style {
    if ([self isEditable]) {
        PDFBorder *oldBorder = [self border];
        PDFBorder *border = nil;
        if (oldBorder || style)
            border = [[PDFBorder allocWithZone:[self zone]] init];
        if (oldBorder) {
            [border setLineWidth:[oldBorder lineWidth]];
            [border setDashPattern:[oldBorder dashPattern]];
        }
        if (border)
            [border setStyle:style];
        [self setBorder:border];
        [border release];
    }
}

- (CGFloat)lineWidth {
    PDFBorder *border = [self border];
    return border ? [border lineWidth] : 0.0;
}

- (void)setLineWidth:(CGFloat)width {
    if ([self isEditable]) {
        PDFBorder *border = nil;
        if (width > 0.0) {
            PDFBorder *oldBorder = [self border];
            border = [[PDFBorder allocWithZone:[self zone]] init];
            if (oldBorder && [oldBorder lineWidth] > 0.0) {
                [border setDashPattern:[oldBorder dashPattern]];
                [border setStyle:[oldBorder style]];
            }
            [border setLineWidth:width];
            [self setBorder:border];
        } else {
            [self setBorder:nil];
            if ([self border] != nil) {
                border = [[PDFBorder allocWithZone:[self zone]] init];
                [border setLineWidth:0.0];
                [self setBorder:border];
            }
        }
        [border release];
    }
}

- (NSArray *)dashPattern {
    return [[self border] dashPattern];
}

- (void)setDashPattern:(NSArray *)pattern {
    if ([self isEditable]) {
        PDFBorder *oldBorder = [self border];
        PDFBorder *border = nil;
        if (oldBorder || [pattern count])
            border = [[PDFBorder allocWithZone:[self zone]] init];
        if (oldBorder) {
            [border setLineWidth:[oldBorder lineWidth]];
            [border setStyle:[oldBorder style]];
        }
        if (border)
            [border setDashPattern:pattern];
        [self setBorder:border];
        [border release];
    }
}

- (NSImage *)image { return nil; }

- (NSAttributedString *)text { return nil; }

- (BOOL)hasNoteText { return NO; }

- (SKNoteText *)noteText { return nil; }

- (id)objectValue { return [self string]; }

- (NSString *)textString { return nil; }

- (NSColor *)interiorColor { return nil; }

- (BOOL)isMarkup { return NO; }

- (BOOL)isNote { return NO; }

- (BOOL)isText { return NO; }

- (BOOL)isLine { return NO; }

- (BOOL)isLink { return [[self type] isEqualToString:@"Link"]; }

- (BOOL)isResizable { return NO; }

- (BOOL)isMovable { return NO; }

- (BOOL)isEditable { return [self isSkimNote] && ([self page] == nil || [[self page] isEditable]); }

- (BOOL)hasBorder { return [self isSkimNote]; }

- (BOOL)isConvertibleAnnotation {
    static NSSet *convertibleTypes = nil;
    if (convertibleTypes == nil)
        convertibleTypes = [[NSSet alloc] initWithObjects:SKNFreeTextString, SKNTextString, SKNNoteString, SKNCircleString, SKNSquareString, SKNHighlightString, SKNUnderlineString, SKNStrikeOutString, SKNLineString, SKNInkString, nil];
    return [convertibleTypes containsObject:[self type]];
}

- (BOOL)hitTest:(NSPoint)point {
    return [self shouldDisplay] ? NSPointInRect(point, [self bounds]) : NO;
}

- (CGFloat)boundsOrder {
    return [[self page] sortOrderForBounds:[self bounds]];
}

- (NSRect)displayRectForBounds:(NSRect)bounds lineWidth:(CGFloat)lineWidth {
    return bounds;
}

- (NSRect)displayRect {
    return [self displayRectForBounds:[self bounds] lineWidth:[self lineWidth]];
}

- (SKRectEdges)resizeHandleForPoint:(NSPoint)point scaleFactor:(CGFloat)scaleFactor {
    return [self isResizable] ? SKResizeHandleForPointFromRect(point, [self bounds], 4.0 / scaleFactor) : 0;
}

- (void)drawSelectionHighlightForView:(PDFView *)pdfView inContext:(CGContextRef)context {
    if (NSIsEmptyRect([self bounds]))
        return;
    if ([self isSkimNote]) {
        BOOL active = floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_12 ? YES : [[pdfView window] isKeyWindow] && [[[pdfView window] firstResponder] isDescendantOf:pdfView];
        NSRect rect = [pdfView integralRect:[self bounds] onPage:[self page]];
        CGFloat lineWidth = [pdfView unitWidthOnPage:[self page]];
        CGContextSaveGState(context);
        CGColorRef color = [(active ? [NSColor alternateSelectedControlColor] : [NSColor disabledControlTextColor]) CGColor];
        CGContextSetStrokeColorWithColor(context, color);
        CGContextStrokeRectWithWidth(context, CGRectInset(NSRectToCGRect(rect), 0.5 * lineWidth, 0.5 * lineWidth), lineWidth);
        if ([self isResizable])
            SKDrawResizeHandles(context, rect, 4.0 * lineWidth, active);
        CGContextRestoreGState(context);
    } else if ([self isLink] && [self respondsToSelector:@selector(setHighlighted:)] == NO) {
        CGContextSaveGState(context);
        CGColorRef color = CGColorCreateGenericGray(0.0, 0.2);
        CGContextSetFillColorWithColor(context, color);
        CGColorRelease(color);
        CGContextFillRect(context, NSRectToCGRect([self bounds]));
        CGContextRestoreGState(context);
    }
}

- (void)registerUserName {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKUseUserNameKey]) {
        NSString *userName = [[NSUserDefaults standardUserDefaults] stringForKey:SKUserNameKey];
        [self setUserName:[userName length] ? userName : NSFullUserName()];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableModificationDateKey] == NO)
        [self setModificationDate:[NSDate date]];
}

- (void)autoUpdateString {}

- (NSString *)colorDefaultKey { return nil; }

- (NSString *)alternateColorDefaultKey { return nil; }

- (void)setColor:(NSColor *)color alternate:(BOOL)alternate updateDefaults:(BOOL)update {
    BOOL isFill = alternate && [self respondsToSelector:@selector(setInteriorColor:)];
    BOOL isText = alternate && [self respondsToSelector:@selector(setFontColor:)];
    NSColor *oldColor = (isFill ? [(id)self interiorColor] : (isText ? [(id)self fontColor] : [self color])) ?: [NSColor clearColor];
    if ([oldColor isEqual:color] == NO) {
        if (isFill)
            [(id)self setInteriorColor:[color alphaComponent] > 0.0 ? color : nil];
        else if (isText)
            [(id)self setFontColor:[color alphaComponent] > 0.0 ? color : nil];
        else
            [self setColor:color];
    }
    if (update) {
        NSString *key = (isFill || isText) ? [self alternateColorDefaultKey] : [self colorDefaultKey];
        if (key)
            [[NSUserDefaults standardUserDefaults] setColor:color forKey:key];
    }
}

- (NSSet *)keysForValuesToObserveForUndo {
    static NSSet *keys = nil;
    if (keys == nil)
        keys = [[NSSet alloc] initWithObjects:SKNPDFAnnotationBoundsKey, SKNPDFAnnotationStringKey, SKNPDFAnnotationColorKey, SKNPDFAnnotationBorderKey, SKNPDFAnnotationModificationDateKey, SKNPDFAnnotationUserNameKey, nil];
    return keys;
}

#pragma mark Scripting support

- (NSScriptObjectSpecifier *)objectSpecifier {
	NSUInteger idx = [[[self page] notes] indexOfObjectIdenticalTo:self];
    if (idx != NSNotFound) {
        NSScriptObjectSpecifier *containerRef = [[self page] objectSpecifier];
        return [[[NSUniqueIDSpecifier allocWithZone:[self zone]] initWithContainerClassDescription:[containerRef keyClassDescription] containerSpecifier:containerRef key:@"notes" uniqueID:[self uniqueID]] autorelease];
    } else {
        return nil;
    }
}

- (NSString *)uniqueID {
    return [NSString stringWithFormat:@"%p", (void *)self];
}

// overridden by subclasses to add or remove custom scripting keys relevant for the class, subclasses should call super first
+ (NSSet *)customScriptingKeys {
    static NSSet *customScriptingKeys = nil;
    if (customScriptingKeys == nil)
        customScriptingKeys = [[NSSet alloc] initWithObjects:SKNPDFAnnotationLineWidthKey, SKPDFAnnotationScriptingBorderStyleKey, SKNPDFAnnotationDashPatternKey, nil];
    return customScriptingKeys;
}

- (NSDictionary *)scriptingProperties {
    static NSSet *allCustomScriptingKeys = nil;
    if (allCustomScriptingKeys == nil) {
        NSMutableSet *customScriptingKeys = [NSMutableSet set];
        [customScriptingKeys unionSet:[PDFAnnotationCircle customScriptingKeys]];
        [customScriptingKeys unionSet:[PDFAnnotationSquare customScriptingKeys]];
        [customScriptingKeys unionSet:[PDFAnnotationFreeText customScriptingKeys]];
        [customScriptingKeys unionSet:[SKNPDFAnnotationNote customScriptingKeys]];
        [customScriptingKeys unionSet:[PDFAnnotationMarkup customScriptingKeys]];
        [customScriptingKeys unionSet:[PDFAnnotationLine customScriptingKeys]];
        [customScriptingKeys unionSet:[PDFAnnotationInk customScriptingKeys]];
        allCustomScriptingKeys = [customScriptingKeys copy];
    }
    // remove all custom properties that are not valid for this class
    NSMutableDictionary *properties = [[[super scriptingProperties] mutableCopy] autorelease];
    NSMutableSet *customKeys = [allCustomScriptingKeys mutableCopy];
    [customKeys minusSet:[[self class] customScriptingKeys]];
    [properties removeObjectsForKeys:[customKeys allObjects]];
    [customKeys release];
    return properties;
}

- (void)setScriptingProperties:(NSDictionary *)properties {
    [super setScriptingProperties:properties];
    // set the borderStyle afterwards, as this may have been changed when setting the dash pattern
    id style = [properties objectForKey:SKPDFAnnotationScriptingBorderStyleKey];
    if ([style respondsToSelector:@selector(integerValue)] && [properties objectForKey:SKNPDFAnnotationDashPatternKey])
        [self setScriptingBorderStyle:[style integerValue]];
}

- (NSColor *)scriptingColor {
    return [self color];
}

- (void)setScriptingColor:(NSColor *)newColor {
    if ([self isEditable]) {
        [self setColor:newColor];
    }
}

- (PDFPage *)scriptingPage {
    return [self page];
}

- (NSDate *)scriptingModificationDate {
    return [self modificationDate];
}

- (void)setScriptingModificationDate:(NSDate *)date {
    if ([self isEditable]) {
        [self setModificationDate:date];
    }
}

- (NSString *)scriptingUserName {
    return [self userName];
}

- (void)setScriptingUserName:(NSString *)name {
    if ([self isEditable]) {
        [self setUserName:name];
    }
}

- (PDFTextAnnotationIconType)scriptingIconType {
    return kPDFTextAnnotationIconNote;
}

- (id)textContents;
{
    return [[[NSTextStorage alloc] initWithString:[self string] ?: @""] autorelease];
}

- (void)setTextContents:(id)text;
{
    if ([self isEditable]) {
        [self setString:[text string]];
    }
}

- (id)coerceValueForTextContents:(id)value {
    if ([value isKindOfClass:[NSScriptObjectSpecifier class]])
        value = [(NSScriptObjectSpecifier *)value objectsByEvaluatingSpecifier];
    return [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:value toClass:[NSTextStorage class]];
}

- (id)richText {
    return nil;
}

- (void)setBoundsAsQDRect:(NSData *)inQDBoundsAsData {
    if ([self isMovable] && [self isEditable]) {
        NSRect newBounds = [inQDBoundsAsData rectValueAsQDRect];
        if ([self isResizable] == NO) {
            newBounds.size = [self bounds].size;
        } else {
            if (NSWidth(newBounds) < 0.0)
                newBounds.size.width = 0.0;
            if (NSHeight(newBounds) < 0.0)
                newBounds.size.height = 0.0;
        }
        [self setBounds:newBounds];
    }

}

- (NSData *)boundsAsQDRect {
    return [NSData dataWithRectAsQDRect:[self bounds]];
}

- (NSColor *)scriptingInteriorColor {
    return nil;
}

- (NSString *)fontName {
    return nil;
}

- (CGFloat)fontSize {
    return 0;
}

- (NSColor *)scriptingFontColor {
    return nil;
}

- (NSTextAlignment)scriptingAlignment {
    return NSLeftTextAlignment;
}

- (PDFBorderStyle)scriptingBorderStyle {
    return [self borderStyle];
}

- (void)setScriptingBorderStyle:(PDFBorderStyle)borderStyle {
    if ([self isEditable]) {
        [self setBorderStyle:borderStyle];
    }
}

- (NSData *)startPointAsQDPoint {
    return nil;
}

- (NSData *)endPointAsQDPoint {
    return nil;
}

- (PDFLineStyle)scriptingStartLineStyle {
    return kPDFLineStyleNone;
}

- (PDFLineStyle)scriptingEndLineStyle {
    return kPDFLineStyleNone;
}

- (id)selectionSpecifier {
    return nil;
}

- (NSArray *)scriptingPointLists {
    return nil;
}

- (void)handleEditScriptCommand:(NSScriptCommand *)command {
    if ([self isEditable]) {
        NSDocument *doc = [[self page] containingDocument];
        if ([doc isPDFDocument])
            [[(SKMainDocument *)doc pdfView] editAnnotation:self];
    }
}

@end
