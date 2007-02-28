//
//  TestBibItem.m
//  BibDesk
//
//  Created by Michael McCracken on Thu Nov 28 2002.
/*
 This software is Copyright (c) 2003,2004,2005,2006,2007
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

#import "TestBibItem.h"
static NSString *oneItem = @"@inproceedings{Lee96RTOptML,\nYear = {1996},\nUrl = {http://citeseer.nj.nec.com/70627.html},\nTitle = {Optimizing ML with Run-Time Code Generation},\nBooktitle = {PLDI},\nAuthor = {Peter Lee and Mark Leone}}";
static NSString *twoItems = @"@inproceedings{Lee96RTOptML,\nYear = {1996},\nUrl = {http://citeseer.nj.nec.com/70627.html},\nTitle = {Optimizing ML with Run-Time Code Generation},\nBooktitle = {PLDI},\nAuthor = {Peter Lee and Mark Leone}}\n\n@inproceedings{yang01LoopTransformPowerImpact,\nYear = {2001},\nTitle = {Power and Energy Impact by Loop Transformations},\nBooktitle = {COLP '01},\nAuthor = {Hongbo Yang and Guang R. Gao and Andres Marquez and George Cai and Ziang Hu}}";

@implementation TestBibItem
- (void)testInitWithType{
    BibItem *b = [[BibItem alloc] initWithType:BDSKIncollectionString
                                      fileType:BDSKBibtexString
                                       authors:[NSMutableArray arrayWithObjects:@"Less, von More, Jr.",nil]
                                        isNew:NO];
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

    [item1 setField:BDSKAuthorString toValue:@"foo"];
    [item1 setField:BDSKYearString toValue:@"2000"];

    [item2 setField:BDSKYearString toValue:@"2000"];
    [item2 setField:BDSKAuthorString toValue:@"foo"];

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
    NSEnumerator *typeE = [[[BibTypeManager sharedManager] bibTypesForFileType:BDSKBibtexString] objectEnumerator];
    NSString *aType = nil;
    NSString *beforeString = [item1 bibTeXString];
    
    while(aType = [typeE nextObject]){
        [item1 setType:aType];
    }
    [item1 setType:firstType];
    UKStringsEqual(beforeString, [item1 bibTeXString]);
}

@end
