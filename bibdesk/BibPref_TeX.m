// BibPref_TeX.m
// BibDesk
// Created by Michael McCracken, 2002
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006
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
#import "BibAppController.h"
#import "BDSKStringEncodingManager.h"
#import "BDSKPreviewer.h"
#import "NSFileManager_BDSKExtensions.h"
#import "NSWindowController_BDSKExtensions.h"
#import "BDSKShellCommandFormatter.h"

#define BDSK_TEX_DOWNLOAD_URL @"http://ii2.sourceforge.net/tex-index.html"


@implementation BibPref_TeX

- (void)awakeFromNib{
    [super awakeFromNib];
    
    BDSKShellCommandFormatter *formatter = [[BDSKShellCommandFormatter alloc] init];
    [texBinaryPathField setFormatter:formatter];
    [texBinaryPathField setDelegate:self];
    [bibtexBinaryPathField setFormatter:formatter];
    [bibtexBinaryPathField setDelegate:self];
    [formatter release];
}

- (void)updateUI{
    [usesTeXButton setState:[defaults boolForKey:BDSKUsesTeXKey] ? NSOnState : NSOffState];
  
    [texBinaryPathField setStringValue:[defaults objectForKey:BDSKTeXBinPathKey]];
    [bibtexBinaryPathField setStringValue:[defaults objectForKey:BDSKBibTeXBinPathKey]];
    [bibTeXStyleField setStringValue:[defaults objectForKey:BDSKBTStyleKey]];
    [encodingPopUpButton setEncoding:[defaults integerForKey:BDSKTeXPreviewFileEncodingKey]];
    [bibTeXStyleField setEnabled:[defaults boolForKey:BDSKUsesTeXKey]];
    
    if ([BDSKShellCommandFormatter isValidExecutableCommand:[defaults objectForKey:BDSKTeXBinPathKey]])
        [texBinaryPathField setTextColor:[NSColor blackColor]];
    else
        [texBinaryPathField setTextColor:[NSColor redColor]];
    
    if ([BDSKShellCommandFormatter isValidExecutableCommand:[defaults objectForKey:BDSKBibTeXBinPathKey]])
        [bibtexBinaryPathField setTextColor:[NSColor blackColor]];
    else
        [bibtexBinaryPathField setTextColor:[NSColor redColor]];
    
}

-(IBAction)changeTexBinPath:(id)sender{
    [defaults setObject:[sender stringValue] forKey:BDSKTeXBinPathKey];
    [self valuesHaveChanged];
}

- (IBAction)changeBibTexBinPath:(id)sender{
    [defaults setObject:[sender stringValue] forKey:BDSKBibTeXBinPathKey];
    [self valuesHaveChanged];
}

- (IBAction)changeUsesTeX:(id)sender{
    if ([sender state] == NSOffState) {		
        [defaults setBool:NO forKey:BDSKUsesTeXKey];
		
		// hide preview panel if necessary
		[[BDSKPreviewer sharedPreviewer] hideWindow:self];
    }else{
        [defaults setBool:YES forKey:BDSKUsesTeXKey];
    }
    [defaults autoSynchronize];
}

- (BOOL)control:(NSControl *)control didFailToFormatString:(NSString *)string errorDescription:(NSString *)error
{
	NSBeginAlertSheet(NSLocalizedString(@"Invalid Path",@"Message in alert dialog when binary path for TeX preview is invalid"), 
    nil, nil, nil, 
    [[self controlBox] window], 
    self, 
    NULL, 
    NULL, 
    nil, 
    error);
        
    // allow the user to end editing and ignore the warning, since TeX may not be installed
    return YES;
}

- (IBAction)changeStyle:(id)sender{
    [defaults setObject:[sender stringValue] forKey:BDSKBTStyleKey];
    [defaults autoSynchronize];
}

- (void)openTemplateFailureSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode path:(void *)path{
    [(id)path autorelease];
    if(returnCode == NSAlertDefaultReturn)
        [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:@""];
}

- (IBAction)openTeXPreviewFile:(id)sender{
    // Edit the TeX template in the Application Support folder
    NSString *applicationSupportPath = [[NSFileManager defaultManager] currentApplicationSupportPathForCurrentUser];
    
    // edit the previewtemplate.tex file, so the bibpreview.tex is only edited by PDFPreviewer
    NSString *path = [applicationSupportPath stringByAppendingPathComponent:@"previewtemplate.tex"];
    NSURL *url = nil;
    
    if([[NSFileManager defaultManager] fileExistsAtPath:path] == NO)
        [self resetTeXPreviewFile:nil];

    url = [NSURL fileURLWithPath:path];
    
    if([[NSWorkspace sharedWorkspace] openURL:url] == NO && [[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:url] withAppBundleIdentifier:@"com.apple.textedit" options:0 additionalEventParamDescriptor:nil launchIdentifiers:NULL] == NO)
        NSBeginAlertSheet(NSLocalizedString(@"Unable to Open File", @"Message in alert dialog when unable to open file"), NSLocalizedString(@"Reveal", @"Button title"), NSLocalizedString(@"Cancel", @"Button title"), nil, [[BDSKPreferenceController sharedPreferenceController] window], self, @selector(openTemplateFailureSheetDidEnd:returnCode:path:), NULL, [[url path] retain], NSLocalizedString(@"The system was unable to find an application to open the TeX template file.  Choose \"Reveal\" to show the template in the Finder.", @"Informative text in alert dialog"));
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    if (returnCode == NSAlertAlternateReturn)
        return;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportPath = [[NSFileManager defaultManager] currentApplicationSupportPathForCurrentUser];
    NSString *previewTemplatePath = [applicationSupportPath stringByAppendingPathComponent:@"previewtemplate.tex"];
    if([fileManager fileExistsAtPath:previewTemplatePath])
        [fileManager removeFileAtPath:previewTemplatePath handler:nil];
    // copy previewtemplate.tex file from the bundle
    [fileManager copyPath:[[NSBundle mainBundle] pathForResource:@"previewtemplate" ofType:@"tex"]
                   toPath:previewTemplatePath handler:nil];
}

- (IBAction)resetTeXPreviewFile:(id)sender{
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Reset TeX template to its original value?", @"Message in alert dialog when resetting preview TeX template file") 
									 defaultButton:NSLocalizedString(@"OK", @"Button title") 
								   alternateButton:NSLocalizedString(@"Cancel", @"Button title") 
									   otherButton:nil 
						 informativeTextWithFormat:NSLocalizedString(@"Choosing Reset will revert the TeX template file to its original content.", @"Informative text in alert dialog")];
	[alert beginSheetModalForWindow:[[BDSKPreferenceController sharedPreferenceController] window] 
					  modalDelegate:self
					 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
						contextInfo:NULL];
}

- (IBAction)downloadTeX:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:BDSK_TEX_DOWNLOAD_URL]];
}

- (IBAction)changeDefaultTeXEncoding:(id)sender{
    [defaults setInteger:[sender encoding] forKey:BDSKTeXPreviewFileEncodingKey];        
    [defaults autoSynchronize];
}


@end
