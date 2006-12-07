//
//  BDSKErrorObjectController.m
//  Bibdesk
//
//  Created by Adam Maxwell on 08/12/05.
/*
 This software is Copyright (c) 2005,2006
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

#import "BDSKErrorObjectController.h"
#import <OmniBase/assertions.h>
#import <BTParse/BDSKErrorObject.h>
#import "BDSKErrorManager.h"
#import "BDSKErrorEditor.h"
#import "BibPrefController.h"
#import "BDSKOwnerProtocol.h"
#import "BibDocument.h"
#import "BibDocument_Actions.h"
#import "BibItem.h"
#import "BibEditor.h"
#import "NSWindowController_BDSKExtensions.h"
#import "BDSKPublicationsArray.h"

// put it here because IB chokes on it
@interface BDSKLineNumberTransformer : NSValueTransformer @end

#pragma mark -

@implementation BDSKErrorObjectController

static BDSKErrorObjectController *sharedErrorObjectController = nil;

+ (void)initialize;
{
    OBINITIALIZE;
	[NSValueTransformer setValueTransformer:[[[BDSKLineNumberTransformer alloc] init] autorelease]
									forName:@"BDSKLineNumberTransformer"];
}

+ (BDSKErrorObjectController *)sharedErrorObjectController;
{
    if(!sharedErrorObjectController)
        sharedErrorObjectController = [[BDSKErrorObjectController alloc] init];
    return sharedErrorObjectController;
}

- (id)init;
{
    if(self = [super initWithWindowNibName:[self windowNibName]]){
        if(sharedErrorObjectController){
            [self release];
            self = sharedErrorObjectController;
        } else {
            errors = [[NSMutableArray alloc] initWithCapacity:10];
            managers = [[NSMutableArray alloc] initWithCapacity:4];
            lastIndex = 0;
            handledNonIgnorableError = NO;
            
            [managers addObject:[BDSKErrorManager allItemsErrorManager]];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleErrorNotification:)
                                                         name:BDSKParserErrorNotification
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleRemoveDocumentNotification:)
                                                         name:BDSKDocumentControllerRemoveDocumentNotification
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleRemovePublicationNotification:)
                                                         name:BDSKDocDelItemNotification
                                                       object:nil];
        }
    }
    
    return self;
}

- (NSString *)windowNibName;
{
    return @"BDSKErrorPanel";
}


- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [errors release];
    [managers release];
    [currentErrors release];
    [super dealloc];
}

- (void)awakeFromNib;
{
    [errorTableView setDoubleAction:@selector(gotoError:)];
    
    [errorsController setFilterManager:[BDSKErrorManager allItemsErrorManager]];
    [errorsController setHideWarnings:NO];
}

#pragma mark Accessors

#pragma mark | errors

- (NSArray *)errors {
    return errors;
}

- (unsigned)countOfErrors {
    return [errors count];
}

- (id)objectInErrorsAtIndex:(unsigned)index {
    return [errors objectAtIndex:index];
}

- (void)insertObject:(id)obj inErrorsAtIndex:(unsigned)index {
    [errors insertObject:obj atIndex:index];
}

- (void)removeObjectFromErrorsAtIndex:(unsigned)index {
    [errors removeObjectAtIndex:index];
}

#pragma mark | managers

- (NSArray *)managers {
    return managers;
}

- (unsigned)countOfManagers {
    return [managers count];
}

- (id)objectInManagersAtIndex:(unsigned)theIndex {
    return [managers objectAtIndex:theIndex];
}

- (void)insertObject:(id)obj inManagersAtIndex:(unsigned)theIndex {
    [managers insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromManagersAtIndex:(unsigned)theIndex {
    [managers removeObjectAtIndex:theIndex];
}

- (void)addManager:(BDSKErrorManager *)manager{
    [manager setErrorController:self];
    [self insertObject:manager inManagersAtIndex:[self countOfManagers]];
}

- (void)removeManager:(BDSKErrorManager *)manager{
    if ([errorsController filterManager] == manager)
        [errorsController setFilterManager:[BDSKErrorManager allItemsErrorManager]];
    [manager setErrorController:nil];
    [self removeObjectFromManagersAtIndex:[managers indexOfObject:manager]];
}

#pragma mark Getting managers and editors

- (BDSKErrorManager *)managerForDocument:(BibDocument *)document create:(BOOL)create{
    NSEnumerator *mEnum = [managers objectEnumerator];
    BDSKErrorManager *manager = nil;
    
    while(manager = [mEnum nextObject]){
        if(document == [manager sourceDocument])
                break;
    }
    
    if(manager == nil && create){
        manager = [(BDSKErrorManager *)[BDSKErrorManager alloc] initWithDocument:document];
        [self addManager:manager];
        [manager release];
    }
    
    return manager;
}

- (BDSKErrorEditor *)editorForDocument:(BibDocument *)document create:(BOOL)create{
    BDSKErrorManager *manager = [self managerForDocument:document create:create];
    BDSKErrorEditor *editor = [manager mainEditor];
    
    if(editor == nil && create){
        editor = [(BDSKErrorEditor *)[BDSKErrorEditor alloc] initWithFileName:[[document fileURL] path]];
        [manager addEditor:editor isMain:YES];
        [editor release];
    }
    
    return editor;
}

- (BDSKErrorEditor *)editorForPasteDragData:(NSData *)data document:(BibDocument *)document{
    OBASSERT(document != nil);
    
    BDSKErrorManager *manager = [self managerForDocument:document create:YES];
    
    BDSKErrorEditor *editor = [[BDSKErrorEditor alloc] initWithPasteDragData:data];
    [manager addEditor:editor isMain:NO];
    [editor release];
    
    return editor;
}

// double click in the error tableview
- (void)showEditorForErrorObject:(BDSKErrorObject *)errObj{
    NSString *fileName = [errObj fileName];
    BDSKErrorEditor *editor = [errObj editor];
    BibItem *pub = [errObj publication];

    // fileName is nil for paste/drag and author parsing errors; check for a pub first, since that's the best way to edit
    if (pub) {
        // if we have an error for a pub, it should be from a BibDocument. Otherwise we would have ignored it, see endObservingErrorsForDocument:...
        BibEditor *pubEditor = [(BibDocument *)[pub owner] editPub:pub];
        [pubEditor setKeyField:BDSKAuthorString];
    } else if (nil == fileName || [[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
        [editor showWindow:self];
        [editor gotoLine:[errObj lineNumber]];
    } else NSBeep();
}

// edit paste/drag error; sent via document error panel displayed when paste fails
- (void)showEditorForLastPasteDragError{
    if(lastIndex < [self countOfErrors]){
        BDSKErrorObject *errObj = [self objectInErrorsAtIndex:lastIndex];
        OBASSERT([[errObj editor] isPasteDrag]);
        [self showWindow:self];
        [self showEditorForErrorObject:errObj];
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(lastIndex, [self countOfErrors] - lastIndex)];
        [errorTableView selectRowIndexes:indexes byExtendingSelection:NO];
    }else NSBeep();
}

#pragma mark Managing managers, editors and errors

// failed load of a document
- (void)documentFailedLoad:(BibDocument *)document shouldEdit:(BOOL)shouldEdit{
    if(shouldEdit)
        [self showWindow:self];
	
    // remove any earlier failed load editors unless we're editing them
    unsigned index = [managers count];
    BDSKErrorManager *manager;
    
    while (index--) {
        manager = [managers objectAtIndex:index];
        if([manager sourceDocument] == document){
            [manager setSourceDocument:nil];
            if(shouldEdit)
                [[manager mainEditor] showWindow:self];
        }else if([manager sourceDocument] == nil && [manager isAllItems] == NO){
            [manager removeClosedEditors];
        }
    }
    
    // there shouldn't be any at this point, but just make sure
    [self removeErrorsForPublications:[document publications]];
}

// remove a document
- (void)handleRemoveDocumentNotification:(NSNotification *)notification{
    BibDocument *document = [notification object];
    // clear reference to document in its editors and close it when it is not editing
    unsigned index = [managers count];
    BDSKErrorManager *manager;
    
    while (index--) {
        manager = [managers objectAtIndex:index];
        if([[manager sourceDocument] isEqual:document]){
            [manager setSourceDocument:nil];
            [manager removeClosedEditors];
        }
    }
    
    [self removeErrorsForPublications:[document publications]];
}

// remove a publication
- (void)handleRemovePublicationNotification:(NSNotification *)notification{
    NSArray *pubs = [[notification userInfo] objectForKey:@"pubs"];
    [self removeErrorsForPublications:pubs];
}

- (void)removeErrorsForPublications:(NSArray *)pubs{
	unsigned index = [self countOfErrors];
    BibItem *pub;
    
    while (index--) {
		pub = [[self objectInErrorsAtIndex:index] publication];
        if(pub && [pubs containsObject:pub])
            [self removeObjectFromErrorsAtIndex:index];
    }
}

- (void)removeErrorsForEditor:(BDSKErrorEditor *)editor{
	unsigned index = [self countOfErrors];
    BDSKErrorObject *errObj;
    
    while (index--) {
		errObj = [self objectInErrorsAtIndex:index];
        if ([[errObj editor] isEqual:editor]) {
            [self removeObjectFromErrorsAtIndex:index];
    	}
    }
}

#pragma mark Actions

// copy error messages
- (IBAction)copy:(id)sender{
    if([[self window] isKeyWindow] && [errorTableView numberOfSelectedRows] > 0){
        NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
        NSMutableString *s = [[NSMutableString string] retain];
        NSEnumerator *objEnumerator = [[errorsController selectedObjects] objectEnumerator];
		int lineNumber;
        
        // Columns order:  @"File Name\t\tLine Number\t\tMessage Type\t\tMessage Text\n"];
		BDSKErrorObject *errObj;
		
        while(errObj = [objEnumerator nextObject]){
            [s appendString:[[errObj editor] displayName]];
            [s appendString:@"\t\t"];
            
			lineNumber = [errObj lineNumber];
			if(lineNumber == -1)
				[s appendString:NSLocalizedString(@"Unknown line number", @"Error message for error window")];
			else
				[s appendFormat:@"%i", lineNumber];
            [s appendString:@"\t\t"];
            
            [s appendString:[errObj errorClassName]];
            [s appendString:@"\t\t"];
            
            [s appendString:[errObj errorMessage]];
            [s appendString:@"\n\n"];
        }
        [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [pasteboard setString:s forType:NSStringPboardType];
    }
    
}

- (IBAction)gotoError:(id)sender{
    int clickedRow = [sender clickedRow];
    if(clickedRow != -1)
        [self showEditorForErrorObject:[[errorsController arrangedObjects] objectAtIndex:clickedRow]];
}

#pragma mark Error notification handling

- (void)startObservingErrors{
    if(currentErrors == nil){
        currentErrors = [[NSMutableArray alloc] initWithCapacity:10];
    } else {
        OBASSERT([currentErrors count] == 0);
        [currentErrors removeAllObjects];
    }
    lastIndex = [self countOfErrors];
}

- (void)endObservingErrorsForDocument:(BibDocument *)document pasteDragData:(NSData *)data publication:(BibItem *)pub{
    if([currentErrors count]){
        if(document != nil){ // this should happen only for temporary author objects, which we ignore as they don't belong to any document
            id editor = data ? [self editorForPasteDragData:data document:document] : [self editorForDocument:document create:YES];
            [currentErrors makeObjectsPerformSelector:@selector(setEditor:) withObject:editor];
            if(pub)
                [currentErrors makeObjectsPerformSelector:@selector(setPublication:) withObject:pub];
            [[self mutableArrayValueForKey:@"errors"] addObjectsFromArray:currentErrors];
            if([self isWindowVisible] == NO && (handledNonIgnorableError || [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShowWarningsKey]))
                [self showWindow:self];
            handledNonIgnorableError = NO;
        }
        [currentErrors removeAllObjects];
    }
}

- (void)endObservingErrorsForDocument:(BibDocument *)document pasteDragData:(NSData *)data{
    [self endObservingErrorsForDocument:document pasteDragData:data publication:nil];
}

- (void)endObservingErrorsForPublication:(BibItem *)pub{
    id document = [pub owner];
    // we can't and shouldn't manage errors from external groups
    if ([document isDocument] == NO)
        document = nil;
    [self endObservingErrorsForDocument:document pasteDragData:nil publication:pub];
}

- (void)handleErrorNotification:(NSNotification *)notification{
    BDSKErrorObject *obj = [notification object];
    [currentErrors addObject:obj];
    
    // set a flag so we know that the window should be displayed after endObserving:...
    if (NO == handledNonIgnorableError && [obj isIgnorableWarning] == NO)
        handledNonIgnorableError = YES;
    
}

#pragma mark TableView tooltips

- (NSString *)tableView:(NSTableView *)aTableView toolTipForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
	return [[[errorsController arrangedObjects] objectAtIndex:rowIndex] errorMessage];
}

@end

#pragma mark -
#pragma mark Array controller for error objects

@implementation BDSKFilteringArrayController

- (NSArray *)arrangeObjects:(NSArray *)objects {
    if(hideWarnings || filterManager){
        NSMutableArray *matchedObjects = [NSMutableArray arrayWithCapacity:[objects count]];
        
        NSEnumerator *itemEnum = [objects objectEnumerator];
        id item;	
        while (item = [itemEnum nextObject]) {
            if(filterManager && [filterManager managesError:item] == NO)
                continue;
            if(hideWarnings && [item isIgnorableWarning])
                continue;
            [matchedObjects addObject:item];
        }
        
        objects = matchedObjects;
    }
    return [super arrangeObjects:objects];
}

- (void)dealloc {
    [self setFilterManager: nil];    
    [super dealloc];
}

- (BDSKErrorManager *)filterManager {
	return filterManager;
}

- (void)setFilterManager:(BDSKErrorManager *)manager {
    if (filterManager != manager) {
        [filterManager release];
        filterManager = [manager retain];
		[self rearrangeObjects];
    }
}

- (BOOL)hideWarnings {
    return hideWarnings;
}

- (void)setHideWarnings:(BOOL)flag {
    if(hideWarnings != flag) {
        hideWarnings = flag;
		[self rearrangeObjects];
    }
}

@end

#pragma mark -
#pragma mark Line number transformer

@implementation BDSKLineNumberTransformer

+ (Class)transformedValueClass {
    return [NSObject class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)number {
	return ([number intValue] == -1) ? @"?" : number;
}

@end
