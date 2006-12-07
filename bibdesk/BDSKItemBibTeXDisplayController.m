//
//  BDSKItemBibTeXDisplayController.m

#import "BDSKItemBibTeXDisplayController.h"


@implementation BDSKItemBibTeXDisplayController
- (NSString *)displayName{
	return NSLocalizedString(@"BibTeX", @"BibTeX display controller name");
}

- (NSArray *)compatibleTypes{
	return [NSArray arrayWithObject:NSStringFromClass([BibItem class])];
}
- (NSView *)view{
    if(!enclosingView){
        [NSBundle loadNibNamed:@"BibTeXItemDisplay" owner:self];
    }
    return enclosingView;
}

- (void)setItemSource:(id)source{
	// we don't retain the source
	itemSource = source;
}

- (id)itemSource{ return itemSource; }

- (void)awakeFromNib{
    NSLog(@"%@ Awake from nib", NSStringFromClass([self class]));
    [self registerForNotifications];
}

- (void)registerForNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSelectedItemsChangedNotification:)
                                                 name:BDSKBibLibrarySelectedItemsChangedNotification
                                               object:itemSource];
    
}

- (void)handleSelectedItemsChangedNotification:(NSNotification *)notification{
    NSLog(@"handling sel items changed");
    [self updateUI];
}

- (void)updateUI{
    NSMutableString *s = [NSMutableString stringWithCapacity:100];
    
    foreach(item, [itemSource selectedItems]){
        [s appendString: [(BibItem *)item bibTeXString]];
        [s appendString:@"\n"];
    }
    
    [textView setString:s];
}

@end
