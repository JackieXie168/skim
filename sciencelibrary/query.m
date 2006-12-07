//
//  query.m
//  CocoaMed
//
//  Created by Kurt Marek on Mon Mar 18 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "query.h"
#import "XMLParser.h"
#import "reference.h"

@implementation query
-(id) init
{
    if (self =[super init]) {
        //[self setReferenceDictionary:[NSMutableDictionary dictionary]];
        [self setNewReferenceArray:[NSMutableArray array]];
	[self setReferenceArray:[NSMutableArray array]];
        [self setNumberOfNewReferences:[NSNumber numberWithInt: 0]];
	searchTextColor=[NSColor blackColor];
    }
    return self;
}

////////////////////
//Instance Methods//
////////////////////

-(void)performSearchInNewThread:(NSArray *)argArray {
    
    NSString *aSearchString=[argArray objectAtIndex:1];
    id sender=[argArray objectAtIndex:0];
    id referenceController=[argArray objectAtIndex:2];
    
    //create autorelease pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [sender performSelectorOnMainThread:@selector(toggleSearchProgressIndicatorOn) withObject:nil waitUntilDone:NO];
    
    //get contents of search URL
    NSString *searchString=[NSString stringWithFormat:@"http://www.ncbi.nlm.nih.gov/entrez/utils/pmqty.fcgi?db=PubMed&term=%@&dopt=d&dispmax=%@&mode=xml",[self fixSearchString:aSearchString], [[NSUserDefaults standardUserDefaults] objectForKey:@"maxRefsToRetrieve"]];
    NSURL *searchURL=[NSURL URLWithString:searchString];
    NSString *searchResultString=[NSString stringWithContentsOfURL:searchURL];
    
    NSString *idString=[XMLParser parse:searchResultString withBeginningTag:@"<Id>" withEndingTag:@"</Id>"];
    [self setNumberOfTotalReferences:[NSNumber numberWithInt:[[XMLParser parse:searchResultString withBeginningTag:@"<Count>" withEndingTag:@"</Count>"] intValue]]];
    [self setDisplayStart:[[NSNumber numberWithInt:[[XMLParser parse:searchResultString withBeginningTag:@"<DispStart>" withEndingTag:@"</DispStart>"] intValue]] intValue]];
    [self setDisplayMax:[[NSNumber numberWithInt:[[XMLParser parse:searchResultString withBeginningTag:@"<DispMax>" withEndingTag:@"</DispMax>"] intValue]] intValue]];
    
    
    //set queryTitle and referenceLastChecked
    [self setQueryTitle:aSearchString];
    [self setTimeReferenceLastChecked:[NSCalendarDate calendarDate]];
    
    //call searchForIDs
    if ([[self numberOfTotalReferences] intValue]!=0) {
	NSLog(@"search for ids");
	[self searchForIDs:idString withReferenceController:referenceController];
    }

    else {
	NSLog(@"alert panel");
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:@"No results were returned for your search."];
	[alert setInformativeText:@"Check your search terms and try again."];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert runModal];
	
	
	[alert release];
    }

    [sender performSelectorOnMainThread:@selector(toggleSearchProgressIndicatorOff) withObject:nil waitUntilDone:NO];
    [pool release];
    return;
}


-(void)performSearch:(NSString *)aSearchString {

    //get contents of search URL
    NSString *searchString=[NSString stringWithFormat:@"http://www.ncbi.nlm.nih.gov/entrez/utils/pmqty.fcgi?db=PubMed&term=%@&dopt=d&dispmax=50&mode=xml",[self fixSearchString:aSearchString]];
    NSURL *searchURL=[NSURL URLWithString:searchString];
    NSString *searchResultString=[NSString stringWithContentsOfURL:searchURL];
   
    NSString *idString=[XMLParser parse:searchResultString withBeginningTag:@"<Id>" withEndingTag:@"</Id>"];
    [self setNumberOfTotalReferences:[NSNumber numberWithInt:[[XMLParser parse:searchResultString withBeginningTag:@"<Count>" withEndingTag:@"</Count>"] intValue]]];
    [self setDisplayStart:[[NSNumber numberWithInt:[[XMLParser parse:searchResultString withBeginningTag:@"<DispStart>" withEndingTag:@"</DispStart>"] intValue]] intValue]];
    [self setDisplayMax:[[NSNumber numberWithInt:[[XMLParser parse:searchResultString withBeginningTag:@"<DispMax>" withEndingTag:@"</DispMax>"] intValue]] intValue]];
    
    
    //set queryTitle and referenceLastChecked
    [self setQueryTitle:aSearchString];
    [self setTimeReferenceLastChecked:[NSCalendarDate calendarDate]];
    
    //call searchForIDs
    if (![idString isEqual:@""]) {
	NSLog(@"search for ids");
	[self searchForIDs:idString];
    }
    return;
}

