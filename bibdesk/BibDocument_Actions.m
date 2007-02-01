//
//  BibDocument_Actions.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 10/14/06.
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

#import "BibDocument_Actions.h"
#import "BibDocument_DataSource.h"
#import "BibDocument_Groups.h"
#import "BibDocument_Search.h"
#import "BibPrefController.h"
#import "BibItem.h"
#import "BibAuthor.h"
#import "BDSKGroup.h"
#import "BDSKStaticGroup.h"
#import "BDSKPublicationsArray.h"
#import "BDSKGroupsArray.h"

#import "BibEditor.h"
#import "BibPersonController.h"
#import "BDSKDocumentInfoWindowController.h"
#import "MacroWindowController.h"

#import "NSString_BDSKExtensions.h"
#import "NSArray_BDSKExtensions.h"
#import "NSWorkspace_BDSKExtensions.h"
#import "NSFileManager_BDSKExtensions.h"
#import "NSTableView_BDSKExtensions.h"

#import "BibTypeManager.h"
#import "BDSKScriptHookManager.h"
#import "BDSKAlert.h"
#import "BibFiler.h"
#import "BDSKTextImportController.h"
#import "BDSKStatusBar.h"
#import "BDSKSharingServer.h"
#import "BDSKSharingBrowser.h"
#import "BDSKTemplate.h"
#import "BDSKTemplateObjectProxy.h"
#import "BDSKMainTableView.h"
#import "BDSKGroupTableView.h"
#import "BDSKSplitView.h"
#import "BDSKShellTask.h"
#import "BDSKColoredBox.h"
#import "BDSKStringParser.h"
#import "BDSKZoomablePDFView.h"
#import "BDSKSearchField.h"
#import "BDSKCustomCiteDrawerController.h"
#import "NSObject_BDSKExtensions.h"
#import "BDSKOwnerProtocol.h"


@implementation BibDocument (Actions)

#pragma mark -
#pragma mark Publication actions

- (void)addNewPubAndEdit:(BibItem *)newBI{
    // add the publication; addToGroup:handleInherited: depends on the pub having a document
    [self addPublication:newBI];

	[[self undoManager] setActionName:NSLocalizedString(@"Add Publication", @"Undo action name")];
	
    NSEnumerator *groupEnum = [[self selectedGroups] objectEnumerator];
	BDSKGroup *group;
	BOOL isSingleValued = [[self currentGroupField] isSingleValuedField];
    int count = 0;
    // we don't overwrite inherited single valued fields, they already have the field set through inheritance
    int op, handleInherited = isSingleValued ? BDSKOperationIgnore : BDSKOperationAsk;
    
    while (group = [groupEnum nextObject]) {
		if ([group isCategory]){
            if (isSingleValued && count > 0)
                continue;
			op = [newBI addToGroup:group handleInherited:handleInherited];
            if(op == BDSKOperationSet || op == BDSKOperationAppend){
                count++;
            }else if(op == BDSKOperationAsk){
                BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Inherited Value", @"Message in alert dialog when trying to edit inherited value")
                                                     defaultButton:NSLocalizedString(@"Don't Change", @"Button title")
                                                   alternateButton:nil // "Set" would end up choosing an arbitrary one
                                                       otherButton:NSLocalizedString(@"Append", @"Button title")
                                         informativeTextWithFormat:NSLocalizedString(@"The new item has a group value that was inherited from an item linked to by the Crossref field. This operation would break the inheritance for this value. What do you want me to do with inherited values?", @"Informative text in alert dialog")];
                handleInherited = [alert runSheetModalForWindow:documentWindow];
                if(handleInherited != BDSKOperationIgnore){
                    [newBI addToGroup:group handleInherited:handleInherited];
                    count++;
                }
            }
        } else if ([group isStatic]) {
            [(BDSKStaticGroup *)group addPublication:newBI];
        }
    }
	
	if (isSingleValued && [groups numberOfCategoryGroupsAtIndexes:[groupTableView selectedRowIndexes]] > 1) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Cannot Add to All Groups", @"Message in alert dialog when trying to add to multiple single-valued field groups")
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"The new item can only be added to one of the selected \"%@\" groups", @"Informative text in alert dialog"), [self currentGroupField]];
        [alert beginSheetModalForWindow:documentWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
    
    [self selectPublication:newBI];
    [self editPub:newBI];
}

- (void)createNewPub{
    BibItem *newBI = [[[BibItem alloc] init] autorelease];
    [self addNewPubAndEdit:newBI];
}

- (void)createNewPubUsingCrossrefForItem:(BibItem *)item{
    BibItem *newBI = [[BibItem alloc] init];
	NSString *parentType = [item pubType];
    
	[newBI setField:BDSKCrossrefString toValue:[item citeKey]];
	if ([parentType isEqualToString:BDSKProceedingsString]) {
		[newBI setPubType:BDSKInproceedingsString];
	} else if ([parentType isEqualToString:BDSKBookString] || 
			   [parentType isEqualToString:BDSKBookletString] || 
			   [parentType isEqualToString:BDSKTechreportString] || 
			   [parentType isEqualToString:BDSKManualString]) {
		if (![[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKPubTypeStringKey] isEqualToString:BDSKInbookString]) 
			[newBI setPubType:BDSKIncollectionString];
	}
    [self addNewPubAndEdit:newBI];
    [newBI release];
}

- (IBAction)createNewPubUsingCrossrefAction:(id)sender{
    BibItem *selectedBI = [[self selectedPublications] lastObject];
    [self createNewPubUsingCrossrefForItem:selectedBI];
}

- (IBAction)newPub:(id)sender{
    if ([NSApp currentModifierFlags] & NSAlternateKeyMask) {
        [self createNewPubUsingCrossrefAction:sender];
    } else {
        [self createNewPub];
    }
}

- (void)removePubsAlertDidEnd:(BDSKAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if ([alert checkValue] == YES)
		[[OFPreferenceWrapper sharedPreferenceWrapper] setBool:NO forKey:BDSKWarnOnRemovalFromGroupKey];
    if (returnCode == NSAlertDefaultReturn)
        [self removePublications:[self selectedPublications] fromGroups:[self selectedGroups]];
}

