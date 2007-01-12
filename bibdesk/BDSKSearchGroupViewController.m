//
//  BDSKSearchGroupViewController.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 1/2/07.
/*
 This software is Copyright (c) 2007
 Christiaan Hofman. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Christiaan Hofman nor the names of any
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

#import "BDSKSearchGroupViewController.h"
#import "BDSKSearchGroup.h"
#import "BDSKCollapsibleView.h"
#import "BDSKEdgeView.h"


@implementation BDSKSearchGroupViewController

- (NSString *)windowNibName { return @"BDSKSearchGroupView"; }

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [group release];
    [super dealloc];
}

- (void)awakeFromNib {
    [view setMinSize:[view frame].size];
    [edgeView setEdges:BDSKMinXEdgeMask | BDSKMaxXEdgeMask];
}

- (void)updateSearchView {
    OBASSERT(group);
    [self window];
    NSString *name = [[group serverInfo] name];
    [searchField setStringValue:[group searchTerm] ? [group searchTerm] : @""];
    [searchField setRecentSearches:[group history]];
    [searchButton setEnabled:[group isRetrieving] == NO];
    [[searchField cell] setPlaceholderString:[NSString stringWithFormat:NSLocalizedString(@"Search %@", @"search group field placeholder"), name ? name : @""]];
    [searchField setFormatter:[group searchStringFormatter]];
    [searchField selectText:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSearchGroupUpdatedNotification:) name:BDSKSearchGroupUpdatedNotification object:group];
}

- (NSView *)view {
    [self window];
    return view;
}

- (BDSKSearchGroup *)group {
    return group;
}

- (void)setGroup:(BDSKSearchGroup *)newGroup {
    if (group != newGroup) {
        if (group)
            [[NSNotificationCenter defaultCenter] removeObserver:self name:BDSKSearchGroupUpdatedNotification object:group];
        
        [group release];
        group = [newGroup retain];
        
        if (group)
            [self updateSearchView];
    }
}

- (IBAction)changeSearchTerm:(id)sender {
    [group setSearchTerm:[sender stringValue]];
    [group setHistory:[sender recentSearches]];
}

- (IBAction)nextSearch:(id)sender {
    [self changeSearchTerm:searchField];
    [group search];
}

- (IBAction)searchHelp:(id)sender{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"Searching-External-Databases" inBook:@"BibDesk Help"];
}

- (BOOL)control:(NSControl *)control didFailToFormatString:(NSString *)aString errorDescription:(NSString *)error {
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Invalid search string syntax", @"") defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:error];
    [alert beginSheetModalForWindow:[view window] modalDelegate:nil didEndSelector:nil contextInfo:NULL];
    return YES;
}

- (void)handleSearchGroupUpdatedNotification:(NSNotification *)notification{
    [searchButton setEnabled:[group isRetrieving] == NO];
}

@end
