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
	[NSThread detachNewThreadSelector:@selector(_fetchAppcastFromURL:) toTarget:self withObject:url]; // let's not block the main thread
}

- (void)setDelegate:del
{
	delegate = del;
}

- (void)dealloc
{
	[items release];
	[super dealloc];
}

- (SUAppcastItem *)newestItem
{
	return [items count] ? [items objectAtIndex:0] : nil; // the RSS class takes care of sorting by published date, descending.
}

- (NSArray *)items
{
	return items;
}

- (void)_fetchAppcastFromURL:(NSURL *)url
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSError *error = nil;
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
    NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSXMLDocument *document = nil;
    
    if (data)
        document = [[NSXMLDocument alloc] initWithData:data options:0 error:&error];
        
	BOOL failed = NO;
	
	if (nil == document)
		failed = YES;
		
	NSArray *xmlItems = [document nodesForXPath:@"/rss/channel/item" error:&error];
	if (nil == xmlItems)
		failed = YES;
	
	NSMutableArray *appcastItems = [NSMutableArray array];
	
	if (xmlItems) {
		
		NSEnumerator *nodeEnum = [xmlItems objectEnumerator];
		NSXMLNode *node;
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		
		while ((node = [nodeEnum nextObject])) {
			
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
			[appcastItems addObject:anItem];
			[anItem release];
			[dict removeAllObjects];
		}
	}
	
	if ([appcastItems count]) {
		NSSortDescriptor *sort = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
		[appcastItems sortUsingDescriptors:[NSArray arrayWithObject:sort]];
		items = [appcastItems copy];
	}
	
	if (failed && [delegate respondsToSelector:@selector(appcastDidFailToLoad:)])
		[delegate performSelectorOnMainThread:@selector(appcastDidFailToLoad:) withObject:self waitUntilDone:NO];
	else if (NO == failed && [delegate respondsToSelector:@selector(appcastDidFinishLoading:)])
		[delegate performSelectorOnMainThread:@selector(appcastDidFinishLoading:) withObject:self waitUntilDone:NO];
	
	[document release];
	[pool release];
}

@end
