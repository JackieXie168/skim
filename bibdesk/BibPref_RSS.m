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
