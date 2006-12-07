//
//  BDSKCompletionServerProtocol.h
//
//  Created by Christiaan Hofman on 11/23/06.
/*
 This software is Copyright (c) 2006
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

#import <Foundation/Foundation.h>

#define BIBDESK_SERVER_NAME @"BDSKCompletionServer"

/*
 Keys for objects returned by completionsForString:
 
  ** Value is guaranteed non-nil **
 citeKey        Cite key of the item (NSString)
 title          Title of the item as shown in BibDesk (NSString)
 numberOfNames  Number of authors or editors, corresponding to lastName and sortableName (NSNumber)
 
  ** Value may be nil **
 lastName       Last name of the first author or editor, including von and Jr parts (NSString)
 sortableName   Name used for sorting in BibDesk (NSString)
 year           Publication year (NSNumber)
 
 The primary usage of the items returned is for pretty-printing a list to be displayed.  The title and names in particular may be formatted differently from the actual BibTeX file's content.
 
 */

@protocol BDSKCompletionServer
// Returns an array of KVC-compliant objects
- (NSArray *)completionsForString:(NSString *)searchString;
// Returns a list of URLs of currently opened documents
- (NSArray *)orderedDocumentURLs;
@end


static inline NSArray *BDSKCompletionsForString(NSString *searchString) {
    NSArray *completions = nil;
    NSConnection *connection = [NSConnection connectionWithRegisteredName:BIBDESK_SERVER_NAME host:nil];
    
    // if we don't set these explicitly, timeout never seems to take place
    [connection setRequestTimeout:10.0f];
    [connection setReplyTimeout:10.0f];

    id server;
    
    @try {
        server = [connection rootProxy];
        [server setProtocolForProxy:@protocol(BDSKCompletionServer)];
        completions = [server completionsForString:searchString];
    }
    @catch(id exception) {
        NSLog(@"Discarding exception %@ caught when contacting BibDesk", exception);
        completions = nil;
    }
    [[connection receivePort] invalidate];
    [[connection sendPort] invalidate];
    [connection invalidate];
    
    return completions;
}
