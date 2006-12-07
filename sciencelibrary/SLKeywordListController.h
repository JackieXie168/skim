/* SLKeywordListController */

#import <Cocoa/Cocoa.h>
#import <SLMainController.h>

@interface SLKeywordListController : NSArrayController
{
    IBOutlet NSTextField *newKeywordTextField;
    IBOutlet SLMainController *mainController;
}
@end