-(void)searchForIDs:(NSString *) stringOfIDs withReferenceController:(id) referenceController{
    NSScanner *idScanner=[NSScanner scannerWithString:stringOfIDs];
    NSURL *referencesURL;
    NSMutableString *idList=[NSMutableString string];
    NSString *idInstance;
    NSString *referencesString;
    NSString *referencesResultString;
    NSScanner *articleScanner;
    NSString *articleInstance;
    reference *newReference;
    NSLog(@"string of ids=%@",stringOfIDs);
    //replace spaces in stringOfIDS with commas (?)
    while ([idScanner isAtEnd]==NO) {
        [idScanner scanUpToString:@" " intoString:&idInstance];
        [idList appendString:idInstance];
        [idList appendString:@","];
    }
    [idList deleteCharactersInRange:NSMakeRange([idList length]-1,1)];
    
    //get all references from IDs
    NSLog(@"idList=%@",idList);
    referencesString=[NSString stringWithFormat:@"http://www.ncbi.nlm.nih.gov/entrez/utils/pmfetch.fcgi?db=PubMed&id=%@&report=xml&mode=text", idList];
    referencesURL=[NSURL URLWithString:referencesString];
    referencesResultString=[NSString stringWithContentsOfURL:referencesURL];
    articleScanner=[NSScanner scannerWithString:referencesResultString];
    //[referenceDictionary removeAllObjects];
    
    //extract each reference and create a new reference object, put it into referenceArray
    while ([articleScanner isAtEnd]!=YES) {
        [articleScanner scanUpToString:@"<PubmedArticle>" intoString:NULL];
        if ([articleScanner scanUpToString:@"</PubmedArticle>" intoString:&articleInstance]==YES) {
	    
	    newReference=[[reference alloc] init];
	    
	    [newReference loadReferenceFromXML:articleInstance];
	   // [referenceArray addObject:newReference];
	    [referenceController addObject:newReference];
	    
	    //
	    //[referenceDictionary setObject:newReference forKey:[newReference referencePMID]];
	    //
	    [newReference release];
	}
        
    }
  
}    



-(NSString *)fixSearchString:(NSString *)stringToFix {
    NSScanner *fixScanner;
    NSString *fixedString=[NSString string];
    NSString *partOfFixedString=[NSString string];
    NSCharacterSet *charactersToRemove;
    charactersToRemove=[NSCharacterSet characterSetWithCharactersInString:@", "];
    fixScanner=[NSScanner scannerWithString:stringToFix];

    while ([fixScanner isAtEnd]==NO) {
        [fixScanner scanUpToCharactersFromSet:charactersToRemove intoString:&partOfFixedString];
        fixedString=[fixedString stringByAppendingString:@"+"];
        fixedString=[fixedString stringByAppendingString:partOfFixedString];
        [fixScanner scanCharactersFromSet:charactersToRemove intoString:NULL];
      
    }
    
    return fixedString;
}

-(void)checkForNewRefs:(id)sender {
    NSLog(@"query check for new");
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [sender performSelectorOnMainThread:@selector(toggleSearchProgressIndicatorOn) withObject:nil waitUntilDone:NO];

    NSString *idInstance;
    NSString *searchString=[NSString stringWithFormat:@"http://www.ncbi.nlm.nih.gov/entrez/utils/pmqty.fcgi?db=PubMed&term=%@&dopt=d&dispmax=20&mode=xml",[self fixSearchString:[self queryTitle]]];
    NSURL *searchURL=[NSURL URLWithString:searchString];
    NSString *searchResultString=[NSString stringWithContentsOfURL:searchURL];
    NSNumber *newTotal=[NSNumber numberWithInt:[[XMLParser parse:searchResultString withBeginningTag:@"<Count>" withEndingTag:@"</Count>"] intValue]];
    NSString *idString=[XMLParser parse:searchResultString withBeginningTag:@"<Id>" withEndingTag:@"</Id>"];
    NSScanner *idScanner=[NSScanner scannerWithString:idString];
    [self setNewReferenceArray:[NSMutableArray array]];
    [self setNumberOfNewReferences:[NSNumber numberWithInt:([newTotal intValue])-([[self numberOfTotalReferences] intValue])]];
    reference *nextOldRef;
    NSMutableArray *oldRefIDs=[[NSMutableArray alloc] init];
    NSMutableString *newIDString=[[NSMutableString alloc] init];

    if ([numberOfNewReferences intValue]>0) {
	
	searchTextColor=[NSColor redColor];
	
	NSEnumerator *oldRefsEnumerator = [referenceArray objectEnumerator];
	
	while (nextOldRef=[oldRefsEnumerator nextObject]) {
	    [oldRefIDs addObject:[nextOldRef referencePMID]];
	}
	
	while ([idScanner isAtEnd]==NO) {
	    [idScanner scanUpToString:@" " intoString:&idInstance];
	    
	    if ([oldRefIDs containsObject:idInstance] !=YES) {
		[newReferenceArray addObject:idInstance];
	    }
	}
	NSEnumerator *newRefsEnumerator = [newReferenceArray objectEnumerator];
	NSString *nextNewRef;
	while (nextNewRef=[newRefsEnumerator nextObject]) {
	    [newIDString appendString:nextNewRef];
	    [newIDString appendString:@" "];
	    
	}
	
    }
    else {
	searchTextColor=[NSColor blackColor];
    }
    [self setTimeReferenceLastChecked:[NSCalendarDate calendarDate]];
    [self setNumberOfTotalReferences:newTotal];
        if ([newReferenceArray count]>0) {
	[self searchForIDs:newIDString];
    }
    [sender performSelectorOnMainThread:@selector(toggleSearchProgressIndicatorOff) withObject:nil waitUntilDone:NO];
    [oldRefIDs release];
    [pool release];
    return;
}

