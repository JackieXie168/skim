//
//  BDSKHCiteParser.m
//
//  Created by Michael McCracken on 11/1/06.
//

#import "BDSKHCiteParser.h"

@interface NSXMLNode (BDSKExtensions)
- (NSString *)stringValueOfAttribute:(NSString *)attrName;
- (NSArray *)descendantOrSelfNodesWithClassName:(NSString *)className error:(NSError **)err;
- (BOOL)hasParentWithClassName:(NSString *)class;
- (NSArray *)classNames;
- (NSString *)fullStringValueIfABBR;

@end

@interface BDSKHCiteParser (internal)
+ (NSCalendarDate *)dateFromNode:(NSXMLNode *)node;
+ (NSString *)BTAuthorStringFromVCardNode:(NSXMLNode *)node;
+ (NSMutableDictionary *)dictionaryFromCitationNode:(NSXMLNode *)citationNode;

@end


@implementation BDSKHCiteParser


+ (NSArray *)itemsFromXHTMLString:(NSString *)XHTMLString error:(NSError **)error{

    NSMutableArray *items = [NSMutableArray arrayWithCapacity:0];
    
    NSError *err = nil;
    
    NSXMLDocument *doc = [[NSXMLDocument alloc] initWithXMLString:XHTMLString
                                                          options:NSXMLDocumentTidyHTML error:&err];
    if(doc == nil && err){
        error = &err;
        return items;
    }
    
    NSString *containsCitationPath = @".//*[contains(concat(' ', normalize-space(@class), ' '),' hcite ')]";
    
    NSArray *mainNodes = [[doc rootElement] nodesForXPath:containsCitationPath
                                                    error:&err];
    
    unsigned int i, count = [mainNodes count];
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


@implementation BDSKHCiteParser (internal)

+ (NSMutableDictionary *)dictionaryFromCitationNode:(NSXMLNode *)citationNode{
    BibTypeManager *typeMan = [BibTypeManager sharedManager];
    NSMutableDictionary *rd = [NSMutableDictionary dictionaryWithCapacity:0];
    
    NSError *err = nil;
    unsigned int i = 0;
    
    // find type 
    NSArray *typeNodes = [citationNode descendantOrSelfNodesWithClassName:@"type" error:&err];
    
    if([typeNodes count] > 0){
        NSString *typeString = [[typeNodes objectAtIndex:0] fullStringValueIfABBR];
        [rd setObject:[typeMan bibtexTypeForHCiteType:typeString]
               forKey:@"Type"];
    }else{
        [rd setObject:@"misc" forKey:@"Type"];
    }
    
    
    // find title node
    
    // TODO temporary: will title be represented as fn or title in final hcite?
    // for now we read both.
    NSMutableArray *titleNodes = [NSMutableArray arrayWithCapacity:0];
    [titleNodes addObjectsFromArray:[citationNode descendantOrSelfNodesWithClassName:@"fn" error:&err]];
    [titleNodes addObjectsFromArray:[citationNode descendantOrSelfNodesWithClassName:@"title" error:&err]];
    
    for(i = 0; i < [titleNodes count]; i++){
        NSXMLNode *node = [titleNodes objectAtIndex:i];
        if([node hasParentWithClassName:@"vcard"] ||
           [node hasParentWithClassName:@"container"]){
            // note: todo - avoid second hasParentWithClassName by finding container nodes first and caching those then checking against them here. (if necessary)
            continue;
        }
        
        [rd setObject:[node stringValue] forKey:@"Title"];
    }
    
    // find authors
    // note, should only find ones that contain 'vcard' as well but for now we ignore it
    
    NSArray *authorNodes = [citationNode descendantOrSelfNodesWithClassName:@"creator" error:&err];
    NSMutableString *BTAuthString = [NSMutableString stringWithCapacity:0];
    
    for(i = 0; i < [authorNodes count]; i++){
        NSXMLNode *node = [authorNodes objectAtIndex:i];
        
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
         [rd setObject:[NSString stringWithFormat:@"%d", [datePublished yearOfCommonEra]] // how is this done in BD?
                forKey:@"Year"];
         [rd setObject:[NSString stringWithFormat:@"%d", [datePublished monthOfYear]]
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