//  BDSKPreviewer.m

//  Created by Michael McCracken on Tue Jan 29 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006,2007
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
#import "BDSKTeXTask.h"
#import "BDSKOverlay.h"
#import "BibAppController.h"
#import "BDSKZoomableScrollView.h"
#import "BDSKZoomablePDFView.h"
#import <OmniFoundation/NSThread-OFExtensions.h>
#import "BibDocument.h"
#import "BDSKFontManager.h"
#import "NSString_BDSKExtensions.h"
#import "NSArray_BDSKExtensions.h"
#import "BDSKPrintableView.h"
#import "NSWindowController_BDSKExtensions.h"
#import "BDSKCollapsibleView.h"
#import "BDSKAsynchronousDOServer.h"
#import "BDSKDocumentController.h"

static NSString *BDSKPreviewPanelFrameAutosaveName = @"BDSKPreviewPanel";

@protocol BDSKPreviewerServerThread <BDSKAsyncDOServerThread>
- (oneway void)runTeXTaskWithString:(NSString *)string;
@end

@protocol BDSKPreviewerServerMainThread <BDSKAsyncDOServerMainThread>
- (oneway void)serverFinishedWithResult:(BOOL)success;
@end

@interface BDSKPreviewerServer : BDSKAsynchronousDOServer <BDSKPreviewerServerThread, BDSKPreviewerServerMainThread> {
    BDSKTeXTask *texTask;
    id delegate;
    NSString *bibString;
}

- (id)delegate;
- (void)setDelegate:(id)newDelegate;
- (BDSKTeXTask *)texTask;
- (void)runTeXTaskInBackgroundWithString:(NSString *)string;

@end

@interface NSObject (BDSKPreviewerServerDelegate)
- (void)serverFinishedWithResult:(BOOL)success;
@end

#pragma mark -

@implementation BDSKPreviewer

+ (BDSKPreviewer *)sharedPreviewer{
    static BDSKPreviewer *sharedPreviewer = nil;

    if (sharedPreviewer == nil) {
        sharedPreviewer = [[self alloc] init];
    }
    return sharedPreviewer;
}

- (id)init{
    if(self = [super init]){
        // this reflects the currently expected state, not necessarily the actual state
        // it corresponds to the last drawing item added to the mainQueue
        previewState = BDSKUnknownPreviewState;
        
        // otherwise a document's previewer might mess up the window position of the shared previewer
        [self setShouldCascadeWindows:NO];
        
        server = [[BDSKPreviewerServer alloc] init];
        [server setDelegate:self];
    }
    return self;
}

- (BOOL)isSharedPreviewer { return [self isEqual:[[self class] sharedPreviewer]]; }

#pragma mark UI setup and display

- (void)awakeFromNib{
    float pdfScaleFactor = 0.0;
    float rtfScaleFactor = 1.0;
    BDSKCollapsibleView *collapsibleView = (BDSKCollapsibleView *)[[[progressOverlay contentView] subviews] firstObject];
    NSSize minSize = [progressIndicator frame].size;
    
    // we use threads, so better let the progressIndicator also use them
    [progressIndicator setUsesThreadedAnimation:YES];
    minSize.height += NSMinY([[progressIndicator superview] frame]);
    [collapsibleView setMinSize:minSize];
    [collapsibleView setCollapseEdges:BDSKMaxXEdgeMask | BDSKMaxYEdgeMask];
	
    if([self isSharedPreviewer]){
        [self setWindowFrameAutosaveName:BDSKPreviewPanelFrameAutosaveName];
        
        // overlay the progressIndicator over the contentView
        [progressOverlay overlayView:[[self window] contentView]];
        
        pdfScaleFactor = [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKPreviewPDFScaleFactorKey];
        rtfScaleFactor = [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKPreviewRTFScaleFactorKey];
        
        // register to observe when the preview needs to be updated (handle this here rather than on a per document basis as the preview is currently global for the application)
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleApplicationWillTerminate:)
                                                     name:NSApplicationWillTerminateNotification
                                                   object:NSApp];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleMainDocumentDidChangeNotification:)
                                                     name:BDSKDocumentControllerDidChangeMainDocumentNotification
                                                   object:nil];
    }
        
    // empty document to avoid problem when zoom is set to auto
    PDFDocument *pdfDoc = [[[PDFDocument alloc] initWithData:[self PDFDataWithString:@"" color:nil]] autorelease];
    [pdfView setDocument:pdfDoc];
    
    // don't reset the scale factor until there's a document loaded, or else we get a huge gray border
    [pdfView setScaleFactor:pdfScaleFactor];
	[(BDSKZoomableScrollView *)[rtfPreviewView enclosingScrollView] setScaleFactor:rtfScaleFactor];
    
    [self displayPreviewsForState:BDSKEmptyPreviewState];
    
    [pdfView retain];
    [[rtfPreviewView enclosingScrollView] retain];
}

