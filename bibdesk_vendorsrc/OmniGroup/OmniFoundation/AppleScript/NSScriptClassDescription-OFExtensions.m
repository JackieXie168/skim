// Copyright 2006 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSScriptClassDescription-OFExtensions.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/AppleScript/NSScriptClassDescription-OFExtensions.m 77394 2006-07-12 18:20:02Z wiml $");

@implementation NSScriptClassDescription (OFExtensions)

+ (NSScriptClassDescription *)commonScriptClassDescriptionForObjects:(NSArray *)objects;
{
    unsigned int objectIndex = [objects count];
    NSScriptClassDescription *common = nil;
    
    while (objectIndex--) {
	id object = [objects objectAtIndex:objectIndex];
	
	NSScriptClassDescription *desc = (NSScriptClassDescription *)[object classDescription];
	if (!desc)
	    [NSException raise:NSInvalidArgumentException format:@"No class description for %@.", OBShortObjectDescription(object)];
	if (![desc isKindOfClass:[NSScriptClassDescription class]])
	    [NSException raise:NSInvalidArgumentException format:@"Class description for %@ is not a script class description.", OBShortObjectDescription(object)];

	// We expect that objects won't return a synonym class description
	OBASSERT(desc == [desc resolveSynonym]);
	
	if (common) {
	    if ([desc isKindOfScriptClassDescription:common]) {
		// already common
	    } else {
		// Look up desc's ancestors to find something that is a parent of common.
		NSScriptClassDescription *ancestor = desc;
		while (ancestor) {
		    if ([common isKindOfScriptClassDescription:ancestor]) {
			common = ancestor;
			break;
		    }
		    ancestor = [ancestor superclassDescription];
		}
		
		if (!ancestor)
		    // No common class description
		    return nil;
	    }
	} else {
	    common = desc;
	}
    }
    
    return common;
}

- (BOOL)isKindOfScriptClassDescription:(NSScriptClassDescription *)desc;
{
    // The caller should do this work
    OBPRECONDITION(self == [self resolveSynonym]);
    OBPRECONDITION(desc == [desc resolveSynonym]);
    
    NSScriptClassDescription *ancestor = self;
    while (ancestor && ancestor != desc)
	ancestor = [ancestor superclassDescription];
    return (ancestor != nil);
}

// Two different class descriptions can exist for a single class, but one of them might be a synonym (typically on the far side of a to-many relationship).  For example, OmniOutliner has many synonyms for 'row' ('children', 'previous siblings', etc.)
- (NSScriptClassDescription *)resolveSynonym;
{
    Class cls = NSClassFromString([self className]);
    if (!cls)
	[NSException raise:NSInvalidArgumentException format:@"Unable to locate the class '%@' for -%@", [self className], NSStringFromSelector(_cmd)];
    
    NSScriptClassDescription *desc = (NSScriptClassDescription *)[cls classDescription];
    OBPOSTCONDITION(desc); // if nothing else, we should have come back since we have that -className!
    
    return desc;
}

@end
