//  BDSKLinkButton.m

//  Created by Michael McCracken on Thu Jul 25 2002.
/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BDSKLinkButton.h"


// implemented at end of file
@interface BDSKLinkButton (Private)

- (void)_gotoLink:(id)sender;

@end

// might be more reusable as an NSButtonCell subclass...
// that's not a hard change to make later though
@implementation BDSKLinkButton : NSButton

- (id)init{
    [super init];
    return self;
}

- (void)setLink:(NSString *)link{
    NSString *oldLink = _link;
    _link = [link retain];
    [oldLink release];
    [self setTarget:self];
    [self setAction:@selector(_gotoLink:)];
}

- (void)setLinkTitle:(NSString *)title{
    NSDictionary *linkAttributes = nil;
    NSMutableAttributedString *linkAttStr = nil;

    if(_link){
        linkAttributes = [NSDictionary dictionaryWithObjectsAndKeys: _link, NSLinkAttributeName,
        [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName,
        [NSColor blueColor], NSForegroundColorAttributeName,
        NULL];
    }else{
        // what to do?
    }
    
    linkAttStr = [[[NSMutableAttributedString alloc] initWithString:title] autorelease];
    [linkAttStr setAttributes:linkAttributes range:NSMakeRange(0,[title length])];
    [self setAttributedTitle:linkAttStr];    
}


@end

@implementation BDSKLinkButton (Private)

- (void)_gotoLink:(id)sender{
    NS_DURING{
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:_link]];
    }NS_HANDLER{
        // for now, ignore NSURL exceptions.
    }NS_ENDHANDLER
}

@end

