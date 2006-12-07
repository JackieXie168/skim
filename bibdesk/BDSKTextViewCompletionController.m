//
//  BDSKTextViewCompletionController.m
//  Bibdesk
//
//  Created by Adam Maxwell on 01/08/06.
/*
 This software is Copyright (c) 2006
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BDSKTextViewCompletionController.h"

@interface BDSKTextViewCompletionWindow : NSWindow @end

static id sharedController = nil;

@interface BDSKTextViewCompletionController (Private)

- (void)setupWindow;
- (void)setupTable;
- (void)updateCompletionsAndInsert:(BOOL)insert;
- (NSSize)windowSizeForLocation:(NSPoint)topLeftPoint;
- (NSSize)windowContentSize;
- (void)registerForNotifications;
- (void)handleWindowChangedNotification:(NSNotification *)notification;

- (void)setCurrentTextView:(NSTextView *)tv;
- (void)setOriginalString:(NSString *)string;
- (void)setTextViewWindow:(NSWindow *)aWindow;
- (void)setCompletions:(NSArray *)newCompletions;

@end

@implementation BDSKTextViewCompletionController

+ (id)sharedController;
{
    if(sharedController == nil)
        sharedController = [[self alloc] init];
    return sharedController;
}

- (id)init;
{
    self = [super init];
    if(self == nil) return nil;
    
    [self setupWindow];
    [self setupTable];
    completions = nil;
	originalString = nil;
    shouldInsert = YES;
    
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setCompletions:nil];
    [self setOriginalString:nil];
    [self setCurrentTextView:nil];
    [completionWindow release];
    [super dealloc];
}

- (NSWindow *)completionWindow { return completionWindow; }
- (NSTextView *)currentTextView { return textView; }

- (void)tableViewSelectionDidChange:(NSNotification *)notification;
{  
    int row = [tableView selectedRow];
    if(row != -1){
        NSString *string = [completions objectAtIndex:row];
        
        // NSTextView makes this an undoable operation, even if isFinal == NO, but I don't think that's right
        [[textView undoManager] disableUndoRegistration];
        [textView insertCompletion:string forPartialWordRange:[textView rangeForUserCompletion] movement:movement isFinal:NO]; 
        [[textView undoManager] enableUndoRegistration];
    }
}

- (void)insertText:(id)insertString {
    movement = NSOtherTextMovement;
    [self updateCompletionsAndInsert:shouldInsert];
}

- (void)moveLeft:(id)sender {
    movement = NSLeftTextMovement;
    [self updateCompletionsAndInsert:NO];
}

- (void)moveRight:(id)sender {
    movement = NSRightTextMovement;
    [tableView numberOfSelectedRows] > 0 ? [self endDisplay] : [self updateCompletionsAndInsert:NO];
}

- (void)moveUp:(id)sender {
    movement = NSUpTextMovement;
    [tableView moveUp:nil];
}

- (void)moveDown:(id)sender {
    movement = NSDownTextMovement;
    [tableView moveDown:nil];
}

- (void)insertTab:(id)sender {
    movement = NSTabTextMovement;
    [tableView numberOfSelectedRows] > 0 ? [self endDisplay] : [self endDisplayNoComplete];
}

- (void)insertNewline:(id)sender {
    movement = NSReturnTextMovement;
    [self endDisplay];
}

- (void)deleteBackward:(id)sender {
    movement = NSLeftTextMovement;
    [self updateCompletionsAndInsert:NO]; // if we insert a new entry here, you can't delete anything
}

// override this method so we can set NSCancelTextMovement
- (void)complete:(id)sender {
    if([[self completionWindow] isVisible]){
        movement = NSCancelTextMovement;
        [self endDisplayNoComplete];
    }
}

- (void)displayCompletions:(NSArray *)array forPartialWordRange:(NSRange)partialWordRange originalString:(NSString *)origString atPoint:(NSPoint)point forTextView:(NSTextView *)tv;
{
    [self displayCompletions:array indexOfSelectedItem:-1 forPartialWordRange:partialWordRange originalString:origString atPoint:point forTextView:tv];
}

- (void)displayCompletions:(NSArray *)array indexOfSelectedItem:(int)indexOfSelectedItem forPartialWordRange:(NSRange)partialWordRange originalString:(NSString *)origString atPoint:(NSPoint)point forTextView:(NSTextView *)tv;
{
    // do nothing; displaying an empty window can lead to oddities when typing, since we get keystrokes as well as the editor
    if([array count] == 0 || NSEqualPoints(point, NSZeroPoint))
        return;

    // don't automatically insert when updating if we're not supposed to insert now
    shouldInsert = (indexOfSelectedItem >= 0);
    
    NSParameterAssert(indexOfSelectedItem == 0 || indexOfSelectedItem < (int)[array count]); // need a cast here or the assertion fails when indexOfSelectedItem == -1
    NSParameterAssert(tv != nil);
    NSParameterAssert(origString != nil);
	
    [self setOriginalString:origString];
    [self setCurrentTextView:tv];
    [self setTextViewWindow:[tv window]];

    [tableView deselectAll:nil];
    [self setCompletions:array];
    [tableView reloadData];
    
    // requires screen coordinates; resize so our scroller stays onscreen (if possible)
    NSRect frame = NSZeroRect;
    frame.size = [self windowSizeForLocation:point];
    frame.origin = point;
    frame.origin.y -= NSHeight(frame);
	[completionWindow setFrame:frame display:NO];

    [textViewWindow addChildWindow:completionWindow ordered:NSWindowAbove];
    [self registerForNotifications];
        
    [completionWindow orderFront:nil];
    
    // scrollers aren't drawn properly unless we do this
    [[completionWindow contentView] setNeedsDisplay:YES];
    
    if(indexOfSelectedItem >= 0){
        movement = NSDownTextMovement;
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:indexOfSelectedItem] byExtendingSelection:NO];
    }
    
}

- (void)endDisplay { [self endDisplayAndComplete:YES]; }

- (void)endDisplayNoComplete { [self endDisplayAndComplete:NO]; }

- (void)endDisplayAndComplete:(BOOL)complete;
{
	BOOL shouldComplete = (complete == YES && [tableView selectedRow] >= 0);
    if(shouldComplete == YES || movement == NSCancelTextMovement){  
        // first revert to the original state, so undo will register the full change
        // if we do this when shouldComplete == NO, it restores the original string and effectively prevents modifying the text (i.e. all non-completable text is deleted when you tab out)
        [[textView undoManager] disableUndoRegistration];
        [textView insertCompletion:originalString forPartialWordRange:[textView rangeForUserCompletion] movement:movement isFinal:(shouldComplete == NO)];
        [[textView undoManager] enableUndoRegistration];
        
        if(movement != NSCancelTextMovement){
            NSString *string = [completions objectAtIndex:[tableView selectedRow]];
            [textView insertCompletion:string forPartialWordRange:[textView rangeForUserCompletion] movement:movement isFinal:YES];
        }
	}
    
    [self setCurrentTextView:nil];
    [self setCompletions:nil];
    [self setOriginalString:nil];    
    
    [tableView setDelegate:nil]; // in case it retains its delegate (shouldn't, though)
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [tableView setDelegate:self]; // re-add, since the removeObserver: breaks the table selection change
    
    [textViewWindow removeChildWindow:completionWindow];
    [self setTextViewWindow:nil];
    [completionWindow close];
}

- (void)tableAction:(id)sender;
{
    [self endDisplay];
}

#pragma mark table datasource

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)column row:(int)row { return [completions objectAtIndex:row]; }

- (int)numberOfRowsInTableView:(NSTableView *)tv { return [completions count]; }

@end

@implementation BDSKTextViewCompletionController (Private)

// constants for determining the window height, which we adjust based on parent window location and screen size
static int BDSKCompletionMaxWidth = 350;
static int BDSKCompletionMaxHeight = 200;
static int BDSKCompletionRowHeight = 17;
static int BDSKCompletionMinWidth = 50;
static int BDSKCompletionMinHeight = 20;


- (void)setupWindow;
{
    NSRect contentRect = NSMakeRect(0, 0, BDSKCompletionMaxWidth, BDSKCompletionMaxHeight);
    completionWindow = [[BDSKTextViewCompletionWindow alloc] initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [completionWindow setReleasedWhenClosed:NO];
    
    tableView = [[NSTableView alloc] initWithFrame:contentRect];
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:contentRect];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setDocumentView:tableView];
    [tableView release];
    [completionWindow setContentView:scrollView];
    [scrollView release];
    [scrollView setAutoresizesSubviews:YES];
    [scrollView setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];
}

- (void)setupTable;
{
    [tableView setDelegate:self];
    [tableView setDataSource:self];
    [tableView setHeaderView:nil];
    [tableView setCornerView:nil];
    [tableView setAllowsColumnReordering:NO];
    [tableView setRowHeight:BDSKCompletionRowHeight];
    [tableView setAction:@selector(tableAction:)];
    [tableView setTarget:self];
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"tc"];
    [column setMaxWidth:BDSKCompletionMaxWidth];
    [column setWidth:BDSKCompletionMaxWidth];
    [column setResizingMask:NSTableColumnAutoresizingMask];
    [column setEditable:NO];
    [tableView addTableColumn:column];
    [column release];
}

// At present, reselecting on a delete keeps you from typing anything
- (void)updateCompletionsAndInsert:(BOOL)insert{

    int idx = -1;
    NSArray *newCompletions = nil;
    NSRange charRange = [textView rangeForUserCompletion];
    
    if([[textView string] isEqualToString:@""] == NO && [[textView string] length] >= NSMaxRange(charRange))
        newCompletions = [textView completionsForPartialWordRange:charRange indexOfSelectedItem:&idx];
    
    // if there are no completions, we should go away in order to avoid catching keystrokes when the completion window isn't visible; if the textview/delegate come up with a new list of completions, we'll be redisplayed anyway
    if([newCompletions count] == 0)
        [self endDisplayNoComplete];
    
    [tableView deselectAll:nil];

    [self setCompletions:newCompletions];
    [tableView reloadData];
    
    // reset the location in case it's changed; could keep charRange as an ivar as NSTextViewCompletionController does and compare against that?
    NSPoint point = [textView locationForCompletionWindow];
    // if the point is NSZeroPoint, it's not valid, so don't move the window; alternately, could endDisplayNoComplete, but we're probably ending anyway
    if(NSEqualPoints(point, NSZeroPoint) == NO){
        NSRect frame = NSZeroRect;
        frame.size = [self windowSizeForLocation:point];
        frame.origin = point;
        frame.origin.y -= NSHeight(frame);
        [completionWindow setFrame:frame display:NO];
    }
    
    if(idx >= 0 && insert)
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
    
    // originalString changes as we update; the range can be incorrect if we have an accent character being replaced
    OBPRECONDITION([[textView string] length] >= NSMaxRange(charRange));
    [self setOriginalString:([[textView string] length] >= NSMaxRange(charRange) ? [[textView string] substringWithRange:charRange] : nil)];

}

- (NSSize)windowSizeForLocation:(NSPoint)topLeftPoint;
{
    NSRect screenFrame = [[NSScreen mainScreen] visibleFrame];
    
    // get the remaining space on the screen
    float hSize = NSMaxX(screenFrame) - BDSKCompletionMaxWidth - topLeftPoint.x;
    hSize = hSize <= 0.0f ? BDSKCompletionMaxWidth + hSize : BDSKCompletionMaxWidth;
    hSize = floorf(fmaxf(hSize, BDSKCompletionMinWidth));
    
    float vSize = topLeftPoint.y - BDSKCompletionMaxHeight;
    vSize = vSize <= 0.0f ? BDSKCompletionMaxHeight + vSize : BDSKCompletionMaxHeight;
    vSize = floorf(fmaxf(vSize, BDSKCompletionMinHeight));
    
    NSSize adjustedSize = [self windowContentSize];
    if(adjustedSize.width > hSize)
		adjustedSize.width = hSize;
    if(adjustedSize.height > vSize)
		adjustedSize.height = vSize;
    
	return adjustedSize;
}

- (NSSize)windowContentSize
{
	float hSize = 0.0f;
    unsigned count = [tableView numberOfRows];
	NSCell *cell = [[[tableView tableColumns] objectAtIndex:0] dataCell];
	while(count--){
		[cell setStringValue:[completions objectAtIndex:count]];
		hSize = fmaxf(hSize, [cell cellSize].width);
	}
	hSize += [NSScroller scrollerWidth] + [tableView intercellSpacing].width;
    
	float vSize = NSHeight(NSUnionRect([tableView rectOfRow:0], [tableView rectOfRow:[tableView numberOfRows] - 1]));
	
	return NSMakeSize(ceilf(hSize), ceilf(vSize));
}


- (void)registerForNotifications;
{
    NSParameterAssert(textViewWindow != nil);
    NSParameterAssert(textView != nil);
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleWindowChangedNotification:) name:NSWindowDidResignKeyNotification object:textViewWindow];
    [nc addObserver:self selector:@selector(handleWindowChangedNotification:) name:NSWindowDidResignMainNotification object:textViewWindow];
    [nc addObserver:self selector:@selector(handleWindowChangedNotification:) name:NSWindowDidResizeNotification object:textViewWindow];
    // this one doesn't seem to work for some reason
    [nc addObserver:self selector:@selector(handleWindowChangedNotification:) name:NSWindowWillMoveNotification object:textViewWindow];
    [nc addObserver:self selector:@selector(handleWindowChangedNotification:) name:NSWindowWillBeginSheetNotification object:textViewWindow];
    
    // go away if the scroller of the textview/field editor changes
    NSClipView *clipView = [[textView enclosingScrollView] contentView];
    if(clipView != nil){
        [clipView setPostsBoundsChangedNotifications:YES];
        [nc addObserver:self selector:@selector(handleWindowChangedNotification:) name:NSViewBoundsDidChangeNotification object:clipView];
    }
}

- (void)handleWindowChangedNotification:(NSNotification *)notification { [self endDisplayAndComplete:NO]; }

// retain the text view, just in case; we've seen some unreproducible crashes in objc_msgSend_stret when calling updateCompletionsAndInsert:, which is presumably the call to rangeForUserCompletion or locationForCompletionWindow
- (void)setCurrentTextView:(NSTextView *)tv;
{
    if(tv != textView){
        [textView release];
        textView = [tv retain];
    }
}

- (void)setOriginalString:(NSString *)string;
{
    if(string != originalString){
        [originalString release];
        originalString = [string copy];
    }
}

// do not retain!
- (void)setTextViewWindow:(NSWindow *)aWindow;
{
    textViewWindow = aWindow;
}

- (void)setCompletions:(NSArray *)newCompletions;
{
    if(completions != newCompletions){
        [completions release];
        completions = [newCompletions copy];
    }
}

@end

#pragma mark NSWindow subclass

@implementation BDSKTextViewCompletionWindow
    
// thanks to cocoadev.com for this handy override that lets us show blue scrollers
- (BOOL)_hasActiveControls { return YES; }

- (BOOL)hasShadow { return YES; }

- (float)alphaValue { return 0.9; }

// explicitly note that we want these to return NO, even though that's the default for windows created in code
- (BOOL)canBecomeKeyWindow { return NO; }
- (BOOL)canBecomeMainWindow { return NO; }

@end