// this method is called for the main table; it's a wrapper for delete or remove from group
- (IBAction)removeSelectedPubs:(id)sender{
	NSArray *selectedGroups = [self selectedGroups];
	
	if([self hasLibraryGroupSelected]){
		[self deleteSelectedPubs:sender];
	}else{
		BOOL canRemove = NO;
        if ([self hasStaticGroupsSelected])
            canRemove = YES;
        else if ([[self currentGroupField] isSingleValuedField] == NO)
            canRemove = [self hasCategoryGroupsSelected];
		if(canRemove == NO){
			NSBeep();
			return;
		}
        // the items may not belong to the groups that you're trying to remove them from, but we'll warn as if they were
        if ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKWarnOnRemovalFromGroupKey]) {
            NSString *groupName = ([selectedGroups count] > 1 ? NSLocalizedString(@"multiple groups", @"multiple groups") : [NSString stringWithFormat:NSLocalizedString(@"group \"%@\"", @"group \"Name\""), [[selectedGroups firstObject] stringValue]]);
            BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Warning", @"Message in alert dialog")
                                                 defaultButton:NSLocalizedString(@"Yes", @"Button title")
                                               alternateButton:nil
                                                   otherButton:NSLocalizedString(@"No", @"Button title")
                                     informativeTextWithFormat:NSLocalizedString(@"You are about to remove %i %@ from %@.  Do you want to proceed?", @"Informative text in alert dialog: You are about to remove [number] item(s) from [group \"Name\"]."), [tableView numberOfSelectedRows], ([tableView numberOfSelectedRows] > 1 ? NSLocalizedString(@"items", @"") : NSLocalizedString(@"item", @"")), groupName];
            [alert setHasCheckButton:YES];
            [alert setCheckValue:NO];
            [alert beginSheetModalForWindow:documentWindow
                              modalDelegate:self 
                             didEndSelector:@selector(removePubsAlertDidEnd:returnCode:contextInfo:) 
                                contextInfo:NULL];
            return;
        } else {
            [self removePublications:[self selectedPublications] fromGroups:selectedGroups];
        }
	}
}

- (void)deletePubsAlertDidEnd:(BDSKAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (alert != nil && [alert checkValue] == YES)
		[[OFPreferenceWrapper sharedPreferenceWrapper] setBool:NO forKey:BDSKWarnOnDeleteKey];
    if (returnCode == NSAlertOtherReturn)
        return;
    
    // deletion changes the scroll position
    NSPoint scrollLocation = [[tableView enclosingScrollView] scrollPositionAsPercentage];
    int lastIndex = [[tableView selectedRowIndexes] lastIndex];
	[self removePublications:[self selectedPublications]];
    [[tableView enclosingScrollView] setScrollPositionAsPercentage:scrollLocation];
    
    // should select the publication following the last deleted publication (if any)
	if(lastIndex >= [tableView numberOfRows])
        lastIndex = [tableView numberOfRows] - 1;
    if(lastIndex != -1)
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:lastIndex] byExtendingSelection:NO];
    
	int numSelectedPubs = [self numberOfSelectedPubs];
	NSString * pubSingularPlural;
	if (numSelectedPubs == 1) {
		pubSingularPlural = NSLocalizedString(@"publication", @"publication, in status message");
	} else {
		pubSingularPlural = NSLocalizedString(@"publications", @"publications, in status message");
	}
	
    [self setStatus:[NSString stringWithFormat:NSLocalizedString(@"Deleted %i %@",@"Deleted %i %@ [i-> number, @-> publication(s)]"),numSelectedPubs, pubSingularPlural] immediate:NO];
	
	[[self undoManager] setActionName:[NSString stringWithFormat:NSLocalizedString(@"Delete %@", @"Undo action name: Delete Publication(s)"),pubSingularPlural]];
}

- (IBAction)deleteSelectedPubs:(id)sender{
	int numSelectedPubs = [self numberOfSelectedPubs];
    if (numSelectedPubs == 0 ||
        [self hasExternalGroupsSelected] == YES) {
        return;
    }
	
	if ([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKWarnOnDeleteKey]) {
		BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Warning", @"Message in alert dialog")
											 defaultButton:NSLocalizedString(@"OK", @"Button title")
										   alternateButton:nil
											   otherButton:NSLocalizedString(@"Cancel", @"Button title")
								 informativeTextWithFormat:NSLocalizedString(@"You are about to delete %i items. Do you want to proceed?", @"Informative text in alert dialog"), numSelectedPubs];
		[alert setHasCheckButton:YES];
		[alert setCheckValue:NO];
        [alert beginSheetModalForWindow:documentWindow
                          modalDelegate:self 
                         didEndSelector:@selector(deletePubsAlertDidEnd:returnCode:contextInfo:) 
                            contextInfo:NULL];
	} else {
        [self deletePubsAlertDidEnd:nil returnCode:NSAlertDefaultReturn contextInfo:NULL];
    }
}

- (IBAction)alternateDelete:(id)sender {
	id firstResponder = [documentWindow firstResponder];
	if (firstResponder == tableView) {
		[self deleteSelectedPubs:sender];
	} else if (firstResponder == groupTableView) {
		[self removeSelectedGroups:sender];
	}
}

// -delete:, -insertNewline:, -cut:, -copy: and -paste: are defined indirectly in NSTableView-OAExtensions using our dataSource method
// Note: cut: calls delete:

- (IBAction)alternateCut:(id)sender {
	if ([documentWindow firstResponder] == tableView) {
		[tableView copy:sender];
		[self alternateDelete:sender];
	}
}

- (IBAction)copyAsAction:(id)sender{
	int copyType = [sender tag];
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
	NSString *citeString = [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKCiteStringKey];
	[self writePublications:[self selectedPublications] forDragCopyType:copyType citeString:citeString toPasteboard:pboard];
}

// Don't use the default action in NSTableView-OAExtensions here, as it uses another pasteboard and some more overhead
- (IBAction)duplicate:(id)sender{
	if ([documentWindow firstResponder] != tableView ||
		[self numberOfSelectedPubs] == 0 ||
        [self hasExternalGroupsSelected] == YES) {
		NSBeep();
		return;
	}
	
    NSArray *newPubs = [[NSArray alloc] initWithArray:[self selectedPublications] copyItems:YES];
    
    [self addPublications:newPubs]; // notification will take care of clearing the search/sorting
    [self selectPublications:newPubs];
    [newPubs release];
	
    if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKEditOnPasteKey]) {
        [self editPubCmd:nil]; // this will aske the user when there are many pubs
    }
}

- (BibEditor *)editorForPublication:(BibItem *)pub create:(BOOL)createNew{
    BibEditor *editor = nil;
	NSEnumerator *wcEnum = [[self windowControllers] objectEnumerator];
	NSWindowController *wc;
	
	while(wc = [wcEnum nextObject]){
		if([wc isKindOfClass:[BibEditor class]] && [[(BibEditor*)wc publication] isEqual:pub]){
			editor = (BibEditor*)wc;
			break;
		}
	}
    if(editor == nil && createNew){
        editor = [[BibEditor alloc] initWithPublication:pub];
        [self addWindowController:editor];
        [editor release];
    }
    return editor;
}

- (BibEditor *)editPub:(BibItem *)pub{
    BibEditor *editor = [self editorForPublication:pub create:YES];
    [editor show];
    return editor;
}

