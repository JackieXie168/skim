#import "RYZImagePopUpButtonCell.h"

@interface RYZImagePopUpButton : NSPopUpButton
{
	NSTimer *currentTimer;
	BOOL highlight;
	id delegate;
}

// --- Getting and setting the icon size ---
- (NSSize)iconSize;
- (void)setIconSize:(NSSize)iconSize;


// --- Getting and setting whether the menu is shown when the icon is clicked ---
- (BOOL)showsMenuWhenIconClicked;
- (void)setShowsMenuWhenIconClicked:(BOOL)showsMenuWhenIconClicked;


// --- Getting and setting the icon image ---
- (NSImage *)iconImage;
- (void)setIconImage:(NSImage *)iconImage;
- (void)fadeIconImageToImage:(NSImage *)iconImage;
- (void)timerFired:(NSTimer *)timer;

// --- Getting and setting the arrow image ---
- (NSImage *)arrowImage;
- (void) setArrowImage:(NSImage *)arrowImage;


// ---  Getting and setting the action enabled flag ---
- (BOOL)iconActionEnabled;
- (void)setIconActionEnabled:(BOOL)iconActionEnabled;

- (BOOL)refreshesMenu;
- (void)setRefreshesMenu:(BOOL)refreshesMenu;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (NSMenu *)menuForCell:(id)cell;

- (BOOL)startDraggingWithEvent:(NSEvent *)theEvent;

@end

@interface NSObject (RYZImagePopUpButtonDelegate)
- (NSMenu *)menuForImagePopUpButton:(RYZImagePopUpButton *)view;
@end

@interface NSObject (RYZImagePopUpButtonDraggingDestination)
- (BOOL)imagePopUpButton:(RYZImagePopUpButton *)view canReceiveDrag:(id <NSDraggingInfo>)sender;
- (BOOL)imagePopUpButton:(RYZImagePopUpButton *)view receiveDrag:(id <NSDraggingInfo>)sender;
@end

@interface NSObject (RYZImagePopUpButtonDraggingSource)
- (BOOL)imagePopUpButton:(RYZImagePopUpButton *)view writeDataToPasteboard:(NSPasteboard *)pasteboard;
- (NSArray *)imagePopUpButton:(RYZImagePopUpButton *)view namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination;
- (void)imagePopUpButton:(RYZImagePopUpButton *)view cleanUpAfterDragOperation:(NSDragOperation)operation;
@end
