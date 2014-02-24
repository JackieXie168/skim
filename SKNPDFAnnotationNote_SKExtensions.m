//
//  SKNPDFAnnotationNote_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/6/07.
/*
 This software is Copyright (c) 2007-2014
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

#import "SKNPDFAnnotationNote_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>
#import "PDFAnnotation_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKFDFParser.h"
#import "NSUserDefaults_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "SKNoteText.h"


NSString *SKPDFAnnotationRichTextKey = @"richText";


@implementation SKNPDFAnnotationNote (SKExtensions)

+ (NSDictionary *)textToNoteSkimNoteProperties:(NSDictionary *)properties {
    if ([[properties objectForKey:SKNPDFAnnotationTypeKey] isEqualToString:SKNTextString]) {
        NSMutableDictionary *mutableProperties = [[properties mutableCopy] autorelease];
        NSRect bounds = NSRectFromString([properties objectForKey:SKNPDFAnnotationBoundsKey]);
        NSString *contents = [properties objectForKey:SKNPDFAnnotationContentsKey];
        [mutableProperties setObject:SKNNoteString forKey:SKNPDFAnnotationTypeKey];
        bounds.origin.y = NSMaxY(bounds) - SKNPDFAnnotationNoteSize.height;
        bounds.size = SKNPDFAnnotationNoteSize;
        [mutableProperties setObject:NSStringFromRect(bounds) forKey:SKNPDFAnnotationBoundsKey];
        if (contents) {
            NSRange r = [contents rangeOfString:@"  "];
            if (NSMaxRange(r) < [contents length]) {
                NSFont *font = [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] stringForKey:SKAnchoredNoteFontNameKey]
                                               size:[[NSUserDefaults standardUserDefaults] floatForKey:SKAnchoredNoteFontSizeKey]];
                NSAttributedString *attrString = [[[NSAttributedString alloc] initWithString:[contents substringFromIndex:NSMaxRange(r)]
                                                    attributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil]] autorelease];
                [mutableProperties setObject:attrString forKey:SKNPDFAnnotationTextKey];
                [mutableProperties setObject:[contents substringToIndex:r.location] forKey:SKNPDFAnnotationContentsKey];
            }
        }
        return mutableProperties;
    }
    return properties;
}

- (id)initSkimNoteWithBounds:(NSRect)bounds {
    self = [super initSkimNoteWithBounds:bounds];
    if (self) {
        [self setColor:[[NSUserDefaults standardUserDefaults] colorForKey:SKAnchoredNoteColorKey]];
        [self setIconType:[[NSUserDefaults standardUserDefaults] integerForKey:SKAnchoredNoteIconTypeKey]];
        textStorage = [[NSTextStorage allocWithZone:[self zone]] init];
        [textStorage setDelegate:self];
        text = [[NSAttributedString alloc] init];
        texts = [[NSArray alloc] initWithObjects:[[[SKNoteText alloc] initWithNote:self] autorelease], nil];
    }
    return self;
}

- (BOOL)isNote { return YES; }

- (BOOL)isMovable { return [self isSkimNote]; }

- (BOOL)hasBorder { return NO; }

// override these Leopard methods to avoid showing the standard tool tips over our own
- (NSString *)toolTip { return @""; }

- (PDFAnnotationPopup *)popup { return nil; }

- (NSArray *)texts { return texts; }

- (NSSet *)keysForValuesToObserveForUndo {
    static NSSet *noteKeys = nil;
    if (noteKeys == nil) {
        NSMutableSet *mutableKeys = [[super keysForValuesToObserveForUndo] mutableCopy];
        [mutableKeys addObject:SKNPDFAnnotationTextKey];
        [mutableKeys addObject:SKNPDFAnnotationImageKey];
        noteKeys = [mutableKeys copy];
        [mutableKeys release];
    }
    return noteKeys;
}

#pragma mark Scripting support

+ (NSSet *)customScriptingKeys {
    static NSSet *customNoteScriptingKeys = nil;
    if (customNoteScriptingKeys == nil) {
        NSMutableSet *customKeys = [[super customScriptingKeys] mutableCopy];
        [customKeys addObject:SKPDFAnnotationRichTextKey];
        customNoteScriptingKeys = [customKeys copy];
        [customKeys release];
    }
    return customNoteScriptingKeys;
}

- (id)richText {
    return textStorage;
}

- (void)setRichText:(id)newText {
    if ([self isEditable] && newText != textStorage) {
        // We are willing to accept either a string or an attributed string.
        if ([newText isKindOfClass:[NSAttributedString class]])
            [textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withAttributedString:newText];
        else
            [textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:newText];
    }
}

- (id)coerceValueForRichText:(id)value {
    if ([value isKindOfClass:[NSScriptObjectSpecifier class]])
        value = [(NSScriptObjectSpecifier *)value objectsByEvaluatingSpecifier];
    // We want to just get Strings unchanged.  We will detect this and do the right thing in setRichText.  We do this because, this way, we will do more reasonable things about attributes when we are receiving plain text.
    if ([value isKindOfClass:[NSString class]])
        return value;
    else
        return [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:value toClass:[NSTextStorage class]];
}

#pragma mark Accessibility

- (NSArray *)accessibilityAttributeNames {
    static NSArray *attributes = nil;
    if (attributes == nil) {
        attributes = [[[super accessibilityAttributeNames] arrayByAddingObject:NSAccessibilityValueAttribute] retain];
    }
    return attributes;
}

- (id)accessibilityRoleAttribute {
    return NSAccessibilityButtonRole;
}

- (id)accessibilityValueAttribute {
    return [self contents];
}

- (id)accessibilityEnabledAttribute {
    return [NSNumber numberWithBool:YES];
}

- (NSArray *)accessibilityActionNames {
    return [NSArray arrayWithObject:NSAccessibilityPressAction];
}

@end
