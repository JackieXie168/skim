//
//  BDSKBibTeXExporter.h
//  Bibdesk
//
//  Created by Michael McCracken on 1/11/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BDSKEXporter.h"
#import "BibItem.h"


@interface BDSKBibTeXExporter : BDSKExporter {
    NSStringEncoding outputEncoding;
    NSString *outFileName;
    
    IBOutlet NSView *enclosingView;
    IBOutlet NSButton *chooseFileNameButton;
    IBOutlet NSButton *overwriteFileButton;
    IBOutlet NSTextField *fileNameTextField;
    IBOutlet NSPopUpButton *encodingPopUpButton;
}
/*!
@method outputEncoding
@abstract the getter corresponding to setOutputEncoding
@result returns value for outputEncoding
*/
- (NSStringEncoding)outputEncoding;

/*!
@method setOutputEncoding
@abstract sets outputEncoding to the param
@discussion 
@param newOutputEncoding 
*/
- (void)setOutputEncoding:(NSStringEncoding)newOutputEncoding;


/*!
@method outFileName
@abstract the getter corresponding to setOutFileName
@result returns value for outFileName
*/
- (NSString *)outFileName;

/*!
@method setOutFileName
@abstract sets outFileName to the param
@discussion 
@param newOutFileName 
*/
- (void)setOutFileName:(NSString *)newOutFileName;


@end
