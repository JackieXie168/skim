//
//  BDSKSearchGroupSheetController.m
//  Bibdesk
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BDSKSearchGroupSheetController.h"
#import "BDSKSearchGroup.h"
#import "BDSKServerInfo.h"
#import "BDSKCollapsibleView.h"
#import "NSFileManager_BDSKExtensions.h"
#import <yaz/BDSKZoomRecord.h>>

#define SERVERS_FILENAME @"SearchGroupServers.plist"

static NSArray *searchGroupServers = nil;

@implementation BDSKSearchGroupSheetController

#pragma mark Server info

+ (void)initialize {
    NSString *applicationSupportPath = [[NSFileManager defaultManager] currentApplicationSupportPathForCurrentUser]; 
    NSString *path = [applicationSupportPath stringByAppendingPathComponent:SERVERS_FILENAME];
    
    if (NO == [[NSFileManager defaultManager] fileExistsAtPath:path])
        path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:SERVERS_FILENAME];
    
    NSArray *serverDicts = [NSArray arrayWithContentsOfFile:path];
    int type, count = [serverDicts count];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
    
    for (type = 0; type < count; type++) {
        NSArray *dicts = [serverDicts objectAtIndex:type];
        NSEnumerator *dictEnum = [dicts objectEnumerator];
        NSDictionary *dict;
        NSMutableArray *infos = [NSMutableArray arrayWithCapacity:[dicts count]];
        while (dict = [dictEnum nextObject]) {
            BDSKServerInfo *info = [[BDSKServerInfo alloc] initWithType:type dictionary:dict];
            [infos addObject:info];
            [info release];
        }
        [array addObject:infos];
    }
    [searchGroupServers release];
    searchGroupServers = [array copy];
}

+ (void)resetServers;
{
    NSArray *serverDicts = [NSArray arrayWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:SERVERS_FILENAME]];
    int type, count = [serverDicts count];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
    
    for (type = 0; type < count; type++) {
        NSArray *dicts = [serverDicts objectAtIndex:type];
        NSEnumerator *dictEnum = [dicts objectEnumerator];
        NSDictionary *dict;
        NSMutableArray *infos = [NSMutableArray arrayWithCapacity:[dicts count]];
        while (dict = [dictEnum nextObject]) {
            BDSKServerInfo *info = [[BDSKServerInfo alloc] initWithType:type dictionary:dict];
            [infos addObject:info];
            [info release];
        }
        [array addObject:infos];
    }
    [searchGroupServers release];
    searchGroupServers = [array copy];
    [self saveServers];
}

+ (void)saveServers;
{
    // @@ temporary
    return;
    
    int type, count = [searchGroupServers count];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
    
    for (type = 0; type < count; type++) {
        NSArray *infos = [searchGroupServers objectAtIndex:type];
        [array addObject:[infos valueForKey:@"dictionaryValue"]];
    }
    
    NSString *error = nil;
    NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:array format:format errorDescription:&error];
    if (error) {
        NSLog(@"Error writing: %@", error);
        [error release];
    } else {
        NSString *applicationSupportPath = [[NSFileManager defaultManager] currentApplicationSupportPathForCurrentUser]; 
        NSString *path = [applicationSupportPath stringByAppendingPathComponent:SERVERS_FILENAME];
        [data writeToFile:path atomically:YES];
    }
}

+ (NSArray *)serversForType:(int)type;
{
    return [searchGroupServers objectAtIndex:type];
}

+ (void)addServer:(BDSKServerInfo *)serverInfo forType:(int)type;
{
    [[searchGroupServers objectAtIndex:type] addObject:serverInfo];
    [self saveServers];
}

+ (void)setServer:(BDSKServerInfo *)serverInfo atIndex:(unsigned)index forType:(int)type;
{
    [[searchGroupServers objectAtIndex:type] replaceObjectAtIndex:index withObject:serverInfo];
    [self saveServers];
}

+ (void)removeServerAtIndex:(unsigned)index forType:(int)type;
{
    [[searchGroupServers objectAtIndex:type] removeObjectAtIndex:index];
    [self saveServers];
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
        
        type = group ? [group type] : BDSKSearchGroupEntrez;
        serverInfo = [[group serverInfo] copy];
        if (nil == serverInfo)
            serverInfo = [[BDSKServerInfo defaultServerInfoWithType:type] retain];
        
        isExpanded = YES;

    }
    return self;
}

