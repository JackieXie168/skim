//
//  BDSKLibraryController.m
//  Bibdesk
//
//  Created by Michael McCracken on 2/11/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKLibraryController.h"

@implementation BDSKLibraryController

- (id)init{
    if(self = [super init]){

		currentCollection = nil;
        [self registerForNotifications];
    }
    return self;
}

- (void)dealloc{
#if DEBUG
    NSLog(@"bibdoc dealloc");
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)registerForNotifications{
    //  register to observe for selected items changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBDSKLibraryControllerSelectionChangedNotification:)
                                                 name:BDSKBibLibrarySelectedItemsChangedNotification
                                               object:nil];
    
    // register to observe for add/delete items.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBibCollectionItemAddedNotification:)
                                                 name:BDSKBibCollectionItemAddedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBibCollectionItemRemovedNotification:)
                                                 name:BDSKBibCollectionItemRemovedNotification
                                               object:nil];
    
}

- (void)awakeFromNib{
	// FIXME: for now, hard-code the displaycontroller
	BDSKItemBibTeXDisplayController* c = [[BDSKItemBibTeXDisplayController alloc] init];
	[c setItemSource:self];
	
	[mainSplitView replaceSubview:currentItemDisplayView with:[c view]];
	currentItemDisplayView = [c view];
	currentCollection = [(BDSKLibrary*)[self document] publications]; 
    [self setSelectedItems:[currentCollection items]];
    [self registerForNotifications];
    [self updateInfoLine];
}

- (void)reloadSourceList{
    [sourceList reloadData];
}

- (void)setSelectedItems:(NSArray *)newItems{
    if (newItems != selectedItems){
        [selectedItems autorelease];
        selectedItems = [newItems retain];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibLibrarySelectedItemsChangedNotification	
                                                            object:self];
    }
}

#pragma mark itemSource protocol implementation

- (NSArray *)selectedItems{
    return [[selectedItems retain] autorelease];
}

- (NSArray *)allItems{
    return [currentCollection items];
}

#pragma mark actions

- (IBAction)makeNewPublicationCollection:(id)sender{
    [[(BDSKLibrary*)[self document] publications] addNewSubCollection];
    [self reloadSourceList];
}

- (IBAction)makeNewAuthorCollection:(id)sender{
    [[(BDSKLibrary*)[self document] authors] addNewSubCollection];
    [self reloadSourceList];
}
- (IBAction)makeNewExternalSourceCollection:(id)sender{
    [[(BDSKLibrary*)[self document] sources] addNewSubCollection];
    [self reloadSourceList];
}

- (IBAction)makeNewNoteCollection:(id)sender{
    [[(BDSKLibrary*)[self document] notes] addNewSubCollection];
    [self reloadSourceList];
}

- (IBAction)newPub:(id)sender{
    BibItem *newBI = [[[BibItem alloc] init] autorelease];
    NSString *nowStr = [[NSCalendarDate date] description];
	NSDictionary *dictWithDates = [NSDictionary dictionaryWithObjectsAndKeys:nowStr, BDSKDateCreatedString, nowStr, BDSKDateModifiedString, nil];
	[newBI setPubFields:dictWithDates];	
    
    //@@todo: should find current collection and add to it, not just always to top level.
    
    [(BDSKLibrary*)[self document] addPublicationToLibrary:newBI];
    
}

#pragma mark UI updating

- (void)updateInfoLine{
 	int shownPubsCount = [currentCollection count];
	int totalPubsCount = [selectedItems count];
	
	if (shownPubsCount != totalPubsCount) { 
		// inform people
		[infoLine setStringValue: [NSString stringWithFormat:
			NSLocalizedString(@"%d of %d Publications",
                              @"need two ints in format string."),
            shownPubsCount,totalPubsCount] ];
	}else{
		[infoLine setStringValue:[NSString stringWithFormat:
			NSLocalizedString(@"%d Publications",
							  @"%d Publications (total number)"),
            totalPubsCount]];
	}   
}

#pragma mark notification handling methods

- (void)handleBDSKLibraryControllerSelectionChangedNotification:(NSNotification *)notification{
    [self updateInfoLine];
}

