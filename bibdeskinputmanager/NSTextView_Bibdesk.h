//
//  NSTextView_Bibdesk.h
//  BibDeskInputManager
//
//  Created by Sven-S. Porst on Sat Jul 17 2004.
/*
 This software is Copyright (c) 2004,2005,2006
 Sven-S. Porst. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Sven-S. Porst nor the names of any
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
#import "NSAppleScript+HandlerCalls.h"

extern NSString *BDSKInputManagerID;
extern NSString *BDSKInputManagerLoadableApplications;
#define noScriptErr 0

@interface NSTextView_Bibdesk: NSTextView

/*!
    @method    isBibTeXCitation:
    @abstract   Returns whether the range immediately preceding braceRange is (probably) a citekey context.
    @param      braceRange The range of the first curly brace that you're interested in
    @discussion Uses some slightly bizarre heuristics for searching, but seems to work.  See the implementation for comments on why it works this way.
*/

@end
@interface NSTextView (BDSKCompletion)

- (BOOL)isBibTeXCitation:(NSRange)braceRange;
- (NSRange)citeKeyRange;
- (NSRange)rangeForBibTeXUserCompletion;

@end


/*!
@function SafeBackwardSearchRange(NSRange startRange, unsigned seekLength)
 @abstract   Returns a safe range for a backwards search, as used in -[NSString rangeOfString:@"findMe" options:NSBackwardsSearch range:aRange]
 @discussion Useful when you want to search backwards an arbitrary distance, but may run into the beginning of the string (or textview text storage).
 This returns the maximum range you can search backwards, within your desired seek length, and avoids out of range exceptions.
 NSBackwardsSearch is confusing, since it starts from the <it>end</it> of the range and works towards the beginning.
 @param      (startRange) The range of your initial starting point (only the startRange.location is used, but it was more convenient this way)
 @param      (seekLength) The desired backwards search length, starting from startRange.location
 @result     An NSRange with startRange.location and some maximum length to search backwards.
 */
static inline 
NSRange SafeBackwardSearchRange(NSRange startRange, unsigned seekLength){
    unsigned minLoc = ( (startRange.location > seekLength) ? seekLength : startRange.location);
    return NSMakeRange(startRange.location - minLoc, minLoc);
}

/*!
@function SafeForwardSearchRange( unsigned startLoc, unsigned seekLength, unsigned maxLength )
 @abstract   Returns a range for a forward search that avoids out-of-range exceptions.
 @discussion This is useful if you want to make safe adjustments to ranges, such as making a new range based on
 an existing range plus some offset value, since it gets confusing to keep track of the adjustments.
 @param      (startLoc) The range.location you're starting the search from.
 @param     (seekLength) The desired length to search (usually based on a guess of some sort), from startLoc.
 @param      (maxLoc) The maximum location you're searching to (usually the maximum length of the textview storage)
 @result     An NSRange with your given start as the location and a length corresponding to maxLoc or seekLength.
 */
static inline
NSRange SafeForwardSearchRange( unsigned startLoc, unsigned seekLength, unsigned maxLoc ){
    seekLength = ( (startLoc + seekLength > maxLoc) ? maxLoc - startLoc : seekLength );
    return NSMakeRange(startLoc, seekLength);
}