//
//  BDSKFileContentsFilter.m
//  BibDesk
//
//  Created by Michael McCracken on Tue May 04 2004.
/*
 This software is Copyright (c) 2004,2005
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

#import "BDSKFileContentsFilter.h"

static BDSKFileContentsFilter *sharedFileContentsFilter = nil;

@implementation BDSKFileContentsFilter

+ (BDSKFileContentsFilter *)sharedFileContentsFilter{
	if(!sharedFileContentsFilter){
		sharedFileContentsFilter = [[BDSKFileContentsFilter alloc] init];
	}
	return sharedFileContentsFilter;
}

- (void)setupIndex{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *applicationSupportPath = [[[NSFileManager defaultManager] applicationSupportDirectory:kUserDomain] stringByAppendingPathComponent:@"BibDesk"] ;

	NSString *indexFileName = [applicationSupportPath stringByAppendingPathComponent:@"File Contents Index"];
	NSURL *indexFileURL = [NSURL fileURLWithPath:indexFileName];
	
	if([fm fileExistsAtPath:indexFileName]){
		[fm removeFileAtPath:indexFileName handler:nil];
	}
	
	index = SKIndexCreateWithURL( (CFURLRef)indexFileURL,
				       (CFStringRef)@"BibDesk File Contents Index",
				       kSKIndexInvertedVector, // larger, but useful for searching for similar docs, which we'll want to do
				       NULL);
	SKLoadDefaultExtractorPlugIns();
}

- (void)indexFilesFromDocument:(BibDocument *)doc{
	NSArray *pubs = [doc publications];
	foreach(pub, pubs){
		NSString *path = [pub localURLPath];
		if(path){
			NSURL *url = [NSURL fileURLWithPath:path];
			[self indexFileAtURL:url fromPub:pub inDocument:doc];
		}
	}
}

- (void)indexFileAtURL:(NSURL *)url fromPub:(BibItem *)pub inDocument:(BibDocument *)doc{
	NSLog(@"indexing %@",[url absoluteString]);
	NSAssert(index != nil, @"Index is nil");
	
	SKDocumentRef skDoc = SKDocumentCreateWithURL((CFURLRef) url);
		
	Boolean success = SKIndexAddDocument(index,skDoc,NULL,true);
	
	if(!success){
		[NSException raise:@"IndexAddDocumentException" 
					format:@"Failed to create document ref for file at %@", [url absoluteString]];
	}
	
	NSDictionary *propDict = [NSDictionary dictionaryWithObjectsAndKeys:@"docFileName",[doc fileName],@"pubCiteKey", [pub citeKey],nil];
	SKIndexSetDocumentProperties(index, skDoc, (CFDictionaryRef) propDict);
	
	CFRelease(skDoc);
	
}

- (NSArray *)filesMatchingQuery:(NSString *)query inDocument:(BibDocument *)doc{
	int maxResults = 15;  // @@ pref
	
	if(!index){
		[NSException raise:@"IndexNotThereException" 
					format:@"There is no index in filesMatchingQuery"];
	}
	
	SKIndexRef indexArray[1];
	indexArray[0] = index;
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
			  (NSDictionary *) SKIndexCopyDocumentProperties (index, outDocumentsArray[i])
			  );
		
	}
	return [NSArray array];
}

@end
