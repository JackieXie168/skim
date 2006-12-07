/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BibPref_Cite.h"

@implementation BibPref_Cite
- (void)awakeFromNib{
    [super awakeFromNib];

    customStringArray = [[NSMutableArray arrayWithCapacity:6] retain];
    [customStringArray setArray:[defaults arrayForKey:BDSKCustomCiteStringsKey]];
}


- (void)updateUI{
    NSString *citeString = [defaults stringForKey:BDSKCiteStringKey];
	NSString *startCiteBracket = [defaults stringForKey:BDSKCiteStartBracketKey]; 
	NSString *endCiteBracket = [defaults stringForKey:BDSKCiteEndBracketKey]; 
	
	if([startCiteBracket isEqualToString:@"{"]){
		
	}

    [dragCopyRadio selectCellWithTag:[defaults integerForKey:BDSKDragCopyKey]];
    [separateCiteCheckButton setState:[defaults integerForKey:BDSKSeparateCiteKey]];
    [citeStringField setStringValue:citeString];
    if([separateCiteCheckButton state] == NSOnState){
        [citeBehaviorLine setStringValue:[NSString stringWithFormat:@"\\%@%@key1%@ \\%@%@key2%@",citeString, startCiteBracket, endCiteBracket,
			citeString, startCiteBracket,endCiteBracket]];
	}else{
		[citeBehaviorLine setStringValue:[NSString stringWithFormat:@"\\%@%@key1, key2%@" ,citeString, startCiteBracket, endCiteBracket]];
	}
  //  [editOnPasteButton setState:[defaults integerForKey:BDSKEditOnPasteKey]];
}

- (IBAction)changeCopyBehavior:(id)sender{
    [defaults setInteger:[[sender selectedCell] tag] forKey:BDSKDragCopyKey];
}

- (IBAction)changeSeparateCite:(id)sender{
    [defaults setInteger:[sender state] forKey:BDSKSeparateCiteKey];
	[self updateUI];
}
    - (IBAction)citeStringFieldChanged:(id)sender{
    [defaults setObject:[sender stringValue] forKey:BDSKCiteStringKey];
    [self changeSeparateCite:separateCiteCheckButton];
}

/*
 - (IBAction)changeEditOnPaste:(id)sender{
    [defaults setInteger:[sender state] forKey:BDSKEditOnPasteKey];
}
*/

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

- (IBAction)setCitationBracketStyle:(id)sender{
	// 1 - tex 2 - context
	int tag = [[sender selectedCell] tag];
	if(tag == 1){
		[defaults setObject:@"{" forKey:BDSKCiteStartBracketKey];
		[defaults setObject:@"}" forKey:BDSKCiteEndBracketKey];
	}else if(tag == 2){
		[defaults setObject:@"[" forKey:BDSKCiteStartBracketKey];
		[defaults setObject:@"]" forKey:BDSKCiteEndBracketKey];
	}
	[self updateUI];
}

@end
