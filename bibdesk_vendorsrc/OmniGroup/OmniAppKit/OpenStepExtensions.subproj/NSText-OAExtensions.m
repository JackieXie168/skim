// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/NSText-OAExtensions.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSText-OAExtensions.m,v 1.23 2004/02/10 04:07:34 kc Exp $")

@implementation NSText (OAExtensions)

- (IBAction)jumpToSelection:(id)sender;
{
    [self scrollRangeToVisible:[self selectedRange]];
}

- (unsigned int)textLength;
{
    return [[self string] length];
}

- (void)appendTextString:(NSString *)string;
{
    NSRange endRange;

    if ([NSString isEmptyString:string])
	return;
    endRange = NSMakeRange([self textLength], 0);
    [self replaceCharactersInRange:endRange withString:string];
}

- (void)appendRTFData:(NSData *)data;
{
    NSRange endRange;

    if (data == nil || [data length] == 0)
	return;
    endRange = NSMakeRange([self textLength], 0);
    [self replaceCharactersInRange:endRange withRTF:data];
}

- (void)appendRTFDData:(NSData *)data;
{
    NSRange endRange;

    if (data == nil || [data length] == 0)
	return;
    endRange = NSMakeRange([self textLength], 0);
    [self replaceCharactersInRange:endRange withRTFD:data];
}

- (void)appendRTFString:(NSString *)string;
{
    NSData *rtfData;
    NSRange endRange;

    if ([NSString isEmptyString:string])
	return;
    rtfData = [string dataUsingEncoding:[NSString defaultCStringEncoding] allowLossyConversion:YES];
    endRange = NSMakeRange([self textLength], 0);
    [self replaceCharactersInRange:endRange withRTF:rtfData];
}

- (NSData *)textData;
{
    return [[self string] dataUsingEncoding:[NSString defaultCStringEncoding] allowLossyConversion:YES];
}

- (NSData *)rtfData;
{
    return [self RTFFromRange:NSMakeRange(0, [self textLength])];
}

- (NSData *)rtfdData;
{
    return [self RTFDFromRange:NSMakeRange(0, [self textLength])];
}

- (void)setRTFData:(NSData *)rtfData;
{
    [self replaceCharactersInRange:NSMakeRange(0, [self textLength]) withRTF:rtfData];
}

- (void)setRTFDData:(NSData *)rtfdData;
{
    [self replaceCharactersInRange:NSMakeRange(0, [self textLength]) withRTFD:rtfdData];
}

- (void)setRTFString:(NSString *)string;
{
    NSData *rtfData;
    NSRange fullRange;

    rtfData = [string dataUsingEncoding:[NSString defaultCStringEncoding] allowLossyConversion:YES];
    fullRange = NSMakeRange(0, [self textLength]);
    [self replaceCharactersInRange:fullRange withRTF:rtfData];
}

- (void)setTextFromString:(NSString *)aString;
{
    [self setString:aString != nil ? aString : @""];
}

- (NSString *)substringWithRange:(NSRange)aRange;
{
    NS_DURING {
	NSString *substring;

        substring = [[self string] substringWithRange:aRange];
	NS_VALUERETURN(substring, NSString *);
    } NS_HANDLER {
	return @"";
    } NS_ENDHANDLER;
}

// OAFindControllerAware informal protocol

- (id <OAFindControllerTarget>)omniFindControllerTarget;
{
    return self;
}

// OAFindControllerTarget

- (BOOL)findPattern:(id <OAFindPattern>)pattern backwards:(BOOL)backwards wrap:(BOOL)wrap;
{
    if ([self findPattern:pattern backwards:backwards ignoreSelection:NO])
        return YES;

    if (!wrap)
        return NO;

    // Try again, ignoring the selection and searching from one end or the other.
    return [self findPattern:pattern backwards:backwards ignoreSelection:YES];
}

// OASearchableContent protocol

- (BOOL)findPattern:(id <OAFindPattern>)pattern backwards:(BOOL)backwards ignoreSelection:(BOOL)ignoreSelection;
{
    NSString *string;
    unsigned int stringLength;
    NSRange searchedRange, selectedRange, range;
    BOOL found;

    string = [self string];
    if (!string || (stringLength = [string length]) == 0)
        return NO;

    if (ignoreSelection)
        found = [pattern findInString:string foundRange:&range];
    else {
        selectedRange = [self selectedRange];
        if (backwards)
            searchedRange = NSMakeRange(0, selectedRange.location);
        else
            searchedRange = NSMakeRange(NSMaxRange(selectedRange), stringLength - NSMaxRange(selectedRange));
        found = [pattern findInRange:searchedRange ofString:string foundRange:&range];
    }
            
    if (found) {
        [self setSelectedRange:range];
        [self scrollRangeToVisible:range];
        [[self window] makeFirstResponder:self];
    }
    return found;
}

@end

@implementation NSTextView (OAExtensions)

- (unsigned int)textLength;
{
    return [[self textStorage] length];
}

- (void)replaceSelectionWithString:(NSString *)aString;
{
    NSTextStorage *textStorage;
    NSRange selectedRange;
    
    selectedRange = [self selectedRange];
    textStorage = [self textStorage];
    // this is almost guaranteed to succeed by the time we get here, but going through -shouldChangeTextInRange:withString: is what hooks us into the undo manager.
    if ([self isEditable] && [self shouldChangeTextInRange:selectedRange replacementString:aString]) {
        [textStorage replaceCharactersInRange:selectedRange withString:aString];
        [self didChangeText];
        selectedRange.length = [aString length];
        [self setSelectedRange:selectedRange];
    } else {
        NSBeep();
    }
}

- (void)replaceAllOfPattern:(id <OAFindPattern>)pattern inRange:(NSRange)searchRange;
{
    NSTextStorage *textStorage;
    NSString *string, *replacement;
    NSRange range;
    
    textStorage = [self textStorage];
    string = [textStorage string];
    while (searchRange.length != 0) {
        if (![pattern findInRange:searchRange ofString:string foundRange:&range])
            break;

        replacement = [pattern replacementStringForLastFind];
        // this is almost guaranteed to succeed by the time we get here, but going through -shouldChangeTextInRange:withString: is what hooks us into the undo manager.
        if ([self isEditable] && [self shouldChangeTextInRange:range replacementString:replacement]) {
            [textStorage replaceCharactersInRange:range withString:replacement];
            [self didChangeText];
        } else {
            NSBeep();
        }
        OBINVARIANT(string == [self string]); // Or we should cache it again
        searchRange.location = range.location + [replacement length];
        searchRange.length = [string length] - searchRange.location;
    }
}

- (void)replaceAllOfPattern:(id <OAFindPattern>)pattern;
{
    [self replaceAllOfPattern:pattern inRange:NSMakeRange(0, [[self string] length])];
}

- (void)replaceAllOfPatternInCurrentSelection:(id <OAFindPattern>)pattern;
{
    [self replaceAllOfPattern:pattern inRange:[self selectedRange]];
}

@end
