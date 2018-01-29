//
//  SKKeychain.m
//  Skim
//
//  Created by Christiaan on 29/01/2018.
/*
 This software is Copyright (c) 2018
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

#import "SKKeychain.h"
#import <Security/Security.h>


@implementation SKKeychain

+ (SKPasswordStatus)getPassword:(NSString **)password item:(id *)itemPtr forService:(NSString *)service account:(NSString *)account {
    void *passwordData = NULL;
    UInt32 passwordLength = 0;
    const char *serviceData = [service UTF8String];
    const char *accountData = [account UTF8String];
    
    OSStatus err = SecKeychainFindGenericPassword(NULL, strlen(serviceData), serviceData, strlen(accountData), accountData, password ? &passwordLength : NULL, password ? &passwordData : NULL, (SecKeychainItemRef *)itemPtr);
    
    if (err == noErr && password) {
        *password = [[[NSString alloc] initWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding] autorelease];
        SecKeychainItemFreeContent(NULL, passwordData);
    }
    
    if (err != noErr && err != errSecItemNotFound)
        NSLog(@"Error %d occurred finding password: %@", (int)err, [(id)SecCopyErrorMessageString(err, NULL) autorelease]);
    
    return err == noErr ? SKPasswordStatusFound : err == errSecItemNotFound ? SKPasswordStatusNotFound : SKPasswordStatusError;
}

static inline SecKeychainAttribute makeKeychainAttribute(SecKeychainAttrType tag, NSString *string) {
    const char *data = [string UTF8String];
    SecKeychainAttribute attr;
    attr.tag = tag;
    attr.length = strlen(data);
    attr.data = (void *)data;
    return attr;
}

+ (void)setPassword:(NSString *)password item:(id)item forService:(NSString *)service account:(NSString *)account label:(NSString *)label comment:(NSString *)comment {
    const void *passwordData = [password UTF8String];
    UInt32 passwordLength = password ? strlen(passwordData) : 0;
    NSUInteger attrCount = 2;
    SecKeychainAttributeList attributes;
    SecKeychainAttribute attrs[4];
    OSStatus err;
    
    attrs[0] = makeKeychainAttribute(kSecServiceItemAttr, service);
    attrs[1] = makeKeychainAttribute(kSecAccountItemAttr, account);
    if (label)
        attrs[attrCount++] = makeKeychainAttribute(kSecLabelItemAttr, label);
    if (comment)
        attrs[attrCount++] = makeKeychainAttribute(kSecCommentItemAttr, comment);
    
    attributes.count = attrCount;
    attributes.attr = attrs;
    
    if (item) {
        // password was on keychain, so modify the keychain
        err = SecKeychainItemModifyAttributesAndData((SecKeychainItemRef)item, &attributes, passwordLength, passwordData);
        if (err != noErr)
            NSLog(@"Error %d occurred modifying password: %@", (int)err, [(id)SecCopyErrorMessageString(err, NULL) autorelease]);
    } else if (password) {
        // password not on keychain, so add it
        err = SecKeychainItemCreateFromContent(kSecGenericPasswordItemClass, &attributes, passwordLength, passwordData, NULL, NULL, NULL);
        if (err != noErr)
            NSLog(@"Error %d occurred adding password: %@", (int)err, [(id)SecCopyErrorMessageString(err, NULL) autorelease]);
    }
}

@end
