//
//  OFCharacterSet_BDSKExtensions.m
//  Bibdesk
//
//  Created by Adam Maxwell on 01/02/06.
/*
 This software is Copyright (c) 2006,2006,2007
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

#import "OFCharacterSet_BDSKExtensions.h"

@implementation OFCharacterSet (BDSKExtensions)

static OFCharacterSet *curlyBraceCharacterSet = nil;
static OFCharacterSet *autocompletePunctuationCharacterSet = nil;
static OFCharacterSet *newlineCharacterSet = nil;
static OFCharacterSet *whitespaceCharacterSet = nil;

+ (void)didLoad;
{
    curlyBraceCharacterSet = [[OFCharacterSet alloc] initWithString:@"{}"];
    autocompletePunctuationCharacterSet = [[OFCharacterSet alloc] initWithString:@",:;"];
        
    // character set with all newline characters (including the weird Unicode ones)
    // character set with all newline characters (including the weird Unicode ones)
    CFMutableCharacterSetRef newlineCFCharacterSet = NULL;
    newlineCFCharacterSet = CFCharacterSetCreateMutableCopy(CFAllocatorGetDefault(), CFCharacterSetGetPredefined(kCFCharacterSetWhitespace));
    CFCharacterSetInvert(newlineCFCharacterSet); // no whitespace in this one, but it also has all letters...
    CFCharacterSetIntersect(newlineCFCharacterSet, CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline));
    newlineCharacterSet = [[OFCharacterSet alloc] initWithCharacterSet:(NSCharacterSet *)newlineCFCharacterSet];
    CFRelease(newlineCFCharacterSet);
    
    // whitespaceOFCharacterSet is too limited
    whitespaceCharacterSet = [[OFCharacterSet alloc] initWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
}

+ (OFCharacterSet *)curlyBraceCharacterSet;
{  
    return curlyBraceCharacterSet; 
}    

+ (OFCharacterSet *)autocompletePunctuationCharacterSet;
{
    return autocompletePunctuationCharacterSet;
}

+ (OFCharacterSet *)newlineCharacterSet;
{
    return newlineCharacterSet;
}

+ (OFCharacterSet *)whitespaceCharacterSet;
{
    return whitespaceCharacterSet;
}

@end
