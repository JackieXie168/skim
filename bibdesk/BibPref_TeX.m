#import "BibPref_TeX.h"

@implementation BibPref_TeX
- (void)updateUI{
    [usesTeXButton setState:[defaults integerForKey:BDSKUsesTeXKey]];
    [self changeUsesTeX:usesTeXButton]; // this makes sure the fields are set enabled / disabled properly

    [texBinaryPath setStringValue:[defaults objectForKey:BDSKTeXBinPathKey]];
    [bibtexBinaryPath setStringValue:[defaults objectForKey:BDSKBibTeXBinPathKey]];
    [bibTeXStyle setStringValue:[defaults objectForKey:BDSKBTStyleKey]];
}

-(IBAction)changeTexBinPath:(id)sender{
    [defaults setObject:[sender stringValue] forKey:BDSKTeXBinPathKey];
}
- (IBAction)changeBibTexBinPath:(id)sender{
    [defaults setObject:[sender stringValue] forKey:BDSKBibTeXBinPathKey];
}

- (IBAction)changeUsesTeX:(id)sender{
    if ([sender state] == NSOffState) {
        [bibTeXStyle setEnabled:NO];
        [texBinaryPath setEnabled:NO];
        [bibtexBinaryPath setEnabled:NO];
        [defaults setInteger:NSOffState forKey:BDSKUsesTeXKey];
    }else{
        [bibTeXStyle setEnabled:YES];
        [texBinaryPath setEnabled:YES];
        [bibtexBinaryPath setEnabled:YES];
        [defaults setInteger:NSOnState forKey:BDSKUsesTeXKey];
    }
}

- (IBAction)changeStyle:(id)sender{
    [defaults setObject:[sender stringValue] forKey:BDSKBTStyleKey];
}

@end