- (void)handleBibCollectionItemAddedNotification:(NSNotification *)notification{
	NSDictionary *userInfo = [notification userInfo];
    id object = [notification object];
    if(object == currentCollection){
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibLibrarySelectedItemsChangedNotification	
                                                            object:self];
    }
}

- (void)handleBibCollectionItemRemovedNotification:(NSNotification *)notification{
	NSDictionary *userInfo = [notification userInfo];
    id object = [notification object];
    if(object == currentCollection){
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibLibrarySelectedItemsChangedNotification	
                                                            object:self];
    }
}

#pragma mark Outlineview datasource methods for Source List

- (void)outlineViewSelectionDidChange:(NSNotification *)notification{
    if (sourceList != [notification object]) return;
	
    id item = [sourceList selectedItem];
    if([item respondsToSelector:@selector(items)]){
		currentCollection = (BibCollection*)item;
        [self setSelectedItems:[currentCollection items]];
    }else{
		[NSException raise:NSInternalInconsistencyException 
					format:@"Selected an item that doesn't yield items"];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibLibrarySelectedItemsChangedNotification	
														object:self];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item{
    if(outlineView != sourceList) [NSException raise:NSInvalidArgumentException 
                                              format:@"OutlineView data source method called by unknown outlineview."];
	
	BDSKLibrary *doc = (BDSKLibrary*)[self document];
    if(item == nil){ // root item is nil
        switch (index){
            case 0: 
                // the Library
                return [doc publications];
            case 1:
                return [doc authors];
            case 2:
                return [doc notes];
            case 3:
                return [doc sources];
            default:
                [NSException raise:NSInvalidArgumentException 
                            format:@"Unknown index of item in OutlineView data source method."];
                return nil;
        }
    }else{
		return [(BibCollection*)item subCollectionAtIndex:index];
    }
	
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
    if(outlineView != sourceList) [NSException raise:NSInvalidArgumentException 
                                              format:@"OutlineView data source method called by unknown outlineview."];
    
    if(item == nil){ // root item is nil
        return YES;
    }else{
		return ([(BibCollection *) item count] > 0);
    }        
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item{
    if(outlineView != sourceList) [NSException raise:NSInvalidArgumentException 
                                              format:@"OutlineView data source method called by unknown outlineview."];
    
    if(item == nil){ // root item is nil
        return 4;
    }else{
		return [(BibCollection *) item count];
    }        
}

- (id)outlineView:(NSOutlineView *)outlineView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
           byItem:(id)item{
    if(outlineView != sourceList) [NSException raise:NSInvalidArgumentException 
                                              format:@"OutlineView data source method called by unknown outlineview."];
    
    if(item == nil){ // root item is nil
        return @"root";
    }else{
		return [item name];
    }        
    
}

// NSOutlineView - drag and drop support

// This method is called after it has been determined that a drag should begin, but before the drag has been started.  To refuse the drag, return NO.  To start a drag, return YES and place the drag data onto the pasteboard (data, owner, etc...).  The drag image and other drag related information will be set up and provided by the outline view once this call returns with YES.  
//The items array is the list of items that will be participating in the drag.

- (BOOL)outlineView:(NSOutlineView *)olv 
         writeItems:(NSArray*)items 
       toPasteboard:(NSPasteboard*)pboard{
    // temporary - at some point we should write each bibitem in a collection to the pb, and allow dragging items from sources to collections/the library.
    return NO;
}

// This method is used by NSOutlineView to determine a valid drop target.  
//Based on the mouse position, the outline view will suggest a proposed drop location.  This method must return a value that indicates which dragging operation the data source will perform.  The data source may "re-target" a drop if desired by calling setDropItem:dropChildIndex: and returning something other than NSDragOperationNone. 
// One may choose to re-target for various reasons (eg. for better visual feedback when inserting into a sorted position).
- (NSDragOperation)outlineView:(NSOutlineView*)olv 
                  validateDrop:(id <NSDraggingInfo>)info 
                  proposedItem:(id)item 
            proposedChildIndex:(int)index{
    if(olv != sourceList) [NSException raise:NSInvalidArgumentException 
									  format:@"OutlineView data source method called by unknown outlineview."];
	
    id draggingSource = [info draggingSource];
    
    NSPasteboard *dragPB = [info draggingPasteboard];
	BDSKLibrary *doc = (BDSKLibrary*)[self document];
    
    if(item == nil){
        // redirect moves onto general space to the library.
        // note that this might get adjusted in the next if-block
        // if the drag is bibitems from our own table, in which case
        // drags back to the library don't make a lot of sense.
        [olv setDropItem:doc dropChildIndex:NSOutlineViewDropOnItemIndex];
        item = doc;
        index = NSOutlineViewDropOnItemIndex;
    }
    
    if(draggingSource){
		// fixme!!
		//&& [localDragPboard hasType:BDSKBibItemLocalDragPboardType]){
		
        // we are dragging bibitems from within bibdesk (and within our own document)
        // note that draggingSource might be the calling outline view, aka sourceList, aka olv.
        //  onto a collection, allow it. 
        //  onto anywhere else, retarget to collections:0, making new collection...
        if((item == [doc publications] || [[[doc publications] subCollections] containsObject:item] )
		   && index == NSOutlineViewDropOnItemIndex){
            return NSDragOperationCopy;
        }else{
            [olv setDropItem:[doc publications] dropChildIndex:0];
            return NSDragOperationCopy;
        }
    }
    
    if([[dragPB types] containsObject:NSStringPboardType]){
        // if we're dropping text, allow it in library or collections or notes
        if(item == [doc sources]){
            [olv setDropItem:[doc publications] dropChildIndex:NSOutlineViewDropOnItemIndex];
        }
        return NSDragOperationCopy;
    }else{
        // if we're dropping random data (ie, image, etc) allow it on notes only.
        NSLog(@"NON STRING OR LOCAL DATA DROP proposed item:%@ index: %d", item, index);
        if(item != [doc notes]){
            [olv setDropItem:[doc publications] dropChildIndex:NSOutlineViewDropOnItemIndex];
        }
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}


// This method is called when the mouse is released over an outline view that previously decided to allow a drop via the validateDrop method.  The data source should incorporate the data from the dragging pasteboard at this time.
- (BOOL)outlineView:(NSOutlineView*)olv acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index{
    if(olv != sourceList) [NSException raise:NSInvalidArgumentException 
                                      format:@"OutlineView data source method called by unknown outlineview."];
    
    id draggingSource = [info draggingSource];
    
    NSPasteboard *dragPB = [info draggingPasteboard];
	BDSKLibrary *doc = (BDSKLibrary*)[self document];

    if(draggingSource ){//fixme!!
	   //&& [localDragPboard hasType:BDSKBibItemLocalDragPboardType]){
        if(index == NSOutlineViewDropOnItemIndex){
            [(BibCollection *) item addItemsFromArray:draggedItems];
        }else{
            BibCollection *newBC = [[BibCollection alloc] initWithParent:self];
            [newBC setItems:draggedItems];
            [(NSMutableArray *) item addObject:[newBC autorelease]];
            [self reloadSourceList];
            [olv expandItem:[doc publications]];
            [olv selectRow:[olv rowForItem:newBC] byExtendingSelection:NO];
            [olv editColumn:0 row:[olv rowForItem:newBC]
                  withEvent:nil
                     select:YES];
        }
        [draggedItems removeAllObjects];
    }
    
    return YES;
}

// Delegate methods:

// NSTableView replacements
//- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item;

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item{
    BDSKLibrary *doc = (BDSKLibrary*)[self document];
	if (item == nil || 
        item == [doc publications] ||
        item == [doc authors] ||
        item == [doc notes] || 
		item == [doc sources]){
        return NO;
    }else{
        return YES;
    }
}

// Optional method: needed to allow editing.
- (void)outlineView:(NSOutlineView *)olv setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item  {
    [(BibCollection *) item setName: object];
}


// - (BOOL)selectionShouldChangeInOutlineView:(NSOutlineView *)outlineView;

//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item;
//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectTableColumn:(NSTableColumn *)tableColumn;
// NSOutlineView specific
//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item;
//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item;
//- (void)outlineView:(NSOutlineView *)outlineView willDisplayOutlineCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item;




@end
