//
//  reference.m
//  CocoaMed
//
//  Created by Kurt Marek on Mon Mar 18 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "reference.h"
#import "XMLParser.h"

@implementation reference

//Instance Methods

-(id) init {
    if (self =[super init]) {
	[self setReferenceTextColor:[NSColor redColor]];
	[self setKeywords:[[NSMutableArray alloc] init]];
    }
    return self;
}

/*
- (void)associatePDFFileWithArticle {
    
    NSString *result;
    NSOpenPanel *panel=[NSOpenPanel openPanel];
    result = [panel runModalForDirectory:NSHomeDirectory()
                                    file:nil types:[NSImage imageFileTypes]];
    
    if (result !=NSCancelButton) {
        [self setURLToPDFFile:[[panel URLs] objectAtIndex:0]];
        NSLog(@"filename=%@",[[panel URLs] objectAtIndex:0]);
    }
}
*/

-(void) loadReferenceFromXML:(NSString *)referenceXML {
    [self setNewReference:YES];
    [self setReferencePMID: [XMLParser parse:referenceXML withBeginningTag:@"<PMID>" 		withEndingTag:@"</PMID>"]];
    
    [self setArticleJournal:[XMLParser parse:referenceXML withBeginningTag:@"<MedlineTA>" 		withEndingTag:@"</MedlineTA>"]];

    [self setArticleAuthors:[self extractAuthors:[XMLParser parse:referenceXML withBeginningTag:@"<AuthorList" 		withEndingTag:@"</AuthorList>"]]];
    
    [self setArticleAbstract:[XMLParser parse:referenceXML withBeginningTag:@"<AbstractText>" 		withEndingTag:@"</AbstractText>"]];

    [self setArticleVolume:[XMLParser parse:referenceXML withBeginningTag:@"<Volume>" 		withEndingTag:@"</Volume>"]];

    [self setArticleIssue:[XMLParser parse:referenceXML withBeginningTag:@"<Issue>" 		withEndingTag:@"</Issue>"]];

    [self setArticlePages:[XMLParser parse:referenceXML withBeginningTag:@"<MedlinePGN>" 		withEndingTag:@"</MedlinePGN>"]];

    [self setArticleTitle:[XMLParser parse:referenceXML withBeginningTag:@"<ArticleTitle>" 		withEndingTag:@"</ArticleTitle>"]];

    [self setArticleYear:[XMLParser parse:referenceXML withBeginningTag:@"<Year>" withEndingTag:@"</Year>"]];
    
    
    
    [self setArticleDateWithYear:[XMLParser parse:referenceXML withBeginningTag:@"<Year>" withEndingTag:@"</Year>"] withMonth:[XMLParser parse:referenceXML withBeginningTag:@"<Month>" withEndingTag:@"</Month>"] withDay:[XMLParser parse:referenceXML withBeginningTag:@"<Day>" withEndingTag:@"</Day>"] ];
    //NSLog(@"date loaded=%@",[self articleDateString]);
    
}


-(void) loadReference:(NSString *)referenceID {

    NSString *referenceString;
    NSString *referencesResultString;
    NSURL *referenceURL;
  
    [self setReferenceTextColor:[NSColor redColor]];
    [self setReferencePMID:referenceID];

    referenceString=[NSString stringWithFormat:@"http://www.ncbi.nlm.nih.gov/entrez/utils/pmfetch.fcgi?db=PubMed&id=%@&report=xml&mode=text",referenceID];
    referenceURL=[NSURL URLWithString:referenceString];
    //NSLog(@"loading");
    referencesResultString=[NSString stringWithContentsOfURL:referenceURL];
    [self setArticleTitle:[XMLParser parse:referencesResultString withBeginningTag:@"<ArticleTitle>" 		withEndingTag:@"</ArticleTitle>"]];
    //NSLog(@"articletitle=%@",articleTitle);
    [self setArticleJournal:[XMLParser parse:referencesResultString withBeginningTag:@"<MedlineTA>" 		withEndingTag:@"</MedlineTA>"]];
    
    [self setArticleAuthors:[self extractAuthors:[XMLParser parse:referencesResultString withBeginningTag:@"<AuthorList" 		withEndingTag:@"</AuthorList>"]]];

    //[self setArticleAuthors:[XMLParser parse:referencesResultString withBeginningTag:@"<LastName>" 		withEndingTag:@"</LastName>"]];

    [self setArticleYear:[XMLParser parse:[XMLParser parse:referencesResultString withBeginningTag:@"<Article>" withEndingTag:@"</Article>"] withBeginningTag:@"<Year>" withEndingTag:@"</Year>"]];

}

