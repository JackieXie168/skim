//
//  SKPSProgressController.h


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Adam Maxwell on 12/6/06.
//  Copyright 2006 Adam R. Maxwell. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SKPSProgressController : NSWindowController
{
    CGPSConverterRef converter;
    IBOutlet NSButton *cancelButton;
    IBOutlet NSProgressIndicator *progressBar;
    IBOutlet NSTextField *textField;
}
- (NSData *)PDFDataWithPostScriptData:(NSData *)psData;
- (IBAction)cancel:(id)sender;
@end
