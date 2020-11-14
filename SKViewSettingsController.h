//
//  SKViewSettingsController.h
//  Skim
//
//  Created by Christiaan Hofman on 13/11/2020.
/*
This software is Copyright (c) 2020
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

#import "SKWindowController.h"


@interface SKViewSettingsController : SKWindowController {
    BOOL fullScreen;
    BOOL custom;
    BOOL autoScales;
    CGFloat scaleFactor;
    NSInteger displayMode;
    NSInteger displayDirection;
    BOOL displaysAsBook;
    BOOL displaysRTL;
    BOOL displaysPageBreaks;
    NSInteger displayBox;
    NSButton *customButton;
}

- (id)initForFullScreen:(BOOL)isFullScreen;

@property (nonatomic, retain) IBOutlet NSButton *customButton;

@property (nonatomic) BOOL custom;
@property (nonatomic, readonly) BOOL allowsHorizontalSettings;
@property (nonatomic) BOOL autoScales;
@property (nonatomic) CGFloat scaleFactor;
@property (nonatomic) NSInteger displayMode, extendedDisplayMode;
@property (nonatomic) NSInteger displayDirection;
@property (nonatomic) BOOL displaysAsBook, displaysRTL, displaysPageBreaks;
@property (nonatomic) NSInteger displayBox;

@end
