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
#import "BDSKPreviewMessageQueue.h"
#import <OmniFoundation/NSThread-OFExtensions.h>

static BOOL
runTeXTask(NSString *applicationSupportPath, NSString *fileName, NSString *binPathDir);

static BOOL
runBibTeXTask(NSString *applicationSupportPath, NSString *fileName);

static BOOL
runLaTeX2RTFTask(NSString *applicationSupportPath, NSString *fileName);


/*! @const BDSKPreviewer helps to enforce a single object of this class */
static BDSKPreviewer *thePreviewer;

OFSimpleLockType drawingLock;

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
        usertexTemplatePath = [[applicationSupportPath stringByAppendingPathComponent:@"previewtemplate.tex"] retain];
        texTemplatePath = [[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.tex"] retain];
        finalPDFPath = [[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.pdf"] retain];
        nopreviewPDFPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"nopreview.pdf"] retain];
        tmpBibFilePath = [[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.bib"] retain];
        rtfFilePath = [[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.rtf"] retain];
        binPathDir = [[NSString alloc] init]; // set from where we run the tasks, since some programs (e.g. XeLaTeX) need a real path setting        
        messageQueue = [[BDSKPreviewMessageQueue alloc] init];
        [messageQueue setDelegate:self];
        [messageQueue startBackgroundProcessors:1];
        [messageQueue setSchedulesBasedOnPriority:NO];
        OFSimpleLockInit(&drawingLock);
    }
    return self;
}

#pragma mark Message Queue

// required for OFMessageQueue delegate
OFWeakRetainConcreteImplementation_NULL_IMPLEMENTATION

- (void)queueHasInvocations:(OFMessageQueue *)aQueue;
{
    [messageQueue hasInvocations];
}

#pragma mark UI setup and display

- (void)awakeFromNib{
    [self setWindowFrameAutosaveName:@"BDSKPreviewPanel"];

	DraggableScrollView *scrollView = (DraggableScrollView*)[imagePreviewView enclosingScrollView];
    float scaleFactor = [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKPreviewPDFScaleFactorKey];
	[scrollView setScaleFactor:scaleFactor];
    
    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3){
        [self performSelectorOnMainThread:@selector(resetPreviews) withObject:nil waitUntilDone:YES];
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
    OFSimpleLock(&drawingLock);

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    OBASSERT([NSThread inMainThread]);
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
    
    [pool release];

    OFSimpleUnlock(&drawingLock);
    [self displayRTFPreviewFromData:[self RTFPreviewData]]; // does its own locking of the view
}	

// This should only be called from the main thread
- (void)resetPreviews{
    OFSimpleLock(&drawingLock);
	
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    OBASSERT([NSThread inMainThread]);

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
	
	[pool release];
    OFSimpleUnlock(&drawingLock);
}

- (BOOL)displayRTFPreviewFromData:(NSData *)rtfdata{  // This draws the RTF in a textview
    OFSimpleLock(&drawingLock);
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    OBASSERT([NSThread inMainThread]);
    BOOL rv = YES;
    
    NSSize inset = NSMakeSize(20,20); // set this for the margin
    
    [rtfPreviewView setString:@""];   // clean the view
    [rtfPreviewView setTextContainerInset:inset];  // pad the edges of the text
    
    // we get a zero-length string if a bad bibstyle is used, so check for it
    if([rtfdata length] > 0){
        [rtfPreviewView replaceCharactersInRange:[rtfPreviewView selectedRange]
                                         withRTF:rtfdata];
    } else {
        [rtfPreviewView replaceCharactersInRange: [rtfPreviewView selectedRange]
                                      withString:@"***** ERROR:  unable to create preview *****"];
    	rv = NO;
    }
    [pool release];

    OFSimpleUnlock(&drawingLock);

    return rv;	
}

#pragma mark TeX Tasks

- (BOOL)PDFFromString:(NSString *)str{
    
    // pool for MT
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    volatile BOOL rv = YES;
    
    if(str == nil || [str isEqualToString:@""]){
		NS_DURING
			[self performSelectorOnMainThread:@selector(resetPreviews) withObject:nil waitUntilDone:YES];
		NS_HANDLER
			NSLog(@"Failed to reset previews: %@", [localException reason]);
			rv = NO;
		NS_ENDHANDLER
        [pool release];
        return NO;
    }
    
    [messageQueue queueSelector:@selector(_BDPDFFromString:) forObject:self withObject:str];
    [pool release];
    return YES;
}

- (BOOL)_BDPDFFromString:(NSString *)str;
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    volatile BOOL rv = YES;
    
    NS_DURING
        rv = ([self writeTeXFile] &&
              [self writeBibTeXFile:str] &&
              [self previewTexTasks:@"bibpreview.tex"]);
    NS_HANDLER
        NSLog(@"Failed to perform TeX tasks for previews: %@", [localException reason]);
        rv = NO;
    NS_ENDHANDLER
    
    if(rv){
		NS_DURING
			[self performSelectorOnMainThread:@selector(performDrawing) withObject:nil waitUntilDone:YES];
		NS_HANDLER
			NSLog(@"Failed to draw previews: %@", [localException reason]);
			rv = NO;
		NS_ENDHANDLER
	}
	[pool release];
    
    return rv;    
}

// Files:  previewtemplate.tex is intended to be changed by the user, and so we allow opening
// this file from the preview prefpane.  By using previewtemplate.tex as a base instead of the previous
// bibpreview.tex file, we avoid problems.   Previously if the user was editing the 
// bibpreview.tex file and we overwrote it by running another preview, the editor would lose the file.
// Therefore, bibpreview.* are essentially temporary files, only modified by BibDesk.
- (BOOL)writeTeXFile{
    NSMutableString *finalTexFile = [[NSMutableString alloc] initWithCapacity:200];
    NSString *texFile = [[NSString alloc] initWithContentsOfFile:usertexTemplatePath];
    NSString *prefix = nil;
    NSString *postfix = nil;
    NSString *style = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKBTStyleKey];
    NSScanner *scanner = [[NSScanner alloc] initWithString:texFile];
	[texFile release];

    // replace the appropriate style & bib files.
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
		[finalTexFile release];
		return NO;
	}
	
	[finalTexFile release];
	return YES;
}

- (BOOL)writeBibTeXFile:(NSString *)str{
    NSMutableString *bibTemplate = [[NSMutableString alloc] initWithContentsOfFile:
        [[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKOutputTemplateFileKey] stringByExpandingTildeInPath]];
    
	[bibTemplate appendString:@"\n"];
    [bibTemplate appendString:str];
    if(![[bibTemplate dataUsingEncoding:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKTeXPreviewFileEncodingKey]] writeToFile:tmpBibFilePath atomically:YES]){
        NSLog(@"Error replacing bibfile.");
		[bibTemplate release];
		return NO;
	}
	
	[bibTemplate release];
	return YES;
}

