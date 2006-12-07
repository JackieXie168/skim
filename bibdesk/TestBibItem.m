//
//  TestBibItem.m
//  Bibdesk
//
//  Created by Michael McCracken on Thu Nov 28 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "TestBibItem.h"
static NSString *oneItem = @"@inproceedings{Lee96RTOptML,\nYear = {1996},\nUrl = {http://citeseer.nj.nec.com/70627.html},\nTitle = {Optimizing ML with Run-Time Code Generation},\nBooktitle = {PLDI},\nAuthor = {Peter Lee and Mark Leone}}";
static NSString *twoItems = @"@inproceedings{Lee96RTOptML,\nYear = {1996},\nUrl = {http://citeseer.nj.nec.com/70627.html},\nTitle = {Optimizing ML with Run-Time Code Generation},\nBooktitle = {PLDI},\nAuthor = {Peter Lee and Mark Leone}}\n\n@inproceedings{yang01LoopTransformPowerImpact,\nYear = {2001},\nTitle = {Power and Energy Impact by Loop Transformations},\nBooktitle = {COLP '01},\nAuthor = {Hongbo Yang and Guang R. Gao and Andres Marquez and George Cai and Ziang Hu}}";

@implementation TestBibItem
- (void)testInitWithType{
    BibItem *b = [[BibItem alloc] initWithType:@"incollection"
                                      fileType:@"BibTeX"
                                       authors:[NSMutableArray arrayWithObjects:@"Less, von More, Jr.",nil]];
    UKIntsEqual(1, [b numberOfAuthors]);

}

- (void)testFileOrder{
    // init two bibitems, then check that the difference in their fileorder is one
    BOOL error = NO;
	NSData *twoItemsData = [twoItems dataUsingEncoding:NSASCIIStringEncoding];
    NSMutableArray *testArray = [BibTeXParser itemsFromData:twoItemsData
													  error:&error
												frontMatter:nil
												   filePath:@"testFileOrder"];
    BibItem *item1 = [testArray objectAtIndex:0];
    BibItem *item2 = [testArray objectAtIndex:1];

    UKNotNil(testArray);
    UKIntsEqual(2, [testArray count]);

    UKObjectsNotEqual([item1 fileOrder], [item2 fileOrder]);
}

- (void)testFieldOrder{
    // init two bibitems from same string, change two fields each (identically but in different order) then test that their bibtexvalues are equal.
    // init two bibitems, then check that the difference in their fileorder is one
    BOOL error = NO;
	NSData *oneItemData = [oneItem dataUsingEncoding:NSASCIIStringEncoding];
    NSMutableArray *testArray = [BibTeXParser itemsFromData:oneItemData
													  error:&error
												frontMatter:nil
												   filePath:@"testFieldOrder"];
    BibItem *item1 = [testArray objectAtIndex:0];
    
    BibItem *item2 = [item1 copy];

    UKNotNil(testArray);
    UKIntsEqual(1, [testArray count]);

    [item1 setField:@"Author" toValue:@"foo"];
    [item1 setField:@"Year" toValue:@"2000"];

    [item2 setField:@"Year" toValue:@"2000"];
    [item2 setField:@"Author" toValue:@"foo"];

    UKStringsEqual([item1 bibTeXString], [item2 bibTeXString]);
}

- (void)testMakeTypeBibTeX{
    BOOL error = NO;
	NSData *oneItemData = [oneItem dataUsingEncoding:NSASCIIStringEncoding];
    NSMutableArray *testArray = [BibTeXParser itemsFromData:oneItemData
													  error:&error
												frontMatter:nil
												   filePath:@"testFieldOrder"];
    BibItem *item1 = [testArray objectAtIndex:0];
    NSString *firstType = [item1 type];
    NSEnumerator *typeE = [[[BibTypeManager sharedManager] bibTypesForFileType:@"BibTeX"] objectEnumerator];
    NSString *aType = nil;
    NSString *beforeString = [item1 bibTeXString];
    
    while(aType = [typeE nextObject]){
        [item1 makeType:aType];
    }
    [item1 makeType:firstType];
    UKStringsEqual(beforeString, [item1 bibTeXString]);
}

@end
