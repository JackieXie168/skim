// Copyright 2004-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFBinding.h"

#import <Cocoa/Cocoa.h>
#import <OmniBase/OmniBase.h>

#import "OFNull.h" // For OFISEQUAL()

#define DEBUG_KVO 0

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OFBinding.m 79089 2006-09-07 23:41:01Z kc $");

@interface OFBinding (Private)
- (void)_register;
- (void)_deregister;
@end

@implementation OFBinding

+ (id)allocWithZone:(NSZone *)zone;
{
    OBPRECONDITION((self == [OFBinding class]) || (self == [OFObjectBinding class]) || (self == [OFArrayBinding class]) || (self == [OFSetBinding class]));
    if (self == [OFBinding class])
	return [OFObjectBinding allocWithZone:zone];
    return [super allocWithZone:zone];
}

- initWithSourceObject:(id)sourceObject sourceKey:(NSString *)sourceKey
     destinationObject:(id)destinationObject destinationKey:(NSString *)destinationKey;
{
    OBPRECONDITION(sourceObject);
    OBPRECONDITION(sourceKey);
    OBPRECONDITION(destinationObject);
    OBPRECONDITION(destinationKey);
#ifdef OMNI_ASSERTIONS_ON
    // Make sure the source will respond to this key
    [sourceObject valueForKey:sourceKey];
#endif
    
    _sourceObject = [sourceObject retain];
    _sourceKey = [sourceKey copy];
    _nonretained_destinationObject = destinationObject;
    _destinationKey = [destinationKey copy];
    
    [self enable];
    
    // Caller is responsible for setting up the initial value
    
    OBPOSTCONDITION([self isEnabled]);
    return self;
}

- (void)dealloc;
{
    [self invalidate];
    [super dealloc];
}

- (void)invalidate;
{
#if DEBUG_KVO
    NSLog(@"binding %p invalidated:%p %@.%@", self, _sourceObject, [_sourceObject shortDescription], [self sourceKey]);
#endif
    
    if (_registered)
        [self _deregister];
    
    if ([_sourceObject respondsToSelector:@selector(bindingWillInvalidate:)])
	[_sourceObject bindingWillInvalidate:self];
    [_sourceObject release];
    _sourceObject = nil;
    
    [_sourceKey release];
    _sourceKey = nil;
    
    [_destinationKey release];
    _destinationKey = nil;
    
    _nonretained_destinationObject = nil;
}

- (BOOL)isEnabled;
{
    return _enabledCount > 0;
}

- (void)enable;
{
    BOOL wasEnabled = [self isEnabled];
    _enabledCount++;
    BOOL newEnabled = [self isEnabled];
    if (!wasEnabled && newEnabled)
	[self _register];
}

- (void)disable;
{
    OBPRECONDITION(_enabledCount > 0);

    BOOL wasEnabled = [self isEnabled];
    _enabledCount--;
    BOOL newEnabled = [self isEnabled];
    if (wasEnabled && !newEnabled)
	[self _deregister];
}

- (void)reset;
{
    [_sourceObject reset];
}

- (id)sourceObject;
{
    return _sourceObject;
}

- (NSString *)sourceKey;
{
    return _sourceKey;
}

- (id)destinationObject;
{
    return _nonretained_destinationObject;
}

- (NSString *)destinationKey;
{
    return _destinationKey;
}

- (id)currentValue;
{
    return [_sourceObject valueForKey:_sourceKey];
}

- (void)propagateCurrentValue;
{
    [_nonretained_destinationObject setValue:[_sourceObject valueForKey:_sourceKey] forKeyPath:_destinationKey];
}

- (NSString *)humanReadableDescription;
{
    return [_sourceObject humanReadableDescriptionForKey:_sourceKey];
}

- (NSString *)shortHumanReadableDescription;
{
    return [_sourceObject shortHumanReadableDescriptionForKey:_sourceKey];
}

- (BOOL)isEqualConsideringSourceAndKey:(OFBinding *)otherBinding;
{
    return [_sourceObject isEqual:[otherBinding sourceObject]] && [_sourceKey isEqual:[otherBinding sourceKey]];
}

// Use the hash of the key.  This will provide less dispersal of values, but then the source don't need to implement hash.
- (unsigned)hash;
{
    return [_sourceKey hash];
}

