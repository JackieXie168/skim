//
//  BDSKSearchGroupSheetController.m
//  Bibdesk
//
//  Created by Adam Maxwell on 12/26/06.
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

#import "BDSKSearchGroupSheetController.h"
#import "BDSKSearchGroup.h"
#import "BDSKZoomGroupServer.h"
#import "BDSKServerInfo.h"
#import "BDSKCollapsibleView.h"
#import "NSFileManager_BDSKExtensions.h"
#import "NSWorkspace_BDSKExtensions.h"

#define SERVERS_FILENAME @"SearchGroupServers.plist"
#define SERVERS_DIRNAME @"SearchGroupServers"

static NSDictionary *searchGroupServers = nil;

@implementation BDSKSearchGroupSheetController

#pragma mark Server info

static BOOL isSearchFileAtPath(NSString *path)
{
    return [[[NSWorkspace sharedWorkspace] UTIForURL:[NSURL fileURLWithPath:path]] isEqualToUTI:@"net.sourceforge.bibdesk.bdsksearch"];
}
    
+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"type", nil] triggerChangeNotificationsForDependentKey:@"entrez"];
    [self setKeys:[NSArray arrayWithObjects:@"type", nil] triggerChangeNotificationsForDependentKey:@"zoom"];
    [self setKeys:[NSArray arrayWithObjects:@"type", nil] triggerChangeNotificationsForDependentKey:@"oai"];
    
    NSString *applicationSupportPath = [[NSFileManager defaultManager] currentApplicationSupportPathForCurrentUser]; 
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:SERVERS_FILENAME];
    
    NSDictionary *serverDicts = [NSDictionary dictionaryWithContentsOfFile:path];
    NSMutableDictionary *newServerDicts = [NSMutableDictionary dictionaryWithCapacity:[serverDicts count]];
    NSEnumerator *typeEnum = [[NSArray arrayWithObjects:BDSKSearchGroupEntrez, BDSKSearchGroupZoom, BDSKSearchGroupOAI, nil] objectEnumerator];
    NSString *type;
    
    while (type = [typeEnum nextObject]) {
        NSArray *dicts = [serverDicts objectForKey:type];
        NSEnumerator *dictEnum = [dicts objectEnumerator];
        NSDictionary *dict;
        NSMutableArray *infos = [NSMutableArray arrayWithCapacity:[dicts count]];
        while (dict = [dictEnum nextObject]) {
            BDSKServerInfo *info = [[BDSKServerInfo alloc] initWithType:type dictionary:dict];
            [infos addObject:info];
            [info release];
        }
        [newServerDicts setObject:infos forKey:type];
    }
    
    NSString *serversPath = [applicationSupportPath stringByAppendingPathComponent:SERVERS_DIRNAME];
    BOOL isDir = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:serversPath isDirectory:&isDir] && isDir) {
        NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:serversPath];
        NSString *file;
        while (file = [dirEnum nextObject]) {
            if ([[[dirEnum fileAttributes] valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
                [dirEnum skipDescendents];
            } else if (isSearchFileAtPath([serversPath stringByAppendingPathComponent:file])) {
                NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[serversPath stringByAppendingPathComponent:file]];
                BDSKServerInfo *info = [[BDSKServerInfo alloc] initWithType:nil dictionary:dict];
                if (info) {
                    NSMutableArray *servers = [newServerDicts objectForKey:[info type]];
                    unsigned index = [[servers valueForKey:@"name"] indexOfObject:[info name]];
                    if (index != NSNotFound)
                        [servers replaceObjectAtIndex:index withObject:info];
                    else
                        [servers addObject:info];
                    [info release];
                }
            }
        }
    }
    
    [searchGroupServers release];
    searchGroupServers = [newServerDicts copy];
}

