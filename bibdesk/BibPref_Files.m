//
//  BibPref_Files.m
//  BibDesk
//
//  Created by Adam Maxwell on 01/02/05.
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

#import "BibPref_Files.h"
#import "BDSKStringEncodingManager.h"
#import "BibAppController.h"
#import "BDSKCharacterConversion.h"
#import "BDSKConverter.h"
#import "BDSKErrorObjectController.h"
#import "NSFileManager_BDSKExtensions.h"
#import "NSWindowController_BDSKExtensions.h"

@implementation BibPref_Files

- (void)updateUI{
    [encodingPopUp setEncoding:[defaults integerForKey:BDSKDefaultStringEncodingKey]];
    [showErrorsCheckButton setState: 
		([defaults boolForKey:BDSKShowWarningsKey] == YES) ? NSOnState : NSOffState  ];	
    [shouldTeXifyCheckButton setState:([defaults boolForKey:BDSKShouldTeXifyWhenSavingAndCopyingKey] == YES) ? NSOnState : NSOffState];
    [saveAnnoteAndAbstractAtEndButton setState:([defaults boolForKey:BDSKSaveAnnoteAndAbstractAtEndOfItemKey] == YES) ? NSOnState : NSOffState];
    [useNormalizedNamesButton setState:[defaults boolForKey:BDSKShouldSaveNormalizedAuthorNamesKey] ? NSOnState : NSOffState];
    [useTemplateFileButton setState:[defaults boolForKey:BDSKShouldUseTemplateFile] ? NSOnState : NSOffState];
    
    [autosaveDocumentButton setState:[defaults boolForKey:BDSKShouldAutosaveDocumentKey] ? NSOnState : NSOffState];
    
    // prefs time is in seconds, but we display in minutes
    NSTimeInterval saveDelay = [defaults integerForKey:BDSKAutosaveTimeIntervalKey] / 60;
    [autosaveTimeField setIntValue:saveDelay];
    [autosaveTimeStepper setIntValue:saveDelay];
    
    [autosaveTimeField setEnabled:[defaults boolForKey:BDSKShouldAutosaveDocumentKey]];
    [autosaveTimeStepper setEnabled:[defaults boolForKey:BDSKShouldAutosaveDocumentKey]];
    
}

- (IBAction)setDefaultStringEncoding:(id)sender{    
    [defaults setInteger:[sender encoding] forKey:BDSKDefaultStringEncodingKey];
    [defaults autoSynchronize];
}

- (IBAction)toggleShowWarnings:(id)sender{
    [defaults setBool:([sender state] == NSOnState) ? YES : NO forKey:BDSKShowWarningsKey];
    [defaults autoSynchronize];
    if ([sender state] == NSOnState) {
        [[BDSKErrorObjectController sharedErrorObjectController] showWindow:self];
    }else{
        [[BDSKErrorObjectController sharedErrorObjectController] hideWindow:self];
    }        
}

- (IBAction)toggleShouldTeXify:(id)sender{
    [defaults setBool:([sender state] == NSOnState ? YES : NO) forKey:BDSKShouldTeXifyWhenSavingAndCopyingKey];
    [self valuesHaveChanged];
}

- (IBAction)toggleShouldUseNormalizedNames:(id)sender{
    [defaults setBool:([sender state] == NSOnState ? YES : NO) forKey:BDSKShouldSaveNormalizedAuthorNamesKey];
    [defaults autoSynchronize];
}

- (IBAction)toggleSaveAnnoteAndAbstractAtEnd:(id)sender{
    [defaults setBool:([sender state] == NSOnState ? YES : NO) forKey:BDSKSaveAnnoteAndAbstractAtEndOfItemKey];
    [self valuesHaveChanged];
}

- (IBAction)toggleShouldUseTemplateFile:(id)sender{
    [defaults setBool:([sender state] == NSOnState ? YES : NO) forKey:BDSKShouldUseTemplateFile];
    [defaults autoSynchronize];
}

