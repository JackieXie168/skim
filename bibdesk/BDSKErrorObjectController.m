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
#import "BibPrefController.h"
#import "NSTextView_BDSKExtensions.h"
#import "NSString_BDSKExtensions.h"
#import "BibDocument.h"
#import "NSFileManager_BDSKExtensions.h"
#import "CFString_BDSKExtensions.h"

static BDSKErrorObjectController *sharedErrorObjectController = nil;

@implementation BDSKErrorObjectController

+ (BDSKErrorObjectController *)sharedErrorObjectController;
{
    if(!sharedErrorObjectController)
        sharedErrorObjectController = [[BDSKErrorObjectController alloc] init];
    return sharedErrorObjectController;
}

- (id)init;
{
    if(sharedErrorObjectController){
        [self release];
        return sharedErrorObjectController;
    }
    
    [NSBundle loadNibNamed:[self windowNibName] owner:self];
    if(self = [super initWithWindowNibName:[self windowNibName]]){
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleErrorNotification:)
                                                     name:BDSKParserErrorNotification
                                                   object:nil];
        errors = [[NSMutableArray alloc] initWithCapacity:10];
        documents = [[NSMutableArray alloc] initWithCapacity:4];
		[self insertObject:[BDSKPlaceHolderFilterItem allItemsPlaceHolderFilterItem] inDocumentsAtIndex:0];
		[self insertObject:[BDSKPlaceHolderFilterItem emptyItemsPlaceHolderFilterItem] inDocumentsAtIndex:1];
		[errorsController setFilterValue:[self objectInDocumentsAtIndex:0]];
        
		enableSyntaxHighlighting = YES;
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
    [documents release];
    [super dealloc];
}

- (void)awakeFromNib;
{
    [errorTableView setDoubleAction:@selector(gotoError:)];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleEditWindowWillCloseNotification:)
                                                 name:NSWindowWillCloseNotification
                                               object:sourceEditWindow];

    [errorsController setFilterKey:@"document"];
	
	[[sourceEditTextView textStorage] setDelegate:self];
    [syntaxHighlightCheckbox setState:NSOnState];
}

#pragma mark Accessors

