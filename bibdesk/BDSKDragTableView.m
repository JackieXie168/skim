/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BDSKDragTableView.h"

#import <OmniAppKit/NSString-OAExtensions.h>

@implementation BDSKDragTableView

// this, of course, relies heavily on the fact that the datasource is a bibdocument... i guess it'll break horribly if I ever try to make the tableview
// self contained (maybe not, huh)
- (NSImage*)dragImageForRows:(NSArray*)dragRows event:(NSEvent*)dragEvent dragImageOffset:(NSPointPointer)dragImageOffset{
    NSPasteboard *myPb = [NSPasteboard pasteboardWithUniqueName];
    NSArray *types;
    NSImage *image;
    NSAttributedString *string;
    NSString *s;
    NSSize maxSize = NSMakeSize(600,200); // tunable...
    NSSize stringSize;

    if([[self dataSource] tableView:self
                          writeRows:dragRows
                       toPasteboard:myPb]){
        types = [myPb types];
        if([myPb hasType:NSStringPboardType])
        {
            // draw the string into image
            s = [myPb stringForType:NSStringPboardType];
            string = [[NSAttributedString alloc] initWithString:s];
            image = [[[NSImage alloc] init] autorelease];
            stringSize = [string size];
            if(stringSize.width > maxSize.width)
                stringSize.width = maxSize.width += 4.0;
            if(stringSize.height > maxSize.height)
                stringSize.height = maxSize.height += 4.0; // 4.0 from oakit
            [image setSize:stringSize];
            
            [image lockFocus];
            [string drawAtPoint:NSZeroPoint];
            //[s drawWithFont:[NSFont systemFontOfSize:12.0] color:[NSColor textColor] alignment:NSCenterTextAlignment verticallyCenter:YES inRectangle:(NSRect){NSMakePoint(0, -2), stringSize}];
            [image unlockFocus];

        }
    }else if([myPb hasType:NSPDFPboardType]){
        image = [[[NSImage alloc] initWithData:[myPb dataForType:NSPDFPboardType]] autorelease];
    }else{
        image = [super dragImageForRows:dragRows event:dragEvent dragImageOffset:dragImageOffset];
    }
    //*dragImageOffset = NSMakePoint(([image size].width)/2.0, 0.0);
    return image;
}
// This method computes and returns an image to use for dragging.  Override this to return a custom image.  'dragRows' represents the rows participating in the drag.  'dragEvent' is a reference to the mouse down event that began the drag.  'dragImageOffset' is an in/out parameter.  This method will be called with dragImageOffset set to NSZeroPoint, but it can be modified to re-position the returned image.  A dragImageOffset of NSZeroPoint will cause the image to be centered under the mouse.



- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    if (isLocal) return NSDragOperationEvery; // might want more than this later, maybe?
    else return NSDragOperationCopy;
}

-(id)init{
    if(self=[super init]){
     //   ownedPublications = [NSMutableArray arrayWithCapacity:1];
      //  [self setDataSource:self];
        NSLog(@"*SHOULDNT HAPPEN* called init of tableview");
    }
    return self;
}

- (void)awakeFromNib{
    typeAheadHelper = [[OATypeAheadSelectionHelper alloc] init];
    [typeAheadHelper setDataSource:[self delegate]]; // which is the bibdocument
    [typeAheadHelper setCyclesSimilarResults:YES];
}

- (void)dealloc{
    [typeAheadHelper release];
}

- (void)setOwnedPublications:(NSMutableArray *)pubs{
    [ownedPublications autorelease];
    ownedPublications = [pubs retain];
}

- (NSMutableArray *)ownedPublications{
    return [ownedPublications retain];
}

- (void)keyDown:(NSEvent *)event{
    unichar c = [[event characters] characterAtIndex:0];
    NSCharacterSet *alnum = [NSCharacterSet alphanumericCharacterSet];
    if (c == NSDeleteCharacter ||
        c == NSBackspaceCharacter) {
        [[self delegate] delPub:nil];
    }else if(c == NSNewlineCharacter ||
             c == NSEnterCharacter ||
             c == NSCarriageReturnCharacter){
        [[self delegate] editPubCmd:nil];
    }else if ([alnum characterIsMember:c]) {
        [typeAheadHelper newProcessKeyDownCharacter:c];
    }else{
        [super keyDown:event];
    }
}


// a convenience method.
- (void)removeAllTableColumns{
    NSEnumerator *e = [[self tableColumns] objectEnumerator];
    NSTableColumn *tc;

    while (tc = [e nextObject]) {
        [self removeTableColumn:tc];
    }
    
}


// ----------------------------------------------------------------------------------------
#pragma mark || tableView methods
// ----------------------------------------------------------------------------------------

// this was part of an attempt to make BDSKTableView self-contained. Not currently in use.
- (int)numberOfRowsInTableView:(NSTableView *)tView{
    //NSLog(@"calling myself!");
    return [ownedPublications count];
}

// this was part of an attempt to make BDSKTableView self-contained. Not currently in use.
- (id)tableView:(NSTableView *)tView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    if([[tableColumn identifier] isEqualToString: @"Cite Key"] ){
        return [[ownedPublications objectAtIndex:row] citeKey];
    }
    if([[tableColumn identifier] isEqualToString: @"Title"] ){
        return [[ownedPublications objectAtIndex:row] title];
    }
    if([[tableColumn identifier] isEqualToString: @"Date"] ){
        if([[ownedPublications objectAtIndex:row] date] == nil)
            return @"No date";
        else
            return [[[ownedPublications objectAtIndex:row] date] descriptionWithCalendarFormat:@"%b %Y"];
    }else{
        return nil; // This really shouldn't happen. Maybe I should abort here, but I won't
    }
}



@end