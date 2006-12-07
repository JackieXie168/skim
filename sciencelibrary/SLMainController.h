/* SLMainController */

#import <Cocoa/Cocoa.h>


@interface SLMainController : NSObject
{
    
    IBOutlet NSArrayController *SLSourceArrayController;
    IBOutlet NSArrayController *SLArticleController;
    IBOutlet NSArrayController *SLPubmedSearchArrayController;
    IBOutlet NSTableView *sourceTableView;
    IBOutlet NSTableView *articleTableView;
    IBOutlet NSTableView *pubmedArticleTableView;
    IBOutlet NSView *articleView;
    IBOutlet NSView *pubMedView;
    IBOutlet NSWindow *mainWindow;
    IBOutlet NSWindow *setupWindow;
    IBOutlet NSPopUpButton *SLKeywordPopupButton;
    IBOutlet NSArrayController *SLKeywordListController;
    IBOutlet NSWindow *keywordsWindow;
    //NSMutableArray *sourceListArray;
}

-(void) awakeFromNib;
-(IBAction)applicationWillTerminate:(id)sender;
-(IBAction)addArticle:(id)sender;
-(IBAction)changeLibraryLocation:(id)sender;
-(IBAction)setInitialLibraryLocation:(id)sender;

-(IBAction)editKeywordList:(id)sender;
- (void)populatePopMenu;


//-(IBAction)imageViewURLChanged:(id)sender;
//-(void)renameFile:(id)sender;

-(void) openSetupWindow;
-(void) closeSetupWindow:(id)sender;

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
-(IBAction)save:(id)sender;


@end
