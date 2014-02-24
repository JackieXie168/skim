//
//  NSData_SKExtensions.h
//  Skim
//
//  Created by Christiaan Hofman on 9/8/07.
/*
 This software is Copyright (c) 2007-2014
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

// For base 64 encoding/decoding:
//
//  Created by Matt Gallagher on 2009/06/03.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import <Cocoa/Cocoa.h>


@interface NSData (SKExtensions)

- (NSString *)md5String;
- (NSString *)xmlString;

- (id)initWithHexString:(NSString *)hexString;
- (NSString *)hexString;

+ (NSData *)dataWithPointAsQDPoint:(NSPoint)point;
+ (NSData *)dataWithRectAsQDRect:(NSRect)rect;

- (NSPoint)pointValueAsQDPoint;
- (NSRect)rectValueAsQDRect;

+ (id)scriptingPdfWithDescriptor:(NSAppleEventDescriptor *)descriptor;
- (id)scriptingPdfDescriptor;
+ (id)scriptingTiffPictureWithDescriptor:(NSAppleEventDescriptor *)descriptor;
- (id)scriptingTiffPictureDescriptor;
+ (id)scriptingRtfWithDescriptor:(NSAppleEventDescriptor *)descriptor;
- (id)scriptingRtfDescriptor;

@end
