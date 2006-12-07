//  BDSKPreviewer.m

//  Created by Michael McCracken on Tue Jan 29 2002.
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

#import "BDSKPreviewer.h"
#import "BibPrefController.h"
#import "BibAppController.h"
#import "DraggableScrollView.h"

/*! @const BDSKPreviewer helps to enforce a single object of this class */
static BDSKPreviewer *thePreviewer;

@implementation BDSKPreviewer

+ (BDSKPreviewer *)sharedPreviewer{
    if (!thePreviewer) {
        thePreviewer = [[BDSKPreviewer alloc] init];
    }
    return thePreviewer;
}

- (id)init{
    if(self = [super init]){
        applicationSupportPath = [[[[NSFileManager defaultManager] applicationSupportDirectory:kUserDomain] stringByAppendingPathComponent:@"BibDesk"] retain];
        bundle = [NSBundle mainBundle];
        usertexTemplatePath = [[applicationSupportPath stringByAppendingPathComponent:@"previewtemplate.tex"] retain];
        texTemplatePath = [[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.tex"] retain];
        finalPDFPath = [[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.pdf"] retain];
        nopreviewPDFPath = [[[bundle resourcePath] stringByAppendingPathComponent:@"nopreview.pdf"] retain];
        tmpBibFilePath = [[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.bib"] retain];
        rtfFilePath = [[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.rtf"] retain];
        binPathDir = [[NSString alloc] init]; // set from where we run the tasks, since some programs (e.g. XeLaTeX) need a real path setting
        theLock = [[BDOrganizedLock alloc] init];
    }
    return self;
}

- (void)awakeFromNib{
    [self setWindowFrameAutosaveName:@"BDSKPreviewPanel"];

	DraggableScrollView *scrollView = (DraggableScrollView*)[imagePreviewView enclosingScrollView];
    float scaleFactor = [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKPreviewPDFScaleFactorKey];
	[scrollView setScaleFactor:scaleFactor];
    
    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3){
        [self performSelectorOnMainThread:@selector(resetPreviews) withObject:nil waitUntilDone:NO];
    } else {
#ifdef BDSK_USING_TIGER
        NSRect frameRect = [imagePreviewView frame];
        pdfView = [[NSClassFromString(@"BDSKZoomablePDFView") alloc] initWithFrame:frameRect];
        [[tabView tabViewItemAtIndex:0] setView:pdfView];
        [pdfView release];
        [self performSelectorOnMainThread:@selector(resetPreviews) withObject:nil waitUntilDone:YES];
        // don't reset the scale factor until there's a document loaded, or else we get a huge gray border
        [pdfView setScaleFactor:scaleFactor];
#endif
    }
    
    scrollView = (DraggableScrollView*)[rtfPreviewView enclosingScrollView];
	scaleFactor = [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKPreviewRTFScaleFactorKey];
	[scrollView setScaleFactor:scaleFactor];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
					     selector:@selector(appWillTerminate:)
						 name:NSApplicationWillTerminateNotification
					       object:NSApp];
	
}

- (NSString *)windowNibName
{
    return @"Previewer";
}

- (BOOL)PDFFromString:(NSString *)str{
    
    // pool for MT
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    volatile BOOL rv = YES;
    
    if(str == nil || [str isEqualToString:@""]){
        [self performSelectorOnMainThread:@selector(resetPreviews) withObject:nil waitUntilDone:NO];
        [pool release];
        return NO;
    }
    // get a fresh copy of the file:
    NSString *texFile; 

    NSMutableString *bibTemplate; 
    NSString *prefix;
    NSString *postfix;
    NSString *style;
    NSMutableString *finalTexFile = [[NSMutableString alloc] initWithCapacity:200];
    NSScanner *scanner;
    
    switch ([theLock lockFor:self job:str])
    {
        case BDDoTheWork:
            break; // run the preview setup and tasks
            
        case BDWorkJustDone:
            goto display; // display the results
            
        case BDOtherWorkRequested:
            goto cleanup; // cleanup
    }
        
    // Files:  previewtemplate.tex is intended to be changed by the user, and so we allow opening
    // this file from the preview prefpane.  By using previewtemplate.tex as a base instead of the previous
    // bibpreview.tex file, we avoid problems.   Previously if the user was editing the 
    // bibpreview.tex file and we overwrote it by running another preview, the editor would lose the file.
    // Therefore, bibpreview.* are essentially temporary files, only modified by BibDesk.
    texFile = [[NSString alloc] initWithContentsOfFile:usertexTemplatePath];
    bibTemplate = [[NSMutableString alloc] initWithContentsOfFile:
        [[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKOutputTemplateFileKey] stringByExpandingTildeInPath]];
    scanner = [[NSScanner alloc] initWithString:texFile];

    // replace the appropriate style & bib files.
    style = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKBTStyleKey];
    [scanner scanUpToString:@"bibliographystyle{" intoString:&prefix];
    [scanner scanUpToString:@"}" intoString:nil];
    [scanner scanUpToString:@"\bye" intoString:&postfix];
    [scanner release];
    
    [finalTexFile appendString:prefix];
    [finalTexFile appendString:@"bibliographystyle{"];
    [finalTexFile appendString:style];
    [finalTexFile appendString:postfix];
    // overwrites the old bibpreview.tex file, replacing the previous bibliographystyle
    if(![[finalTexFile dataUsingEncoding:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKTeXPreviewFileEncodingKey]] writeToFile:texTemplatePath atomically:YES]){
        NSLog(@"error replacing texfile");
        rv = NO;
        goto cleanup;
    }

    // write out the bib file with the template attached:
    [bibTemplate appendString:@"\n"];
    [bibTemplate appendString:str];
    if(![[bibTemplate dataUsingEncoding:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKTeXPreviewFileEncodingKey]] writeToFile:tmpBibFilePath atomically:YES]){
        NSLog(@"Error replacing bibfile.");
        rv = NO;
        goto cleanup;
    }
    
    NS_DURING
        if(![self previewTexTasks:@"bibpreview.tex"]){
            NSLog(@"Task failure in -[%@ %@]", [self class], NSStringFromSelector(_cmd));
            rv = NO;
        }
    NS_HANDLER 
        // clean up and return, since we're responsible for all exceptions here
        rv = NO;
        goto cleanup;
    NS_ENDHANDLER
            
    display:
        [self performSelectorOnMainThread:@selector(performDrawing) withObject:nil waitUntilDone:NO];
    cleanup:
        [bibTemplate release];
        [texFile release];
        [finalTexFile release];
        [pool release];
        [theLock unlock];
        
    return rv;    
    
}

- (void)printDocument:(id)sender{ // first responder gets this
    NSView *printView = [[tabView selectedTabViewItem] view];
    
    // Construct the print operation and setup Print panel
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:printView
                                                          printInfo:[NSPrintInfo sharedPrintInfo]];
    [op setShowPanels:YES];
    [op setCanSpawnSeparateThread:YES];
    
    // Run operation, which shows the Print panel if showPanels was YES
    [op runOperationModalForWindow:[self window] delegate:nil didRunSelector:NULL contextInfo:NULL];
    
}

// This should only be called from the main thread
- (void)performDrawing{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // if we're offscreen, no point in doing any extra work; the files are still available for copy operations
    if(![[self window] isVisible]){
        [pool release];
        return;
    }
    
    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3){
        [imagePreviewView loadFromPath:finalPDFPath];
    } else {
#ifdef BDSK_USING_TIGER
        id pdfDocument = [[NSClassFromString(@"PDFDocument") alloc] initWithURL:[NSURL fileURLWithPath:finalPDFPath]];
        [(PDFView *)pdfView setDocument:pdfDocument];
        [pdfDocument release];
#endif
    }

    [self displayRTFPreviewFromData:[self RTFPreviewData]]; // does its own locking of the view
    [pool release];
}	

- (BOOL)previewTexTasks:(NSString *)fileName{ // we set working dir in NSTask
        
    NSTask *pdftex1;
    NSTask *pdftex2;
    NSTask *pdftex3;
    NSTask *bibtex;
    NSString *pdftexbinpath = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKTeXBinPathKey];
    NSString *bibtexbinpath = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKBibTeXBinPathKey];
    NSTask *latex2rtf;
    NSString *latex2rtfpath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"latex2rtf"];
    
    if(![[pdftexbinpath stringByDeletingLastPathComponent] isEqualToString:binPathDir]){
        [binPathDir release];
        binPathDir = [[pdftexbinpath stringByDeletingLastPathComponent] retain];
        NSString *original_path = [NSString stringWithCString: getenv("PATH")];
        NSString *new_path = [NSString stringWithFormat: @"%@:%@", original_path, binPathDir];
        setenv("PATH", [new_path cString], 1);
    }
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:pdftexbinpath]){
        NSLog(@"%@ cannot continue: %@ not found", NSStringFromSelector(_cmd), pdftexbinpath);
        return NO;    
    }
    if(![[NSFileManager defaultManager] fileExistsAtPath:bibtexbinpath]){        
        NSLog(@"%@ cannot continue: %@ not found", NSStringFromSelector(_cmd), bibtexbinpath);
        return NO;     
    }

    // remove the old pdf file.
    [[NSFileManager defaultManager] removeFileAtPath:[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.pdf"]
                                             handler:nil];
    
    // Now start the tex task fun.

    pdftex1 = [[NSTask alloc] init];
    [pdftex1 setCurrentDirectoryPath:applicationSupportPath];
    [pdftex1 setLaunchPath:pdftexbinpath];
    [pdftex1 setArguments:[NSArray arrayWithObjects:@"-interaction=batchmode", fileName, nil ]];
    [pdftex1 setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];

    NS_DURING
        [pdftex1 launch];
        [pdftex1 waitUntilExit];
    NS_HANDLER
        if([pdftex1 isRunning])
            [pdftex1 terminate];
        NSLog(@"%@ %@ failed", [pdftex1 description], [pdftex1 launchPath]);
        [pdftex1 release];
        return NO;
    NS_ENDHANDLER
    
    [pdftex1 release];

    bibtex = [[NSTask alloc] init];
    [bibtex setCurrentDirectoryPath:applicationSupportPath];
    [bibtex setLaunchPath:bibtexbinpath];
    [bibtex setArguments:[NSArray arrayWithObjects:[fileName stringByDeletingPathExtension],nil ]];
    [bibtex setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];

    NS_DURING
        [bibtex launch];
        [bibtex waitUntilExit];
    NS_HANDLER
        if([bibtex isRunning])
            [bibtex terminate];
        NSLog(@"%@ %@ failed", [bibtex description], [bibtex launchPath]);
        [bibtex release];
        return NO;
    NS_ENDHANDLER
    
    [bibtex release];

    pdftex2 = [[NSTask alloc] init];
    [pdftex2 setCurrentDirectoryPath:applicationSupportPath];
    [pdftex2 setLaunchPath:pdftexbinpath];
    [pdftex2 setArguments:[NSArray arrayWithObjects:@"-interaction=batchmode",fileName, nil ]];
    [pdftex2 setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    
    NS_DURING
        [pdftex2 launch];
        [pdftex2 waitUntilExit];
    NS_HANDLER
        if([pdftex2 isRunning])
            [pdftex2 terminate];
        NSLog(@"%@ %@ failed", [pdftex2 description], [pdftex2 launchPath]);
        [pdftex2 release];
        return NO;
    NS_ENDHANDLER
    
    [pdftex2 release];

    // third and final pdftex run
    pdftex3 = [[NSTask alloc] init];
    [pdftex3 setCurrentDirectoryPath:applicationSupportPath];
    [pdftex3 setLaunchPath:pdftexbinpath];
    [pdftex3 setArguments:[NSArray arrayWithObjects:@"-interaction=batchmode", fileName, nil]];
    [pdftex3 setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    
    NS_DURING
        [pdftex3 launch];
        [pdftex3 waitUntilExit];
    NS_HANDLER
        if([pdftex3 isRunning])
            [pdftex3 terminate];
        NSLog(@"%@ %@ failed", [pdftex3 description], [pdftex3 launchPath]);
        [pdftex3 release];
        return NO;
    NS_ENDHANDLER
    
    [pdftex3 release];
    
    // This task runs latex2rtf on our tex file to generate bibpreview.rtf
    latex2rtf = [[NSTask alloc] init];
    [latex2rtf setCurrentDirectoryPath:applicationSupportPath];
    [latex2rtf setLaunchPath:latex2rtfpath];  // full path to the binary
    // the arguments: it needs -P "path" which is the path to the cfg files in the app wrapper
    [latex2rtf setArguments:[NSArray arrayWithObjects:[NSString stringWithString:@"-P"], [[NSBundle mainBundle] resourcePath], fileName, nil ]];
    [latex2rtf setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [latex2rtf setStandardError:[NSFileHandle fileHandleWithNullDevice]];
    
    NS_DURING
        [latex2rtf launch];
        [latex2rtf waitUntilExit];
    NS_HANDLER
        if([latex2rtf isRunning])
            [latex2rtf terminate];
        NSLog(@"%@ %@ failed", [latex2rtf description], [latex2rtf launchPath]);
        [latex2rtf release];
        return NO;
    NS_ENDHANDLER

    [latex2rtf release];

    return YES;

}

- (NSData *)PDFDataFromString:(NSString *)str{
    if([self PDFFromString:str])
        return [NSData dataWithContentsOfFile:finalPDFPath];
    else
        return nil;
}

- (NSAttributedString *)rtfStringPreview:(NSString *)filePath{      // RTF Preview support
    return [[[NSAttributedString alloc] initWithPath:filePath documentAttributes:nil] autorelease];
}

- (NSData *)RTFPreviewData{   // Returns the RTF as NSData, used for pasteboard ops
    return [NSData dataWithContentsOfFile:rtfFilePath];
}

- (BOOL)displayRTFPreviewFromData:(NSData *)rtfdata{  // This draws the RTF in a textview
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL rv = YES;
    
    NSSize inset = NSMakeSize(20,20); // set this for the margin
    
    [rtfPreviewView setString:@""];   // clean the view
    [rtfPreviewView setTextContainerInset:inset];  // pad the edges of the text

    // we get a zero-length string if a bad bibstyle is used, so check for it
    if([rtfdata length] > 0){
        [rtfPreviewView replaceCharactersInRange:[rtfPreviewView selectedRange]
                                         withRTF:rtfdata];
    } else {
        NSString *errstr = [NSString stringWithString:@"***** ERROR:  unable to create preview *****"];
        [rtfPreviewView replaceCharactersInRange: [rtfPreviewView selectedRange]
                                      withString:errstr];
    	rv = NO;
    }
    [pool release];
    return rv;	
}

- (void)windowWillClose:(NSNotification *)notification{
	[self performSelectorOnMainThread:@selector(resetPreviews) withObject:nil waitUntilDone:NO];
}

- (void)appWillTerminate:(NSNotification *)notification{
	// save the scalefactors of the views
    float scaleFactor;
    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3){
        scaleFactor = [(DraggableScrollView*)[imagePreviewView enclosingScrollView] scaleFactor];
    } else {
        scaleFactor = ([pdfView autoScales] ? 0.0 : [pdfView scaleFactor]);
    }
	if (scaleFactor != [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKPreviewPDFScaleFactorKey])
		[[OFPreferenceWrapper sharedPreferenceWrapper] setFloat:scaleFactor forKey:BDSKPreviewPDFScaleFactorKey];
	scaleFactor = [(DraggableScrollView*)[rtfPreviewView enclosingScrollView] scaleFactor];
	if (scaleFactor != [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKPreviewRTFScaleFactorKey])
		[[OFPreferenceWrapper sharedPreferenceWrapper] setFloat:scaleFactor forKey:BDSKPreviewRTFScaleFactorKey];
}

// This should only be called from the main thread
- (void)resetPreviews{
    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3){
        [imagePreviewView loadFromPath:nopreviewPDFPath];
    } else {
#ifdef BDSK_USING_TIGER
        id pdfDocument = [[NSClassFromString(@"PDFDocument") alloc] initWithURL:[NSURL fileURLWithPath:nopreviewPDFPath]];
        [(PDFView *)pdfView setDocument:pdfDocument];
        [pdfDocument release];
#endif
    }
    [rtfPreviewView setString:@""];
    [rtfPreviewView setTextContainerInset:NSMakeSize(20, 20)];
    [rtfPreviewView replaceCharactersInRange:[rtfPreviewView selectedRange]
                                  withString:NSLocalizedString(@"Please select an item or items from the bibliography list for LaTeX to preview.",@"")];
}


- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [usertexTemplatePath release];
    [texTemplatePath release];
    [finalPDFPath release];
    [nopreviewPDFPath release];
    [tmpBibFilePath release];
    [rtfFilePath release];
    [applicationSupportPath release];
    [binPathDir release];
    [theLock release];
    [super dealloc];
}
@end
