@interface RYZImagePopUpButtonCell : NSPopUpButtonCell
{
    NSButtonCell *RYZ_buttonCell;
    NSSize RYZ_iconSize;
    BOOL RYZ_showsMenuWhenIconClicked;
    NSImage *RYZ_iconImage;
    NSImage *RYZ_arrowImage;
	BOOL RYZ_iconActionEnabled;
	BOOL RYZ_alwaysUsesFirstItemAsSelected;
	BOOL RYZ_refreshesMenu;
}

// -- Setting if the icon is enabled, leaves the menu enabled --
// -- meaningless if showsmenuwheniconclicked is true.
- (BOOL)iconActionEnabled;
- (void)setIconActionEnabled:(BOOL)iconActionEnabled;


// --- Getting and setting the icon size ---
- (NSSize)iconSize;
- (void)setIconSize:(NSSize)iconSize;


// --- Getting and setting whether the menu is shown when the icon is clicked ---
- (BOOL)showsMenuWhenIconClicked;
- (void)setShowsMenuWhenIconClicked:(BOOL)showsMenuWhenIconClicked;


// --- Getting and setting the icon image ---
- (NSImage *)iconImage;
- (void)setIconImage:(NSImage *)iconImage;


// --- Getting and setting the arrow image ---
- (NSImage *) arrowImage;
- (void)setArrowImage:(NSImage *)arrowImage;

// --- changing whether or not the selected item changes.
- (BOOL)alwaysUsesFirstItemAsSelected;
- (void)setAlwaysUsesFirstItemAsSelected:(BOOL)newAlwaysUsesFirstItemAsSelected;

- (BOOL)refreshesMenu;
- (void)setRefreshesMenu:(BOOL)newRefreshesMenu;


// Private methods

- (void)showMenuInView:(NSView *)controlView withEvent:(NSEvent *)event;

- (NSSize)iconDrawSize;

@end
