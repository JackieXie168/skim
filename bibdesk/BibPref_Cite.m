#import "BibPref_Cite.h"

@implementation BibPref_Cite
- (void)awakeFromNib{
    [super awakeFromNib];

    customStringArray = [[NSMutableArray arrayWithCapacity:6] retain];
    [customStringArray setArray:[defaults arrayForKey:BDSKCustomCiteStringsKey]];

}
- (void)updateUI{
    NSString *citeString = [defaults stringForKey:BDSKCiteStringKey];

    [dragCopyRadio selectCellWithTag:[defaults integerForKey:BDSKDragCopyKey]];
    [separateCiteCheckButton setState:[defaults integerForKey:BDSKSeparateCiteKey]];
    [citeStringField setStringValue:citeString];
    if([separateCiteCheckButton state] == NSOnState)
        [citeBehaviorLine setStringValue:[NSString stringWithFormat:@"\\%@{key1} \\%@{key2}",citeString, citeString]];
    else
        [citeBehaviorLine setStringValue:[NSString stringWithFormat:@"\\%@{key1, key2}" , citeString]];
    [editOnPasteButton setState:[defaults integerForKey:BDSKEditOnPasteKey]];
}

- (IBAction)changeCopyBehavior:(id)sender{
    [defaults setInteger:[[sender selectedCell] tag] forKey:BDSKDragCopyKey];
}

- (IBAction)changeSeparateCite:(id)sender{
    NSString *cs = [defaults stringForKey:BDSKCiteStringKey];
    if([sender state] == NSOnState){
        [citeBehaviorLine setStringValue:[NSString stringWithFormat:@"\\%@{key1} \\%@{key2}",cs, cs]];
            }else{
                [citeBehaviorLine setStringValue:[NSString stringWithFormat:@"\\%@{key1, key2}" , cs]];
                    }
    [defaults setInteger:[sender state] forKey:BDSKSeparateCiteKey];
}
    - (IBAction)citeStringFieldChanged:(id)sender{
    [defaults setObject:[sender stringValue] forKey:BDSKCiteStringKey];
    [self changeSeparateCite:separateCiteCheckButton];
}

- (IBAction)changeEditOnPaste:(id)sender{
    [defaults setInteger:[sender state] forKey:BDSKEditOnPasteKey];
}

#pragma mark ||  Methods to support table view of custom strings.

- (IBAction)addCustomString:(id)sender{
    [customStringArray addObject:[customStringField stringValue]];
    [customStringTableView reloadData];
    [defaults setObject:customStringArray
                 forKey:BDSKCustomCiteStringsKey];
    [customStringField setStringValue:@""];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKCustomStringsChangedNotification
                                                        object:nil];
}

- (IBAction)delSelectedCustomString:(id)sender{
    if([customStringTableView numberOfSelectedRows] != 0){
        [customStringArray removeObjectAtIndex:[customStringTableView selectedRow]];
        [customStringTableView reloadData];
        [defaults setObject:customStringArray
                     forKey:BDSKCustomCiteStringsKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKCustomStringsChangedNotification
                                                            object:nil];
    }
}


- (int)numberOfRowsInTableView:(NSTableView *)tView{
    return [customStringArray count];
}
- (id)tableView:(NSTableView *)tView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    return [customStringArray objectAtIndex:row];
}


@end
