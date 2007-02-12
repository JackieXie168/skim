/* BDSKFileMatchConfigController */

#import <Cocoa/Cocoa.h>
#import "BDSKSheetController.h"

@interface BDSKFileMatchConfigController : BDSKSheetController
{
    IBOutlet NSButton *allDocsCheckbox;
    IBOutlet NSTableView *documentTableView;
    IBOutlet NSTableView *fileTableView;
    IBOutlet NSButton *useOrphansCheckbox;
    
    NSMutableArray *documents;
    NSMutableArray *files;
    BOOL useOrphanedFiles;
    BOOL useAllOpenDocuments;
    
    IBOutlet NSArrayController *documentArrayController;
    IBOutlet NSArrayController *fileArrayController;
}

- (IBAction)add:(id)sender;
- (IBAction)remove:(id)sender;

- (NSArray *)publications;
- (void)handleDocumentAddRemove:(NSNotification *)note;
- (void)setDocuments:(NSArray *)docs;
- (NSArray *)documents;
- (NSArray *)files;
- (NSArray *)publications;

@end
