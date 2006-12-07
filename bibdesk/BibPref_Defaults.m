// BibPref_Defaults.m
// Created by Michael McCracken, 2002
/*
 This software is Copyright (c) 2002,2003,2004,2005
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

#import "BibPref_Defaults.h"
#import "BDSKTypeInfoEditor.h"

@implementation BibPref_Defaults

- (void)awakeFromNib{
    [super awakeFromNib];

    defaultFieldsArray = [[NSMutableArray arrayWithCapacity:6] retain];
    [defaultFieldsArray setArray:[defaults arrayForKey:BDSKDefaultFieldsKey]];
    BDSKFieldNameFormatter *fieldNameFormatter = [[BDSKFieldNameFormatter alloc] init];
    [RSSDescriptionFieldTextField setFormatter:fieldNameFormatter];
    [[[[defaultFieldsTableView tableColumns] objectAtIndex:0] dataCell] setFormatter:fieldNameFormatter];
    [fieldNameFormatter release];
    
}

- (void)updateUI{
    [defaultFieldsTableView reloadData];
    [defaults setObject:defaultFieldsArray forKey:BDSKDefaultFieldsKey];
    
    if ([[defaults objectForKey:BDSKRSSDescriptionFieldKey] isEqualToString:BDSKRssDescriptionString]) {
        [RSSDescriptionFieldMatrix selectCellWithTag:0];
        [RSSDescriptionFieldTextField setEnabled:NO];
    }else{
		[RSSDescriptionFieldTextField setStringValue:[defaults objectForKey:BDSKRSSDescriptionFieldKey]];
        [RSSDescriptionFieldMatrix selectCellWithTag:1];
        [RSSDescriptionFieldTextField setEnabled:YES];
    }
}


- (void)dealloc{
    [defaultFieldsArray release];
    [super dealloc];
}


#pragma mark ||  Methods to support table view of default fields.

- (int)numberOfRowsInTableView:(NSTableView *)tView{
    return [defaultFieldsArray count];
}

- (id)tableView:(NSTableView *)tView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    return [defaultFieldsArray objectAtIndex:row];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    if([object isEqualToString:@""])
        [defaultFieldsArray removeObjectAtIndex:row];
    else
        [defaultFieldsArray replaceObjectAtIndex:row withObject:object];
    [self updateUI];
}

    // defaultFieldStuff
- (IBAction)delSelectedDefaultField:(id)sender{
    if([defaultFieldsTableView numberOfSelectedRows] != 0){
        [defaultFieldsArray removeObjectAtIndex:[defaultFieldsTableView selectedRow]];
        [self updateUI];
    }
}
- (IBAction)addDefaultField:(id)sender{
    NSString *newField = @"Field"; // do not localize
    [defaultFieldsArray addObject:newField];
    int row = [defaultFieldsArray count] - 1;
    [defaultFieldsTableView reloadData];
    [defaultFieldsTableView selectRow:row byExtendingSelection:NO];
    [defaultFieldsTableView editColumn:0 row:row withEvent:nil select:YES];
}

- (IBAction)showTypeInfoEditor:(id)sender{
    [[BDSKTypeInfoEditor sharedTypeInfoEditor] showWindow:self];
}

- (IBAction)RSSDescriptionFieldChanged:(id)sender{
    int selTag = [[sender selectedCell] tag];
    switch(selTag){
        case 0:
            // use Rss-
            //BDSKRSSDescriptionFieldKey
            [defaults setObject:BDSKRssDescriptionString
                         forKey:BDSKRSSDescriptionFieldKey];
			break;
        case 1:
            [defaults setObject:[[RSSDescriptionFieldTextField stringValue] capitalizedString]
                         forKey:BDSKRSSDescriptionFieldKey];
            break;
    }
    [self updateUI];
}

- (void)controlTextDidChange:(NSNotification *)aNotification{
	if ([aNotification object] == RSSDescriptionFieldTextField) {
		[defaults setObject:[[RSSDescriptionFieldTextField stringValue] capitalizedString]
					 forKey:BDSKRSSDescriptionFieldKey];
		[self updateUI];
	}
}

@end
