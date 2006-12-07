//  BDSKPreviewer.m

//  Created by Michael McCracken on Tue Jan 29 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006
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
#import "BibDocument.h"
#import "BDSKFontManager.h"
#import "NSArray_BDSKExtensions.h"
#import "BDSKPrintableView.h"

enum {
	BDSKUnknownPreviewState = -1,
	BDSKEmptyPreviewState = 0,
	BDSKWaitingPreviewState = 1,
	BDSKShowingPreviewState = 2
};

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
        if(thePreviewer){
            [self release];
            self = thePreviewer;
        } else {
            texTask = [[BDSKTeXTask alloc] initWithFileName:@"bibpreview"];
            [texTask setDelegate:self];
            
            messageQueue = [[BDSKPreviewMessageQueue alloc] init];
            [messageQueue startBackgroundProcessors:1];
            [messageQueue setSchedulesBasedOnPriority:NO];
            
            OFSimpleLockInit(&stateLock);
            
            // this reflects the currently expected state, not necessarily the actual state
            // it corresponds to the last drawing item added to the mainQueue
            previewState = BDSKUnknownPreviewState;
        }
    }
    return self;
}

#pragma mark UI setup and display

- (void)awakeFromNib{
    volatile float scaleFactor = [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKPreviewPDFScaleFactorKey];
    DraggableScrollView *scrollView;
	
	[self setWindowFrameAutosaveName:@"BDSKPreviewPanel"];
    
    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3){
		scrollView = (DraggableScrollView*)[imagePreviewView enclosingScrollView];
		[scrollView setScaleFactor:scaleFactor];
        
        [self drawPreviewsForState:BDSKEmptyPreviewState];
    } else {
        NSRect frameRect = [imagePreviewView frame];
        pdfView = [[NSClassFromString(@"BDSKZoomablePDFView") alloc] initWithFrame:frameRect];
        [[tabView tabViewItemAtIndex:0] setView:pdfView];
        [pdfView release];
        [self drawPreviewsForState:BDSKEmptyPreviewState];
        
        // don't reset the scale factor until there's a document loaded, or else we get a huge gray border
        [pdfView setScaleFactor:scaleFactor];
    }
    	
    scrollView = (DraggableScrollView*)[rtfPreviewView enclosingScrollView];
	scaleFactor = [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKPreviewRTFScaleFactorKey];
	[scrollView setScaleFactor:scaleFactor];
	
	// overlay the progressIndicator over the contentView
	[progressOverlay overlayView:[[self window] contentView]];
	// we use threads, so better let the progressIndicator also use them
	[progressIndicator setUsesThreadedAnimation:YES];
	
	// register to observe when the preview needs to be updated (handle this here rather than on a per document basis as the preview is currently global for the application)
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handlePreviewNeedsUpdate:)
												 name:BDSKPreviewNeedsUpdateNotification
											   object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleApplicationWillTerminate:)
												 name:NSApplicationWillTerminateNotification
											   object:NSApp];
}