- (BibEditor *)editPubBeforePub:(BibItem *)pub{
    int index = [shownPublications indexOfObject:pub];
    if(index == NSNotFound){
        NSBeep();
        return nil;
    }
    if(index-- == 0)
        index = [shownPublications count] - 1;
    return [self editPub:[shownPublications objectAtIndex:index]];
}

- (BibEditor *)editPubAfterPub:(BibItem *)pub{
    unsigned int index = [shownPublications indexOfObject:pub];
    if(index == NSNotFound){
        NSBeep();
        return nil;
    }
    if(++index == [shownPublications count])
        index = 0;
    return [self editPub:[shownPublications objectAtIndex:index]];
}

- (void)editPubAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    NSArray *pubs = (NSArray *)contextInfo;
    if (returnCode == NSAlertAlternateReturn) {
        [self performSelector:@selector(editPub:) withObjectsFromArray:pubs];
    }
    [pubs release];
}

- (void)editPublications:(NSArray *)pubs{
    int n = [pubs count];
    if (n > 6) {
        // Do we really want a gazillion of editor windows?
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Edit publications", @"Message in alert dialog when trying to open a lot of publication editors")
                                         defaultButton:NSLocalizedString(@"No", @"Button title")
                                      alternateButton:NSLocalizedString(@"Yes", @"Button title")
                                          otherButton:nil
                            informativeTextWithFormat:[NSString stringWithFormat:NSLocalizedString(@"BibDesk is about to open %i editor windows.  Is this really what you want?" , @"Informative text in alert dialog"), n]];
        [alert beginSheetModalForWindow:documentWindow
                          modalDelegate:self
                         didEndSelector:@selector(editPubAlertDidEnd:returnCode:contextInfo:) 
                            contextInfo:[pubs retain]];
    } else {
        [self editPubAlertDidEnd:nil returnCode:NSAlertAlternateReturn contextInfo:[pubs retain]];
    }
}

- (IBAction)editPubCmd:(id)sender{
    [self editPublications:[self selectedPublications]];
}

- (void)editAction:(id)sender {
	id firstResponder = [documentWindow firstResponder];
	if (firstResponder == tableView) {
		[self editPubCmd:sender];
	} else if (firstResponder == groupTableView) {
		[self editGroupAction:sender];
	}
}

- (IBAction)editPubOrOpenURLAction:(id)sender{
    int column = [tableView clickedColumn];
    NSString *colID = column != -1 ? [[[tableView tableColumns] objectAtIndex:column] identifier] : nil;
    
    if([colID isLocalFileField])
		[self openLinkedFileForField:colID];
    else if([colID isRemoteURLField])
		[self openRemoteURLForField:colID];
    else
        [self editPubCmd:sender];
}

- (void)showPerson:(BibAuthor *)person{
    OBASSERT(person != nil && [person isKindOfClass:[BibAuthor class]]);
    BibPersonController *pc = [person personController];
    
    if(pc == nil){
        pc = [[BibPersonController alloc] initWithPerson:person];
        [self addWindowController:pc];
        [pc release];
    }
    [pc show];
}

- (IBAction)emailPubCmd:(id)sender{
    NSMutableArray *items = [[self selectedPublications] mutableCopy];
    NSEnumerator *e = [[self selectedPublications] objectEnumerator];
    BibItem *pub = nil;
    
    NSFileManager *dfm = [NSFileManager defaultManager];
    NSString *pubPath = nil;
    NSMutableString *body = [NSMutableString string];
    NSMutableArray *files = [NSMutableArray array];
    
    NSString *templateName = [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:@"BDSKEmailTemplateKey"];
    BDSKTemplate *template = nil;
    
    if ([NSString isEmptyString:templateName] == NO)
        template = [BDSKTemplate templateForStyle:templateName];
    
    while (pub = [e nextObject]) {
        pubPath = [pub localUrlPath];
        if([dfm fileExistsAtPath:pubPath])
            [files addObject:pubPath];
        
        pub = [pub crossrefParent];
        if (pub != nil && [items containsObject:pub] == NO) {
            [items addObject:pub];
            pubPath = [pub localUrlPath];
            if([dfm fileExistsAtPath:pubPath])
                [files addObject:pubPath];
        }
    }
    
    if (template != nil && ([template templateFormat] & BDSKTextTemplateFormat)) {
        [body setString:[BDSKTemplateObjectProxy stringByParsingTemplate:template withObject:self publications:items]];
    } else {
        e = [items objectEnumerator];
        while (pub = [e nextObject]) {
            // use the detexified version without internal fields, since TeXification introduces things that 
            // AppleScript can't deal with (OAInternetConfig may end up using AS)
            [body appendString:[pub bibTeXStringDroppingInternal:YES texify:NO]];
            [body appendString:@"\n\n"];
        }
    }
    
    // ampersands are common in publication names
    [body replaceOccurrencesOfString:@"&" withString:@"\\&" options:NSLiteralSearch range:NSMakeRange(0, [body length])];
    // escape backslashes
    [body replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:NSLiteralSearch range:NSMakeRange(0, [body length])];
    // escape double quotes
    [body replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSLiteralSearch range:NSMakeRange(0, [body length])];

    // OAInternetConfig will use the default mail helper (at least it works with Mail.app and Entourage)
    OAInternetConfig *ic = [OAInternetConfig internetConfig];
    [ic launchMailTo:nil
          carbonCopy:nil
     blindCarbonCopy:nil
             subject:@"BibDesk references"
                body:body
         attachments:files];

}

- (IBAction)sendToLyX:(id)sender {
    if ([self numberOfSelectedPubs] == 0)
        return;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *appSupportPath = [fileManager applicationSupportDirectory:kUserDomain];
    NSString *lyxPipePath = [[appSupportPath stringByAppendingPathComponent:@"LyX-1.4"] stringByAppendingPathComponent:@".lyxpipe.in"];
    
    if ([fileManager fileExistsAtPath:lyxPipePath] == NO) {
        lyxPipePath = [[appSupportPath stringByAppendingPathComponent:@"LyX"] stringByAppendingPathComponent:@".lyxpipe.in"];
        if ([fileManager fileExistsAtPath:lyxPipePath] == NO) {
            lyxPipePath = [[NSHomeDirectory() stringByAppendingPathComponent:@".lyx"] stringByAppendingPathComponent:@"lyxpipe.in"];
            if ([fileManager fileExistsAtPath:lyxPipePath] == NO) {
                NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Unable to Find LyX Pipe", @"Message in alert dialog when LyX pipe cannot be found")
                                                 defaultButton:nil
                                               alternateButton:nil
                                                   otherButton:nil
                                    informativeTextWithFormat:NSLocalizedString(@"BibDesk was unable to find the LyX pipe." , @"Informative text in alert dialog")];
                [alert beginSheetModalForWindow:documentWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
                return;
            }
        }
    }
    
    NSEnumerator *itemEnum = [[self selectedPublications] objectEnumerator];
    BibItem *item;
    NSMutableString *cites = [NSMutableString string];
    
    while (item = [itemEnum nextObject]) {
        if ([cites length] > 0) [cites appendString:@","];
        [cites appendString:[item citeKey]];
    }
    
    NSString *lyxCmd = [NSString stringWithFormat:@"echo LYXCMD:BibDesk:citation-insert:%@ > \"%@\"", cites, lyxPipePath];
    
    [BDSKShellTask runShellCommand:lyxCmd withInputString:nil];
}
- (IBAction)postItemToWeblog:(id)sender{

	[NSException raise:BDSKUnimplementedException
				format:@"postItemToWeblog is unimplemented."];
	
	NSString *appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Blapp"]; // pref
	NSLog(@"%@",appPath);
#if 0	
	AppleEvent *theAE;
	OSERR err = AECreateAppleEvent (NNWEditDataItemAppleEventClass,
									NNWEditDataItemAppleEventID,
									'MMcC', // Blapp
									kAutoGenerateReturnID,
									kAnyTransactionID,
									&theAE);


	
	
	OSErr AESend (
				  const AppleEvent * theAppleEvent,
				  AppleEvent * reply,
				  AESendMode sendMode,
				  AESendPriority sendPriority,
				  SInt32 timeOutInTicks,
				  AEIdleUPP idleProc,
				  AEFilterUPP filterProc
				  );
#endif
}

