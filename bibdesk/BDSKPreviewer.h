//  BDSKPreviewer.h

//  Created by Michael McCracken on Tue Jan 29 2002.

/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/*! @header BDSKPreviewer.h
    @discussion Contains class declaration for the Tex task manager and preview window.
*/

#import <Cocoa/Cocoa.h>

@class BibDocument;

/*!
    @class BDSKPreviewer
    @abstract TeX task manager and preview window controller
    @discussion ...
*/
@interface BDSKPreviewer : NSWindowController {
    NSString *texTemplatePath;
    NSString *finalPDFPath;
    NSString *tmpBibFilePath;
    NSImageView *imageView;
    NSImage *image;
    NSBundle *bundle;
    BOOL working;
    int bibStep;
    BibDocument *theDoc;
    NSString *applicationSupportPath;
    NSLock *countLock;
    NSLock *workingLock;
    IBOutlet NSImageView* imagePreviewView;
}
/*!
    @method sharedPreviewer
    @abstract accesses the single object
 @result Pointer to the single BDSKPreviewer instance.
    
*/
+ (BDSKPreviewer *)sharedPreviewer;

/*!
    @method init
    @abstract initializer
    @discussion should only be called once (by appcontroller)
    
*/
- (id)init;

/*!
    @method PDFFromString:
    @abstract given a string, displays the PDF preview
    @discussion takes the string as a bibtex entry or entries, inserts appropriate values into a template, runs LaTeX, BibTeX, LaTeX, LateX, and loads the file as PDF into its imageview
    @param str the bibtex source
 @result YES indicates success... <em>might not be correct - I don't use the result</em>
*/
- (BOOL)PDFFromString:(NSString *)str;


/*!
@method PDFDataFromString:
    @abstract given a string, gives PDF of the preview as NSData
    @discussion takes the string as a bibtex entry or entries, inserts appropriate values into a template, runs LaTeX, BibTeX, LaTeX, LateX, and returns the PDF file as an NSData object.
 @param str  The bibtex source
 @result pointer to autoreleased (?) NSData object that contains the PDF Data of the preview
*/
- (NSData *)PDFDataFromString:(NSString *)str;

@end


