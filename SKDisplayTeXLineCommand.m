//
//  SKDisplayLineCommand.m
//  Skim
//
//  Created by Christiaan Hofman on 4/22/07.
/*
 This software is Copyright (c) 2007
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

#import "SKDisplayTeXLineCommand.h"
#import "SKDocument.h"
#import "SKPDFSynchronizer.h"
#import "SKPDFView.h"


@implementation SKDisplayTeXLineCommand

- (id)performDefaultImplementation {
	id lineNumber = [self directParameter];
	NSDictionary *args = [self evaluatedArguments];
	id file = [args objectForKey:@"file"];
	id source = [args objectForKey:@"source"];
    NSURL *fileURL = nil;
    
    if (source == nil)
        source = file;
    
    if ([source isKindOfClass:[NSURL class]]) {
        source = [source path];
    } else if ([source isKindOfClass:[NSString class]]) {
        if ([source hasPrefix:@"file://"])
            source = [[NSURL URLWithString:source] path];
        else
            source = [source stringByStandardizingPath];
	}
    
    if ([[source pathExtension] length] == 0)
        source = [source stringByAppendingPathExtension:@"tex"];
    else if ([[source pathExtension] caseInsensitiveCompare:@"tex"] != NSOrderedSame) 
        source = [[source stringByDeletingPathExtension] stringByAppendingPathExtension:@"tex"];
    
    if ([file isKindOfClass:[NSURL class]]) {
        fileURL = file;
    } else if ([source isKindOfClass:[NSString class]]) {
        if ([file hasPrefix:@"file://"])
            fileURL = [NSURL URLWithString:file];
        else
            fileURL = [NSURL fileURLWithPath:[file stringByStandardizingPath]];
	}
    
    file = [fileURL path];
    if ([[file pathExtension] length] == 0)
        fileURL = [NSURL fileURLWithPath:[file stringByAppendingPathExtension:@"pdf"]];
    else if ([[file pathExtension] caseInsensitiveCompare:@"pdf"] != NSOrderedSame) 
        fileURL = [NSURL fileURLWithPath:[[file stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"]];
    
    if (fileURL && source && [[NSFileManager defaultManager] fileExistsAtPath:source]) {
        SKDocument *document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL display:YES error:NULL];
        SKPDFSynchronizer *synchronizer = [document synchronizer];
        unsigned int pageIndex;
        NSPoint point;
        
        if ([synchronizer getPageIndex:&pageIndex location:&point forLine:[lineNumber intValue] inFile:source])
            [[document pdfView] displayLineAtPoint:point inPageAtIndex:pageIndex];
    }
    
    return nil;
}

@end