#pragma mark | URL actions

- (IBAction)openLinkedFile:(id)sender{
	NSString *field = [sender representedObject];
    if (field == nil)
		field = BDSKLocalUrlString;
    [self openLinkedFileForField:field];
}
/*
- (BOOL)textView:(NSTextView *)aTextView clickedOnLink:(id)link atIndex:(unsigned)charIndex
{
    if ([link respondsToSelector:@selector(isFileURL)] && [link isFileURL]) {
        NSString *searchString;
        if([[searchField searchKey] isEqualToString:BDSKKeywordsString] || [[searchField searchKey] isEqualToString:BDSKAllFieldsString])
            searchString = [searchField stringValue];
        else
            searchString = @"";
        [[NSWorkspace sharedWorkspace] openURL:link withSearchString:searchString];
        return YES;
    }
    // let the next responder handle it if it was a string or non-file URL
    return NO;
}
*/
- (void)openLinkedFileAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    NSString *field = (NSString *)contextInfo;
    if (returnCode == NSAlertAlternateReturn) {
        NSEnumerator *e = [[self selectedPublications] objectEnumerator];
        BibItem *pub;
        NSURL *fileURL;
        
        NSString *searchString;
        // See bug #1344720; don't search if this is a known field (Title, Author, etc.).  This feature can be annoying because Preview.app zooms in on the search result in this case, in spite of your zoom settings (bug report filed with Apple).
        if([[searchField searchKey] isEqualToString:BDSKKeywordsString] || [[searchField searchKey] isEqualToString:BDSKAllFieldsString])
            searchString = [searchField stringValue];
        else
            searchString = @"";
        
        // the user said to go ahead
        while (pub = [e nextObject]) {
            fileURL = [pub URLForField:field];
            if(fileURL == nil) continue;
            [[NSWorkspace sharedWorkspace] openURL:fileURL withSearchString:searchString];
        }
    }
    [field release];
}

- (void)openLinkedFileForField:(NSString *)field{
	int n = [self numberOfSelectedPubs];
    
    if (n > 6) {
		// Do we really want a gazillion of files open?
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Open Linked Files", @"Message in alert dialog when opening a lot of linked files")
                                         defaultButton:NSLocalizedString(@"No", @"Button title")
                                       alternateButton:NSLocalizedString(@"Open", @"Button title")
                                           otherButton:nil
                             informativeTextWithFormat:[NSString stringWithFormat:NSLocalizedString(@"BibDesk is about to open %i linked files. Do you want to proceed?" , @"Informative text in alert dialog"), n]];
        [alert beginSheetModalForWindow:documentWindow
                          modalDelegate:self
                         didEndSelector:@selector(openLinkedFileAlertDidEnd:returnCode:contextInfo:) 
                            contextInfo:NULL];
	} else {
        [self openLinkedFileAlertDidEnd:nil returnCode:NSAlertAlternateReturn contextInfo:[field retain]];
    }
}

- (IBAction)revealLinkedFile:(id)sender{
	NSString *field = [sender representedObject];
    if (field == nil)
		field = BDSKLocalUrlString;
    [self revealLinkedFileForField:field];
}

- (void)revealLinkedFileAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    NSString *field = (NSString *)contextInfo;
    if (returnCode == NSAlertAlternateReturn) {
        NSEnumerator *e = [[self selectedPublications] objectEnumerator];
        BibItem *pub;
        
        while (pub = [e nextObject]) {
            [[NSWorkspace sharedWorkspace]  selectFile:[pub localFilePathForField:field] inFileViewerRootedAtPath:nil];
        }
    }
    [field release];
}

- (void)revealLinkedFileForField:(NSString *)field{
	int n = [self numberOfSelectedPubs];
    
    if (n > 6) {
		// Do we really want a gazillion of Finder windows?
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Reveal Linked Files", @"Message in alert dialog when trying to reveal a lot of linked files")
                                         defaultButton:NSLocalizedString(@"No", @"Button title")
                                       alternateButton:NSLocalizedString(@"Reveal", @"Button title")
                                           otherButton:nil
                             informativeTextWithFormat:[NSString stringWithFormat:NSLocalizedString(@"BibDesk is about to reveal %i linked files. Do you want to proceed?" , @"Informative text in alert dialog"), n]];
        [alert beginSheetModalForWindow:documentWindow
                          modalDelegate:self
                         didEndSelector:@selector(revealLinkedFileAlertDidEnd:returnCode:contextInfo:) 
                            contextInfo:NULL];
	} else {
        [self revealLinkedFileAlertDidEnd:nil returnCode:NSAlertAlternateReturn contextInfo:[field retain]];
    }
}

- (IBAction)openRemoteURL:(id)sender{
	NSString *field = [sender representedObject];
    if (field == nil)
		field = BDSKUrlString;
    [self openRemoteURLForField:field];
}

- (void)openRemoteURLAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	NSString *field = (NSString *)contextInfo;
    if(returnCode == NSAlertAlternateReturn){
        NSEnumerator *e = [[self selectedPublications] objectEnumerator];
        BibItem *pub;
        
		while (pub = [e nextObject]) {
			[[NSWorkspace sharedWorkspace] openURL:[pub remoteURLForField:field]];
		}
	}
    [field release];
}

