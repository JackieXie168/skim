#import "SLQueryController.h"
#import "reference.h"
#import "query.h"

@implementation SLQueryController

-(id) init {
    if (self =[super init]) {
        
    }
    return self;
}

-(void) awakeFromNib {
    [self checkForNew:self];
}

//////////////////
//Action Methods//
//////////////////

//responds to search action (button or search field being exited)
- (IBAction)search:(id)sender {
    if ([[searchField stringValue] isEqualToString:@""]) {
    }
    else {
	query *search=[[query alloc] init];
	NSMutableArray *argumentArray=[[NSMutableArray alloc] init];
	[argumentArray addObject:self];
	[argumentArray addObject:[searchField stringValue]];
	[argumentArray addObject:SLPubmedReferenceController];
	[NSThread detachNewThreadSelector:@selector(performSearchInNewThread:) toTarget:search withObject:argumentArray];
	[self setCurrentSearch:search];
	[self addObject:search];
    }
}

-(void)toggleSearchProgressIndicatorOn {
    NSLog(@"toggling");
    [searchProgressIndicator startAnimation:self];
}

-(void)toggleSearchProgressIndicatorOff {
    NSLog(@"toggling");
    [searchProgressIndicator stopAnimation:self];
    //[self setSelectionIndex:[[self arrangedObjects] count]-1];
    [mainWindow makeFirstResponder:pubmedReferenceTableView];
    //[queryTableView setNeedsDisplay];
    //[pubmedReferenceTableView setNeedsDisplay];
}


////////////////////
//Instance Methods//
////////////////////

//creates new query instance and performs search with it

/*
-(query *)generateQuery:(NSString *) queryString {
    query *search=[[query alloc] init];
    NSMutableArray *argumentArray=[[NSMutableArray alloc] init];
    [argumentArray addObject:self];
    [argumentArray addObject:queryString];
    [argumentArray addObject:SLPubmedReferenceController];
    [NSThread detachNewThreadSelector:@selector(performSearchInNewThread:) toTarget:search withObject:argumentArray];
    //[search performSearch:queryString];
    return [search autorelease];
}
*/


- (void)checkForNew:(id)sender {
    NSLog(@"checking for new");
    NSEnumerator *queryEnumerator = [[self arrangedObjects] objectEnumerator];
    
    id nextItem;
    while ((nextItem = [queryEnumerator nextObject])) {
        if ([nextItem isMemberOfClass:[query class]]) {
	    [NSThread detachNewThreadSelector:@selector(checkForNewRefs:) toTarget:nextItem withObject:self];
	    // [nextItem checkForNewRefs];
        }
    }
    
    [lastCheckedTextField setStringValue:[[NSCalendarDate calendarDate] descriptionWithCalendarFormat:@"%a %m/%d/%y %I:%M %p"]];
    checkForNewTimer=[[NSTimer scheduledTimerWithTimeInterval:3600
						    target:self
						    selector:@selector(checkForNew:)
						    userInfo:nil
						    repeats:NO] retain];
}



////////////////////
//Accessor Methods//
////////////////////

-(query *)currentSearch {
    return currentSearch;
}

-(void)setCurrentSearch:(query *)search {
    [search retain];
    [currentSearch release];
    currentSearch=search;
}



@end

