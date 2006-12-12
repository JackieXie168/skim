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
#import "BDSKShellTask.h"


@implementation BDSKTemplateObjectProxy

+ (NSString *)stringByParsingTemplate:(BDSKTemplate *)template withObject:(id)anObject publications:(NSArray *)items {
    NSString *string = [template mainPageString];
    NSString *scriptPath = [template scriptPath];
    BDSKTemplateObjectProxy *objectProxy = [[self alloc] initWithObject:anObject publications:items template:template];
    string = [BDSKTemplateParser stringByParsingTemplate:string usingObject:objectProxy delegate:objectProxy];
    [objectProxy release];
    if(scriptPath)
        string = [[BDSKShellTask shellTask] runShellCommand:scriptPath withInputString:string];
    return string;
}

+ (NSAttributedString *)attributedStringByParsingTemplate:(BDSKTemplate *)template withObject:(id)anObject publications:(NSArray *)items documentAttributes:(NSDictionary **)docAttributes {
    NSAttributedString *attrString = nil;
    NSString *scriptPath = [template scriptPath];
    if(scriptPath == nil){
        BDSKTemplateObjectProxy *objectProxy = [[self alloc] initWithObject:anObject publications:items template:template];
        attrString = [template mainPageAttributedStringWithDocumentAttributes:docAttributes];
        attrString = [BDSKTemplateParser attributedStringByParsingTemplate:attrString usingObject:objectProxy delegate:objectProxy];
        [objectProxy release];
    }else{
        NSString *docType = nil;
        BDSKTemplateFormat templateFormat = [template templateFormat];
        if(templateFormat == BDSKRichHTMLTemplateFormat)
            docType = NSHTMLTextDocumentType;
        if(templateFormat == BDSKRTFTemplateFormat)
            docType = NSRTFTextDocumentType;
        else if(templateFormat == BDSKRTFDTemplateFormat)
            docType = NSRTFDTextDocumentType;
        else if(templateFormat == BDSKDocTemplateFormat)
            docType = NSDocFormatTextDocumentType;
        NSData *data = [self dataByParsingTemplate:template withObject:anObject publications:items];
        attrString = [[[NSAttributedString alloc] initWithData:data options:[NSDictionary dictionaryWithObjectsAndKeys:docType, NSDocumentTypeDocumentOption, nil] documentAttributes:NULL error:NULL] autorelease];
    }
    return attrString;
}

+ (NSData *)dataByParsingTemplate:(BDSKTemplate *)template withObject:(id)anObject publications:(NSArray *)items {
    NSString *string = [template mainPageString];
    NSString *scriptPath = [template scriptPath];
    BDSKTemplateObjectProxy *objectProxy = [[self alloc] initWithObject:anObject publications:items template:template];
    string = [BDSKTemplateParser stringByParsingTemplate:string usingObject:objectProxy delegate:objectProxy];
    [objectProxy release];
    string = [[BDSKShellTask shellTask] runShellCommand:scriptPath withInputString:string];
    return [string dataUsingEncoding:NSUTF8StringEncoding];
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
