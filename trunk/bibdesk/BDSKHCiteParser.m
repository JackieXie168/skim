//
//  BDSKHCiteParser.m
//
//  Created by Michael McCracken on 11/1/06.
/*
 This software is Copyright (c) 2007
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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

#import "BDSKHCiteParser.h"
#import <WebKit/WebKit.h>
#import "BibItem.h"
#import "BibTypeManager.h"

@interface NSXMLNode (BDSKExtensions)
- (NSString *)stringValueOfAttribute:(NSString *)attrName;
- (NSArray *)descendantOrSelfNodesWithClassName:(NSString *)className error:(NSError **)err;
- (BOOL)hasParentWithClassName:(NSString *)class;
- (NSArray *)classNames;
- (NSString *)fullStringValueIfABBR;

@end

@interface BDSKHCiteParser (Private)
+ (NSCalendarDate *)dateFromNode:(NSXMLNode *)node;
+ (NSString *)BTAuthorStringFromVCardNode:(NSXMLNode *)node;
+ (NSMutableDictionary *)dictionaryFromCitationNode:(NSXMLNode *)citationNode;

@end


@implementation BDSKHCiteParser

+ (BOOL)canParseDocument:(DOMDocument *)domDocument fromURL:(NSURL *)url{
    NSString *htmlString = [(id)[domDocument documentElement] outerHTML];
    NSError *error = nil;
    NSXMLDocument *doc = [[NSXMLDocument alloc] initWithXMLString:htmlString
                                                          options:NSXMLDocumentTidyHTML error:&error];
    if(doc == nil)
        return NO;
    
    NSString *containsCitationPath = @".//*[contains(concat(' ', normalize-space(@class), ' '),' hcite ')]";
    
    return [[[doc rootElement] nodesForXPath:containsCitationPath error:&error] count] > 0;
}

+ (NSArray *)itemsFromDocument:(DOMDocument *)domDocument fromURL:(NSURL *)url error:(NSError **)outError{

    NSMutableArray *items = [NSMutableArray arrayWithCapacity:0];
    
    NSString *htmlString = [(id)[domDocument documentElement] outerHTML];
    NSError *error = nil;
    NSXMLDocument *doc = [[NSXMLDocument alloc] initWithXMLString:htmlString
                                                          options:NSXMLDocumentTidyHTML error:&error];
    
    if(doc == nil){
        if (outError) *outError = error;
        return nil;
    }
    
    NSString *containsCitationPath = @".//*[contains(concat(' ', normalize-space(@class), ' '),' hcite ')]";
    
    NSArray *mainNodes = [[doc rootElement] nodesForXPath:containsCitationPath
                                                    error:&error];
    
    unsigned int i, count = [mainNodes count];
    
    if(mainNodes == nil){
        if(outError) *outError = error;
        return nil;
    }else if(count == 0){
        return items;
    }
    
    for (i = 0; i < count; i++) {
        NSMutableDictionary *rd = nil;
        NSXMLNode* obj = [mainNodes objectAtIndex:i];
        
        // avoid creating top-level refs from containers:
        if([[obj classNames] containsObject:@"container"]) continue;
        
        rd = [self dictionaryFromCitationNode:obj];
        
        BibItem *item = [[[BibItem alloc] initWithType:[rd valueForKey:@"Type"]
                                              fileType:BDSKBibtexString
                                               citeKey:nil
                                             pubFields:rd
                                                 isNew:YES] autorelease];
        [items addObject:item];
    }
    
    return items;  
    
}

@end 


@implementation BDSKHCiteParser (Private)

+ (NSMutableDictionary *)dictionaryFromCitationNode:(NSXMLNode *)citationNode{
    BibTypeManager *typeMan = [BibTypeManager sharedManager];
    NSMutableDictionary *rd = [NSMutableDictionary dictionaryWithCapacity:0];
    
    NSError *err = nil;
    unsigned int i = 0;
    
    // find type but not type that's a descendant of 'container'.
    NSArray *typeNodes = [citationNode descendantOrSelfNodesWithClassName:@"type" error:&err];
    
    NSString *typeString = nil;
    for (i = 0; i < [typeNodes count]; i++) {
        NSXMLNode *node = [typeNodes objectAtIndex:i];
        if(![[citationNode classNames] containsObject:@"container"] &&
           [node hasParentWithClassName:@"container"] ) continue;
        typeString = [node fullStringValueIfABBR];
    }
    
    if(typeString != nil){
        [rd setObject:[typeMan bibtexTypeForHCiteType:typeString]
               forKey:@"Type"];
    }else{
        [rd setObject:@"misc" forKey:@"Type"];
    }
    
    
    // find title node
    
    NSArray *titleNodes = [citationNode descendantOrSelfNodesWithClassName:@"title" error:&err];
    
    for(i = 0; i < [titleNodes count]; i++){
        NSXMLNode *node = [titleNodes objectAtIndex:i];
        if(![[citationNode classNames] containsObject:@"container"] &&
           [node hasParentWithClassName:@"container"]){
            // note: todo - avoid second hasParentWithClassName by finding container 
            // nodes first and caching those then checking against them here. (if necessary)
            continue; // deal with this citation's container later
        }
        
        [rd setObject:[node stringValue] forKey:@"Title"];
    }
    
    // find authors

    NSArray *authorNodes = [citationNode descendantOrSelfNodesWithClassName:@"creator" error:&err];
    NSMutableString *BTAuthString = [NSMutableString stringWithCapacity:0];
    
    for(i = 0; i < [authorNodes count]; i++){
        NSXMLNode *node = [authorNodes objectAtIndex:i];
        if (! [[node classNames] containsObject:@"vcard"]) continue;
        
        if(i > 0)[BTAuthString appendFormat:@" and "];
        
        [BTAuthString appendString:[self BTAuthorStringFromVCardNode:node]];
        
    }
    [rd setObject:BTAuthString forKey:@"Author"];
    
    // find keywords
    
    NSArray *tagNodes = [citationNode nodesForXPath:@".//*[contains(concat(' ', normalize-space(@rel), ' '), ' tag ')]" error:&err];
     NSMutableString *BTKeywordString = [NSMutableString stringWithCapacity:0];
     
     for(i = 0; i < [tagNodes count]; i++){
         NSXMLNode *node = [tagNodes objectAtIndex:i];
         
         if(i > 0)[BTKeywordString appendFormat:@"; "];
         
         [BTKeywordString appendString:[node stringValue]];
         
     }
     [rd setObject:BTKeywordString forKey:@"Keywords"];
     
     // find description (append multiple descriptions to avoid data loss)
     
     NSMutableArray *descNodes = [NSMutableArray arrayWithCapacity:0];
     [descNodes addObjectsFromArray:[citationNode descendantOrSelfNodesWithClassName:@"description" error:&err]];
     [descNodes addObjectsFromArray:[citationNode descendantOrSelfNodesWithClassName:@"abstract" error:&err]];
     
     NSMutableString *BTDescString = [NSMutableString stringWithCapacity:0];
     
     for(i = 0; i < [descNodes count]; i++){
         NSXMLNode *node = [descNodes objectAtIndex:i];
         
         if(i > 0)[BTDescString appendFormat:@"\n"];
         
         [BTDescString appendString:[node stringValue]];
         
     }
     [rd setObject:BTDescString forKey:@"Abstract"];
     
     
     // find date published
     
     NSArray *datePublishedNodes = [citationNode descendantOrSelfNodesWithClassName:@"date-published" error:&err];
     
     if([datePublishedNodes count] > 0) {
         NSXMLNode *datePublishedNode = [datePublishedNodes objectAtIndex:0]; // Only use the first such node.
         NSCalendarDate *datePublished = [self dateFromNode:datePublishedNode];
         [rd setObject:[datePublished descriptionWithCalendarFormat:@"%Y"]
                forKey:@"Year"];
         [rd setObject:[datePublished descriptionWithCalendarFormat:@"%B"]
                forKey:@"Month"];
     }
     
     // find issue
     
     NSArray *issueNodes = [citationNode descendantOrSelfNodesWithClassName:@"issue" error:&err];
     
     if([issueNodes count] > 0) {
         NSXMLNode *issueNode = [issueNodes objectAtIndex:0]; // Only use the first such node.

         [rd setObject:[issueNode stringValue]
                forKey:@"issue"];
     }     
     
     // find pages
     
     NSArray *pagesNodes = [citationNode descendantOrSelfNodesWithClassName:@"pages" error:&err];
     
     if([pagesNodes count] > 0) {
         NSXMLNode *pagesNode = [pagesNodes objectAtIndex:0]; // Only use the first such node.
         
         [rd setObject:[pagesNode stringValue]
                forKey:@"pages"];
     }  
     
     // find URI
     
     NSArray *URINodes = [citationNode descendantOrSelfNodesWithClassName:@"uri" error:&err];
     
     if([URINodes count] > 0) {
         NSXMLNode *URINode = [URINodes objectAtIndex:0]; // Only use the first such node.
         NSString *URIString = nil;
         
         if([[URINode name] isEqualToString:@"a"]){
             URIString = [URINode stringValueOfAttribute:@"href"];
         }else{
             URIString = [URINode fullStringValueIfABBR];
         }
         
         [rd setObject:URIString
                forKey:@"URI"];
         
         if([URIString hasPrefix:@"http://"]){
             [rd setObject:URIString forKey:@"Url"];
         }
     }  
     
     // get container info: 
     // *** NOTE: should do this last, to avoid overwriting data
     
     NSArray *containerNodes = [citationNode descendantOrSelfNodesWithClassName:@"container"
                                                                          error:&err];
     
     if([containerNodes count] > 0) {
         NSXMLNode *containerNode = [containerNodes objectAtIndex:0];
         
         if([[containerNode classNames] containsObject:@"hcite"]){
             NSString *citationType = [rd objectForKey:@"Type"];
             
             NSMutableDictionary *containerDict = [NSMutableDictionary dictionaryWithDictionary:[BDSKHCiteParser dictionaryFromCitationNode:containerNode]];
             NSString *containerTitle = [containerDict objectForKey:@"Title"];
             NSString *containerType = [containerDict objectForKey:@"Type"];
             
             if(containerType != nil && containerTitle != nil){
                 // refine type based on container type
                 if([citationType isEqualToString:@"misc"]){
                     if([containerType isEqualToString:@"journal"]){
                         [rd setObject:BDSKArticleString
                                forKey:@"Type"];
                     }else if([containerType isEqualToString:@"proceedings"]){
                         [rd setObject:BDSKInproceedingsString
                                forKey:@"Type"];
                     }
            
                 }

                 // refresh:
                 citationType = [rd objectForKey:@"Type"];
                 
                 if([citationType isEqualToString:@"article"]){
                     [rd setObject:containerTitle
                            forKey:@"Journal"];
                 }else if([citationType isEqualToString:@"incollection"] ||
                          [citationType isEqualToString:@"inproceedings"]){
                     [rd setObject:containerTitle
                            forKey:@"Booktitle"];
                 }else if([citationType isEqualToString:@"inbook"]){
                     // TODO: this case may need some tweaking
                     [rd setObject:[rd objectForKey:@"Title"]
                            forKey:@"Chapter"];
                     [rd setObject:containerTitle
                            forKey:@"Title"];
                 }else{
                     [rd setObject:containerTitle
                            forKey:@"ContainerTitle"];
                 }
             }
             // Containers have more info than just title and type:
             // TODO: do we only dump it in or do we need to do more?
             [containerDict removeObjectsForKeys:[rd allKeys]];
             [rd addEntriesFromDictionary:containerDict];
         }
         
     }
     
     return rd;
}

+ (NSString *)BTAuthorStringFromVCardNode:(NSXMLNode *)node{
    NSError *err;
    
    // note: may eventually need to do more than just look at fn and abbr.
    NSArray *fnNodes = [node descendantOrSelfNodesWithClassName:@"fn" error:&err];
    
    if([fnNodes count] < 1) return @"";
    
    return [[fnNodes objectAtIndex:0] fullStringValueIfABBR];
}

+ (NSCalendarDate *)dateFromNode:(NSXMLNode *)node{
    
    NSString *fullString = [node fullStringValueIfABBR];
    
    // todo - support other formats
    NSCalendarDate *d = [NSCalendarDate dateWithString:fullString
                                        calendarFormat:@"%Y%m%d"];
    
    if (d) return d;
    
    d = [NSCalendarDate dateWithString:fullString
                                        calendarFormat:@"%Y%m%dT%H%M"];

    if (d) return d;
    
    d = [NSCalendarDate dateWithString:fullString
                                        calendarFormat:@"%Y%m%dT%H%M%z"];
    
    
    d = [NSCalendarDate dateWithString:fullString
                        calendarFormat:@"%Y"]; // degenerate year-only case
    
    if (d) return d;
    
    return d;
}

@end



@implementation NSXMLNode (BDSKExtensions)

- (NSString *)stringValueOfAttribute:(NSString *)attrName{
    NSError *err = nil;
    NSString *path = [NSString stringWithFormat:@"./@%@", attrName];
     NSArray *atts = [self nodesForXPath:path error:&err];
     if ([atts count] == 0) return nil;
     return [[atts objectAtIndex:0] stringValue];
}

- (NSArray *)descendantOrSelfNodesWithClassName:(NSString *)className error:(NSError **)err{
    NSString *path = [NSString stringWithFormat:@".//*[contains(concat(' ', normalize-space(@class), ' '), ' %@ ')]", className];
     NSArray *ar = [self nodesForXPath:path error:err];
     return ar;
}

- (BOOL)hasParentWithClassName:(NSString *)class{
   
    NSXMLNode *parent = [self parent];

    do{
        if([parent kind] != NSXMLElementKind) return NO; // handles root node
        
        NSArray *parentClassNames = [parent classNames];

        if ([parentClassNames containsObject:class]){ 
            return YES;
        }
        
    }while(parent = [parent parent]);
    
    return NO;
}


- (NSArray *)classNames{
    
    if([self kind] != NSXMLElementKind) [NSException raise:NSInvalidArgumentException format:@"wrong node kind"];
    
    NSMutableArray *a = [NSMutableArray arrayWithCapacity:0];
    
    NSError *err = nil;
    
    NSArray *classNodes = [self nodesForXPath:@"@class"
                                        error:&err];
    if([classNodes count] == 0) 
        return a;
    
    NSAssert ([classNodes count] == 1, @"too many nodes in classNodes");
    
    NSXMLNode *classNode = [classNodes objectAtIndex:0];
    
    [a addObjectsFromArray:[[classNode stringValue] componentsSeparatedByString:@" "]];
    
    return a;
}


- (NSString *)fullStringValueIfABBR{
    NSError *err;
    if([self kind] != NSXMLElementKind) [NSException raise:NSInvalidArgumentException format:@"wrong node kind"];
    
    if([[self name] isEqualToString:@"abbr"]){
        //todo: will need more robust comparison for namespaced node titles.
        
        // return value of title attribute instead
        NSArray *titleNodes = [self nodesForXPath:@"@title"
                                            error:&err];
        if([titleNodes count] > 0){
            return [[titleNodes objectAtIndex:0] stringValue];
        }            
    }
    
    return [self stringValue];
}

@end