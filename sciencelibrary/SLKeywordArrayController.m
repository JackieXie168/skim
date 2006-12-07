#import "SLKeywordArrayController.h"

@implementation SLKeywordArrayController


-(IBAction) add:(id)sender {
    if (![[self arrangedObjects] containsObject:[[keywordPopup selectedCell] title]]) {
	[self addObject:[[keywordPopup selectedCell] title]];
    NSLog(@"done adding");
    NSLog(@"array contains=%@",[self arrangedObjects]);
    }
}
@end
