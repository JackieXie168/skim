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
#import "BDSKWebParser.h"
#import "BDSKWebGroup.h"
#import "BDSKCollapsibleView.h"
#import "BDSKEdgeView.h"
#import "NSFileManager_BDSKExtensions.h"
#import "BibDocument.h"


@implementation BDSKWebGroupViewController

- (id)initWithGroup:(BDSKWebGroup *)aGroup document:(BibDocument *)aDocument {
    if (self = [super init]) {
        [self setGroup:aGroup];
        document = aDocument;
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
    [[urlComboBox cell] setPlaceholderString:NSLocalizedString(@"URL", @"Web group URL field placeholder")];
}

- (void)handleWebGroupUpdatedNotification:(NSNotification *)notification{
    // ?
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
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWebGroupUpdatedNotification:) name:BDSKWebGroupUpdatedNotification object:group];
    }
}

- (IBAction)changeURL:(id)sender {
	NSString *URLString = [[[[[webView mainFrame] dataSource] request] URL] absoluteString];
    if ([NSString isEmptyString:[sender stringValue]] == NO && [[sender stringValue] isEqualToString:URLString] == NO)
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

#pragma mark WebFrameLoadDelegate protocol

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

	NSURL *url = [[[frame dataSource] request] URL];
    DOMDocument *domDocument = [frame DOMDocument];
    
    NSError *error = nil;
    NSArray *newPubs = [BDSKWebParser itemsFromDocument:domDocument fromURL:url error:&error];
        
    if (frame == loadingWebFrame) {
        [self setRetrieving:NO];
        [group addPublications:newPubs ? newPubs : [NSArray array]];
        loadingWebFrame = nil;
    } else {
        [group addPublications:newPubs ? newPubs : [NSArray array]];
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

#pragma mark WebUIDelegate protocol

- (void)setStatus:(NSString *)text {
    if ([NSString isEmptyString:text])
        [document updateStatus];
    else 
        [document setStatus:text];
}

- (void)webView:(WebView *)sender setStatusText:(NSString *)text {
    [self setStatus:text];
}

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation modifierFlags:(unsigned int)modifierFlags {
    NSURL *link = [elementInformation objectForKey:WebElementLinkURLKey];
    [self setStatus:[link absoluteString]];
}

@end