#pragma mark -
#pragma mark NSObject (NSKeyValueObserving)

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
    OBRequestConcreteImplementation(self, _cmd);
}

#pragma mark -
#pragma mark Debugging

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *dict = [super debugDictionary];
    [dict setValue:_sourceObject forKey:@"sourceObject"];
    [dict setValue:_sourceKey forKey:@"sourceKey"];
    [dict setValue:_nonretained_destinationObject forKey:@"destinationObject"];
    [dict setValue:_destinationKey forKey:@"destinationKey"];
    return dict;
}

@end


@implementation OFBinding (Private)

- (NSKeyValueObservingOptions)_options;
{
    // Most need only the new.
    return NSKeyValueObservingOptionNew;
}

- (void)_register;
{
    OBPRECONDITION(_sourceObject);
    OBPRECONDITION(_sourceKey);
    OBPRECONDITION(_destinationKey);
    OBPRECONDITION(_nonretained_destinationObject);
    
    OBPRECONDITION(!_registered);
    if (_registered) // don't double-register if there is a programming error
	return;
    
    
    NSKeyValueObservingOptions options = [self _options];
    [_sourceObject addObserver:self forKeyPath:_sourceKey options:options context:NULL];
    
    _registered = YES;
#if DEBUG_KVO
    NSLog(@"binding %p observing:%@.%@", self, [_sourceObject shortDescription], _sourceKey);
#endif
}

- (void)_deregister;
{
    OBPRECONDITION(_registered);
    if (!_registered) // don't null-deregister if there is a programming error
	return;

    [_sourceObject removeObserver:self forKeyPath:_sourceKey];
    _registered = NO;

#if DEBUG_KVO
    NSLog(@"binding %p ignoring:%p.%@", self, [_sourceObject shortDescription], _sourceKey);
#endif
}

@end

static void _handleSetValue(id sourceObject, NSString *sourceKey, id destinationObject, NSString *destinationKey, NSDictionary *change)
{
    // Possibly faster than looking it up via a key path
    id value = [change objectForKey:NSKeyValueChangeNewKey];
    OBASSERT(OFISEQUAL(value, [sourceObject valueForKeyPath:sourceKey]));
    
    [destinationObject setValue:value forKeyPath:destinationKey];
}

@implementation OFObjectBinding

#pragma mark -
#pragma mark NSObject (NSKeyValueObserving)

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
    OBPRECONDITION([keyPath isEqualToString:_sourceKey]);
    OBPRECONDITION(object == _sourceObject);
    
#if DEBUG_KVO
    //if (![_sourceObject isKindOfClass:[ODEventPlaybackEventSource class]] && ![_sourceObject isKindOfClass:[ODTimeParametricEventSource class]])
    NSLog(@"binding %p observe %@.%@ -- propagating to %@.%@, change %@", self, [_sourceObject shortDescription], _sourceKey, [_nonretained_destinationObject shortDescription], _destinationKey, change);
#endif
    
    // The destination may cause us to get freed when we notify it.  Our caller doesn't like it when we are dead when we return.
    [[self retain] autorelease];
    
    NSNumber *kind = [change objectForKey:NSKeyValueChangeKindKey];
    switch ((NSKeyValueChange)[kind intValue]) {
	case NSKeyValueChangeSetting: {
	    _handleSetValue(_sourceObject, _sourceKey, _nonretained_destinationObject, _destinationKey, change);
	    break;
	}
	default: {
	    [NSException raise:NSInvalidArgumentException format:@"Don't know how to handle change %@", change];
	}
    }
}

@end

// Ordered to-many properties
@implementation OFArrayBinding

#pragma mark -
#pragma mark NSObject (NSKeyValueObserving)

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
    OBPRECONDITION([keyPath isEqualToString:_sourceKey]);
    OBPRECONDITION(object == _sourceObject);
    
#if DEBUG_KVO
    //if (![_sourceObject isKindOfClass:[ODEventPlaybackEventSource class]] && ![_sourceObject isKindOfClass:[ODTimeParametricEventSource class]])
    NSLog(@"binding %p observe %@.%@ -- propagating to %@.%@, change %@", self, [_sourceObject shortDescription], _sourceKey, [_nonretained_destinationObject shortDescription], _destinationKey, change);
