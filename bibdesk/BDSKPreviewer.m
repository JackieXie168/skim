//
//  BDSKPreviewer.m
//  Bibdesk
//
//  Created by Michael McCracken on Tue Jan 29 2002.
//  Copyright (c) 2001 Michael McCracken. All rights reserved.
//

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
        texTemplatePath = [[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.tex"] retain];
        finalPDFPath = [[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.pdf"] retain];
        tmpBibFilePath = [[applicationSupportPath stringByAppendingPathComponent:@"bibpreview.bib"] retain];
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
    image = [[[NSImage alloc] initWithContentsOfFile:finalPDFPath] autorelease];
    [image setBackgroundColor:[NSColor whiteColor]];
    [imagePreviewView setImageAlignment:NSImageAlignTopLeft];
    [imagePreviewView setImageScaling:NSScaleNone];
    [imagePreviewView setImage:image];
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
    texFile = [NSString stringWithContentsOfFile:
        [[NSBundle mainBundle] pathForResource:@"bibpreview" ofType:@"tex"]];
    bibTemplate = [NSMutableString stringWithContentsOfFile:
        [[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKOutputTemplateFileKey] stringByExpandingTildeInPath]];
    s = [NSScanner scannerWithString:texFile];

    [imagePreviewView setImage:[NSImage imageNamed:@"typesetting.pdf"]];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:pdftexbinpath]){
#warning need more user-level errors in PDFPreviewer.
        NSLog(@"Incorrect path for pdftex.");
        return NO;
    }
    if(![[NSFileManager defaultManager] fileExistsAtPath:bibtexbinpath]){
        NSLog(@"Incorrect path for bibtex.");
        return NO;
    }

    bibStep = 0;

    // replace the appropriate style & bib files.
    style = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKBTStyleKey];
    [s scanUpToString:@"bibliographystyle{" intoString:&prefix];
    [s scanUpToString:@"}" intoString:nil];
    [s scanUpToString:@"\bye" intoString:&postfix];
    [finalTexFile appendFormat:@"%@bibliographystyle{%@%@", prefix, style, postfix];
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


    image = [[[NSImage alloc] initWithContentsOfFile:finalPDFPath] autorelease];
    [image setBackgroundColor:[NSColor whiteColor]];

    if (myThreadCount >= threadCount){
        [imagePreviewView setImageAlignment:NSImageAlignTopLeft];
        [imagePreviewView setImageScaling:NSScaleNone];
        [imagePreviewView setImage:image];
    }
    
    [pdftex1 release];
    [bibtex release];
    [pdftex2 release];

    // Pool for MT
    [pool release];

    [workingLock lock];
    working = NO;
    [workingLock unlock];

    return YES;
}

#warning PDFDataFromString isn't properly threaded!
- (NSData *)PDFDataFromString:(NSString *)str{
    // pool for MT
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSString *texFile = [NSString stringWithContentsOfFile:texTemplatePath];
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
    bibStep = 0;

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

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [texTemplatePath release];
    [finalPDFPath release];
    [tmpBibFilePath release];
    [applicationSupportPath release];
    [countLock release];
    [workingLock release];
}
@end