-(NSMutableArray *)extractAuthors:(NSString *)authorxml {
    NSScanner *authorScanner;
    NSMutableArray *authors=[[NSMutableArray alloc] init];
    NSLog(@"extracting authors");
    authorScanner = [NSScanner scannerWithString:authorxml];
    
    while ([authorScanner isAtEnd] ==NO) {
	NSString *singleAuthor;
	NSString *lastName;
	NSString *initials;
	
	[authorScanner scanUpToString:@"<LastName>" intoString:NULL];
	[authorScanner scanString:@"<LastName>" intoString:NULL];
	[authorScanner scanUpToString:@"</LastName>" intoString:&lastName];
	[authorScanner scanString:@"</LastName>" intoString:NULL];
	[authorScanner scanUpToString:@"<Initials>" intoString:NULL];
	[authorScanner scanString:@"<Initials>" intoString:NULL];
	[authorScanner scanUpToString:@"</Initials>" intoString:&initials];

	singleAuthor=[NSString stringWithFormat:lastName];
	singleAuthor=[singleAuthor stringByAppendingString:@" "];
	singleAuthor=[singleAuthor stringByAppendingString:initials];

	[authors addObject:singleAuthor];
    }
    if ([authors count]>0) {
	[authors removeLastObject];
    }
    return [authors autorelease];
    
    
}


-(void)renameFile {
    NSMutableString *newName=[[NSMutableString alloc] init];
    if ([articleAuthors count]==1) {
	newName=[newName stringByAppendingString:[[self articleAuthors] objectAtIndex:0]];
	newName=[newName stringByAppendingString:@" ("];
	newName=[newName stringByAppendingString:[self articleJournal]];
	newName=[newName stringByAppendingString:@", "];
	newName=[newName stringByAppendingString:[self articleYear]];
	newName=[newName stringByAppendingString:@")"];
    }
    
    else if ([articleAuthors count]==2) {
	newName=[newName stringByAppendingString:[[self articleAuthors] objectAtIndex:0]];	newName=[newName stringByAppendingString:@" and "];
	newName=[newName stringByAppendingString:[articleAuthors lastObject]];
	newName=[newName stringByAppendingString:@" ("];
	newName=[newName stringByAppendingString:[self articleJournal]];
	newName=[newName stringByAppendingString:@", "];
	newName=[newName stringByAppendingString:[self articleYear]];
	newName=[newName stringByAppendingString:@")"];
    }
    
    
    else if ([articleAuthors count]>2) {
	newName=[newName stringByAppendingString:[[self articleAuthors] objectAtIndex:0]];
	newName=[newName stringByAppendingString:@", et al."];
	newName=[newName stringByAppendingString:@" ("];
	newName=[newName stringByAppendingString:[self articleJournal]];
	newName=[newName stringByAppendingString:@", "];
	newName=[newName stringByAppendingString:[self articleYear]];
	newName=[newName stringByAppendingString:@")"];
	
    }
    
    NSLog(@"newName=%@",newName);
    
    NSMutableString *newDirectoryAndFileName =[[NSMutableString alloc] init];
    [newDirectoryAndFileName appendString: [[self URLToPDFFile] path]];
    

    NSLog(@"newdirrectory and file name=%@",newDirectoryAndFileName);

    
    newDirectoryAndFileName=[newDirectoryAndFileName stringByDeletingLastPathComponent];
    NSLog(@"newdirrectory and file name=%@",newDirectoryAndFileName);
        newDirectoryAndFileName=[newDirectoryAndFileName stringByAppendingPathComponent:newName];
    newDirectoryAndFileName=[newDirectoryAndFileName stringByAppendingString:@".pdf"];

    NSLog(@"newdirrectory and file name=%@",newDirectoryAndFileName);
    NSLog(@"old file name=%@",[self URLToPDFFile]);
    
    if ([[NSFileManager defaultManager] movePath:[[self URLToPDFFile] path] toPath:newDirectoryAndFileName handler:nil]==NO) {
	NSLog(@"didn't rename");
    }
    /*
    if ([[NSFileManager defaultManager] movePath:@"~/Desktop/soylent.pdf" toPath:@"~/Desktop/testfile" handler:nil]==NO) {
	NSLog(@"didn't move");
    }
     */
    [self setURLToPDFFile:newDirectoryAndFileName];
    //[newName autorelease];
}

