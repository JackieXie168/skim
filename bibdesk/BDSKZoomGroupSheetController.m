//
//  BDSKZoomGroupSheetController.m
//  Bibdesk
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BDSKZoomGroupSheetController.h"
#import "BDSKZoomGroup.h"

// !!! move to a plist
static const NSString *hosts[] = { @"z3950.loc.gov:7090/Voyager", @"other" };
static const NSString *names[] = { @"Library of Congress", @"Other" };

@implementation BDSKZoomGroupSheetController

- (id)init {
    return [self initWithGroup:nil];
}

- (id)initWithGroup:(BDSKZoomGroup *)aGroup;
{
    if (self = [super init]) {
        group = [aGroup retain];
        editors = CFArrayCreateMutable(kCFAllocatorMallocZone, 0, NULL);
        undoManager = nil;
        port = 0;
    }
    return self;
}

- (void)dealloc
{
    [group release];
    [undoManager release];
    [host release];
    CFRelease(editors);    
    [super dealloc];
}

- (BDSKZoomGroup *)group { return group; }
- (NSString *)windowNibName { return @"BDSKZoomGroupSheet"; }

- (void)awakeFromNib
{
    [serverPopup removeAllItems];
    // !!! this will be a loop
    [serverPopup addItemWithTitle:names[0]];
    [serverPopup selectItemAtIndex:0];
    host = [hosts[0] copy];
    
    [serverComboBox setEnabled:NO];
    [serverComboBox setEnabled:NO];
    [portTextField setEnabled:NO];
}
    

- (IBAction)dismiss:(id)sender {
    if ([sender tag] == NSOKButton) {
        
        if ([self commitEditing] == NO) {
            NSBeep();
            return;
        }
        
        if(group == nil){
            group = [[BDSKZoomGroup alloc] initWithHost:host port:port searchTerm:nil];
        }else{
            [group setHost:host];
            [group setPort:port];
            [[group undoManager] setActionName:NSLocalizedString(@"Edit External File Group", @"Undo action name")];
        }
    }
    
    [super dismiss:sender];
}

- (IBAction)selectPredefinedServer:(id)sender;
{
    int i = [sender indexOfSelectedItem];
    if (i = [sender numberOfItems] - 1) {
        [serverComboBox setEnabled:NO];
        [serverComboBox setEnabled:NO];
        [serverComboBox setStringValue:host];
        [portTextField setIntValue:port];
    } else {
        [serverComboBox setEnabled:NO];
        [serverComboBox setEnabled:NO];
        [serverComboBox setStringValue:@""];
        [portTextField setIntValue:port];
        [host release];
        host = [hosts[i] copy];
    }
}
        
- (IBAction)changeServer:(id)sender;
{
    [host release];
    host = [[sender stringValue] copy];
}
    
- (IBAction)changePort:(id)sender;
{
    port = [sender intValue];
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
    
    if ([NSString isEmptyString:host]) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Empty Host", @"Message in alert dialog when URL for external file group is invalid")
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"Unable to create a host name with an empty string", @"Informative text in alert dialog when host name for external file group is invalid")];
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
