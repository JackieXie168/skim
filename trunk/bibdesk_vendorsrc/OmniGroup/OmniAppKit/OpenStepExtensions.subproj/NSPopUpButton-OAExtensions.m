// Copyright 1997-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/NSPopUpButton-OAExtensions.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSPopUpButton-OAExtensions.m 74796 2006-05-03 20:08:11Z kc $")

@implementation NSPopUpButton (OAExtensions)

#if !defined(MAC_OS_X_VERSION_10_4) || (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_4)
- (BOOL)selectItemWithTag:(int)tag
{
    NSArray *array;
    int index, count;

    array = [self itemArray];
    count = [array count];
    for (index = 0; index < count; index++) {
        if ([[array objectAtIndex:index] tag] == tag) {
            [self selectItemAtIndex:index];
            return YES;
        }
    }
    return NO;
}
#endif

- (void)selectItemWithRepresentedObject:(id)object;
{
    NSArray *array = [self itemArray];
    unsigned int elementIndex = [array count];
    while (elementIndex--) {
        if (OFISEQUAL([[array objectAtIndex:elementIndex] representedObject], object)) {
            [self selectItemAtIndex:elementIndex];
            return;
        }
    }
}

- (id <NSMenuItem>)itemWithTag:(int)tag
{
    int index = [self indexOfItemWithTag:tag];
    if (index == -1)
        return nil;
    else
        return [self itemAtIndex:index];
}

- (void)addRepresentedObjects:(NSArray *)objects titleSelector:(SEL)titleSelector;
{
    // Don't bother doing anything on nil or empty arrays
    if ([objects count] == 0)
        return;
        
    NSMenu *menu = [self menu];

    unsigned int objectIndex, objectCount;
    for (objectIndex = 0, objectCount = [objects count]; objectIndex < objectCount; objectIndex++) {
        id object = [objects objectAtIndex:objectIndex];
        NSString *title = [object performSelector:titleSelector];
        
        NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:title action:NULL keyEquivalent:@""];
        [newItem setRepresentedObject:object];
        [menu addItem:newItem];
        [newItem release];
    }
}

- (void)addRepresentedObjects:(NSArray *)objects titleKeyPath:(NSString *)keyPath;
{
    // Don't bother doing anything on nil or empty arrays
    if ([objects count] == 0)
        return;
        
    NSMenu *menu = [self menu];

    unsigned int objectIndex, objectCount;
    for (objectIndex = 0, objectCount = [objects count]; objectIndex < objectCount; objectIndex++) {
        id object = [objects objectAtIndex:objectIndex];
        NSString *title = [object valueForKeyPath:keyPath];
        
        NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:title action:NULL keyEquivalent:@""];
        [newItem setRepresentedObject:object];
        [menu addItem:newItem];
        [newItem release];
    }
}

@end
