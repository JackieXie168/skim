//
//  SKNote.h
//  Skim
//
//  Created by Christiaan Hofman on 12/10/08.
//  Copyright 2008 Christiaan Hofman. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SKNote : NSObject {
    NSDictionary *properties;
    NSString *type;
    NSString *contents;
    NSArray *texts;
}

- (id)initWithSkimNoteProperties:(NSDictionary *)aProperties;

- (NSDictionary *)SkimNoteProperties;

- (NSString *)type;
- (NSRect)bounds;
- (NSString *)contents;
- (unsigned int)pageIndex;
- (NSString *)string;
- (NSAttributedString *)text;

- (id)page;

- (NSArray *)texts;

@end