- (NSString *)windowNibName
{
    return @"Previewer";
}

- (void)handleMainDocumentDidChangeNotification:(NSNotification *)notification
{
    OBASSERT([self isSharedPreviewer]);
    if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKUsesTeXKey] && [self isWindowVisible])
        [[[NSDocumentController sharedDocumentController] mainDocument] updatePreviewer:self];
}

- (void)updateRepresentedFilename
{
    NSString *path = nil;
	if(previewState == BDSKShowingPreviewState){
        path = ([tabView indexOfTabViewItem:[tabView selectedTabViewItem]] == 0) ? [[server texTask] PDFFilePath] : [[server texTask] RTFFilePath];
        if(path == nil)
            path = [[server texTask] logFilePath];
    }
    [[self window] setRepresentedFilename:path ? path : @""];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [self updateRepresentedFilename];
}

- (PDFView *)pdfView;
{
    [self window];
    return pdfView;
}

- (NSTextView *)textView;
{
    [self window];
    return rtfPreviewView;
}

- (BDSKOverlay *)progressOverlay;
{
    [self window];
    return progressOverlay;
}

- (float)PDFScaleFactor;
{
    [self window];
    return [pdfView autoScales] ? 0.0 : [pdfView scaleFactor];
}

- (void)setPDFScaleFactor:(float)scaleFactor;
{
    [self window];
    [pdfView setScaleFactor:scaleFactor];
}

- (float)RTFScaleFactor;
{
    [self window];
    return [(BDSKZoomableScrollView *)[rtfPreviewView enclosingScrollView] scaleFactor];
}

- (void)setRTFScaleFactor:(float)scaleFactor;
{
    [self window];
    [(BDSKZoomableScrollView *)[rtfPreviewView enclosingScrollView] setScaleFactor:scaleFactor];
}

- (BOOL)isVisible{
    return [[pdfView window] isVisible] || [[rtfPreviewView window] isVisible];
}

#pragma mark Actions

- (IBAction)showWindow:(id)sender{
    OBASSERT([self isSharedPreviewer]);
	[super showWindow:self];
	[progressOverlay orderFront:sender];
	[(BibDocument *)[[NSDocumentController sharedDocumentController] currentDocument] updatePreviewer:self];
    if(![[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKUsesTeXKey])
        NSBeginAlertSheet(NSLocalizedString(@"Previewing is Disabled.", @"Message in alert dialog when showing preview with TeX preview disabled"),
                          NSLocalizedString(@"Yes", @"Button title"),
                          NSLocalizedString(@"No", @"Button title"),
                          nil,
                          [self window],
                          self,
                          @selector(shouldShowTeXPreferences:returnCode:contextInfo:),
                          NULL, NULL,
                          NSLocalizedString(@"TeX previewing must be enabled in BibDesk's preferences in order to use this feature.  Would you like to open the preference pane now?", @"Informative text in alert dialog") );
}

- (void)shouldShowTeXPreferences:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    if(returnCode == NSAlertDefaultReturn){
        [[BDSKPreferenceController sharedPreferenceController] showPreferencesPanel:nil];
        [[BDSKPreferenceController sharedPreferenceController] setCurrentClientByClassName:@"BibPref_TeX"];
    }else{
		[self hideWindow:nil];
	}
}