- (void)openRemoteURLForField:(NSString *)field{
	int n = [self numberOfSelectedPubs];
    
    if (n > 6) {
		// Do we really want a gazillion of browser windows?
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Open Remote URL", @"Message in alert dialog when trying to open a lot of remote URLs")
                                         defaultButton:NSLocalizedString(@"No", @"Button title")
                                      alternateButton:NSLocalizedString(@"Open", @"Button title")
                                          otherButton:nil
                            informativeTextWithFormat:[NSString stringWithFormat:NSLocalizedString(@"BibDesk is about to open %i URLs. Do you want to proceed?" , @"Informative text in alert dialog"), n]];
        [alert beginSheetModalForWindow:documentWindow
                          modalDelegate:self
                         didEndSelector:@selector(openRemoteURLAlertDidEnd:returnCode:contextInfo:) 
                            contextInfo:NULL];
	} else {
        [self openRemoteURLAlertDidEnd:nil returnCode:NSAlertAlternateReturn contextInfo:[field retain]];
    }
}

#pragma mark View Actions

- (IBAction)selectAllPublications:(id)sender {
	[tableView selectAll:sender];
}

- (IBAction)deselectAllPublications:(id)sender {
	[tableView deselectAll:sender];
}

- (IBAction)toggleStatusBar:(id)sender{
	[statusBar toggleBelowView:mainBox offset:1.0];
	[[OFPreferenceWrapper sharedPreferenceWrapper] setBool:[statusBar isVisible] forKey:BDSKShowStatusBarKey];
}

- (IBAction)changeMainTableFont:(id)sender{
    NSString *fontName = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKMainTableViewFontNameKey];
    float fontSize = [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKMainTableViewFontSizeKey];
	[[NSFontManager sharedFontManager] setSelectedFont:[NSFont fontWithName:fontName size:fontSize] isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:sender];
    
    id firstResponder = [documentWindow firstResponder];
    if (firstResponder != tableView)
        [documentWindow makeFirstResponder:tableView];
}

- (IBAction)changeGroupTableFont:(id)sender{
    NSString *fontName = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKGroupTableViewFontNameKey];
    float fontSize = [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKGroupTableViewFontSizeKey];
	[[NSFontManager sharedFontManager] setSelectedFont:[NSFont fontWithName:fontName size:fontSize] isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:sender];
    
    id firstResponder = [documentWindow firstResponder];
    if (firstResponder != groupTableView)
        [documentWindow makeFirstResponder:groupTableView];
}

- (IBAction)changePreviewDisplay:(id)sender{
    int tag = [sender tag];
    if(tag != [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKPreviewDisplayKey]){
        [[OFPreferenceWrapper sharedPreferenceWrapper] setInteger:tag forKey:BDSKPreviewDisplayKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewDisplayChangedNotification object:nil];
    }
}

- (void)pageDownInPreview:(id)sender{
    NSScrollView *scrollView = nil;
    
    if([currentPreviewView isKindOfClass:[NSScrollView class]])
        scrollView = (NSScrollView *)currentPreviewView;
    else if([currentPreviewView isKindOfClass:[BDSKZoomablePDFView class]])
        scrollView = [(BDSKZoomablePDFView *)currentPreviewView scrollView];
    
    NSPoint p = [[scrollView documentView] scrollPositionAsPercentage];
    
    if(p.y > 0.99 || NSHeight([scrollView documentVisibleRect]) >= NSHeight([[scrollView documentView] bounds])){ // select next row if the last scroll put us at the end
        int i = [[tableView selectedRowIndexes] lastIndex];
        if (i == NSNotFound)
            i = 0;
        else if (i < [tableView numberOfRows])
            i++;
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
        [tableView scrollRowToVisible:i];
    }else{
        [scrollView pageDown:sender];
    }
}

