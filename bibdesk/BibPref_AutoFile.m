//
//  BibPref_AutoFile.m
//  BibDesk
//
//  Created by Michael McCracken on Wed Oct 08 2003.
/*
 This software is Copyright (c) 2003,2004,2005,2006
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

#import "BibPref_AutoFile.h"
#import "NSImage+Toolbox.h"
#import "BDSKAlert.h"
#import "BDSKFormatParser.h"
#import "BibAppController.h"
#import "BDSKPreviewItem.h"

#define MAX_PREVIEW_WIDTH	501.0
#define MAX_FORMAT_WIDTH	288.0
#define USE_DOCUMENT_FOLDER NSLocalizedString(@"Use Document Folder", @"Placeholder string for Papers Folder")

@interface BDSKFolderPathFormatter : NSFormatter @end

@implementation BibPref_AutoFile

// these should correspond to the items in the popups set in IB
static NSString *presetFormatStrings[] = {@"%L", @"%l%n0%e", @"%a1/%Y%u0%e", @"%a1/%T5%e"};
static NSString *repositorySpecifierStrings[] = {@"", @"%a00", @"%A0", @"%t0", @"%T0", @"%Y", @"%y", @"%m", @"%k0", @"%L", @"%l", @"%e", @"%b", @"%f{}0", @"%s{}[][][]0", @"%c{}", @"%f{Cite Key}", @"%u0", @"%U0", @"%n0", @"%0", @"%%"};

- (void)dealloc{
    [coloringEditor release];
	[formatSheet release];
	[super dealloc];
}

- (void)awakeFromNib{
    [super awakeFromNib];
	BDSKFormatStringFormatter *formatter = [[BDSKFormatStringFormatter alloc] initWithField:BDSKLocalUrlString fileType:BDSKBibtexString];
    [formatSheetField setFormatter:formatter];
	[formatter release];
    coloringEditor = [[BDSKFormatStringFieldEditor alloc] initWithFrame:[formatSheetField frame] parseField:BDSKLocalUrlString fileType:BDSKBibtexString];
    [papersFolderLocationTextField setFormatter:[[[BDSKFolderPathFormatter alloc] init] autorelease]];
    [previewDisplay setStringValue:[[BDSKPreviewItem sharedItem] displayText]];
    [previewDisplay sizeToFit];
}

// sheet's delegate must be connected to file's owner in IB
- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject{
    return (anObject == formatSheetField ? coloringEditor : nil);
}

- (void)updateUI{
    NSString *formatString = [defaults stringForKey:BDSKLocalUrlFormatKey];
	NSAttributedString *attrFormat = nil;
    int formatPresetChoice = [defaults integerForKey:BDSKLocalUrlFormatPresetKey];
	BOOL custom = (formatPresetChoice == 0);
    NSString * error;
	NSString *papersFolder = [[defaults objectForKey:BDSKPapersFolderPathKey] stringByAbbreviatingWithTildeInPath];
	NSRect frame;
	
    [filePapersAutomaticallyCheckButton setState:[defaults boolForKey:BDSKFilePapersAutomaticallyKey] ? NSOnState : NSOffState];
    [useRelativePathCheckButton setState:[defaults boolForKey:BDSKAutoFileUsesRelativePathKey] ? NSOnState : NSOffState];
    [warnOnMoveFolderCheckButton setState:[defaults boolForKey:BDSKWarnOnMoveFolderKey] ? NSOnState : NSOffState];

    if ([NSString isEmptyString:papersFolder]) {
		[papersFolderLocationTextField setStringValue:USE_DOCUMENT_FOLDER];
		[papersFolderLocationTextField setEnabled:NO];
		[choosePapersFolderLocationButton setEnabled:NO];
		[clearPapersFolderLocationButton setState:NSOffState];
		[useRelativePathCheckButton setEnabled:YES];
	} else {
		[papersFolderLocationTextField setStringValue:papersFolder];
		[papersFolderLocationTextField setEnabled:YES];
		[choosePapersFolderLocationButton setEnabled:YES];
		[clearPapersFolderLocationButton setState:NSOnState];
		[useRelativePathCheckButton setState:NSOffState];
		[useRelativePathCheckButton setEnabled:NO];
	}

    [formatLowercaseCheckButton setState:[defaults boolForKey:BDSKLocalUrlLowercaseKey] ? NSOnState : NSOffState];
    [formatCleanRadio selectCellWithTag:[defaults integerForKey:BDSKLocalUrlCleanOptionKey]];
	
	if ([BDSKFormatParser validateFormat:&formatString attributedFormat:&attrFormat forField:BDSKLocalUrlString inFileType:BDSKBibtexString error:&error]) {
		[self setLocalUrlFormatInvalidWarning:NO message:nil];
		
        [previewTextField setStringValue:[[BDSKPreviewItem sharedItem] suggestedLocalUrl]];
		[previewTextField sizeToFit];
		frame = [previewTextField frame];
		if (frame.size.width > MAX_PREVIEW_WIDTH) {
			frame.size.width = MAX_PREVIEW_WIDTH;
			[previewTextField setFrame:frame];
		}
		[controlBox setNeedsDisplay:YES];
	} else {
		[self setLocalUrlFormatInvalidWarning:YES message:error];
		[previewTextField setStringValue:NSLocalizedString(@"Invalid Format", @"Preview for invalid autogeneration format")];
		if (![formatSheet isVisible])
			[self showFormatSheet:self];
	}
	[formatPresetPopUp selectItemAtIndex:[formatPresetPopUp indexOfItemWithTag:formatPresetChoice]];
	[formatPresetSheetPopUp selectItemAtIndex:[formatPresetPopUp indexOfItemWithTag:formatPresetChoice]];
	[formatField setAttributedStringValue:attrFormat];
	[formatField sizeToFit];
	frame = [formatField frame];
	if (frame.size.width > MAX_FORMAT_WIDTH) {
		frame.size.width = MAX_FORMAT_WIDTH;
		[formatField setFrame:frame];
	}
	[formatSheetField setAttributedStringValue:attrFormat];
	[formatSheetField setEnabled:custom];
	[formatRepositoryPopUp setHidden:!custom];
}

- (IBAction)setPapersFolderPathFromTextField:(id)sender{
    [defaults setObject:[[sender stringValue] stringByStandardizingPath] forKey:BDSKPapersFolderPathKey];
    [self valuesHaveChanged];
}

- (IBAction)choosePapersFolderLocationAction:(id)sender{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setResolvesAliases:NO];
    [openPanel setPrompt:NSLocalizedString(@"Choose", @"Prompt for Choose panel")];
    [openPanel beginSheetForDirectory:nil 
								 file:nil
								types:nil
					   modalForWindow:[[BDSKPreferenceController sharedPreferenceController] window] 
						modalDelegate:self 
					   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
						  contextInfo:NULL];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSOKButton) {
		NSString *path = [[sheet filenames] objectAtIndex: 0];
		[defaults setObject:path forKey:BDSKPapersFolderPathKey];
	}
	[self valuesHaveChanged];
}

- (IBAction)clearPapersFolderLocationAction:(id)sender{
	if ([sender state] == NSOnState) {
        [defaults setBool:NO forKey:BDSKAutoFileUsesRelativePathKey];
		[self choosePapersFolderLocationAction:sender];
        [defaults autoSynchronize];
	} else {
		[defaults setObject:@"" forKey:BDSKPapersFolderPathKey];
		[self valuesHaveChanged];
	}
}

- (IBAction)toggleUseRelativePathAction:(id)sender{
	[defaults setBool:([useRelativePathCheckButton state] == NSOnState)
			   forKey:BDSKAutoFileUsesRelativePathKey];
	[self valuesHaveChanged];
}

- (IBAction)toggleFilePapersAutomaticallyAction:(id)sender{
	[defaults setBool:([filePapersAutomaticallyCheckButton state] == NSOnState)
			   forKey:BDSKFilePapersAutomaticallyKey];
    [defaults autoSynchronize];
}

- (IBAction)toggleWarnOnMoveFolderAction:(id)sender{
	[defaults setBool:([warnOnMoveFolderCheckButton state] == NSOnState)
			   forKey:BDSKWarnOnMoveFolderKey];
    [defaults autoSynchronize];
}

// presently just used to display the warning if the path for autofile was invalid
- (BOOL)control:(NSControl *)control didFailToFormatString:(NSString *)string errorDescription:(NSString *)error{
    if(error != nil)
        NSBeginAlertSheet(NSLocalizedString(@"Invalid Entry", @"Message in alert dialog when entering invalid entry"), nil, nil, nil, [controlBox window], nil, NULL, NULL, NULL, error);
    return NO;
}

#pragma mark Local-Url format stuff

- (IBAction)localUrlHelp:(id)sender{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"AutoFile" inBook:@"BibDesk Help"];
}

- (IBAction)formatHelp:(id)sender{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"Autogeneration-Format-Syntax" inBook:@"BibDesk Help"];
}

- (IBAction)changeLocalUrlLowercase:(id)sender{
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKLocalUrlLowercaseKey];
	[self valuesHaveChanged];
}

- (IBAction)setFormatCleanOption:(id)sender{
	[defaults setInteger:[[sender selectedCell] tag] forKey:BDSKLocalUrlCleanOptionKey];
    [defaults autoSynchronize];
}

- (IBAction)localUrlFormatAdd:(id)sender{
	int index = [formatRepositoryPopUp indexOfSelectedItem];
	NSString *newSpecifier = repositorySpecifierStrings[index];
    NSText *fieldEditor = [formatSheetField currentEditor];
	NSRange selRange;
	
	if ([NSString isEmptyString:newSpecifier])
		return;
	
    if (fieldEditor) {
		selRange = NSMakeRange([fieldEditor selectedRange].location + 2, [newSpecifier length] - 2);
		[fieldEditor insertText:newSpecifier];
	} else {
		NSString *formatString = [formatSheetField stringValue];
		selRange = NSMakeRange([formatString length] + 2, [newSpecifier length] - 2);
		[formatSheetField setStringValue:[formatString stringByAppendingString:newSpecifier]];
	}
	
	// this handles the new defaults and the UI update
	[self localUrlFormatChanged:sender];
	
	// select the 'arbitrary' numbers
	if ([newSpecifier isEqualToString:@"%0"]) {
		selRange.location -= 1;
		selRange.length = 1;
	}
	else if ([newSpecifier isEqualToString:@"%f{}0"] || [newSpecifier isEqualToString:@"%s{}[][][]0"] || [newSpecifier isEqualToString:@"%c{}"]) {
		selRange.location += 1;
		selRange.length = 0;
	}
	else if ([newSpecifier isEqualToString:@"%f{Cite Key}"]) {
		selRange.location += 10;
		selRange.length = 0;
	}
	[formatSheetField selectText:self];
	[[formatSheetField currentEditor] setSelectedRange:selRange];
}

- (IBAction)localUrlFormatChanged:(id)sender{
	int presetChoice = 0;
	NSString *formatString;
	
	if (sender == formatPresetPopUp || sender == formatPresetSheetPopUp) {
		presetChoice = [[sender selectedItem] tag];
		if (presetChoice == [defaults integerForKey:BDSKLocalUrlFormatPresetKey]) 
			return; // nothing changed
		[defaults setInteger:presetChoice forKey:BDSKLocalUrlFormatPresetKey];
		if (presetChoice > 0) {
			formatString = presetFormatStrings[presetChoice - 1];
		} else if (presetChoice == 0) {
			formatString = [formatSheetField stringValue];
			if (sender == formatPresetPopUp)
				[self showFormatSheet:self];
		} else {
			return;
		}
		// this one is always valid
		[defaults setObject:formatString forKey:BDSKLocalUrlFormatKey];
	}
	else { //changed the text field or added from the repository
		NSString *error = nil;
		NSAttributedString *attrFormat = nil;
		formatString = [formatSheetField stringValue];
		//if ([formatString isEqualToString:[defaults stringForKey:BDSKLocalUrlFormatKey]]) return; // nothing changed
		if ([BDSKFormatParser validateFormat:&formatString attributedFormat:&attrFormat forField:BDSKLocalUrlString inFileType:BDSKBibtexString error:&error]) {
			[defaults setObject:formatString forKey:BDSKLocalUrlFormatKey];
		}
		else {
			[self setLocalUrlFormatInvalidWarning:YES message:error];
			[formatSheetField setAttributedStringValue:attrFormat];
			return;
		}
	}
	[[NSApp delegate] setRequiredFieldsForLocalUrl: [BDSKFormatParser requiredFieldsForFormat:formatString]];
    [self valuesHaveChanged];
}

#pragma mark Format sheet stuff

- (IBAction)showFormatSheet:(id)sender{
	
    [NSApp beginSheet:formatSheet
       modalForWindow:[[self controlBox] window]
        modalDelegate:self
       didEndSelector:NULL
          contextInfo:nil];
}

- (BOOL)canCloseFormatSheet{
	NSString *formatString = [formatSheetField stringValue];
	NSString *error = nil;
	NSString *otherButton = nil;
	
	if ([formatSheet makeFirstResponder:nil])
		[formatSheet endEditingFor:nil];
	
	if ([BDSKFormatParser validateFormat:&formatString forField:BDSKLocalUrlString inFileType:BDSKBibtexString error:&error]) 
		return YES;
	
	formatString = [defaults stringForKey:BDSKLocalUrlFormatKey];
	if ([BDSKFormatParser validateFormat:&formatString forField:BDSKLocalUrlString inFileType:BDSKBibtexString error:NULL]) {
		// The currently set local-url format is valid, so we can keep it 
		otherButton = NSLocalizedString(@"Revert to Last", @"Button title");
	}
	
	BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Invalid Local-Url Format", @"Message in alert dialog when entering invalid Local-Url format") 
										 defaultButton:NSLocalizedString(@"Keep Editing", @"Button title") 
									   alternateButton:NSLocalizedString(@"Revert to Default", @"Button title") 
										   otherButton:otherButton
							 informativeTextWithFormat:@"%@", error];
	int rv = [alert runSheetModalForWindow:formatSheet];
	
	if (rv == NSAlertDefaultReturn){
		[formatSheetField selectText:self];
		return NO;
	} else if (rv == NSAlertAlternateReturn){
		formatString = [[[OFPreferenceWrapper sharedPreferenceWrapper] preferenceForKey:BDSKLocalUrlFormatKey] defaultObjectValue];
		[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:formatString forKey:BDSKLocalUrlFormatKey];
		[[NSApp delegate] setRequiredFieldsForLocalUrl: [BDSKFormatParser requiredFieldsForFormat:formatString]];
	}
	[self updateUI];
	return YES;
}

- (IBAction)closeFormatSheet:(id)sender{
    if([self canCloseFormatSheet]){
        [formatSheet orderOut:sender];
        [NSApp endSheet:formatSheet];
    }
}

#pragma mark Invalid format warning stuff

- (IBAction)showLocalUrlFormatWarning:(id)sender{
	NSString *msg = [sender toolTip];
	
	if ([NSString isEmptyString:msg]) {
		msg = NSLocalizedString(@"The format string you entered contains invalid format specifiers.", @"Informative text in alert dialog");
	}
	
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Invalid Local-Url Format", @"Message in alert dialog when entering invalid Local-Url format") 
									 defaultButton:NSLocalizedString(@"OK", @"Button title") 
								   alternateButton:nil 
									   otherButton:nil 
						 informativeTextWithFormat:@"%@", msg];
	[alert beginSheetModalForWindow:formatSheet 
					  modalDelegate:nil
					 didEndSelector:NULL 
						contextInfo:NULL];
}

- (void)setLocalUrlFormatInvalidWarning:(BOOL)set message:(NSString *)message{
	if(set){
		[formatWarningButton setImage:[NSImage cautionIconImage]];
		[formatWarningButton setToolTip:message];
	}else{
		[formatWarningButton setImage:nil];
		[formatWarningButton setToolTip:nil];
	}
	[formatWarningButton setEnabled:set];
	[formatSheetField setTextColor:(set ? [NSColor redColor] : [NSColor blackColor])]; // overdone?
}

@end

//
// Formatter for validating a directory in a text field
//

@implementation BDSKFolderPathFormatter

- (NSString *)stringForObjectValue:(id)obj{
    return obj;
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error{
    if ([string isEqualToString:USE_DOCUMENT_FOLDER]) {
        *obj = string;
        return YES;
    }
    
    BOOL isDir;
    // we want to return the original value if it's valid, not the expanded path; the action method should expand it
    NSString *pathString = [string stringByStandardizingPath];
    NS_DURING
        pathString = [[NSFileManager defaultManager] resolveAliasesInPath:pathString];
    NS_HANDLER
        NSLog(@"Ignoring exception %@ raised while resolving aliases in %@", [localException name], pathString);
    NS_ENDHANDLER
    if([[NSFileManager defaultManager] fileExistsAtPath:pathString isDirectory:&isDir] == NO){
        if(error)
            *error = [NSString stringWithFormat:NSLocalizedString(@"The directory \"%@\" does not exist.", @"Error description"), pathString];
        return NO;
    } else if(isDir == NO){
        if(error)
            *error = [NSString stringWithFormat:NSLocalizedString(@"The file \"%@\" is not a directory.", @"Error description"), pathString];
        return NO;
    } else
	    *obj = string;
    return YES;

}

@end