- (NSString *)windowNibName
{
    return @"Previewer";
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem{
	SEL act = [menuItem action];

	if (act == @selector(toggleShowingPreviewPanel:)){ 
		// menu item for toggling the preview panel
		// set the on/off state according to the panel's visibility
		if ([[self window] isVisible]) {
			[menuItem setState:NSOnState];
		}else {
			[menuItem setState:NSOffState];
		}
	}
    return YES;
}

#pragma mark Actions

- (IBAction)toggleShowingPreviewPanel:(id)sender{
    if([[self window] isVisible]){
		[self hidePreviewPanel:sender];
    }else{
		[self showPreviewPanel:sender];
    }
}

- (IBAction)showPreviewPanel:(id)sender{
	[self showWindow:self];
    if(![[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKUsesTeXKey])
        NSBeginAlertSheet(NSLocalizedString(@"Previewing is Disabled.", @"TeX preview is disabled"),
                          NSLocalizedString(@"Yes", @""),
                          NSLocalizedString(@"No", @""),
                          nil,
                          [self window],
                          self,
                          @selector(shouldShowTeXPreferences:returnCode:contextInfo:),
                          NULL, NULL,
                          NSLocalizedString(@"TeX previewing must be enabled in BibDesk's preferences in order to use this feature.  Would you like to open the preference pane now?", @"") );
}

- (void)shouldShowTeXPreferences:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    if(returnCode == NSAlertDefaultReturn){
        [[BDSKPreferenceController sharedPreferenceController] showPreferencesPanel:nil];
        [[BDSKPreferenceController sharedPreferenceController] setCurrentClientByClassName:@"BibPref_TeX"];
    }else{
		[self hidePreviewPanel:nil];
	}
}

- (IBAction)hidePreviewPanel:(id)sender{
	[[self window] close];
}

- (IBAction)showWindow:(id)sender{
	[super showWindow:sender];
	[progressOverlay orderFront:sender];
	[self handlePreviewNeedsUpdate:nil];
}

- (void)handlePreviewNeedsUpdate:(NSNotification *)notification {
    id document = [[NSApp orderedDocuments] firstObject];
    if(document && [document respondsToSelector:@selector(updatePreviews:)])
        [document updatePreviews:nil];
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

#pragma mark Drawing methods

- (NSData *)PDFDataWithString:(NSString *)string color:(NSColor *)color{
	NSData *data;
	BDSKPrintableView *printableView = [[BDSKPrintableView alloc] initForScreenDisplay:YES];
	[printableView setFont:[(BDSKFontManager *)[BDSKFontManager sharedFontManager] bodyFontForFamily:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKPreviewPaneFontFamilyKey]]];
	[printableView setTextColor:color];
	data = [printableView PDFDataWithString:string];
	[printableView release];
	return data;
}

// This should only be called from the main thread
- (void)performDrawingForState:(int)state{
    
    if ([self previewState] != state)
		return; // we should already be in another state, so we ignore this one
	
    NSAssert2([NSThread inMainThread], @"-[%@ %@] must be called from the main thread!", [self class], NSStringFromSelector(_cmd));
	
	// start or stop the spinning wheel
	if(state == BDSKWaitingPreviewState)
		[progressIndicator startAnimation:nil];
    else
		[progressIndicator stopAnimation:nil];
	
    // if we're offscreen, no point in doing any extra work; we want to be able to reset offscreen though
    if(![[self window] isVisible] && state != BDSKEmptyPreviewState){
        return;
    }
	
	NSString *message = nil;
    NSData *pdfData = nil;
	NSAttributedString *attrString = nil;
	static NSData *emptyMessagePDFData = nil;
	static NSData *generatingMessagePDFData = nil;
	
	// get the data to display
	if(state == BDSKShowingPreviewState){
		
        NSData *rtfData = nil;
		if([texTask hasRTFData] && (rtfData = [texTask RTFData]) != nil)
			attrString = [[NSAttributedString alloc] initWithRTF:rtfData documentAttributes:NULL];
		else
			message = NSLocalizedString(@"***** ERROR:  unable to create preview *****", @"");
		
		if([texTask hasPDFData] == NO || (pdfData = [texTask PDFData]) == nil){
			// show the TeX log file in the view
			NSMutableString *errorString = [[NSMutableString alloc] initWithCapacity:200];
			[errorString appendString:NSLocalizedString(@"TeX preview generation failed.  Please review the log below to determine the cause.", @"")];
			[errorString appendString:@"\n\n"];
			[errorString appendString:[texTask logFileString]];
			pdfData = [self PDFDataWithString:errorString color:[NSColor redColor]];
			[errorString release];
		}
		
	}else if(state == BDSKEmptyPreviewState){
		
		message = NSLocalizedString(@"No items are selected.", @"No items are selected.");
		
		if (emptyMessagePDFData == nil)
			emptyMessagePDFData = [[self PDFDataWithString:message color:[NSColor grayColor]] retain];
		pdfData = emptyMessagePDFData;
		
	}else if(state == BDSKWaitingPreviewState){
		
		message = [NSString stringWithFormat:@"%@%C", NSLocalizedString(@"Generating preview", @"Generating preview..."), 0x2026];
		
		if (generatingMessagePDFData == nil)
			generatingMessagePDFData = [[self PDFDataWithString:message color:[NSColor grayColor]] retain];
		pdfData = generatingMessagePDFData;
		
	}
	
	OBPOSTCONDITION(pdfData != nil);
	
	// draw the PDF preview
    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3){
        [imagePreviewView loadData:pdfData];
    } else {
        id pdfDocument = [[NSClassFromString(@"PDFDocument") alloc] initWithData:pdfData];
        [(PDFView *)pdfView setDocument:pdfDocument];
        [pdfDocument release];
    }    
    
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
    
}	

- (void)drawPreviewsForState:(int)state{
    
	// this should not be queued, so we know our expected state
	if (![self changePreviewState:state])
		return; // the last element in the queue was already in this state, so no need to add it again
	
	// flush the queue as any remaining invocations are not valid anymore
	if (state == BDSKEmptyPreviewState)
		[messageQueue removeAllInvocations];

	[[OFMessageQueue mainQueue] queueSelector:@selector(performDrawingForState:) forObject:self withInt:state];
}

#pragma mark TeX Tasks

