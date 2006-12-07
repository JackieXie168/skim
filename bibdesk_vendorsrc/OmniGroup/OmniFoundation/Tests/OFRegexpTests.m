// Copyright 2000-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OFRegularExpression.h>
#import <OmniFoundation/OFRegularExpressionMatch.h>
#import <OmniFoundation/OFStringScanner.h>
#import <stdio.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Tests/OFRegexpTests.m,v 1.10 2003/01/15 22:52:04 kc Exp $")

void test(OFRegularExpression *rx, NSString *text)
{
    BOOL did;
    
    printf("matching in \"%s\" ... ", [text cString]);
    did = [rx hasMatchInString:text];
    if (did)
        printf("matched\n");
    else
        printf("no match\n");
}

void runtests()
{
    OFRegularExpression *rx;
    
    rx = [[OFRegularExpression alloc] initWithString:@"b( (a))?"];
    NSLog(@"initial test: %@", [[rx matchInString:@"b a"] subexpressionAtIndex:1]);
    
    
    printf("Looking for \"%s\" ... ", [@"foo+" cString]);
    rx = [[OFRegularExpression alloc] initWithString:@"foo+"];
    test(rx, @"foo");
    test(rx, @"fofo");
    test(rx, @"foobar");
    test(rx, @"foboar");
    test(rx, @"barfoo");
    test(rx, @"barfo");
    test(rx, @"fofoobar");
    test(rx, @"fofobooar");
    test(rx, @"fofoo");
    [rx release];
}

void charscantests(NSString *text, NSString *pat)
{
    OFStringScanner *scan = [[OFStringScanner alloc] initWithString:text];
    
    NSLog(@"Finding [%@] in [%@]: %@", pat, text, [scan scanUpToStringCaseInsensitive:pat]?@"found":@"not found");
    NSLog(@"  follows: %@", [scan readLine]);
}

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    runtests();
    
    charscantests(@"blah blah oof blah", @"oof");
    charscantests(@"blah blah ooof blah", @"oof");
    charscantests(@"knurd fofoo blurfl", @"fofoo");
    charscantests(@"knurd fofofoo blurfl", @"fofoo");
    [pool release];
    
    return 0;
}

