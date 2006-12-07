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

static NSDictionary *WholeDict;
static NSCharacterSet *EmptySet;
static NSCharacterSet *FinalCharSet;
static NSCharacterSet *SkipSet;

@implementation BDSKConverter
+ (void)loadDict{
    
    //create a characterset from the characters we know how to convert

    NSMutableCharacterSet *workingSet;
    NSRange highCharRange;
    NSMutableCharacterSet *tempSet = [[NSMutableCharacterSet alloc] init];
    NSString *texReserved = [NSString stringWithString:@"%"]; // use this for characters that are ASCII but still need to be converted.
    
    WholeDict = [[NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"CharacterConversion.plist"]] retain];
    EmptySet = [[NSCharacterSet characterSetWithCharactersInString:@""] retain];
    
    highCharRange.location = (unsigned int) '~' + 1; //exclude tilde, or we'll get an alert on it
    highCharRange.length = 256; //this should get all the characters in the upper-range.
    workingSet = [[NSCharacterSet decomposableCharacterSet] mutableCopy];
    [workingSet addCharactersInRange:highCharRange];
    [workingSet addCharactersInString:texReserved];

    // Build a dictionary of one-way conversions that we know how to do, then add these to the character set
    NSDictionary *oneWayCharacters = [WholeDict objectForKey:@"One-Way Conversions"];
    NSEnumerator *e = [oneWayCharacters keyEnumerator];
    NSString *oneWayKey;
      while(oneWayKey = [e nextObject]){
	  [workingSet addCharactersInString:oneWayKey];
      }

    FinalCharSet = [workingSet copy];
    [workingSet release];
	
    // build a character set SkipSet of stuff that we do not need to convert
    // making the static NSCharacterSet cuts another second off save time with tugboat.bib
    NSRange skipRange;
    skipRange.location = 0;
    skipRange.length = 127;
    [tempSet addCharactersInRange:skipRange];
    [tempSet removeCharactersInString:texReserved];
    SkipSet = [tempSet copy];
    [tempSet release];

}

+ (NSString *)stringByTeXifyingString:(NSString *)s{
    // s should be in UTF-8 or UTF-16 (i'm not sure which exactly) format (since that's what the property list editor spat)
    // This direction could be faster, since we're comparing characters to the keys, but that'll be left for later.
    OFCharacterScanner *scanner = [[OFStringScanner alloc] initWithString:s];
    NSString *tmpConv = nil;
    NSMutableString *convertedSoFar = [s mutableCopy];
    NSScanner *fastScan = [[NSScanner alloc] initWithString:s];

    int offset=0;
    NSString *TEXString;

    // get the dictionary
    if(!WholeDict)[self loadDict];
    NSMutableDictionary *conversions = [WholeDict objectForKey:@"Roman to TeX"];
    [conversions addEntriesFromDictionary:[WholeDict objectForKey:@"One-Way Conversions"]];
    if(!conversions){
        conversions = [NSDictionary dictionary]; // an empty one won't break the code.
    }

    // convertedSoFar has s to begin with.
    // while scanner's not at eof, scan up to characters from that set into tmpOut

    // fastScan is an NSScanner, which is faster than the OFCharacterScanner (which makes an OFCharacterSet)
    // tell fastScan to skip characters we do not need to convert, then if
    // it picks up something that is not in that range, run OFCharacterScanner
    [fastScan setCharactersToBeSkipped:SkipSet];
	if([fastScan scanCharactersFromSet:FinalCharSet intoString:nil]){
	    while(scannerHasData(scanner)){
			[scanner scanUpToCharacterInSet:FinalCharSet];
			tmpConv = [scanner readCharacterCount:1];
			if(TEXString = [conversions objectForKey:tmpConv]){
				[convertedSoFar replaceCharactersInRange:NSMakeRange((scannerScanLocation(scanner) + offset - 1), 1)
											  withString:TEXString];
				offset += [TEXString length] - 1;    // we're adding length-1 characters, so we have to make sure we insert at the right point in the future.
			}else if(tmpConv != nil){ // if tmpConv is non-nil, we had a character that was accented and not in the dictionary
			      [NSObject cancelPreviousPerformRequestsWithTarget:self 
								       selector:@selector(runConversionAlertPanel:)
								         object:tmpConv];
			    [self performSelector:@selector(runConversionAlertPanel:) withObject:tmpConv afterDelay:0.1];
			     }
	    }
		
    }
	
    //clean up
    [scanner release];
    [fastScan release];
    // shouldn't [tmpConv release]; ? I should look in the omni source code...
    
    return([convertedSoFar autorelease]);
}

+ (void)runConversionAlertPanel:(NSString *)tmpConv{
    NSString *errorString = [NSString localizedStringWithFormat:@"The accented or Unicode character \"%@\" could not be converted.  Please enter the TeX code directly in your bib file.", tmpConv];
    int i = NSRunAlertPanel(NSLocalizedString(@"Character Conversion Error",
				              @"Title of alert when an error happens"),
		            NSLocalizedString(errorString,
				              @"Informative alert text when the error happens."),
			    @"Send e-mail", @"Edit", nil, nil);
    if(i == NSAlertDefaultReturn){
	NSString *urlString = [NSString stringWithFormat:@"mailto:bibdesk-develop@lists.sourceforge.net?subject=Character Conversion Error&body=Please enter a description of the accented character \"%@\" that failed to convert and its TeX equivalent.", tmpConv];
	CFStringRef escapedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)urlString, NULL, NULL, kCFStringEncodingUTF8);
	NSURL *mailURL = [NSURL URLWithString:[(NSString *)escapedString autorelease]];
	[[NSWorkspace sharedWorkspace] openURL:mailURL];
    } else {
    }
}


+ (NSString *)stringByDeTeXifyingString:(NSString *)s{
    NSScanner *scanner = [NSScanner scannerWithString:s];
    NSString *tmpPass;
    NSString *tmpConv;
    NSString *tmpConvB;
    NSString *TEXString;
    NSMutableString *convertedSoFar = [[NSMutableString alloc] initWithCapacity:10];

    // get the dictionary
    NSDictionary *conversions;

    if(!s || [s isEqualToString:@""]){
		return [NSString string];
    }
    
    if(!WholeDict)[self loadDict];
    conversions = [WholeDict objectForKey:@"TeX to Roman"];

    if(!conversions){
        conversions = [NSDictionary dictionary]; // an empty one won't break the code.
    }
    [scanner setCharactersToBeSkipped:EmptySet];
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
    
  return [convertedSoFar autorelease]; 
}
@end
