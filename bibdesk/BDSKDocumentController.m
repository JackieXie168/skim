//  BDSKDocumentController.m

//  Created by Christiaan Hofman on 5/31/06.
/*
 This software is Copyright (c) 2006,2007
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

#import "BDSKDocumentController.h"
#import "BibPrefController.h"
#import <OmniBase/OmniBase.h>
#import <AGRegex/AGRegex.h>
#import "BDSKStringEncodingManager.h"
#import "BibAppController.h"
#import "BibDocument.h"
#import "BibDocument_Groups.h"
#import "BibDocument_Search.h"
#import "BDSKShellTask.h"
#import "NSArray_BDSKExtensions.h"
#import "BDAlias.h"
#import "NSWorkspace_BDSKExtensions.h"
#import "BDSKAlert.h"
#import "BibItem.h"
#import "BDSKTemplate.h"
#import "NSString_BDSKExtensions.h"
#import "NSError_BDSKExtensions.h"
#import "BDSKSearchGroup.h"
#import "BDSKGroupsArray.h"

@implementation BDSKDocumentController

- (id)init
{
    if(self = [super init]){
		if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShouldAutosaveDocumentKey])
		    [self setAutosavingDelay:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKAutosaveTimeIntervalKey]];
        
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleWindowDidBecomeMainNotification:)
                                                     name:NSWindowDidBecomeMainNotification
                                                   object:nil];
    }
    return self;
}

- (void)awakeFromNib{
    [openUsingFilterAccessoryView retain];
}

- (id)mainDocument{
    return mainDocument;
}

- (void)handleWindowDidBecomeMainNotification:(NSNotification *)notification{
    id currentDocument = [self currentDocument];
    if(currentDocument && [currentDocument isEqual:mainDocument] == NO){
        mainDocument = currentDocument;
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocumentControllerDidChangeMainDocumentNotification object:self];
    }
}

- (void)addDocument:(id)aDocument{
    [super addDocument:aDocument];
    if(mainDocument == nil){
        mainDocument = [[NSApp orderedDocuments] firstObject];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocumentControllerDidChangeMainDocumentNotification object:aDocument];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocumentControllerAddDocumentNotification object:aDocument];
}

- (void)removeDocument:(id)aDocument{
    [aDocument retain];
    [super removeDocument:aDocument];
    if([mainDocument isEqual:aDocument]){
        mainDocument = [[NSApp orderedDocuments] firstObject];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocumentControllerDidChangeMainDocumentNotification object:aDocument];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKDocumentControllerRemoveDocumentNotification object:aDocument];
    [aDocument release];
}

- (void)noteNewRecentDocument:(NSDocument *)aDocument{
    
    // may need to revisit this for new document classes
    OBASSERT([aDocument isKindOfClass:[BibDocument class]]);
    
    if ([aDocument respondsToSelector:@selector(documentStringEncoding)]) {
        NSStringEncoding encoding = [(BibDocument *)aDocument documentStringEncoding];
        
        // only add it to the list of recent documents if it can be opened without manually selecting an encoding
        if(encoding == NSASCIIStringEncoding || encoding == [BDSKStringEncodingManager defaultEncoding])
            [super noteNewRecentDocument:aDocument]; 

    } else {
        [super noteNewRecentDocument:aDocument];
    }
}

- (NSArray *)allReadableTypesForOpenPanel {
    NSMutableArray *types = [NSMutableArray array];
    NSEnumerator *classNamesEnumerator = [[self documentClassNames] objectEnumerator];
    NSString *className;
    while (className = [classNamesEnumerator nextObject])
        [types addObjectsFromArray:[NSClassFromString(className) readableTypes]];
    
    NSMutableArray *openPanelTypes = [NSMutableArray array];
    NSEnumerator *typeE = [types objectEnumerator];
    NSString *type;
    while (type = [typeE nextObject])
        [openPanelTypes addObjectsFromArray:[self fileExtensionsFromType:type]];
    
    return [openPanelTypes count] ? openPanelTypes : types;
}

- (NSArray *)URLsFromRunningOpenPanelForTypes:(NSArray *)types encoding:(NSStringEncoding *)encoding{
    
    NSParameterAssert(encoding);
    
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:YES];
    [oPanel setAccessoryView:openTextEncodingAccessoryView];
    [openTextEncodingPopupButton setEncoding:[BDSKStringEncodingManager defaultEncoding]];
    [oPanel setDirectory:[self currentDirectory]];
		
    int result = [self runModalOpenPanel:oPanel forTypes:types];
    if(result == NSOKButton){
        *encoding = [openTextEncodingPopupButton encoding];
        return [oPanel URLs];
    }else 
        return nil;
}

- (void)openDocument:(id)sender{

    NSStringEncoding encoding;
    NSEnumerator *fileEnum = [[self URLsFromRunningOpenPanelForTypes:[self allReadableTypesForOpenPanel] encoding:&encoding] objectEnumerator];
    NSURL *aURL;

	while (aURL = [fileEnum nextObject]) {
        if (nil == [self openDocumentWithContentsOfURL:aURL encoding:encoding])
            break;
	}
}

- (IBAction)openDocumentUsingPhonyCiteKeys:(id)sender{
    NSStringEncoding encoding;
    NSEnumerator *fileEnum = [[self URLsFromRunningOpenPanelForTypes:[NSArray arrayWithObject:@"bib"] encoding:&encoding] objectEnumerator];
    NSURL *aURL;
    
	while (aURL = [fileEnum nextObject]) {
        [self openDocumentWithContentsOfURLUsingPhonyCiteKeys:aURL encoding:encoding];
	}
}

- (IBAction)openDocumentUsingFilter:(id)sender
{
    int result;
    
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:YES];
    [oPanel setDirectory:[self currentDirectory]];

    [openTextEncodingPopupButton setEncoding:[BDSKStringEncodingManager defaultEncoding]];
    [openTextEncodingAccessoryView setFrameOrigin:NSZeroPoint];
    [openUsingFilterAccessoryView addSubview:openTextEncodingAccessoryView];
    [oPanel setAccessoryView:openUsingFilterAccessoryView];

    NSSet *uniqueCommandHistory = [NSSet setWithArray:[[OFPreferenceWrapper sharedPreferenceWrapper] stringArrayForKey:BDSKFilterFieldHistoryKey]];
    NSMutableArray *commandHistory = [NSMutableArray arrayWithArray:[uniqueCommandHistory allObjects]];
        
    unsigned MAX_HISTORY = 7;
    if([commandHistory count] > MAX_HISTORY)
        [commandHistory removeObjectsInRange:NSMakeRange(MAX_HISTORY, [commandHistory count] - MAX_HISTORY)];
    [openUsingFilterComboBox addItemsWithObjectValues:commandHistory];
    
    if([commandHistory count]){
        [openUsingFilterComboBox selectItemAtIndex:0];
        [openUsingFilterComboBox setObjectValue:[openUsingFilterComboBox objectValueOfSelectedItem]];
    }
    result = [self runModalOpenPanel:oPanel forTypes:nil];
    
    if (result == NSOKButton) {
        NSString *shellCommand = [openUsingFilterComboBox stringValue];
        NSStringEncoding encoding = [openTextEncodingPopupButton encoding];
        NSEnumerator *fileEnum = [[oPanel URLs] objectEnumerator];
        NSURL *aURL;
        
        while (aURL = [fileEnum nextObject]) {
            [self openDocumentWithContentsOfURL:aURL usingFilter:shellCommand encoding:encoding];
        }
        
        unsigned commandIndex = [commandHistory indexOfObject:shellCommand];
        if(commandIndex != NSNotFound && commandIndex != 0)
            [commandHistory removeObject:shellCommand];
        [commandHistory insertObject:shellCommand atIndex:0];
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:commandHistory forKey:BDSKFilterFieldHistoryKey];
    }
}

- (id)openDocumentWithContentsOfURL:(NSURL *)fileURL encoding:(NSStringEncoding)encoding{
    NSParameterAssert(encoding != 0);
	// first see if we already have this document open
    id doc = [self documentForURL:fileURL];
    
    if(doc == nil){
        BOOL success;
        // make a fresh document, and don't display it until we can set its name.
        
        NSError *error;
        doc = [self openUntitledDocumentAndDisplay:NO error:&error];
        
        if (nil == doc) {
            [self presentError:error];
            return nil;
        }
        
        NSString *type = [self typeForContentsOfURL:fileURL error:&error];
        
        if (nil == type) {
            [self presentError:error];
            return nil;
        }

        [doc setFileURL:fileURL]; // this effectively makes it not an untitled document anymore.
        success = [doc readFromURL:fileURL ofType:type encoding:encoding error:&error];
        if (success == NO) {
            [self removeDocument:doc];
            [self presentError:error];
            return nil;
        }
    }
    
    [doc makeWindowControllers];
    [doc showWindows];
    
    return doc;
}

- (id)openUntitledBibTeXDocumentWithString:(NSString *)fileString encoding:(NSStringEncoding)encoding error:(NSError **)outError{
    // @@ we could also use [[NSApp delegate] temporaryFilePath:[filePath lastPathComponent] createDirectory:NO];
    // or [[NSFileManager defaultManager] uniqueFilePath:[filePath lastPathComponent] createDirectory:NO];
    // or move aside the original file
    NSString *tmpFilePath = [[[NSApp delegate] temporaryFilePath:nil createDirectory:NO] stringByAppendingPathExtension:@"bib"];
    NSURL *tmpFileURL = [NSURL fileURLWithPath:tmpFilePath];
    NSData *data = [fileString dataUsingEncoding:encoding];
    
    // If data is nil, then [data writeToFile:error:] is interpreted as NO since it's a message to nil...but doesn't initialize &error, so we crash!
    if (nil == data) {
        if (outError) {
            *outError = [NSError mutableLocalErrorWithCode:kBDSKStringEncodingError localizedDescription:NSLocalizedString(@"Incorrect string encoding", @"")];
            [*outError setValue:[NSNumber numberWithInt:encoding] forKey:NSStringEncodingErrorKey];
            [*outError setValue:[NSString stringWithFormat:NSLocalizedString(@"The file could not be converted to encoding \"%@\".  Please try a different encoding.", @""), [NSString localizedNameOfStringEncoding:encoding]] forKey:NSLocalizedRecoverySuggestionErrorKey];
        }
        return nil;
    }
    
    NSError *error;
    
    // bail out if we can't write the temp file
    if([data writeToFile:tmpFilePath options:NSAtomicWrite error:&error] == NO) {
        if (outError) *outError = error;
        return nil;
    }
    
    // make a fresh document, and don't display it until we can set its name.
    BibDocument *doc = [self openUntitledDocumentAndDisplay:NO error:outError];    
    [doc setFileURL:tmpFileURL]; // required for error handling
    BOOL success = [doc readFromURL:tmpFileURL ofType:BDSKBibTeXDocumentType encoding:encoding error:outError];
    
    if (success == NO) {
        [self removeDocument:doc];
        doc = nil;
    } else {
        [doc setFileURL:nil];
        // set date-added for imports
        NSString *importDate = [[NSCalendarDate date] description];
        [[doc publications] makeObjectsPerformSelector:@selector(setField:toValue:) withObject:BDSKDateAddedString withObject:importDate];
        [[doc undoManager] removeAllActions];
        [doc makeWindowControllers];
        [doc showWindows];
        // mark as dirty, since we've changed the content
        [doc updateChangeCount:NSChangeDone];
    }
    
    return doc;
}

- (id)openDocumentWithContentsOfURLUsingPhonyCiteKeys:(NSURL *)fileURL encoding:(NSStringEncoding)encoding;
{
    NSString *stringFromFile = [NSString stringWithContentsOfURL:fileURL encoding:encoding error:NULL];
    stringFromFile = [stringFromFile stringWithPhoneyCiteKeys:@"FixMe"];
    
    NSError *error;
	BibDocument *doc = [self openUntitledBibTeXDocumentWithString:stringFromFile encoding:encoding error:&error];
    if (nil == doc)
        [self presentError:error];
    
    [doc reportTemporaryCiteKeys:@"FixMe" forNewDocument:YES];
    
    return doc;
}

- (id)openDocumentWithContentsOfURL:(NSURL *)fileURL usingFilter:(NSString *)shellCommand encoding:(NSStringEncoding)encoding;
{
    NSError *error;
    NSString *fileInputString = [NSString stringWithContentsOfURL:fileURL encoding:encoding error:NULL];
    BibDocument *doc = nil;
        
    if (nil == fileInputString){
        [self presentError:error];
    } else {
        NSString *filterOutput = [BDSKShellTask runShellCommand:shellCommand withInputString:fileInputString];
        
        if ([NSString isEmptyString:filterOutput]){
            NSRunAlertPanel(NSLocalizedString(@"Unable To Open With Filter", @"Message in alert dialog when unable to open a document with filter"),
                            NSLocalizedString(@"Unable to read the file correctly. Please ensure that the shell command specified for filtering is correct by testing it in Terminal.app.", @"Informative text in alert dialog"),
                            NSLocalizedString(@"OK", @"Button title"),
                            nil, nil, nil, nil);
        } else {
            doc = [self openUntitledBibTeXDocumentWithString:filterOutput encoding:NSUTF8StringEncoding error:&error];
            if (nil == doc)
                [self presentError:error];
        }
    }    
    return doc;
}

- (id)openDocumentWithContentsOfURL:(NSURL *)absoluteURL display:(BOOL)displayDocument error:(NSError **)outError{
            
    NSString *theUTI = [[NSWorkspace sharedWorkspace] UTIForURL:absoluteURL];
    id document = nil;
    
    if ([theUTI isEqualToUTI:@"net.sourceforge.bibdesk.bdskcache"]) {
        NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfURL:absoluteURL];
        BDAlias *fileAlias = [BDAlias aliasWithData:[dictionary valueForKey:@"FileAlias"]];
        NSString *fullPath = [fileAlias fullPath];
        
        if(fullPath == nil) // if the alias didn't work, let's see if we have a filepath key...
            fullPath = [dictionary valueForKey:@"net_sourceforge_bibdesk_owningfilepath"];
        
        if(fullPath == nil){
            if(outError != nil) 
                *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to find the file associated with this item.", @"Error description"), NSLocalizedDescriptionKey, nil]];
            return nil;
        }
            
        NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
        
        NSError *error = nil; // this is a garbage pointer if the document is already open
        document = [super openDocumentWithContentsOfURL:fileURL display:YES error:&error];
        
        if(document == nil)
            NSLog(@"document at URL %@ failed to open for reason: %@", fileURL, [error localizedFailureReason]);
        else
            if(![document selectItemForPartialItem:dictionary])
                NSBeep();
    } else if ([theUTI isEqualToUTI:@"net.sourceforge.bibdesk.bdsksearch"]) {
        
        NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfURL:absoluteURL];
        Class aClass = NSClassFromString([dictionary objectForKey:@"class"]);
        if (aClass == Nil) aClass = [BDSKSearchGroup class];
        BDSKSearchGroup *group = [[aClass alloc] initWithDictionary:dictionary];
        
        if (nil == group) {
            if (outError) *outError = [NSError mutableLocalErrorWithCode:kBDSKPropertyListDeserializationFailed localizedDescription:NSLocalizedString(@"Unable to read this file as a search group property list", @"error when opening search group file")];
            NSLog(@"Unable to instantiate BDSKSearchGroup of class %@", [dictionary objectForKey:@"class"]);
            // make sure we return nil
            document = nil;
            
        } else {
            // try the main document first
            document = [self mainDocument];
            if (nil == document) {
                document = [self openUntitledDocumentAndDisplay:YES error:outError];
                [document showWindows];
            }
            
            [[document groups] addSearchGroup:group];
            [group release];
        }
        
    } else {
        document = [super openDocumentWithContentsOfURL:absoluteURL display:displayDocument error:outError];
    }
    
    return document;
}

- (void)closeAllDocumentsWithDelegate:(id)delegate didCloseAllSelector:(SEL)didCloseAllSelector contextInfo:(void *)contextInfo{
    NSArray *fileNames = [[self documents] valueForKeyPath:@"@distinctUnionOfObjects.fileName"];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[fileNames count]];
    NSEnumerator *fEnum = [fileNames objectEnumerator];
    NSString *fileName;
    while(fileName = [fEnum nextObject]){
        NSData *data = [[BDAlias aliasWithPath:fileName] aliasData];
        if(data)
            [array addObject:[NSDictionary dictionaryWithObjectsAndKeys:fileName, @"fileName", data, @"_BDAlias", nil]];
        else
            [array addObject:[NSDictionary dictionaryWithObjectsAndKeys:fileName, @"fileName", nil]];
    }
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:array forKey:BDSKLastOpenFileNamesKey];
    
    [super closeAllDocumentsWithDelegate:delegate didCloseAllSelector:didCloseAllSelector contextInfo:contextInfo];
}

#pragma mark Document types

- (NSArray *)fileExtensionsFromType:(NSString *)documentTypeName
{
    NSArray *fileExtensions = [super fileExtensionsFromType:documentTypeName];
    if([fileExtensions count] == 0){
    	NSString *fileExtension = [[BDSKTemplate templateForStyle:documentTypeName] fileExtension];
        if(fileExtension != nil)
            fileExtensions = [NSArray arrayWithObject:fileExtension];
    }
	return fileExtensions;
}

- (NSString *)typeFromFileExtension:(NSString *)fileExtensionOrHFSFileType
{
	NSString *type = [super typeFromFileExtension:fileExtensionOrHFSFileType];
    if(type == nil){
        type = [[BDSKTemplate defaultStyleNameForFileType:fileExtensionOrHFSFileType] valueForKey:BDSKTemplateNameString];
    }else if ([type isEqualToString:BDSKMinimalBibTeXDocumentType]){
        // fix of bug when reading a .bib file
        // this is interpreted as Minimal BibTeX, even though we don't declare that as a readable type
        type = BDSKBibTeXDocumentType;
    }
	return type;
}

- (Class)documentClassForType:(NSString *)documentTypeName
{
	Class docClass = [super documentClassForType:documentTypeName];
    if (docClass == Nil){
        [[BDSKTemplate allStyleNames] containsObject:documentTypeName];
            docClass = [BibDocument class];
    }
    return docClass;
}

- (NSString *)displayNameForType:(NSString *)documentTypeName{
    NSString *displayName = nil;
    if([documentTypeName isEqualToString:BDSKMinimalBibTeXDocumentType])
        displayName = NSLocalizedString(@"Minimal BibTeX", @"Popup menu title for Minimal BibTeX");
    else if([documentTypeName isEqualToString:[BDSKTemplate defaultStyleNameForFileType:@"html"]])
        displayName = @"HTML";
    else if([documentTypeName isEqualToString:[BDSKTemplate defaultStyleNameForFileType:@"rss"]])
        displayName = @"RSS";
    else if([documentTypeName isEqualToString:[BDSKTemplate defaultStyleNameForFileType:@"rtf"]])
        displayName = NSLocalizedString(@"Rich Text (RTF)", @"Popup menu title for Rich Text (RTF)");
    else if([documentTypeName isEqualToString:[BDSKTemplate defaultStyleNameForFileType:@"rtfd"]])
        displayName = NSLocalizedString(@"Rich Text with Graphics (RTFD)", @"Popup menu title for Rich Text (RTFD)");
    else if([documentTypeName isEqualToString:[BDSKTemplate defaultStyleNameForFileType:@"doc"]])
        displayName = NSLocalizedString(@"Word Format (Doc)", @"Popup menu title for Word Format (Doc)");
    else
        displayName = [super displayNameForType:documentTypeName];
    return displayName;
}

@end

#pragma mark -

@interface NSSavePanel (AppleBugPrivate)
- (BOOL)_canShowGoto;
@end

@interface BDSKPosingSavePanel : NSSavePanel @end

@implementation BDSKPosingSavePanel

+ (void)load
{
    [self poseAsClass:NSClassFromString(@"NSSavePanel")];
}

// hack around an acknowledged Apple bug (http://www.cocoabuilder.com/archive/message/cocoa/2006/4/14/161080) that causes the goto panel to be displayed when trying to enter a leading / in "Open Using Filter" accessory view (our bug #1480815)
- (BOOL)_canShowGoto;
{
    id firstResponder = [self firstResponder];
    // this is likely a field editor, but we have to make sure
    if([firstResponder isKindOfClass:[NSText class]] && [firstResponder isFieldEditor]){
        // if it's our custom view, the control will be a combo box (delegate of the field editor)
        NSView *accessoryView = [self accessoryView];
        if (accessoryView != nil && [accessoryView ancestorSharedWithView:[firstResponder delegate]] == accessoryView)
            return NO;
    }
    return [super _canShowGoto];
}

@end
