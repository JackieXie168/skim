/* SLController */

#import <Cocoa/Cocoa.h>

@interface SLController : NSObject
{
    IBOutlet NSTableView *folderTable;
    IBOutlet NSView *browseView;
    NSMutableArray *folderListArray;
    
}
- (IBAction)addFolder:(id)sender;
@end
