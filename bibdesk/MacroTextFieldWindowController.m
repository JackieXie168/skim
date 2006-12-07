// MacroTextFieldWindowController.m
// Created by Michael McCracken, January 2005

/*
 This software is Copyright (c) 2005
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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
    [originalInfoLineValue release];
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
    
    [self setStartString:string];
    [expandedValueTextField setStringValue:string];
    // in case we already ran and had an error that wasn't recorded:
    [infoLine setStringValue:originalInfoLineValue];

    [textField setStringValue:[string stringAsBibTeXString]];
    
    if(font) [textField setFont:font];

    [win makeKeyAndOrderFront:self];
    notifyingChanges = NO;

}

- (void)controlTextDidEndEditing:(NSNotification *)notification{
	NSString *s = nil;
	NS_DURING
		s = [self stringValue];
    NS_HANDLER
    NS_ENDHANDLER
	if (s)
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
    NS_ENDHANDLER

    if(value){
		[infoLine setStringValue:originalInfoLineValue]; 
		[expandedValueTextField setStringValue:value];
	}
}

- (NSString *)startString{
	return [[startString retain] autorelease];
}

- (void)setStartString:(NSString *)string{
	[startString autorelease];
	startString = [string retain];
}

- (NSString *)stringValue{
    return [NSString complexStringWithBibTeXString:[textField stringValue] macroResolver:macroResolver];
}


- (void)windowDidResignKey:(NSNotification *)aNotification{
    if(!notifyingChanges)
        [self notifyNewValueAndOrderOut];
}

@end
