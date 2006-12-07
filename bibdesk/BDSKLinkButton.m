//
//  BDSKLinkButton.m
//  
//
//  Created by Michael McCracken on Thu Jul 25 2002.
//  Copyright (c) 2002 Michael McCracken. All rights reserved.
//

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

