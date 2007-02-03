//
//  BDSKWebGroupViewController.m
//  Bibdesk
//
//  Created by Michael McCracken on 1/26/07.

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
 
 - Neither the name of Michael McCracken nor the names of any
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

#import "BDSKWebGroupViewController.h"
#import <WebKit/WebKit.h>
#import "BDSKHCiteParser.h"
#import "BDSKWebGroup.h"
#import "BDSKCollapsibleView.h"
#import "BDSKEdgeView.h"
#import "NSFileManager_BDSKExtensions.h"


@implementation BDSKWebGroupViewController

- (id)init {
    if (self = [super init]) {
		bookmarks = [[NSMutableArray alloc] init];
		
        NSString *applicationSupportPath = [[NSFileManager defaultManager] currentApplicationSupportPathForCurrentUser]; 
		NSString *bookmarksPath = [applicationSupportPath stringByAppendingPathComponent:@"Bookmarks.plist"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:bookmarksPath]) {
			NSEnumerator *bEnum = [[NSArray arrayWithContentsOfFile:bookmarksPath] objectEnumerator];
			NSDictionary *bm;
			while(bm = [bEnum nextObject])
				[bookmarks addObject:[[bm mutableCopy] autorelease]];
		}
    }
    return self;
}

- (NSString *)windowNibName { return @"BDSKWebGroupView"; }

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [group release];
    [bookmarks release];
    [super dealloc];
}

- (void)awakeFromNib {
    [view setMinSize:[view frame].size];
    [edgeView setEdges:BDSKMinXEdgeMask | BDSKMaxXEdgeMask];
    [webEdgeView setEdges:BDSKEveryEdgeMask];
    [backButton setImagePosition:NSImageOnly];
    [backButton setImage:[NSImage imageNamed:@"back_small"]];
    [forwardButton setImagePosition:NSImageOnly];
    [forwardButton setImage:[NSImage imageNamed:@"forward_small"]];
    [stopOrReloadButton setImagePosition:NSImageOnly];
    [stopOrReloadButton setImage:[NSImage imageNamed:@"reload_small"]];
	[urlComboBox removeAllItems];
    [urlComboBox addItemsWithObjectValues:[bookmarks valueForKey:@"URLString"]];
}

- (void)handleWebGroupUpdatedNotification:(NSNotification *)notification{
    // ?
}

- (void)updateWebGroupView {
    OBASSERT(group);
    [self window];

    [[urlComboBox cell] setPlaceholderString:NSLocalizedString(@"URL ", @"Web group URL field placeholder")];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWebGroupUpdatedNotification:) name:BDSKWebGroupUpdatedNotification object:group];
}

- (NSView *)view {
    [self window];
    return view;
}

- (NSView *)webView {
    [self window];
    return webEdgeView;
}

- (BDSKWebGroup *)group {
    return group;
}

- (void)setGroup:(BDSKWebGroup *)newGroup {
    if (group != newGroup) {
        if (group)
            [[NSNotificationCenter defaultCenter] removeObserver:self name:BDSKWebGroupUpdatedNotification object:group];
        
        [group release];
        group = [newGroup retain];
        
        if (group)
            [self updateWebGroupView];
    }
}

- (IBAction)changeURL:(id)sender {
    [webView takeStringURLFrom:sender];
}

- (IBAction)stopOrReloadAction:(id)sender {
	if ([group isRetrieving]) {
		[webView stopLoading:sender];
	} else {
		[webView reload:sender];
	}
}

- (void)setRetrieving:(BOOL)retrieving {
    [group setRetrieving:retrieving];
    [backButton setEnabled:[webView canGoBack]];
    [forwardButton setEnabled:[webView canGoForward]];
    [stopOrReloadButton setEnabled:YES];
    if (retrieving) {
        [stopOrReloadButton setImage:[NSImage imageNamed:@"stop_small"]];
        [stopOrReloadButton setToolTip:NSLocalizedString(@"Cancel download", @"Tool tip message")];
        [stopOrReloadButton setKeyEquivalent:@""];
    } else {
        [stopOrReloadButton setImage:[NSImage imageNamed:@"reload_small"]];
        [stopOrReloadButton setToolTip:NSLocalizedString(@"Reload page", @"Tool tip message")];
        [stopOrReloadButton setKeyEquivalent:@"r"];
    }
}

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame{
    
    if (frame == [sender mainFrame]) {
        
        OBASSERT(loadingWebFrame == nil);
        
        [self setRetrieving:YES];
        [group setPublications:nil];
        loadingWebFrame = frame;
        
    } else if (loadingWebFrame == nil) {
        
        [self setRetrieving:YES];
        loadingWebFrame = frame;
        
    }
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame{

    NSString *htmlString = [(id)[[frame DOMDocument] documentElement] outerHTML];
    
    NSError *err = nil;
    NSArray *newPubs = htmlString ? [BDSKHCiteParser itemsFromXHTMLString:htmlString error:&err] : nil;
        
    if (frame == loadingWebFrame) {
        [self setRetrieving:NO];
        [group addPublications:newPubs];
        loadingWebFrame = nil;
    } else {
        [group addPublications:newPubs];
    }
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame{
    if (frame == loadingWebFrame) {
        [self setRetrieving:NO];
        [group addPublications:nil];
        loadingWebFrame = nil;
    }
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame{
    if (frame == loadingWebFrame) {
        [self setRetrieving:NO];
        [group addPublications:nil];
        loadingWebFrame = nil;
    }
}

@end