- (NSArray *)errors {
    return [[errors retain] autorelease];
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

- (void)replaceObjectInErrorsAtIndex:(unsigned)index withObject:(id)newObject{
    [errors replaceObjectAtIndex:index withObject:newObject];
}

- (NSArray *)documents {
    return [[documents retain] autorelease];
}

- (unsigned)countOfDocuments {
    return [documents count];
}

- (id)objectInDocumentsAtIndex:(unsigned)theIndex {
    return [documents objectAtIndex:theIndex];
}

- (void)insertObject:(id)obj inDocumentsAtIndex:(unsigned)theIndex {
    [documents insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromDocumentsAtIndex:(unsigned)theIndex {
    [documents removeObjectAtIndex:theIndex];
}

- (void)replaceObjectInDocumentsAtIndex:(unsigned)theIndex withObject:(id)obj {
    [documents replaceObjectAtIndex:theIndex withObject:obj];
}

- (void)setCurrentFileName:(NSString *)newPath;
{
    if(currentFileName != newPath){
        [currentFileName release];
        currentFileName = [newPath copy];
    }
}

- (NSString *)currentFileName;
{
    return currentFileName;
}

- (void)setCurrentDocument:(id)document;
{
    if(currentDocument != document){
        [currentDocument release];
        currentDocument = [document retain];
    }
}

- (id)currentDocument;
{
    return currentDocument;
}

- (void)setDocumentForErrors:(id)document{
	if (document != currentDocumentForErrors) {
		[currentDocumentForErrors release];
		currentDocumentForErrors = [document retain];
		if (document != nil && [documents containsObject:document] == NO)
			[self insertObject:document inDocumentsAtIndex:[self countOfDocuments]];
	}
}

- (id)documentForErrors{
	return currentDocumentForErrors;
}

#pragma mark Actions

- (IBAction)toggleShowingErrorPanel:(id)sender{
    if (![errorPanel isVisible]) {
        [self showErrorPanel:sender];
    }else{
        [self hideErrorPanel:sender];
    }
}

- (IBAction)hideErrorPanel:(id)sender{
    [errorPanel orderOut:sender];
}

- (IBAction)showErrorPanel:(id)sender{
    [errorPanel makeKeyAndOrderFront:sender];
}

// copy error messages
- (IBAction)copy:(id)sender{
    if([errorPanel isKeyWindow] && [errorTableView numberOfSelectedRows] > 0){
        NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
        NSMutableString *s = [[NSMutableString string] retain];
        NSEnumerator *objEnumerator = [[errorsController selectedObjects] objectEnumerator];
        NSString *fileName;
		int lineNumber;
        
        // Columns order:  @"File Name\t\tLine Number\t\tMessage Type\t\tMessage Text\n"];
		BDSKErrObj *errObj;
		
        while(errObj = [objEnumerator nextObject]){
            fileName = [errObj displayFileName];
            [s appendString:fileName ? fileName : @""];
            [s appendString:@"\t\t"];
            
			lineNumber = [errObj lineNumber];
			if(lineNumber == -1)
				[s appendString:NSLocalizedString(@"Unknown line number",@"unknown line number for error")];
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
        [self gotoErrorObj:[[errorsController arrangedObjects] objectAtIndex:clickedRow]];
}

- (void)gotoErrorObj:(id)errObj{
    NSString *fileName = [errObj fileName];    
    [self openEditWindowWithFile:fileName forDocument:[errObj document]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileName])
        [sourceEditTextView selectLineNumber:[errObj lineNumber]];
}

- (IBAction)changeSyntaxHighlighting:(id)sender{
    NSTextStorage *textStorage = [sourceEditTextView textStorage];
    if([sender state] == NSOffState){
        enableSyntaxHighlighting = NO;
        [textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, [textStorage length])];
    } else 
        enableSyntaxHighlighting = YES;
    [textStorage edited:NSTextStorageEditedAttributes range:NSMakeRange(0, [textStorage length]) changeInLength:0];
}

#pragma mark Notifications and Update

- (void)handleErrorNotification:(NSNotification *)notification{
    BDSKErrObj *errDict = [notification object];
    NSString *errorClass = [errDict errorClassName];
    
    // don't show lexical buffer overflow warnings
    if ([errorClass isEqualToString:BDSKParserHarmlessWarningString] == NO) {
		[errDict setDocument:currentDocumentForErrors];
		[self insertObject:errDict inErrorsAtIndex:[self countOfErrors]];
        if([errorPanel isVisible] == NO && [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShowWarningsKey])
            [self showErrorPanel:self];
    }

}

// here we have to identify errors by file name, as we've no idea what document the edit window is associated with
- (void)handleEditWindowWillCloseNotification:(NSNotification *)notification{
	if ([self currentDocument] == nil)
		[self removeErrorObjsForFileName:[[self currentFileName] stringByExpandingTildeInPath]];
	else
		[self setCurrentDocument:nil];
}

static inline Boolean isLeftBrace(UniChar ch) { return ch == '{'; }
static inline Boolean isRightBrace(UniChar ch) { return ch == '}'; }
static inline Boolean isAt(UniChar ch) { return ch == '@'; }

// extend the edited range of the textview to include the previous and next newline; including the previous/next delimiter is less reliable
static inline NSRange invalidatedRange(NSString *string, NSRange proposedRange){
    
    static NSCharacterSet *delimSet = nil;
    if(delimSet == nil)
        delimSet = [[NSCharacterSet characterSetWithCharactersInString:@"@{}"] retain];
    
    static NSMutableCharacterSet *newlineSet = nil;
    if(newlineSet == nil){
        newlineSet = (NSMutableCharacterSet *)CFCharacterSetCreateMutableCopy(CFAllocatorGetDefault(), CFCharacterSetGetPredefined(kCFCharacterSetWhitespace));
        CFCharacterSetInvert((CFMutableCharacterSetRef)newlineSet); // no whitespace in this one, but it also has all letters...
        CFCharacterSetIntersect((CFMutableCharacterSetRef)newlineSet, CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline));
    }
    
    if([string containsCharacterInSet:delimSet] == NO)
        return proposedRange;
    
    NSRange startRange;
    startRange = [string rangeOfCharacterFromSet:newlineSet options:NSBackwardsSearch|NSLiteralSearch range:NSMakeRange(0, proposedRange.location)];
    if(startRange.location == NSNotFound)
        startRange = NSMakeRange(proposedRange.location, 0);
    
    NSRange endRange;
    endRange = [string rangeOfCharacterFromSet:newlineSet options:NSLiteralSearch range:NSMakeRange(NSMaxRange(proposedRange), [string length] - NSMaxRange(proposedRange))];
    if(endRange.location == NSNotFound)
        endRange = proposedRange;
    
    return NSMakeRange(startRange.location, NSMaxRange(endRange) - startRange.location);
}
    

- (void)textStorageDidProcessEditing:(NSNotification *)notification{
    
    if(enableSyntaxHighlighting == NO)
        return;
    
    NSTextStorage *textStorage = [notification object];    
    CFStringRef string = (CFStringRef)[textStorage string];
    CFIndex length = CFStringGetLength(string);

    NSRange editedRange = [textStorage editedRange];
    
    // see what range we should actually invalidate; if we're not adding any special characters, the default edited range is probably fine
    editedRange = invalidatedRange((NSString *)string, editedRange);
    
    CFIndex cnt = editedRange.location;
    
    CFStringInlineBuffer inlineBuffer;
    CFStringInitInlineBuffer(string, &inlineBuffer, CFRangeMake(cnt, editedRange.length));
    
    [textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:editedRange];
    
    // inline buffer only covers the edited range, starting from 0; adjust length to length of buffer
    length = editedRange.length;
    UniChar ch;
    CFIndex lbmark, atmark;
    
    NSColor *braceColor = [NSColor blueColor];
    NSColor *typeColor = [NSColor purpleColor];
    NSColor *quotedColor = [NSColor brownColor];
    
    CFIndex braceDepth = 0;
     
    // This is fairly crude; I don't think it's worthwhile to implement a full BibTeX parser here, since we need this to be fast (and it won't be used that often).
    // remember that cnt and length determine the index and length of the inline buffer, not the textStorage
    for(cnt = 0; cnt < length; cnt++){
        ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
        if(isAt(ch) && (cnt == 0 || BDIsNewlineCharacter(CFStringGetCharacterAtIndex(string, cnt - 1)))){
            atmark = cnt;
            for(cnt = cnt; cnt < length; cnt++){
                ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
                if(isLeftBrace(ch)){
                    [textStorage addAttribute:NSForegroundColorAttributeName value:braceColor range:NSMakeRange(editedRange.location + cnt, 1)];
                    break;
                }
            }
            [textStorage addAttribute:NSForegroundColorAttributeName value:typeColor range:NSMakeRange(editedRange.location + atmark, cnt - atmark)];
            // sneaky hack: don't rewind here, since cite keys don't have a closing brace (of course)
        }else if(isLeftBrace(ch)){
            braceDepth++;
            [textStorage addAttribute:NSForegroundColorAttributeName value:braceColor range:NSMakeRange(editedRange.location + cnt, 1)];
            lbmark = cnt + 1;
            for(cnt = lbmark; (cnt < length && braceDepth != 0); cnt++){
                ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
                if(isRightBrace(ch)){
                    braceDepth--;
                    [textStorage addAttribute:NSForegroundColorAttributeName value:braceColor range:NSMakeRange(editedRange.location + cnt, 1)];
                } else if(isLeftBrace(ch)){
                    braceDepth++;
                    [textStorage addAttribute:NSForegroundColorAttributeName value:braceColor range:NSMakeRange(editedRange.location + cnt, 1)];
                } else
                    [textStorage addAttribute:NSForegroundColorAttributeName value:quotedColor range:NSMakeRange(editedRange.location + cnt, 1)];
            }
        }
    }

}

#pragma mark Error objects management

- (void)removeErrorObjsForDocument:(id)document{
	
	if ([self currentDocument] == document) {
		[self handoverErrorObjsForDocument:document];
		[self setCurrentDocument:nil];
		return;
	}
	
	unsigned index = [self countOfErrors];
    id errObj;
    
    while (index--) {
		errObj = [self objectInErrorsAtIndex:index];
        if ([errObj document] == document) {
            [self removeObjectFromErrorsAtIndex:index];
    	}
    }
	if (currentDocumentForErrors == document)
		[self setDocumentForErrors:nil];
	if ([documents containsObject:document])
		[self removeObjectFromDocumentsAtIndex:[documents indexOfObject:document]];
}

- (void)removeErrorObjsForFileName:(NSString *)fileName{
	unsigned index = [self countOfErrors];
    id errObj;
    
    while (index--) {
		errObj = [self objectInErrorsAtIndex:index];
        if ([[errObj fileName] isEqualToString:fileName]) {
            [self removeObjectFromErrorsAtIndex:index];
    	}
    }
	[self setCurrentFileName:nil];
}

- (void)handoverErrorObjsForDocument:(id)document{
	unsigned index = [self countOfErrors];
    id errObj;
    
    while (index--) {
		errObj = [self objectInErrorsAtIndex:index];
        if ([errObj document] == document) {
            [errObj setDocument:nil];
    	}
    }
    // this is required, or else we retain the document and can have problems (potential crash due to endless loop from notifications); if it never had a window, it won't be cleaned up.  maybe better just to clear them immediately?
    if(document == currentDocumentForErrors)
        [self setDocumentForErrors:nil];
}

- (void)transferErrorsTo:(NSString *)fileName fromDocument:(id)document{
	unsigned index = [self countOfErrors];
    id errObj;
    
    while (index--) {
		errObj = [self objectInErrorsAtIndex:index];
        if ([errObj document] == document) {
            [errObj setDocument:nil];
            [errObj setFileName:fileName];
    	}
    }
}

#pragma mark Edit window

- (id <OAFindControllerTarget>)omniFindControllerTarget { return sourceEditTextView; }

- (void)openEditWindowWithFile:(NSString *)fileName;
{
	[self openEditWindowWithFile:fileName forDocument:nil];
}

- (void)openEditWindowWithFile:(NSString *)fileName forDocument:(id)document;
{
    NSFileManager *dfm = [NSFileManager defaultManager];
    if (!fileName) return;
    
    // let's see if the document has an encoding (hopefully the user guessed correctly); if not, fall back to the default C string encoding
    NSStringEncoding encoding = (currentDocumentForErrors != nil ? [(BibDocument *)currentDocumentForErrors documentStringEncoding] : [NSString defaultCStringEncoding]);
        
    if ([dfm fileExistsAtPath:fileName]) {
        if(![currentFileName isEqualToString:fileName]){
            NSData *fileData = [[NSData alloc] initWithContentsOfFile:fileName];
            NSString *fileStr = [[NSString alloc] initWithData:fileData encoding:encoding];
            if(!fileStr)
                fileStr = [[NSString alloc] initWithData:fileData encoding:NSISOLatin1StringEncoding]; // usually a good guess
            [fileData release];
            if(!fileStr)
                fileStr = [[NSString alloc] initWithString:NSLocalizedString(@"Unable to determine the correct character encoding.", @"")];
            [sourceEditTextView setString:fileStr];
            [fileStr release];
            [sourceEditWindow setTitle:[fileName lastPathComponent]];
        }
        [sourceEditWindow makeKeyAndOrderFront:self];
        [self setCurrentFileName:fileName];
		[self setCurrentDocument:document];
    }
}
    
// we identify errors either by document or file name
- (void)openEditWindowForDocument:(id)document{
	[self removeErrorObjsForDocument:nil]; // this removes errors from a previous failed load
	[self handoverErrorObjsForDocument:document]; // this dereferences the doc from the errors, so they won't be removed when the document is deallocated
	
	[self openEditWindowWithFile:[document fileName] forDocument:nil];
}

- (IBAction)reopenDocument:(id)sender{
    NSString *expandedCurrentFileName = [[self currentFileName] stringByExpandingTildeInPath];
    
    [self removeErrorObjsForFileName:expandedCurrentFileName];
    
    expandedCurrentFileName = [[NSFileManager defaultManager] uniqueFilePath:expandedCurrentFileName
															 createDirectory:NO];
    
    // write this out with the user's default encoding, so the openDocumentWithContentsOfFile is more likely to succeed
    NSData *fileData = [[sourceEditTextView string] dataUsingEncoding:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKDefaultStringEncodingKey] allowLossyConversion:NO];
    [fileData writeToFile:expandedCurrentFileName atomically:YES];
    
    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:expandedCurrentFileName
                                                                            display:YES];
    
}

