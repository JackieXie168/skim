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
#import "NSFileManager_BDSKExtensions.h"

#define SERVERS_FILENAME @"SearchGroupServers.plist"

static NSArray *searchGroupServers = nil;

@implementation BDSKSearchGroupSheetController

#pragma mark Server info

+ (void)initialize {
    [self resetServers];
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
}

+ (void)saveServers;
{
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
    //[self saveServers];
}

+ (void)setServer:(BDSKServerInfo *)serverInfo atIndex:(unsigned)index forType:(int)type;
{
    [[searchGroupServers objectAtIndex:type] replaceObjectAtIndex:index withObject:serverInfo];
    //[self saveServers];
}

+ (void)removeServerAtIndex:(unsigned)index forType:(int)type;
{
    [[searchGroupServers objectAtIndex:type] removeObjectAtIndex:index];
    //[self saveServers];
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
        name = nil;
        address = nil;
        port = nil;
        database = nil;
        username = nil;
        password = nil;
    }
    return self;
}

- (void)dealloc
{
    [group release];
    [undoManager release];
    [name release];
    [address release];
    [port release];
    [database release];
    [username release];
    [password release];
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

- (void)awakeFromNib
{
    NSArray *servers = [[self class] serversForType:type];
    unsigned index = 0;
    
    if ([servers count] == 0) {
        index = 1;
    } else if (group) {
        index = [servers indexOfObject:[group serverInfo]];
        if (index == NSNotFound)
            index = [servers count] + 1;
    }
    
    [self reloadServersSelectingIndex:index];
}

#pragma mark Actions

- (IBAction)dismiss:(id)sender {
    if ([sender tag] == NSOKButton) {
        
        if ([self commitEditing] == NO) {
            NSBeep();
            return;
        }
        
        BDSKServerInfo *serverInfo = [[BDSKServerInfo alloc] initWithType:[self type] name:[self name] host:[self address] port:[self port] database:[self database] password:[self password] username:[self username]];
        
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
        [nameField setEnabled:YES];
        [addressField setEnabled:[self type] == BDSKSearchGroupZoom];
        [portField setEnabled:[self type] == BDSKSearchGroupZoom];
        [databaseField setEnabled:YES];
        [passwordField setEnabled:[self type] == BDSKSearchGroupZoom];
        [userField setEnabled:[self type] == BDSKSearchGroupZoom];
    } else {
        NSArray *servers = [searchGroupServers objectAtIndex:type];
        BDSKServerInfo *serverInfo = [servers objectAtIndex:i];
        [self setName:[serverInfo name]];
        [self setAddress:[serverInfo host]];
        [self setPort:[serverInfo port]];
        [self setDatabase:[serverInfo database]];
        [self setPassword:[serverInfo password]];
        [self setUsername:[serverInfo username]];
        [nameField setEnabled:NO];
        [addressField setEnabled:NO];
        [portField setEnabled:NO];
        [databaseField setEnabled:NO];
        [passwordField setEnabled:NO];
        [userField setEnabled:NO];
    }
    [self didChangeValueForKey:@"canAddServer"];
    [self didChangeValueForKey:@"canRemoveServer"];
    [self didChangeValueForKey:@"canEditServer"];
}

- (IBAction)addServer:(id)sender;
{
    unsigned index = [serverPopup indexOfSelectedItem];
    
    if ((int)index != [serverPopup numberOfItems] - 1 || [self commitEditing] == NO) {
        NSBeep();
        return;
    }
    
    BDSKServerInfo *serverInfo = [[BDSKServerInfo alloc] initWithType:[self type] name:[self name] host:[self address] port:[self port] database:[self database] password:[self password] username:[self username]];
    index = [[[self class] serversForType:[self type]] count];
    [[self class] addServer:serverInfo forType:[self type]];
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
    unsigned index = [serverPopup indexOfSelectedItem];
    
    if ((int)index >= [serverPopup numberOfItems] - 2) {
        NSBeep();
        return;
    }
    
    if ([nameField isEnabled]) {
        BDSKServerInfo *serverInfo = [[BDSKServerInfo alloc] initWithType:[self type] name:[self name] host:[self address] port:[self port] database:[self database] password:[self password] username:[self username]];
        [[self class] setServer:serverInfo atIndex:index forType:[self type]];
        [self reloadServersSelectingIndex:index];
    } else {
        [editButton setTitle:NSLocalizedString(@"Set", @"")];
        
        [nameField setEnabled:YES];
        [addressField setEnabled:[self type] == BDSKSearchGroupZoom];
        [portField setEnabled:[self type] == BDSKSearchGroupZoom];
        [databaseField setEnabled:YES];
        [passwordField setEnabled:[self type] == BDSKSearchGroupZoom];
        [userField setEnabled:[self type] == BDSKSearchGroupZoom];
        
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

- (NSString *)name {
    return name;
}

- (void)setName:(NSString *)newName {
    if(name != newName){
        [name release];
        name = [newName copy];
    }
}

- (NSString *)address {
    return address;
}

- (void)setAddress:(NSString *)newAddress {
    if(address != newAddress){
        [address release];
        address = [newAddress copy];
    }
}

- (BOOL)validateAddress:(id *)value error:(NSError **)error {
    NSString *string = *value;
    NSRange range = [string rangeOfString:@"://"];
    if(range.location != NSNotFound){
        // ZOOM gets confused when the host has a protocol
        string = [string substringFromIndex:NSMaxRange(range)];
    }
    // split address:port/dbase in components
    range = [string rangeOfString:@"/"];
    if(range.location != NSNotFound){
        [self setDatabase:[string substringFromIndex:NSMaxRange(range)]];
        [databaseField setStringValue:database];
        string = [string substringToIndex:range.location];
    }
    range = [string rangeOfString:@":"];
    if(range.location != NSNotFound){
        [self setPort:[string substringFromIndex:NSMaxRange(range)]];
        [portField setStringValue:port];
        string = [string substringToIndex:range.location];
    }
    *value = string;
    return YES;
}

- (NSString *)database {
    return database;
}

- (void)setDatabase:(NSString *)newDb {
    if(database != newDb){
        [database release];
        database = [newDb copy];
    }
}
  
- (NSString *)port {
    return port;
}
  
- (void)setPort:(NSString *)newPort {
    if(port != newPort){
        [port release];
        port = [newPort retain];
    }
}

- (BOOL)validatePort:(id *)value error:(NSError **)error {
    if (nil != *value)
        *value = [NSString stringWithFormat:@"%i", [*value intValue]];
    return YES;
}
  
- (int)type {
    return type;
}
  
- (void)setType:(int)newType {
    if(type != newType) {
        type = newType;
        [self reloadServersSelectingIndex:0];
    }
}

- (void)setUsername:(NSString *)user
{
    [username autorelease];
    username = [user copy];
}

- (NSString *)username { return username; }

- (void)setPassword:(NSString *)pw
{
    [password autorelease];
    password = [pw copy];
}

- (NSString *)password { return password; }

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
    
    if (type == 0 && ([NSString isEmptyString:name] || [NSString isEmptyString:database])) {
        message = NSLocalizedString(@"Unable to create a search group with an empty server name or database", @"Informative text in alert dialog when search group is invalid");
    } else if (type == 1 && ([NSString isEmptyString:name] || [NSString isEmptyString:address] || [NSString isEmptyString:database] || port == 0)) {
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
