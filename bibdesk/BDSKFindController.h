//
//  BDSKFindController.h
//  Bibdesk
//
//  Created by Adam Maxwell on 06/21/05.
//
/*
 This software is Copyright (c) 2005
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
 
 - Neither the name of Adam Maxwell nor the names of any
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

#import <Cocoa/Cocoa.h>
#import <OmniFoundation/OmniFoundation.h>

extern NSString *BDSKFindControllerDefaultFindAndReplaceTypeKey;
extern NSString *BDSKFindControllerCaseSensitiveFindAndReplaceKey;
extern NSString *BDSKFindControllerFindAndReplaceSelectedItemsKey;
extern NSString *BDSKFindControllerLastFindAndReplaceFieldKey;

@class BibDocument;

@interface BDSKFindController : NSWindowController {
    OFPreferenceWrapper *defaults;
    
    // outlets
    IBOutlet NSComboBox *fieldToSearchComboBox;
    IBOutlet NSMatrix *searchTypeMatrix;
    IBOutlet NSButton *caseSensitiveCheckbox;
    IBOutlet NSButton *searchSelectionCheckbox;
    IBOutlet NSTextField *findTextField;
    IBOutlet NSTextField *replaceTextField;
    IBOutlet NSButton *findAsMacroCheckbox;
    IBOutlet NSButton *replaceAsMacroCheckbox;
    IBOutlet NSButton *replaceButton;
}

/*!
    @method     sharedFindController
    @abstract   Returns the shared instance of the find controller.  This object operates on the current
                document from the NSDocumentController.
    @discussion (comprehensive description)
    @result     (description)
*/
+ (BDSKFindController *)sharedFindController;

/*!
    @method     resetDefaults
    @abstract   The values for most of the find switches are stored in preferences, so they are persistent
                even if the panel gets closed or the controller is deallocated.  However, we don't want all
                of them to persist across launches of the program, so this method is called in <tt>awakeFromNib</tt>.
    @discussion (comprehensive description)
*/
- (void)resetDefaults;

    /*!
    @method     updateUI
    @abstract   Call this after changing a UI element (button, field, etc); it performs some validation.
    @discussion (comprehensive description)
*/
- (void)updateUI;

/*!
    @method     currentRegexIsValid
    @abstract   Check to make sure the current regular expression is valid.  AGRegex returns nil if the
                regex is not valid.
    @discussion (comprehensive description)
    @result     (description)
*/
- (BOOL)currentRegexIsValid;

/*!
    @method     stringIsValidAsComplexString:errorMessage:
    @abstract   Wrapper around exception handling to check for problems parsing the complex strings as
                BibTeX strings.  Returns an error message by reference if the string was not valid.
    @discussion (comprehensive description)
    @param      btstring BibTeX macro string
    @param      errString (description)
    @result     (description)
*/
- (BOOL)stringIsValidAsComplexString:(NSString *)btstring errorMessage:(NSString **)errString;

- (IBAction)openHelp:(id)sender;

// set options for searching
- (IBAction)changeFieldName:(id)sender;
- (IBAction)toggleSearchType:(id)sender;
- (IBAction)toggleCaseSensitivity:(id)sender;
- (IBAction)toggleSelection:(id)sender;
- (IBAction)toggleFindAsMacro:(id)sender;
- (IBAction)toggleReplaceAsMacro:(id)sender;

// set find/replace strings
- (IBAction)changeFindExpression:(id)sender;
- (IBAction)changeReplaceExpression:(id)sender;

- (IBAction)findAndHighlight:(id)sender;
- (IBAction)replaceAndHighlightNext:(id)sender;

// perform the replacement on the front document
- (IBAction)replaceAll:(id)sender;

/*!
    @method     findAndHighlightWithReplace:
    @abstract   Replaces in the selected item if there is a selection and replace is YES, then highlights the next match.
                Search wraps around by default.
    @discussion (comprehensive description)
    @param      replace (description)
*/
- (void)findAndHighlightWithReplace:(BOOL)replace;

/*!
    @method     currentFoundItemsInDocument:
    @abstract   Returns an array of BibItems representing the current search results for the given document.
    @discussion (comprehensive description)
    @param      theDocument (description)
    @result     (description)
*/
- (NSArray *)currentFoundItemsInDocument:(BibDocument *)theDocument;

/*!
    @method     findAndReplaceInItems:ofDocument:
    @abstract   Does a find-and-replace on all the items in arrayOfPubs for the given document
    @discussion (comprehensive description)
    @param      arrayOfPubs Array of BibItems
    @param      theDocument The document containing the publications
*/
- (void)findAndReplaceInItems:(NSArray *)arrayOfPubs ofDocument:(BibDocument *)theDocument;

@end
