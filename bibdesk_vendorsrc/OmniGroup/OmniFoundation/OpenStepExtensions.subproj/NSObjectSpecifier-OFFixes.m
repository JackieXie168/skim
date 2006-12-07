// Copyright 2002-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>
#import <objc/objc-class.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSObjectSpecifier-OFFixes.m,v 1.6 2004/02/10 04:07:46 kc Exp $");

/* Private methods used when converting an NSObjectSpecifier to an NSAppleEventDecriptor (10.2.+ only) */
@interface NSScriptObjectSpecifier (NSPrivateAPI)
- (NSAppleEventDescriptor *)_asDescriptor;
- (BOOL)_putKeyFormAndDataInRecord:(NSAppleEventDescriptor *)aedesc;
@end

@interface NSAppleEventDescriptor (JaguarAPI)
+ (NSAppleEventDescriptor *)descriptorWithInt32:(SInt32)signedInt;
+ (NSAppleEventDescriptor *)descriptorWithString:(NSString *)string;
+ (NSAppleEventDescriptor *)descriptorWithEnumCode:(OSType)enumerator;
+ (NSAppleEventDescriptor *)descriptorWithDescriptorType:(DescType)descriptorType bytes:(const void *)bytes length:(unsigned int)byteCount;
@end


/* This allows us to convert an NSSpecifierTest to its corresponding typeCompDescriptor. */
@interface NSSpecifierTest (OFFixes)
- (NSAppleEventDescriptor *)fixed_asDescriptor;
@end
@implementation NSSpecifierTest (OFFixes)

- (NSAppleEventDescriptor *)fixed_asDescriptor
{
    NSAppleEventDescriptor *seld, *testd, *obj2;
    OSType comparisonOp;


    switch (_comparisonOperator) {
        case NSEqualToComparison: comparisonOp = kAEEquals; break;
        case NSLessThanOrEqualToComparison: comparisonOp = kAELessThanEquals; break;
        case NSLessThanComparison: comparisonOp = kAELessThan; break;
        case NSGreaterThanOrEqualToComparison: comparisonOp = kAEGreaterThanEquals; break;
        case NSGreaterThanComparison: comparisonOp = kAEGreaterThan; break;
        case NSBeginsWithComparison: comparisonOp = kAEBeginsWith; break;
        case NSEndsWithComparison: comparisonOp = kAEEndsWith; break;
        case NSContainsComparison: comparisonOp = kAEContains; break;
        default:
            return nil;
    }

    /* Half-assed conversion of _object2 into an AEDesc */
    if ([_object2 respondsToSelector:@selector(_asDescriptor)])
        obj2 = [_object2 _asDescriptor];
    else if ([_object2 isKindOfClass:[NSNumber class]])
        obj2 = [NSAppleEventDescriptor descriptorWithInt32:[_object2 intValue]];
    else if ([_object2 isKindOfClass:[NSString class]])
        obj2 = [NSAppleEventDescriptor descriptorWithString:_object2];
    else
        return nil;

    testd = [[NSAppleEventDescriptor alloc] initRecordDescriptor];
    [testd setDescriptor:[NSAppleEventDescriptor descriptorWithEnumCode:comparisonOp] forKeyword:keyAECompOperator];
    [testd setDescriptor:[_object1 _asDescriptor] forKeyword:keyAEObject1];
    [testd setDescriptor:obj2 forKeyword:keyAEObject2];

    seld = [testd coerceToDescriptorType:typeCompDescriptor];
    [testd autorelease];
    return seld;
}

@end

/* Patched-up subclass of NSWhoseSpecifier */

@interface OFFixedWhoseSpecifier : NSWhoseSpecifier
{
}

@end

@implementation OFFixedWhoseSpecifier

- (BOOL)_putKeyFormAndDataInRecord:(NSAppleEventDescriptor *)aedesc
{
    BOOL ok;
    NSAppleEventDescriptor *testClause, *ordinalAny;
    const FourCharCode ordinalAnyContents = kAEAny;

    ok = [super _putKeyFormAndDataInRecord:aedesc];
    /* The buggy code does not set anything for the seld keyword. If there is data for that keyword, assume we're running with a non-broken version of Foundation. */
    if (!ok || [aedesc descriptorForKeyword:keyAEKeyData] != nil)
        return ok;

    /* Fix for Apple bug #3137439: NSWhoseDescriptor does not correctly handle the creation of an AEDesc. We create and return a correct descriptor (actually, a nested index/test descriptor). */

    /* Since this code is only here as a workaround until Apple fixes their bug, I'm not implementing the full set of possibilities here, only the cases I expect to encounter. */
    if (![[self test] isKindOfClass:[NSSpecifierTest class]])
        return NO;

    /* Although there is a descriptor form of formWhose, it apparently does not work to return one of these directly in an apple event; we must only return the equivalent nested formIndex and formTest. */
    testClause = [[NSAppleEventDescriptor alloc] initRecordDescriptor];

    [testClause setDescriptor:[aedesc descriptorForKeyword:keyAEDesiredClass] forKeyword:keyAEDesiredClass];
    [testClause setDescriptor:[NSAppleEventDescriptor descriptorWithEnumCode:formTest] forKeyword:keyAEKeyForm];
    [testClause setDescriptor:[(NSSpecifierTest *)[self test] fixed_asDescriptor] forKeyword:keyAEKeyData];
    [testClause setDescriptor:[aedesc descriptorForKeyword:keyAEContainer] forKeyword:keyAEContainer];

    /* This isn't at all correct for the general case; it just handles the one case I'm interested in. */
    [aedesc setDescriptor:[NSAppleEventDescriptor descriptorWithEnumCode:formAbsolutePosition] forKeyword:keyAEKeyForm];
    ordinalAny = [NSAppleEventDescriptor descriptorWithDescriptorType:typeAbsoluteOrdinal bytes:&ordinalAnyContents length:4];
    [aedesc setDescriptor:ordinalAny forKeyword:keyAEKeyData];
    [aedesc setDescriptor:[testClause coerceToDescriptorType:typeObjectSpecifier] forKeyword:keyAEContainer];

    [testClause release];

    return ok;
}

/* Install the fixed class when the program is launched. */
/* static void __attribute__((constructor)) do_posing(void) */
+ (void)performPosing
{
    // don't use +poseAsClass: since that would force +initialize early (and +performPosing gets called w/o forcing it via OBPostLoader).
    class_poseAs((Class)self, ((Class)self)->super_class);
}

@end


