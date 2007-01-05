//
//  BDSKStringEncodingManager.m
//  BibDesk
//
//  Created by Adam Maxwell on 03/01/05.
/*
 This software is Copyright (c) 2005,2006,2007
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

#import "BDSKStringEncodingManager.h"

// this one isn't declared in CFStringEncodingExt.h or CFString.h
enum {
    kBDStringEncodingMacKeyboardSymbol = 0x29
};

#pragma mark -

// EncodingPopUpButton is a subclass of NSPopUpButton which provides the ability to automatically recompute its contents on changes to the encodings list. This allows sprinkling these around the app any have them automatically update themselves.  EncodingPopUpButtonCell is the corresponding cell. It would normally not be needed, but we really want to know when the cell's selectedItem is changed, as we want to prevent the last item ("Customize...") from being selected.
@interface BDSKEncodingPopUpButtonCell : NSPopUpButtonCell
@end

@implementation BDSKEncodingPopUpButtonCell

// Do not allow selecting the "Customize" item and the separator before it. (Note that the customize item can be chosen and an action will be sent, but the selection doesn't change to it.)
- (void)selectItemAtIndex:(int)index {
    if (index + 2 <= [self numberOfItems]) [super selectItemAtIndex:index];
}

@end

#pragma mark -

@implementation BDSKEncodingPopUpButton

+ (Class)cellClass{
    return [BDSKEncodingPopUpButtonCell class];
}

- (id)initWithFrame:(NSRect)frameRect {
	if (self = [super initWithFrame:frameRect]) {
            [self setAutoenablesItems:NO];
            
            defaultEncoding = [BDSKStringEncodingManager defaultEncoding];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEncodingsListChanged:) name:BDSKEncodingsListChangedNotification object:nil];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder{
	if (self = [super initWithCoder:coder]) {
		if ([[self cell] isKindOfClass:[BDSKEncodingPopUpButtonCell class]] == NO) {
            BDSKEncodingPopUpButtonCell *newCell = [[BDSKEncodingPopUpButtonCell alloc] init];
            [newCell setAction:[[self cell] action]];
            [newCell setTarget:[[self cell] target]];
            [newCell setControlSize:[[self cell] controlSize]];
            [newCell setFont:[[self cell] font]];
            [self setCell:newCell];
            [newCell release];

            [self setAutoenablesItems:NO];
            
            defaultEncoding = [BDSKStringEncodingManager defaultEncoding];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEncodingsListChanged:) name:BDSKEncodingsListChangedNotification object:nil];
        }
    }
    return self;
}

- (NSStringEncoding)encoding {
    return [[self selectedItem] tag];
}

- (void)setEncoding:(NSStringEncoding)encoding {
    defaultEncoding = encoding;
    [[BDSKStringEncodingManager sharedEncodingManager] setupPopUp:self selectedEncoding:defaultEncoding];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

// Update contents based on encodings list customization
- (void)handleEncodingsListChanged:(NSNotification *)notification {
    int tag = [[self selectedItem] tag];
    if (tag != 0 && (unsigned)tag != 0) defaultEncoding = tag;
    [[BDSKStringEncodingManager sharedEncodingManager] setupPopUp:self selectedEncoding:defaultEncoding];
}

@end

#pragma mark -

@implementation BDSKStringEncodingManager

static BDSKStringEncodingManager *sharedEncodingManager = nil;

+ (BDSKStringEncodingManager *)sharedEncodingManager{
    if(!sharedEncodingManager){
        sharedEncodingManager = [[BDSKStringEncodingManager alloc] init];
    }
    return sharedEncodingManager;
}

+ (NSStringEncoding)defaultEncoding;
{
    return [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKDefaultStringEncodingKey];
}

-(id)init{
    if(sharedEncodingManager != nil){
        [self release];
        self = sharedEncodingManager;
    } else 
        self = [super init];
    return self;
}

- (void)dealloc{
    if(self != sharedEncodingManager)
        [super dealloc];
}

#pragma mark -

// Improve grouping as for some encodings CFStringGetMostCompatibleMacStringEncoding returns kCFStringEncodingInvalidId 
extern CFStringEncoding BDStringGetMostCompatibleMacStringEncoding(CFStringEncoding encoding) {
    if(encoding == kCFStringEncodingISOLatin6 || encoding == kCFStringEncodingISOLatin8 || encoding == kCFStringEncodingNonLossyASCII || encoding == kCFStringEncodingEBCDIC_CP037)
        return kCFStringEncodingMacRoman;
    else if(encoding == kCFStringEncodingISOLatin10)
        return kCFStringEncodingMacCentralEurRoman;
    else if(encoding == kCFStringEncodingShiftJIS_X0213_00)
        return kCFStringEncodingMacJapanese;
    else if(encoding == kCFStringEncodingBig5_HKSCS_1999 || encoding == kCFStringEncodingBig5_E)
        return kCFStringEncodingMacChineseTrad;
    else if(encoding == kCFStringEncodingGB_18030_2000)
        return kCFStringEncodingMacChineseSimp;
    else if(encoding == kCFStringEncodingKOI8_U)
        return kCFStringEncodingMacCyrillic;
    return CFStringGetMostCompatibleMacStringEncoding(encoding);
}

// Sort using the equivalent Mac encoding as the major key. Secondary key is the actual encoding value, which works well enough. We treat Unicode encodings as special case, putting them at top of the list.
static int encodingCompare(const void *firstPtr, const void *secondPtr) {
    CFStringEncoding first = *(CFStringEncoding *)firstPtr;
    CFStringEncoding second = *(CFStringEncoding *)secondPtr;
    CFStringEncoding macEncodingForFirst = BDStringGetMostCompatibleMacStringEncoding(first);
    CFStringEncoding macEncodingForSecond = BDStringGetMostCompatibleMacStringEncoding(second);
    if (first == second) return 0;	// Should really never happen
    if (macEncodingForFirst == kCFStringEncodingUnicode || macEncodingForSecond == kCFStringEncodingUnicode) {
        if (macEncodingForSecond == macEncodingForFirst) return (first > second) ? 1 : -1;	// Both Unicode; compare second order
        return (macEncodingForFirst == kCFStringEncodingUnicode) ? -1 : 1;	// First is Unicode
    }
    if ((macEncodingForFirst > macEncodingForSecond) || ((macEncodingForFirst == macEncodingForSecond) && (first > second))) return 1;
    return -1;
}

// Return a sorted list of all available string encodings.
+ (NSArray *)allAvailableStringEncodings {
    static NSMutableArray *allEncodings = nil;
    if (allEncodings == nil) {	// Build list of encodings, sorted, and including only those with human readable names
        const CFStringEncoding *cfEncodings = CFStringGetListOfAvailableEncodings();
        CFStringEncoding *tmp;
        int cnt, num = 0;
        while (cfEncodings[num] != kCFStringEncodingInvalidId) num++;	// Count
        tmp = malloc(sizeof(CFStringEncoding) * num);
        memcpy(tmp, cfEncodings, sizeof(CFStringEncoding) * num);	// Copy the list
        qsort(tmp, num, sizeof(CFStringEncoding), encodingCompare);	// Sort it
        allEncodings = [[NSMutableArray alloc] init];			// Now put it in an NSArray
        for (cnt = 0; cnt < num; cnt++) {
            CFStringEncoding cfEncoding = tmp[cnt];
            NSStringEncoding nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
            if (nsEncoding && [NSString localizedNameOfStringEncoding:nsEncoding] && cfEncoding != kCFStringEncodingMacSymbol && cfEncoding != kCFStringEncodingMacDingbats && cfEncoding != kBDStringEncodingMacKeyboardSymbol)
                [allEncodings addObject:[NSNumber numberWithUnsignedInt:nsEncoding]];
        }
        free(tmp);
    }
    return allEncodings;
}

// encodings which btparse cannot handle, we might add more encodings when we find out
- (BOOL)isUnparseableEncoding:(NSStringEncoding)encoding;
{
    CFStringEncoding cfEncoding = CFStringConvertNSStringEncodingToEncoding(encoding);
    return cfEncoding == kCFStringEncodingUTF16 || cfEncoding == kCFStringEncodingUTF16BE || cfEncoding == kCFStringEncodingUTF16LE || 
           cfEncoding == kCFStringEncodingUTF32 || cfEncoding == kCFStringEncodingUTF32BE || cfEncoding == kCFStringEncodingUTF32LE || 
           cfEncoding == kCFStringEncodingDOSJapanese || cfEncoding == kCFStringEncodingShiftJIS || cfEncoding == kCFStringEncodingMacJapanese || cfEncoding == kCFStringEncodingISO_2022_JP || cfEncoding == kCFStringEncodingShiftJIS_X0213_00 || 
           cfEncoding == kCFStringEncodingEBCDIC_CP037;
}

// Called once (when the UI is first brought up) to properly setup the encodings list in the "Customize Encodings List" panel.
- (void)setupEncodingsList {
    NSArray *allEncodings = [[self class] allAvailableStringEncodings];
    int cnt, numEncodings = [allEncodings count];

    for (cnt = 0; cnt < numEncodings; cnt++) {
        NSStringEncoding encoding = [[allEncodings objectAtIndex:cnt] unsignedIntValue];
        NSString *encodingName = [NSString localizedNameOfStringEncoding:encoding];
        NSCell *cell;
        if (cnt >= [encodingMatrix numberOfRows]) [encodingMatrix addRow];
        cell = [encodingMatrix cellAtRow:cnt column:0];
        [cell setTitle:encodingName];
        [cell setTag:encoding];
    }
    [encodingMatrix sizeToCells];
    [self noteEncodingListChange:NO updateList:YES postNotification:NO];
}


// This method initializes the provided popup with list of encodings; it also sets up the selected encoding as indicated and if includeDefaultItem is YES, includes an initial item for selecting "Automatic" choice.  These non-encoding items all have 0 as their tags. Otherwise the tags are set to the NSStringEncoding value for the encoding.
- (void)setupPopUp:(BDSKEncodingPopUpButton *)popup selectedEncoding:(unsigned)selectedEncoding {
    NSArray *encs = [self enabledEncodings];
    unsigned cnt, numEncodings, itemToSelect = 0;
        
    // Put the encodings in the popup
    [popup removeAllItems];

    // Make sure the initial selected encoding appears in the list
    if ((selectedEncoding != 0) && NO == [encs containsObject:[NSNumber numberWithUnsignedInt:selectedEncoding]]) encs = [encs arrayByAddingObject:[NSNumber numberWithUnsignedInt:selectedEncoding]];

    numEncodings = [encs count];

    // Fill with encodings
    for (cnt = 0; cnt < numEncodings; cnt++) {
        NSStringEncoding enc = [[encs objectAtIndex:cnt] unsignedIntValue];
        [popup addItemWithTitle:[NSString localizedNameOfStringEncoding:enc]];
        [[popup lastItem] setTag:enc];
        [[popup lastItem] setEnabled:YES];
        if (enc == selectedEncoding) itemToSelect = [popup numberOfItems] - 1;
    }

    // Add an optional separator and "customize" item at end
    if ([popup numberOfItems] > 0) {
        [[popup menu] addItem:[NSMenuItem separatorItem]];
        [[popup lastItem] setTag:0];
    }
    [popup addItemWithTitle:[NSLocalizedString(@"Customize Encodings List", @"Encoding popup entry for bringing up the Customize Encodings List panel") stringByAppendingEllipsis]];
    [[popup lastItem] setAction:@selector(showPanel:)];
    [[popup lastItem] setTarget:self];
    [[popup lastItem] setTag:0];

    [popup selectItemAtIndex:itemToSelect];
}


// Returns the actual enabled list of encodings.
- (NSArray *)enabledEncodings {
    // see CFStringEncodingExt.h for CF encodings
    static const int defaultStringEncodings[] = {
        kCFStringEncodingUTF8, kCFStringEncodingMacRoman, kCFStringEncodingWindowsLatin1, kCFStringEncodingASCII, kCFStringEncodingMacJapanese, kCFStringEncodingShiftJIS, kCFStringEncodingMacChineseTrad, kCFStringEncodingMacKorean, kCFStringEncodingMacChineseSimp, kCFStringEncodingGB_18030_2000, -1
    };
    if (encodings == nil) {
        NSMutableArray *encs = [[[OFPreferenceWrapper sharedPreferenceWrapper] arrayForKey:BDSKStringEncodingsKey] mutableCopy];
        if ([encs count] == 0) {
            NSStringEncoding defaultEncoding = [NSString defaultCStringEncoding];
            NSStringEncoding encoding;
            BOOL hasDefault = NO;
            int cnt = 0;
            if (encs == nil)
                encs = [[NSMutableArray alloc] init];
            while (defaultStringEncodings[cnt] != -1) {
                if ((encoding = CFStringConvertEncodingToNSStringEncoding(defaultStringEncodings[cnt++])) != kCFStringEncodingInvalidId) {
                    [encs addObject:[NSNumber numberWithUnsignedInt:encoding]];
                    if (encoding == defaultEncoding) hasDefault = YES;
                }
            }
            if (hasDefault == NO)
                [encs addObject:[NSNumber numberWithUnsignedInt:defaultEncoding]];
        }
        encodings = encs;
    }
    return encodings;
}

// Should be called after any customization to the encodings list. Writes the new list out to defaults; updates the UI; also posts notification to get all encoding popups to update.
- (void)noteEncodingListChange:(BOOL)writeDefault updateList:(BOOL)updateList postNotification:(BOOL)post {
    if (writeDefault) [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:encodings forKey:BDSKStringEncodingsKey];

    if (updateList) {
        int cnt, numEncodings = [encodingMatrix numberOfRows];
        for (cnt = 0; cnt < numEncodings; cnt++) {
            NSCell *cell = [encodingMatrix cellAtRow:cnt column:0];
            [cell setState:[encodings containsObject:[NSNumber numberWithUnsignedInt:[cell tag]]] ? NSOnState : NSOffState];
        }
    }

    if (post) [[NSNotificationCenter defaultCenter] postNotificationName:BDSKEncodingsListChangedNotification object:nil];
}

// Because we want the encoding list to be modifiable even when a modal panel (such as the open panel) is up, we indicate that both the encodings list panel and the target work when modal. (See showPanel: below for the former...)
// CMH: this method seems to be undocumented, it is only documented for NSWindow, not for targets or whatever
- (BOOL)worksWhenModal{
    return YES;
}

#pragma mark Action methods

- (IBAction)showPanel:(id)sender {
    if (encodingMatrix == nil) {
        if (NO == [NSBundle loadNibNamed:@"SelectEncodingsPanel" owner:self])  {
            NSLog(@"Failed to load SelectEncodingsPanel.nib");
            return;
        }
        [(NSPanel *)[encodingMatrix window] setWorksWhenModal:YES];	// This should work when open panel is up
        [[encodingMatrix window] setLevel:NSModalPanelWindowLevel];	// Again, for the same reason
        [self setupEncodingsList];					// Initialize the list (only need to do this once)
    }
    [[encodingMatrix window] makeKeyAndOrderFront:nil];
}

- (IBAction)encodingListChanged:(id)sender {
    int cnt, numRows = [encodingMatrix numberOfRows];
    NSMutableArray *encs = [[NSMutableArray alloc] init];

    for (cnt = 0; cnt < numRows; cnt++) {
        NSCell *cell = [encodingMatrix cellAtRow:cnt column:0];
        if (((unsigned)[cell tag] != 0) && ([cell state] == NSOnState)) [encs addObject:[NSNumber numberWithUnsignedInt:[cell tag]]];
    }

    [encodings autorelease];
    encodings = encs;

    [self noteEncodingListChange:YES updateList:NO postNotification:YES];
}

- (IBAction)clearAll:(id)sender {
    [encodings autorelease];
    encodings = [[NSArray array] retain];				// Empty encodings list
    [self noteEncodingListChange:YES updateList:YES postNotification:YES];
}

- (IBAction)selectAll:(id)sender {
    [encodings autorelease];
    encodings = [[[self class] allAvailableStringEncodings] retain];	// All encodings
    [self noteEncodingListChange:YES updateList:YES postNotification:YES];
}

- (IBAction)revertToDefault:(id)sender {
    [encodings autorelease];
    encodings = nil;
    [[[OFPreferenceWrapper sharedPreferenceWrapper] preferenceForKey:BDSKStringEncodingsKey] restoreDefaultValue];
    (void)[self enabledEncodings];					// Regenerate default list
    [self noteEncodingListChange:NO updateList:YES postNotification:YES];
}

@end

/*
        Based on: EncodingManager.m
        Copyright (c) 2002-2005 by Apple Computer, Inc., all rights reserved.
        Author: Ali Ozer
        
        Helper class providing additional functionality for character encodings.
        This file also defines EncodingPopUpButtonCell and EncodingPopUpButton classes.
*/
/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation,
 modification or redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.

 In consideration of your agreement to abide by the following terms, and subject to these
 terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in
 this original Apple software (the "Apple Software"), to use, reproduce, modify and
 redistribute the Apple Software, with or without modifications, in source and/or binary
 forms; provided that if you redistribute the Apple Software in its entirety and without
 modifications, you must retain this notice and the following text and disclaimers in all
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES,
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE,
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
