/* SLQueryController */

#import <Cocoa/Cocoa.h>
#import <query.h>


@interface SLQueryController : NSArrayController
{
    IBOutlet NSSearchField *searchField;
    query *currentSearch;
    IBOutlet NSArrayController *SLPubmedReferenceController;
    IBOutlet NSTextField *lastCheckedTextField;
    IBOutlet NSProgressIndicator *searchProgressIndicator;
    IBOutlet NSTableView *pubmedReferenceTableView;
    IBOutlet NSTableView *queryTableView;
    IBOutlet NSWindow *mainWindow;
    NSTimer *checkForNewTimer;
}

//////////////////
//Action Methods//
//////////////////

- (IBAction)search:(id)sender;
-(void)toggleSearchProgressIndicatorOn;
-(void)toggleSearchProgressIndicatorOff;


////////////////////
//Instance Methods//
////////////////////

- (query *)generateQuery:(NSString *)queryString;
- (void)checkForNew:(id)sender;

////////////////////
//Accessor Methods//
////////////////////

- (query *)currentSearch;
- (void)setCurrentSearch:(query *)search;


@end


