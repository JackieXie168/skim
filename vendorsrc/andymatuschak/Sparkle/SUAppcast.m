//
//  SUAppcast.m
//  Sparkle
//
//  Created by Andy Matuschak on 3/12/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import "SUAppcast.h"
#import "SUAppcastItem.h"
#import "SUUtilities.h"

@implementation SUAppcast

- (void)fetchAppcastFromURL:(NSURL *)url
{
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
            
    data = [[NSMutableData alloc] init];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [connection retain];
}

- (void)setDelegate:del
{
	delegate = del;
}

- (void)dealloc
{
	[data release];
	[items release];
	[super dealloc];
}

- (SUAppcastItem *)newestItem
{
	return [items count] ? [items objectAtIndex:0] : nil; // we take care of sorting by published date, descending.
}

- (NSArray *)items
{
	return items;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
	return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)incrementalData
{
	[data appendData:incrementalData];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[connection release];
	
    if ([delegate respondsToSelector:@selector(appcastDidFailToLoad:)])
		[delegate appcastDidFailToLoad:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[connection release];
	
	NSError *error = nil;
    NSXMLDocument *document = nil;
	NSArray *xmlItems = nil;
	NSMutableArray *appcastItems = [NSMutableArray array];
    BOOL failed = NO;
	
    if ([data length])
        document = [[NSXMLDocument alloc] initWithData:data options:0 error:&error];
    
    if (document == nil) {
        failed = YES;
	} else {
        xmlItems = [document nodesForXPath:@"/rss/channel/item" error:&error];
        if (nil == xmlItems)
            failed = YES;
	}
	
	if (failed == NO) {
		
		NSEnumerator *nodeEnum = [xmlItems objectEnumerator];
		NSXMLNode *node;
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		
		while (failed == NO && (node = [nodeEnum nextObject])) {
			
			// walk the children in reverse
			node = [[node children] lastObject];
			while (nil != node) {
				
				NSString *name = [node name];
				
				if ([name isEqualToString:@"enclosure"]) {
					// enclosure is flattened as a separate dictionary for some reason
					NSEnumerator *attributeEnum = [[(NSXMLElement *)node attributes] objectEnumerator];
					NSXMLNode *attribute;
					NSMutableDictionary *encDict = [NSMutableDictionary dictionary];
					
					while ((attribute = [attributeEnum nextObject]))
						[encDict setObject:[attribute stringValue] forKey:[attribute name]];
					
					[dict setObject:encDict forKey:@"enclosure"];
					
				} else if ([name isEqualToString:@"pubDate"]) {
					// pubDate is expected to be an NSDate by SUAppcastItem, but the RSS class was returning an NSString
					NSDate *date = [NSDate dateWithNaturalLanguageString:[node stringValue]];
					if (date)
						[dict setObject:date forKey:name];
				} else {
					// add all other values as strings
					[dict setObject:[node stringValue] forKey:name];
				}
				
				// previous sibling; returns nil when exhausted
				node = [node previousSibling];
			}
			SUAppcastItem *anItem = [[SUAppcastItem alloc] initWithDictionary:dict];
            if (anItem == nil) {
                failed = YES;
            } else {
                [appcastItems addObject:anItem];
                [anItem release];
            }
			[dict removeAllObjects];
		}
	}
	
	[document release];
	
	if ([appcastItems count]) {
		NSSortDescriptor *sort = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
		[appcastItems sortUsingDescriptors:[NSArray arrayWithObject:sort]];
		items = [appcastItems copy];
	}
	
	if (failed && [delegate respondsToSelector:@selector(appcastDidFailToLoad:)])
		[delegate appcastDidFailToLoad:self];
	else if (NO == failed && [delegate respondsToSelector:@selector(appcastDidFinishLoading:)])
		[delegate appcastDidFinishLoading:self];
}

@end
