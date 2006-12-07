//
//  BibFiler.m
//  Bibdesk
//
//  Created by Michael McCracken on Fri Apr 30 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BibFiler.h"

static BibFiler *_sharedFiler = nil;

@implementation BibFiler

+ (BibFiler *)sharedFiler{
	if(!_sharedFiler){
		_sharedFiler = [[BibFiler alloc] init];
	}
	return _sharedFiler;
}

- (void)filePapers:(NSArray *)papers fromDocument:(BibDocument *)doc{
	NSFileManager *fm = [NSFileManager defaultManager];
	
	foreach(paper , papers){
		NSString *path = [paper localURLPathRelativeTo:[[(NSDocument *)doc fileName] stringByDeletingLastPathComponent]];
		NSString *fileName = [path lastPathComponent];
		NSString *newPath = [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKPapersFolderPathKey];
		newPath = [newPath stringByAppendingPathComponent:fileName];
		
		if(path){
			if(![path isEqualToString:newPath]){
				NSLog(@"filing path: %@\nnew path: %@", path, newPath);
				
				if(![fm fileExistsAtPath:newPath]){
					if([fm movePath:path toPath:newPath handler:nil]){
						
						NSString *fileURLString = [[NSURL fileURLWithPath:newPath] absoluteString];
						
						[paper setField:@"Local-Url" toValue:fileURLString];
					}else{
						NSLog(@"there was an error moving the file %@", path);
					}
				}else{
					NSLog(@"a file that name is already there"); // Throw a bdskerrobj
				}
				
			}
			
		}
	}
}

@end
