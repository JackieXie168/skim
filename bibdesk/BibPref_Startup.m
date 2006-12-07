//  BibPref_Startup.m

//  Created by Michael McCracken on Sat Jun 01 2002.
/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BibPref_Startup.h"


@implementation BibPref_Startup
- (void)updateUI{
    [defaultBibFileField setStringValue:[[defaults objectForKey:BDSKDefaultBibFilePathKey] stringByAbbreviatingWithTildeInPath]];
    [startupBehaviorRadio selectCellWithTag:[[defaults objectForKey:BDSKStartupBehaviorKey] intValue]];
    prevStartupBehaviorTag = [[defaults objectForKey:BDSKStartupBehaviorKey] intValue];
    [showErrorsCheckButton setState:
([defaults boolForKey:BDSKShowWarningsKey] == YES) ? NSOnState : NSOffState  ];
}

- (void)setValueForSender:(id)sender{
    // ?
}


- (void)becomeCurrentPreferenceClient{
//    NSLog(@"not sure - becomecurrent");
}
- (void)resignCurrentPreferenceClient{
//    NSLog(@"not sure - resigncurrent");
}

- (IBAction)toggleShowWarnings:(id)sender{
    BibAppController *ac = (BibAppController *)[NSApp delegate];
    [defaults setBool:([sender state] == NSOnState) ? YES : NO forKey:BDSKShowWarningsKey];
    if ([sender state] == NSOnState) {
        [ac showErrorPanel:self];
    }else{
        [ac hideErrorPanel:self];
    }        
}

- (IBAction)changeStartupBehavior:(id)sender{
    int n = [[sender selectedCell] tag];
    NSOpenPanel *openPanel = nil;
    NSString *path;
    [defaults setObject:[NSNumber numberWithInt:n] forKey:BDSKStartupBehaviorKey];
    
    if (n == 3) {
        openPanel = [NSOpenPanel openPanel];
        if ([openPanel runModalForTypes:[NSArray arrayWithObject:@"bib"]] != NSOKButton)
        {
            [startupBehaviorRadio selectCellWithTag:prevStartupBehaviorTag];
            return;
        }
        path = [[openPanel filenames] objectAtIndex: 0];
        [defaultBibFileField setStringValue:[path stringByAbbreviatingWithTildeInPath]];
        [defaults setObject:path forKey:BDSKDefaultBibFilePathKey];
        [defaults setObject:path forKey:@"NSOpen"]; // -- what did this do?
    }else{
        prevStartupBehaviorTag = n;
    }
    [defaults synchronize];
}
@end
