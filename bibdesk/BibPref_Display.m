/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BibPref_Display.h"

@implementation BibPref_Display

- (void)awakeFromNib{
    [super awakeFromNib];

    showColsArray = [[NSMutableArray arrayWithCapacity:6] retain];
    [showColsArray setArray:[defaults arrayForKey:BDSKShowColsKey]];
    [[NSNotificationCenter defaultCenter]
addObserver:self
   selector:@selector(handleFontChangedNotification:)
       name:BDSKTableViewFontChangedNotification
     object:nil];
}

- (void)updateUI{
    NSFont *tableViewFont = [NSFont fontWithName:[defaults objectForKey:BDSKTableViewFontKey]
                                    size:[defaults floatForKey:BDSKTableViewFontSizeKey]];

    [fontPreviewField setStringValue:[[tableViewFont displayName] stringByAppendingFormat:@" %.0f",[tableViewFont pointSize]]];
    [fontPreviewField setFont:tableViewFont];

    [displayPrefRadioMatrix selectCellWithTag:[defaults integerForKey:BDSKPreviewDisplayKey]];

    // update Fri 07/26/02 - i replaced this with contextual menu handling, but I'm not sure if i can just delete it all, so I'm leaving it as is for now.
    [showColsButtons setState:[[showColsArray objectAtIndex:0] intValue] atRow:0 column:0];    // citekey
    [showColsButtons setState:[[showColsArray objectAtIndex:2] intValue] atRow:1 column:0];    // date
    [showColsButtons setState:[[showColsArray objectAtIndex:3] intValue] atRow:2 column:0];    // a1
    [showColsButtons setState:[[showColsArray objectAtIndex:4] intValue] atRow:3 column:0];    // a2
    [showColsButtons setState:[[showColsArray objectAtIndex:5] intValue] atRow:4 column:0];    // a3
    
}

- (IBAction)changePreviewDisplay:(id)sender{
    int tag = [[sender selectedCell] tag];
    if(tag != [defaults integerForKey:BDSKPreviewDisplayKey]){
        switch(tag){
            case 0:
                // show everything
                [defaults setInteger:tag forKey:BDSKPreviewDisplayKey];
                break;
            case 1:
                // show only annote
                [defaults setInteger:tag forKey:BDSKPreviewDisplayKey];
                break;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKPreviewDisplayChangedNotification object:nil];
            }
}

- (IBAction)changeShownColumns:(id)sender{
    // 0,1,2,3,4,5 = citekey, title(shouldn't change), date,auth1,auth2,auth3
    int n = [[sender selectedCell] tag];
    if([[sender selectedCell] state] == NSOnState){
        [showColsArray replaceObjectAtIndex:n
                                 withObject:[NSNumber numberWithInt:1]];
    }else{
        [showColsArray replaceObjectAtIndex:n
                                 withObject:[NSNumber numberWithInt:0]];
    }
    [defaults setObject:showColsArray forKey:BDSKShowColsKey];
    [[[NSDocumentController sharedDocumentController] documents]
makeObjectsPerformSelector:@selector(updateUI)];
}

- (IBAction)chooseFont:(id)sender{
    NSFont *oldFont = [NSFont fontWithName:
        [defaults objectForKey:BDSKTableViewFontKey]
                                      size:
        [defaults floatForKey:BDSKTableViewFontSizeKey]];
    [[NSFontManager sharedFontManager] setSelectedFont:oldFont isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (void)handleFontChangedNotification:(NSNotification *)notification{
    NSFont *font =
    [NSFont fontWithName:[defaults objectForKey:BDSKTableViewFontKey]
                    size:[defaults floatForKey:BDSKTableViewFontSizeKey]];
    //NSLog(@"%@", font);
    [fontPreviewField setStringValue:
        [[font displayName] stringByAppendingFormat:@" %.0f",[font pointSize]]];
    [fontPreviewField setFont:font];
}

// changeFont is deprecated here.
// this same code (mostly) is in the BibAppController now.
// we just listen for a notification about the font change so we can change the previewfield.
- (void)changeFont:(id)fontManager{
    NSFont *newFont;
    NSFont *oldFont =
        [NSFont fontWithName:[defaults objectForKey:BDSKTableViewFontKey]
                        size:[defaults floatForKey:BDSKTableViewFontSizeKey]];

    newFont = [[NSFontPanel sharedFontPanel] panelConvertFont:oldFont];
    [defaults setObject:[newFont fontName] forKey:BDSKTableViewFontKey];
    [defaults setFloat:[newFont pointSize] forKey:BDSKTableViewFontSizeKey];
    [fontPreviewField setStringValue:
        [[newFont displayName] stringByAppendingFormat:@" %.0f",[newFont pointSize]]];
    // make it have live updates:
    //  [[[NSDocumentController sharedDocumentController] documents]
    //makeObjectsPerformSelector:@selector(updateUI)];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKTableViewFontChangedNotification
                                                            object:nil];
}

- (void)dealloc{
    [showColsArray release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