- (void)pageUpInPreview:(id)sender{
    NSScrollView *scrollView = nil;
    
    if([currentPreviewView isKindOfClass:[NSScrollView class]])
        scrollView = (NSScrollView *)currentPreviewView;
    else if([currentPreviewView isKindOfClass:[BDSKZoomablePDFView class]])
        scrollView = [(BDSKZoomablePDFView *)currentPreviewView scrollView];
    
    NSPoint p = [[scrollView documentView] scrollPositionAsPercentage];
    
    if(p.y < 0.01){ // select previous row if we're already at the top
        int i = [[tableView selectedRowIndexes] firstIndex];
		if (i == NSNotFound)
			i = 0;
		else if (i > 0)
			i--;
		[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
        [tableView scrollRowToVisible:i];
    }else{
        [scrollView pageUp:sender];
    }
}

- (void)splitViewDoubleClick:(OASplitView *)sender{
    int i = [[sender subviews] count] - 2;
    OBASSERT(i >= 0);
	NSView *firstView = [[sender subviews] objectAtIndex:i];
	NSView *secondView = [[sender subviews] objectAtIndex:++i];
	NSRect firstFrame = [firstView frame];
	NSRect secondFrame = [secondView frame];
	
	if (sender == splitView) {
		// first = table, second = preview
		if(NSHeight([secondView frame]) > 0){ // not sure what the criteria for isSubviewCollapsed, but it doesn't work
			docState.lastPreviewHeight = NSHeight(secondFrame); // cache this
			firstFrame.size.height += docState.lastPreviewHeight;
			secondFrame.size.height = 0;
		} else {
			if(docState.lastPreviewHeight <= 0)
				docState.lastPreviewHeight = NSHeight([sender frame]) / 3; // a reasonable value for uncollapsing the first time
			firstFrame.size.height = NSHeight(firstFrame) + NSHeight(secondFrame) - docState.lastPreviewHeight;
			secondFrame.size.height = docState.lastPreviewHeight;
		}
	} else {
		// first = group, second = table+preview
		if(NSWidth([firstView frame]) > 0){
			docState.lastGroupViewWidth = NSWidth(firstFrame); // cache this
			secondFrame.size.width += docState.lastGroupViewWidth;
			firstFrame.size.width = 0;
		} else {
			if(docState.lastGroupViewWidth <= 0)
				docState.lastGroupViewWidth = 120; // a reasonable value for uncollapsing the first time
			secondFrame.size.width = NSWidth(firstFrame) + NSWidth(secondFrame) - docState.lastGroupViewWidth;
			firstFrame.size.width = docState.lastGroupViewWidth;
		}
	}
	
	[firstView setFrame:firstFrame];
	[secondView setFrame:secondFrame];
    [sender adjustSubviews];
}

#pragma mark Showing related info windows

- (IBAction)toggleShowingCustomCiteDrawer:(id)sender{
    if(drawerController == nil)
        drawerController = [[BDSKCustomCiteDrawerController alloc] initForDocument:self];
    [drawerController toggle:sender];
    return;
}

- (IBAction)showDocumentInfoWindow:(id)sender{
    if (!infoWC) {
        infoWC = [(BDSKDocumentInfoWindowController *)[BDSKDocumentInfoWindowController alloc] initWithDocument:self];
    }
    if ([[self windowControllers] containsObject:infoWC] == NO) {
        [self addWindowController:infoWC];
    }
    [infoWC beginSheetModalForWindow:documentWindow];
}

- (IBAction)showMacrosWindow:(id)sender{
    if ([self hasExternalGroupsSelected]) {
        BDSKMacroResolver *resolver = [(id<BDSKOwner>)[groups objectAtIndex:[groupTableView selectedRow]] macroResolver];
        MacroWindowController *controller = nil;
        NSEnumerator *wcEnum = [[self windowControllers] objectEnumerator];
        NSWindowController *wc;
        while(wc = [wcEnum nextObject]){
            if([wc isKindOfClass:[MacroWindowController class]] && [(MacroWindowController*)wc macroResolver] == resolver)
                break;
        }
        if(wc){
            controller = (MacroWindowController *)wc;
        }else{
            controller = [[MacroWindowController alloc] initWithMacroResolver:resolver];
            [self addWindowController:controller];
            [controller release];
        }
        [controller showWindow:self];
    } else {
        if (!macroWC) {
            macroWC = [[MacroWindowController alloc] initWithMacroResolver:[self macroResolver]];
        }
        if ([[self windowControllers] containsObject:macroWC] == NO) {
            [self addWindowController:macroWC];
        }
        [macroWC showWindow:self];
    }
}

#pragma mark Sharing Actions

- (IBAction)refreshSharing:(id)sender{
    [[BDSKSharingServer defaultServer] restartSharingIfNeeded];
}

- (IBAction)refreshSharedBrowsing:(id)sender{
    [[BDSKSharingBrowser sharedBrowser] restartSharedBrowsingIfNeeded];
}

#pragma mark Text import sheet support

- (IBAction)importFromPasteboardAction:(id)sender{
    
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    NSString *type = [pasteboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKReferenceMinerStringPboardType, BDSKBibItemPboardType, NSStringPboardType, nil]];
    
    if(type != nil){
        NSError *error = nil;
        BOOL isKnownFormat = YES;
		if([type isEqualToString:NSStringPboardType]){
			// sniff the string to see if we should add it directly
			NSString *pboardString = [pasteboard stringForType:type];
			isKnownFormat = ([pboardString contentStringType] != BDSKUnknownStringType);
		}
		
        if(isKnownFormat && [self addPublicationsFromPasteboard:pasteboard selectLibrary:YES error:&error] && error == nil)
            return; // it worked, so we're done here
    }
    
    BDSKTextImportController *tic = [(BDSKTextImportController *)[BDSKTextImportController alloc] initWithDocument:self];

    [tic beginSheetForPasteboardModalForWindow:documentWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	[tic release];
}

- (IBAction)importFromFileAction:(id)sender{
    BDSKTextImportController *tic = [(BDSKTextImportController *)[BDSKTextImportController alloc] initWithDocument:self];

    [tic beginSheetForFileModalForWindow:documentWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	[tic release];
}

- (IBAction)importFromWebAction:(id)sender{
    BDSKTextImportController *tic = [(BDSKTextImportController *)[BDSKTextImportController alloc] initWithDocument:self];

    [tic beginSheetForWebModalForWindow:documentWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	[tic release];
}

#pragma mark AutoFile stuff

- (void)consolidateAlertDidEnd:(BDSKAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    BOOL check = (returnCode == NSAlertDefaultReturn);
    if (returnCode == NSAlertAlternateReturn)
        return;

    // first we make sure all edits are committed
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKFinalizeChangesNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionary]];

    [[BibFiler sharedFiler] filePapers:[self selectedPublications] fromDocument:self check:check];
	
	[[self undoManager] setActionName:NSLocalizedString(@"Consolidate Files", @"Undo action name")];
}

- (IBAction)consolidateLinkedFiles:(id)sender{
    if ([self hasExternalGroupsSelected] == YES) {
        NSBeep();
        return;
    }
    BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Consolidate Linked Files", @"Message in alert dialog when consolidating files")
                                         defaultButton:NSLocalizedString(@"Move Complete Only", @"Button title")
                                       alternateButton:NSLocalizedString(@"Cancel", @"Button title")
                                           otherButton:NSLocalizedString(@"Move All", @"Button title")
                             informativeTextWithFormat:NSLocalizedString(@"This will put all files linked to the selected items in your Papers Folder, according to the format string. Do you want me to generate a new location for all linked files, or only for those for which all the bibliographical information used in the generated file name has been set?", @"Informative text in alert dialog")];
    // we need the callback in the didDismissSelector, because the sheet must be removed from the document before we call BibFiler 
    // as that will use a sheet as well, see bug # 1526145
	[alert beginSheetModalForWindow:documentWindow
                      modalDelegate:self
                     didEndSelector:NULL
                 didDismissSelector:@selector(consolidateAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:NULL];
    
}

#pragma mark Cite Keys and Crossref support

- (void)generateCiteKeysForPublications:(NSArray *)pubs{
    
    unsigned int numberOfPubs = [pubs count];
    NSEnumerator *selEnum = [pubs objectEnumerator];
    BibItem *aPub;
    NSMutableArray *arrayOfPubs = [NSMutableArray arrayWithCapacity:numberOfPubs];
    NSMutableArray *arrayOfOldValues = [NSMutableArray arrayWithCapacity:numberOfPubs];
    NSMutableArray *arrayOfNewValues = [NSMutableArray arrayWithCapacity:numberOfPubs];
    BDSKScriptHook *scriptHook = [[BDSKScriptHookManager sharedManager] makeScriptHookWithName:BDSKWillGenerateCiteKeyScriptHookName];
    
    // first we make sure all edits are committed
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKFinalizeChangesNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionary]];
    
    // put these pubs into an array, since the indices can change after we set the cite key, due to sorting or searching
    while (aPub = [selEnum nextObject]) {
        [arrayOfPubs addObject:aPub];
        if(scriptHook){
            [arrayOfOldValues addObject:[aPub citeKey]];
            [arrayOfNewValues addObject:[aPub suggestedCiteKey]];
        }
    }
    
    if (scriptHook) {
        [scriptHook setField:BDSKCiteKeyString];
        [scriptHook setOldValues:arrayOfOldValues];
        [scriptHook setNewValues:arrayOfNewValues];
        [[BDSKScriptHookManager sharedManager] runScriptHook:scriptHook forPublications:arrayOfPubs document:self];
    }
    
    scriptHook = [[BDSKScriptHookManager sharedManager] makeScriptHookWithName:BDSKDidGenerateCiteKeyScriptHookName];
    [arrayOfOldValues removeAllObjects];
    [arrayOfNewValues removeAllObjects];
    selEnum = [arrayOfPubs objectEnumerator];
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    while(aPub = [selEnum nextObject]){
        NSString *newKey = [aPub suggestedCiteKey];
        NSString *crossref = [aPub valueOfField:BDSKCrossrefString inherit:NO];
        if (crossref != nil && [crossref caseInsensitiveCompare:newKey] == NSOrderedSame) {
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Could not generate cite key",@"Message in alert dialog when failing to generate cite key") 
                                             defaultButton:nil
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"The cite key for \"%@\" could not be generated because the generated key would be the same as the crossref key.", @"Informative text in alert dialog"), [aPub citeKey]];
            [alert beginSheetModalForWindow:documentWindow
                              modalDelegate:nil
                             didEndSelector:NULL
                                contextInfo:NULL];
            continue;
        }
        [aPub setCiteKey:newKey];
        
        if(scriptHook){
            [arrayOfOldValues addObject:[aPub citeKey]];
            [arrayOfNewValues addObject:newKey];
        }
        
        [pool release];
        pool = [[NSAutoreleasePool alloc] init];
    }
    
    // should be safe to release here since arrays were created outside the scope of this local pool
    [pool release];
    
    if (scriptHook) {
        [scriptHook setField:BDSKCiteKeyString];
        [scriptHook setOldValues:arrayOfOldValues];
        [scriptHook setNewValues:arrayOfNewValues];
        [[BDSKScriptHookManager sharedManager] runScriptHook:scriptHook forPublications:arrayOfPubs document:self];
    }
    
    [[self undoManager] setActionName:(numberOfPubs > 1 ? NSLocalizedString(@"Generate Cite Keys", @"Undo action name") : NSLocalizedString(@"Generate Cite Key", @"Undo action name"))];
}    

