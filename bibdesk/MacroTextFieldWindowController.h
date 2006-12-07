// MacroTextFieldWindowController.h
// Created by Michael McCracken, January 2005

// Inspired by and somewhat copied from Calendar, whose author I've
// lost record of.

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


#import <AppKit/AppKit.h>
#import "BDSKComplexString.h"
#import "BDSKBackgroundView.h"
#import "BDSKForm.h"

@interface MacroTextFieldWindowController : NSWindowController <BDSKFormDelegate>{
    IBOutlet NSTextField *expandedValueTextField;
    IBOutlet BDSKBackgroundView *backgroundView;
	NSControl *control;
	int row;
	int column;
    id macroResolver;
	id controlDelegate;
	NSFormatter *cellFormatter;
    NSString *startString;
	id theDelegate;
	SEL theShouldEndSelector;
	SEL theDidEndSelector;
	void *theContextInfo;
	BOOL startEdit;
	BOOL forceEndEditing;
}


/*!
    @method     editCellOfView:atRow:column:withValue:macroResolver:delegate:didEndSelector:contextInfo:
    @abstract   Starts editing a cell as a raw BibteX string.
    @discussion (discussion) 
    @param      aControl The control view containing the cell to be edited.
    @param      aRow The row for the cell to be edited.
    @param      aColumn The column for the cell to be edited.
    @param      aString The string value to start editing with.
    @param      aMacroResolver The macro resolver to use for generated complex strings.
    @param      aDelegate The delegate for current editing process, the receiver of the callback methods. 
    @param      shouldEndSelector The callback method of the delegate that will be called when the editing should end. It should have signature 
				- (BOOL)macroEditorShouldEndEditing:(NSControl *)control withValue:(NSString *)value contextInfo:(void *)contextInfo; 
    @param      didEndSelector The callback method of the delegate that will be called when the editing ends. It should have signature 
				- (void)macroEditorDidEndEditing:(NSControl *)control withValue:(NSString *)value contextInfo:(void *)contextInfo; 
    @param      contextInfo Any other information you nmight want to send along, and which will be passed in the callback methods. This should be retained by the sender. 
*/
- (BOOL)editCellOfView:(NSControl *)aControl
				 atRow:(int)aRow
				column:(int)aColumn
			 withValue:(NSString *)aString
		 macroResolver:(id<BDSKMacroResolver>)aMacroResolver
			  delegate:(id)aDelegate
	 shouldEndSelector:(SEL)shouldEndSelector 
		didEndSelector:(SEL)didEndSelector 
		   contextInfo:(void *)contextInfo;

/*!
    @method     stringValue
    @abstract   The current (complex) string value corresponding to the BibTeX string being edited.
    @discussion Returns nil if the BibTeX string is invalid.
*/
- (NSString *)stringValue;
/*!
    @method     stringValueGeneratingError:
    @abstract   Returns the current (complex) string value corresponding to the BibTeX string being edited.
    @discussion Returns nil and generates a description of the error if the BibTeX string is invalid.
    @param      error A pointer to the error message in case the BibteX string is invalid.
*/
- (NSString *)stringValueGeneratingError:(NSString **)error;

@end
