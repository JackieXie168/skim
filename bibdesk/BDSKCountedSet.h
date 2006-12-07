//
//  BDSKCountedSet.h
//  Bibdesk
//
//  Created by Adam Maxwell on 10/31/05.
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

/*!
    @header BDSKCountedSet
    @abstract   Interface to BDSKCountedSet
*/

/*!
    @class BDSKCountedSet
    @abstract    A flexible subclass of NSCountedSet.
    @discussion  Can be used with case-insensitive strings, or any CFDictionaryKeyCallBacks structure for maximum flexibility.  Although this class inherits NSCoding from its superclass, support is not implemented.
*/


@interface BDSKCountedSet : NSCountedSet {
    CFMutableDictionaryRef dictionary;
    BOOL keysAreStrings;
}

/*!
    @method     initWithKeyCallBacks:
    @abstract   Designated initializer for this class.
    @discussion Uses CFDictionaryKeyCallBacks structure for flexibility in key comparison (key meaning the objects in the set).  Don't rely on the usage of a CFDictionary as storage.
    @param      keyCallBacks (description)
    @result     Returns a mutable set that retains each object added (or copies the object, depending on the callbacks supplied).
*/
- (id)initWithKeyCallBacks:(const CFDictionaryKeyCallBacks *)keyCallBacks;
/*!
    @method     initCaseInsensitive:withCapacity:
    @abstract   Assumes a set of string objects.
    @discussion (comprehensive description)
    @param      caseInsensitive Set to YES if you want case-insensitive string key comparisons
    @param      numItems Hint for size of the set (ignored)
    @result     Returns a mutable set that retains each object added.
*/
- (id)initCaseInsensitive:(BOOL)caseInsensitive withCapacity:(unsigned)numItems;

@end

extern const CFDictionaryKeyCallBacks BDSKCaseInsensitiveStringKeyDictionaryCallBacks;
extern const CFSetCallBacks BDSKCaseInsensitiveStringSetCallBacks;