- (IBAction)editTemplateFile:(id)sender{
    if(![[NSWorkspace sharedWorkspace] openFile:[[defaults stringForKey:BDSKOutputTemplateFileKey] stringByExpandingTildeInPath]])
        if(![[NSWorkspace sharedWorkspace] openFile:[[defaults stringForKey:BDSKOutputTemplateFileKey] stringByExpandingTildeInPath] withApplication:@"TextEdit"])
            NSBeep();
}

- (void)templateAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    if (returnCode == NSAlertAlternateReturn)
        return;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *templateFilePath = [[defaults stringForKey:BDSKOutputTemplateFileKey] stringByExpandingTildeInPath];
    if([fileManager fileExistsAtPath:templateFilePath])
        [fileManager removeFileAtPath:templateFilePath handler:nil];
    // copy template.txt file from the bundle
    [fileManager copyPath:[[NSBundle mainBundle] pathForResource:@"template" ofType:@"txt"]
                   toPath:templateFilePath handler:nil];
}

- (IBAction)resetTemplateFile:(id)sender{
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Reset the default template file to its original value?", @"Message in alert dialog when resetting bibtex template files") 
									 defaultButton:NSLocalizedString(@"OK", @"Button title") 
								   alternateButton:NSLocalizedString(@"Cancel", @"Button title") 
									   otherButton:nil 
						 informativeTextWithFormat:NSLocalizedString(@"Choosing Reset will restore the original content of the template file.", @"Informative text in alert dialog")];
	[alert beginSheetModalForWindow:[[BDSKPreferenceController sharedPreferenceController] window] 
					  modalDelegate:self
					 didEndSelector:@selector(templateAlertDidEnd:returnCode:contextInfo:) 
						contextInfo:NULL];
}

- (IBAction)showConversionEditor:(id)sender{
	[[BDSKCharacterConversion sharedConversionEditor] beginSheetModalForWindow:[[self controlBox] window]];
}

- (void)conversionsAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    if (returnCode == NSAlertAlternateReturn)
        return;
    NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *conversionsFilePath = [[fileManager currentApplicationSupportPathForCurrentUser] stringByAppendingPathComponent:CHARACTER_CONVERSION_FILENAME];
    if([fileManager fileExistsAtPath:conversionsFilePath])
        [fileManager removeFileAtPath:conversionsFilePath handler:nil];
	// tell the converter to reload its dictionaries
	[[BDSKConverter sharedConverter] loadDict];
}

- (IBAction)resetConversions:(id)sender{
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Reset character conversions to their original value?", @"Message in alert dialog when resetting custom character conversions") 
									 defaultButton:NSLocalizedString(@"OK", @"Button title") 
								   alternateButton:NSLocalizedString(@"Cancel", @"Button title") 
									   otherButton:nil 
						 informativeTextWithFormat:NSLocalizedString(@"Choosing Reset will erase all custom character conversions.", @"Informative text in alert dialog")];
	[alert beginSheetModalForWindow:[[BDSKPreferenceController sharedPreferenceController] window] 
					  modalDelegate:self
					 didEndSelector:@selector(conversionsAlertDidEnd:returnCode:contextInfo:) 
						contextInfo:NULL];
}

- (IBAction)setAutosaveTime:(id)sender;
{    
    NSTimeInterval saveDelay = [sender intValue] * 60; // convert to seconds
    [defaults setInteger:saveDelay forKey:BDSKAutosaveTimeIntervalKey];
    [[NSDocumentController sharedDocumentController] setAutosavingDelay:saveDelay];
    [self valuesHaveChanged];
}

- (IBAction)setShouldAutosave:(id)sender;
{
    BOOL shouldSave = ([sender state] == NSOnState);
    [defaults setBool:shouldSave forKey:BDSKShouldAutosaveDocumentKey];
    [self valuesHaveChanged];
}

@end
