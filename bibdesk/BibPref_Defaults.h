/* BibPref_Defaults */
/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <Cocoa/Cocoa.h>
#import <OmniAppKit/OAPreferenceClient.h>
#import "BibPrefController.h"
#import "BDSKFieldNameFormatter.h"

@interface BibPref_Defaults : OAPreferenceClient
{
    // Default Fields stuff
    NSMutableArray *defaultFieldsArray;    // the fields to add to every new bib.
    IBOutlet NSButton* delSelectedFieldButton;
    IBOutlet NSButton* addFieldButton;
    IBOutlet NSTextField* addFieldField;
    IBOutlet NSTableView* defaultFieldsTableView;
    // the template file button:
    IBOutlet NSButton* outputTemplateFileButton;
    IBOutlet NSMatrix *templateRadioMatrix;
    
    IBOutlet NSButton *useNormalizedNamesButton;
}
// defaultFieldStuff
- (IBAction)delSelectedDefaultField:(id)sender;
- (IBAction)addDefaultField:(id)sender;
// edits the template file:
- (IBAction)outputTemplateButtonPressed:(id)sender;
- (IBAction)shouldUseTemplateFile:(id)sender;

- (IBAction)setShouldUseNormalizedNames:(id)sender;

@end
