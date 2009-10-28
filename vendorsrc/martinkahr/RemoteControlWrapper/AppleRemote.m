/*****************************************************************************
 * RemoteControlWrapper.m
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

#import "AppleRemote.h"

#import <mach/mach.h>
#import <mach/mach_error.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/hid/IOHIDKeys.h>

const char* AppleRemoteDeviceName = "AppleIRController";

@implementation AppleRemote

+ (const char*) remoteControlDeviceName {
	return AppleRemoteDeviceName;
}

- (void) setCookieMappingInDictionary: (NSMutableDictionary*) _cookieToButtonMapping	{	
    [_cookieToButtonMapping setObject:[NSNumber numberWithInteger:kRemoteButtonPlus]		forKey:@"31_29_28_19_18_"];
    [_cookieToButtonMapping setObject:[NSNumber numberWithInteger:kRemoteButtonMinus]		forKey:@"31_30_28_19_18_"];	
    [_cookieToButtonMapping setObject:[NSNumber numberWithInteger:kRemoteButtonMenu]		forKey:@"31_20_19_18_31_20_19_18_"];
    [_cookieToButtonMapping setObject:[NSNumber numberWithInteger:kRemoteButtonPlay]		forKey:@"31_21_19_18_31_21_19_18_"];
    [_cookieToButtonMapping setObject:[NSNumber numberWithInteger:kRemoteButtonRight]		forKey:@"31_22_19_18_31_22_19_18_"];
    [_cookieToButtonMapping setObject:[NSNumber numberWithInteger:kRemoteButtonLeft]		forKey:@"31_23_19_18_31_23_19_18_"];
    [_cookieToButtonMapping setObject:[NSNumber numberWithInteger:kRemoteButtonRight_Hold]	forKey:@"31_19_18_4_2_"];
    [_cookieToButtonMapping setObject:[NSNumber numberWithInteger:kRemoteButtonLeft_Hold]	forKey:@"31_19_18_3_2_"];
    [_cookieToButtonMapping setObject:[NSNumber numberWithInteger:kRemoteButtonMenu_Hold]	forKey:@"31_19_18_31_19_18_"];
    [_cookieToButtonMapping setObject:[NSNumber numberWithInteger:kRemoteButtonPlay_Hold]	forKey:@"35_31_19_18_35_31_19_18_"];
    [_cookieToButtonMapping setObject:[NSNumber numberWithInteger:kRemoteControl_Switched]	forKey:@"19_"];			
}

- (void) sendRemoteButtonEvent: (RemoteControlEventIdentifier) event pressedDown: (BOOL) pressedDown {
	if (pressedDown == NO && event == kRemoteButtonMenu_Hold) {
		// There is no seperate event for pressed down on menu hold. We are simulating that event here
		[super sendRemoteButtonEvent:event pressedDown:YES];
	}	
	
	[super sendRemoteButtonEvent:event pressedDown:pressedDown];
	
	if (pressedDown && (event == kRemoteButtonRight || event == kRemoteButtonLeft || event == kRemoteButtonPlay || event == kRemoteButtonMenu || event == kRemoteButtonPlay_Hold)) {
		// There is no seperate event when the button is being released. We are simulating that event here
		[super sendRemoteButtonEvent:event pressedDown:NO];
	}
}

@end
