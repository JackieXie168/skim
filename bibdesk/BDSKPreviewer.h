//  BDSKPreviewer.h

//  Created by Michael McCracken on Tue Jan 29 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006,2007
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

/*! @header BDSKPreviewer.h
    @discussion Contains class declaration for the Tex task manager and preview window.
*/

#import <Cocoa/Cocoa.h>

@class PDFView, BDSKZoomablePDFView, BDSKTeXTask, BDSKOverlay, BDSKPreviewerServer;

typedef enum {
	BDSKUnknownPreviewState = -1,
	BDSKEmptyPreviewState   =  0,
	BDSKWaitingPreviewState =  1,
	BDSKShowingPreviewState =  2
} BDSKPreviewState;

/*!
    @class BDSKPreviewer
    @abstract TeX task manager and preview window controller
    @discussion ...
*/
@interface BDSKPreviewer : NSWindowController {
    IBOutlet BDSKZoomablePDFView *pdfView;
    IBOutlet NSTextView *rtfPreviewView;
    IBOutlet NSTextView *logView;
    IBOutlet NSTabView *tabView;
    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet BDSKOverlay *progressOverlay;
    IBOutlet NSImageView *warningImageView;
    IBOutlet NSView *warningView;
    
    BDSKPreviewerServer *server;
    BDSKPreviewState previewState;
}

/*!
    @method sharedPreviewer
    @abstract accesses the single object
	@result Pointer to the single BDSKPreviewer instance.
*/
+ (BDSKPreviewer *)sharedPreviewer;

- (PDFView *)pdfView;
- (NSTextView *)textView;
- (BDSKOverlay *)progressOverlay;

- (float)PDFScaleFactor;
- (void)setPDFScaleFactor:(float)scaleFactor;
- (float)RTFScaleFactor;
- (void)setRTFScaleFactor:(float)scaleFactor;

- (BOOL)isVisible;
- (void)handleMainDocumentDidChangeNotification:(NSNotification *)notification;
- (void)shouldShowTeXPreferences:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

/*!
    @method updateWithBibTeXString:
    @abstract Given a BibTeX string, generates the PDF and RTF data and updates the previews
    @discussion Takes the bibtex string, runs aproprate TeX tasks, and loads the resulting PDF and RTF into their views.
		Pass nil to reset the previews to their default state, showing the nopreview message. 
		This is the main method to be called from outside, and is completely thread safe. 
    @param bibStr The bibtex string source
*/
- (void)updateWithBibTeXString:(NSString *)bibStr;

/*!
    @method     displayPreviewsForState:
    @abstract   This will draw the previews or message in the appropriate views.
    @discussion This method sets the state flag and puts -performDrawingForState: on the main queue for drawing.
	@param		state An integer indicating the preview state for which to draw.
*/
- (void)displayPreviewsForState:(BDSKPreviewState)state success:(BOOL)success;

/*!
    @method     PDFDataWithString:color:
    @abstract   Converts the given string into PDF data, applying the given color to the entire range of the string.  This method is not thread safe.
    @discussion (comprehensive description)
    @param      string (description)
    @param      color (description)
    @result     (description)
*/
- (NSData *)PDFDataWithString:(NSString *)string color:(NSColor *)color;

/*!
    @method     PDFData
    @abstract   Returns the PDF data in the preview if it is valid. Otherwise returns nil.
    @discussion Any data is considered invalid if the previews were reset, our window is not visible, 
		or there are updates waiting. This should be thread safe. 
*/
- (NSData *)PDFData;

/*!
    @method     RTFData
    @abstract   Returns the RTF data in the preview if it is valid. Otherwise returns nil.
    @discussion Any data is considered invalid if the previews were reset, our window is not visible, 
		or there are updates waiting. This should be thread safe. 
*/
- (NSData *)RTFData;

/*!
    @method     LaTeXString
    @abstract   Returns the LaTeX string for the preview if it is valid. Otherwise returns nil.
    @discussion Any data is considered invalid if the previews were reset, our window is not visible, 
		or there are updates waiting. This should be thread safe. 
*/
- (NSString *)LaTeXString;

/*!
    @method     handleApplicationWillTerminate:
    @abstract   Perform cleanup actions here, since this object never gets deallocated.
    @discussion (comprehensive description)
    @param      notification (description)
*/
- (void)handleApplicationWillTerminate:(NSNotification *)notification;
@end
