// Copyright 2002-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFEnumNameTable.h>

#import <OmniBase/OmniBase.h>

#import <OmniFoundation/NSString-OFExtensions.h>
#import <OmniFoundation/OFStringScanner.h>
#import <OmniFoundation/OFXMLCursor.h>
#import <OmniFoundation/OFXMLDocument.h>
#import <OmniFoundation/OFXMLElement.h>
#import <OmniFoundation/CFArray-OFExtensions.h>
#import <OmniFoundation/CFDictionary-OFExtensions.h>
#import <OmniBase/system.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DataStructures.subproj/OFEnumNameTable.m 79079 2006-09-07 22:35:32Z kc $");

/*"
This class is intended for use in a bi-directional mapping between an integer enumeration and string representations for the elements of the enumeration.  This is useful, for example, when converting data structures to and from an external representation.  Instead of encoding internal enumeration values as integers, they can be encoded as string names.  This makes it easier to interpret the external representation and easier to rearrange the private enumeration values without impact to existing external representations in files, defaults property lists, databases, etc.

The implementation does not currently assume anything about the range of the enumeration values.  It would simplify the implementation if we could assume that there was a small set of values, starting at zero and all contiguous.  This is the default for enumerations in C, but certainly isn't required.
"*/
@implementation OFEnumNameTable

// Init and dealloc

- init;
{
    OBRequestConcreteImplementation(isa, _cmd);
    [self release];
    return nil;
}

- initWithDefaultEnumValue: (int) defaultEnumValue;
{
    _defaultEnumValue = defaultEnumValue;

    // Typically the default value will be first, but not always, so we don't set its order here.
    _enumOrder = CFArrayCreateMutable(kCFAllocatorDefault, 0, &OFIntegerArrayCallbacks);

    _enumToName = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &OFIntegerDictionaryKeyCallbacks, &OFNSObjectDictionaryValueCallbacks);
    _enumToDisplayName = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &OFIntegerDictionaryKeyCallbacks, &OFNSObjectDictionaryValueCallbacks);
    _nameToEnum = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &OFNSObjectDictionaryKeyCallbacks, &OFIntegerDictionaryValueCallbacks);
    
    return self;
}

- (void)dealloc;
{
    CFRelease(_enumOrder);
    CFRelease(_enumToName);
    CFRelease(_enumToDisplayName);
    CFRelease(_nameToEnum);
    [super dealloc];
}


// API

- (int) defaultEnumValue;
{
    return _defaultEnumValue;
}

// For cases where we don't care about the localized values.
- (void)setName:(NSString *)enumName forEnumValue:(int)enumValue;
{
    [self setName:enumName displayName:enumName forEnumValue:enumValue];
}

/*" Registers a string name and its corresponding integer enumeration value with the receiver. There must be a one-to-one correspondence between names and values; it is an error for either a name or a value to be duplicated. The order in which name-value pairs are registered determines the ordering used by -nextEnum:. "*/
- (void)setName:(NSString *)enumName displayName:(NSString *)displayName forEnumValue:(int)enumValue;
{
    OBPRECONDITION(enumName);
    OBPRECONDITION(displayName);

    // Note that we aren't enforcing uniqueness of display names... I'm not sure if that is a bug or feature yet
    OBPRECONDITION(!CFDictionaryContainsKey(_enumToDisplayName, (const void *)enumValue));
    OBPRECONDITION(!CFDictionaryContainsKey(_enumToName, (const void *)enumValue));
    OBPRECONDITION(!CFDictionaryContainsKey(_nameToEnum, (const void *)enumName));

    CFArrayAppendValue(_enumOrder, (const void *)enumValue);

    CFDictionarySetValue(_enumToName, (const void *)enumValue, (const void *)enumName);
    CFDictionarySetValue(_enumToDisplayName, (const void *)enumValue, (const void *)displayName);
    CFDictionarySetValue(_nameToEnum, (const void *)enumName, (const void *)enumValue);
}

/*" Returns the string name corresponding to the given integer enumeration value. "*/
- (NSString *) nameForEnum: (int) enumValue;
{
    NSString *name = nil;
    
    if (!CFDictionaryGetValueIfPresent(_enumToName, (const void *)enumValue, (const void **)&name)) {
        // Since the enumeration values are internal, we expect that we know all of them and all are registered.
        [NSException raise: NSInvalidArgumentException format: @"Attempted to get name for unregistered enum value %d", enumValue];
    }
    OBASSERT(name);
    return name;
}

