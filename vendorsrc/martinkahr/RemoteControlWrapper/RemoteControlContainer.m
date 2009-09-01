/*****************************************************************************
 * RemoteControlContainer.m
 * RemoteControlWrapper
 *
 * Created by Martin Kahr on 11.03.06 under a MIT-style license. 
 * Copyright (c) 2006 martinkahr.com. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a 
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 *****************************************************************************/

#import "RemoteControlContainer.h"

NSString *RemoteControlContainerObservationContext = @"RemoteControlContainerObservationContext";

@implementation RemoteControlContainer

- (id) initWithDelegate: (id) _remoteControlDelegate {
	if (self = [super initWithDelegate:_remoteControlDelegate]) {
		remoteControls = [[NSMutableArray alloc] init];
		listeningToRemote = NO;
	}
	return self;
}

- (void) dealloc {
	NSUInteger i;
	for(i=0; i < [remoteControls count]; i++) {
		[[remoteControls objectAtIndex: i] removeObserver: self forKeyPath:@"listeningToRemote"];
	}	
	[self stopListening: self];
	[remoteControls release];
	[super dealloc];
}

- (void) reset {
	[self willChangeValueForKey:@"listeningToRemote"];
    listeningToRemote = NO;
    NSUInteger i;
	for(i=0; i < [remoteControls count]; i++) {
		if ([[remoteControls objectAtIndex: i] isListeningToRemote]) {
			listeningToRemote = YES;
			break;
		}
	}
	[self didChangeValueForKey:@"listeningToRemote"];
}

- (BOOL) instantiateAndAddRemoteControlDeviceWithClass: (Class) clazz {
	RemoteControl* remoteControl = [[clazz alloc] initWithDelegate: delegate];
	if (remoteControl) {
		[remoteControls addObject: remoteControl];
		[remoteControl addObserver: self forKeyPath:@"listeningToRemote" options:0 context:RemoteControlContainerObservationContext];
        [remoteControl release];
		[self reset];
		return YES;
	}
	return NO;	
}

- (NSUInteger) count {
	return [remoteControls count];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == RemoteControlContainerObservationContext) {
		[self reset];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void) setListeningToRemote: (BOOL) value {
	NSUInteger i;
	for(i=0; i < [remoteControls count]; i++) {
		[[remoteControls objectAtIndex: i] setListeningToRemote: value];
	}
	if (value && value != [self isListeningToRemote]) [self performSelector:@selector(reset) withObject:nil afterDelay:0.01];
}
- (BOOL) isListeningToRemote {
	return listeningToRemote;
}

- (IBAction) startListening: (id) sender {
	NSUInteger i;
	for(i=0; i < [remoteControls count]; i++) {
		[[remoteControls objectAtIndex: i] startListening: sender];
	}	
}
- (IBAction) stopListening: (id) sender {
	NSUInteger i;
	for(i=0; i < [remoteControls count]; i++) {
		[[remoteControls objectAtIndex: i] stopListening: sender];
	}	
}

- (BOOL) isOpenInExclusiveMode {
	BOOL mode = YES;
	NSUInteger i;
	for(i=0; i < [remoteControls count]; i++) {
		mode = mode && ([[remoteControls objectAtIndex: i] isOpenInExclusiveMode]);
	}
	return mode;	
}
- (void) setOpenInExclusiveMode: (BOOL) value {
	NSUInteger i;
	for(i=0; i < [remoteControls count]; i++) {
		[[remoteControls objectAtIndex: i] setOpenInExclusiveMode:value];
	}	
}

@end
