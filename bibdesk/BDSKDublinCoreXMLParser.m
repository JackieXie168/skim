//
//  BDSKDublinCoreXMLParser.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 12/31/06.
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

#import "BDSKDublinCoreXMLParser.h"
#import "BibItem.h"


@implementation BDSKDublinCoreXMLParser

+ (BOOL)canParseString:(NSString *)string{
    return [string rangeOfString:@"<dc-record>"].location != NSNotFound || [string rangeOfString:@"<dc:dc-record>"].location != NSNotFound;
}

static NSString *joinedArrayComponents(NSArray *arrayOfXMLNodes, NSString *separator)
{
    NSArray *strings = [arrayOfXMLNodes valueForKeyPath:@"stringValue"];
    return [strings componentsJoinedByString:separator];
}

+ (NSArray *)itemsFromString:(NSString *)xmlString error:(NSError **)outError
{
    NSXMLDocument *doc = [[NSXMLDocument alloc] initWithXMLString:xmlString options:0 error:outError];
    if (nil == doc)
        return nil;
    
    NSXMLElement *root = [doc rootElement];
    
    NSMutableArray *arrayOfPubs = [NSMutableArray array];
    unsigned i, iMax = [root childCount];
    NSXMLNode *node;
    
    BOOL hasPrefix = [[root name] hasPrefix:@"dc:"];
    
    for (i = 0; i < iMax; i++) {
        
        node = [root childAtIndex:i];
        NSMutableDictionary *pubDict = [[NSMutableDictionary alloc] initWithCapacity:5];
        
        NSMutableArray *authors = [NSMutableArray arrayWithArray:[node nodesForXPath:hasPrefix ? @"dc:creator" : @"creator" error:NULL]];
        [authors addObjectsFromArray:[node nodesForXPath:hasPrefix ? @"dc:contributor" : @"contributor" error:NULL]];
        [pubDict setObject:joinedArrayComponents(authors, @" and ") forKey:BDSKAuthorString];
        
        NSArray *array = [node nodesForXPath:hasPrefix ? @"dc:title" : @"title" error:NULL];
        [pubDict setObject:joinedArrayComponents(array, @"; ") forKey:BDSKTitleString];
        
        array = [node nodesForXPath:hasPrefix ? @"dc:subject" : @"subject" error:NULL];
        [pubDict setObject:joinedArrayComponents(array, @"; ") forKey:BDSKKeywordsString];
        
        array = [node nodesForXPath:hasPrefix ? @"dc:publisher" : @"publisher" error:NULL];
        [pubDict setObject:joinedArrayComponents(array, @"; ") forKey:BDSKPublisherString];
        
        array = [node nodesForXPath:hasPrefix ? @"dc:location" : @"location" error:NULL];
        [pubDict setObject:joinedArrayComponents(array, @"; ") forKey:@"Location"];

        BibItem *pub = [[BibItem alloc] initWithType:BDSKBookString
                                            fileType:BDSKBibtexString 
                                             citeKey:nil 
                                           pubFields:pubDict 
                                               isNew:YES];
        [pubDict release];
        [arrayOfPubs addObject:pub];
        [pub release];
    }
    
    [doc release];
    return arrayOfPubs;
    
}

@end
