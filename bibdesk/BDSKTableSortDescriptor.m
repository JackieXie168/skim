//
//  BDSKTableSortDescriptor.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 12/11/05.
/*
 This software is Copyright (c) 2005,2006,2007
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

#import "BDSKTableSortDescriptor.h"
#import <OmniBase/assertions.h>
#import <OmniBase/OBUtilities.h>
#import <OmniFoundation/NSString-OFExtensions.h>
#import "BibTypeManager.h"

@interface NSObject (FastKVC)

@end

@implementation NSObject (FastKVC)

// Foundation's implementation of valueForKeyPath: uses substringToIndex: to parse the keypath, which ends up creating a lot of autoreleased objects when called in a loop (as when sorting an array).  Here we should create 2 * N strings per call, where N is the number of dots in the key path, but they are released immediately.  The ugly method name is to avoid current and future conflicts with Apple method names.

- (id)bdsk_valueForKeyPath:(NSString *)aKey
{
    Boolean foundDot;
    CFRange rangeOfDot;
    CFIndex keyPathLength = CFStringGetLength((CFStringRef)aKey);
    foundDot = CFStringFindWithOptions((CFStringRef)aKey, CFSTR("."), CFRangeMake(0, keyPathLength), 0, &rangeOfDot);
    
    id value = nil;
    
    if(foundDot == FALSE){
        value = [self valueForKey:aKey];
    } else {
        CFAllocatorRef alloc = CFAllocatorGetDefault();
        CFStringRef firstKey = CFStringCreateWithSubstring(alloc, (CFStringRef)aKey, CFRangeMake(0, rangeOfDot.location));
        CFIndex nextStartingIndex = rangeOfDot.location + rangeOfDot.length;
        CFStringRef restOfPath = CFStringCreateWithSubstring(alloc, (CFStringRef)aKey, CFRangeMake(nextStartingIndex, keyPathLength - nextStartingIndex));
        value = [[self valueForKey:(NSString *)firstKey] bdsk_valueForKeyPath:(NSString *)restOfPath];

        CFRelease(firstKey);
        CFRelease(restOfPath);
    }
    
    return value;
}

@end

@implementation BDSKTableSortDescriptor

+ (BDSKTableSortDescriptor *)tableSortDescriptorForIdentifier:(NSString *)tcID ascending:(BOOL)ascend{

    NSParameterAssert([NSString isEmptyString:tcID] == NO);
    
    BDSKTableSortDescriptor *sortDescriptor = nil;
    
	if([tcID isEqualToString:BDSKCiteKeyString]){
		sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"citeKey" ascending:ascend selector:@selector(localizedCaseInsensitiveNumericCompare:)];
        
	}else if([tcID isEqualToString:BDSKTitleString]){
		
		sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"title.stringByRemovingTeXAndStopWords" ascending:ascend selector:@selector(localizedCaseInsensitiveCompare:)];
		
	}else if([tcID isEqualToString:BDSKContainerString]){
		
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"container.stringByRemovingTeXAndStopWords" ascending:ascend selector:@selector(localizedCaseInsensitiveCompare:)];
        
	}else if([tcID isEqualToString:BDSKPubDateString]){
		
		sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"date" ascending:ascend selector:@selector(compare:)];		
        
	}else if([tcID isEqualToString:BDSKDateAddedString]){
		
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"dateAdded" ascending:ascend selector:@selector(compare:)];
        
	}else if([tcID isEqualToString:BDSKDateModifiedString]){
		
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"dateModified" ascending:ascend selector:@selector(compare:)];
        
	}else if([tcID isEqualToString:BDSKFirstAuthorString] ||
             [tcID isEqualToString:BDSKAuthorString]){
        
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"firstAuthor" ascending:ascend selector:@selector(sortCompare:)];
        
	}else if([tcID isEqualToString:BDSKSecondAuthorString]){
		
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"secondAuthor" ascending:ascend selector:@selector(sortCompare:)];
		
	}else if([tcID isEqualToString:BDSKThirdAuthorString]){
		
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"thirdAuthor" ascending:ascend selector:@selector(sortCompare:)];
        
	}else if([tcID isEqualToString:BDSKLastAuthorString]){
		
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"lastAuthor" ascending:ascend selector:@selector(sortCompare:)];
        
	}else if([tcID isEqualToString:BDSKFirstAuthorEditorString] ||
             [tcID isEqualToString:BDSKAuthorEditorString]){
        
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"firstAuthorOrEditor" ascending:ascend selector:@selector(sortCompare:)];
        
	}else if([tcID isEqualToString:BDSKSecondAuthorEditorString]){
		
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"secondAuthorOrEditor" ascending:ascend selector:@selector(sortCompare:)];
		
	}else if([tcID isEqualToString:BDSKThirdAuthorEditorString]){
		
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"thirdAuthorOrEditor" ascending:ascend selector:@selector(sortCompare:)];
        
	}else if([tcID isEqualToString:BDSKLastAuthorEditorString]){
		
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"lastAuthorOrEditor" ascending:ascend selector:@selector(sortCompare:)];
        
	}else if([tcID isEqualToString:BDSKEditorString]){
		
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"pubEditors.@firstObject" ascending:ascend selector:@selector(sortCompare:)];

	}else if([tcID isEqualToString:BDSKPubTypeString]){

        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"pubType" ascending:ascend selector:@selector(localizedCaseInsensitiveCompare:)];
        
    }else if([tcID isEqualToString:BDSKItemNumberString] || [tcID isEqualToString:BDSKImportOrderString]){
        
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"fileOrder" ascending:ascend selector:@selector(compare:)];		
        
    }else if([tcID isEqualToString:BDSKBooktitleString]){
        
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:@"Booktitle.stringByRemovingTeXAndStopWords" ascending:ascend selector:@selector(localizedCaseInsensitiveCompare:)];
        
    }else if([tcID isBooleanField] || [tcID isTriStateField]){
        
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:tcID ascending:ascend selector:@selector(triStateCompare:)];
        
    }else if([tcID isRatingField]){
        
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:tcID ascending:ascend selector:@selector(numericCompare:)];
        
    }else if([tcID isRemoteURLField]){
        
        // compare pathExtension for URL fields so the subsort is more useful
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:tcID ascending:ascend selector:@selector(extensionCompare:)];

    }else if([tcID isLocalFileField]){
        
        // compare UTI for file fields so the subsort is more useful
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:tcID ascending:ascend selector:@selector(UTICompare:)];
        
    }else{
        
        // this assumes that all other columns must be NSString objects
        sortDescriptor = [[BDSKTableSortDescriptor alloc] initWithKey:tcID ascending:ascend selector:@selector(localizedCaseInsensitiveNumericCompare:)];
        
	}
 
    OBASSERT(sortDescriptor);
    return [sortDescriptor autorelease];
}

- (void)cacheKeys;
{
    // cache the components of the keypath and their count
    keys = CFArrayCreateCopy(CFAllocatorGetDefault(), (CFArrayRef)[[self key] componentsSeparatedByString:@"."]);
    keyCount = CFArrayGetCount(keys);
}

- (id)initWithKey:(NSString *)key ascending:(BOOL)flag selector:(SEL)theSel;
{
    if(self = [super initWithKey:key ascending:flag selector:theSel]){
        [self cacheKeys];
        
        // since NSSortDescriptor ivars are declared @private, we have to use @defs to access them directly; use our own instead, since this won't be subclassed
        selector = theSel;
        ascending = flag;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];
    [self cacheKeys];
    selector = [self selector];
    ascending = [self ascending];
    return self;
}

- (id)copyWithZone:(NSZone *)aZone
{
    return [[[self class] allocWithZone:aZone] initWithKey:[self key] ascending:[self ascending] selector:[self selector]];
}

- (void)dealloc
{
    CFRelease(keys);
    [super dealloc];
}

static inline void __GetValuesUsingCache(BDSKTableSortDescriptor *sort, id object1, id object2, id *value1, id *value2)
{
    CFIndex i;
    *value1 = object1;
    *value2 = object2;
    NSString *key;
    
    // storing the array as an NSString ** buffer really didn't help with performance, but using CFArray functions does help cut down on the objc overhead
    for(i = 0; i < sort->keyCount; i++){
        key = (NSString *)CFArrayGetValueAtIndex(sort->keys, i);
        *value1 = [*value1 valueForKey:key];
        *value2 = [*value2 valueForKey:key];
    }
}

- (NSComparisonResult)compareEndObject:(id)value1 toEndObject:(id)value2;
{
    // check to see if one of the values is nil
    if(value1 == nil){
        if(value2 == nil)
            return NSOrderedSame;
        else
            return (ascending ? NSOrderedDescending : NSOrderedAscending);
    } else if(value2 == nil){
        return (ascending ? NSOrderedAscending : NSOrderedDescending);
        // this check only applies to NSString objects
    } else if([value1 isKindOfClass:[NSString class]] && [value2 isKindOfClass:[NSString class]]){
        if ([value1 isEqualToString:@""]) {
            if ([value2 isEqualToString:@""]) {
                return NSOrderedSame;
            } else {
                return (ascending ? NSOrderedDescending : NSOrderedAscending);
            }
        } else if ([value2 isEqualToString:@""]) {
            return (ascending ? NSOrderedAscending : NSOrderedDescending);
        }
    } 	
    
    // we use the IMP directly since performSelector: returns an id
    typedef NSComparisonResult (*comparatorIMP)(id, SEL, id);
    comparatorIMP comparator = (comparatorIMP)[value1 methodForSelector:selector];
    NSComparisonResult result = comparator(value1, selector, value2);
    
    return ascending ? result : (result *= -1);
}

- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2 {

    id value1, value2;
    OBASSERT_NOT_REACHED("Inefficient code path; use -[NSArray sortedArrayUsingMergesortWithDescriptors:] instead");
    // get the values in bulk; since the same keypath is used for both objects, why compute it twice?
    __GetValuesUsingCache(self, object1, object2, &value1, &value2);
    return [self compareEndObject:value1 toEndObject:value2];
}

@end
