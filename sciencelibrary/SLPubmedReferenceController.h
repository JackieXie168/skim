/* SLPubmedReferenceController */

#import <Cocoa/Cocoa.h>

@interface SLPubmedReferenceController : NSArrayController
{
    IBOutlet NSTableView *pubmedReferenceTable;

}

-(void)pubmedReferenceTableRowClicked:(id)sender;
-(void)openReferenceInBrowser:(id)sender;

@end
