// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniAppKit/NSPopUpButton-OAExtensions.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSPopUpButton-OAExtensions.m,v 1.12 2003/01/15 22:51:38 kc Exp $")

@implementation NSPopUpButton (OAExtensions)

- (void)selectItemWithTag:(int)tag
{
    NSArray *array;
    int index, count;

    array = [self itemArray];
    count = [array count];
    for (index = 0; index < count; index++)
        if ([[array objectAtIndex:index] tag] == tag) {
            [self selectItemAtIndex:index];
            return;
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
    unsigned int objectIndex, objectCount;
    
    // Don't bother doing anything on nil or empty arrays
    if ([objects count] == 0)
        return;
        
    for (objectIndex = 0, objectCount = [objects count]; objectIndex < objectCount; objectIndex++) {
        NSString *title;
        NSMenuItem *item;
        id object;
        
        object = [objects objectAtIndex:objectIndex];
        title = [object performSelector:titleSelector];
        
        [self addItemWithTitle:title];
        item = [self itemAtIndex:[self numberOfItems] - 1];
        [item setRepresentedObject:object];
    }
}

- (void)addRepresentedObjects:(NSArray *)objects titleKeyPath:(NSString *)keyPath;
{
    unsigned int objectIndex, objectCount;
    
    // Don't bother doing anything on nil or empty arrays
    if ([objects count] == 0)
        return;
        
    for (objectIndex = 0, objectCount = [objects count]; objectIndex < objectCount; objectIndex++) {
        NSString *title;
        NSMenuItem *item;
        id object;
        
        object = [objects objectAtIndex:objectIndex];
        title = [object valueForKeyPath:keyPath];
        
        [self addItemWithTitle:title];
        item = [self itemAtIndex:[self numberOfItems] - 1];
        [item setRepresentedObject:object];
    }
}

@end