-(void) loadWholeReference {

    NSString *referenceString;
    NSString *referencesResultString;
    NSURL *referenceURL;
    
    referenceString=[NSString stringWithFormat:@"http://www.ncbi.nlm.nih.gov/entrez/utils/pmfetch.fcgi?db=PubMed&id=%@&report=xml&mode=text",referencePMID];
    referenceURL=[NSURL URLWithString:referenceString];
    referencesResultString=[NSString stringWithContentsOfURL:referenceURL];
    [self setArticleTitle:[XMLParser parse:referencesResultString withBeginningTag:@"<ArticleTitle>" 		withEndingTag:@"</ArticleTitle>"]];
    [self setArticleJournal:[XMLParser parse:referencesResultString withBeginningTag:@"<MedlineTA>" 		withEndingTag:@"</MedlineTA>"]];
    //[self setArticleAuthors:[XMLParser parse:referencesResultString withBeginningTag:@"<LastName>" 		withEndingTag:@"</LastName>"]];
    [self setArticleAbstract:[XMLParser parse:referencesResultString withBeginningTag:@"<AbstractText>" 		withEndingTag:@"</AbstractText>"]];
    [self setArticleJournal:[XMLParser parse:referencesResultString withBeginningTag:@"<MedlineTA>" 		withEndingTag:@"</MedlineTA>"]];
    [self setArticleVolume:[XMLParser parse:referencesResultString withBeginningTag:@"<Volume>" 		withEndingTag:@"</Volume>"]];
    [self setArticleIssue:[XMLParser parse:referencesResultString withBeginningTag:@"<Issue>" 		withEndingTag:@"</Issue>"]];
    [self setArticlePages:[XMLParser parse:referencesResultString withBeginningTag:@"<MedlinePGN>" 		withEndingTag:@"</MedlinePGN>"]];
}

//Accessor Methods

-(NSString *)referencePMID {
    return referencePMID;
}

-(void)setReferencePMID:(NSString *)newReferencePMID {
    [newReferencePMID retain];
    [referencePMID release];
    referencePMID=newReferencePMID;
}

-(NSString *)articleTitle {
    return articleTitle;
}


-(void)setArticleTitle:(NSString *)title {
    [title retain];
    [articleTitle release];
    articleTitle=title;
}

-(NSMutableArray *)articleAuthors {
    return articleAuthors;
}

-(NSMutableString *)articleAuthorsAsString {
    
    id nextItem;
    NSMutableString *authorString=[[NSMutableString alloc] init];
    if ([articleAuthors count] >0) {
	NSEnumerator *authorEnumerator = [articleAuthors objectEnumerator];
	while ((nextItem = [authorEnumerator nextObject])) {
	    [authorString appendString:nextItem];
	    [authorString appendString:@", "];
        }
	[authorString deleteCharactersInRange:NSMakeRange([authorString length]-2,1)];
    }
    else {
	[authorString appendString:@""];
    }
    return authorString;
    [authorString autorelease];
    
}

-(void)setArticleAuthors:(NSMutableArray *)authors {
    [authors retain];
    [articleAuthors release];
    articleAuthors=authors;

}

-(NSString *)articleJournal {
    return articleJournal;
}

-(void)setArticleJournal:(NSString *)journal {
    [journal retain];
    [articleJournal release];
    articleJournal=journal;
}

-(NSString *)articleAbstract {
    return articleAbstract;
}
-(void) setArticleAbstract:(NSString *)abstractText {
    [abstractText retain];
    [articleAbstract release];
    articleAbstract=abstractText;
}

-(NSMutableString *)articleNotes {
    return articleNotes;
}
-(void) setArticleNotes:(NSMutableString *)noteText {
    [noteText retain];
    [articleNotes release];
    articleNotes=noteText;
}

-(NSString *)articleVolume {
    return articleVolume;
}
-(void)setArticleVolume:(NSString *)aVolume {
    [aVolume retain];
    [articleVolume release];
    articleVolume=aVolume;
}

-(NSString *)articleYear {
    return articleYear;
}
-(void)setArticleYear:(NSString *)aYear {
    [aYear retain];
    [articleYear release];
    articleYear=aYear;
}

-(NSString *)articleIssue {
    return articleIssue;
}
-(void)setArticleIssue:(NSString *) anIssue {
    [anIssue retain];
    [articleIssue release];
    articleIssue=anIssue;
}

-(NSString *)articlePages {
    return articlePages;
}
-(void)setArticlePages:(NSString *) aPages {
    [aPages retain];
    [articlePages release];
    articlePages=aPages;
}

