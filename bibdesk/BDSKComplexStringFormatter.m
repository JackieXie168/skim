//  BDSKComplexStringFormatter.m

//  Created by Michael McCracken on Mon Jul 22 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006,2007
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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

#import "BDSKComplexStringFormatter.h"
#import "BDSKComplexString.h"
#import "NSString_BDSKExtensions.h"
#import "BDSKMacroResolver.h"

@implementation BDSKComplexStringFormatter

- (id)init {
    return [self initWithDelegate:nil macroResolver:nil];
}

- (id)initWithDelegate:(id)anObject macroResolver:(BDSKMacroResolver *)aMacroResolver {
    if (self = [super init]) {
		parsedString = nil;
		parseError = nil;
		highlighted = NO;
		editAsComplexString = NO;
		[self setMacroResolver:aMacroResolver];
		[self setDelegate:anObject];
    }
    return self;
}

- (void)dealloc {
    [macroResolver release];
    [parsedString release];
    [parseError release];
    [super dealloc];
}

#pragma mark Implementation of formatter methods

- (NSString *)stringForObjectValue:(id)obj {
    return obj;
}

- (NSString *)editingStringForObjectValue:(id)obj {
	NSString *string = [self stringForObjectValue:obj];
	[parsedString release];
	parsedString = [obj retain];
	[parseError release];
	parseError = nil;
	if ([obj isComplex] == YES && editAsComplexString == NO) {
		if ([delegate respondsToSelector:@selector(formatter:shouldEditAsComplexString:)])
			editAsComplexString = [delegate formatter:self shouldEditAsComplexString:obj];
	}
	if (editAsComplexString)
		return [string stringAsBibTeXString];
	else
		return string;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)obj withDefaultAttributes:(NSDictionary *)defaultAttrs{

    if(![obj isComplex] && ![obj isInherited])
        return nil;
    
    NSMutableDictionary *attrs = [[NSMutableDictionary alloc] initWithDictionary:defaultAttrs];
	NSColor *color;
	NSString *string = (NSString *)obj;
	
	if ([string isComplex]) {
		if ([string isInherited]) {
			if (highlighted)
				color = [[NSColor blueColor] blendedColorWithFraction:0.5 ofColor:[NSColor controlBackgroundColor]];
			else
				color = [[NSColor blueColor] blendedColorWithFraction:0.4 ofColor:[NSColor controlBackgroundColor]];
		} else {
			if (highlighted)
				color = [[NSColor blueColor] blendedColorWithFraction:0.8 ofColor:[NSColor controlBackgroundColor]];
			else
				color = [NSColor blueColor];
		}
	} else {
		if ([string isInherited]) {
			if (highlighted)
				color = [NSColor lightGrayColor];
			else
				color = [NSColor disabledControlTextColor];
		} else {
			color = [NSColor controlTextColor];
		}
	}
	[attrs setObject:color forKey:NSForegroundColorAttributeName];
    NSAttributedString *attStr = [[[NSAttributedString alloc] initWithString:[self stringForObjectValue:obj] attributes:attrs] autorelease];
    [attrs release];
	return attStr;
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error{
    
    [self setParseError:nil];
    [self setParsedString:nil];
    
    // convert newlines to a single space, then collapse (mainly for paste/drag text, RFE #1457532)
    if([string containsCharacterInSet:[NSCharacterSet newlineCharacterSet]]){
        string = [string stringByReplacingCharactersInSet:[NSCharacterSet newlineCharacterSet] withString:@" "];
        string = [string fastStringByCollapsingWhitespaceAndRemovingSurroundingWhitespace];
    }
    // remove control and other non-characters (mainly for paste/drag text, BUG #1481675)
    string = [string stringByReplacingCharactersInSet:[NSCharacterSet controlCharacterSet] withString:@""];
    string = [string stringByReplacingCharactersInSet:[NSCharacterSet illegalCharacterSet] withString:@""];
    
    @try{
        if (editAsComplexString) {
            [self setParsedString:[NSString stringWithBibTeXString:string macroResolver:macroResolver]];
        } else {
            // not complex, but we check for balanced braces anyway
            [self setParsedString:string];
            if([string isStringTeXQuotingBalancedWithBraces:YES connected:NO] == NO)
                // not really a complex string exception, but we'll handle it the same way
                @throw [NSException exceptionWithName:BDSKComplexStringException reason:NSLocalizedString(@"Unbalanced braces", @"Exception description") userInfo:nil];
        }

    }
    @catch(id anException){
        if([anException isKindOfClass:[NSException class]] && [[anException name] isEqualToString:BDSKComplexStringException])
            [self setParseError:[anException reason]];
        else
            @throw;
    }
    
    // if we use @finally here, this gets executed even if it wasn't our exception
    if(error)
        *error = [self parseError];
    if(obj)
        *obj = [self parsedString];

    return (parseError ? NO : YES);
}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr     
	   proposedSelectedRange:(NSRangePointer)proposedSelRangePtr  
			  originalString:(NSString *)origString 
	   originalSelectedRange:(NSRange)origSelRange
            errorDescription:(NSString **)error{
	// this sets the parsed string or the parse error
	[self getObjectValue:NULL forString:*partialStringPtr errorDescription:NULL];
    // return YES even if not valid or we won't be able to edit
	return YES;
}

#pragma mark Accessors

- (NSString *)parseError {
    return [[parseError retain] autorelease];
}

- (void)setParseError:(NSString *)newError{
    if(parseError != newError){
        [parseError release];
        parseError = [newError copy];
    }
}

- (NSString *)parsedString {
    return [[parsedString retain] autorelease];
}

- (void)setParsedString:(NSString *)newString{
    if(parsedString != newString){
        [parsedString release];
        parsedString = [newString copy];
    }
}

- (id)macroResolver {
    return macroResolver;
}

- (void)setMacroResolver:(BDSKMacroResolver *)newMacroResolver {
    if (macroResolver != newMacroResolver) {
        [macroResolver release];
        macroResolver = [newMacroResolver retain];
    }
}

- (BOOL)editAsComplexString {
	return editAsComplexString;
}

- (void)setEditAsComplexString:(BOOL)newEditAsComplexString {
	if (editAsComplexString != newEditAsComplexString) {
		editAsComplexString = newEditAsComplexString;
	}
}

- (id)delegate {
    return delegate;
}

- (void)setDelegate:(id)newDelegate {
    OBPRECONDITION([newDelegate respondsToSelector:@selector(formatter:shouldEditAsComplexString:)]);
	delegate = newDelegate;
}

- (BOOL)isHighlighted{
	return highlighted;
}

- (void)setHighlighted:(BOOL)flag{
	highlighted = flag;
}

@end
