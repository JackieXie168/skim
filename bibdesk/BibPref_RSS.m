/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BibPref_RSS.h"
#import "BibEditor.h"

@implementation BibPref_RSS
- (void)updateUI{
    [autoSaveAsRSSButton setState:[defaults integerForKey:BDSKAutoSaveAsRSSKey]];
    [findOutMoreButton setLink:@"http://www.cs.ucsd.edu/~mmccrack/AboutRSS.html"];
    [findOutMoreButton setLinkTitle:NSLocalizedString(@"Find out more about RSS",@"")];
    if ([[defaults objectForKey:BDSKRSSDescriptionFieldKey] isEqualToString:BDSKRssDescriptionString]) {
        [descriptionFieldMatrix selectCellWithTag:0];
        [descriptionFieldTextField setEnabled:NO];
    }else{
        [descriptionFieldMatrix selectCellWithTag:1];
        [descriptionFieldTextField setEnabled:YES];
        [descriptionFieldTextField setStringValue:[defaults objectForKey:BDSKRSSDescriptionFieldKey]];
    }
}

- (IBAction)autoSaveAsRSSChanged:(id)sender{
    [defaults setInteger:[sender state] forKey:BDSKAutoSaveAsRSSKey];
}

- (IBAction)descriptionFieldChanged:(id)sender{
    int selTag = [[sender selectedCell] tag];
    switch(selTag){
        case 0:
            // use Rss-
            //BDSKRSSDescriptionFieldKey
            [defaults setObject:BDSKRssDescriptionString
                         forKey:BDSKRSSDescriptionFieldKey];
            break;
        case 1:
            [defaults setObject:[descriptionFieldTextField stringValue]
                         forKey:BDSKRSSDescriptionFieldKey];
            break;
    }
    [self updateUI];
}

- (void)controlTextDidChange:(NSNotification *)aNotification{
    [defaults setObject:[descriptionFieldTextField stringValue]
                 forKey:BDSKRSSDescriptionFieldKey];
}

@end