/*" Returns the display name corresponding to the given integer enumeration value. "*/
- (NSString *)displayNameForEnum:(int)enumValue;
{
    NSString *name = nil;

    if (!CFDictionaryGetValueIfPresent(_enumToDisplayName, (const void *)enumValue, (const void **)&name)) {
        // Since the enumeration values are internal, we expect that we know all of them and all are registered.
        [NSException raise: NSInvalidArgumentException format: @"Attempted to get display name for unregistered enum value %d", enumValue];
    }
    OBASSERT(name);
    return name;
}

/*" Returns the integer enumeration value corresponding to the given string. "*/
- (int) enumForName: (NSString *) name;
{
    int enumValue;

    if (!name)
        // Don't require the name -- the external representation might not encode default values
        return _defaultEnumValue;
    
    if (!CFDictionaryGetValueIfPresent(_nameToEnum, (const void *)name, (const void **)&enumValue)) {
        // some unknown name -- the external representation might have been mucked up somehow
        return _defaultEnumValue;
    }
    return enumValue;
}

/*" Tests whether the specified enumeration value has been registered with the receiver.  "*/
- (BOOL) isEnumValue: (int) enumValue;
{
    return CFDictionaryContainsKey(_enumToName, (const void *)enumValue)? YES : NO;
}

/*" Tests whether the specified enumeration name has been registered with the receiver.  "*/
- (BOOL) isEnumName: (NSString *) name;
{
    return name != nil && CFDictionaryContainsKey(_nameToEnum, (const void *)name)? YES : NO;
}

- (unsigned int)count;
{
    OBPRECONDITION(CFArrayGetCount(_enumOrder) == CFDictionaryGetCount(_enumToName));
    OBPRECONDITION(CFArrayGetCount(_enumOrder) == CFDictionaryGetCount(_nameToEnum));
    return CFArrayGetCount(_enumOrder);
}

- (unsigned int)indexForEnum:(int)enumValue;
{
    CFIndex count = CFArrayGetCount(_enumOrder);
    CFRange range = (CFRange){0, count};
    OBASSERT(CFArrayContainsValue(_enumOrder, range, (const void *)enumValue));
    return CFArrayGetFirstIndexOfValue(_enumOrder, range, (const void *)enumValue);
}

- (int)enumForIndex:(unsigned int)enumIndex;
{
    OBASSERT(enumIndex < (unsigned)CFArrayGetCount(_enumOrder));
    return (int)CFArrayGetValueAtIndex(_enumOrder, enumIndex);
}

/*" Returns the 'next' enum value based on the cyclical order defined by the order of name/value definition. "*/
- (int)nextEnum:(int)enumValue;
{
    CFIndex index, count;

    index = [self indexForEnum:enumValue];
    count = [self count];
    index = (index + 1) % count;
    return [self enumForIndex:index];
}

- (NSString *)nextName:(NSString *)name;
{
    return [self nameForEnum:[self nextEnum:[self enumForName:name]]];
}

// Comparison

/*" Compares the receiver's name/value pairs against another instance of OFEnumNameTable. This implementation does not require that the cyclical ordering of the two enumerations be the same for them to compare equal, but callers should probably not rely on this behavior.  This also doesn't require that the display names are equal -- this is intentional. "*/
- (BOOL) isEqual: (id)anotherEnumeration
{
    unsigned int associationCount, associationIndex;
    
    if (anotherEnumeration == self)
        return YES;
    
    if (![anotherEnumeration isMemberOfClass:isa])
        return NO;

    associationCount = [anotherEnumeration count];
    if (associationCount != [self count])
        return NO;
    
    if ([anotherEnumeration defaultEnumValue] != [self defaultEnumValue])
        return NO;

    for (associationIndex = 0; associationIndex < associationCount; associationIndex ++) {
        int anEnumValue = [self enumForIndex:associationIndex];
        if ([anotherEnumeration enumForName:[self nameForEnum:anEnumValue]] != anEnumValue)
            return NO;
    }

    return YES;
}

#pragma mark -
#pragma mark Masks