- (void)generateCiteKeyAlertDidEnd:(BDSKAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if([alert checkValue] == YES)
		[[OFPreferenceWrapper sharedPreferenceWrapper] setBool:NO forKey:BDSKWarnOnCiteKeyChangeKey];
    
    if(returnCode == NSAlertDefaultReturn)
        [self generateCiteKeysForPublications:[self selectedPublications]];
}

- (IBAction)generateCiteKey:(id)sender
{
    unsigned int numberOfSelectedPubs = [self numberOfSelectedPubs];
	if (numberOfSelectedPubs == 0 ||
        [self hasExternalGroupsSelected] == YES) return;
    
    if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKWarnOnCiteKeyChangeKey]){
        NSString *alertTitle = numberOfSelectedPubs > 1 ? NSLocalizedString(@"Really Generate Cite Keys?", @"Message in alert dialog when generating cite keys") : NSLocalizedString(@"Really Generate Cite Key?", @"Message in alert dialog when generating cite keys");
        NSString *message = numberOfSelectedPubs > 1 ? [NSString stringWithFormat:NSLocalizedString(@"This action will generate cite keys for %d publications.  This action is undoable.", @"Informative text in alert dialog"), numberOfSelectedPubs] : NSLocalizedString(@"This action will generate a cite key for the selected publication.  This action is undoable.", @"Informative text in alert dialog");
        BDSKAlert *alert = [BDSKAlert alertWithMessageText:alertTitle
                                             defaultButton:NSLocalizedString(@"Generate", @"Button title")
                                           alternateButton:NSLocalizedString(@"Cancel", @"Button title") 
                                               otherButton:nil
                                 informativeTextWithFormat:message];
        [alert setHasCheckButton:YES];
        [alert setCheckValue:NO];
        [alert beginSheetModalForWindow:documentWindow 
                          modalDelegate:self 
                         didEndSelector:@selector(generateCiteKeyAlertDidEnd:returnCode:contextInfo:) 
                            contextInfo:NULL];
    } else {
        [self generateCiteKeysForPublications:[self selectedPublications]];
    }
}

- (void)performSortForCrossrefs{
    NSArray *copyOfPubs = [[NSArray alloc] initWithArray:publications];
	NSEnumerator *pubEnum = [copyOfPubs objectEnumerator];
	BibItem *pub = nil;
	BibItem *parent;
	NSString *key;
	NSMutableSet *prevKeys = [NSMutableSet set];
	BOOL moved = NO;
	NSArray *selectedPubs = [self selectedPublications];
    
    [copyOfPubs release];
	
	// We only move parents that come before a child.
	while (pub = [pubEnum nextObject]){
		key = [[pub valueOfField:BDSKCrossrefString inherit:NO] lowercaseString];
		if (![NSString isEmptyString:key] && [prevKeys containsObject:key]) {
            [prevKeys removeObject:key];
			parent = [publications itemForCiteKey:key];
			[publications removeObjectIdenticalTo:parent];
			[publications addObject:parent];
			moved = YES;
		}
		[prevKeys addObject:[[pub citeKey] lowercaseString]];
	}
	
	if (moved) {
		[self sortPubsByKey:nil];
		[self selectPublications:selectedPubs];
		[self setStatus:NSLocalizedString(@"Publications sorted for cross references.", @"Status message")];
	}
}

- (IBAction)sortForCrossrefs:(id)sender{
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] setPublications:publications];
	[undoManager setActionName:NSLocalizedString(@"Sort Publications", @"Undo action name")];
	
	[self performSortForCrossrefs];
}

- (void)selectCrossrefParentForItem:(BibItem *)item{
    BibItem *parent = [item crossrefParent];
    if(parent){
        [tableView deselectAll:nil];
        [self selectPublication:parent];
        [tableView scrollRowToCenter:[tableView selectedRow]];
    } else
        NSBeep(); // if no parent found
}

- (IBAction)selectCrossrefParentAction:(id)sender{
    BibItem *selectedBI = [[self selectedPublications] lastObject];
    [self selectCrossrefParentForItem:selectedBI];
}

- (void)dublicateTitleToBooktitleAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	BOOL overwrite = (returnCode == NSAlertAlternateReturn);
	
	NSSet *parentTypes = [NSSet setWithArray:[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKTypesForDuplicateBooktitleKey]];
	NSEnumerator *selEnum = [[self selectedPublications] objectEnumerator];
	BibItem *aPub;
	
    // first we make sure all edits are committed
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKFinalizeChangesNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionary]];
	
	while (aPub = [selEnum nextObject]) {
		if([parentTypes containsObject:[aPub pubType]])
			[aPub duplicateTitleToBooktitleOverwriting:overwrite];
	}
	[[self undoManager] setActionName:([self numberOfSelectedPubs] > 1 ? NSLocalizedString(@"Duplicate Titles", @"Undo action name") : NSLocalizedString(@"Duplicate Title", @"Undo action name"))];
}

