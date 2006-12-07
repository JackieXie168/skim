//
//  BibEditor.m
//  Bibdesk
//
//  Created by Michael McCracken on Mon Dec 24 2001.
//  Copyright (c) 2001 Michael McCracken. All rights reserved.
//


#import "BibEditor.h"
#import "BibDocument.h"
#import <OmniAppKit/NSScrollView-OAExtensions.h>


NSString *BDSKAnnoteString = @"Annote";
NSString *BDSKAbstractString = @"Abstract";
NSString *BDSKRssDescriptionString = @"Rss-Description";
NSString *BDSKLocalUrlString = @"Local-Url";
NSString *BDSKUrlString = @"Url";

@implementation BibEditor

- (NSString *)windowNibName{
    return @"BibEditor";
}


- (id)initWithBibItem:(BibItem *)aBib andBibDocument:(BibDocument *)aDoc{
    self = [super initWithWindowNibName:@"BibEditor"];
    fieldNumbers = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
    citeKeyFormatter = [[BDSKCiteKeyFormatter alloc] init];
    
    theBib = aBib;
    [theBib setEditorObj:self];
    theDoc = aDoc; // don't retain - it owns us.
    currentType = [theBib type];    // do this once in init so it's right at the start.
                                    // has to be before we call [self window] because that calls windowDidLoad:.
    // this should probably be moved around.
    [[self window] setTitle:[theBib title]];
    [[self window] setDelegate:self];
    [[self window] registerForDraggedTypes:[NSArray arrayWithObjects:
            NSStringPboardType, NSFilenamesPboardType, nil]];

#if DEBUG
    NSLog(@"BibEditor alloc");
#endif
    needsRefresh = YES;
    changeCount = 0;
    return self;
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification{
    // read the data and initialize the tmpBib.
    // this is in windowDidBecomeMain because it has to be re-done
    // in case we are reopening the window after a cancel.
    if(needsRefresh){
        if(tmpBib) [tmpBib release];
        tmpBib = [theBib copy];
        currentType = [tmpBib type];
        [tmpBib setEditorObj:self];
        [citeKeyField setStringValue:[tmpBib citeKey]];
        [self setupForm];
        [notesView setString:[tmpBib valueOfField:BDSKAnnoteString]];
        [abstractView setString:[tmpBib valueOfField:BDSKAbstractString]];
        [rssDescriptionView setString:[tmpBib valueOfField:BDSKRssDescriptionString]];
        [[self window] setTitle:[theBib title]];
        // [[self window] setDocumentEdited:NO];
        [self fixURLs];
    }
    needsRefresh = NO;
}

- (BibItem *)currentBib{
    return tmpBib;
}

- (void)setupForm{
    NSString *tmp;
    NSFormCell *entry;
    NSArray *sKeys;
    NSFont *requiredFont = [NSFont labelFontOfSize:12.0];
    int i=0;
    int numRows;
    NSRect rect = [bibFields frame];
    NSPoint origin = rect.origin;

    NSDictionary *reqAtt = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSColor redColor],nil]
                                                       forKeys:[NSArray arrayWithObjects:NSForegroundColorAttributeName,nil]];

    
    [[NSFontManager sharedFontManager] convertFont:requiredFont
                                       toHaveTrait:NSBoldFontMask];
    // set up for adding all items 
    // remove all items in the NSForm (NSForm doesn't have a removeAllEntries.)
    numRows = [bibFields numberOfRows];
    for(i=0;i < numRows; i++){
        [bibFields removeEntryAtIndex:0]; // it shifts indices every time so we have to pop them.
    }

    // make two passes to get the required entries at top.
    // there's got to be a better way to do this but i was lazy when i wrote this.
    i=0;
    sKeys = [[[tmpBib dict] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    e = [sKeys objectEnumerator];
    while(tmp = [e nextObject]){
        if ([tmpBib isRequired:tmp] &&
            ![tmp isEqualToString:BDSKAnnoteString] && 
            ![tmp isEqualToString:BDSKAbstractString] &&
            ![tmp isEqualToString:BDSKRssDescriptionString]){
            
            entry = [bibFields insertEntry:tmp atIndex:i];
            [entry setTarget:self];
            [entry setAction:@selector(textFieldDidEndEditing:)];
            [entry setTag:i];
            [entry setObjectValue:[tmpBib valueOfField:tmp]];
            [entry setTitleFont:requiredFont];
            [entry setAttributedTitle:[[[NSAttributedString alloc] initWithString:tmp
                                                                       attributes:reqAtt] autorelease]];
//            [entry setFormatter:[[NSApp delegate] formatterForEntry:tmp]];
            //[entry setTitleAlignment:NSRightTextAlignment]; this doesn't work...
            i++;
        }
    }

    e = [sKeys objectEnumerator];
    while(tmp = [e nextObject]){
        if(![tmpBib isRequired:tmp] &&
           ![tmp isEqualToString:BDSKAnnoteString] &&
           ![tmp isEqualToString:BDSKAbstractString] &&
           ![tmp isEqualToString:BDSKRssDescriptionString]){
            
            entry = [bibFields insertEntry:tmp atIndex:i];
            [entry setTarget:self];
            [entry setAction:@selector(textFieldDidEndEditing:)];
            [entry setTag:i];
            [entry setObjectValue:[tmpBib valueOfField:tmp]];
            [entry setTitleAlignment:NSLeftTextAlignment];
//            [entry setFormatter:[[NSApp delegate] formatterForEntry:tmp]];
            i++;
        }
    }
    [bibFields sizeToFit];
    
    [bibFields setFrameOrigin:origin];
    [bibFields setNeedsDisplay:YES];
}

- (void)awakeFromNib{

    [citeKeyField setFormatter:citeKeyFormatter];
    // This is here because I don't know how to make an empty popupbutton in IB.
    [bibTypeButton removeAllItems];

    // Now we add items. The indexes are the enum values we'll use later to set the selected item.
    // Using them here guarantees that we'll have the right values later.
    // ?? Bad comment?? - because we don't know what index they'll be put at if we don't explicitly change them...
    [bibTypeButton insertItemWithTitle: @"Article" atIndex: ARTICLE];
    [bibTypeButton insertItemWithTitle: @"Book" atIndex: BOOK];
    [bibTypeButton insertItemWithTitle: @"Booklet" atIndex: BOOKLET];
    [bibTypeButton insertItemWithTitle: @"InBook" atIndex: INBOOK];
    [bibTypeButton insertItemWithTitle: @"InCollection" atIndex: INCOLLECTION];
    [bibTypeButton insertItemWithTitle: @"InProceedings" atIndex: INPROCEEDINGS];
    [bibTypeButton insertItemWithTitle: @"Manual" atIndex: MANUAL];
    [bibTypeButton insertItemWithTitle: @"Mastersthesis" atIndex: MASTERSTHESIS];
    [bibTypeButton insertItemWithTitle: @"Misc" atIndex: MISC];
    [bibTypeButton insertItemWithTitle: @"PhdThesis" atIndex: PHDTHESIS];
    [bibTypeButton insertItemWithTitle: @"Proceedings" atIndex: PROCEEDINGS];
    [bibTypeButton insertItemWithTitle: @"Techreport" atIndex: TECHREPORT];
    [bibTypeButton insertItemWithTitle: @"Unpublished" atIndex: UNPUBLISHED];
    [bibTypeButton selectItemAtIndex: currentType];
    [self setupForm];
}

- (void)dealloc{
#if DEBUG
    NSLog(@"BibEditor dealloc");
#endif
    if(tmpBib)[tmpBib release];
    [citeKeyFormatter release];
    [super dealloc];
}

- (void)show{
    [self showWindow:self];
}

- (void)windowWillLoad{
#warning - hack seems like i should do it a better way.
#warning   Use a notification instead.
    // use this to make form show up right away when dragging in while bd is in background.
    // needsRefresh = YES;
    //[self windowDidBecomeMain:nil]; // OK for now because we don't use the notification in windowDidBecomeMain.
    //  NSLog(@"windowwillload");
    // i think at least it's better than the way we did it before: this messed up the changeCount
    //    [self bibTypeDidChange:self];
}
     
// NOTE FIXME revert and cancel need to change the fields too... ?
- (IBAction)revert:(id)sender{
    //kill changes by making the temp bib a copy of the original bib and keep the window open
    // (ADD Alert Window) to check if the user is sure.
    [tmpBib release];
    tmpBib = [theBib copy];
    currentType = [tmpBib type];
    [tmpBib setEditorObj:self];
    [self setupForm];
    [notesView setString:[tmpBib valueOfField:BDSKAnnoteString]];
    [abstractView setString:[tmpBib valueOfField:BDSKAbstractString]];
    [rssDescriptionView setString:[tmpBib valueOfField:BDSKRssDescriptionString]];
    [bibTypeButton selectItemAtIndex: currentType];
}

- (IBAction)saveDocument:(id)sender{
    if ([[self window] makeFirstResponder:[self window]]) {
        /* All fields are now valid; it's safe to use fieldEditor:forObject:
        to claim the field editor. */
    }
    else {
        /* Force first responder to resign. */
        [[self window] endEditingFor:nil];
    }

    [theBib setFields:[tmpBib dict]]; // Set fields handles some metadata updating.
    [theBib setType:[tmpBib type]];
    [theBib setCiteKey:[tmpBib citeKey]];
    [theDoc updateChangeCount:NSChangeDone];
    [theDoc controlTextDidChange:nil];
    [self updateChangeCount:NSChangeCleared];
    [theDoc highlightBib:theBib];
    // no close for the menu item.
}

- (IBAction)save:(id)sender{
    // a safety call to be sure that the current field's changes are saved :...
    [self textFieldDidEndEditing:bibFields];
    [self citeKeyDidChange:citeKeyField];
    /* can't use a sheet within a sheet: find a better way
    if([[tmpBib valueOfField:@"Title"] isEqualToString:@""]){
        NSBeginCriticalAlertSheet(@"The Title Field is Required.",
                                  nil,nil,nil,
                                  [self window],self,
                                  NULL, NULL,[self window],
                                  @"If you have already entered a title, be sure to confirm your change by pressing Enter.",nil
                          );
        return;
    }*/
    // FIXME: Only do this if we did change something...
    if ([bibFields indexOfSelectedItem] != -1) {
        [self textFieldDidEndEditing:bibFields];
    }
    [theBib setFields:[tmpBib dict]]; // Set fields handles some metadata updating.
    [theBib setType:[tmpBib type]];
    [theBib setCiteKey:[tmpBib citeKey]];
    [self updateChangeCount:NSChangeCleared];
    [self close];
    [theDoc updateChangeCount:NSChangeDone];
    [theDoc controlTextDidChange:nil]; // so we catch new bibs into shownPubs (this calls updateUI also)

    //  note that needsRefresh should be set to NO after a save. it always will, though, so we don't bother.
}

- (IBAction)cancel:(id)sender{
    //Just close the window - we will re read the info if we need to reopen.
    // (ADD Alert Window) to check if user is sure.?
    [self close];
    needsRefresh = YES;
    [tmpBib release]; // need to do this because windowWillLoad creates a new one.
    tmpBib = nil;     // need to do this because windowWillLoad doesn't get called as soon as we'd like
    [self updateChangeCount:NSChangeCleared];
    [theDoc updateChangeCount:NSChangeUndone]; // testing this now

    [theDoc controlTextDidChange:nil];
}

- (IBAction)viewLocal:(id)sender{
    NSWorkspace *sw = [NSWorkspace sharedWorkspace];
    NSString *lurl = [tmpBib valueOfField:BDSKLocalUrlString];
#warning - want to change this to use fileURLWIthPath?
    if (![@"" isEqualToString:lurl]) {
        [sw openURL:[NSURL URLWithString:[lurl stringByExpandingTildeInPath]]];
    }
}

- (IBAction)viewRemote:(id)sender{
    NSWorkspace *sw = [NSWorkspace sharedWorkspace];
    NSString *rurl = [tmpBib valueOfField:BDSKUrlString];
    if ([@"" caseInsensitiveCompare:rurl] != NSOrderedSame) {
        [sw openURL:[NSURL URLWithString:rurl]];
    }
}

- (IBAction)citeKeyDidChange:(id)sender{
    if(tmpBib){
        [tmpBib setCiteKey:[sender stringValue]];
        if(![tmpBib isEqual: theBib]){
            [self updateChangeCount:NSChangeDone];
            [theDoc updateChangeCount:NSChangeDone];
        }
        //[self fixEditedStatus];
    }        
}

// sent by the notesView and the abstractView
- (void)textDidChange:(NSNotification *)aNotification{
    if([aNotification object] == notesView){
        [tmpBib setField:BDSKAnnoteString toValue:[[notesView string] copy]];
    }
    else if([aNotification object] == abstractView){
        [tmpBib setField:BDSKAbstractString toValue:[[abstractView string] copy]];
    }
    else if([aNotification object] == rssDescriptionView){
        // NSLog(@"setting rssdesc to %@", [rssDescriptionView string]);
        [tmpBib setField:BDSKRssDescriptionString toValue:[[rssDescriptionView string] copy]];
    }

    [self updateChangeCount:NSChangeDone];
    [theDoc updateChangeCount:NSChangeDone];

    //[self fixEditedStatus];
}

- (IBAction)bibTypeDidChange:(id)sender{
    // we can use indexOfSelectedItem because we guarantee there is always a selected item.
    currentType = [bibTypeButton indexOfSelectedItem];
    if([tmpBib type] != currentType){
        [tmpBib makeType:currentType];
        [self setupForm];
        [self updateChangeCount:NSChangeDone];
        [theDoc updateChangeCount:NSChangeDone];
        [[OFPreferenceWrapper sharedPreferenceWrapper] setInteger:currentType
                                                           forKey:BDSKPubTypeKey];
        //[self fixEditedStatus];
    }
}

- (void)fixURLs{
    NSString *lurl = [tmpBib valueOfField:BDSKLocalUrlString];
    NSString *rurl = [tmpBib valueOfField:BDSKUrlString];
    NSImage *icon;
    NSURL *local;
    NSURL *remote = [NSURL URLWithString:rurl];
    NSDictionary *linkAttributes;
    NSMutableAttributedString *link = [[NSMutableAttributedString alloc] initWithString:rurl];
    NSImage *snoopImage;

    BOOL drawerWasOpen = ([documentSnoopDrawer state] == NSDrawerOpenState);
    BOOL drawerIsOpening = ([documentSnoopDrawer state] == NSDrawerOpeningState);

    if(drawerWasOpen) [documentSnoopDrawer close];
    //local is either a file:// URL -or a path
    if(![@"" isEqualToString:lurl]){
        local = [NSURL fileURLWithPath:[lurl stringByExpandingTildeInPath]];
    }else{
        local = nil;
    }

    if (local && [[NSFileManager defaultManager] fileExistsAtPath:[lurl stringByExpandingTildeInPath]]){
            icon = [[NSWorkspace sharedWorkspace] iconForFile:
                [local path]];
            [viewLocalButton setImage:icon];
            [viewLocalButton setEnabled:YES];
            [viewLocalButton setToolTip:@"View File"];
            [viewLocalButton setTitle:@""];

            if(drawerWasOpen || drawerIsOpening){
                snoopImage = [[[NSImage alloc] initWithContentsOfFile:[local path]] autorelease];
#if DEBUG
                NSLog(@"setting snoop to %@ from file %@", snoopImage, lurl);
#endif
                if(snoopImage){
                    [documentSnoopImageView setImage:snoopImage];
                    [snoopImage setBackgroundColor:[NSColor whiteColor]];
                    [documentSnoopButton setEnabled:YES];
                    [documentSnoopButton setToolTip:NSLocalizedString(@"Show first page in a drawer.", @"show first page in a drawer")];
                    [documentSnoopScrollView setDocumentViewAlignment:NSImageAlignTopLeft];
                    if(drawerWasOpen) // open it again.
                        [documentSnoopDrawer open];
                    
                }
            }
    }else{
        [viewLocalButton setEnabled:NO];
        [viewLocalButton setImage:nil];
        [viewLocalButton setTitle:NSLocalizedString(@"No\nFile.", @"No file, make sure it fits in the icon")];
        [viewLocalButton setToolTip:NSLocalizedString(@"Bad or Empty Local-Url Field", @"bad/empty local url field")];

        [documentSnoopButton setEnabled:NO];
        [documentSnoopButton setToolTip:NSLocalizedString(@"Bad or Empty Local-Url Field", @"bad/empty local field")];
    }

    if(remote && ![rurl isEqualToString:@""]){
        linkAttributes= [NSDictionary dictionaryWithObjectsAndKeys: rurl, NSLinkAttributeName,
            [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName,
            [NSColor blueColor], NSForegroundColorAttributeName,
            NULL];
        [link setAttributes:linkAttributes range:NSMakeRange(0,[rurl length])];
        [viewRemoteButton setAttributedTitle:link];     // set the URL field
        [viewRemoteButton setEnabled:YES];
        [viewRemoteButton setToolTip:NSLocalizedString(@"View in web browser", @"")];
    }else{
        [viewRemoteButton setTitle:rurl];
        [viewRemoteButton setEnabled:NO];
        [viewRemoteButton setToolTip:NSLocalizedString(@"Bad or Empty Url Field", @"")];
    }

    [link release];
}

- (void)fixEditedStatus{
    if(changeCount != 0){
        [[self window] setDocumentEdited:YES];
        [theDoc updateChangeCount:NSChangeDone];
    }else{
        [[self window] setDocumentEdited:NO];
        if([theDoc isDocumentEdited])// if this isn't a bug, at least it's undocumented
            [theDoc updateChangeCount:NSChangeUndone];
    }
}

- (void)updateChangeCount:(NSDocumentChangeType)changeType{
    switch(changeType){
        case NSChangeDone: changeCount++;
            break;
        case NSChangeUndone: changeCount--;
            break;
        case NSChangeCleared: changeCount = 0;
            break;
    }
    if(changeCount != 0){
        [[self window] setDocumentEdited:YES];
    }else{
        [[self window] setDocumentEdited:NO];
    }
}

- (BOOL)isEdited{
    return (changeCount != 0);
}

// ----------------------------------------------------------------------------------------
#pragma mark ||  add-Field-Sheet Support
// Add field sheet support
// ----------------------------------------------------------------------------------------

// raises the add field sheet
- (IBAction)raiseAddField:(id)sender{
    [newFieldName setStringValue:@""];
    [NSApp beginSheet:newFieldWindow
       modalForWindow:[self window]
        modalDelegate:self
       didEndSelector:@selector(addFieldSheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
}
//dismisses it
- (IBAction)dismissAddField:(id)sender{
    [newFieldWindow orderOut:sender];
    [NSApp endSheet:newFieldWindow returnCode:[sender tag]];
}

// tag, and hence return code is 0 for OK and 1 for cancel.
// called upon dismissal
- (void)addFieldSheetDidEnd:(NSWindow *)sheet
                 returnCode:(int) returnCode
                contextInfo:(void *)contextInfo{
    if(returnCode == 0){
        if(![[[tmpBib dict] allKeys] containsObject:[newFieldName stringValue]]){
            [tmpBib setField:[newFieldName stringValue] toValue:@""];
            [self setupForm];
            [self updateChangeCount:NSChangeDone];
            [theDoc updateChangeCount:NSChangeDone];
            //[self fixEditedStatus];
        }
    }
    // else, nothing.
}

// ----------------------------------------------------------------------------------------
#pragma mark ||  delete-Field-Sheet Support
// delete- field -sheet support
// ----------------------------------------------------------------------------------------

// raises the del field sheet
- (IBAction)raiseDelField:(id)sender{
    // populate the popupbutton
    NSEnumerator *keyE = [[[[tmpBib dict] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]objectEnumerator];
    NSString *k;
    [delFieldPopUp removeAllItems];
    while(k = [keyE nextObject]){
        if(![k isEqualToString:BDSKAnnoteString] &&
           ![k isEqualToString:BDSKAbstractString] &&
           ![k isEqualToString:BDSKRssDescriptionString])
            [delFieldPopUp addItemWithTitle:k];
    }
    [delFieldPopUp selectItemAtIndex:0];
    [NSApp beginSheet:delFieldWindow
       modalForWindow:[self window]
        modalDelegate:self
       didEndSelector:@selector(delFieldSheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
}
//dismisses it
- (IBAction)dismissDelField:(id)sender{
    [delFieldWindow orderOut:sender];
    [NSApp endSheet:delFieldWindow returnCode:[sender tag]];
}

// tag, and hence return code is 0 for delete and 1 for cancel.
// called upon dismissal
- (void)delFieldSheetDidEnd:(NSWindow *)sheet
                 returnCode:(int) returnCode
                contextInfo:(void *)contextInfo{
    if(returnCode == 0){

        [tmpBib removeField:[delFieldPopUp titleOfSelectedItem]];
        [self setupForm];
        [self updateChangeCount:NSChangeDone];
        [theDoc updateChangeCount:NSChangeDone];
    }
    // else, nothing.
}
- (void)controlTextDidBeginEditing:(NSNotification *)aNotification{
//    id fieldEditor = [[aNotification userInfo] objectForKey:@"NSFieldEditor"];
//    NSUndoManager *undoManager = [theDoc undoManager];
    id cell = [aNotification object];
 //   [undoManager registerUndoWithTarget:cell
  //                             selector:@selector(setStringValue:)
   //                              object:[cell stringValue]];
    //[undoManager setActionName:NSLocalizedString(@"Edit Cell",@"")];
    
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification{
}

// This does nothing right now because I can't seem to get a notification about changes in an nsformcell
- (IBAction)controlTextDidChange:(NSNotification *)notification{
    NSForm *form = [notification object];
    NSCell *sel = [form cellAtIndex: [form indexOfSelectedItem]];
    NSString *title = [sel title];
#if DEBUG
    NSLog(@"controlTextDidChange -  %@", [notification object]);
#endif
}

#warning - why does this sometimes get called with no tmpBib?
// I know the answer - it gets called before windowWillLoad... but why?!
// sent by the NSForm
- (IBAction)textFieldDidEndEditing:(id)sender{
    NSCell *sel = [sender cellAtIndex: [sender indexOfSelectedItem]];
    NSString *title = [sel title];
    if(tmpBib && [sender indexOfSelectedItem] != -1){
        [tmpBib setField:title toValue:[sel stringValue]];
        if([title isEqualToString:BDSKUrlString] || [title isEqualToString:BDSKLocalUrlString]){
            [self fixURLs];
        }
        if([title isEqualToString:@"Title"]){
            [[self window] setTitle:[sel stringValue]];
        }
        if(![[theBib dict] isEqual:[tmpBib dict]]){
            [self updateChangeCount:NSChangeDone];
            [theDoc updateChangeCount:NSChangeDone];
        }
        //        [self fixEditedStatus];
    }
}

#pragma mark ||  drawer delegate stuff

- (void)drawerWillOpen:(NSNotification *)notification{
    [self fixURLs]; //no this won't cause a loop - see fixURLs. Please don't break that though. Boy it's fragile.
    [documentSnoopButton setToolTip:NSLocalizedString(@"Close drawer", @"")];
}


- (void)drawerWillClose:(NSNotification *)notification{
    [documentSnoopButton setToolTip:NSLocalizedString(@"Show the first page in a drawer.", @"")];
}

- (void)windowWillClose:(NSNotification *)notification{

    [documentSnoopDrawer close];
}

#pragma mark ||  edited status support
- (BOOL)windowShouldClose:(id)sender{
    if ([[self window] makeFirstResponder:[self window]]) {
        /* All fields are now valid; it's safe to use fieldEditor:forObject:
        to claim the field editor. */
    }
    else {
        /* Force first responder to resign. */
        [[self window] endEditingFor:nil];
    }
    //[self fixEditedStatus]; - endEditingFor in the line above will cause all relevant messages to be sent. don't need this.
    if([[self window] isDocumentEdited]){
        NSBeginAlertSheet(@"Do you want to save changes to this publication before closing?",    // title
                          @"Save",    // default button
                          @"Cancel",    // alt. button
                          @"Don't Save",    // other button
                          sender,    // the window
                          self,    // modal delegate
                          @selector(closeSheetDidEnd:returnCode:contextInfo:), nil, nil,
                          @"If you don't save, your changes will be lost.", nil);
    }
    return ![[self window] isDocumentEdited];
}

- (void)closeSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo{
    if(returnCode == NSAlertDefaultReturn){
        [self save:nil];
    }
    else if(returnCode == NSAlertAlternateReturn){
        // do nothing...
    }
    else if(returnCode == NSAlertOtherReturn){
        [self cancel:nil];
    }
}

@end