#pragma mark TableView tooltips

- (NSString *)tableView:(NSTableView *)aTableView toolTipForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
	return [[[errorsController arrangedObjects] objectAtIndex:rowIndex] errorMessage];
}

@end


@implementation BDSKErrObj (Accessors)

- (NSString *)fileName {
    return [[fileName retain] autorelease];
}

- (void)setFileName:(NSString *)newFileName {
    if (fileName != newFileName) {
        [fileName release];
        fileName = [newFileName copy];
    }
}

- (NSDocument *)document {
    return [[document retain] autorelease];
}

- (void)setDocument:(NSDocument *)newDocument {
    if (document != newDocument) {
        [document release];
        document = [newDocument retain];
    }
}

- (NSString *)displayFileName {
	NSString *docFileName = [document fileName];
    if (docFileName == nil)
		docFileName = fileName;
	return [docFileName lastPathComponent];
}

- (int)lineNumber {
    return lineNumber;
}

- (void)setLineNumber:(int)newLineNumber {
    if (lineNumber != newLineNumber) {
        lineNumber = newLineNumber;
    }
}

- (NSString *)itemDescription {
    return [[itemDescription retain] autorelease];
}

- (void)setItemDescription:(NSString *)newItemDescription {
    if (itemDescription != newItemDescription) {
        [itemDescription release];
        itemDescription = [newItemDescription copy];
    }
}

