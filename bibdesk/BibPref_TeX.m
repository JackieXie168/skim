// BibPref_TeX.m
// BibDesk
// Created by Michael McCracken, 2002
/*
 This software is Copyright (c) 2002,2003,2004,2005
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

#import "BibPref_TeX.h"

@implementation BibPref_TeX

- (void)awakeFromNib{
    [super awakeFromNib];
    encodingManager = [BDSKStringEncodingManager sharedEncodingManager];
    [encodingPopUpButton removeAllItems];
    [encodingPopUpButton addItemsWithTitles:[encodingManager availableEncodingDisplayedNames]];
}

- (void)updateUI{
    [usesTeXButton setState:[defaults boolForKey:BDSKUsesTeXKey] ? NSOnState : NSOffState];
  
    [texBinaryPath setStringValue:[defaults objectForKey:BDSKTeXBinPathKey]];
    [bibtexBinaryPath setStringValue:[defaults objectForKey:BDSKBibTeXBinPathKey]];
    [bibTeXStyle setStringValue:[defaults objectForKey:BDSKBTStyleKey]];
    [encodingPopUpButton selectItemWithTitle:[encodingManager displayedNameForStringEncoding:[defaults integerForKey:BDSKTeXPreviewFileEncodingKey]]];

	//This has to follow the lines above because it checks their validity
	[self changeUsesTeX:usesTeXButton]; // this makes sure the fields are set enabled / disabled properly

}

-(IBAction)changeTexBinPath:(id)sender{
    [defaults setObject:[sender stringValue] forKey:BDSKTeXBinPathKey];
}

- (IBAction)changeBibTexBinPath:(id)sender{
    [defaults setObject:[sender stringValue] forKey:BDSKBibTeXBinPathKey];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)control{
    if(returnCode == NSOKButton)
        [[alert window] orderOut:nil];
    NSText *fe = [[[OAPreferenceController sharedPreferenceController] window] fieldEditor:YES forObject:control];
    [(NSTextField *)control selectText:nil];
    [fe setSelectedRange:NSMakeRange([[fe string] length], 0)];
}

- (IBAction)changeUsesTeX:(id)sender{
    if ([sender state] == NSOffState) {
        [bibTeXStyle setEnabled:NO];
		
		//These are left enabled so that the user can fix errors.
        [texBinaryPath setEnabled:YES];
        [bibtexBinaryPath setEnabled:YES];
		
        [defaults setBool:NO forKey:BDSKUsesTeXKey];
		
		// hide preview panel if necessary
		if ([[NSApp delegate] isShowingPreviewPanel]) {
			[[NSApp delegate] hidePreviewPanel:self];
		}
    }else{
		// Check that executable paths are valid
	    if ([self checkBibTexBinPath] && [self checkTexBinPath]) {
		
			// Ensure that paths don't change while previewing is enabled.
			// so that we can reliably validate them.
			[bibtexBinaryPath setEnabled:NO];
			[texBinaryPath setEnabled:NO];
		
			// Enable the style changing interface
			[bibTeXStyle setEnabled:YES];
			
			[defaults setBool:YES forKey:BDSKUsesTeXKey];
		
			// show preview panel if necessary
			if ([[defaults objectForKey:@"BDSK Showing Preview Key"] isEqualToString:@"showing"]) {
				[[NSApp delegate] showPreviewPanel:self];
			}
		}
    }
}

- (BOOL) checkTexBinPath { 
  //Ensure that the fields to be validated have finished editing and thus called changeTexPath
  [self changeTexBinPath:texBinaryPath];

  if( ![[NSFileManager defaultManager] isExecutableFileAtPath:[defaults objectForKey:BDSKTeXBinPathKey]] ) {
    [self warnAndDisablePreview:[defaults objectForKey:BDSKTeXBinPathKey]];
	return FALSE;
   } else {
	return TRUE;
   }
}

- (BOOL) checkBibTexBinPath { 
  //Ensure that the fields to be validated have finished editing and thus called changeTexPath
  [self changeBibTexBinPath:bibtexBinaryPath];

  if( ![[NSFileManager defaultManager] isExecutableFileAtPath:[defaults objectForKey:BDSKBibTeXBinPathKey]] ) {
    [self warnAndDisablePreview:[defaults objectForKey:BDSKBibTeXBinPathKey]];
	return FALSE;
   } else {
	return TRUE;
   }
}
		
- (void) warnAndDisablePreview:(NSString *) errStr {
        NSBeep();
        NSAlert *anAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error!",@"Error!")
					   defaultButton:nil
					 alternateButton:nil
					     otherButton:nil
			       informativeTextWithFormat:NSLocalizedString(@"The file %@ does not exist or is not executable. Previewing is disabled. Please set an appropriate path and re-enable previewing.",@""), errStr];
	[anAlert beginSheetModalForWindow:[[OAPreferenceController sharedPreferenceController] window]
			    modalDelegate:nil
			   didEndSelector:nil
			      contextInfo:nil];
				  
		//Disable previewing
		[usesTeXButton setState:NSOffState];
		[self changeUsesTeX:usesTeXButton];
    }

- (IBAction)changeStyle:(id)sender{
    [defaults setObject:[sender stringValue] forKey:BDSKBTStyleKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewNeedsUpdateNotification object:self];
}

- (IBAction)openTeXpreviewFile:(id)sender{
    // Edit the TeX template in the Application Support folder
    NSString *applicationSupportPath = [[[NSFileManager defaultManager] applicationSupportDirectory:kUserDomain] stringByAppendingPathComponent:@"BibDesk"];
    
    // edit the previewtemplate.tex file, so the bibpreview.tex is only edited by PDFPreviewer
    NSString *path = [applicationSupportPath stringByAppendingPathComponent:@"previewtemplate.tex"];
    NSURL *url = nil;

    url = [NSURL fileURLWithPath:path];
    // we could check to see if the file exists, but this is already done at startup
	if([url isFileURL]){
	    LSOpenCFURLRef((CFURLRef)url, NULL);
	} else
	    NSLog(@"The url is not a FileURL.");
}


- (IBAction)downloadTeX:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:BDSKTEXDOWNLOADURL]];
}

- (IBAction)changeDefaultTeXEncoding:(id)sender{
    NSStringEncoding encoding = [encodingManager stringEncodingForDisplayedName:[[sender selectedItem] title]];
    
    // NSLog(@"set encoding to %i for tag %i", [[encodingsArray objectAtIndex:[sender indexOfSelectedItem]] intValue], [sender indexOfSelectedItem]);    
    [defaults setInteger:encoding forKey:BDSKTeXPreviewFileEncodingKey];        
}


@end