// first responder gets this
- (void)printDocument:(id)sender{
    if([tabView indexOfTabViewItem:[tabView selectedTabViewItem]] == 0){
        [pdfView printWithInfo:[NSPrintInfo sharedPrintInfo] autoRotate:NO];
    }else{
        BDSKPrintableView *printableView = [[BDSKPrintableView alloc] initForScreenDisplay:NO];
        [printableView setAttributedString:[rtfPreviewView textStorage]];    
        
        // Construct the print operation and setup Print panel
        NSPrintOperation *op = [NSPrintOperation printOperationWithView:printableView
                                                              printInfo:[NSPrintInfo sharedPrintInfo]];
        [op setShowPanels:YES];
        [op setCanSpawnSeparateThread:YES];
        
        // Run operation, which shows the Print panel if showPanels was YES
        [op runOperationModalForWindow:[self window] delegate:nil didRunSelector:NULL contextInfo:NULL];
    }
}

#pragma mark Drawing methods

- (NSData *)PDFDataWithString:(NSString *)string color:(NSColor *)color{
	NSData *data;
	BDSKPrintableView *printableView = [[BDSKPrintableView alloc] initForScreenDisplay:YES];
	[printableView setFont:[NSFontManager bodyFontForFamily:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKPreviewPaneFontFamilyKey]]];
	[printableView setTextColor:color];
	data = [printableView PDFDataWithString:string];
	[printableView release];
	return data;
}

