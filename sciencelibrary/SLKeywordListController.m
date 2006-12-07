#import "SLKeywordListController.h"

@implementation SLKeywordListController

-(IBAction) add:(id)sender {
    if (![[self arrangedObjects] containsObject:[newKeywordTextField stringValue]]) {
	[self addObject:[newKeywordTextField stringValue]];
    }
    NSLog(@"done adding");
    [mainController populatePopMenu];
}

-(IBAction) remove: (id)sender {
    [super remove:self];
    [mainController populatePopMenu];
}
@end
