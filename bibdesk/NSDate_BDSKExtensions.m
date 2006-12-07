//
//  NSDate_BDSKExtensions.m
//  Bibdesk
//
//  Created by Adam Maxwell on 07/29/05.
/*
 This software is Copyright (c) 2005
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

#import "NSDate_BDSKExtensions.h"
#import "BibPrefController.h"

@implementation NSDate (BDSKExtensions)

- (NSDate *)initWithMonthDayYearString:(NSString *)dateString;
{    
    // this strange looking code is here to keep us from leaking an NSCFDate from [NSDate alloc]
    // since we go into an endless loop if we try to release self without doing [self init]
    self = [self init];
    [self release];
    
    static NSDictionary *locale = nil;
    if(locale == nil)
        locale = [[NSDictionary alloc] initWithObjectsAndKeys:@"MDYH", NSDateTimeOrdering, 
            [NSArray arrayWithObjects:@"January", @"February", @"March", @"April", @"May", @"June", @"July", @"August", @"September", @"October", @"November", @"December", nil], NSMonthNameArray,
            [NSArray arrayWithObjects:@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec", nil], NSShortMonthNameArray, nil];
    
    if(CFLocaleCreate == NULL){ // headers say this function exists in 10.3, but Tiger docs say it's 10.4-only.  rdar://4198323        
        return [[NSDate dateWithNaturalLanguageString:dateString locale:locale] retain];
    }
    
    // Create a date formatter that accepts "text month-numeric day-numeric year", which is arguably the most common format in BibTeX
    // NB: formatters are fairly expensive beasts to create, so we cache them here
    static CFDateFormatterRef dateFormatter = NULL;
    if(dateFormatter == NULL){
        // use the en locale, since dates use en short names as keys in BibTeX
        CFLocaleRef enLocale = CFLocaleCreate(CFAllocatorGetDefault(), CFSTR("en"));
        
        // the formatter styles aren't used here, since we set an explicit format
        dateFormatter = CFDateFormatterCreate(CFAllocatorGetDefault(), enLocale, kCFDateFormatterLongStyle, kCFDateFormatterLongStyle);
        if(enLocale) CFRelease(enLocale);
        if(dateFormatter == NULL)
            return nil;
        
        // CFDateFormatter uses ICU formats: http://icu.sourceforge.net/userguide/formatDateTime.html
        CFDateFormatterSetFormat(dateFormatter, CFSTR("MMM-dd-yy"));
        CFDateFormatterSetProperty(dateFormatter, kCFDateFormatterIsLenient, kCFBooleanTrue);            
    }
    CFDateRef date = CFDateFormatterCreateDateFromString(CFAllocatorGetDefault(), dateFormatter, (CFStringRef)dateString, NULL);
    
    if(date != nil)
        return (NSDate *)date;
    
    // If we didn't get a valid date on the first attempt, let's try a purely numeric formatter
    static CFDateFormatterRef numericDateFormatter = NULL;
    if(numericDateFormatter == NULL){
        // use the en locale, since dates use en short names as keys in BibTeX
        CFLocaleRef enLocale = CFLocaleCreate(CFAllocatorGetDefault(), CFSTR("en"));
        
        // the formatter styles aren't used here, since we set an explicit format
        numericDateFormatter = CFDateFormatterCreate(CFAllocatorGetDefault(), enLocale, kCFDateFormatterLongStyle, kCFDateFormatterLongStyle);
        if(enLocale) CFRelease(enLocale);
        if(numericDateFormatter == NULL)
            return nil;
        
        // CFDateFormatter uses ICU formats: http://icu.sourceforge.net/userguide/formatDateTime.html
        CFDateFormatterSetFormat(numericDateFormatter, CFSTR("MM-dd-yy"));
        CFDateFormatterSetProperty(dateFormatter, kCFDateFormatterIsLenient, kCFBooleanTrue);            
    }
    
    date = CFDateFormatterCreateDateFromString(CFAllocatorGetDefault(), numericDateFormatter, (CFStringRef)dateString, NULL);
    
    if(date != nil)
        return (NSDate *)date;
    
    // Now fall back to natural language parsing, which is fairly memory-intensive.
    // We should be able to use NSDateFormatter with the natural language option, but it doesn't seem to work as well as +dateWithNaturalLanguageString
    return [[NSDate dateWithNaturalLanguageString:dateString locale:locale] retain];


}

@end

@implementation NSCalendarDate (BDSKExtensions)

- (NSCalendarDate *)initWithNaturalLanguageString:(NSString *)dateString;
{
    // initWithString should release self when it returns nil
    NSCalendarDate *date = [self initWithString:dateString];

    return (date != nil ? date : [[NSCalendarDate dateWithNaturalLanguageString:dateString] retain]);
}


@end
