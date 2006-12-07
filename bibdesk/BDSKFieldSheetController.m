//
//  BDSKFieldSheetController.m
//  BibDesk
//
//  Created by Christiaan Hofman on 3/18/06.
/*
 This software is Copyright (c) 2005,2006
 Christiaan Hofman. All rights reserved.

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

#import "BDSKFieldSheetController.h"
#import "BDSKFieldNameFormatter.h"

@implementation BDSKFieldSheetController

- (id)initWithPrompt:(NSString *)promptString fieldsArray:(NSArray *)fields{
    if (self = [super init]) {
        [self window]; // make sure the nib is loaded
        field = nil;
        [self setPrompt:promptString];
        [self setFieldsArray:fields];
        editors = CFArrayCreateMutable(kCFAllocatorMallocZone, 0, NULL);
    }
    return self;
}

- (void)dealloc {
    [prompt release];
    [fieldsArray release];
    [field release];
    CFRelease(editors);
    [super dealloc];
}

- (void)awakeFromNib{}

- (NSString *)field{
    return field;
}

- (void)setField:(NSString *)newField{
    if (field != newField) {
        [field release];
        field = [newField copy];
    }
}

- (NSArray *)fieldsArray{
    return fieldsArray;
}

- (void)setFieldsArray:(NSArray *)array{
    if (fieldsArray != array) {
        [fieldsArray release];
        fieldsArray = [array retain];
    }
}

- (NSString *)prompt{
    return prompt;
}

- (void)setPrompt:(NSString *)promptString{
    if (prompt != promptString) {
        [prompt release];
        prompt = [promptString retain];
    }
}

- (void)prepare{
    NSRect fieldsFrame = [fieldsControl frame];
    NSRect oldPromptFrame = [promptField frame];
    [promptField setStringValue:(prompt)? prompt : @""];
    [promptField sizeToFit];
    NSRect newPromptFrame = [promptField frame];
    float dw = NSWidth(newPromptFrame) - NSWidth(oldPromptFrame);
    fieldsFrame.size.width -= dw;
    fieldsFrame.origin.x += dw;
    [fieldsControl setFrame:fieldsFrame];
}

- (IBAction)dismiss:(id)sender{
    if ([sender tag] == NSCancelButton || [self commitEditing])
        [super dismiss:sender];
}

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
    
    return YES;
}

@end


@implementation BDSKAddFieldSheetController

- (void)awakeFromNib{
    [super awakeFromNib];
	[(NSTextField *)fieldsControl setFormatter:[[[BDSKFieldNameFormatter alloc] init] autorelease]];
}

- (NSString *)windowNibName{
    return @"AddFieldSheet";
}

@end

@implementation BDSKRemoveFieldSheetController

- (NSString *)windowNibName{
    return @"RemoveFieldSheet";
}

- (void)setFieldsArray:(NSArray *)array{
    [super setFieldsArray:array];
    if ([fieldsArray count]) {
        [self setField:[fieldsArray objectAtIndex:0]];
        [okButton setEnabled:YES];
    } else {
        [okButton setEnabled:NO];
    }
}

@end
