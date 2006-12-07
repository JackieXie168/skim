//
//  BDSKFileContentsFilter.m
//  Bibdesk
//
//  Created by Michael McCracken on Tue May 04 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BDSKFileContentsFilter.h"

static BDSKFileContentsFilter *_sharedFileContentsFilter = nil;

@implementation BDSKFileContentsFilter

+ (BDSKFileContentsFilter *)sharedFileContentsFilter{
	if(!_sharedFileContentsFilter){
		_sharedFileContentsFilter = [[BDSKFileContentsFilter alloc] init];
	}
	return _sharedFileContentsFilter;
}

- (void)setupIndex{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *applicationSupportPath = [[[NSFileManager defaultManager] applicationSupportDirectory:kUserDomain] stringByAppendingPathComponent:@"BibDesk"] ;

	NSString *indexFileName = [applicationSupportPath stringByAppendingPathComponent:@"File Contents Index"];
	NSURL *indexFileURL = [NSURL fileURLWithPath:indexFileName];
	
	if([fm fileExistsAtPath:indexFileName]){
		[fm removeFileAtPath:indexFileName handler:nil];
	}
	
	_index = SKIndexCreateWithURL( (CFURLRef)indexFileURL,
				       (CFStringRef)@"BibDesk File Contents Index",
				       kSKIndexInvertedVector, // larger, but useful for searching for similar docs, which we'll want to do
				       NULL);
	SKLoadDefaultExtractorPlugIns();
}

- (void)indexFilesFromDocument:(BibDocument *)doc{
	NSArray *pubs = [doc publications];
	foreach(pub, pubs){
		NSString *path = [pub localURLPathRelativeTo:[[doc fileName] stringByDeletingLastPathComponent]];
		if(path){
			NSURL *url = [NSURL fileURLWithPath:path];
			[self indexFileAtURL:url fromPub:pub inDocument:doc];
		}
	}
}

- (void)indexFileAtURL:(NSURL *)url fromPub:(BibItem *)pub inDocument:(BibDocument *)doc{
	NSLog(@"indexing %@",[url absoluteString]);
	NSAssert(_index != nil, @"Index is nil");
	
	SKDocumentRef skDoc = SKDocumentCreateWithURL((CFURLRef) url);
		
	Boolean success = SKIndexAddDocument(_index,skDoc,NULL,true);
	
	if(!success){
		[NSException raise:@"IndexAddDocumentException" 
					format:@"Failed to create document ref for file at %@", [url absoluteString]];
	}
	
	NSDictionary *propDict = [NSDictionary dictionaryWithObjectsAndKeys:@"docFileName",[doc fileName],@"pubCiteKey", [pub citeKey],nil];
	SKIndexSetDocumentProperties(_index, skDoc, (CFDictionaryRef) propDict);
	
	CFRelease(skDoc);
	
}

- (NSArray *)filesMatchingQuery:(NSString *)query inDocument:(BibDocument *)doc{
	int maxResults = 15;  // @@ pref
	
	if(!_index){
		[NSException raise:@"IndexNotThereException" 
					format:@"There is no index in filesMatchingQuery"];
	}
	
	SKIndexRef indexArray[1];
	indexArray[0] = _index;
	CFArrayRef searchArray = CFArrayCreate(NULL, (void *)indexArray, 1, &kCFTypeArrayCallBacks);
	SKSearchGroupRef searchGroup = SKSearchGroupCreate(searchArray);
	
	SKSearchResultsRef searchResults = SKSearchResultsCreateWithQuery(searchGroup,
																	  (CFStringRef) query,
																	  kSKSearchRanked,
																	  maxResults,
																	  NULL,
																	  NULL);
	
	SKDocumentRef outDocumentsArray[maxResults];
	float scoresArray[maxResults];
	
	CFIndex resultCount = SKSearchResultsGetInfoInRange(searchResults,
														CFRangeMake(0,maxResults),
														outDocumentsArray,
														NULL, //outindexesarray, don't care -- only one index for now.
														scoresArray);
	int i = 0;
	for(i = 0; i< resultCount; i++){
		NSLog(@"sc: %f ___ doc: %@ __ prop: %@",scoresArray[i], 
			  (NSString *) SKDocumentGetName(outDocumentsArray[i]),
			  (NSDictionary *) SKIndexCopyDocumentProperties (_index, outDocumentsArray[i])
			  );
		
	}
	return [NSArray array];
}

@end
