//  BDSKPreviewer.m

//  Created by Michael McCracken on Tue Jan 29 2002.
/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BDSKPreviewer.h"
#import "BibPrefController.h"


/*! @const BDSKPreviewer helps to enforce a single object of this class */
static BDSKPreviewer *thePreviewer;

static unsigned threadCount = 0;

@implementation BDSKPreviewer

+ (BDSKPreviewer *)sharedPreviewer{
    if (!thePreviewer) {
        thePreviewer = [[[BDSKPreviewer alloc] init] retain];
    }
    return thePreviewer;
}

- (id)init{
    applicationSupportPath = [[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
        stringByAppendingPathComponent:@"Application Support"]
        stringByAppendingPathComponent:@"BibDesk"] retain];

    if(self = [super init]){
        bundle = [NSBundle mainBundle];
	usertexTemplatePath = [[applicationSupportPath stringByAppendingPathComponent:@"previewtemplate.tex"] retain];
        texTemplatePath = [[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.tex"] retain];
        finalPDFPath = [[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.pdf"] retain];
        tmpBibFilePath = [[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.bib"] retain];
	rtfFilePath = [[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.rtf"] retain];
        countLock = [[NSLock alloc] init];
        workingLock = [[NSLock alloc] init];
    }
    return self;
}


- (NSString *)windowNibName
{
    return @"Previewer";
}

- (void)windowDidLoad{
             
             [imagePreviewView loadFromPath:finalPDFPath];
	     [self rtfPreviewFromData:[self rtfDataPreview]];  // set up the rtf preview also
}

- (BOOL)PDFFromString:(NSString *)str{
    // pool for MT
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // get a fresh copy of the file:
    NSString *texFile; 

    NSMutableString *bibTemplate; 
    NSString *prefix = [NSString string];
    NSString *postfix = [NSString string];
    NSString *style;
    NSMutableString *finalTexFile = [NSMutableString string];
    NSScanner *s;
    
    unsigned myThreadCount;

    [countLock lock];
    threadCount++;
    myThreadCount = threadCount;
    [countLock unlock];
    
    if(working){
        if(myThreadCount == threadCount){
            // if someone else is working and i'm the top go to sleep for a bit
            [NSThread sleepUntilDate:[[NSDate date] addTimeInterval:2.0]];
        }else{
            // if someone else is working and I'm not the top, die.
            return NO;
        }
    }

    // don't do anything if i'm not the top.
    if(myThreadCount < threadCount)
        return NO;

    [workingLock lock];
    working = YES;
    [workingLock unlock];

//    NSLog(@"**** starting thread %d", myThreadCount);
    
    // Files:  previewtemplate.tex is intended to be changed by the user, and so we allow opening
    // this file from the preview prefpane.  By using previewtemplate.tex as a base instead of the previous
    // bibpreview.tex file, we avoid problems.   Previously if the user was editing the 
    // bibpreview.tex file and we overwrote it by running another preview, the editor would lose the file.
    // Therefore, bibpreview.* are essentially temporary files, only modified by BibDesk.
    texFile = [NSString stringWithContentsOfFile:usertexTemplatePath];
    bibTemplate = [NSMutableString stringWithContentsOfFile:
        [[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKOutputTemplateFileKey] stringByExpandingTildeInPath]];
    s = [NSScanner scannerWithString:texFile];

    //[imagePreviewView setImage:[NSImage imageNamed:@"typesetting.pdf"]];

    // replace the appropriate style & bib files.
    style = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKBTStyleKey];
    [s scanUpToString:@"bibliographystyle{" intoString:&prefix];
    [s scanUpToString:@"}" intoString:nil];
    [s scanUpToString:@"\bye" intoString:&postfix];
    [finalTexFile appendFormat:@"%@bibliographystyle{%@%@", prefix, style, postfix];
    // overwrites the old bibpreview.tex file, replacing the previous bibliographystyle
    if(![finalTexFile writeToFile:texTemplatePath atomically:YES]){
        NSLog(@"error replacing texfile");
        return NO;
    }

    // write out the bib file with the template attached:
    [bibTemplate appendFormat:@"\n%@",str];
    if(![bibTemplate writeToFile:tmpBibFilePath atomically:YES]){
        NSLog(@"Error replacing bibfile.");
        return NO;
    }
    
    if([self previewTexTasks:@"bibpreview.tex"]){ // run the TeX tasks
    
      if (myThreadCount >= threadCount){
	  if([splitView lockFocusIfCanDraw]) {  // Apple Thread Safety docs say to do this if a thread is drawing in a view
	      [imagePreviewView loadFromPath:finalPDFPath];
	      [self rtfPreviewFromData:[self rtfDataPreview]];
	      [splitView unlockFocus];
	  }
      } else{
	  return NO;
      } // if the tex task failed
    }
    
    // Pool for MT
    [pool release];
    
    [workingLock lock];
    working = NO;
    [workingLock unlock];
    
    return YES;    
    
}

- (BOOL)previewTexTasks:(NSString *)fileName{ // we set working dir in NSTask
    
    NSTask *pdftex1;
    NSTask *pdftex2;
    NSTask *bibtex;
    NSString *pdftexbinpath = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKTeXBinPathKey];
    NSString *bibtexbinpath = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKBibTeXBinPathKey];
    NSTask *latex2rtf;
    NSString *latex2rtfpath = [NSString stringWithFormat:@"%@/latex2rtf",[[NSBundle mainBundle] resourcePath]];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:pdftexbinpath]){
#warning need more user-level errors in PDFPreviewer.
        NSLog(@"Incorrect path for pdftex.");
        return NO;
    }
    if(![[NSFileManager defaultManager] fileExistsAtPath:bibtexbinpath]){
        NSLog(@"Incorrect path for bibtex.");
        return NO;
    }

    // remove the old pdf file.
    [[NSFileManager defaultManager] removeFileAtPath:[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.pdf"]
                                             handler:nil];
    
    // Now start the tex task fun.

    //FIXME = we need to deal with errors better...

    pdftex1 = [[NSTask alloc] init];
    [pdftex1 setCurrentDirectoryPath:applicationSupportPath];
    [pdftex1 setLaunchPath:pdftexbinpath];
    [pdftex1 setArguments:[NSArray arrayWithObjects:@"-interaction=batchmode", [NSString stringWithString:fileName],
        nil ]];
    [pdftex1 launch];
    [pdftex1 waitUntilExit];

    bibtex = [[NSTask alloc] init];
    [bibtex setCurrentDirectoryPath:applicationSupportPath];
    [bibtex setLaunchPath:bibtexbinpath];
    [bibtex setArguments:[NSArray arrayWithObjects:[fileName stringByDeletingPathExtension],nil ]];
    [bibtex launch];
    [bibtex waitUntilExit];

    pdftex2 = [[NSTask alloc] init];
    [pdftex2 setCurrentDirectoryPath:applicationSupportPath];
    [pdftex2 setLaunchPath:pdftexbinpath];
    [pdftex2 setArguments:[NSArray arrayWithObjects:@"-interaction=batchmode",[NSString stringWithString:fileName],
        nil ]];
    [pdftex2 launch];
    [pdftex2 waitUntilExit];

    // This task runs latex2rtf on our tex file to generate bibpreview.rtf
    latex2rtf = [[NSTask alloc] init];
    [latex2rtf setCurrentDirectoryPath:applicationSupportPath];
    [latex2rtf setLaunchPath:latex2rtfpath];  // full path to the binary
    // the arguments: it needs -P "path" which is the path to the cfg files in the app wrapper
    [latex2rtf setArguments:[NSArray arrayWithObjects:[NSString stringWithString:@"-P"],
	                   [[NSBundle mainBundle] resourcePath],
	                   [NSString stringWithString:fileName],nil ]];
    [latex2rtf launch];
    [latex2rtf waitUntilExit];
    
    [pdftex1 release];
    [bibtex release];
    [pdftex2 release];
    [latex2rtf release];
    
    return YES;

}

#warning PDFDataFromString is not properly threaded!
- (NSData *)PDFDataFromString:(NSString *)str{
    // pool for MT
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSString *texFile = [NSString stringWithContentsOfFile:usertexTemplatePath];
    NSMutableString *bibTemplate = [NSMutableString stringWithContentsOfFile:
        [[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKOutputTemplateFileKey] stringByExpandingTildeInPath]];

    NSString *prefix;
    NSString *postfix;
    NSString *style;
    NSMutableString *finalTexFile = [NSMutableString string];
    NSScanner *s = [NSScanner scannerWithString:texFile];
    NSTask *pdftex1;
    NSTask *pdftex2;
    NSTask *bibtex;
    NSString *pdftexbinpath = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKTeXBinPathKey];
    NSString *bibtexbinpath = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKBibTeXBinPathKey];
    unsigned myThreadCount;

    [countLock lock];
    threadCount++;
    myThreadCount = threadCount;
    [countLock unlock];

    if(working){
        // if someone else is working and i'm the top go to sleep for a bit
        [NSThread sleepUntilDate:[[NSDate date] addTimeInterval:2.0]];
    }

    
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:pdftexbinpath]){
        NSLog(@"Incorrect path for pdftex.");
        return nil;
    }
    if(![[NSFileManager defaultManager] fileExistsAtPath:bibtexbinpath]){
        NSLog(@"Incorrect path for bibtex.");
        return nil;
    }
   
    if(working) return nil;

    [workingLock lock];
    working = YES;
    [workingLock unlock];

    // replace the appropriate style & bib files.
    style = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKBTStyleKey];
    [s scanUpToString:@"bibliographystyle{" intoString:&prefix];
    [s scanUpToString:@"}" intoString:nil];
    [s scanUpToString:@"\bye" intoString:&postfix];
    [finalTexFile appendFormat:@"%@bibliographystyle{%@%@", prefix, style, postfix];
    if(![finalTexFile writeToFile:texTemplatePath atomically:YES]){
        NSLog(@"error replacing texfile");
        return nil;
    }

    // write out the bib file with the template attached:
    [bibTemplate appendFormat:@"\n%@",str];
    if(![bibTemplate writeToFile:tmpBibFilePath atomically:YES]){
        NSLog(@"Error replacing bibfile.");
        return nil;
    }

    // remove the old pdf file.
    [[NSFileManager defaultManager] removeFileAtPath:[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.pdf"]
                                             handler:nil];

    // Now start the tex task fun.

    //FIXME = we need to deal with errors better...

    pdftex1 = [[NSTask alloc] init];
    [pdftex1 setCurrentDirectoryPath:applicationSupportPath];
    [pdftex1 setLaunchPath:pdftexbinpath];
    [pdftex1 setArguments:[NSArray arrayWithObjects:@"-interaction=batchmode", [NSString stringWithString:@"bibpreview.tex"],
        nil ]];
    [pdftex1 launch];
    [pdftex1 waitUntilExit];

    bibtex = [[NSTask alloc] init];
    [bibtex setCurrentDirectoryPath:applicationSupportPath];
    [bibtex setLaunchPath:bibtexbinpath];
    [bibtex setArguments:[NSArray arrayWithObjects:[NSString stringWithString:@"bibpreview"],nil ]];
    [bibtex launch];
    [bibtex waitUntilExit];

    pdftex2 = [[NSTask alloc] init];
    [pdftex2 setCurrentDirectoryPath:applicationSupportPath];
    [pdftex2 setLaunchPath:pdftexbinpath];
    [pdftex2 setArguments:[NSArray arrayWithObjects:@"-interaction=batchmode",[NSString stringWithString:@"bibpreview.tex"],
        nil ]];
    [pdftex2 launch];
    [pdftex2 waitUntilExit];

    [pdftex1 release];
    [bibtex release];
    [pdftex2 release];

    // pool for MT
    [pool release];

    
    working = NO;
    return [NSData dataWithContentsOfFile:finalPDFPath];
}