- (void)dealloc
{
    [group release];
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

- (void)setupOptionPopups {
    [syntaxPopup addItemWithTitle:@"USMarc"];
    [[syntaxPopup lastItem] setRepresentedObject:[BDSKZoomRecord stringWithSyntaxType:USMARC]];
    [syntaxPopup addItemWithTitle:@"XML"];
    [[syntaxPopup lastItem] setRepresentedObject:[BDSKZoomRecord stringWithSyntaxType:XML]];
    /*
    [syntaxPopup addItemWithTitle:@"UKMarc"];
    [[syntaxPopup lastItem] setRepresentedObject:[BDSKZoomRecord stringWithSyntaxType:UKMARC]];
    [syntaxPopup addItemWithTitle:@"SUTRS"];
    [[syntaxPopup lastItem] setRepresentedObject:[BDSKZoomRecord stringWithSyntaxType:SUTRS]];
    [syntaxPopup addItemWithTitle:@"GRS-1"];
    [[syntaxPopup lastItem] setRepresentedObject:[BDSKZoomRecord stringWithSyntaxType:GRS1]];
    */
}

- (void)changeOptions {
    NSString *value = [[serverInfo options] objectForKey:@"preferredRecordSyntax"];
    int index = 0;
    if (value != nil) {
        index = [syntaxPopup numberOfItems];
        while (--index) {
            if ([[[syntaxPopup itemAtIndex:index] representedObject] isEqualToString:value])
                break;
        }
        if (index == 0) {
            index = [syntaxPopup numberOfItems];
            [syntaxPopup addItemWithTitle:value];
            [[syntaxPopup lastItem] setRepresentedObject:value];
        }
    }
    [syntaxPopup selectItemAtIndex:index];
}

- (void)awakeFromNib
{
    [serverView retain];
    [serverView setMinSize:[serverView frame].size];
    [serverView setCollapseEdges:BDSKMaxXEdgeMask | BDSKMinYEdgeMask];
    [self collapse:self];
    
    NSArray *servers = [[self class] serversForType:type];
    unsigned index = 0;
    
    if ([servers count] == 0) {
        index = 1;
    } else if (group) {
        index = [servers indexOfObject:[group serverInfo]];
        if (index == NSNotFound)
            index = [servers count] + 1;
    }
    
    [self setupOptionPopups];
    [self reloadServersSelectingIndex:index];
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
            [[group undoManager] setActionName:NSLocalizedString(@"Edit Search Group", @"Undo action name")];
        }
    }
    
    [super dismiss:sender];
}

- (IBAction)selectPredefinedServer:(id)sender;
{
    int i = [sender indexOfSelectedItem];
    
    [self willChangeValueForKey:@"canAddServer"];
    [self willChangeValueForKey:@"canRemoveServer"];
    [self willChangeValueForKey:@"canEditServer"];
    
    [editButton setTitle:NSLocalizedString(@"Edit", @"")];
    
    if (i == [sender numberOfItems] - 1) {
        BOOL isZoom = [self type] == BDSKSearchGroupZoom;
        [self setServerInfo:[BDSKServerInfo defaultServerInfoWithType:[self type]]];
        [nameField setEnabled:YES];
        [addressField setEnabled:isZoom];
        [portField setEnabled:isZoom];
        [databaseField setEnabled:YES];
        [passwordField setEnabled:isZoom];
        [userField setEnabled:isZoom];
        [syntaxPopup setEnabled:isZoom];
        
        [self expand:self];
    } else {
        NSArray *servers = [searchGroupServers objectAtIndex:type];
        [self setServerInfo:[[searchGroupServers objectAtIndex:type] objectAtIndex:i]];
        [nameField setEnabled:NO];
        [addressField setEnabled:NO];
        [portField setEnabled:NO];
        [databaseField setEnabled:NO];
        [passwordField setEnabled:NO];
        [userField setEnabled:NO];
        [syntaxPopup setEnabled:NO];
    }
    [self didChangeValueForKey:@"canAddServer"];
    [self didChangeValueForKey:@"canRemoveServer"];
    [self didChangeValueForKey:@"canEditServer"];
}

- (IBAction)selectSyntax:(id)sender;
{
    NSString *syntax = [sender indexOfSelectedItem] == 0 ? nil : [[sender selectedItem] representedObject];
    NSMutableDictionary *options = [NSMutableDictionary dictionaryWithDictionary:[serverInfo options]];
    [options setValue:syntax forKey:@"preferredRecordSyntax"];
    [serverInfo setOptions:[options count] ? options : nil];
}

- (IBAction)addServer:(id)sender;
{
    unsigned index = [serverPopup indexOfSelectedItem];
    
    if ((int)index != [serverPopup numberOfItems] - 1 || [self commitEditing] == NO) {
        NSBeep();
        return;
    }
    
    BDSKServerInfo *info = [BDSKServerInfo defaultServerInfoWithType:[self type]];
    index = [[[self class] serversForType:0] count];
    [[self class] addServer:info forType:[self type]];
    [self reloadServersSelectingIndex:index];
}

- (IBAction)removeServer:(id)sender;
{
    unsigned index = [serverPopup indexOfSelectedItem];
    
    if ((int)index >= [serverPopup numberOfItems] - 2 || [serverPopup numberOfItems] < 4) {
        NSBeep();
        return;
    }
    
    [[self class] removeServerAtIndex:index forType:[self type]];
    [self reloadServersSelectingIndex:0];
}

