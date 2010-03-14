//
//  SKNotesPreferences.h
//  Skim
//
//  Created by Christiaan on 3/14/10.
/*
 This software is Copyright (c) 2010
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

#import <Cocoa/Cocoa.h>
#import "SKViewController.h"

@class SKLineWell, SKFontWell;

@interface SKNotesPreferences : SKViewController {
    IBOutlet NSTextField *textColorLabelField;
    IBOutlet NSColorWell *textColorWell;
    IBOutlet NSTextField *anchoredColorLabelField;
    IBOutlet NSColorWell *anchoredColorWell;
    IBOutlet NSTextField *lineColorLabelField;
    IBOutlet NSColorWell *lineColorWell;
    IBOutlet NSTextField *freehandColorLabelField;
    IBOutlet NSColorWell *freehandColorWell;
    IBOutlet NSTextField *circleColorLabelField;
    IBOutlet NSColorWell *circleColorWell;
    IBOutlet NSTextField *circleInteriorColorLabelField;
    IBOutlet NSColorWell *circleInteriorColorWell;
    IBOutlet NSTextField *boxColorLabelField;
    IBOutlet NSColorWell *boxColorWell;
    IBOutlet NSTextField *boxInteriorColorLabelField;
    IBOutlet NSColorWell *boxInteriorColorWell;
    IBOutlet NSTextField *highlightColorLabelField;
    IBOutlet NSColorWell *highlightColorWell;
    IBOutlet NSTextField *underlineColorLabelField;
    IBOutlet NSColorWell *underlineColorWell;
    IBOutlet NSTextField *strikeOutColorLabelField;
    IBOutlet NSColorWell *strikeOutColorWell;
    IBOutlet NSTextField *textLineLabelField;
    IBOutlet NSTextField *lineLineLabelField;
    IBOutlet NSTextField *circleLineLabelField;
    IBOutlet NSTextField *boxLineLabelField;
    IBOutlet NSTextField *freehandLineLabelField;
    IBOutlet NSTextField *textFontLabelField;
    IBOutlet NSTextField *anchoredFontLabelField;
    IBOutlet SKLineWell *textLineWell;
    IBOutlet SKLineWell *lineLineWell;
    IBOutlet SKLineWell *circleLineWell;
    IBOutlet SKLineWell *boxLineWell;
    IBOutlet SKLineWell *freehandLineWell;
    IBOutlet SKFontWell *textNoteFontWell;
    IBOutlet SKFontWell *anchoredNoteFontWell;
}

@end