- (NSAttributedString *)rtfStringPreview:(NSString *)filePath{      // RTF Preview support
    rtfString = [[[NSAttributedString alloc] initWithPath:filePath documentAttributes:nil] autorelease];
    return rtfString;
}

- (NSData *)rtfDataPreview{   // Returns the RTF as NSData, used for pasteboard ops
    NSData *d = [NSData dataWithContentsOfFile:rtfFilePath];
    return d;
}

- (BOOL)rtfPreviewFromData:(NSData *)rtfdata{  // This draws the RTF in a textview
    NSSize inset = NSMakeSize(20,20); // set this for the margin
    [rtfPreviewView setString:@""];   // clean the view
    [rtfPreviewView setTextContainerInset:inset];  // pad the edges of the text

    // we get a zero-length string if a bad bibstyle is used, so check for it
    if([rtfdata length] > 0){
	[rtfPreviewView replaceCharactersInRange: [rtfPreviewView selectedRange]
				      withRTF:rtfdata];
      return YES;
    }else{
	NSString *errstr = [NSString stringWithString:@"***** ERROR:  unable to create preview *****"];
        [rtfPreviewView replaceCharactersInRange: [rtfPreviewView selectedRange]
				      withString:errstr];
        return NO;
        }
	
}



- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [usertexTemplatePath release];
    [texTemplatePath release];
    [finalPDFPath release];
    [tmpBibFilePath release];
    [rtfFilePath release];
    [applicationSupportPath release];
    [countLock release];
    [workingLock release];
}
@end
