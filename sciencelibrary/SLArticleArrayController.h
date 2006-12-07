/* SLArticleArrayController */

#import <Cocoa/Cocoa.h>

@interface SLArticleArrayController : NSArrayController
{
    IBOutlet NSSearchField *searchField;
    IBOutlet NSTableView *articleTable;
}

- (void)search:(id)sender;
-(void)openReferenceInBrowser:(id)sender;
- (void)associatePDFFileWithArticle:(id)sender;
-(IBAction)imageViewURLChanged:(id)sender;
-(void)renameFile:(id)sender;


@end
