//
//  query.h
//  CocoaMed
//
//  Created by Kurt Marek on Mon Mar 18 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface query : NSObject <NSCoding> {
    NSString *queryTitle;
    NSString *queryName;
    NSArray *referenceIDArray;
    //NSMutableDictionary *referenceDictionary;
    NSMutableArray *referenceArray;
    NSMutableArray *newReferenceArray;
    NSNumber *numberOfNewReferences;
    NSCalendarDate *timeReferenceLastChecked;
    NSNumber *numberOfTotalReferences;
    NSColor *searchTextColor;
    
   // IBOutlet NSArrayController *SLPubmedArrayController;
    int displayStart;
    int displayMax;
}



-(NSString *)queryTitle;
-(void)setQueryTitle:(NSString *)title;
-(void)performSearch:(NSString *)aSearchString;
-(void)performSearchInNewThread:(NSArray *)argArray;


//-(NSMutableDictionary *)referenceDictionary;
//-(void)setReferenceDictionary:(NSMutableDictionary *)dictionary;

-(NSMutableArray *)referenceArray;
-(void)setReferenceArray:(NSMutableArray *)array;

-(NSMutableArray *)newReferenceArray;
-(void) setNewReferenceArray:(NSMutableArray *)array;


-(void) setTimeReferenceLastChecked:(NSCalendarDate *)currentTime;
-(NSString *)timeReferenceLastChecked;
-(NSNumber *)numberOfNewReferences;
-(void)setNumberOfNewReferences:(NSNumber *)newRefs;
-(NSNumber *)numberOfTotalReferences;
-(void)setNumberOfTotalReferences:(NSNumber *) totRefs;
-(void)checkForNewRefs:(id)sender;
-(int)displayStart;
-(void)setDisplayStart:(int)dispStart;
-(int)displayMax;
-(void)setDisplayMax:(int)dispMax;
-(NSString *)fixSearchString:(NSString *)stringToFix;
-(void)addNewRefs;

-(NSString *)folderName;
-(void)searchForIDs:(NSString *) stringOfIDs withReferenceController:(id) referenceController;

- (void) encodeWithCoder:(NSCoder *)coder;
- (id) initWithCoder:(NSCoder *) coder;

@end
