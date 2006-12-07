//
//  BDSKPreviewer.h
//  Bibdesk
//
//  Created by Michael McCracken on Tue Jan 29 2002.
//  Copyright (c) 2001 Michael McCracken. All rights reserved.
//
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


