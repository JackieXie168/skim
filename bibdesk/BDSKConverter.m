//  BDSKConverter.m
//  Created by Michael McCracken on Thu Mar 07 2002.
/*
This software is Copyright (c) 2001,2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BDSKConverter.h"

@implementation BDSKConverter
+ (NSString *)stringByTeXifyingString:(NSString *)s{
    // s should be in UTF-8 or UTF-16 (i'm not sure which exactly) format (since that's what the property list editor spat)
    // This direction could be faster, since we're comparing characters to the keys, but that'll be left for later.
    OFCharacterScanner *scanner = [[OFStringScanner alloc] initWithString:s];
    NSString *tmpConv = nil;
    NSMutableString *convertedSoFar = [s mutableCopy];

    //create a characterset from the characters we know how to convert
    NSCharacterSet *finalInvertedCharSet;
    NSCharacterSet *finalCharSet;
    NSMutableCharacterSet *workingSet;
    NSRange highCharRange;
    int offset=0;
    NSString *TEXString;

    // get the dictionary
    NSDictionary *WholeDict = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"CharacterConversion.plist"]];
    NSDictionary *conversions = [WholeDict objectForKey:@"Roman to TeX"];
    if(!conversions){
        conversions = [NSDictionary dictionary]; // an empty one won't break the code.
    }

    highCharRange.location = (unsigned int) '~';
    highCharRange.length = 128; //this should get all the characters in the upper-range.
    workingSet = [[NSCharacterSet decomposableCharacterSet] mutableCopy];
    [workingSet addCharactersInRange:highCharRange];
    finalCharSet = [workingSet copy];
    finalInvertedCharSet = [finalCharSet invertedSet];
   

    // Now the character set is ready.
    // convertedSoFar has s to begin with.
    // while scanner's not at eof, scan up to characters from that set into tmpOut
    while(scannerHasData(scanner)){
        [scanner scanUpToCharacterInSet:finalCharSet];
        tmpConv = [scanner readCharacterCount:1];
        if(TEXString = [conversions objectForKey:tmpConv]){
            [convertedSoFar replaceCharactersInRange:NSMakeRange((scannerScanLocation(scanner) + offset - 1), 1)
                                          withString:TEXString];
            offset += [TEXString length] - 1;    // we're adding length-1 characters, so we have to make sure we insert at the right point in the future.
        }else{

        }

    }

    //clean up
    [scanner release];
    // shouldn't [tmpConv release]; ? I should look in the omni source code...
    [finalCharSet release];
    
    [workingSet release];
    
    return([NSString stringWithString:convertedSoFar]);
}


+ (NSString *)stringByDeTeXifyingString:(NSString *)s{
    NSScanner *scanner = [NSScanner scannerWithString:s];
    NSString *tmpPass;
    NSString *tmpConv;
    NSString *tmpConvB;
    NSString *TEXString;
    NSMutableString *convertedSoFar = [NSMutableString string];
    NSCharacterSet *emptySet = [NSCharacterSet characterSetWithCharactersInString:@""];

    // get the dictionary
    NSDictionary *WholeDict;
    NSDictionary *conversions;

    if(!s || [s isEqualToString:@""])
        return [NSString stringWithString:@""];
    
    WholeDict = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"CharacterConversion.plist"]];
    conversions = [WholeDict objectForKey:@"TeX to Roman"];

    if(!conversions){
        conversions = [NSDictionary dictionary]; // an empty one won't break the code.
    }
    [scanner setCharactersToBeSkipped:emptySet];
    //    NSLog(@"scanning string: %@",s);
    while(![scanner isAtEnd]){
        if([scanner scanUpToString:@"{\\" intoString:&tmpPass])
            [convertedSoFar appendString:tmpPass];
        if([scanner scanUpToString:@"}" intoString:&tmpConv]){
            tmpConvB = [NSString stringWithFormat:@"%@}", tmpConv];
            if(TEXString = [conversions objectForKey:tmpConvB]){
                [convertedSoFar appendString:TEXString];
                [scanner scanString:@"}" intoString:nil];
            }else{
                [convertedSoFar appendString:tmpConvB];
                // if there's another rightbracket hanging around, we want to scan past it:
                [scanner scanString:@"}" intoString:nil];
                // but what if that was the end?
            }
        }
    }

    return [NSString stringWithString:convertedSoFar];    
}
@end