+ (void)resetServers;
{
    NSDictionary *serverDicts = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:SERVERS_FILENAME]];
    NSMutableDictionary *newServerDicts = [NSMutableDictionary dictionaryWithCapacity:[serverDicts count]];
    NSEnumerator *typeEnum = [[NSArray arrayWithObjects:BDSKSearchGroupEntrez, BDSKSearchGroupZoom, BDSKSearchGroupOAI, nil] objectEnumerator];
    NSString *type;
    
    while (type = [typeEnum nextObject]) {
        NSArray *dicts = [serverDicts objectForKey:type];
        NSEnumerator *dictEnum = [dicts objectEnumerator];
        NSDictionary *dict;
        NSMutableArray *infos = [NSMutableArray arrayWithCapacity:[dicts count]];
        while (dict = [dictEnum nextObject]) {
            BDSKServerInfo *info = [[BDSKServerInfo alloc] initWithType:type dictionary:dict];
            [infos addObject:info];
            [info release];
        }
        [newServerDicts setObject:infos forKey:type];
    }
    
    NSString *applicationSupportPath = [[NSFileManager defaultManager] currentApplicationSupportPathForCurrentUser];
    NSString *serversPath = [applicationSupportPath stringByAppendingPathComponent:SERVERS_DIRNAME];
    BOOL isDir = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:serversPath isDirectory:&isDir] && isDir) {
        NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:serversPath];
        NSString *file;
        while (file = [dirEnum nextObject]) {
            if ([[[dirEnum fileAttributes] valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
                [dirEnum skipDescendents];
            } else if (isSearchFileAtPath([serversPath stringByAppendingPathComponent:file])) {
                [[NSFileManager defaultManager] removeFileAtPath:[serversPath stringByAppendingPathComponent:file] handler:nil];
            }
        }
    }
    
    [searchGroupServers release];
    searchGroupServers = [newServerDicts copy];
}

+ (void)saveServer:(BDSKServerInfo *)serverInfo;
{
    NSString *error = nil;
    NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:[serverInfo dictionaryValue] format:format errorDescription:&error];
    if (error) {
        NSLog(@"Error writing: %@", error);
        [error release];
    } else {
        NSString *applicationSupportPath = [[NSFileManager defaultManager] currentApplicationSupportPathForCurrentUser];
        NSString *serversPath = [applicationSupportPath stringByAppendingPathComponent:SERVERS_DIRNAME];
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:serversPath isDirectory:&isDir] == NO) {
            if ([[NSFileManager defaultManager] createDirectoryAtPath:serversPath attributes:nil] == NO) {
                NSLog(@"Unable to save server info");
                return;
            }
        } else if (isDir == NO) {
            NSLog(@"Unable to save server info");
            return;
        }
        
        NSString *path = [serversPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@.bdsksearch", [serverInfo name], [serverInfo type]]];
        [data writeToFile:path atomically:YES];
    }
}

