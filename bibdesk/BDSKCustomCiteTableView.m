// BDSKCustomCiteTableView.m
/*
 This software is Copyright (c) 2002,2003,2004,2005
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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

#import "BDSKCustomCiteTableView.h"
#import "BibDocument_DataSource.h"

@implementation BDSKCustomCiteTableView
- (NSImage*)dragImageForRows:(NSArray*)dragRows event:(NSEvent*)dragEvent dragImageOffset:(NSPointPointer)dragImageOffset{
    NSImage *image = nil;
    NSAttributedString *string;
    NSString *s;
    NSSize maxSize = NSMakeSize(600,200); // tunable...
    NSSize stringSize;
    
    NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSDragPboard];
    NSArray *types = [pb types];
    
    if([[pb availableTypeFromArray:types] isEqualToString:NSStringPboardType]){
        s = [pb stringForType:NSStringPboardType]; // draw the string from the drag pboard, if it's available
    } else {
        s = [[self dataSource] citeStringForRows:dragRows tableViewDragSource:self];
    }
            
    if(s){
        string = [[NSAttributedString alloc] initWithString:s];
        image = [[[NSImage alloc] init] autorelease];
        stringSize = [string size];
        if(stringSize.width == 0 || stringSize.height == 0){
            NSLog(@"string size was zero");
            stringSize = maxSize; // work around bug in NSAttributedString
        }
        if(stringSize.width > maxSize.width)
            stringSize.width = maxSize.width += 4.0;
        if(stringSize.height > maxSize.height)
            stringSize.height = maxSize.height += 4.0; // 4.0 from oakit
        [image setSize:stringSize];
        
        [image lockFocus];
        [string drawAtPoint:NSZeroPoint];
        //[s drawWithFont:[NSFont systemFontOfSize:12.0] color:[NSColor textColor] alignment:NSCenterTextAlignment verticallyCenter:YES inRectangle:(NSRect){NSMakePoint(0, -2), stringSize}];
        [image unlockFocus];
        
    }else{
        image = [super dragImageForRows:dragRows event:dragEvent dragImageOffset:dragImageOffset];
    }
    //*dragImageOffset = NSMakePoint(([image size].width)/2.0, 0.0);
    return image;
}


- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    if (isLocal) return NSDragOperationNone; 
    else return NSDragOperationCopy;
}

@end
