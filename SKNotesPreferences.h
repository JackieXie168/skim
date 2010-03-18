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

@class SKLineWell, SKFontWell, SKIBArray;

@interface SKNotesPreferences : SKViewController {
    IBOutlet SKIBArray *colorLabels1;
    IBOutlet SKIBArray *colorLabels2;
    IBOutlet SKIBArray *colorLabels3;
    IBOutlet SKIBArray *fontLabels;
    IBOutlet SKIBArray *lineLabels1;
    IBOutlet SKIBArray *lineLabels2;
    IBOutlet SKIBArray *colorWells1;
    IBOutlet SKIBArray *colorWells2;
    IBOutlet SKIBArray *colorWells3;
    IBOutlet SKIBArray *fontWells;
    IBOutlet SKIBArray *lineWells1;
    IBOutlet SKIBArray *lineWells2;
}

@end
