//
//  BDSKTemplateObjectProxy.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 10/10/06.
/*
 This software is Copyright (c) 2006
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

#import "BDSKTemplateObjectProxy.h"
#import "BDSKTemplate.h"
#import "BibItem.h"


@implementation BDSKTemplateObjectProxy

+ (NSString *)stringByParsingTemplate:(BDSKTemplate *)template withObject:(id)anObject publications:(NSArray *)items {
    NSString *string = [template mainPageString];
    BDSKTemplateObjectProxy *objectProxy = [[self alloc] initWithObject:anObject publications:items template:template];
    string = [BDSKTemplateParser stringByParsingTemplate:string usingObject:objectProxy delegate:objectProxy];
    [objectProxy release];
    return string;
}

+ (NSAttributedString *)attributedStringByParsingTemplate:(BDSKTemplate *)template withObject:(id)anObject publications:(NSArray *)items documentAttributes:(NSDictionary **)docAttributes {
    NSAttributedString *string = [template mainPageAttributedStringWithDocumentAttributes:docAttributes];
    BDSKTemplateObjectProxy *objectProxy = [[self alloc] initWithObject:anObject publications:items template:template];
    string = [BDSKTemplateParser attributedStringByParsingTemplate:string usingObject:objectProxy delegate:objectProxy];
    [objectProxy release];
    return string;
}

- (id)initWithObject:(id)anObject publications:(NSArray *)items template:(BDSKTemplate *)aTemplate {
    if (self = [super init]) {
        object = [anObject retain];
        publications = [items copy];
        template = [aTemplate retain];
        currentIndex = 0;
    }
    return self;
}

- (void)dealloc {
    [object release];
    [publications release];
    [template release];
    [super dealloc];
}

- (id)valueForUndefinedKey:(NSString *)key { return [object valueForKey:key]; }

- (NSArray *)publications { return publications; }

- (id)publicationsUsingTemplate{
    NSEnumerator *e = [publications objectEnumerator];
    BibItem *pub = nil;
    
    OBPRECONDITION(nil != template);
    BDSKTemplateFormat format = [template templateFormat];
    id returnString = nil;
    NSAutoreleasePool *pool = nil;
    
    if (format & BDSKTextTemplateFormat) {
        
        returnString = [NSMutableString stringWithString:@""];        
        while(pub = [e nextObject]){
            pool = [NSAutoreleasePool new];
            [pub setItemIndex:++currentIndex];
            [returnString appendString:[pub stringValueUsingTemplate:template]];
            [pool release];
        }
        
    } else if (format & BDSKRichTextTemplateFormat) {
        
        returnString = [[[NSMutableAttributedString alloc] init] autorelease];
        while(pub = [e nextObject]){
            pool = [NSAutoreleasePool new];
            [pub setItemIndex:++currentIndex];
            [returnString appendAttributedString:[pub attributedStringValueUsingTemplate:template]];
            [pool release];
        }
    }
    
    return returnString;
}

// legacy method, as it may appear as a key in older templates
- (id)publicationsAsHTML{ return [self publicationsUsingTemplate]; }

- (NSCalendarDate *)currentDate{ return [NSCalendarDate date]; }

// BDSKTemplateParserDelegate protocol
- (void)templateParserWillParseTemplate:(id)template usingObject:(id)anObject isAttributed:(BOOL)flag {
    if ([anObject isKindOfClass:[BibItem class]]) {
        [(BibItem *)anObject setItemIndex:++currentIndex];
        [(BibItem *)anObject prepareForTemplateParsing];
    }
}

- (void)templateParserDidParseTemplate:(id)template usingObject:(id)anObject isAttributed:(BOOL)flag {
    if ([anObject isKindOfClass:[BibItem class]]) 
        [(BibItem *)anObject cleanupAfterTemplateParsing];
}

@end
