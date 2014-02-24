//
//  NSAttributedString_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 6/12/08.
/*
 This software is Copyright (c) 2008-2014
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

#import "NSAttributedString_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "NSData_SKExtensions.h"


@implementation NSAttributedString (SKExtensions)

- (NSAttributedString *)accessibilityAttributedString {
    static NSTextFieldCell *cell = nil;
    if (cell == nil)
        cell = [[NSTextFieldCell alloc] init];
    [cell setAttributedStringValue:self];
    return [cell accessibilityAttributeValue:NSAccessibilityAttributedStringForRangeParameterizedAttribute forParameter:[NSValue valueWithRange:NSMakeRange(0, [self length])]];
}

#pragma mark Templating support

- (NSString *)xmlString {
    return [[self string] xmlString];
}

- (NSData *)RTFRepresentation {
    return [self RTFFromRange:NSMakeRange(0, [self length]) documentAttributes:nil];
}

#pragma mark Scripting support

- (NSString *)scriptingName {
    return [[self RTFRepresentation] hexString];
}

- (NSTextStorage *)scriptingRichText {
    return [[[NSTextStorage alloc] initWithAttributedString:self] autorelease];
}

- (NSScriptObjectSpecifier *)objectSpecifier {
    NSScriptClassDescription *containerClassDescription = [NSScriptClassDescription classDescriptionForClass:[NSApp class]];
    return [[[NSNameSpecifier allocWithZone:[self zone]] initWithContainerClassDescription:containerClassDescription containerSpecifier:nil key:@"richTextFormat" name:[self scriptingName]] autorelease];
}

- (NSScriptObjectSpecifier *)richTextSpecifier {
    NSScriptObjectSpecifier *rtfSpecifier = [self objectSpecifier];
    return [[[NSPropertySpecifier alloc] initWithContainerClassDescription:[rtfSpecifier keyClassDescription] containerSpecifier:rtfSpecifier key:@"scriptingRichText"] autorelease];
}

@end


@implementation NSTextStorage (SKExtensions)

#pragma mark Scripting support

- (id)scriptingRTF {
    return [self RTFRepresentation];
}

- (void)setScriptingRTF:(id)data {
    if (data) {
        NSAttributedString *attrString = [[NSAttributedString alloc] initWithData:data options:[NSDictionary dictionary] documentAttributes:NULL error:NULL];
        if (attrString)
            [self setAttributedString:attrString];
        [attrString release];
    }
}

@end


@implementation NSApplication (SKRichTextFormat)

- (NSAttributedString *)valueInRichTextFormatWithName:(NSString *)name {
    NSData *data = [[[NSData alloc] initWithHexString:name] autorelease];
    return data ? [[[NSAttributedString alloc] initWithData:data options:[NSDictionary dictionary] documentAttributes:NULL error:NULL] autorelease] : nil;
}

@end
