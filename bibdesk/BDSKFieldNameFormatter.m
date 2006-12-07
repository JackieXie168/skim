//
//  BDSKFieldNameFormatter.m
//  Bibdesk
//
//  Created by Michael McCracken on Sat Sep 27 2003.
//   See BDSKFieldNameFormatter.h for copyright information.

//
//  File Description: BDSKFieldNameFormatter
//
//  This is a formatter that makes sure you can't enter invalid field names.
//



#import "BDSKFieldNameFormatter.h"


@implementation BDSKFieldNameFormatter

- (NSString *)stringForObjectValue:(id)obj{
    return obj;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)obj withDefaultAttributes:(NSDictionary *)attrs{
    return [[[NSAttributedString alloc] initWithString:[self stringForObjectValue:obj] attributes:attrs] autorelease];
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error{
    *obj = string; // ? retain?
    return YES;
}

// This is currently the same deal as what we check for in cite-keys, but in a different class
// because that may change.

- (BOOL)isPartialStringValid:(NSString *)partialString
            newEditingString:(NSString **)newString
            errorDescription:(NSString **)error{
    NSRange r = [partialString rangeOfCharacterFromSet:[[BibTypeManager sharedManager] invalidFieldNameCharacterSetForFileType:BDSKBibtexString]];
    if ( r.location != NSNotFound)
        return NO;
    else if([partialString length] && [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[partialString characterAtIndex:0]])
        return NO; // BibTeX chokes if the first character of a field name is a digit
    else if([partialString length] && ![[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[partialString characterAtIndex:0]]){
        // this is a BibDesk requirement, since we expect field names to be capitalized
        *newString = [partialString capitalizedString];
        return NO;
    }
    else return YES;
}


@end