- (void)updateWithBibTeXString:(NSString *)bibStr{
    
	// pool for MT
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	if([NSString isEmptyString:bibStr]){
		// reset, also removes any waiting tasks from the queue
		NS_DURING
			[self drawPreviewsForState:BDSKEmptyPreviewState];
		NS_HANDLER
			NSLog(@"Failed to reset previews: %@", [localException reason]);
		NS_ENDHANDLER
		
    }else{
		// this will start the spinning wheel
		NS_DURING
            [self drawPreviewsForState:BDSKWaitingPreviewState];
		NS_HANDLER
			NSLog(@"Failed to invalidate previews: %@", [localException reason]);
		NS_ENDHANDLER
		// put a new task on the queue
		[messageQueue queueSelector:@selector(runWithBibTeXString:) forObject:texTask withObject:bibStr];
	}
	
    [pool release];
}

- (BOOL)texTaskShouldStartRunning:(BDSKTeXTask *)texTask{
	// not really necessary, as we would never be called when previews were reset
	return ![self isEmpty];
}

- (void)texTask:(BDSKTeXTask *)aTexTask finishedWithResult:(BOOL)success{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if([self isEmpty] || [messageQueue hasInvocations]){
		// we finished a task that was running when the previews were reset, or we have more updates waiting
		// so we ignore the result of this task
		[pool release];
		return; 
    }
	
	// if we didn't have success, the drawing method will show the log file
	NS_DURING
		[self drawPreviewsForState:BDSKShowingPreviewState];
	NS_HANDLER
		NSLog(@"Failed to draw previews: %@", [localException reason]);
	NS_ENDHANDLER
	
	[pool release];
}

#pragma mark Data accessors

- (NSData *)PDFData{
	if([texTask hasPDFData] && ![self isEmpty] && ![messageQueue hasInvocations] && [[self window] isVisible]){
		return [texTask PDFData];
	}
	return nil;
}

- (NSData *)RTFData{
	if([texTask hasRTFData] && ![self isEmpty] && ![messageQueue hasInvocations] && [[self window] isVisible]){
		return [texTask RTFData];
	}
	return nil;
}

- (NSString *)LaTeXString{
	if([texTask hasLaTeX] && ![self isEmpty] && ![messageQueue hasInvocations] && [[self window] isVisible]){
		return [texTask LaTeXString];
	}
	return nil;
}

- (BOOL)isEmpty{
	return ([self previewState] == BDSKEmptyPreviewState);
}

- (int)previewState{
	int state = BDSKUnknownPreviewState;
	OFSimpleLock(&stateLock); // or Try?
	state = previewState;
	OFSimpleUnlock(&stateLock);
	return state;
}

- (BOOL)changePreviewState:(int)state{
	OFSimpleLock(&stateLock); // I don't think Try, as it would mean we might not add to the queue
	if (previewState == state) {
		OFSimpleUnlock(&stateLock);
		return NO;
	}
	previewState = state;
	OFSimpleUnlock(&stateLock);
	return YES;
}

#pragma mark Cleanup

- (void)windowWillClose:(NSNotification *)notification{
	[self drawPreviewsForState:BDSKEmptyPreviewState];
}

- (void)handleApplicationWillTerminate:(NSNotification *)notification{
	// save the visibility of the previewer
	[[OFPreferenceWrapper sharedPreferenceWrapper] setBool:[[self window] isVisible] forKey:BDSKShowingPreviewKey];
    // save the scalefactors of the views
    volatile float scaleFactor = 0.0;
    if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3)
        scaleFactor = [(DraggableScrollView*)[imagePreviewView enclosingScrollView] scaleFactor];
    else
        scaleFactor = ([pdfView autoScales] ? 0.0 : [pdfView scaleFactor]);

	if (scaleFactor != [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKPreviewPDFScaleFactorKey])
		[[OFPreferenceWrapper sharedPreferenceWrapper] setFloat:scaleFactor forKey:BDSKPreviewPDFScaleFactorKey];
	scaleFactor = [(DraggableScrollView*)[rtfPreviewView enclosingScrollView] scaleFactor];
	if (scaleFactor != [[OFPreferenceWrapper sharedPreferenceWrapper] floatForKey:BDSKPreviewRTFScaleFactorKey])
		[[OFPreferenceWrapper sharedPreferenceWrapper] setFloat:scaleFactor forKey:BDSKPreviewRTFScaleFactorKey];
    
    // make sure we don't process anything else; the TeX task will take care of its own cleanup
    [messageQueue removeAllInvocations];
    [messageQueue release];
    messageQueue = nil;
    
	// call this here, since we can't guarantee that the task received the NSApplicationWillTerminate before we flushed the queue
    [texTask terminate];
	[texTask release]; // This removes the temporary directory. Doing this here as we are a singleton. 
	texTask = nil;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [messageQueue release];
	[texTask release];
    OFSimpleLockFree(&stateLock);
    [super dealloc];
}
@end