- (IBAction)editServer:(id)sender;
{
    [self expand:sender];
    
    unsigned index = [serverPopup indexOfSelectedItem];
    
    if ((int)index >= [serverPopup numberOfItems] - 2) {
        NSBeep();
        return;
    }
    
    if ([nameField isEnabled]) {
        BDSKServerInfo *info = [[serverInfo copy] autorelease];
        [[self class] setServer:info atIndex:index forType:[self type]];
        [self reloadServersSelectingIndex:index];
    } else {
        [editButton setTitle:NSLocalizedString(@"Set", @"")];
        
        BOOL isZoom = [self type] == BDSKSearchGroupZoom;
        [nameField setEnabled:YES];
        [addressField setEnabled:isZoom];
        [portField setEnabled:isZoom];
        [databaseField setEnabled:YES];
        [passwordField setEnabled:isZoom];
        [userField setEnabled:isZoom];
        [syntaxPopup setEnabled:isZoom];
        
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Edit Server Setting", @"Message in alert dialog when editing default search group server")
                                         defaultButton:NSLocalizedString(@"OK", @"Button title")
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"After editing, commit by choosing Set.", @"Informative text in alert dialog when editing default search group server")];
        [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
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

- (void)resetAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSOKButton) {
        [[self class] resetServers];
        [self reloadServersSelectingIndex:0];
    }
}

- (IBAction)expand:(id)sender;
{
    if (isExpanded)
        return;
    
    NSRect winRect = [[self window] frame];
    NSSize minSize = [[self window] minSize];
    NSSize maxSize = [[self window] maxSize];
    float dh = [serverView minSize].height;
    winRect.size.height += dh;
    winRect.origin.y -= dh;
    minSize.height += dh;
    maxSize.height += dh;
    [serverView setHidden:NO];
    [[self window] setFrame:winRect display:YES animate:YES];
    [[self window] setMinSize:minSize];
    [[self window] setMaxSize:maxSize];
    
    [revealButton setState:NSOnState];
    isExpanded = YES;
}

- (IBAction)collapse:(id)sender;
{
    if (isExpanded == NO)
        return;
    
    NSRect winRect = [[self window] frame];
    NSSize minSize = [[self window] minSize];
    NSSize maxSize = [[self window] maxSize];
    float dh = [serverView minSize].height;
    winRect.size.height -= dh;
    winRect.origin.y += dh;
    minSize.height -= dh;
    maxSize.height -= dh;
    [[self window] setFrame:winRect display:YES animate:YES];
    [[self window] setMinSize:minSize];
    [[self window] setMaxSize:maxSize];
    [serverView setHidden:YES];
    
    [revealButton setState:NSOffState];
    isExpanded = NO;
}

- (IBAction)toggle:(id)sender;
{
    if (isExpanded)
        [self collapse:sender];
    else
        [self expand:sender];
}

#pragma mark Accessors

- (BOOL)canAddServer;
{
    return [serverPopup indexOfSelectedItem] == [serverPopup numberOfItems] - 1;
}

- (BOOL)canRemoveServer;
{
    return [serverPopup indexOfSelectedItem] < [serverPopup numberOfItems] - 2;
}

- (BOOL)canEditServer;
{
    return [serverPopup indexOfSelectedItem] < [serverPopup numberOfItems] - 2;
}

- (BDSKSearchGroup *)group { return group; }

- (BDSKServerInfo *)serverInfo { return serverInfo; }

- (void)setServerInfo:(BDSKServerInfo *)info;
{
    [serverInfo autorelease];
    serverInfo = [info copy];
    [self changeOptions];
}

- (void)setType:(int)t { 
    type = t; 
    [self reloadServersSelectingIndex:0];
}

- (int)type { return type; }
  
#pragma mark NSEditorRegistration

- (void)objectDidBeginEditing:(id)editor {
    if (CFArrayGetFirstIndexOfValue(editors, CFRangeMake(0, CFArrayGetCount(editors)), editor) == -1)
		CFArrayAppendValue((CFMutableArrayRef)editors, editor);		
}

- (void)objectDidEndEditing:(id)editor {
    CFIndex index = CFArrayGetFirstIndexOfValue(editors, CFRangeMake(0, CFArrayGetCount(editors)), editor);
    if (index != -1)
		CFArrayRemoveValueAtIndex((CFMutableArrayRef)editors, index);		
}

- (BOOL)commitEditing {
    CFIndex index = CFArrayGetCount(editors);
    
	while (index--)
		if([(NSObject *)(CFArrayGetValueAtIndex(editors, index)) commitEditing] == NO)
        return NO;
    
    NSString *message = nil;
    
    if (type == 0 && ([NSString isEmptyString:[serverInfo name]] || [NSString isEmptyString:[serverInfo database]])) {
        message = NSLocalizedString(@"Unable to create a search group with an empty server name or database", @"Informative text in alert dialog when search group is invalid");
    } else if (type == 1 && ([NSString isEmptyString:[serverInfo name]] || [NSString isEmptyString:[serverInfo host]] || [NSString isEmptyString:[serverInfo database]] || [[serverInfo port] intValue] == 0)) {
        message = NSLocalizedString(@"Unable to create a search group with an empty server name, address, database or port", @"Informative text in alert dialog when search group is invalid");
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