- (int)itemNumber {
    return itemNumber;
}

- (void)setItemNumber:(int)newItemNumber {
    if (itemNumber != newItemNumber) {
        itemNumber = newItemNumber;
    }
}

- (NSString *)errorClassName {
    return [[errorClassName retain] autorelease];
}

- (void)setErrorClassName:(NSString *)newErrorClassName {
    if (errorClassName != newErrorClassName) {
        [errorClassName release];
        errorClassName = [newErrorClassName copy];
    }
}

- (NSString *)errorMessage {
    return [[errorMessage retain] autorelease];
}

- (void)setErrorMessage:(NSString *)newErrorMessage {
    if (errorMessage != newErrorMessage) {
        [errorMessage release];
        errorMessage = [newErrorMessage copy];
    }
}

@end

@implementation BDSKPlaceHolderFilterItem

static BDSKPlaceHolderFilterItem *allItemsPlaceHolderFilterItem = nil;
static BDSKPlaceHolderFilterItem *emptyItemsPlaceHolderFilterItem = nil;

+ (void)initialize {
	allItemsPlaceHolderFilterItem = [[BDSKPlaceHolderFilterItem alloc] initWithDisplayName:NSLocalizedString(@"All", @"All")];
	emptyItemsPlaceHolderFilterItem = [[BDSKPlaceHolderFilterItem alloc] initWithDisplayName:NSLocalizedString(@"Empty", @"Empty")];
}