- (IBAction)duplicateTitleToBooktitle:(id)sender{
	if ([self numberOfSelectedPubs] == 0 ||
        [self hasExternalGroupsSelected] == YES) return;
	
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Overwrite Booktitle?", @"Message in alert dialog when duplicating Title to Booktitle")
                                     defaultButton:NSLocalizedString(@"Don't Overwrite", @"Button title: overwrite Booktitle")
                                   alternateButton:NSLocalizedString(@"Overwrite", @"Button title: don't overwrite Booktitle")
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"Do you want me to overwrite the Booktitle field when it was already entered?", @"Informative text in alert dialog")];
	[alert beginSheetModalForWindow:documentWindow
                      modalDelegate:self
                     didEndSelector:@selector(dublicateTitleToBooktitleAlertDidEnd:returnCode:contextInfo:) 
                        contextInfo:NULL];
}

#pragma mark Duplicate and Incomplete searching

// select duplicates, then allow user to delete/copy/whatever
- (IBAction)selectPossibleDuplicates:(id)sender{
    
	[self setSearchString:@""]; // make sure we can see everything
    
    [documentWindow makeFirstResponder:tableView]; // make sure tableview has the focus
    
    CFIndex index = [shownPublications count];
    id object1 = nil, object2 = nil;
    
    OBASSERT(sortKey);
    
    NSMutableIndexSet *rowsToSelect = [NSMutableIndexSet indexSet];
    CFIndex countOfItems = 0;
    BOOL isURL = [sortKey isURLField];
    
    // Compare objects in the currently sorted table column using the isEqual: method to test adjacent cells in order to check for duplicates based on a specific sort key.  BibTool does this, but its effectiveness is obviously limited by the key used <http://lml.ls.fi.upm.es/manuales/bibtool/m_2_11_1.html>.
    while(index--){
        object1 = object2;
        object2 = isURL ? [[shownPublications objectAtIndex:index] valueOfField:sortKey] : [[shownPublications objectAtIndex:index] displayValueOfField:sortKey];
        if([object1 isEqual:object2]){
            [rowsToSelect addIndexesInRange:NSMakeRange(index, 2)];
            countOfItems++;
        }
    }
    
    if(countOfItems){
        [tableView selectRowIndexes:rowsToSelect byExtendingSelection:NO];
        [tableView scrollRowToCenter:[rowsToSelect firstIndex]];  // make sure at least one item is visible
    }else
        NSBeep();
    
	NSString *pubSingularPlural = (countOfItems == 1) ? NSLocalizedString(@"publication", @"publication, in status message") : NSLocalizedString(@"publications", @"publications, in status message");
    // update status line after the updateStatus notification, or else it gets overwritten
    [self setStatus:[NSString stringWithFormat:NSLocalizedString(@"%i duplicate %@ found.", @"Status message: [number] duplicate publication(s) found"), countOfItems, pubSingularPlural]];
}

// select duplicates, then allow user to delete/copy/whatever
- (IBAction)selectDuplicates:(id)sender{
    
	[self setSearchString:@""]; // make sure we can see everything
    
    [documentWindow makeFirstResponder:tableView]; // make sure tableview has the focus
    
    NSMutableArray *pubsToRemove = nil;
    NSZone *zone = [self zone];
    CFIndex countOfItems = 0;
    BibItem **pubs;
    
    if ([self hasExternalGroupsSelected]) {
        countOfItems = [publications count];
        pubs = (BibItem **)NSZoneMalloc(zone, sizeof(BibItem *) * countOfItems);
        [publications getObjects:pubs];
        pubsToRemove = [[NSMutableArray alloc] initWithArray:groupedPublications];
    } else {
        pubsToRemove = [[NSMutableArray alloc] initWithArray:publications];
        countOfItems = [publications count];
        pubs = (BibItem **)NSZoneMalloc(zone, sizeof(BibItem *) * countOfItems);
        [pubsToRemove getObjects:pubs];
        
        // Tests equality based on standard fields (high probability that these will be duplicates)
        countOfItems = [pubsToRemove count];
        NSSet *uniquePubs = (NSSet *)CFSetCreate(CFAllocatorGetDefault(), (const void **)pubs, countOfItems, &BDSKBibItemEqualityCallBacks);
        [pubsToRemove removeIdenticalObjectsFromArray:[uniquePubs allObjects]]; // remove all unique ones based on pointer equality
        [uniquePubs release];
        
        // original buffer should be large enough, since we've only removed items from pubsToRemove
        countOfItems = [pubsToRemove count];
        [pubsToRemove getObjects:pubs];
        [pubsToRemove setArray:publications];
    }
    
    NSSet *removeSet = (NSSet *)CFSetCreate(CFAllocatorGetDefault(), (const void **)pubs, countOfItems, &BDSKBibItemEqualityCallBacks);
    NSZoneFree(zone, pubs);
    
    CFIndex idx = [pubsToRemove count];
    
    while(idx--){
        if([removeSet containsObject:[pubsToRemove objectAtIndex:idx]] == NO)
            [pubsToRemove removeObjectAtIndex:idx];
    }
    
    [removeSet release];
	[self selectPublications:pubsToRemove];
    [pubsToRemove release];

    if(countOfItems)
        [tableView scrollRowToCenter:[tableView selectedRow]];  // make sure at least one item is visible
    else
        NSBeep();
    
	NSString *pubSingularPlural = (countOfItems == 1) ? NSLocalizedString(@"publication", @"publication, in status message") : NSLocalizedString(@"publications", @"publications, in status message");
    [self setStatus:[NSString stringWithFormat:NSLocalizedString(@"%i duplicate %@ found.", @"Status message: [number] duplicate publication(s) found"), countOfItems, pubSingularPlural]];
}

- (IBAction)selectIncompletePublications:(id)sender{
	[self setSearchString:@""]; // make sure we can see everything
    
    [documentWindow makeFirstResponder:tableView]; // make sure tableview has the focus
    
    CFIndex i, index = [shownPublications count], countOfItems = 0;
    BibItem *pub;
    NSMutableIndexSet *rowsToSelect = [NSMutableIndexSet indexSet];
    BibTypeManager *typeman = [BibTypeManager sharedManager];
    NSArray *reqFields;
    
    while(index--){
        pub = [shownPublications objectAtIndex:index];
        reqFields = [typeman requiredFieldsForType:[pub pubType]];
        i = [reqFields count];
        while(i--){
            if([NSString isEmptyString:[pub valueOfField:[reqFields objectAtIndex:i]]]){
                [rowsToSelect addIndex:index];
                countOfItems++;
                break;
            }
        }
    }
    
    if(countOfItems){
        [tableView selectRowIndexes:rowsToSelect byExtendingSelection:NO];
        [tableView scrollRowToCenter:[rowsToSelect firstIndex]];  // make sure at least one item is visible
    }else
        NSBeep();
    
	NSString *pubSingularPlural = (countOfItems == 1) ? NSLocalizedString(@"publication", @"publication, in status message") : NSLocalizedString(@"publications", @"publications, in status message");
    [self setStatus:[NSString stringWithFormat:NSLocalizedString(@"%i incomplete %@ found.", @"Status message: [number] incomplete publication(s) found"), countOfItems, pubSingularPlural]];
}

@end