+ (void)deleteServer:(BDSKServerInfo *)serverInfo;
{
    NSString *applicationSupportPath = [[NSFileManager defaultManager] currentApplicationSupportPathForCurrentUser];
    NSString *serversPath = [applicationSupportPath stringByAppendingPathComponent:SERVERS_DIRNAME];
    NSString *path = [serversPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@.bdsksearch", [serverInfo name], [serverInfo type]]];
    BOOL isDir = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir == NO) {
        [[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
    }
    
}

+ (NSArray *)serversForType:(NSString *)type;
{
    return [searchGroupServers objectForKey:type];
}

+ (void)addServer:(BDSKServerInfo *)serverInfo forType:(NSString *)type;
{
    [[searchGroupServers objectForKey:type] addObject:serverInfo];
    [self saveServer:serverInfo];
}

+ (void)setServer:(BDSKServerInfo *)serverInfo atIndex:(unsigned)index forType:(NSString *)type;
{
    NSMutableArray *servers = [searchGroupServers objectForKey:type];
    [self deleteServer:[servers objectAtIndex:index]];
    [servers replaceObjectAtIndex:index withObject:serverInfo];
    [self saveServer:serverInfo];
}

+ (void)removeServerAtIndex:(unsigned)index forType:(NSString *)type;
{
    NSMutableArray *servers = [searchGroupServers objectForKey:type];
    [self deleteServer:[servers objectAtIndex:index]];
    [servers removeObjectAtIndex:index];
}

#pragma mark Initialization

- (id)init {
    return [self initWithGroup:nil];
}

- (id)initWithGroup:(BDSKSearchGroup *)aGroup;
{
    if (self = [super init]) {
        group = [aGroup retain];
        editors = CFArrayCreateMutable(kCFAllocatorMallocZone, 0, NULL);
        undoManager = nil;
        
        type = group ? [[group type] copy] : [BDSKSearchGroupEntrez copy];
        serverInfo = nil; // this will be set indirectly in awakeFromNib
        
        isCustom = NO;
        isEditable = NO;
    }
    return self;
}

- (void)dealloc
{
    [group release];
    [type release];
    [undoManager release];
    [serverInfo release];
    [serverView release];
    CFRelease(editors);    
    [super dealloc];
}

- (NSString *)windowNibName { return @"BDSKSearchGroupSheet"; }

- (void)reloadServersSelectingIndex:(unsigned)index{
    NSArray *servers = [[self class] serversForType:type];
    [serverPopup removeAllItems];
    [serverPopup addItemsWithTitles:[servers valueForKey:@"name"]];
    [[serverPopup menu] addItem:[NSMenuItem separatorItem]];
    [serverPopup addItemWithTitle:NSLocalizedString(@"Other", @"Popup menu item name for other search group server")];
    [serverPopup selectItemAtIndex:index];
    [self selectPredefinedServer:serverPopup];
}

- (void)changeOptions {
    NSString *value = [serverInfo recordSyntax];
    if (value == nil) {
        [syntaxPopup selectItemAtIndex:0];
    } else {
        if ([syntaxPopup itemWithTitle:value] == nil)
            [syntaxPopup addItemWithTitle:value];
        [syntaxPopup selectItemWithTitle:value];
    }
}

- (void)awakeFromNib
{
    [serverView retain];
    [serverView setMinSize:[serverView frame].size];
    [serverView setCollapseEdges:BDSKMaxXEdgeMask | BDSKMinYEdgeMask];
    
    [revealButton setBezelStyle:NSRoundedDisclosureBezelStyle];
    [revealButton performClick:self];
    
    [typeMatrix selectCellWithTag:[self isEntrez] ? 0 : [self isZoom] ? 1 : 2];
    
    NSArray *servers = [[self class] serversForType:type];
    unsigned index = 0;
    
    if ([servers count] == 0) {
        index = 1;
    } else if (group) {
        index = [servers indexOfObject:[group serverInfo]];
        if (index == NSNotFound)
            index = [servers count] + 1;
    }
    
    [syntaxPopup addItemsWithTitles:[BDSKZoomGroupServer supportedRecordSyntaxes]];
    
    [self reloadServersSelectingIndex:index];
    [self changeOptions];
}

#pragma mark Actions

- (IBAction)dismiss:(id)sender {
    if ([sender tag] == NSOKButton) {
        
        if ([self commitEditing] == NO) {
            NSBeep();
            return;
        }
                
        // we don't have a group, so create  a new one
        if(group == nil){
            group = [[BDSKSearchGroup alloc] initWithType:type serverInfo:serverInfo searchTerm:nil];
        }else{
            [group setServerInfo:serverInfo];
        }
    }
    
    [super dismiss:sender];
}

- (IBAction)selectServerType:(id)sender;
{
    int t = [[sender selectedCell] tag];
    [self setType:t == 0 ? BDSKSearchGroupEntrez : t == 1 ? BDSKSearchGroupZoom : BDSKSearchGroupOAI];
}

- (IBAction)selectPredefinedServer:(id)sender;
{
    int i = [sender indexOfSelectedItem];
    
    [editButton setTitle:NSLocalizedString(@"Edit", @"Button title")];
    [editButton setToolTip:NSLocalizedString(@"Edit the selected default server settings", @"Tool tip message")];
    
    if (i == [sender numberOfItems] - 1) {
        [self setServerInfo:(serverInfo == nil && group) ? [group serverInfo] : [BDSKServerInfo defaultServerInfoWithType:[self type]]];
        if ([revealButton state] == NSOffState)
            [revealButton performClick:self];
        [self setCustom:YES];
        [self setEditable:YES];
        [addRemoveButton setTitle:NSLocalizedString(@"Add", @"Button title")];
        [addRemoveButton setToolTip:NSLocalizedString(@"Add a new default server with the current settings", @"Tool tip message")];
    } else {
        NSArray *servers = [[self class] serversForType:type];
        [self setServerInfo:[servers objectAtIndex:i]];
        [self setCustom:NO];
        [self setEditable:NO];
        [addRemoveButton setTitle:NSLocalizedString(@"Remove", @"Button title")];
        [addRemoveButton setToolTip:NSLocalizedString(@"Remove the selected default server", @"Tool tip message")];
    }
}

- (IBAction)selectSyntax:(id)sender;
{
    NSString *syntax = [sender indexOfSelectedItem] == 0 ? nil : [sender titleOfSelectedItem];
    [serverInfo setRecordSyntax:syntax];
}

- (IBAction)addRemoveServer:(id)sender;
{
    if ([self commitEditing] == NO) {
        NSBeep();
        return;
    }
    
    if ([self isCustom]) {
        // add the custom server as a default server
        
        NSArray *servers = [[self class] serversForType:[self type]];
        if ([[servers valueForKey:@"name"] containsObject:[[self serverInfo] name]]) {
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Duplicate Server Name", @"Message in alert dialog when adding a search group server with a duplicate name")
                                             defaultButton:nil
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"A default server with the specified name already exists. Edit and Set the default server or use a different name.", @"Informative text in alert dialog when adding a search group server server with a duplicate name")];
            [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
            return;
        }
        
        unsigned index = [servers count];
        [[self class] addServer:[self serverInfo] forType:[self type]];
        [self reloadServersSelectingIndex:index];
        
    } else {
        // remove the selected default server
        
        [[self class] removeServerAtIndex:[serverPopup indexOfSelectedItem] forType:[self type]];
        [self reloadServersSelectingIndex:0];
        
    }
}

- (IBAction)editServer:(id)sender;
{
    if ([revealButton state] == NSOffState)
        [revealButton performClick:sender];
    
    if ([self isCustom]) {
        NSBeep();
        return;
    }
    
    if ([self isEditable]) {
        if ([self commitEditing] == NO)
            return;
        
        unsigned index = [serverPopup indexOfSelectedItem];
        unsigned existingIndex = [[[[self class] serversForType:[self type]] valueForKey:@"name"] indexOfObject:[serverPopup titleOfSelectedItem]];
        if (existingIndex != NSNotFound && existingIndex != index) {
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Duplicate Server Name", @"Message in alert dialog when setting a search group server with a duplicate name")
                                             defaultButton:nil
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"Another default server with the specified name already exists. Edit and Set the default server or use a different name.", @"Informative text in alert dialog when setting a search group server server with a duplicate name")];
            [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
            return;
        }
        
        BDSKServerInfo *info = [[serverInfo copy] autorelease];
        [[self class] setServer:info atIndex:index forType:[self type]];
        [self reloadServersSelectingIndex:index];
    } else {
        [editButton setTitle:NSLocalizedString(@"Set", @"Button title")];
        [editButton setToolTip:NSLocalizedString(@"Set the selected default server settings", @"Tool tip message")];
        [self setEditable:YES];
        
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Edit Server Setting", @"Message in alert dialog when editing default search group server")
                                         defaultButton:NSLocalizedString(@"OK", @"Button title")
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"After editing, commit by choosing Set.", @"Informative text in alert dialog when editing default search group server")];
        [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}