- (NSString *)copyStringForMask:(unsigned int)mask withSeparator:(unichar)separator;
{
    if (mask == 0)
	return [[self nameForEnum:0] copy];
    
    NSMutableString *result = [[NSMutableString alloc] init];
    
    unsigned int enumIndex, enumCount = [self count];
    for (enumIndex = 0; enumIndex < enumCount; enumIndex++) {
	unsigned int enumValue = [self enumForIndex:enumIndex];
	if (mask & enumValue) { // The 0 entry will fail this trivially so we need not skip it manually
	    NSString *name = [self nameForEnum:enumValue];
	    if ([result length])
		[result appendFormat:@"%C%@", separator, name];
	    else
		[result appendString:name];
	}
    }
    
    return result;
}

- (unsigned int)maskForString:(NSString *)string withSeparator:(unichar)separator;
{
    // Avoid passing nil to -[OFStringScanner initWithString:];
    if ([string isEqualToString:[self nameForEnum:0]] || [NSString isEmptyString:string])
	return 0;
    
    OFStringScanner *scanner = [[OFStringScanner alloc] initWithString:string];
    NSString *name;
    unsigned int mask = 0;
    while ((name = [scanner readFullTokenWithDelimiterCharacter:separator])) {
	mask |= [self enumForName:name];
	[scanner readCharacter];
    }
    [scanner release];
    
    return mask;
}

// Archiving (primarily for OAEnumStyleAttribute)
+ (NSString *)xmlElementName;
{
    return @"enum-name-table";
}

static int _compareInts(const void *arg1, const void *arg2) {
    int int1 = *(int *)arg1;
    int int2 = *(int *)arg2;

    return ( int1 > int2 )? 1 : ( (int1 == int2)? 0 : -1 );
}

- (void)appendXML:(OFXMLDocument *)doc;
{
    [doc pushElement:[isa xmlElementName]];
    {
        [doc setAttribute:@"default-value" integer:_defaultEnumValue];

        // Store elements sorted by enum value
        unsigned int enumIndex, enumCount;
        int *values;
        
        enumCount = CFDictionaryGetCount(_enumToName);
        OBASSERT(enumCount == (unsigned)CFDictionaryGetCount(_nameToEnum));

        values = malloc(sizeof(int *) * enumCount);
        CFDictionaryGetKeysAndValues(_nameToEnum, NULL, (const void **)values);

        qsort(values, enumCount, sizeof(int), _compareInts);

        for (enumIndex = 0; enumIndex < enumCount; enumIndex++) {
            [doc pushElement:@"enum-name-table-element"];
            {
                int enumValue = values[enumIndex];
                [doc setAttribute:@"value" integer:enumValue];

                NSString *name = [self nameForEnum:enumValue];
                NSString *displayName = [self displayNameForEnum:enumValue];
                
                [doc setAttribute:@"name" string:name];

                if (![name isEqualToString:displayName])
                    [doc setAttribute:@"display-name" string:displayName];
            }
            [doc popElement];
        }
        free(values);
    }
    [doc popElement];
}

- initFromXML:(OFXMLCursor *)cursor;
{
    OBPRECONDITION([[cursor name] isEqualToString:[isa xmlElementName]]);

    _defaultEnumValue = [[cursor attributeNamed:@"default-value"] intValue];

    if (!(self = [self initWithDefaultEnumValue:_defaultEnumValue]))
        return nil;
    
    id child;
    while ((child = [cursor nextChild])) {
        if (![child isKindOfClass:[OFXMLElement class]])
            continue;
        OFXMLElement *element = child;

        if (![[element name] isEqualToString:@"enum-name-table-element"])
            continue;

        int value = [[element attributeNamed:@"value"] intValue];
        NSString *name  = [element attributeNamed:@"name"];
        NSString *displayName = [element attributeNamed:@"display-name"];
        
        if (CFDictionaryContainsKey(_enumToName, (const void *)value)) {
            [self release];
            [NSException raise:NSInvalidArgumentException
                        format:@"Unable to unarchive OFEnumNameTable: %@", @"Duplicate enum value"];
        }

        if (CFDictionaryContainsKey(_nameToEnum, (const void *)name)) {
            [self release];
            [NSException raise:NSInvalidArgumentException
                        format:@"Unable to unarchive OFEnumNameTable: %@", @"Duplicate enum name"];
        }

        if (!displayName)
            displayName = name;
        
        [self setName:name displayName:displayName forEnumValue:value];
    }

    if (!CFDictionaryContainsKey(_enumToName, (const void *)_defaultEnumValue)) {
        [self release];
        [NSException raise:NSInvalidArgumentException
                    format:@"Unable to unarchive OFEnumNameTable: %@", @"Missing definition for default enum value"];
    }

    return self;
}

@end
