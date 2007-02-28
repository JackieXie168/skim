//
//  BibPersonController.m
//  BibDesk
//
//  Created by Michael McCracken on Thu Mar 18 2004.
/*
 This software is Copyright (c) 2004,2005,2006,2007
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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

#import "BibPersonController.h"
#import "BibTypeManager.h"
#import "BDSKOwnerProtocol.h"
#import "BibDocument.h"
#import "BibDocument_Actions.h"
#import "BibAuthor.h"
#import "BibItem.h"
#import "BibTeXParser.h"
#import "BDSKCollapsibleView.h"
#import "BDSKDragImageView.h"
#import "BDSKPublicationsArray.h"
#import "NSWindowController_BDSKExtensions.h"
#import "NSImage+Toolbox.h"
#import <AddressBook/AddressBook.h>

@implementation BibPersonController

#pragma mark initialization

+ (void)initialize{
    [self setKeys:[NSArray arrayWithObject:@"document"] triggerChangeNotificationsForDependentKey:@"publications"];
}

- (NSString *)windowNibName{return @"BibPersonView";}

- (id)initWithPerson:(BibAuthor *)aPerson{

    self = [super initWithWindowNibName:@"BibPersonView"];
	if(self){
        [self setPerson:aPerson];
        publications = nil;
        
        isEditable = [[[person publication] owner] isDocument];
        
        [person setPersonController:self];
	}
	return self;

}

- (void)dealloc{
    [pubsTableView setDelegate:nil];
    [pubsTableView setDataSource:nil];
    [person setPersonController:nil];
    [person release];
    [publications release];
    [super dealloc];
}

- (void)awakeFromNib{
	if ([[self superclass] instancesRespondToSelector:@selector(awakeFromNib)]){
        [super awakeFromNib];
	}
	
	[collapsibleView setMinSize:NSMakeSize(0.0, 38.0)];
	[imageView setDelegate:self];
	[splitView setPositionAutosaveName:@"OASplitView Position BibPersonView"];
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePubListChanged:)
                                                 name:BDSKAuthorPubListChangedNotification 
                                               object:nil]; 
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBibItemChanged:)
                                                 name:BDSKBibItemChangedNotification
                                               object:nil];
    if(isEditable == NO)
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleGroupWillBeRemoved:)
                                                         name:BDSKDidAddRemoveGroupNotification
                                                       object:nil];

	[self updateUI];
    [pubsTableView setDoubleAction:@selector(openSelectedPub:)];
    
    if (isEditable)
        [imageView registerForDraggedTypes:[NSArray arrayWithObject:NSVCardPboardType]];
    
    [nameTextField setEditable:isEditable];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName{
    return [person name];
}

- (NSString *)representedFilenameForWindow:(NSWindow *)aWindow {
    return [[[person publication] owner] isDocument] ? nil : @"";
}

#pragma mark accessors

- (NSArray *)publications{
    if (publications == nil)
        publications = [[[[[person publication] owner] publications] itemsForAuthor:person] retain];
    return publications;
}

- (void)setPublications:(NSArray *)pubs{
    if(publications != pubs){
        [publications release];
        publications = [pubs copy];
    }
}

- (BibAuthor *)person {
    return person;
}

- (void)setPerson:(BibAuthor *)newPerson {
    if(newPerson != person){
        [person release];
        person = [newPerson copy];
    }
}

// binding directly to person.personFromAddressBook.imageData in IB doesn't work for some reason
- (NSData *)imageData{
    return [[person personFromAddressBook] imageData] ? [[person personFromAddressBook] imageData] : [[NSImage imageForFileType:@"vcf"] TIFFRepresentation];
}

#pragma mark actions

- (void)show{
    [self showWindow:self];
}

- (void)updateUI{
	[nameTextField setStringValue:[person name]];
	[pubsTableView reloadData];
}

- (void)handlePubListChanged:(NSNotification *)notification{
	[self updateUI]; 
}

- (void)handleBibItemChanged:(NSNotification *)note{
    // we may be adding or removing items, so we can't check publications for containment
    [self setPublications:nil];
}

- (void)handleGroupWillBeRemoved:(NSNotification *)note{
	NSArray *groups = [[note userInfo] objectForKey:@"groups"];
	
	if ([groups containsObject:[[person publication] owner]])
		[self close];
}

- (void)openSelectedPub:(id)sender{
    int row = [pubsTableView selectedRow];
    NSAssert(row >= 0, @"Cannot perform double-click action when no row is selected");
    [(BibDocument *)[self document] editPub:[publications objectAtIndex:row]];
}

- (void)changeNameWarningSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode newName:(NSString *)newNameString;
{
    if(returnCode == NSAlertDefaultReturn)
        [self changeNameToString:newNameString];
    else
        [self updateUI];
	[newNameString release];
}


- (void)controlTextDidEndEditing:(NSNotification *)aNotification;
{
    id sender = [aNotification object];
    if(sender == nameTextField && [sender isEditable]) // this shouldn't be called for uneditable cells, but it is
        NSBeginAlertSheet(NSLocalizedString(@"Really Change Name?", @"Message in alert dialog when trying to edit author name"),  NSLocalizedString(@"Yes", @"Button title"), NSLocalizedString(@"No", @"Button title"), nil, [self window], self, @selector(changeNameWarningSheetDidEnd:returnCode:newName:), NULL, [[sender stringValue] retain], NSLocalizedString(@"This will change matching names in any \"person\" field (e.g. \"Author\" and \"Editor\") of the publications shown in the list below.  Do you want to do this?", @"Informative text in alert dialog"));
}

- (void)changeNameToString:(NSString *)newNameString{
    
    NSUndoManager *undoManager = [[self window] undoManager];
    
    // @@ undo on our window is a no-op without this
    if(undoManager)
        [[undoManager prepareWithInvocationTarget:self] changeNameToString:[person name]];
    
    NSEnumerator *pubE = [publications objectEnumerator];
    BibItem *pub = nil;
    
    // @@ maybe handle this in the type manager?
    NSArray *fieldNames = [[[BibTypeManager sharedManager] personFieldsSet] allObjects];
    NSArray *peopleFromString;
    CFIndex numberOfFields = [fieldNames count];
    NSString *fieldName;
    
    CFMutableArrayRef people = CFArrayCreateMutable(CFAllocatorGetDefault(), 0, &BDSKAuthorFuzzyArrayCallBacks);
    CFIndex index, fieldIndex;
    BibAuthor *newAuthor;
    
    // we set our person at some point in the iteration, so copy the current value now
    BibAuthor *oldPerson = [[person copy] autorelease];

    while(pub = [pubE nextObject]){
        
        // change for both author and editor, if possible; we don't know if this person is an author or editor for a given publication, but presumably we want uniform names throughout
        for(fieldIndex = 0; fieldIndex < numberOfFields; fieldIndex++){
            fieldName = [fieldNames objectAtIndex:fieldIndex];
            
            // create a new array of BibAuthor objects from a person field (which may be nil or empty)
            peopleFromString = [BibTeXParser authorsFromBibtexString:[pub valueOfField:fieldName] withPublication:pub];
                    
            if([peopleFromString count]){
                
                CFRange range = CFRangeMake(0, [peopleFromString count]);            
                CFArrayAppendArray(people, (CFArrayRef)peopleFromString, range);
                
                // use the fuzzy compare to find which author we're going to replace
                index = CFArrayGetFirstIndexOfValue(people, range, (const void *)oldPerson);
                if(index != -1){
                    // replace this author, then create a new BibTeX author string
                    newAuthor = [BibAuthor authorWithName:newNameString andPub:pub];
                    CFArraySetValueAtIndex(people, index, newAuthor);
                    [pub setField:fieldName toValue:[(NSArray *)people componentsJoinedByString:@" and "]];
                    if([pub isEqual:[person publication]])
                        [self setPerson:newAuthor]; // changes the window title
                }
                CFArrayRemoveAllValues(people);
            }
        }
    }
    CFRelease(people);
    
	[undoManager setActionName:NSLocalizedString(@"Change Author Name", @"Undo action name")];
    
    // needed to update our tableview with the new publications list after setting a new person
    [self handleBibItemChanged:nil];

	[self updateUI];
}

#pragma mark TableView delegate

- (NSString *)tableViewFontNamePreferenceKey:(NSTableView *)tv {
    if (tv == pubsTableView)
        return BDSKPersonTableViewFontNameKey;
    else 
        return nil;
}

- (NSString *)tableViewFontSizePreferenceKey:(NSTableView *)tv {
    if (tv == pubsTableView)
        return BDSKPersonTableViewFontSizeKey;
    else 
        return nil;
}

#pragma mark Dragging delegate methods

- (NSDragOperation)dragImageView:(BDSKDragImageView *)view validateDrop:(id <NSDraggingInfo>)sender {
    if(isEditable == NO)
        return NO;
    
    if ([[sender draggingSource] isEqual:view])
		return NSDragOperationNone;
	
	NSPasteboard *pboard = [sender draggingPasteboard];
    
    if([[pboard types] containsObject:NSVCardPboardType])
        return NSDragOperationCopy;

    return NSDragOperationNone;
}

- (BOOL)dragImageView:(BDSKDragImageView *)view acceptDrop:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if([[pboard types] containsObject:NSVCardPboardType] == NO)
        return NO;
	
	BibAuthor *newAuthor = [BibAuthor authorWithVCardRepresentation:[pboard dataForType:NSVCardPboardType] andPub:nil];
	
	if([newAuthor isEqual:[BibAuthor emptyAuthor]])
		return NO;
	
    NSBeginAlertSheet(NSLocalizedString(@"Really Change Name?", @"Message in alert dialog when trying to edit author name"),  NSLocalizedString(@"Yes", @"Button title"), NSLocalizedString(@"No", @"Button title"), nil, [self window], self, @selector(changeNameWarningSheetDidEnd:returnCode:newName:), NULL, [[newAuthor name] retain], NSLocalizedString(@"This will change matching names in any \"person\" field (e.g. \"Author\" and \"Editor\") of the publications shown in the list below.  Do you want to do this?", @"Informative text in alert dialog"));
    return YES;
}

- (BOOL)dragImageView:(BDSKDragImageView *)view writeDataToPasteboard:(NSPasteboard *)pboard {
	[pboard declareTypes:[NSArray arrayWithObjects:NSVCardPboardType, NSFilesPromisePboardType, nil] owner:nil];

	// if we don't have a match in the address book, this will create a new person record
	NSData *data = [[ABPerson personWithAuthor:person] vCardRepresentation];
	OBPOSTCONDITION(data);

	if(data == nil)
		return NO;
		
	[pboard setData:data forType:NSVCardPboardType];
	[pboard setPropertyList:[NSArray arrayWithObject:[[person name] stringByAppendingPathExtension:@"vcf"]] forType:NSFilesPromisePboardType];
	return YES;
}

- (NSArray *)dragImageView:(BDSKDragImageView *)view namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination {
    NSData *data = [[ABPerson personWithAuthor:person] vCardRepresentation];
    NSString *fileName = [[person name] stringByAppendingPathExtension:@"vcf"];
    [data writeToFile:[[dropDestination path] stringByAppendingPathComponent:fileName] atomically:YES];
    
    return [NSArray arrayWithObject:fileName];
}
 
- (NSImage *)dragImageForDragImageView:(BDSKDragImageView *)view {
	return [[NSImage imageForFileType:@"vcf"] dragImageWithCount:1];
}

#pragma mark Splitview delegate methods

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
    NSView *pickerView = [[splitView subviews] objectAtIndex:0];
    NSView *pubsView = [[splitView subviews] objectAtIndex:1];
    NSRect pubsFrame = [pubsView frame];
    NSRect pickerFrame = [pickerView frame];
    float factor = (NSWidth([sender frame]) - [sender dividerThickness]) / (oldSize.width - [sender dividerThickness]);
	
	if (sender == splitView) {
		// pubs = table, picker = preview
        pickerFrame.size.width *= factor;
        if (NSWidth(pickerFrame) < 1.0)
            pickerFrame.size.width = 0.0;
        pickerFrame = NSIntegralRect(pickerFrame);
        pubsFrame.size.width = NSWidth([sender frame]) - NSWidth(pickerFrame) - [sender dividerThickness];
        if (NSWidth(pubsFrame) < 0.0) {
            pubsFrame.size.width = 0.0;
            pickerFrame.size.width = NSWidth([sender frame]) - NSWidth(pubsFrame) - [sender dividerThickness];
        }
	} else {
        pubsFrame.size.width *= factor;
        if (NSWidth(pubsFrame) < 1.0)
            pubsFrame.size.width = 0.0;
        pubsFrame = NSIntegralRect(pubsFrame);
        pickerFrame.size.width = NSWidth([sender frame]) - NSWidth(pubsFrame) - [sender dividerThickness];
        if (NSWidth(pubsFrame) < 0.0) {
            pickerFrame.size.width = 0.0;
            pubsFrame.size.width = NSWidth([sender frame]) - NSWidth(pickerFrame) - [sender dividerThickness];
        }
    }
	
	[pubsView setFrame:pubsFrame];
	[pickerView setFrame:pickerFrame];
    [sender adjustSubviews];
}

- (void)splitViewDoubleClick:(OASplitView *)sender{
    NSView *pickerView = [[splitView subviews] objectAtIndex:0];
    NSView *pubsView = [[splitView subviews] objectAtIndex:1];
    NSRect pubsFrame = [pubsView frame];
    NSRect pickerFrame = [pickerView frame];
    
    if(NSHeight(pickerFrame) > 0.0){ // can't use isSubviewCollapsed, because implementing splitView:canCollapseSubview: prevents uncollapsing
        lastPickerHeight = NSHeight(pickerFrame); // cache this
        pubsFrame.size.height += lastPickerHeight;
        pickerFrame.size.height = 0;
    } else {
        if(lastPickerHeight <= 0)
            lastPickerHeight = 150.0; // a reasonable value to start
		pickerFrame.size.height = lastPickerHeight;
        pubsFrame.size.height = NSHeight([splitView frame]) - lastPickerHeight - [splitView dividerThickness];
    }
    [pubsView setFrame:pubsFrame];
    [pickerView setFrame:pickerFrame];
    [splitView adjustSubviews];
	// fix for NSSplitView bug, which doesn't send this in adjustSubviews
	[[NSNotificationCenter defaultCenter] postNotificationName:NSSplitViewDidResizeSubviewsNotification object:splitView];
}

@end
