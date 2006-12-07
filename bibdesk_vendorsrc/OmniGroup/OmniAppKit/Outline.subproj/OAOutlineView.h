// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Outline.subproj/OAOutlineView.h,v 1.16 2003/01/15 22:51:40 kc Exp $

// This is the outline view

#import <AppKit/NSView.h>

@class NSDate;
@class NSMutableString;
@class NSMutableArray;
@class OAOutlineDragPoint, OAOutlineEntry;

#import <AppKit/NSNibDeclarations.h> // For IBOutlet

#import <OmniAppKit/OAOutlineFormatterProtocol.h>
#import <OmniAppKit/OAOutlineDragSupportProtocol.h>
#import <OmniAppKit/OAFindControllerTargetProtocol.h>
#import <OmniAppKit/FrameworkDefines.h>

@interface OAOutlineView : NSView <OAFindControllerTarget>
{
    IBOutlet id delegate;

    NSMutableArray *dragPoints;
    int scrollDirection;

    OAOutlineEntry *topLevelEntry;
    OAOutlineEntry *dragEntry; // the entry curently being dragged
    OAOutlineDragPoint *nonretainedCurrentDragPoint;
    NSMutableString *typed;
    NSDate *lastTyped;
    float tabWidth, borderWidth;
    id <NSObject, OAOutlineDragSupport> dragSupport;
    NSArray *sublistPasteboardTypes;
    id <NSObject, OAOutlineFormatter> formatter;
    OAOutlineEntry *nonretainedSelectedEntry;
    struct {
        unsigned int enableScroll:1;
        unsigned int isScrolling:1;
        unsigned int editable:1;
        unsigned int selectable:1;
        unsigned int hierarchical:1;
        unsigned int performingOperation:1;
        unsigned int internalDrag:1;
        unsigned int allowDraggingOut:1;
        unsigned int allowDraggingIn:1;
        unsigned int allowAutoFinding:1;
        unsigned int dragEntireSublists:1;
        unsigned int acceptEntireSublists:1;
        unsigned int formatterIsFindable:1;
        unsigned int formatterIsEditable:1;
        unsigned int delegateDidSelect:1;
        unsigned int delegateWillSelect:1;
        unsigned int delegateWillAdd:1;
        unsigned int delegateDidAdd:1;
        unsigned int delegateWillEdit:1;
        unsigned int delegateDidEdit:1;
        unsigned int delegateWillRemove:1;
        unsigned int delegateDidRemove:1;
        unsigned int delegateDidGetKey:1;
        unsigned int delegateDidPromote:1;
        unsigned int delegateDidDemote:1;
        unsigned int draggingAlreadyEntered:1;
        unsigned int hasPendingHeightRecalculation:1;
    } flags;
}

- initWithFrame:(NSRect)aFrame;

// this is the very top of the hierarchy - not displayed itself, and doesn't
// usually have a represented object (but it can)
- (OAOutlineEntry *)topLevelEntry;
- (void)setTopLevelEntry:(OAOutlineEntry *)anEntry;

// the formatter for displaying all the entries
- (id <NSObject, OAOutlineFormatter>)formatter;
- (void)setFormatter:(id <NSObject, OAOutlineFormatter>)aFormatter;

// the object which provides drag support for the custom objects represented
- (id <NSObject, OAOutlineDragSupport>)dragSupport;
- (void)setDragSupport:(id <NSObject, OAOutlineDragSupport>)aSupport;
- (OAOutlineEntry *)entryWithChildrenFromPasteboard:(NSPasteboard *)pasteboard;

- (BOOL)isEditable;
- (void)setEditable:(BOOL)newEditable;

- (BOOL)isHierarchical;
- (void)setHierarchical:(BOOL)newHierarchical;

- (BOOL)isSelectable;
- (void)setSelectable:(BOOL)newSelectable;

- (BOOL)doesAllowDraggingOut;
- (void)allowDraggingOut:(BOOL)newAllowDraggingOut;

