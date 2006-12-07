#import "MacroTextFieldWindowController.h"


@implementation MacroTextFieldWindowController

- (id) init {
    if (self = [super initWithWindowNibName:@"MacroTextFieldWindow"]) {
    }
    return self;
}

- (void)awakeFromNib{    
    [textField setDelegate:self];
    originalInfoLineValue = [[infoLine stringValue] retain];
}

- (void)dealloc{
    [originalInfoLineValue dealloc];
	[startString release];
    [super dealloc];
}


- (void)windowDidLoad{
    [[self window] setExcludedFromWindowsMenu:TRUE];
    [[self window] setOneShot:TRUE];
    [[self window] setDelegate:self];
    [[self window] setLevel:NSModalPanelWindowLevel];
}

- (void)startEditingValue:(NSString *) string
               atLocation:(NSPoint)point
                    width:(float)width
                 withFont:(NSFont*)font
                fieldName:(NSString *)aFieldName
			macroResolver:(id<BDSKMacroResolver>)aMacroResolver{
    NSWindow *win = [self window];
    
    fieldName = aFieldName;
    macroResolver = aMacroResolver; // should we retain?
    NSRect currentFrame = [[self window] frame];
    
    // make sure the window starts out at the small size
    // and at the right point, thanks to the above assignment.
    [win setFrame:NSMakeRect(point.x,
                             point.y - currentFrame.size.height,
                             width,
                             currentFrame.size.height)
                    display:YES
                    animate:NO];
    
    startString = [string retain];
    [expandedValueTextField setStringValue:string];
    // in case we already ran and had an error that wasn't recorded:
    [infoLine setStringValue:originalInfoLineValue];

    [textField setStringValue:[string stringAsBibTeXString]];
    
    if(font) [textField setFont:font];

    [win makeKeyAndOrderFront:self];
    notifyingChanges = NO;

}

- (void)controlTextDidEndEditing:(NSNotification *)notification{
	NS_DURING
		[self stringValue];
    NS_HANDLER
		return;
    NS_ENDHANDLER
	[[self window] resignKeyWindow];
}

// Any object that uses this class should respond to the 
//  BDSKMacroTextFieldWindowWillCloseNotification by removing itself
// as an observer for that notification so it doesn't get it multiple times.
- (void)notifyNewValueAndOrderOut{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSString *stringValue = nil;
    NSDictionary *userInfo = nil;
        
    NS_DURING
        stringValue = [self stringValue];
    NS_HANDLER
        // if there was a problem building the new string, notify with the old one.
        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:startString, @"stringValue", fieldName, @"fieldName", nil];
    NS_ENDHANDLER
    
    if(!userInfo)
        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:stringValue, @"stringValue", fieldName, @"fieldName", nil];

    [nc postNotificationName:BDSKMacroTextFieldWindowWillCloseNotification
                      object:self
                    userInfo:userInfo];

    // if we don't record this, we may get sent windowDidResignKey a second time
    // when we enter this method from that one.
    notifyingChanges = YES;
    [[self window] orderOut:self];
    notifyingChanges = NO;

}

- (void)controlTextDidChange:(NSNotification*)aNotification { 
    NSString *value = nil;
    NS_DURING
        value = [self stringValue];
    NS_HANDLER
        [infoLine setStringValue:NSLocalizedString(@"Invalid BibTeX string: this change will not be recorded. Error:", 
                                                   @"Invalid raw bibtex string error message") ];
        [expandedValueTextField setStringValue:[localException reason]];
        return;
    NS_ENDHANDLER

    [infoLine setStringValue:originalInfoLineValue]; 
    [expandedValueTextField setStringValue:value];
}


- (NSString *)stringValue{
    return [NSString complexStringWithBibTeXString:[textField stringValue] macroResolver:macroResolver];
}


- (void)windowDidResignKey:(NSNotification *)aNotification{
    if(!notifyingChanges)
        [self notifyNewValueAndOrderOut];
}

@end
