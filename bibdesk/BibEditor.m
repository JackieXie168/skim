//  BibEditor.m

//  Created by Michael McCracken on Mon Dec 24 2001.
//  Copyright (c) 2001 Michael McCracken. All rights reserved.
/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


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
    fieldNameFormatter = [[BDSKFieldNameFormatter alloc] init];
    
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
    changeCount = 0;
    return self;
}
- (void)windowWillLoad{
    [theBib setEditorObj:self];
    [citeKeyField setStringValue:[theBib citeKey]];
    [self setupForm];
    [notesView setString:[theBib valueOfField:BDSKAnnoteString]];
    [abstractView setString:[theBib valueOfField:BDSKAbstractString]];
    [rssDescriptionView setString:[theBib valueOfField:BDSKRssDescriptionString]];
    [self fixURLs];
    NSLog(@"BibEditor gets willLoad.");
}


- (BibItem *)currentBib{
    return theBib;
}

- (void)setupForm{
    BibAppController *appController = (BibAppController *)[NSApp delegate];
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
    sKeys = [[[theBib dict] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    e = [sKeys objectEnumerator];
    while(tmp = [e nextObject]){
        if ([theBib isRequired:tmp] &&
            ![tmp isEqualToString:BDSKAnnoteString] && 
            ![tmp isEqualToString:BDSKAbstractString] &&
            ![tmp isEqualToString:BDSKRssDescriptionString]){
            
            entry = [bibFields insertEntry:tmp atIndex:i];
            [entry setTarget:self];
            [entry setAction:@selector(textFieldDidEndEditing:)];
            [entry setTag:i];
            [entry setObjectValue:[theBib valueOfField:tmp]];
            [entry setTitleFont:requiredFont];
            [entry setAttributedTitle:[[[NSAttributedString alloc] initWithString:tmp
                                                                       attributes:reqAtt] autorelease]];
            // Autocompletion stuff
            [entry setFormatter:[appController formatterForEntry:tmp]];
            //[entry setTitleAlignment:NSRightTextAlignment]; this doesn't work...
            i++;
        }
    }

    e = [sKeys objectEnumerator];
    while(tmp = [e nextObject]){
        if(![theBib isRequired:tmp] &&
           ![tmp isEqualToString:BDSKAnnoteString] &&
           ![tmp isEqualToString:BDSKAbstractString] &&
           ![tmp isEqualToString:BDSKRssDescriptionString]){
            
            entry = [bibFields insertEntry:tmp atIndex:i];
            [entry setTarget:self];
            [entry setAction:@selector(textFieldDidEndEditing:)];
            [entry setTag:i];
            [entry setObjectValue:[theBib valueOfField:tmp]];
            [entry setTitleAlignment:NSLeftTextAlignment];
            // Autocompletion stuff
            [entry setFormatter:[appController formatterForEntry:tmp]];
            i++;
        }
    }
    [bibFields sizeToFit];
    
    [bibFields setFrameOrigin:origin];
    [bibFields setNeedsDisplay:YES];
}

- (void)awakeFromNib{
    NSEnumerator *typeNamesE = [[[BibTypeManager sharedManager] bibTypesForFileType:[theBib fileType]] objectEnumerator];
    NSString *typeName = nil;
    
    [citeKeyField setFormatter:citeKeyFormatter];
    [newFieldName setFormatter:fieldNameFormatter];

    [bibTypeButton removeAllItems];
    while(typeName = [typeNamesE nextObject]){
        [bibTypeButton addItemWithTitle:typeName];
    }

    [bibTypeButton selectItemWithTitle:currentType];
    [self setupForm]; // gets called in window will load...?
    [self fixURLs];
    [notesView setString:[theBib valueOfField:BDSKAnnoteString]];
    [abstractView setString:[theBib valueOfField:BDSKAbstractString]];
    [rssDescriptionView setString:[theBib valueOfField:BDSKRssDescriptionString]];
    [citeKeyField setStringValue:[theBib citeKey]];
    [theBib setEditorObj:self];
}

- (void)dealloc{
#if DEBUG
    NSLog(@"BibEditor dealloc");
#endif
    // release theBib? no...
    [citeKeyFormatter release];
    [super dealloc];
}

- (void)show{
    [self showWindow:self];
}



- (void)finalizeChanges{
    if ([[self window] makeFirstResponder:[self window]]) {
    /* All fields are now valid; it's safe to use fieldEditor:forObject:
    to claim the field editor. */
    }else{
        /* Force first responder to resign. */
        [[self window] endEditingFor:nil];
    }
}

- (IBAction)saveDocument:(id)sender{
    // a safety call to be sure that the current field's changes are saved :...
    [self finalizeChanges];

    [theDoc saveDocument:sender];
}

- (IBAction)viewLocal:(id)sender{
    NSWorkspace *sw = [NSWorkspace sharedWorkspace];
    
    BOOL err = NO;

    NS_DURING

        if(![sw openFile:[theBib localURLPathRelativeTo:[[theDoc fileName] stringByDeletingLastPathComponent]]]){
                err = YES;
        }

        NS_HANDLER
            err=YES;
        NS_ENDHANDLER
        
        if(err)
            NSBeginAlertSheet(NSLocalizedString(@"Can't open local file", @"can't open local file"),
                              NSLocalizedString(@"OK", @"OK"),
                              nil,nil, [self window],self, NULL, NULL, NULL,
                              NSLocalizedString(@"Sorry, the contents of the Local-Url Field are neither a valid file path nor a valid URL.",
                                                @"explanation of why the local-url failed to open"), nil);

}

- (IBAction)viewRemote:(id)sender{
    NSWorkspace *sw = [NSWorkspace sharedWorkspace];
    NSString *rurl = [theBib valueOfField:BDSKUrlString];
    if ([@"" caseInsensitiveCompare:rurl] != NSOrderedSame) {
        [sw openURL:[NSURL URLWithString:rurl]];
    }
}

- (IBAction)citeKeyDidChange:(id)sender{
    NSString *proposedCiteKey = [sender stringValue];
    int rv;

    if(![self citeKeyIsValid:proposedCiteKey]){
        rv = NSRunCriticalAlertPanel(NSLocalizedString(@"",@""), NSLocalizedString(@"The citation key you entered is either already used in this document or is empty. Please provide an unique one.",@""),
                                NSLocalizedString(@"OK",@"OK"), nil, nil, nil);
        NSLog(@"%d makeFirstResponder",[[self window] makeFirstResponder:citeKeyField]); // why won't this work?
    }else{
        [theBib setCiteKey:proposedCiteKey];
        [self noteChange];
    }
}

- (BOOL)citeKeyIsValid:(NSString *)proposedCiteKey{
    return !([theDoc citeKeyIsUsed:proposedCiteKey byItemOtherThan:theBib] || [proposedCiteKey isEqualToString:@""]);
}

// sent by the notesView and the abstractView
- (void)textDidChange:(NSNotification *)aNotification{
    if([aNotification object] == notesView){
        [theBib setField:BDSKAnnoteString toValue:[[notesView string] copy]];
    }
    else if([aNotification object] == abstractView){
        [theBib setField:BDSKAbstractString toValue:[[abstractView string] copy]];
    }
    else if([aNotification object] == rssDescriptionView){
        // NSLog(@"setting rssdesc to %@", [rssDescriptionView string]);
        [theBib setField:BDSKRssDescriptionString toValue:[[rssDescriptionView string] copy]];
    }

    [self noteChange];
}

- (IBAction)bibTypeDidChange:(id)sender{
    if (![[self window] makeFirstResponder:[self window]]){
        [[self window] endEditingFor:nil];
    }
    currentType = [bibTypeButton titleOfSelectedItem];
    if([theBib type] != currentType){
        [theBib makeType:currentType];
        [self setupForm];
        [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:currentType
                                                           forKey:BDSKPubTypeStringKey];
        [self noteChange];
    }
}

- (void)fixURLs{
    NSString *lurl = [theBib localURLPathRelativeTo:[[theDoc fileName] stringByDeletingLastPathComponent]];
    NSString *rurl = [theBib valueOfField:BDSKUrlString];
    NSImage *icon;
    NSURL *remote = [NSURL URLWithString:rurl];
    NSDictionary *linkAttributes;
    NSMutableAttributedString *link = [[NSMutableAttributedString alloc] initWithString:rurl];


    BOOL drawerWasOpen = ([documentSnoopDrawer state] == NSDrawerOpenState);
    BOOL drawerIsOpening = ([documentSnoopDrawer state] == NSDrawerOpeningState);

    if(drawerWasOpen) [documentSnoopDrawer close];
    //local is either a file:// URL -or a path
    // How to use stringByExpandingTildeInPath to expand the URL? get the url, get its path, then expand that, then replace it as the url? ugly. 

    
    if (lurl && [[NSFileManager defaultManager] fileExistsAtPath:lurl]){
            icon = [[NSWorkspace sharedWorkspace] iconForFile:lurl];
            [viewLocalButton setImage:icon];
            [viewLocalButton setBordered:NO]; 
            [viewLocalButton setToolTip:@"View File"];
            [viewLocalButton setTitle:@""];
            [viewLocalButton setAction:@selector(viewLocal:)];
            [documentSnoopButton setEnabled:YES];
            [documentSnoopButton setToolTip:NSLocalizedString(@"Show first page in a drawer.", @"show first page in a drawer")];
            [documentTextSnoopButton setEnabled:YES];
            [documentTextSnoopButton setToolTip:NSLocalizedString(@"Show first page as text in a drawer.", @"show first page as text in a drawer")];
            
            if(drawerWasOpen || drawerIsOpening){
                if(!_pdfSnoopImage){
                    _pdfSnoopImage = [[NSImage alloc] initWithContentsOfFile:lurl];
                }

                NSLog(@"setting snoop to %@ from file %@", _pdfSnoopImage, lurl);

                if(_pdfSnoopImage){
                    // [documentSnoopImageView setImage:_pdfSnoopImage];
                    [documentSnoopImageView loadFromPath:lurl];
                    [_pdfSnoopImage setBackgroundColor:[NSColor whiteColor]];
                    
                    [documentSnoopScrollView setDocumentViewAlignment:NSImageAlignTopLeft];
                    if(drawerWasOpen) // open it again.
                        [documentSnoopDrawer open];
                    
                }
            }
    }else{
        [viewLocalButton setImage:nil];
        [viewLocalButton setBordered:YES]; 
        [viewLocalButton setTitle:NSLocalizedString(@"Pick\nFile.", @"Choose file, make sure it fits in the icon")];
        [viewLocalButton setToolTip:NSLocalizedString(@"Bad or Empty Local-Url Field", @"bad/empty local url field")];
        [viewLocalButton setAction:@selector(chooseLocalURL:)];
        
        [documentSnoopButton setEnabled:NO];
        [documentSnoopButton setToolTip:NSLocalizedString(@"Bad or Empty Local-Url Field", @"bad/empty local field")];
        [documentTextSnoopButton setEnabled:NO];
        [documentTextSnoopButton setToolTip:NSLocalizedString(@"Bad or Empty Local-Url Field", @"bad/empty local field")];
        
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

#pragma mark || choose-local-url open-sheet support

- (IBAction)chooseLocalURL:(id)sender{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    int result = [oPanel runModalForDirectory:nil
                                     file:nil
                                    types:nil];
    if (result == NSOKButton) {
        [theBib setField:@"Local-Url" toValue:[[oPanel filename] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
        [self noteChange];
        [self setupForm];
        [self fixURLs];
    }
    
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
        if(![[[theBib dict] allKeys] containsObject:[newFieldName stringValue]]){
            [theBib setField:[newFieldName stringValue] toValue:@""];
            [self setupForm];
            [self makeKeyField:[newFieldName stringValue]];
            [theDoc updateChangeCount:NSChangeDone];
        }
    }
    // else, nothing.
}

- (void)makeKeyField:(NSString *)fieldName{
    int sel = -1;
    int i = 0;

    for (i = 0; i < [bibFields numberOfRows]; i++) {
        if ([[[bibFields cellAtIndex:i] title] isEqualToString:fieldName]) {
            sel = i;
        }
    }
    if(sel > -1) [bibFields selectTextAtIndex:sel];
}

// ----------------------------------------------------------------------------------------
#pragma mark ||  delete-Field-Sheet Support
// ----------------------------------------------------------------------------------------

// raises the del field sheet
- (IBAction)raiseDelField:(id)sender{
    // populate the popupbutton
    NSEnumerator *keyE = [[[[theBib dict] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]objectEnumerator];
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

        [theBib removeField:[delFieldPopUp titleOfSelectedItem]];
        [self setupForm];
//        [self updateChangeCount:NSChangeDone];
        [theDoc updateChangeCount:NSChangeDone];
    }
    // else, nothing.
}

- (void)controlTextDidBeginEditing:(NSNotification *)aNotification{
//    id fieldEditor = [[aNotification userInfo] objectForKey:@"NSFieldEditor"];
//    NSUndoManager *undoManager = [theDoc undoManager];
//    id cell = [aNotification object];
 //   [undoManager registerUndoWithTarget:cell
  //                             selector:@selector(setStringValue:)
   //                              object:[cell stringValue]];
    //[undoManager setActionName:NSLocalizedString(@"Edit Cell",@"")];
    
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification{
    // here for undo
}

// sent by the NSForm
- (IBAction)textFieldDidEndEditing:(id)sender{
    NSCell *sel = [sender cellAtIndex: [sender indexOfSelectedItem]];
    NSString *title = [sel title];

    if([sender indexOfSelectedItem] != -1){
        [theBib setField:title toValue:[sel stringValue]];
        if([title isEqualToString:BDSKUrlString] || [title isEqualToString:BDSKLocalUrlString]){
            [self fixURLs];
            [_textSnoopString release];
            [_pdfSnoopImage release];
            _textSnoopString = nil;
            _pdfSnoopImage = nil;
        }
        if([title isEqualToString:@"Title"]){
            [[self window] setTitle:[sel stringValue]];
        }

        [self noteChange]; // shouldn't get called if there was no change.
    }
}

// Note for a future refactoring: This should really just
//  send a notification that "I changed" and let any Doc(/finder) that cares update.
- (void)noteChange{
    [theDoc updateChangeCount:NSChangeDone];
}

#pragma mark -
#pragma mark snoop drawer stuff

- (void)toggleSnoopDrawer:(id)sender{
    if (sender == documentSnoopButton) {
        [documentSnoopDrawer setContentView:pdfSnoopContainerView];
    }else{
        [documentSnoopDrawer setContentView:textSnoopContainerView];
    }
    [documentSnoopDrawer toggle:sender];
}

- (void)drawerWillOpen:(NSNotification *)notification{
    //@@snoop text: these variables all go with the refactoring
    NSString *cmdString = nil;
    NSString *lurl = [theBib valueOfField:BDSKLocalUrlString];
    NSURL *local = nil;
    

    [self fixURLs]; //no this won't cause a loop - see fixURLs. Please don't break that though. Boy it's fragile.
    [documentSnoopButton setToolTip:NSLocalizedString(@"Close drawer", @"")];
    [documentTextSnoopButton setToolTip:NSLocalizedString(@"Close drawer", @"")];

    // @@snoop text - refactor this into a separate method later
    // @@URL handling refactor this
    if(![@"" isEqualToString:lurl]){
        local = [NSURL URLWithString:lurl];
        if(!local){
            local = [NSURL fileURLWithPath:[lurl stringByExpandingTildeInPath]];
        }
    }else{
        return;
    }

    if([documentSnoopDrawer contentView] == textSnoopContainerView){

    cmdString = [NSString stringWithFormat:@"%@/pdftotext -f 1 -l 1 %@ -",[[NSBundle mainBundle] resourcePath], [local path],
        nil];

        if(!_textSnoopString){
            _textSnoopString = [[[BDSKShellTask shellTask] runShellCommand:cmdString withInputString:nil] retain];
        }
        [documentSnoopTextView setString:_textSnoopString];
    }
}


- (void)drawerWillClose:(NSNotification *)notification{
    [documentSnoopButton setToolTip:NSLocalizedString(@"Show the first page as PDF in a drawer.", @"")];
    [documentTextSnoopButton setToolTip:NSLocalizedString(@"Show the first page as Text in a drawer.", @"")];
}

- (BOOL)windowShouldClose:(id)sender{
    int rv = 0;
    if (![self citeKeyIsValid:[citeKeyField stringValue]]) {
        rv = NSRunCriticalAlertPanel(NSLocalizedString(@"",@""), NSLocalizedString(@"The citation key you entered is either already used in this document or is empty. Please provide an unique one.",@""),
                                     NSLocalizedString(@"OK",@"OK"), nil, nil, nil);
        return NO;
    }
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification{
    [[self window] makeFirstResponder:citeKeyField]; // makes the field check if there is a duplicate field.
    [[self window] makeFirstResponder:[self window]];
    [theBib setFields:[theBib dict]]; // should really update its own metadata whenever you call setField:forvalue or whatever. Another thing for the to-do list.
    [theDoc controlTextDidChange:nil]; // should really just tell them I changed and have them update only if my bib is already highlit...
    [theDoc highlightBib:theBib];
    [documentSnoopDrawer close];
}

@end
