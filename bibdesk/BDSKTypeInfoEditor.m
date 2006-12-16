//
//  BDSKTypeInfoEditor.m
//  BibDesk
//
//  Created by Christiaan Hofman on 5/4/05.
/*
 This software is Copyright (c) 2005,2006
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

#import "BDSKTypeInfoEditor.h"
#import "BDSKFieldNameFormatter.h"
#import "BDSKTypeNameFormatter.h"
#import "BibAppController.h"
#import "BibTypeManager.h"
#import "NSFileManager_BDSKExtensions.h"
#import "NSIndexSet_BDSKExtensions.h"

#define BDSKTypeInfoRowsPboardType	@"BDSKTypeInfoRowsPboardType"

static BDSKTypeInfoEditor *sharedTypeInfoEditor;

@implementation BDSKTypeInfoEditor

+ (BDSKTypeInfoEditor *)sharedTypeInfoEditor{
    if (!sharedTypeInfoEditor) {
        sharedTypeInfoEditor = [[BDSKTypeInfoEditor alloc] init];
    }
    return sharedTypeInfoEditor;
}

- (id)init
{
    if (self = [super initWithWindowNibName:@"BDSKTypeInfoEditor"]) {
		// we keep a copy to the bundles TypeInfo list to see which items we shouldn't edit
		NSDictionary *tmpDict = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TypeInfo.plist"]];
		// we are only interested in this dictionary
		defaultFieldsForTypesDict = [[tmpDict objectForKey:FIELDS_FOR_TYPES_KEY] retain];
		defaultTypes = [[[tmpDict objectForKey:REQUIRED_TYPES_FOR_FILE_TYPE_KEY] objectForKey:BDSKBibtexString] retain];
		
		fieldsForTypesDict = [[NSMutableDictionary alloc] initWithCapacity:[defaultFieldsForTypesDict count]];
		types = [[NSMutableArray alloc] initWithCapacity:[defaultFieldsForTypesDict count]];
		[self revertTypes]; // this loads the current typeInfo from BibTypeManager
    }
    return self;
}

- (void)dealloc
{
    [fieldsForTypesDict release];
    [types release];
    [defaultFieldsForTypesDict release];
    [defaultTypes release];
    [currentType release];
    [super dealloc];
}

- (void)awakeFromNib
{
    // we want to be able to reorder the items
	[typeTableView registerForDraggedTypes:[NSArray arrayWithObject:BDSKTypeInfoRowsPboardType]];
    [requiredTableView registerForDraggedTypes:[NSArray arrayWithObject:BDSKTypeInfoRowsPboardType]];
    [optionalTableView registerForDraggedTypes:[NSArray arrayWithObject:BDSKTypeInfoRowsPboardType]];
	
    BDSKFieldNameFormatter *fieldNameFormatter = [[[BDSKFieldNameFormatter alloc] init] autorelease];
    BDSKTypeNameFormatter *typeNameFormatter = [[[BDSKTypeNameFormatter alloc] init] autorelease];
    NSTableColumn *tc = [typeTableView tableColumnWithIdentifier:@"type"];
    [[tc dataCell] setFormatter:typeNameFormatter];
	tc = [requiredTableView tableColumnWithIdentifier:@"required"];
    [[tc dataCell] setFormatter:fieldNameFormatter];
	tc = [optionalTableView tableColumnWithIdentifier:@"optional"];
    [[tc dataCell] setFormatter:fieldNameFormatter];
	
	[typeTableView reloadData];
	[requiredTableView reloadData];
	[optionalTableView reloadData];
	
	[self updateButtons];
}

- (void)revertTypes {
	BibTypeManager *btm = [BibTypeManager sharedManager];
	NSMutableDictionary *fieldsDict = [NSMutableDictionary dictionaryWithCapacity:2];
	NSEnumerator *typeEnum = [[btm bibTypesForFileType:BDSKBibtexString] objectEnumerator];
	NSString *type;
	
	[types removeAllObjects];
	[fieldsForTypesDict removeAllObjects];
	while (type = [typeEnum nextObject]) {
		[fieldsDict setObject:[btm requiredFieldsForType:type] forKey:REQUIRED_KEY];
		[fieldsDict setObject:[btm optionalFieldsForType:type] forKey:OPTIONAL_KEY];
		[self addType:type withFields:fieldsDict];
	}
	[types sortUsingSelector:@selector(compare:)];
	
	[typeTableView reloadData];
	[self setCurrentType:nil];
	
	[self setDocumentEdited:NO];
}

# pragma mark Accessors

- (void)addType:(NSString *)newType withFields:(NSDictionary *)fieldsDict {
    [self insertType:newType withFields:fieldsDict atIndex:[types count]];
}

- (void)insertType:(NSString *)newType withFields:(NSDictionary *)fieldsDict atIndex:(unsigned)index {
	[types insertObject:newType atIndex:index];
	
	// create mutable containers for the fields
	NSMutableArray *requiredFields;
	NSMutableArray *optionalFields;
	
	if (fieldsDict) {
		requiredFields = [NSMutableArray arrayWithArray:[fieldsDict objectForKey:REQUIRED_KEY]];
		optionalFields = [NSMutableArray arrayWithArray:[fieldsDict objectForKey:OPTIONAL_KEY]];
	} else {
		requiredFields = [NSMutableArray arrayWithCapacity:1];
		optionalFields = [NSMutableArray arrayWithCapacity:1];
	}
	NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithObjectsAndKeys: requiredFields, REQUIRED_KEY, optionalFields, OPTIONAL_KEY, nil];
	[fieldsForTypesDict setObject:newDict forKey:newType];
}

- (void)setCurrentType:(NSString *)newCurrentType {
    if (currentType == nil || ![currentType isEqualToString:newCurrentType]) {
        [currentType release];
        currentType = [newCurrentType copy];
		
		if (currentType) {
			currentRequiredFields = [[fieldsForTypesDict objectForKey:currentType] objectForKey:REQUIRED_KEY];
			currentOptionalFields = [[fieldsForTypesDict objectForKey:currentType] objectForKey:OPTIONAL_KEY]; 
			currentDefaultRequiredFields = [[defaultFieldsForTypesDict objectForKey:currentType] objectForKey:REQUIRED_KEY];
			currentDefaultOptionalFields = [[defaultFieldsForTypesDict objectForKey:currentType] objectForKey:OPTIONAL_KEY];
		} else {
			currentRequiredFields = nil;
			currentOptionalFields = nil;
			currentDefaultRequiredFields = nil;
			currentDefaultOptionalFields = nil;
		}
		
		[requiredTableView reloadData];
		[optionalTableView reloadData];
		
		[self updateButtons];
    }
}

#pragma mark Actions

- (IBAction)dismiss:(id)sender {
    [[self window] makeFirstResponder:nil]; // commit edit before saving
	
    if ([sender tag] == NSOKButton) {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: 
                    fieldsForTypesDict, FIELDS_FOR_TYPES_KEY, 
                    [NSDictionary dictionaryWithObject:types forKey:BDSKBibtexString], TYPES_FOR_FILE_TYPE_KEY, nil];
        
        NSString *error = nil;
        NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
        NSData *data = [NSPropertyListSerialization dataFromPropertyList:dict
                                                                  format:format 
                                                        errorDescription:&error];
        if (error) {
            NSLog(@"Error writing: %@", error);
            [error release];
        } else {
            NSString *applicationSupportPath = [[NSFileManager defaultManager] currentApplicationSupportPathForCurrentUser]; 
            NSString *typeInfoPath = [applicationSupportPath stringByAppendingPathComponent:TYPE_INFO_FILENAME];
            [data writeToFile:typeInfoPath atomically:YES];
        }
        
        [[BibTypeManager sharedManager] reloadTypeInfo];
        
        [self setDocumentEdited:NO];
    } else {
        [self revertTypes];
    }
	
    [super dismiss:sender];
}

- (IBAction)addType:(id)sender {
	NSString *newType = [NSString stringWithString:@"new-type"];
	int i = 0;
	while ([types containsObject:newType]) {
		newType = [NSString stringWithFormat:@"new-type-%i",++i];
	}
	[self addType:newType withFields:nil];
	
    [typeTableView reloadData];
	
    int row = [types indexOfObject:newType];
    [typeTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[[[typeTableView tableColumnWithIdentifier:@"type"] dataCell] setEnabled:YES];
    [typeTableView editColumn:0 row:row withEvent:nil select:YES];
	
	[self setDocumentEdited:YES];
}

- (IBAction)removeType:(id)sender {
	NSIndexSet *indexesToRemove = [typeTableView selectedRowIndexes];
	NSArray *typesToRemove = [types objectsAtIndexes:indexesToRemove];
	
	// make sure we stop editing
	[[self window] makeFirstResponder:typeTableView];
	
	[types removeObjectsAtIndexes:indexesToRemove];
	[fieldsForTypesDict removeObjectsForKeys:typesToRemove];
	
    [typeTableView reloadData];
    [typeTableView deselectAll:nil];
	
	[self setDocumentEdited:YES];
}

- (IBAction)addRequired:(id)sender {
	NSString *newField = [NSString stringWithString:@"New-Field"];
	int i = 0;
	while ([currentRequiredFields containsObject:newField]) {
		newField = [NSString stringWithFormat:@"New-Field-%i",++i];
	}
	[currentRequiredFields addObject:newField];
	
    [requiredTableView reloadData];
	
    int row = [currentRequiredFields indexOfObject:newField];
    [requiredTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[[[requiredTableView tableColumnWithIdentifier:@"required"] dataCell] setEnabled:YES];
    [requiredTableView editColumn:0 row:row withEvent:nil select:YES];
	
	[self setDocumentEdited:YES];
}

- (IBAction)removeRequired:(id)sender  {
	NSIndexSet *indexesToRemove = [requiredTableView selectedRowIndexes];
	
	// make sure we stop editing
	[[self window] makeFirstResponder:requiredTableView];
	
	[currentRequiredFields removeObjectsAtIndexes:indexesToRemove];
	
    [requiredTableView reloadData];
    [requiredTableView deselectAll:nil];
	
	[self setDocumentEdited:YES];
}

- (IBAction)addOptional:(id)sender {
	NSString *newField = [NSString stringWithString:@"New-Field"];
	int i = 0;
	while ([currentOptionalFields containsObject:newField]) {
		newField = [NSString stringWithFormat:@"New-Field-%i",++i];
	}
	[currentOptionalFields addObject:newField];
	
    [optionalTableView reloadData];
	
    int row = [currentOptionalFields indexOfObject:newField];
    [optionalTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[[[optionalTableView tableColumnWithIdentifier:@"optional"] dataCell] setEnabled:YES];
    [optionalTableView editColumn:0 row:row withEvent:nil select:YES];
	
	[self setDocumentEdited:YES];
}

- (IBAction)removeOptional:(id)sender {
	NSIndexSet *indexesToRemove = [optionalTableView selectedRowIndexes];
	
	// make sure we stop editing
	[[self window] makeFirstResponder:optionalTableView];

	[currentOptionalFields removeObjectsAtIndexes:indexesToRemove];
	
	[optionalTableView reloadData];
	[optionalTableView deselectAll:nil];
	
	[self setDocumentEdited:YES];
}

- (IBAction)revertCurrentToDefault:(id)sender {
	if (currentType == nil) 
		return;
	
	// make sure we stop editing
	[[self window] makeFirstResponder:nil];
	
	[currentRequiredFields removeAllObjects];
	[currentRequiredFields addObjectsFromArray:currentDefaultRequiredFields];
	[currentOptionalFields removeAllObjects];
	[currentOptionalFields addObjectsFromArray:currentDefaultOptionalFields];
	
	[requiredTableView reloadData];
	[optionalTableView reloadData];
	
	[self setDocumentEdited:YES];
}

- (IBAction)revertAllToDefault:(id)sender {
	NSEnumerator *typeEnum = [defaultFieldsForTypesDict keyEnumerator];
	NSString *type;
	
	// make sure we stop editing
	[[self window] makeFirstResponder:nil];
	
	[fieldsForTypesDict removeAllObjects];
	[types removeAllObjects];
	while (type = [typeEnum nextObject]) {
		[self addType:type withFields:[defaultFieldsForTypesDict objectForKey:type]];
	}
	[types sortUsingSelector:@selector(compare:)];
	[typeTableView reloadData];
	[self setCurrentType:nil];
	
	[self setDocumentEdited:YES];
}

#pragma mark validation methods

- (BOOL)canEditType:(NSString *)type {
	return (![defaultTypes containsObject:type]);
}

- (BOOL)canEditField:(NSString *)field{
	if (currentType == nil) // there is nothing to edit
		return NO;
	if (![defaultTypes containsObject:currentType]) // we allow any edits for non-default types
		return YES;
	if ([currentDefaultRequiredFields containsObject:field] ||
		[currentDefaultOptionalFields containsObject:field]) // we don't allow edits of default fields for default types
		return NO;
	return YES; // any other fields of default types can be removed
}

- (BOOL)canEditTableView:(NSTableView *)tv row:(int)row{
	if (tv == typeTableView)
		return [self canEditType:[types objectAtIndex:row]];
	if ([self canEditType:currentType])
		return YES; // if we can edit the type, we can edit all the fields
	if (tv == requiredTableView)
		return [self canEditField:[currentRequiredFields objectAtIndex:row]];
	if (tv == optionalTableView)
		return [self canEditField:[currentOptionalFields objectAtIndex:row]];
    return NO;
}

- (void)updateButtons {
	NSIndexSet *rowIndexes;
	int row;
	BOOL canRemove;
	NSString *value;
	
	[addTypeButton setEnabled:YES];
	
	if ([typeTableView numberOfSelectedRows] == 0) {
		[removeTypeButton setEnabled:NO];
	} else {
		rowIndexes = [typeTableView selectedRowIndexes];
		row = [rowIndexes firstIndex];
		canRemove = YES;
		while (row != NSNotFound) {
			value = [types objectAtIndex:row];
			if (![self canEditType:value]) {
				canRemove = NO;
				break;
			}
			row = [rowIndexes indexGreaterThanIndex:row];
		}
		[removeTypeButton setEnabled:canRemove];
	}
	
	[addRequiredButton setEnabled:currentType != nil];
	
	if ([requiredTableView numberOfSelectedRows] == 0) {
		[removeRequiredButton setEnabled:NO];
	} else {
		rowIndexes = [requiredTableView selectedRowIndexes];
		row = [rowIndexes firstIndex];
		canRemove = YES;
		while (row != NSNotFound) {
			value = [currentRequiredFields objectAtIndex:row];
			if (![self canEditField:value]) {
				canRemove = NO;
				break;
			}
			row = [rowIndexes indexGreaterThanIndex:row];
		}
		[removeRequiredButton setEnabled:canRemove];
	}
	
	[addOptionalButton setEnabled:currentType != nil];
	
	if ([optionalTableView numberOfSelectedRows] == 0) {
		[removeOptionalButton setEnabled:NO];
	} else {
		rowIndexes = [optionalTableView selectedRowIndexes];
		row = [rowIndexes firstIndex];
		canRemove = YES;
		while (row != NSNotFound) {
			value = [currentOptionalFields objectAtIndex:row];
			if (![self canEditField:value]) {
				canRemove = NO;
				break;
			}
			row = [rowIndexes indexGreaterThanIndex:row];
		}
		[removeOptionalButton setEnabled:canRemove];
	}
	
	[revertCurrentToDefaultButton setEnabled:(currentType && [defaultFieldsForTypesDict objectForKey:currentType])];
}

#pragma mark NSTableview datasource

- (int)numberOfRowsInTableView:(NSTableView *)tv {
	if (tv == typeTableView) {
		return [types count];
	}
	
	if (currentType == nil) return 0;
	
	if (tv == requiredTableView) {
		return [currentRequiredFields count];
	}
	else if (tv == optionalTableView) {
		return [currentOptionalFields count];
	}
    // not reached
    return 0;
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	if (tv == typeTableView) {
		return [types objectAtIndex:row];
	}
	else if (tv == requiredTableView) {
		return [currentRequiredFields objectAtIndex:row];
	}
	else if (tv == optionalTableView) {
		return [currentOptionalFields objectAtIndex:row];
	}
    // not reached
    return nil;
}

- (void)tableView:(NSTableView *)tv setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	NSString *oldValue;
	NSString *newValue;
	
	if (tv == typeTableView) {
        // NSDictionary copies its keys, so types may be the only thing retaining oldValue (see bug #1596532)
		oldValue = [[[types objectAtIndex:row] retain] autorelease];
		newValue = [(NSString *)object entryType];
		if (![newValue isEqualToString:oldValue] && 
			![types containsObject:newValue]) {
			
			[types replaceObjectAtIndex:row withObject:newValue];
			[fieldsForTypesDict setObject:[fieldsForTypesDict objectForKey:oldValue] forKey:newValue];
			[fieldsForTypesDict removeObjectForKey:oldValue];
			[self setCurrentType:newValue];
			
			[self setDocumentEdited:YES];
		}
	}
	else if (tv == requiredTableView) {
		oldValue = [currentRequiredFields objectAtIndex:row];
		newValue = [(NSString *)object fieldName];
		if (![newValue isEqualToString:oldValue] && 
			![currentRequiredFields containsObject:newValue] && 
			![currentOptionalFields containsObject:newValue]) {
			
			[currentRequiredFields replaceObjectAtIndex:row withObject:newValue];
			
			[self setDocumentEdited:YES];
		}
	}
	else if (tv == optionalTableView) {
		oldValue = [currentOptionalFields objectAtIndex:row];
		newValue = [(NSString *)object fieldName];
		if (![newValue isEqualToString:oldValue] && 
			![currentRequiredFields containsObject:newValue] && 
			![currentOptionalFields containsObject:newValue]) {
			
			[currentOptionalFields replaceObjectAtIndex:row withObject:newValue];
			
			[self setDocumentEdited:YES];
		}
	}
}

#pragma mark NSTableview delegate

- (BOOL)tableView:(NSTableView *)tv shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	return [self canEditTableView:tv row:row];
}

- (void)tableView:(NSTableView *)tv willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	if ([self canEditTableView:tv row:row]) {
		[cell setTextColor:[NSColor controlTextColor]]; // when selected, this is automatically changed to white
	} else if ([[self window] isKeyWindow] && [[[self window] firstResponder] isEqual:tv] && [tv isRowSelected:row]) {
		[cell setTextColor:[NSColor lightGrayColor]]; // selected disabled
	} else {
		[cell setTextColor:[NSColor darkGrayColor]]; // unselected disabled
	}
}

#pragma mark NSTableView dragging

- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard {
	// we only drag our own rows
	[pboard declareTypes: [NSArray arrayWithObject:BDSKTypeInfoRowsPboardType] owner:self];
	// write the rows to the pasteboard
	[pboard setPropertyList:rows forType:BDSKTypeInfoRowsPboardType];
	return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
	if ([info draggingSource] != tv) // we don't allow dragging between tables, as we want to keep default types in the same place
		return NSDragOperationNone;
	
	if (row == -1) // redirect drops on the table to the first item
		[tv setDropRow:0 dropOperation:NSTableViewDropAbove];
	if (op == NSTableViewDropOn) // redirect drops on an item
		[tv setDropRow:row dropOperation:NSTableViewDropAbove];
	
    if (tv == typeTableView && [info draggingSourceOperationMask] == NSDragOperationCopy)
        return NSDragOperationCopy;
	else
        return NSDragOperationMove;
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo> )info row:(int)row dropOperation:(NSTableViewDropOperation)op {
	NSPasteboard *pboard = [info draggingPasteboard];
	NSArray *rows = [pboard propertyListForType:BDSKTypeInfoRowsPboardType];
    NSIndexSet *insertIndexes;
	
    if (tv == typeTableView && [info draggingSourceOperationMask] == NSDragOperationCopy) {
        
        NSEnumerator *typeEnum = [[types objectsAtIndexes:[NSIndexSet indexSetWithIndexesInArray:rows]] objectEnumerator];
        NSString *type;
        NSString *newType;
        int i;
        
        insertIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, [rows count])];
        
        while (type = [typeEnum nextObject]) {
            newType = [NSString stringWithFormat:@"%@-copy", type];
            i = 0;
            while ([types containsObject:newType]) {
                newType = [NSString stringWithFormat:@"%@-copy-%i", type, ++i];
            }
            [self insertType:newType withFields:[fieldsForTypesDict objectForKey:type] atIndex:row];
        }
        
    } else {
        
        NSEnumerator *rowEnum = [rows objectEnumerator];
        NSNumber *rowNum;
        int i;
        int insertRow = row;
        NSMutableArray *fields = nil;
        NSArray *draggedFields;
        NSMutableIndexSet *removeIndexes = [NSMutableIndexSet indexSet];
        
        // find the array of fields
        if (tv == typeTableView) {
            fields = types;
        } else if (tv == requiredTableView) {
            fields = currentRequiredFields;
        } else if (tv == optionalTableView) {
            fields = currentOptionalFields;
        }
        
        NSAssert(fields != nil, @"An error occurred:  fields must not be nil when dragging");
        
        while (rowNum = [rowEnum nextObject]) {
            i = [rowNum intValue];
            if (i < row) insertRow--;
            [removeIndexes addIndex:i];
        }
        
        draggedFields = [fields objectsAtIndexes:removeIndexes];
        insertIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertRow, [rows count])];
        [fields removeObjectsAtIndexes:removeIndexes];
        [fields insertObjects:draggedFields atIndexes:insertIndexes];
        
    }
    
    // select the moved rows
    if(![tv allowsMultipleSelection])
        insertIndexes = [NSIndexSet indexSetWithIndex:[insertIndexes firstIndex]];
    [tv selectRowIndexes:insertIndexes byExtendingSelection:NO];
    [tv reloadData];
    
    [self setDocumentEdited:YES];
    
    return YES;
}

#pragma mark NSTableView notifications

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSTableView *tv = [aNotification object];
	
	if (tv == typeTableView) {
		if ([typeTableView numberOfSelectedRows] == 1) {
			[self setCurrentType:[types objectAtIndex:[typeTableView selectedRow]]];
		} else {
			[self setCurrentType:nil];
		}
		// the fields changed, so update their tableViews
		[requiredTableView reloadData];
		[optionalTableView reloadData];
	}
	[self updateButtons];
}

#pragma mark Splitview delegate methods

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset{
	return proposedMin + 50.0;
}

- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset{
	return proposedMax - 50.0;
}

@end