-(void)setNewReference:(BOOL)yn {
    
    newReference=yn;
}
-(BOOL)newReference {
    return newReference;
}

-(void) setArticleDateWithYear:(NSString *) aYear withMonth:(NSString *) aMonth withDay:(NSString *) aDay {
    
    [aYear retain];
    [aMonth retain];
    [aDay retain];
    [articleDate release];
    articleDate=[NSCalendarDate dateWithYear:[aYear intValue] month:[aMonth intValue] day: [aDay intValue] hour:0 minute:0 second:0 timeZone:[NSTimeZone timeZoneWithName:@"PST"]];
}
-(NSString *)articleDateString {
    [articleDate retain];
    //NSLog(@"returning date");
    return [articleDate descriptionWithCalendarFormat:@"%m/%d/%y"];
    
}
-(NSCalendarDate *)articleDate {
    return articleDate;
}

-(void) setReferenceLink:(NSString *) link {
    //NSLog(@"linking");
    [link retain];
    [referenceLink release];
    referenceLink=link;
}
-(NSString *)referenceLink {
    return referenceLink;
}

- (NSURL *) URLToPDFFile {
    return URLToPDFFile;
}

- (void) setURLToPDFFile: (NSURL *) newURL {
    [newURL retain];
    [URLToPDFFile release];
    URLToPDFFile=newURL;
}

-(void)setReferenceTextColor:(NSColor *) newColor {
    [newColor retain];
    [referenceTextColor release];
    referenceTextColor=newColor;
}

-(NSColor *)referenceTextColor {
    return referenceTextColor;
}

-(NSMutableArray *)keywords {
    return keywords;
}
-(void)setKeywords:(NSMutableArray *)array {
    [array retain];
    [keywords release];
    keywords=array;
}




//Encoding

- (void) encodeWithCoder:(NSCoder *)coder {

    [coder encodeObject:referencePMID forKey:@"referencePMID"];
    [coder encodeObject:articleTitle forKey:@"articleTitle"];
    [coder encodeObject:articleAuthors forKey:@"articleAuthors"];
    [coder encodeObject:articleJournal forKey:@"articleJournal"];
    [coder encodeObject:articleYear forKey:@"articleYear"];
    [coder encodeObject:URLToPDFFile forKey:@"URLToPDFFile"];
    [coder encodeObject:articleIssue forKey:@"articleIssue"];
    [coder encodeObject:articlePages forKey:@"articlePages"];
    [coder encodeObject:articleVolume forKey:@"articleVolume"];
    [coder encodeObject:articleAbstract forKey:@"articleAbstract"];
    [coder encodeObject:articleNotes forKey:@"articleNotes"];
    [coder encodeObject:referenceTextColor forKey:@"referenceTextColor"];
    [coder encodeObject:keywords forKey:@"keywords"];

    //[coder encodeobject:articleDate];
}

- (id) initWithCoder:(NSCoder *) coder {
    	
	if ( [coder allowsKeyedCoding] ) {
	    
	    referencePMID=[[coder decodeObjectForKey:@"referencePMID"] retain];
	    articleTitle=[[coder decodeObjectForKey:@"articleTitle"] retain];
	    articleAuthors=[[coder decodeObjectForKey:@"articleAuthors"] retain];
	    articleJournal=[[coder decodeObjectForKey:@"articleJournal"] retain];
	    articleYear=[[coder decodeObjectForKey:@"articleYear"] retain];
	    URLToPDFFile=[[coder decodeObjectForKey:@"URLToPDFFile"] retain];
	    articleIssue=[[coder decodeObjectForKey:@"articleIssue"] retain];
	    articlePages=[[coder decodeObjectForKey:@"articlePages"] retain];
	    articleVolume=[[coder decodeObjectForKey:@"articleVolume"] retain];
	    articleAbstract=[[coder decodeObjectForKey:@"articleAbstract"] retain];
	    articleNotes=[[coder decodeObjectForKey:@"articleNotes"] retain];
	    referenceTextColor=[[coder decodeObjectForKey:@"referenceTextColor"] retain];
	    keywords=[[coder decodeObjectForKey:@"keywords"] retain];

	    //[self setArticleDate:[coder decodeObject]];
	    
	    
	}
	
    
    return self;
}

//Comparing

-(NSComparisonResult) compareByYear:(reference *) toReference {
    
    return [articleDate compare:[toReference articleDate]];

}

@end