- (void)resetAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSOKButton) {
        [[self class] resetServers];
        [self reloadServersSelectingIndex:0];
    }
}

- (IBAction)resetServers:(id)sender;
{
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Reset Servers", @"Message in alert dialog when resetting default search group servers")
                                     defaultButton:NSLocalizedString(@"OK", @"Button title")
                                   alternateButton:NSLocalizedString(@"Cancel", @"Button title")
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"This will restore the default server settings to their original values. This action cannot be undone.", @"Informative text in alert dialog when resetting default search group servers")];
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(resetAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction)toggle:(id)sender;
{
    BOOL collapse = [revealButton state] == NSOffState;
    NSRect winRect = [[self window] frame];
    NSSize minSize = [[self window] minSize];
    NSSize maxSize = [[self window] maxSize];
    float dh = [serverView minSize].height;
    if (collapse)
        dh *= -1;
    winRect.size.height += dh;
    winRect.origin.y -= dh;
    minSize.height += dh;
    maxSize.height += dh;
    if (collapse == NO)
        [serverView setHidden:NO];
    [[self window] setFrame:winRect display:[[self window] isVisible] animate:[[self window] isVisible]];
    [[self window] setMinSize:minSize];
    [[self window] setMaxSize:maxSize];
    if (collapse)
        [serverView setHidden:YES];
}

