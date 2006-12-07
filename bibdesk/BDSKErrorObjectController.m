//
//  BDSKErrorObjectController.m
//  Bibdesk
//
//  Created by Adam Maxwell on 08/12/05.
/*
 This software is Copyright (c) 2005
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
    [super dealloc];
}

- (void)awakeFromNib;
{
    [errorTableView setDoubleAction:@selector(gotoError:)];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleEditWindowWillCloseNotification:)
                                                 name:NSWindowWillCloseNotification
                                               object:sourceEditWindow];
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

- (void)setDocumentForErrors:(id)document{
	if (document != currentDocumentForErrors) {
		[currentDocumentForErrors release];
		currentDocumentForErrors = [document retain];
	}
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
        NSIndexSet *selIndexes = [errorTableView selectedRowIndexes];
        int i = [selIndexes firstIndex];
        NSString *fileName;
		int lineNumber;
        [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        //[s appendString:@"File Name\t\tLine Number\t\tMessage Type\t\tMessage Text\n"];
		BDSKErrObj *errObj;
		
        while(i != NSNotFound){
			errObj = [self objectInErrorsAtIndex:i];
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
			i = [selIndexes indexGreaterThanIndex:i];
        }
        [pasteboard setString:s forType:NSStringPboardType];
    }
    
}

- (IBAction)gotoError:(id)sender{
    id errObj = nil;
    int selectedRow = [sender selectedRow];
    if(selectedRow != -1){
        errObj = [self objectInErrorsAtIndex:selectedRow];
        [self gotoErrorObj:errObj];
    }
}

- (void)gotoErrorObj:(id)errObj{
    NSString *fileName = [errObj fileName];
    int lineNumber = [errObj lineNumber];
    NSFileManager *dfm = [NSFileManager defaultManager];
    
    [self openEditWindowWithFile:fileName];
    
    if ([dfm fileExistsAtPath:fileName]) {
        [sourceEditTextView selectLineNumber:lineNumber];
    }
}

#pragma mark Notifications and Update

- (void)handleErrorNotification:(NSNotification *)notification{
    BDSKErrObj *errDict = [notification object];
    NSString *errorClass = [errDict errorClassName];
    
    if (errorClass) {
		[errDict setDocument:currentDocumentForErrors];
		[self insertObject:errDict inErrorsAtIndex:[self countOfErrors]];
        [self performSelectorOnMainThread:@selector(updateErrorPanelUI) withObject:nil waitUntilDone:NO];
    }
}

// here we have to identify errors by file name, as we've no idea what document the edit window is associated with
- (void)handleEditWindowWillCloseNotification:(NSNotification *)notification{
    [self removeErrorObjsForFileName:[[self currentFileName] stringByExpandingTildeInPath]];
    [self removeErrorObjsForDocument:currentDocumentForErrors];
}

- (void)updateErrorPanelUI{
	[errorTableView reloadData];
	if ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShowWarningsKey]) {
        [self showErrorPanel:self];
	}
}

#pragma mark Error objects management

- (void)removeErrorObjsForDocument:(id)document{
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

- (void)openEditWindowWithFile:(NSString *)fileName{
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
    }
}

- (void)openEditWindowWithFile:(NSString *)fileName forDocument:(id)document;
{
    [self openEditWindowWithFile:fileName];
    [self transferErrorsTo:fileName fromDocument:document];
}
    
// we identify errors either by document or file name
- (void)openEditWindowForDocument:(id)document{
	[self removeErrorObjsForDocument:nil]; // this removes errors from a previous failed load
	[self handoverErrorObjsForDocument:document]; // this dereferences the doc from the errors, so they won't be removed when the document is deallocated
	
	[self openEditWindowWithFile:[document fileName]];
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