- (void)displayPreviewsForState:(BDSKPreviewState)state{
    
    NSAssert2([NSThread inMainThread], @"-[%@ %@] must be called from the main thread!", [self class], NSStringFromSelector(_cmd));
    
    // From Shark: if we were waiting before, and we're still waiting, there's nothing to do.  This is a big performance win when scrolling the main tableview selection, primarily because changing the text storage of rtfPreviewView ends up calling fixFontAttributes.  This in turn causes a disk hit at the ATS cache due to +[NSFont coveredCharacterCache], and parsing the binary plist uses lots of memory.
    if (BDSKWaitingPreviewState == previewState && BDSKWaitingPreviewState == state)
        return;
    
	previewState = state;
		
    // start or stop the spinning wheel
    if(state == BDSKWaitingPreviewState)
        [progressIndicator startAnimation:nil];
    else
        [progressIndicator stopAnimation:nil];
	
    // if we're offscreen, no point in doing any extra work; we want to be able to reset offscreen though
    if(![self isVisible] && state != BDSKEmptyPreviewState){
        return;
    }
	
    NSString *message = nil;
    NSData *pdfData = nil;
	NSAttributedString *attrString = nil;
	static NSData *emptyMessagePDFData = nil;
	static NSData *generatingMessagePDFData = nil;
	
	// get the data to display
	if(state == BDSKShowingPreviewState){
        
        NSData *rtfData = [self RTFData];
		if(rtfData != nil)
			attrString = [[NSAttributedString alloc] initWithRTF:rtfData documentAttributes:NULL];
		else
			message = NSLocalizedString(@"***** ERROR:  unable to create preview *****", @"Preview message");
		
		pdfData = [self PDFData];
        if(pdfData == nil){
			// show the TeX log file in the view
			NSMutableString *errorString = [[NSMutableString alloc] initWithCapacity:200];
			[errorString appendString:NSLocalizedString(@"TeX preview generation failed.  Please review the log below to determine the cause.", @"Preview message")];
			[errorString appendString:@"\n\n"];
            
            // now that we correctly check return codes from the NSTask, users blame us for TeX preview failures that have been failing all along, so we'll try to give them a clue to the error if possible (which may save a LART later on)
            NSSet *standardStyles = [NSSet setWithObjects:@"abbrv", @"acm", @"alpha", @"apalike", @"ieeetr", @"plain", @"siam", @"unsrt", nil];
            NSString *btStyle = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKBTStyleKey];
            if([standardStyles containsObject:btStyle] == NO)
                [errorString appendFormat:NSLocalizedString(@"***** WARNING: You are using a non-standard BibTeX style *****\nThe style \"%@\" may require additional \\usepackage commands to function correctly.\n\n", @"possible cause of TeX failure"), btStyle];
            
            NSString *logString = [[server texTask] logFileString];
            if (nil == logString)
                logString = NSLocalizedString(@"Unable to read log file from TeX run.", @"Preview message");
			[errorString appendString:logString];
			pdfData = [self PDFDataWithString:errorString color:[NSColor redColor]];
			[errorString release];
		}
        
	}else if(state == BDSKEmptyPreviewState){
		
		message = NSLocalizedString(@"No items are selected.", @"Preview message");
		
		if (emptyMessagePDFData == nil)
			emptyMessagePDFData = [[self PDFDataWithString:message color:[NSColor grayColor]] retain];
		pdfData = emptyMessagePDFData;
		
	}else if(state == BDSKWaitingPreviewState){
		
		message = [NSLocalizedString(@"Generating preview", @"Preview message") stringByAppendingEllipsis];
		
		if (generatingMessagePDFData == nil)
			generatingMessagePDFData = [[self PDFDataWithString:message color:[NSColor grayColor]] retain];
		pdfData = generatingMessagePDFData;
		
	}
	
	OBPOSTCONDITION(pdfData != nil);
	
	// draw the PDF preview
    PDFDocument *pdfDocument = [[PDFDocument alloc] initWithData:pdfData];
    [pdfView setDocument:pdfDocument];
    [pdfDocument release];
    
    // draw the RTF preview
	[rtfPreviewView setString:@""];
	[rtfPreviewView setTextContainerInset:NSMakeSize(20,20)];  // pad the edges of the text
	if(attrString){
		[[rtfPreviewView textStorage] appendAttributedString:attrString];
		[attrString release];
	} else if (message){
        NSTextStorage *ts = [rtfPreviewView textStorage];
        [[ts mutableString] setString:message];
        [ts addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:NSMakeRange(0, [ts length])];
	}
    
    if([self isSharedPreviewer])
        [self updateRepresentedFilename];
}

#pragma mark TeX Tasks

- (void)updateWithBibTeXString:(NSString *)bibStr{
    
	if([NSString isEmptyString:bibStr]){
		// reset, also removes any waiting tasks from the queue
        [self displayPreviewsForState:BDSKEmptyPreviewState];
        // clean the server
        [server runTeXTaskInBackgroundWithString:nil];
    } else {
		// this will start the spinning wheel
        [self displayPreviewsForState:BDSKWaitingPreviewState];
        // run the tex task in the background
        [server runTeXTaskInBackgroundWithString:bibStr];
	}	
}

- (void)serverFinishedWithResult:(BOOL)success{
    // ignore this task if we finished a task that was running when the previews were reset
	if(previewState != BDSKEmptyPreviewState) {
        // if we didn't have success, the drawing method will show the log file
        [self displayPreviewsForState:BDSKShowingPreviewState];
    }
}

#pragma mark Data accessors

- (NSData *)PDFData{
	if(previewState != BDSKShowingPreviewState || [self isVisible] == NO)
        return nil;
    return [[server texTask] PDFData];
}

- (NSData *)RTFData{
	if(previewState != BDSKShowingPreviewState || [self isVisible] == NO)
        return nil;
    return [[server texTask] RTFData];
}

