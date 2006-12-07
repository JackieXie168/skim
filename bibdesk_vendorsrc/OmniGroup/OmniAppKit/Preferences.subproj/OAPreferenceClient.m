// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/OAPreferenceClient.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import <OmniAppKit/OAPreferenceController.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Preferences.subproj/OAPreferenceClient.m,v 1.27 2004/02/10 04:07:35 kc Exp $")

@interface OAPreferenceClient (Private)
- (void)_restoreDefaultsSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end

@implementation OAPreferenceClient

/*" Creates a new preferences client (with the specified title), which manipulates the specified defaults. "*/
- initWithTitle:(NSString *)newTitle defaultsArray:(NSArray *)newDefaultsArray;
{
    unsigned int defaultIndex;
    
    if (![super init])
	return nil;

    title = [newTitle copy];
    preferences = [[NSMutableArray alloc] init];
    defaultIndex = [newDefaultsArray count];
    while (defaultIndex--)
        [self addPreference: [OFPreference preferenceForKey: [newDefaultsArray objectAtIndex: defaultIndex]]];
    defaults = [[OFPreferenceWrapper sharedPreferenceWrapper] retain];
    return self;
}


// API

- (void) addPreference: (OFPreference *) preference;
{
    if ([preferences indexOfObjectIdenticalTo: preference] == NSNotFound)
        [preferences addObject: preference];
}

/*" The controlBox outlet points to the box that will be transferred into the Preferences window when this preference client is selected. "*/
- (NSView *)controlBox;
{
    return controlBox;
}

- (NSView *)initialFirstResponder;
{
    return initialFirstResponder;
}

- (NSView *)lastKeyView;
{
    return lastKeyView;
}

/*" Restores all defaults for this preference client to their original installation values. "*/
- (IBAction)restoreDefaults:(id)sender;
{
    NSString *mainPrompt, *secondaryPrompt, *defaultButton, *otherButton;
    NSBundle *bundle;
    
    bundle = [OAPreferenceClient bundle];
    mainPrompt = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Reset %@ preferences to their original values?", @"OmniAppKit", bundle, "message text for reset-to-defaults alert"), title];
    secondaryPrompt = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Choosing Reset will restore all settings in this pane to the state they were in when %@ was first installed.", @"OmniAppKit", bundle, "informative text for reset-to-defaults alert"), [[NSProcessInfo processInfo] processName]];
    defaultButton = NSLocalizedStringFromTableInBundle(@"Reset", @"OmniAppKit", bundle, "alert panel button");
    otherButton = NSLocalizedStringFromTableInBundle(@"Cancel", @"OmniAppKit", bundle, "alert panel button");
    NSBeginAlertSheet(mainPrompt, defaultButton, otherButton, nil, [controlBox window], self, NULL, @selector(_restoreDefaultsSheetDidEnd:returnCode:contextInfo:), NULL, secondaryPrompt);
}

- (void)restoreDefaultsNoPrompt;
{
    unsigned int preferenceIndex;

    preferenceIndex = [preferences count];
    while (preferenceIndex--)
        [[preferences objectAtIndex: preferenceIndex] restoreDefaultValue];
}

- (BOOL)haveAnyDefaultsChanged;
{
    unsigned int preferenceIndex;

    preferenceIndex = [preferences count];
    while (preferenceIndex--) {
        if ([[preferences objectAtIndex: preferenceIndex] hasNonDefaultValue])
            return YES;
    }

    return NO;
}

/*" Prompts the user for a directory (using an open panel), then updates the text field to display it and calls -setValueForSender: specifying that field as the sender. "*/
- (void)pickDirectoryForTextField:(NSTextField *)textField;
{
    NSOpenPanel *openPanel;
    NSString *directory;

    openPanel = [NSOpenPanel new];
    [openPanel setCanChooseDirectories:YES];
    if ([openPanel runModalForTypes:nil] != NSOKButton)
	return;
    
    directory = [[openPanel filenames] objectAtIndex: 0];
    [textField setStringValue:directory];
    [self setValueForSender:textField];
}

- (void)resetFloatValueToDefaultNamed:(NSString *)defaultName inTextField:(NSTextField *)textField;
{
    OFPreference *preference;
    
    preference = [OFPreference preferenceForKey: defaultName];
    [preference restoreDefaultValue];
    [textField setFloatValue:[preference floatValue]];
    NSBeep();
}

- (void)resetIntValueToDefaultNamed:(NSString *)defaultName inTextField:(NSTextField *)textField;
{
    OFPreference *preference;
    
    preference = [OFPreference preferenceForKey: defaultName];
    [preference restoreDefaultValue];
    [textField setIntValue:[preference integerValue]];
    NSBeep();
}


// Subclass me!

/*" Updates the UI to reflect the current defaults. "*/
- (void)updateUI;
{
}

/*" Updates defaults for a modified UI element (the sender). "*/
- (void)setValueForSender:(id)sender;
{
}

/*" Called when the receiver is about to become the current client.  This can be used to register for notifications used to update the UI for the client. "*/
- (void)becomeCurrentPreferenceClient;
{
}

/*" Called when the receiver is about to give up its status as the current client.  This can be used to deregister for notifications used to update the UI for the client. "*/
- (void)resignCurrentPreferenceClient;
{
}

/*" This method should be called whenever a default is changed programmatically.  The default implementation simply calls -updateUI and synchronizes the defaults. "*/
- (void)valuesHaveChanged;
{
    [self updateUI];
    [defaults autoSynchronize];
}

 // Text delegate methods
 // (We have to be the field's text delegate because otherwise the field will just silently take the value if the user hits tab, and won't set the associated preference.)

/*" The default implementation calls -setValueForSender:, setting the sender to be the notification object (i.e., the text field). "*/
- (void)controlTextDidEndEditing:(NSNotification *)notification;
{
    [self setValueForSender:[notification object]];
}


// NSNibAwaking informal protocol

/*" Be sure to call super if you subclass this "*/
- (void)awakeFromNib;
{
    [controlBox retain];
}

@end

@implementation OAPreferenceClient (Private)

- (void)_restoreDefaultsSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode != NSAlertDefaultReturn)
        return;
    [self restoreDefaultsNoPrompt];
    [self valuesHaveChanged];
}

@end