#pragma mark Accessors

- (void)setCustom:(BOOL)flag;
{
    isCustom = flag;
}

- (BOOL)isCustom { return isCustom; }

- (void)setEditable:(BOOL)flag;
{ 
    isEditable = flag;
}

- (BOOL)isEditable { return isEditable; }

- (BOOL)isEntrez { return [[self type] isEqualToString:BDSKSearchGroupEntrez]; }

- (BOOL)isZoom { return [[self type] isEqualToString:BDSKSearchGroupZoom]; }

- (BOOL)isOai { return [[self type] isEqualToString:BDSKSearchGroupOAI]; }

- (BDSKSearchGroup *)group { return group; }

- (BDSKServerInfo *)serverInfo { return serverInfo; }

- (void)setServerInfo:(BDSKServerInfo *)info;
{
    CFArrayRemoveAllValues(editors);
    [serverInfo setDelegate:nil];
    [serverInfo autorelease];
    serverInfo = [info mutableCopy];
    [serverInfo setDelegate:self];
    [self changeOptions];
}

- (void)setType:(NSString *)t {
    [type autorelease];
    type = [t copy];
    [self reloadServersSelectingIndex:0];
}

- (NSString *)type { return type; }
  
#pragma mark NSEditorRegistration

- (void)objectDidBeginEditing:(id)editor {
    if (CFArrayGetFirstIndexOfValue(editors, CFRangeMake(0, CFArrayGetCount(editors)), editor) == -1)
		CFArrayAppendValue(editors, editor);		
}

- (void)objectDidEndEditing:(id)editor {
    CFIndex index = CFArrayGetFirstIndexOfValue(editors, CFRangeMake(0, CFArrayGetCount(editors)), editor);
    if (index != -1)
		CFArrayRemoveValueAtIndex(editors, index);		
}

- (BOOL)commitEditing {
    CFIndex index = CFArrayGetCount(editors);
    
	while (index--)
		if([(NSObject *)(CFArrayGetValueAtIndex(editors, index)) commitEditing] == NO)
        return NO;
    
    NSString *message = nil;
    
    if ([self isEntrez] && ([NSString isEmptyString:[serverInfo name]] || [NSString isEmptyString:[serverInfo database]])) {
        message = NSLocalizedString(@"Unable to create a search group with an empty server name or database", @"Informative text in alert dialog when search group is invalid");
    } else if ([self isZoom] && ([NSString isEmptyString:[serverInfo name]] || [NSString isEmptyString:[serverInfo host]] || [NSString isEmptyString:[serverInfo database]] || [[serverInfo port] intValue] == 0)) {
        message = NSLocalizedString(@"Unable to create a search group with an empty server name, address, database or port", @"Informative text in alert dialog when search group is invalid");
    } else if ([self isOai] && ([NSString isEmptyString:[serverInfo name]] || [NSString isEmptyString:[serverInfo host]])) {
        message = NSLocalizedString(@"Unable to create a search group with an empty server name or address", @"Informative text in alert dialog when search group is invalid");
    }
    if (message) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Empty value", @"Message in alert dialog when data for a search group is invalid")
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:message];
        [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
        return NO;
    }
    return YES;
}

#pragma mark Undo support

- (NSUndoManager *)undoManager{
    if(undoManager == nil)
        undoManager = [[NSUndoManager alloc] init];
    return undoManager;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender{
    return [self undoManager];
}


@end
