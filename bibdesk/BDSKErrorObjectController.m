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
#import <BTParse/error.h>
#import "BibPrefController.h"
#import "NSTextView_BDSKExtensions.h"
#import "NSString_BDSKExtensions.h"
#import "BibDocument.h"

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

// copy error messages
- (IBAction)copy:(id)sender{
    if([errorPanel isKeyWindow] && [errorTableView numberOfSelectedRows] > 0){
        NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
        NSEnumerator *e = [errorTableView selectedRowEnumerator];
        NSMutableString *s = [[NSMutableString string] retain];
        NSNumber *i;
        NSString *fileName;
        [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        //[s appendString:@"File Name\t\tLine Number\t\tMessage Type\t\tMessage Text\n"];
        int row;
        while(i = [e nextObject]){
            row = [i intValue];
            fileName = [[[[errors objectAtIndex:row] valueForKey:@"document"] fileName] lastPathComponent];
            if(!fileName)
                fileName = [[[errors objectAtIndex:row] valueForKey:@"fileName"] lastPathComponent];
            else
                fileName = @"";
            [s appendString:fileName];
            [s appendString:@"\t\t"];
            
            [s appendString:([[[errors objectAtIndex:row] valueForKey:@"lineNumber"] intValue] == -1 ? NSLocalizedString(@"Unknown line number",@"unknown line number for error") : [[[errors objectAtIndex:row] valueForKey:@"lineNumber"] stringValue])];
            [s appendString:@"\t\t"];
            
            [s appendString:[[errors objectAtIndex:row] valueForKey:@"errorClassName"]];
            [s appendString:@"\t\t"];
            
            [s appendString:[[errors objectAtIndex:row] valueForKey:@"errorMessage"]];
            [s appendString:@"\n\n"];
        }
        [pasteboard setString:s forType:NSStringPboardType];
    }
    
}

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

- (void)handleErrorNotification:(NSNotification *)notification{
    BDSKErrObj *errDict = [notification object];
    NSString *errorClass = [errDict valueForKey:@"errorClassName"];
    
    if (errorClass) {
		[errDict takeValue:currentDocumentForErrors forKey:@"document"];
		[errors addObject:errDict];
        [self performSelectorOnMainThread:@selector(updateErrorPanelUI) withObject:nil waitUntilDone:NO];
    }
}

- (void)updateErrorPanelUI{
	[errorTableView reloadData];
	if ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShowWarningsKey]) {
        [self showErrorPanel:self];
	}
}

- (void)setDocumentForErrors:(id)document{
	if (document != currentDocumentForErrors) {
		[currentDocumentForErrors release];
		currentDocumentForErrors = [document retain];
	}
}

- (void)removeErrorObjsForDocument:(id)document{
    NSMutableArray *errorsToRemove = [NSMutableArray arrayWithCapacity:10];
    NSEnumerator *enumerator = [errors objectEnumerator];
    id errObj;
    
    while (errObj = [enumerator nextObject]) {
        if ([errObj valueForKey:@"document"] == document) {
            [errorsToRemove addObject:errObj];
    	}
    }
    [errors removeObjectsInArray:errorsToRemove];
    [errorTableView reloadData];
	
	if (currentDocumentForErrors == document)
		[self setDocumentForErrors:nil];
}

- (void)removeErrorObjsForFileName:(NSString *)fileName{
    NSMutableArray *errorsToRemove = [NSMutableArray arrayWithCapacity:10];
    NSEnumerator *enumerator = [errors objectEnumerator];
    id errObj;
    
    while (errObj = [enumerator nextObject]) {
        if ([[errObj valueForKey:@"fileName"] isEqualToString:fileName]) {
            [errorsToRemove addObject:errObj];
    	}
    }
    [errors removeObjectsInArray:errorsToRemove];
    [errorTableView reloadData];
	[self setCurrentFileName:nil];
}

- (void)handoverErrorObjsForDocument:(id)document{
    NSEnumerator *enumerator = [errors objectEnumerator];
    id errObj;
    
    while (errObj = [enumerator nextObject]) {
        if ([errObj valueForKey:@"document"] == document) {
            [errObj takeValue:nil forKey:@"document"];
    	}
    }
    [errorTableView reloadData];
}

- (void)transferErrorsTo:(NSString *)fileName fromDocument:(id)document;
{
    NSEnumerator *enumerator = [errors objectEnumerator];
    id errObj;
    
    while (errObj = [enumerator nextObject]) {
        if ([errObj valueForKey:@"document"] == document) {
            [errObj takeValue:nil forKey:@"document"];
            [errObj takeValue:fileName forKey:@"fileName"];
    	}
    }
    [errorTableView reloadData];
}

- (IBAction)gotoError:(id)sender{
    id errObj = nil;
    int selectedRow = [sender selectedRow];
    if(selectedRow != -1){
        errObj = [errors objectAtIndex:selectedRow];
        [self gotoErrorObj:errObj];
    }
}

- (void)gotoErrorObj:(id)errObj{
    NSString *fileName = [errObj valueForKey:@"fileName"];
    NSNumber *lineNumber = [errObj valueForKey:@"lineNumber"];
    NSFileManager *dfm = [NSFileManager defaultManager];
    
    [self openEditWindowWithFile:fileName];
    
    if ([dfm fileExistsAtPath:fileName]) {
        [sourceEditTextView selectLineNumber:[lineNumber intValue]];
    }
}

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

// here we have to identify errors by file name, as we've no idea what document the edit window is associated with
- (void)handleEditWindowWillCloseNotification:(NSNotification *)notification{
    [self removeErrorObjsForFileName:[[self currentFileName] stringByExpandingTildeInPath]];
    [self removeErrorObjsForDocument:currentDocumentForErrors];
    [errorTableView reloadData];
}

#pragma mark || tableView datasource methods

- (int)numberOfRowsInTableView:(NSTableView *)tableView{
    return [errors count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    if ([[tableColumn identifier] isEqualToString:@"lineNumber"]) {
        return [NSString stringWithFormat:@"%@", ([[[errors objectAtIndex:row] valueForKey:@"lineNumber"] intValue] == -1 ? NSLocalizedString(@"Unknown",@"unknown line number for error") : [[errors objectAtIndex:row] valueForKey:@"lineNumber"])];
    }
    if ([[tableColumn identifier] isEqualToString:@"errorClass"]) {
        return [NSString stringWithFormat:@"%@", [[errors objectAtIndex:row] valueForKey:@"errorClassName"]];
    }
    if ([[tableColumn identifier] isEqualToString:@"fileName"]) {
        if([[NSFileManager defaultManager] fileExistsAtPath:[[errors objectAtIndex:row] valueForKey:@"fileName"]]){
            return [[NSString stringWithFormat:@"%@", [[errors objectAtIndex:row] valueForKey:@"fileName"]] lastPathComponent];
        }else{
            return [[[[errors objectAtIndex:row] valueForKey:@"document"] fileName] lastPathComponent];
        }
    }
    if ([[tableColumn identifier] isEqualToString:@"errorMessage"]) {
        return [NSString stringWithFormat:@"%@", [[errors objectAtIndex:row] valueForKey:@"errorMessage"]];
    }else{
        return @"";
    }
}

@end