+ (BDSKPlaceHolderFilterItem *)allItemsPlaceHolderFilterItem { return allItemsPlaceHolderFilterItem; };
+ (BDSKPlaceHolderFilterItem *)emptyItemsPlaceHolderFilterItem { return emptyItemsPlaceHolderFilterItem; };

- (id)valueForUndefinedKey:(NSString *)keyPath {
	return displayName;
}

- (id)initWithDisplayName:(NSString *)name {
	if (self = [super init]) {
		displayName = [name copy];
	}
	return self;
}

@end

@implementation BDSKFilteringArrayController

- (NSArray *)arrangeObjects:(NSArray *)objects {
	
    if (filterValue == nil || filterValue == [BDSKPlaceHolderFilterItem allItemsPlaceHolderFilterItem] || [NSString isEmptyString:filterKey]) 
		return [super arrangeObjects:objects];   

    NSMutableArray *matchedObjects = [NSMutableArray arrayWithCapacity:[objects count]];
    
	NSEnumerator *itemEnum = [objects objectEnumerator];
    id item;	
    while (item = [itemEnum nextObject]) {
		id value = [item valueForKeyPath:filterKey];
		if ((filterValue == [BDSKPlaceHolderFilterItem emptyItemsPlaceHolderFilterItem] && value == nil) || [value isEqual:filterValue]) 
			[matchedObjects addObject:item];
    }
    return [super arrangeObjects:matchedObjects];
}

- (void)dealloc {
    [self setFilterValue: nil];    
    [self setFilterKey: nil];    
    [super dealloc];
}

- (id)filterValue {
	return filterValue;
}

- (void)setFilterValue:(id)newValue {
    if (filterValue != newValue) {
        [filterValue autorelease];
        filterValue = [newValue retain];
		[self rearrangeObjects];
    }
}

- (NSString *)filterKey {
    return [[filterKey retain] autorelease];
}

- (void)setFilterKey:(NSString *)newKey {
    if (filterKey != newKey) {
        [filterKey release];
        filterKey = [newKey copy];
		[self rearrangeObjects];
    }
}

@end
