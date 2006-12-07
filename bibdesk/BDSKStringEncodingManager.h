//
//  BDSKStringEncodingManager.h
//  BibDesk
//
//  Created by Adam Maxwell on 03/01/05.
/*
 This software is Copyright (c) 2005,2006
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

#import <Cocoa/Cocoa.h>


@interface BDSKStringEncodingManager : NSObject {
    NSDictionary *encodingsDict;
}

/*!
    @method     sharedEncodingManager
    @abstract   Returns the shared instance of the encoding manager.
    @discussion The encoding manager maintains a list of all supported string encodings in a displayable format suitable for populating
                a popup button, and is able to match the displayable names with NSStringEncodings.
    @result     (description)
*/
+ (BDSKStringEncodingManager *)sharedEncodingManager;

/*!
    @method     availableEncodings
    @abstract   Returns a dictionary of all available encodings, stored as NSNumber objects.  Keys are the display names for each encoding.
    @discussion Don't use this directly; use one of the wrapper methods. 
    @result     (description)
*/
- (NSDictionary *)availableEncodings;

/*!
    @method     availableEncodingDisplayedNames
    @abstract   Returns a sorted array of encodings as human-readable names, based on Apple's documentation.
    @discussion Useful for populating popup buttons with string encodings.  Some of the names are less readable than others.
    @result     (description)
*/
- (NSArray *)availableEncodingDisplayedNames;


/*!
    @method     encodingNumberForDisplayedName:
    @abstract   Returns the string encoding as an NSNumber object, based on the displayed name.
    @discussion Convenience for storing in preferences or archiving.
    @param      Displayed name.
    @result     (description)
*/
- (NSNumber *)encodingNumberForDisplayedName:(NSString *)name;

/*!
    @method     stringEncodingForDisplayedName:
    @abstract   Returns the actual NSStringEncoding for a given displayed name.
    @discussion (comprehensive description)
    @param      The displayed name, as defined in the internal dictionary (accessed from <tt>availableEncodingDisplayedNames</tt>).
    @result     (description)
*/
- (NSStringEncoding)stringEncodingForDisplayedName:(NSString *)name;

/*!
    @method     displayedNameForStringEncoding:
    @abstract   Given an NSStringEncoding, returns the displayed name for it.
    @discussion (comprehensive description)
    @param      encoding (description)
    @result     (description)
*/
- (NSString *)displayedNameForStringEncoding:(NSStringEncoding)encoding;

@end
