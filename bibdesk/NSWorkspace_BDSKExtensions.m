//
//  NSWorkspace_BDSKExtensions.m
//  Bibdesk
//
//  Created by Adam Maxwell on 10/27/05.
/*
 This software is Copyright (c) 2005,2006
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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

#import "NSWorkspace_BDSKExtensions.h"
#import <OmniBase/assertions.h>
#import <Carbon/Carbon.h>
#import "NSURL_BDSKExtensions.h"

@implementation NSWorkspace (BDSKExtensions)

- (BOOL)openURL:(NSURL *)fileURL withSearchString:(NSString *)searchString
{
    
    // Passing a nil argument is a misuse of this method, so don't do it.
    NSParameterAssert(fileURL != nil);
    NSParameterAssert(searchString != nil);
    if(![fileURL isFileURL]) [NSException raise:NSInvalidArgumentException format:@"\"%@\" is not a valid file URL.", fileURL];
    
    /*
     Modified after Apple sample code for FinderLaunch http://developer.apple.com/samplecode/FinderLaunch/FinderLaunch.html
     Create an open documents event targeting the file's creator application; if that doesn't work, fall back on the Finder (which will discard the search text info).
     */
    
    OSStatus err = noErr;
	AppleEvent theAEvent, theReply;
	AEAddressDesc fndrAddress;
	AEDescList targetListDesc;
	OSType fndrCreator;
	AliasHandle targetAlias;    
    AEDesc searchText;
    
	AECreateDesc(typeNull, NULL, 0, &theAEvent);
	AECreateDesc(typeNull, NULL, 0, &fndrAddress);
	AECreateDesc(typeNull, NULL, 0, &theReply);
	AECreateDesc(typeNull, NULL, 0, &targetListDesc);
	targetAlias = NULL;
    

    fileURL = [fileURL fileURLByResolvingAliases]; 
    OBASSERT(fileURL != nil);
    if(fileURL == nil)
        return NO;
    
    // Find the application that should open this file.  NB: we need to release this URL when we're done with it.
    CFURLRef appURL = NULL;
	if (appURL == NULL)
		err = LSGetApplicationForURL((CFURLRef)fileURL, kLSRolesAll, NULL, &appURL);
		
    
    // Make sure the app is launched before sending the event, or AE will give an error
    if (err == noErr)
        err = LSOpenCFURLRef(appURL, NULL);
    
    // Get the type info of the creator application from LS, so we know should receive the event; this is more reliable than getting the FInfo for the fileURL from FSGetCatalogInfo, which sometimes gives weird, invalid creator codes.
    LSItemInfoRecord lsRecord;
    
    if(err == noErr)
        err = LSCopyItemInfoForURL(appURL, kLSRequestTypeCreator, &lsRecord);
    
    if(appURL) CFRelease(appURL);
    
    if (err == noErr){
        fndrCreator = lsRecord.creator;
        OBASSERT(fndrCreator != 0); 
    } else {
        // We'll try the Finder instead; remember to reset err, though!  The problem with passing this to the Finder is that keyAESearchText will be stripped off, but at least it should open the file.
        fndrCreator = 'MACS';
        err = noErr;
    }
    
    if (err == noErr)
        err = AECreateDesc(typeApplSignature, (Ptr) &fndrCreator, sizeof(fndrCreator), &fndrAddress);
    
	if (err == noErr)
        err = AECreateAppleEvent(kCoreEventClass, kAEOpenDocuments,
                                 &fndrAddress, kAutoGenerateReturnID,
                                 kAnyTransactionID, &theAEvent);
    
    // Here's the search text; convert it to UTF8 bytes without null termination.
    NSData *UTF8data = [searchString dataUsingEncoding:NSUTF8StringEncoding];
    if (err == noErr)
        err = AECreateDesc(typeUTF8Text, [UTF8data bytes], [UTF8data length], &searchText);
    
    // Add the search text to our event as keyAESearchText
    if (err == noErr)
        err = AEPutParamDesc(&theAEvent, keyAESearchText, &searchText);
    
	if (err == noErr)
        // We could create a list from an array of FSSpecs, as in the original FinderLaunch sample
        err = AECreateList(NULL, 0, false, &targetListDesc);
    
    // Was using BDAlias to get an AliasHandle, but it crashes if the file doesn't exist; we now check for that, and we'll create our own AliasHandle to be extra safe
    FSRef fileRef;
    if(CFURLGetFSRef((CFURLRef)fileURL, &fileRef) == NO)
        err = fnfErr; // wild guess since CF is unhelpful here...should never happen, though, since we bailed if the alias couldn't be resolved
    
    if(err == noErr)
        err = FSNewAlias(NULL, &fileRef, &targetAlias);
    
    if(err == noErr && targetAlias != NULL){
        HLock((Handle)targetAlias);
        err = AEPutPtr(&targetListDesc, 1, typeAlias, *targetAlias, GetHandleSize((Handle)targetAlias));
        HUnlock((Handle)targetAlias);
    }
	
    /* add the file list to the apple event */
    if( err == noErr )
        err = AEPutParamDesc(&theAEvent, keyDirectObject, &targetListDesc);
    
    // Finally send the event
    if (err == noErr)
        err = AESend(&theAEvent, &theReply, kAENoReply,
                     kAENormalPriority, kAEDefaultTimeout, NULL, NULL);
    
    /* clean up and leave */
	AEDisposeDesc(&targetListDesc);
	AEDisposeDesc(&theAEvent);
	AEDisposeDesc(&fndrAddress);
	AEDisposeDesc(&theReply);
    AEDisposeDesc(&searchText);
	
    return (err == noErr);
}

@end
