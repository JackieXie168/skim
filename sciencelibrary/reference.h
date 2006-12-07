//
//  reference.h
//  CocoaMed
//
//  Created by Kurt Marek on Mon Mar 18 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>


@interface reference : NSObject <NSCoding> {
    NSString *referencePMID;
    NSString *articleTitle;
    NSMutableArray *articleAuthors;
    NSString *articleJournal;
    NSString *articleAbstract;
    NSString *articleVolume;
    NSString *articleYear;
    NSString *articleIssue;
    NSString *articlePages;
    NSMutableString *articleNotes;
    BOOL newReference;
    NSCalendarDate *articleDate;
    NSString *referenceLink;
    NSURL *URLToPDFFile;
    NSColor *referenceTextColor;
    NSMutableArray *keywords;

}

//- (void)associatePDFFileWithArticle;
-(void) loadReference:(NSString *)referenceID;
-(void) loadWholeReference;
-(void) loadReferenceFromXML:(NSString *)referenceXML;
-(NSMutableArray *)extractAuthors:(NSString *)authorxml;

-(void)renameFile;


-(NSMutableArray *)keywords;
-(void)setKeywords:(NSMutableArray *)array;

-(void)setReferenceTextColor:(NSColor *) newColor;
-(NSColor *)referenceTextColor;

-(NSString *)referencePMID;
-(void)setReferencePMID:(NSString *)newReferencePMID;

-(NSString *)articleTitle;
-(void)setArticleTitle:(NSString *)title;
-(NSString *)articleAuthors;
-(void)setArticleTitle:(NSString *)title;

-(void)setArticleAuthors:(NSMutableArray *)authors;
-(NSString *)articleJournal;
-(void)setArticleJournal:(NSString *)journal;
-(NSString *)articleAbstract;
-(void) setArticleAbstract:(NSString *)abstractText;

-(NSMutableString *)articleNotes;
-(void) setArticleNotes:(NSMutableString *)noteText;

-(NSString *)articleVolume;
-(void)setArticleVolume:(NSString *)aVolume;
-(NSString *)articleIssue;
-(void)setArticleIssue:(NSString *)anIssue;
-(NSString *)articlePages;
-(void)setArticlePages:(NSString *)aPages;
-(BOOL)newReference;
-(void)setNewReference:(BOOL)yn;
-(NSString *)articleYear;
-(void)setArticleYear:(NSString *)aYear;
-(void) setArticleDateWithYear:(NSString *) aYear withMonth:(NSString *) aMonth withDay:(NSString *) aDay;
-(NSString *)articleDateString;
-(NSCalendarDate *)articleDate;
-(void) setReferenceLink:(NSString *) link;
-(NSString *)referenceLink;
- (NSURL *) URLToPDFFile;
- (void) setURLToPDFFile: (NSURL *) newURL;

- (void) encodeWithCoder:(NSCoder *)coder;
- (id) initWithCoder:(NSCoder *) coder;
-(NSComparisonResult) compareByYear:(reference *) toReference;

@end