#endif
    
    // The destination may cause us to get freed when we notify it.  Our caller doesn't like it when we are dead when we return.
    [[self retain] autorelease];
    
    NSNumber *kind = [change objectForKey:NSKeyValueChangeKindKey];
    switch ((NSKeyValueChange)[kind intValue]) {
	case NSKeyValueChangeSetting: {
	    _handleSetValue(_sourceObject, _sourceKey, _nonretained_destinationObject, _destinationKey, change);
	    break;
	}
	case NSKeyValueChangeInsertion: {
	    NSArray *inserted = [change objectForKey:NSKeyValueChangeNewKey];
	    NSIndexSet *indexes = [change objectForKey:NSKeyValueChangeIndexesKey];
	    OBASSERT(inserted);
	    OBASSERT(indexes);
	    OBASSERT([inserted count] == [indexes count]);
	    
	    if ([indexes count] != 1)
		// How do we handle the fact that inserting at lower indexes shifts the meaning of higher indexes?
		[NSException raise:NSInvalidArgumentException format:@"Don't know how to handle multiple-index insertions %@", change];
	    
	    [_nonretained_destinationObject insertValue:[inserted objectAtIndex:0] atIndex:[indexes firstIndex] inPropertyWithKey:_destinationKey];
	    break;
	}
	case NSKeyValueChangeRemoval: {
	    NSIndexSet *indexes = [change objectForKey:NSKeyValueChangeIndexesKey];
	    OBASSERT(indexes);
	    
	    if ([indexes count] != 1)
		// How do we handle the fact that remove at lower indexes shifts the meaning of higher indexes?
		[NSException raise:NSInvalidArgumentException format:@"Don't know how to handle multiple-index removals %@", change];
	    
	    [_nonretained_destinationObject removeValueAtIndex:[indexes firstIndex] fromPropertyWithKey:_destinationKey];
	    break;
	}
	default: {
	    [NSException raise:NSInvalidArgumentException format:@"Don't know how to handle change %@", change];
	}
    }
}

@end

// Unordered to-many properties
@implementation OFSetBinding

- (NSKeyValueObservingOptions)_options;
{
    // We need the 'Old' for the remove case.  Since it doesn't contain indexes, like the array case, we need to know what actuall got removed.
    return NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
    OBPRECONDITION([keyPath isEqualToString:_sourceKey]);
    OBPRECONDITION(object == _sourceObject);
    
#if DEBUG_KVO
    //if (![_sourceObject isKindOfClass:[ODEventPlaybackEventSource class]] && ![_sourceObject isKindOfClass:[ODTimeParametricEventSource class]])
    NSLog(@"binding %p observe %@.%@ -- propagating to %@.%@, change %@", self, [_sourceObject shortDescription], _sourceKey, [_nonretained_destinationObject shortDescription], _destinationKey, change);
#endif
    
    // The destination may cause us to get freed when we notify it.  Our caller doesn't like it when we are dead when we return.
    [[self retain] autorelease];
    
    NSNumber *kind = [change objectForKey:NSKeyValueChangeKindKey];
    switch ((NSKeyValueChange)[kind intValue]) {
	case NSKeyValueChangeSetting: {
	    _handleSetValue(_sourceObject, _sourceKey, _nonretained_destinationObject, _destinationKey, change);
	    break;
	}
	case NSKeyValueChangeInsertion: {
	    NSSet *inserted = [change objectForKey:NSKeyValueChangeNewKey];
	    OBASSERT(inserted);
	    OBASSERT([inserted count] > 0);
	    
	    [[_nonretained_destinationObject mutableSetValueForKey:_destinationKey] unionSet:inserted];
	    break;
	}
	case NSKeyValueChangeRemoval: {
	    NSSet *removed = [change objectForKey:NSKeyValueChangeOldKey];
	    OBASSERT(removed);
	    OBASSERT([removed count] > 0);
	    
	    [[_nonretained_destinationObject mutableSetValueForKey:_destinationKey] minusSet:removed];
	    break;
	}
	default: {
	    [NSException raise:NSInvalidArgumentException format:@"Don't know how to handle change %@", change];
	}
    }
}

@end

