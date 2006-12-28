//
//  BDSKSearchGroupSheetController.m
//  Bibdesk
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BDSKSearchGroupSheetController.h"
#import "BDSKSearchGroup.h"
#import "BDSKZoomGroup.h"

static NSArray *zoomServers = nil;
static NSArray *entrezServers = nil;

@implementation BDSKSearchGroupSheetController

+ (void)initialize {
// !!! move to a plist
    entrezServers = [[NSArray alloc] initWithObjects:
        [NSDictionary dictionaryWithObjectsAndKeys:@"PubMed", @"name", @"pubmed", @"database", nil], nil];
    zoomServers = [[NSArray alloc] initWithObjects:
        [NSDictionary dictionaryWithObjectsAndKeys:@"Library of Congress", @"name", @"z3950.loc.gov", @"address", @"Voyager", @"database", [NSNumber numberWithInt:7090], @"port", nil], nil];
}

- (id)init {
    return [self initWithGroup:nil];
}

- (id)initWithGroup:(BDSKGroup *)aGroup;
{
    if (self = [super init]) {
        group = [aGroup retain];
        editors = CFArrayCreateMutable(kCFAllocatorMallocZone, 0, NULL);
        undoManager = nil;
        port = 0;
        type = 0;
        username = nil;
        password = nil;
    }
    return self;
}

- (void)dealloc
{
    [group release];
    [undoManager release];
    [address release];
    [database release];
    [username release];
    [password release];
    CFRelease(editors);    
    [super dealloc];
}

- (NSString *)windowNibName { return @"BDSKSearchGroupSheet"; }

- (void)setDefaultValues{
    NSArray *servers = type == 0 ? entrezServers : zoomServers;
    [serverPopup removeAllItems];
    // !!! this will be a loop
    [serverPopup addItemsWithTitles:[servers valueForKey:@"name"]];
    [serverPopup addItemWithTitle:NSLocalizedString(@"Other", @"Popup menu item name for other search group server")];
    [serverPopup selectItemAtIndex:0];
    
    NSDictionary *host = [servers objectAtIndex:0];
    [self setAddress:[host objectForKey:@"address"]];
    [self setPort:[[host objectForKey:@"port"] intValue]];
    [self setDatabase:[host objectForKey:@"database"]];
    
    [addressField setEnabled:NO];
    [portField setEnabled:NO];
    [databaseField setEnabled:NO];
    
    [self setUsername:nil];
    [self setPassword:nil];
    [userField setEnabled:NO];
    [passwordField setEnabled:NO];
}

- (void)awakeFromNib
{
    [self setDefaultValues];
}

- (BDSKGroup *)group { return group; }

- (IBAction)dismiss:(id)sender {
    if ([sender tag] == NSOKButton) {
        
        if ([self commitEditing] == NO) {
            NSBeep();
            return;
        }
                
        // we don't have a group, so create  a new one
        if(group == nil){
            if(type == 0)
                group = [[BDSKSearchGroup alloc] initWithName:@"Empty" database:database searchTerm:nil];
            else
                group = [[BDSKZoomGroup alloc] initWithHost:address port:port database:database searchTerm:nil];
        }else{
            
            // we have a pubmed/web search group, and we're modifiying it
            if(type == 0){
                if([[group class] isKindOfClass:[BDSKSearchGroup class]]){
                    [(BDSKSearchGroup *)group setDatabase:database];
                }else{
                    // we have a z39.50 group, and need to replace it with a pubmed/web group
                   BDSKSearchGroup *newGroup = [[BDSKSearchGroup alloc] initWithName:[group name] database:database searchTerm:[(BDSKZoomGroup *)group searchTerm]];
                   [group release];
                   group = newGroup;
                }
            }else{
                // we have a z39.50 group, and just need to change some parameters
                if([[group class] isKindOfClass:[BDSKZoomGroup class]]){
                    [(BDSKZoomGroup *)group setHost:address];
                    [(BDSKZoomGroup *)group setPort:port];
                    [(BDSKZoomGroup *)group setDatabase:database];
                    [(BDSKZoomGroup *)group setUser:username];
                    [(BDSKZoomGroup *)group setPass:password];
                }else{
                    // replace our group with a different class
                    BDSKZoomGroup *newGroup = [[BDSKZoomGroup alloc] initWithHost:address port:port database:database searchTerm:[(BDSKSearchGroup *)group searchTerm]];
                    [(BDSKZoomGroup *)group setUser:username];
                    [(BDSKZoomGroup *)group setPass:password];
                    [group release];
                    group = newGroup;
                }
            }
            [[(BDSKMutableGroup *)group undoManager] setActionName:NSLocalizedString(@"Edit Search Group", @"Undo action name")];
        }
    }
    
    [super dismiss:sender];
}

- (IBAction)selectPredefinedServer:(id)sender;
{
    int i = [sender indexOfSelectedItem];
    if (i == [sender numberOfItems] - 1) {
        [addressField setEnabled:type == 1];
        [portField setEnabled:type == 1];
        [databaseField setEnabled:YES];
    } else {
        NSArray *servers = type == 0 ? entrezServers : zoomServers;
        NSDictionary *host = [servers objectAtIndex:i];
        [self setAddress:[host objectForKey:@"address"]];
        [self setPort:[[host objectForKey:@"port"] intValue]];
        [self setDatabase:[host objectForKey:@"database"]];
        [addressField setEnabled:NO];
        [portField setEnabled:NO];
        [databaseField setEnabled:NO];
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
    NSRange range = [string rangeOfString:@"/"];
    if(range.location != NSNotFound){
        [self setDatabase:[string substringFromIndex:NSMaxRange(range)]];
        [databaseField setStringValue:database];
        string = [string substringToIndex:range.location];
    }
    range = [string rangeOfString:@":"];
    if(range.location != NSNotFound){
        [self setPort:[[string substringFromIndex:NSMaxRange(range)] intValue]];
        [portField setIntValue:port];
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
  
- (int)port {
    return port;
}
  
- (void)setPort:(int)newPort {
    port = newPort;
}
  
- (int)type {
    return type;
}
  
- (void)setType:(int)newType {
    if(type != newType) {
        type = newType;
        [self setDefaultValues];
    }
}

- (void)setUsername:(NSString *)user
{
    [username autorelease];
    username = [user copy];
}

- (void)setPassword:(NSString *)pw
{
    [password autorelease];
    password = [pw copy];
}

- (NSString *)password { return password; }
- (NSString *)username { return username; }

- (void)setNilValueForKey:(NSString *)key {
    if ([key isEqualToString:@"port"])
        [self setPort:0];
    else
        [super setNilValueForKey:key];
}

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
    
    if (type == 0 && [NSString isEmptyString:database]) {
        message = NSLocalizedString(@"Unable to create a search group with an empty database", @"Informative text in alert dialog when search group is invalid");
    } else if (type == 1 && ([NSString isEmptyString:address] || [NSString isEmptyString:database] || port == 0)) {
        message = NSLocalizedString(@"Unable to create a search group with an empty address, database or port", @"Informative text in alert dialog when search group is invalid");
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
