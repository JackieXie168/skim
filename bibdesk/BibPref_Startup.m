//
//  BibPref_Startup.m
//  Bibdesk
//
//  Created by Michael McCracken on Sat Jun 01 2002.
//  Copyright (c) 2002 Michael McCracken. All rights reserved.
//

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
    [defaults setBool:([sender state] == NSOnState) ? YES : NO forKey:BDSKShowWarningsKey];
    if ([sender state] == NSOnState) {
        [[NSApp delegate] showErrorPanel:self];
    }else{
        [[NSApp delegate] hideErrorPanel:self];
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
