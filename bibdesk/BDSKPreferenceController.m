//
//  BDSKPreferenceController.m
//  Bibdesk
//
//  Created by Adam Maxwell on 05/04/06.
/*
 This software is Copyright (c) 2006,2007
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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

#import "BDSKPreferenceController.h"
#import "BDSKOverlay.h"
#import <OmniAppKit/OAPreferencesIconView.h>
#import <OmniAppKit/NSToolbar-OAExtensions.h>
#import <OmniAppKit/OAPreferenceClient.h>

@interface NSArray (PreferencesSearch)
- (BOOL)containsCaseInsensitiveSubstring:(NSString *)substring;
@end

@implementation NSArray (PreferencesSearch)

- (BOOL)containsCaseInsensitiveSubstring:(NSString *)substring;
{
    unsigned idx = [self count];
    NSString *aString;
    while(idx--){
        aString = [self objectAtIndex:idx];
        if([aString rangeOfString:substring options:NSCaseInsensitiveSearch].length > 0)
            return YES;
    }
    return NO;
}

@end

@interface OAPreferenceController (PrivateMethods)
- (void)_showAllIcons:(id)sender;
@end

static NSString *BDSKPreferencesSearchField = @"BDSKPreferencesSearchField";

@implementation BDSKPreferenceController

+ (id)sharedPreferenceController;
{
    static id sharedController = nil;

    if(nil == sharedController)
        sharedController = [[self alloc] init];
    
    return sharedController;
}

- (id)init
{
    if(self = [super init]){
        isSearchActive = NO;
        NSString *path = [[NSBundle mainBundle] pathForResource:@"PreferenceSearchTerms" ofType:@"plist"];
        if(nil == path)
            [NSException raise:NSInternalInconsistencyException format:@"unable to find search terms dictionary"];
        clientIdentiferSearchTerms = [[NSDictionary alloc] initWithContentsOfFile:path];
    }
    return self;
}

- (void)dealloc
{
    [clientIdentiferSearchTerms release];
    [searchTerm release];
    [overlay release];
    [super dealloc];
}

- (void)awakeFromNib;
{
    // OAPreferenceController may implement this in future
    if ([[self superclass] instancesRespondToSelector:_cmd])
        [super awakeFromNib];
    
    NSWindow *theWindow = [self window];
    NSRect contentRect = [theWindow contentRectForFrameRect:[theWindow frame]];
        
    overlay = [[BDSKOverlayWindow alloc] initWithContentRect:contentRect styleMask:[theWindow styleMask] backing:[theWindow backingType] defer:YES];
    [overlay setReleasedWhenClosed:NO];

    NSView *view = [[BDSKSpotlightView alloc] initWithFrame:contentRect delegate:self];
    [overlay setContentView:view];
    [view release];
    [overlay overlayView:[theWindow contentView]];
    [theWindow setShowsToolbarButton:NO];
}

- (void)iconView:(OAPreferencesIconView *)iconView buttonHitAtIndex:(unsigned int)index;
{
    isSearchActive = NO;
    [[overlay contentView] setNeedsDisplay:YES];
    [super iconView:iconView buttonHitAtIndex:index];
}

- (IBAction)showPreferencesPanel:(id)sender;
{
    [super showPreferencesPanel:sender];
    [overlay orderFront:nil];
    
    // Sys Prefs gives focus to the search field when launching
    NSEnumerator *tbEnumerator = [[[[self window] toolbar] items] objectEnumerator];
    id anItem;
    while(anItem = [tbEnumerator nextObject]){
        if([[anItem itemIdentifier] isEqual:BDSKPreferencesSearchField])
            [[self window] makeFirstResponder:[anItem view]];
    }
}

- (BOOL)isSearchActive { return isSearchActive; }

static NSRect insetButtonRectAndShift(const NSRect aRect)
{
    // convert to a square
    float side = MAX(NSHeight(aRect), NSWidth(aRect));
    NSPoint center = NSMakePoint(NSMidX(aRect), NSMidY(aRect));
    
    // raise to account for the text; this is the button rect
    // @@ resolution independence
    center.y += 10;
    
    return NSInsetRect(NSMakeRect(center.x - 0.5f * side, center.y - 0.5f * side, side, side), 10, 10);
}

static inline NSRect convertRectInWindowToScreen(NSRect aRect, NSWindow *window)
{
    NSPoint pt = [window convertBaseToScreen:aRect.origin];
    aRect.origin = pt;
    return aRect;
}

- (NSArray *)highlightRectsInScreenCoordinates;
{
    // we have an array of OAPreferencesIconViews; one per category (row)
    NSEnumerator *viewE = [preferencesIconViews objectEnumerator];
    OAPreferencesIconView *view;
    NSMutableArray *rectArray = [NSMutableArray arrayWithCapacity:10];
    NSWindow *theWindow = [self window];
    
    while(view = [viewE nextObject]){
        
        // get the preference client records; these are basically plists for each pref pane
        NSArray *records = [view preferenceClientRecords];
        unsigned i, numberOfRecords = [records count];
        NSString *identifier;
        
        for(i = 0; i < numberOfRecords; i++){
            
            
            NSArray *array = nil;
            identifier = [[records objectAtIndex:i] identifier];

            OBPRECONDITION(identifier != nil);
            if(nil != identifier)
                array = [clientIdentiferSearchTerms objectForKey:identifier];
            OBPOSTCONDITION(array != nil);
            
            if(array != nil && [array containsCaseInsensitiveSubstring:searchTerm]){
                // this is a private method, but declared in the header
                NSRect rect = [view _boundsForIndex:i];
                
                // convert to screen coordinates
                rect = convertRectInWindowToScreen([view convertRect:rect toView:nil], theWindow);
                [rectArray addObject:[NSValue valueWithRect:insetButtonRectAndShift(rect)]];
            }
        }
    }
        
    return rectArray;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)tb;
{
    NSMutableArray *array = [NSMutableArray arrayWithArray:[super toolbarDefaultItemIdentifiers:tb]];
    [array addObject:BDSKPreferencesSearchField];
    return array;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)tb;
{
    NSMutableArray *array = [NSMutableArray arrayWithArray:[super toolbarAllowedItemIdentifiers:tb]];
    [array addObject:BDSKPreferencesSearchField];
    return array;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)tb;
{
    NSMutableArray *array = [NSMutableArray arrayWithArray:[super toolbarSelectableItemIdentifiers:tb]];
    [array removeObject:BDSKPreferencesSearchField];
    return array;
}

- (void)setSearchTerm:(NSString *)term;
{
    [searchTerm autorelease];
    searchTerm = [term copy];
}    

- (void)search:(id)sender;
{
    NSString *term = [sender stringValue];

    if([[[preferenceBox contentView] subviews] lastObject] != showAllIconsView){
        // this method will lose our first responder
        if([self respondsToSelector:@selector(_showAllIcons:)])
            [self _showAllIcons:nil];
        [[self window] makeFirstResponder:sender];
        
        // we just lost the insertion point; if the user just started typing, it should be at the end
        NSText *editor = (NSText *)[[self window] firstResponder];
        if(nil != editor && [editor isKindOfClass:[NSText class]])
            [editor setSelectedRange:NSMakeRange([term length], 0)];
    }

    isSearchActive = ([term isEqualToString:@""] || nil == term) ? NO : YES;
    [self setSearchTerm:[sender stringValue]];
    
    // the view will now ask us which icons to highlight
    [[overlay contentView] setNeedsDisplay:YES];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)tb itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
{
    NSToolbarItem *tbItem = nil;
    if([itemIdentifier isEqual:BDSKPreferencesSearchField]){
        tbItem = [[NSToolbarItem alloc] initWithItemIdentifier:BDSKPreferencesSearchField];
        NSSearchField *searchField = [[NSSearchField alloc] initWithFrame:NSMakeRect(0, 0, 30, 22)];
        [searchField setTarget:self];
        [searchField setAction:@selector(search:)];
        
        [tbItem setAction:@selector(search:)];
        [tbItem setTarget:self];
        [tbItem setMinSize:NSMakeSize(60, NSHeight([searchField frame]))];
        [tbItem setMaxSize:NSMakeSize(NSWidth([[self window] frame])/3,NSHeight([searchField frame]))];
        [tbItem setView:searchField];
        [searchField release];
        
        [tbItem setLabel:NSLocalizedString(@"Search", @"Toolbar item label")];
        [tbItem setPaletteLabel:NSLocalizedString(@"Search", @"Toolbar item label")];
        [tbItem setEnabled:YES];
        [tbItem autorelease];
    }        
    else tbItem = [super toolbar:tb itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
    
    return tbItem;
}

@end
