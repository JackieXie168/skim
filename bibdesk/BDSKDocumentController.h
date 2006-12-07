//  BDSKDocumentController.h

//  Created by Christiaan Hofman on 5/31/06.
/*
 This software is Copyright (c) 2006
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


@class BDSKEncodingPopUpButton;

@interface BDSKDocumentController : NSDocumentController {
    // stuff for the accessory view for openUsingFilter
    IBOutlet NSView* openUsingFilterAccessoryView;
    IBOutlet NSComboBox *openUsingFilterComboBox;
	
	// stuff for the accessory view for open text encoding 
	IBOutlet NSView *openTextEncodingAccessoryView;
	IBOutlet BDSKEncodingPopUpButton *openTextEncodingPopupButton;
    
    id mainDocument;
}

- (id)mainDocument;

/*!
    @method openDocumentUsingFilter:
    @abstract Lets user specify a command-line to read from stdin and give us stdout.
    @discussion «discussion»
    
*/
- (IBAction)openDocumentUsingFilter:(id)sender;

/*!
    @method openDocumentUsingPhonyCiteKeys:
    @abstract First sets cite keys when they are missing, so we can open the file.
    @discussion «discussion»
    
*/
- (IBAction)openDocumentUsingPhonyCiteKeys:(id)sender;

/*!
    @method     openDocumentWithContentsOfURL:encoding:
    @abstract   Creates a new document with given file and string encoding.
    @discussion (comprehensive description)
    @param      fileURL The file to open
    @param      encoding File's character encoding
*/
- (id)openDocumentWithContentsOfURL:(NSURL *)fileURL encoding:(NSStringEncoding)encoding;

/*!
    @method     openDocumentWithContentsOfURLUsingPhonyCiteKeys:encoding:
    @abstract   Generates temporary cite keys in order to keep btparse from choking on files exported from Endnote or BookEnds.
    @discussion Uses a regular expression to find and replace empty cite keys, according to a fairly limited pattern.
                A new, untitled document is created, and a warning about the invalid temporary keys is shown after opening.
    @param      fileURL The file to open
    @param      encoding File's character encoding
*/
- (id)openDocumentWithContentsOfURLUsingPhonyCiteKeys:(NSURL *)fileURL encoding:(NSStringEncoding)encoding;

/*!
    @method     openDocumentWithContentsOfURL:usingFilter:encoding:
    @abstract   Applies a filter to the file content before openening a new document.
    @discussion (comprehensive description)
    @param      fileURL The file to open
    @param      shellCommand The shell command to use to filter the file content
    @param      encoding File's character encoding
*/
- (id)openDocumentWithContentsOfURL:(NSURL *)fileURL usingFilter:(NSString *)shellCommand encoding:(NSStringEncoding)encoding;


- (void)handleWindowDidBecomeMainNotification:(NSNotification *)notification;

@end
