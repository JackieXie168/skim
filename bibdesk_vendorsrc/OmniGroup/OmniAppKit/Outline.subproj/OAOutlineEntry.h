// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Outline.subproj/OAOutlineEntry.h,v 1.10 2003/01/15 22:51:40 kc Exp $

// These are the entries in the outline view. They represent your custom objects.

#import <OmniFoundation/OFObject.h>

@class OAOutlineView;
@class NSArray, NSMutableArray;
@class NSPasteboard;

#import <OmniAppKit/OAOutlineEntryProtocol.h>
#import <OmniAppKit/OAOutlineFormatterProtocol.h>

@interface OAOutlineEntry : OFObject <OAOutlineEntry>
{
    OAOutlineEntry *nonretainedParentEntry;
    OAOutlineView *nonretainedOutlineView;
    id representedObject;
    NSMutableArray *childEntries;
    id <OAOutlineFormatter> formatter;
    float totalHeight;
    struct {
        unsigned int hidden:1;
        unsigned int childrenAllowed:1;
    } flags;
}

+ (OAOutlineEntry *)entryWithRepresentedObject:(id)anObject inEntry:(OAOutlineEntry *)anEntry;

- initInView:(OAOutlineView *)aView;
- initWithRepresentedObject:(id)anObject inEntry:(OAOutlineEntry *)anEntry;

- (id)representedObject;
    // Return the object represented by this entry

- (void)setRepresentedObject:(id)newRepresentedObject;
    // Set the object represented by this entry


- (OAOutlineView *)outlineView;
    // The outline view in which we're displayed

- (void)setOutlineView:(OAOutlineView *)newOutlineView;
    // Set the outline view in which we're displayed


- (OAOutlineEntry *)parentEntry;
    // Return our parent entry in the outline hierarchy

- (BOOL)hasChildren;
    // Returns YES if the receiver claims to have child entries.  This should be used rather than [[self childEntries] count] != 0 since the entry might want to lazily fill its child list.

- (NSArray *)childEntries;
    // Returns the array of child entries.  This should be called rather than accessing the ivar directly when you want the children to really be there.  This should not naively be called recursively since the entry subclass might be creating children lazily for efficiency.

- (NSArray *)representedObjectsOfChildEntries;
    // Returns the objects represented by this entry's child entries.

- (NSArray *)allRepresentedObjects;
    // Returns the objects represented by this entry and all of its descendents.

- (BOOL)hidden;
    // Returns whether child entries are hidden (collapsed)

- (void)setHidden:(BOOL)newHidden;
    // Sets whether child entries are hidden (collapsed)

- (void)toggleHidden;
    // Toggles whether child entries are hidden (collapsed)

- (BOOL)childrenAllowed;
    // Returns whether children are allowed

- (void)setChildrenAllowed:(BOOL)newChildrenAllowed;
    // Sets whether children are allowed.  If children are not allowed, you cannot create children of this entry.

//

- (void)addDragPoints:(NSMutableArray *)dragPointList for:(OAOutlineEntry *)aDraggedEntry inRect:(NSRect)aRect;
- (void)dragDraw:(NSRect)rect inEntry:(OAOutlineEntry *)anEntry;
- (void)makeEntriesPerformSelector:(SEL)selector withObject:(id)anObject;

//

- (unsigned int)indexOfEntry:(OAOutlineEntry *)childEntry;
- (NSRect)entryRect;
- (void)recalculateHeight;

//

- (void)sortResults;

//

- (BOOL)promoteEntry:(OAOutlineEntry *)childEntry;
- (BOOL)demoteEntry:(OAOutlineEntry *)childEntry;
- (void)insertEntry:(OAOutlineEntry *)childEntry atIndex:(unsigned int)index;
- (void)replaceEntry:(OAOutlineEntry *)oldEntry withEntry:(OAOutlineEntry *)newEntry;
- (void)appendEntry:(OAOutlineEntry *)childEntry;
- (void)removeEntry:(OAOutlineEntry *)childEntry;
- (void)removeEntryAtIndex:(unsigned int)index;
- (void)empty;
- (void)nullifyOutlineView;

//

- (OAOutlineEntry *)previousEntry;
- (OAOutlineEntry *)nextEntry;
- (OAOutlineEntry *)previousVisibleEntry;
- (OAOutlineEntry *)nextVisibleEntry;
- (OAOutlineEntry *)lastEntry;

//

- (OAOutlineEntry *)findEntryWithRepresentedObject:(id)anObject;
- (OAOutlineEntry *)entryAndRect:(NSRect *)mutableEntryRect ofPoint:(NSPoint)point;

//

- (void)contractAllIncludingSelf:(BOOL)includeSelf;
- (void)expandAllIncludingSelf:(BOOL)includeSelf;

//

- (void)pasteboard:(NSPasteboard *)pasteboard provideDataForType:(NSString *)type;

// Cache the outline view's formatter.  The -setFormatter: method should only be called by OAOutlineView.
- (id <OAOutlineFormatter>)formatter;
- (void)setFormatter:(id <OAOutlineFormatter>)aFormatter;

@end
