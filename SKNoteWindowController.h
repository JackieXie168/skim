//
//  SKNoteWindowController.h
//  Skim
//
//  Created by Christiaan Hofman on 15/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class PDFAnnotation, BDSKDragImageView;

@interface SKNoteWindowController : NSWindowController {
    IBOutlet BDSKDragImageView *imageView;
    
    PDFAnnotation *note;
    
    id theModalDelegate;
    SEL theDidEndSelector;
    
    CFArrayRef editors;
}

- (id)initWithNote:(PDFAnnotation *)aNote;

- (PDFAnnotation *)note;
- (void)setNote:(PDFAnnotation *)newNote;

- (BOOL)isNoteType;

- (BOOL)commitEditing;

@end

@interface SKRectStringTransformer : NSValueTransformer
@end
