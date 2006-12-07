//
//  BDSKDateStringFormatter.m
//  Bibdesk
//
//  Created by Adam Maxwell on 12/03/05.
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

#import "BDSKDateStringFormatter.h"
#import "NSDate_BDSKExtensions.h"

@implementation BDSKDateStringFormatter

/* This is an old-style date formatter, useful with +[NSDate dateWithNaturalLanguageString:].  The main idea here is to return a string object from a date formatter, so if you enter "yesterday" and it's a valid date, it's not converted to "xx/xx/xx" or an NSDate object.
*/
+ (id)shortDateNaturalLanguageFormatter;
{
    id formatter = [[self alloc] initWithDateFormat:[[NSUserDefaults standardUserDefaults] objectForKey:NSShortDateFormatString] allowNaturalLanguage:YES];
    [formatter setGeneratesCalendarDates:YES];
    return [formatter autorelease];
}

- (id)initWithDateFormat:(NSString *)format allowNaturalLanguage:(BOOL)flag;
{
    if(self = [super init])
        dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:format allowNaturalLanguage:flag];
    
    return self;
}

- (void)dealloc;
{
    [dateFormatter release];
    [super dealloc];
}

- (void)setGeneratesCalendarDates:(BOOL)flag;
{
    if([dateFormatter respondsToSelector:_cmd])
        [dateFormatter setGeneratesCalendarDates:flag];
}

- (NSDate *)dateFromString:(NSString *)string;
{
    NSDate *date = [NSDate dateWithColloquialString:string];
    if(date != nil)
        return date;
    
    // @@ 10.4 only
    if([dateFormatter respondsToSelector:_cmd])
        return [dateFormatter dateFromString:string];
    
    return [dateFormatter getObjectValue:&date forString:string errorDescription:NULL] ? date : nil;
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error;
{
    NSDate *date;
    NSString *errorString;
    if([dateFormatter getObjectValue:&date forString:string errorDescription:&errorString] || [NSDate dateWithColloquialString:string]){
        if(anObject)
            *anObject = [[string copy] autorelease];
        return YES;
    } else {
        if(error != nil)
            *error = (errorString != nil ? errorString : NSLocalizedString(@"Couldn't convert to date", @""));
    }
    return NO;
}

- (NSString *)stringForObjectValue:(id)obj;
{
    OBASSERT([obj isKindOfClass:[NSString class]] || obj == nil);    
    //  not my intent, but someone could treat this as a regular date formatter
    return [obj isKindOfClass:[NSString class]] ? [[obj copy] autorelease] : [obj description];
}

- (NSAttributedString *)attributedStringForObjectValue:(id)obj withDefaultAttributes:(NSDictionary *)attrs;
{
    return [[[NSAttributedString alloc] initWithString:[self stringForObjectValue:obj] attributes:attrs] autorelease];
}

@end
