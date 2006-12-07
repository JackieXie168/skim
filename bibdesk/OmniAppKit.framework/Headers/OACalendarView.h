// Copyright 2001-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <AppKit/NSControl.h>

@class NSCalendarDate, NSMutableArray;
@class NSTableHeaderCell, NSTextFieldCell;
@class OACalendarView;

#import <AppKit/NSNibDeclarations.h>

@interface NSObject (OACalendarViewDelegate)
- (int)calendarView:(OACalendarView *)aCalendarView highlightMaskForVisibleMonth:(NSCalendarDate *)visibleMonth;
- (void)calendarView:(OACalendarView *)aCalendarView willDisplayCell:(id)aCell forDate:(NSCalendarDate *)aDate;	// implement this on the target if you want to be able to set up the date cell
- (void)calendarView:(OACalendarView *)aCalendarView didChangeVisibleMonth:(NSCalendarDate *)aDate;	// implement this on the target if you want to know when the visible month changes
@end


typedef enum _OACalendarViewSelectionType {
    OACalendarViewSelectByDay = 0,		// one day
    OACalendarViewSelectByWeek = 1,		// one week (from Sunday to Saturday) 
    OACalendarViewSelectByWeekday = 2,    	// all of one weekday (e.g. Monday) for a whole month
} OACalendarViewSelectionType;

@interface OACalendarView : NSControl
{
    NSCalendarDate *visibleMonth;
    NSCalendarDate *selectedDay;

    NSView *monthAndYearView;
    NSTextFieldCell *monthAndYearTextFieldCell;
    NSTableHeaderCell *dayOfWeekCell[7];
    NSTextFieldCell *dayOfMonthCell;
    NSMutableArray *buttons;

    int dayHighlightMask;
    OACalendarViewSelectionType selectionType;
    
    float columnWidth;
    float rowHeight;
    NSRect monthAndYearRect;
    NSRect gridHeaderAndBodyRect;
    NSRect gridHeaderRect;
    NSRect gridBodyRect;
    
    struct {
        unsigned int showsDaysForOtherMonths:1;
        unsigned int targetProvidesHighlightMask:1;
        unsigned int targetWatchesCellDisplay:1;
        unsigned int targetWatchesVisibleMonth:1;
    } flags;
}

- (NSCalendarDate *)visibleMonth;
- (void)setVisibleMonth:(NSCalendarDate *)aDate;

- (NSCalendarDate *)selectedDay;
- (void)setSelectedDay:(NSCalendarDate *)newSelectedDay;

- (int)dayHighlightMask;
- (void)setDayHighlightMask:(int)newMask;
- (void)updateHighlightMask;

- (BOOL)showsDaysForOtherMonths;
- (void)setShowsDaysForOtherMonths:(BOOL)value;

- (OACalendarViewSelectionType)selectionType;
- (void)setSelectionType:(OACalendarViewSelectionType)value;

- (NSArray *)selectedDays;

// Actions
- (IBAction)previousMonth:(id)sender;
- (IBAction)nextMonth:(id)sender;
- (IBAction)previousYear:(id)sender;
- (IBAction)nextYear:(id)sender;

@end