- (BOOL)previewTexTasks:(NSString *)fileName{ // we set working dir in NSTask
        
    // remove the old pdf file.
    [[NSFileManager defaultManager] removeFileAtPath:[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.pdf"]
                                             handler:nil];
    
    if(!runTeXTask(applicationSupportPath, fileName, binPathDir) ||
       !runBibTeXTask(applicationSupportPath, fileName) ||
       !runTeXTask(applicationSupportPath, fileName, binPathDir) ||
       !runTeXTask(applicationSupportPath, fileName, binPathDir) ||
       !runLaTeX2RTFTask(applicationSupportPath, fileName))
        return NO;
    else
        return YES;
}

static BOOL
runTeXTask(NSString *applicationSupportPath, NSString *fileName, NSString *binPathDir)
{
    NSString *pdftexbinpath = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKTeXBinPathKey];

    if(![[pdftexbinpath stringByDeletingLastPathComponent] isEqualToString:binPathDir]){
        [binPathDir release];
        binPathDir = [[pdftexbinpath stringByDeletingLastPathComponent] retain];
        NSString *original_path = [NSString stringWithCString: getenv("PATH")];
        NSString *new_path = [NSString stringWithFormat: @"%@:%@", original_path, binPathDir];
        setenv("PATH", [new_path cString], 1);
    }
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:pdftexbinpath]){
        NSLog(@"runTeXTask cannot continue: %@ not found", pdftexbinpath);
        return NO;    
    }
    
    // Now start the tex task fun.

    NSTask *pdftex = [[NSTask alloc] init];
    [pdftex setCurrentDirectoryPath:applicationSupportPath];
    [pdftex setLaunchPath:pdftexbinpath];
    [pdftex setArguments:[NSArray arrayWithObjects:@"-interaction=batchmode", fileName, nil ]];
    [pdftex setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];

    NS_DURING
        [pdftex launch];
        [pdftex waitUntilExit];
    NS_HANDLER
        if([pdftex isRunning])
            [pdftex terminate];
        NSLog(@"%@ %@ failed", [pdftex description], [pdftex launchPath]);
        [pdftex release];
        return NO;
    NS_ENDHANDLER
    
    return YES;
}

static BOOL
runBibTeXTask(NSString *applicationSupportPath, NSString *fileName)
{
    
    NSString *bibtexbinpath = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKBibTeXBinPathKey];

    if(![[NSFileManager defaultManager] fileExistsAtPath:bibtexbinpath]){        
        NSLog(@"runBibTeXTask cannot continue: %@ not found", bibtexbinpath);
        return NO;     
    }    

    NSTask *bibtex = [[NSTask alloc] init];
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
    
    return YES;
}

static BOOL
runLaTeX2RTFTask(NSString *applicationSupportPath, NSString *fileName)
{
    NSString *latex2rtfpath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"latex2rtf"];
    
    // This task runs latex2rtf on our tex file to generate bibpreview.rtf
    NSTask *latex2rtf = [[NSTask alloc] init];
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

    return YES;
}

#pragma mark Data accessors

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

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [messageQueue release];
    [usertexTemplatePath release];
    [texTemplatePath release];
    [finalPDFPath release];
    [nopreviewPDFPath release];
    [tmpBibFilePath release];
    [rtfFilePath release];
    [applicationSupportPath release];
    [binPathDir release];
    OFSimpleLockFree(&drawingLock);
    [super dealloc];
}
@end