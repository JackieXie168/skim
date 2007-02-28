//
//  BDSKBibTeXImporter.m
//  bd2xtest
//
//  Created by Michael McCracken on 1/18/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BDSKBibTeXImporter.h"
#import "BDSKBibTeXParser.h"
#import "BDSKDataModelNames.h"
#import "BDSKDocument.h"
#import "BDSKDragImageView.h"

static BDSKBibTeXImporter *sharedImporter = nil;

@implementation BDSKBibTeXImporter

+ (void)initialize{
    [self setKeys:[NSArray arrayWithObjects:@"fileName", nil] triggerChangeNotificationsForDependentKey:@"fileIcon"];
}


+ (id<BDSKImporter>)sharedImporter{
    if(sharedImporter == nil)
        sharedImporter = [[self alloc] init];
    return sharedImporter;
}


- (id)init{
    return [self initWithSettings:[[self class] defaultSettings]];
}


- (id)initWithSettings:(NSDictionary *)newSettings{
    self = [super init];
    if(self){
        fileName = [[newSettings objectForKey:@"fileName"] retain];
    }
    return self;
}


- (void)dealloc{
    [fileName release];
    [super dealloc];
}

- (void)awakeFromNib{
    [imageView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
}

#pragma mark settings UI and configuration

+ (NSDictionary *)defaultSettings{
    return [NSDictionary dictionary]; //probably want to load this from a plist.
    // candidates for default settings are text encodings, etc.
}

- (NSDictionary *)settings{
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:fileName, @"fileName", nil];
    return settings; 
}

- (NSView *)view{
    if(!view){
        [NSBundle loadNibNamed:@"BDSKBibTeXImporter" owner:self];
    }
    return view;
}


#pragma mark import action

- (BOOL)importIntoDocument:(BDSKDocument *)doc
                  userInfo:(NSDictionary *)userInfo
                     error:(NSError **)outError{
    
    NSLog(@"importIntoDocument %@ with fileName %@", doc, fileName);

    NSData *data = [NSData dataWithContentsOfFile:fileName];
    NSError *error = nil;
    [BDSKBibTeXParser itemsFromData:data error:&error document:doc];
    if (error && outError)
        *outError = error;
    
    return (error == nil);
}


#pragma mark UI actions

- (IBAction)chooseFileName:(id)sender{
    // open file chooser
    
    NSOpenPanel *op = [NSOpenPanel openPanel];
    int rv = [op runModalForDirectory:[fileName stringByDeletingLastPathComponent] 
                                 file:@""
                                types:[NSArray arrayWithObject:@"bib"]];
    
    if (rv == NSOKButton)
        [self setValue:[[op filenames] objectAtIndex:0] forKey:@"fileName"];
}


#pragma mark UI KVO stuff

- (NSImage *)fileIcon{
    
    if(fileName){
        return [[NSWorkspace sharedWorkspace] iconForFile:fileName];
    }else{
        return nil;
    }
}

#pragma mark DragImageView drag & drop delegate

- (NSDragOperation)dragImageView:(BDSKDragImageView *)aView validateDrop:(id <NSDraggingInfo>)sender {
    if ([sender draggingSource] == aView)
		return NSDragOperationNone;
	
	NSPasteboard *pboard = [sender draggingPasteboard];
    
    if([[pboard types] containsObject:NSFilenamesPboardType])
        return NSDragOperationCopy;

    return NSDragOperationNone;
}

- (BOOL)dragImageView:(BDSKDragImageView *)aView acceptDrop:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if([[pboard types] containsObject:NSFilenamesPboardType] == NO)
        return NO;
	
    NSEnumerator *fnEnum = [[pboard propertyListForType:NSFilenamesPboardType] objectEnumerator];
    NSString *file = nil;
    
    while (file = [fnEnum nextObject]) {
        if ([[file pathExtension] caseInsensitiveCompare:@"bib"] == NSOrderedSame) {
            [self setValue:file forKey:@"fileName"];
            return YES;
        }
    }
    
    return NO;
}

@end