- (BOOL)doesAllowDraggingIn;
- (void)allowDraggingIn:(BOOL)newAllowDraggingIn;

- (BOOL)doesAllowAutomaticFind;
- (void)allowAutomaticFind:(BOOL)newAllowAutomaticFind;

- (BOOL)doesDragEntireSublists;
- (void)dragEntireSublists:(BOOL)newDragEntireSublists;

- (BOOL)doesAcceptEntireSublists;
- (void)acceptEntireSublists:(BOOL)newAcceptEntireSublists;

- (void)registerWindowForDrags;
    // Unregister ourself for drags and register the window instead.  This lets the window delegate forward drag messages to us so we can scroll if drag is above or below us

- (OAOutlineEntry *)dragEntry;
    // the entry currently being dragged

- (float)tabWidth;
- (void)setTabWidth:(float)aWidth;

- (float)borderWidth;
- (void)setBorderWidth:(float)aWidth;

- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)aColor;

- delegate;
- (void)setDelegate:(id)aDelegate;

- (OAOutlineEntry *)selection;
    // the currently selected entry
- (void)setSelectionTo:(OAOutlineEntry *)anEntry;
- (void)scrollSelectedEntryToCenter;

- (void)dragSublist:(OAOutlineEntry *)sublist causedByEvent:(NSEvent *)original 
	currentEvent:(NSEvent *)current;

- (BOOL)isOriginalDragPoint;

- (void)markNeedsHeightRecalculationAndDisplay;
    // schedules a recalculateHeight
- (void)recalculateHeightIfNeeded;
    // recalculates

- (void)makeEntriesPerformSelector:(SEL)selector withObject:(id)anObject;

- (IBAction)contractAll:(id)sender;
- (IBAction)expandAll:(id)sender;

- (IBAction)contractSelection:(id)sender;
- (IBAction)expandSelection:(id)sender;

- (IBAction)removeItem:(id)sender;
- (IBAction)insertItem:(id)sender;

- (IBAction)cut:(id)sender;
- (IBAction)copy:(id)sender;
- (IBAction)paste:(id)sender;
- (IBAction)delete:(id)sender;

// Used by editable formatters

- (BOOL)willEdit;
    // Checks whether we're editable and whether the delegate will allow an edit.
- (void)didEdit;
    // Notifies the delegate that we've been edited.

@end

// the messages we send to our delegate (if it implements them)

@protocol OAOutlineViewDelegate
- (BOOL)outlineView:(OAOutlineView *)anOutlineView willSelectEntry:(OAOutlineEntry *)anEntry;
- (void)outlineView:(OAOutlineView *)anOutlineView didSelectEntry:(OAOutlineEntry *)anEntry;
- (BOOL)outlineView:(OAOutlineView *)anOutlineView willAddEntry:(OAOutlineEntry *)anEntry;
- (void)outlineView:(OAOutlineView *)anOutlineView didAddEntry:(OAOutlineEntry *)anEntry;
- (BOOL)outlineView:(OAOutlineView *)anOutlineView willEditEntry:(OAOutlineEntry *)anEntry;
- (void)outlineView:(OAOutlineView *)anOutlineView didEditEntry:(OAOutlineEntry *)anEntry;
- (BOOL)outlineView:(OAOutlineView *)anOutlineView willRemoveEntry:(OAOutlineEntry *)anEntry;
- (void)outlineView:(OAOutlineView *)anOutlineView didRemoveEntry:(OAOutlineEntry *)anEntry;
- (void)outlineView:(OAOutlineView *)anOutlineView didPromoteEntry:(OAOutlineEntry *)anEntry;
- (void)outlineView:(OAOutlineView *)anOutlineView didDemoteEntry:(OAOutlineEntry *)anEntry;
- (BOOL)outlineView:(OAOutlineView *)anOutlineView didGetKey:(unsigned short)key;
@end

OmniAppKit_EXTERN NSString *OAOutlineSubListPasteboardType;
