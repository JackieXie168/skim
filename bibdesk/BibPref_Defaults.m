#import "BibPref_Defaults.h"

@implementation BibPref_Defaults

- (void)awakeFromNib{
    [super awakeFromNib];

    defaultFieldsArray = [[NSMutableArray arrayWithCapacity:6] retain];
    [defaultFieldsArray setArray:[defaults arrayForKey:BDSKDefaultFieldsKey]];
    
}

- (void)updateUI{
    [outputTemplateFileButton setTitle:[[defaults stringForKey:BDSKOutputTemplateFileKey] stringByAbbreviatingWithTildeInPath]];
}


- (void)dealloc{
    [defaultFieldsArray release];
}


#pragma mark ||  Methods to support table view of default fields.

- (int)numberOfRowsInTableView:(NSTableView *)tView{
    return [defaultFieldsArray count];
}
    - (id)tableView:(NSTableView *)tView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    return [defaultFieldsArray objectAtIndex:row];
}
    // defaultFieldStuff
- (IBAction)delSelectedDefaultField:(id)sender{
    if([defaultFieldsTableView numberOfSelectedRows] != 0){
        [defaultFieldsArray removeObjectAtIndex:[defaultFieldsTableView selectedRow]];
        [defaultFieldsTableView reloadData];
        [defaults setObject:defaultFieldsArray
                     forKey:BDSKDefaultFieldsKey];
    }
}
- (IBAction)addDefaultField:(id)sender{
    [defaultFieldsArray addObject:[addFieldField stringValue]];
    [defaultFieldsTableView reloadData];
    [defaults setObject:defaultFieldsArray
                 forKey:BDSKDefaultFieldsKey];
    [addFieldField setStringValue:@""];
}
    // changes the template file:
- (IBAction)outputTemplateButtonPressed:(id)sender{
    [[NSWorkspace sharedWorkspace] openFile:
        [[defaults stringForKey:BDSKOutputTemplateFileKey] stringByExpandingTildeInPath]
                            withApplication:@"TextEdit"];
}

@end