/*
-(void)addNewRefs {

    reference *newReference;
    NSEnumerator *newIDEnumerator = [newReferenceArray objectEnumerator];
    NSString *thisNewID;
    //NSLog(@"newRefArray=%@",newReferenceArray);
    while (thisNewID=[newIDEnumerator nextObject]) {
        newReference=[[reference alloc] init];
        [newReference loadReference:thisNewID];
	
        //[newReference setNewReference:YES]; 
        //[referenceDictionary setObject:newReference forKey:thisNewID];
        [newReference release];
    }

}
*/


//Accessor Methods

-(NSNumber *)numberOfNewReferences {
    return numberOfNewReferences;
}
-(NSString *)stringOfNumberOfNewReferences {
    return [numberOfNewReferences stringValue];
}


-(void)setNumberOfNewReferences:(NSNumber *)newRefs {
    [newRefs retain];
    [numberOfNewReferences release];
    numberOfNewReferences=newRefs;
}

/*
-(NSMutableDictionary *)referenceDictionary {
    return referenceDictionary;
}
-(void)setReferenceDictionary:(NSMutableDictionary *)dictionary {
    [dictionary retain];
    [referenceDictionary release];
    referenceDictionary=dictionary;
}
*/

-(NSMutableArray *)referenceArray {
    return referenceArray;
}
-(void)setReferenceArray:(NSMutableArray *)array {
    [array retain];
    [referenceArray release];
    referenceArray=array;
}


-(NSMutableArray *)newReferenceArray {
    return newReferenceArray;
}
-(void) setNewReferenceArray:(NSMutableArray *)array {
    [array retain];
    [newReferenceArray release];
    newReferenceArray=array;
    //NSLog(@"newReferenceArray in accessor=%@",newReferenceArray);
}

-(NSString *)queryTitle {
    return queryTitle;
}
-(void)setQueryTitle:(NSString *)title {
    [title retain];
    [queryTitle release];
    queryTitle=title;
}

-(void) setTimeReferenceLastChecked:(NSCalendarDate *) currentTime {
    if (currentTime==nil) {
        timeReferenceLastChecked=[NSCalendarDate calendarDate];
    }
    else {
        [currentTime retain];
        [timeReferenceLastChecked release];
        
        timeReferenceLastChecked=currentTime;
    }
}
-(NSString *)timeReferenceLastChecked {
    [timeReferenceLastChecked setCalendarFormat:@"%b %d, %Y: %I:%M %p"];
    return [timeReferenceLastChecked description];
}

-(NSNumber *)numberOfTotalReferences {
    return numberOfTotalReferences;
}
-(void)setNumberOfTotalReferences:(NSNumber *) totRefs {
    [totRefs retain];
    [numberOfTotalReferences release];
    numberOfTotalReferences=totRefs;
}


-(int)displayStart {
    return displayStart;
}

-(void)setDisplayStart:(int)dispStart {
    displayStart=dispStart;
}

-(int)displayMax {
    return displayMax;
}

-(void)setDisplayMax:(int)dispMax {
    displayMax=dispMax;
}



-(NSString *)folderName {
    return queryTitle;
}


//Encoding Methods

- (void) encodeWithCoder:(NSCoder *)coder {
    //[coder encodeValueOfObjCType:@encode(int) at:&numberOfNewReferences];
    [coder encodeObject:numberOfTotalReferences];
    [coder encodeObject:numberOfNewReferences];
    //[coder encodeObject:referenceDictionary];
    [coder encodeObject:referenceArray];
    [coder encodeObject:queryTitle];
    [coder encodeObject:timeReferenceLastChecked];
}

- (id) initWithCoder:(NSCoder *) coder {
    if (self=[super init]) {
       // [coder decodeValueOfObjCType:@encode(int) at:&numberOfNewReferences];
        [self setNumberOfTotalReferences:[coder decodeObject]];
        [self setNumberOfNewReferences:[coder decodeObject]];
        // [self setReferenceDictionary:[coder decodeObject]];
	[self setReferenceArray:[coder decodeObject]];
        [self setQueryTitle:[coder decodeObject]];
        [self setTimeReferenceLastChecked:[coder decodeObject]];
    }
    return self;
}

@end