- (NSString *)LaTeXString{
	if(previewState != BDSKShowingPreviewState || [self isVisible] == NO)
        return nil;
    return [[server texTask] LaTeXString];
}

#pragma mark Cleanup

- (void)windowWillClose:(NSNotification *)notification{
	[self displayPreviewsForState:BDSKEmptyPreviewState];
}

- (void)handleApplicationWillTerminate:(NSNotification *)notification{
    OBASSERT([self isSharedPreviewer]);
    
	// save the visibility of the previewer
	[[OFPreferenceWrapper sharedPreferenceWrapper] setBool:[self isWindowVisible] forKey:BDSKShowingPreviewKey];
    // save the scalefactors of the views
    float scaleFactor = ([pdfView autoScales] ? 0.0 : [pdfView scaleFactor]);

	if (fabs(scaleFactor - [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKPreviewPDFScaleFactorKey]) > 0.01)
		[[OFPreferenceWrapper sharedPreferenceWrapper] setFloat:scaleFactor forKey:BDSKPreviewPDFScaleFactorKey];
	scaleFactor = [(BDSKZoomableScrollView*)[rtfPreviewView enclosingScrollView] scaleFactor];
	if (fabs(scaleFactor - [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKPreviewRTFScaleFactorKey]) > 0.01)
		[[OFPreferenceWrapper sharedPreferenceWrapper] setFloat:scaleFactor forKey:BDSKPreviewRTFScaleFactorKey];
    
    // make sure we don't process anything else; the TeX task will take care of its own cleanup
    [server stopDOServer];
    [server release];
    server = nil;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // make sure we don't process anything else; the TeX task will take care of its own cleanup
    [server stopDOServer];
    [server release];
    [pdfView release];
    [[rtfPreviewView enclosingScrollView] release];
    [super dealloc];
}

@end

#pragma mark -

@implementation BDSKPreviewerServer

- (id)init;
{
    self = [super init];
    if(self){
        texTask = [[BDSKTeXTask alloc] initWithFileName:@"bibpreview"];
        delegate = nil;
        bibString = nil;
    }
    return self;
}

- (void)dealloc;
{
    [texTask release];
    [super dealloc];
}

- (oneway void)cleanup{
    [bibString release];
    bibString = nil;
    [texTask terminate];
    [super cleanup];
}

// superclass overrides

- (Protocol *)protocolForServerThread { return @protocol(BDSKPreviewerServerThread); }

- (Protocol *)protocolForMainThread { return @protocol(BDSKPreviewerServerMainThread); }

// main thread API

- (id)delegate { return delegate; }

- (void)setDelegate:(id)newDelegate { delegate = newDelegate; }

- (BDSKTeXTask *)texTask{
    return texTask;
}

- (void)runTeXTaskInBackgroundWithString:(NSString *)string{
    // the delayed perform is because [self serverOnServerThread] returns nil the first time this is received, since the server thread hasn't had time to set up completely
    id server = [self serverOnServerThread];
    if (server)
        [server runTeXTaskWithString:string];
    else
        [self performSelector:_cmd withObject:string afterDelay:0.1];
}

// Server thread protocol

- (oneway void)runTeXTaskWithString:(NSString *)aString{
    [bibString release];
    bibString = [aString retain];
    
    if([texTask isProcessing] || bibString == nil)
        return;
    
    NSString *string;
    BOOL success;
    
    do{
        string = bibString;
        bibString = nil;
        success = [texTask runWithBibTeXString:string];
        [string release];
    }while(bibString != nil);
    
    [[self serverOnMainThread] serverFinishedWithResult:success];
}

// Main thread protocol

- (oneway void)serverFinishedWithResult:(BOOL)success{
    if([delegate respondsToSelector:@selector(serverFinishedWithResult:)])
        [delegate serverFinishedWithResult:success];
}

@end
