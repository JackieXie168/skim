//
//  BDSKTeXTask.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 6/8/05.
//
/*
 This software is Copyright (c) 2005,2006,2007
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

#import "BDSKTeXTask.h"
#import "NSFileManager_BDSKExtensions.h"
#import "BibPrefController.h"
#import "BibAppController.h"
#import <OmniFoundation/NSThread-OFExtensions.h>
#import "UKDirectoryEnumerator.h"
#import "BDSKShellCommandFormatter.h"
#import <libkern/OSAtomic.h>

@interface BDSKTeXTask (Private) 

- (void)writeHelperFiles;

- (BOOL)writeTeXFile:(BOOL)ltb;

- (BOOL)writeBibTeXFile:(NSString *)bibStr;

- (BOOL)runTeXTasksForLaTeX;

- (BOOL)runTeXTasksForPDF;

- (BOOL)runTeXTaskForRTF;

- (BOOL)runPDFTeXTask;

- (BOOL)runBibTeXTask;

- (BOOL)runLaTeX2RTFTask;

- (BOOL)runTask:(NSString *)binPath withArguments:(NSArray *)arguments;

@end


@implementation BDSKTeXTask

- (id)init{
    NSString *tmpDirPath = [[NSApp delegate] temporaryFilePath:@"tmpbib" createDirectory:YES];
	self = [self initWithWorkingDirPath:tmpDirPath fileName:@"tmpbib"];
	return self;
}

- (id)initWithFileName:(NSString *)newFileName{
    NSString *tmpDirPath = [[NSApp delegate] temporaryFilePath:newFileName createDirectory:YES];
	self = [self initWithWorkingDirPath:tmpDirPath fileName:newFileName];
	return self;
}

- (id)initWithWorkingDirPath:(NSString *)dirPath fileName:(NSString *)newFileName{
	if (self = [super init]) {
		
		NSFileManager *fm = [NSFileManager defaultManager];
        
		workingDirPath = [dirPath retain];
		if (![fm objectExistsAtFileURL:[NSURL fileURLWithPath:workingDirPath]])
			[fm createDirectoryAtPathWithNoAttributes:workingDirPath];
		
		applicationSupportPath = [[fm currentApplicationSupportPathForCurrentUser] retain];
		texTemplatePath = [[applicationSupportPath stringByAppendingPathComponent:@"previewtemplate.tex"] retain];
		
		fileName = [newFileName retain];
		
		NSString *filePath = [workingDirPath stringByAppendingPathComponent:newFileName];
		texFilePath = [[filePath stringByAppendingPathExtension:@"tex"] retain];
		bibFilePath = [[filePath stringByAppendingPathExtension:@"bib"] retain];
        bblFilePath = [[filePath stringByAppendingPathExtension:@"bbl"] retain];
        pdfFilePath = [[filePath stringByAppendingPathExtension:@"pdf"] retain];
        rtfFilePath = [[filePath stringByAppendingPathExtension:@"rtf"] retain];
        logFilePath = [[filePath stringByAppendingPathExtension:@"log"] retain];
        blgFilePath = [[filePath stringByAppendingPathExtension:@"blg"] retain];
        
		binDirPath = nil; // set from where we run the tasks, since some programs (e.g. XeLaTeX) need a real path setting     
        
        // some users set BIBINPUTS in environment.plist, which will break our preview unless they added "." to the path (bug #1471984)
        const char *bibInputs = getenv("BIBINPUTS");
        if(bibInputs != NULL){
            NSString *value = [NSString stringWithCString:bibInputs];
            if([value rangeOfString:workingDirPath].length == 0){
                value = [NSString stringWithFormat:@"%@:%@", value, workingDirPath];
                setenv("BIBINPUTS", [value cString], 1);
            }
        }        
		
		[self writeHelperFiles];
		
		delegate = nil;
        currentTask = nil;
        memset(&flags, 0, sizeof(flags));

        OFSimpleLockInit(&processingLock);
        pthread_rwlock_init(&dataFileLock, NULL);
        
	}
	return self;
}

- (void)dealloc{
	[workingDirPath release];
    [applicationSupportPath release];
    [texTemplatePath release];
    [fileName release];
    [texFilePath release];
    [bibFilePath release];
    [bblFilePath release];
    [pdfFilePath release];
    [rtfFilePath release];
    [logFilePath release];
    [blgFilePath release];
    [taskShouldStartInvocation release];
    [taskFinishedInvocation release];
    OFSimpleLockFree(&processingLock);
    pthread_rwlock_destroy(&dataFileLock);
	[super dealloc];
}

- (NSString *)description{
    NSMutableString *temporaryDescription = [[NSMutableString alloc] initWithString:[super description]];
    [temporaryDescription appendFormat:@" {\nivars:\n\tdelegate = \"%@\"\n\tfile name = \"%@\"\n\ttemplate = \"%@\"\n\tTeX file = \"%@\"\n\tBibTeX file = \"%@\"\n\tTeX binary path = \"%@\"\n\tEncoding = \"%@\"\n\tBibTeX style = \"%@\"\n\nenvironment:\n\tSHELL = \"%s\"\n\tBIBINPUTS = \"%s\"\n\tBSTINPUTS = \"%s\"\n\tPATH = \"%s\" }", delegate, fileName, texTemplatePath, texFilePath, bibFilePath, binDirPath, [NSString localizedNameOfStringEncoding:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKTeXPreviewFileEncodingKey]], [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKBTStyleKey], getenv("SHELL"), getenv("BIBINPUTS"), getenv("BSTINPUTS"), getenv("PATH")];
    NSString *description = [temporaryDescription copy];
    [temporaryDescription release];
    return [description autorelease];
}

- (id)delegate {
    return delegate;
}

- (void)setDelegate:(id)newDelegate {
	delegate = newDelegate;
    
    SEL theSelector;
    
    // set invocations to nil before creating them, since we use that as a check before invoking
    theSelector = @selector(texTaskShouldStartRunning:);
    [taskShouldStartInvocation autorelease];
    taskShouldStartInvocation = nil;
    
    if ([delegate respondsToSelector:theSelector]) {
        taskShouldStartInvocation = [[NSInvocation invocationWithMethodSignature:[delegate methodSignatureForSelector:theSelector]] retain];
        [taskShouldStartInvocation setTarget:delegate];
        [taskShouldStartInvocation setSelector:theSelector];
        [taskShouldStartInvocation setArgument:&self atIndex:2];
    }
    
    [taskFinishedInvocation autorelease];
    taskFinishedInvocation = nil;
    theSelector = @selector(texTask:finishedWithResult:);

    if ([delegate respondsToSelector:theSelector]) {
        taskFinishedInvocation = [[NSInvocation invocationWithMethodSignature:[delegate methodSignatureForSelector:theSelector]] retain];
        [taskFinishedInvocation setTarget:delegate];
        [taskFinishedInvocation setSelector:theSelector];
        [taskFinishedInvocation setArgument:&self atIndex:2];
    }        
}

- (void)terminate{
    
    NSDate *referenceDate = [NSDate date];
    
    while ([self isProcessing] && currentTask){
        // if the task is still running after 2 seconds, kill it; we can't sleep here, because the main thread (usually this one) may be updating the UI for a task
        if([referenceDate timeIntervalSinceNow] > -2.0){
            NSLog(@"Terminating task %@", self);
            [currentTask terminate];
            break;
        }
    }    
}

#pragma mark TeX Tasks

- (BOOL)runWithBibTeXString:(NSString *)bibStr{
	return [self runWithBibTeXString:bibStr generatedTypes:BDSKGenerateRTF];
}

- (BOOL)runWithBibTeXString:(NSString *)bibStr generatedTypes:(int)flag{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL rv = YES;

    if(!OFSimpleLockTry(&processingLock)){
        NSLog(@"%@ couldn't get processing lock", self);
		[pool release];
        return NO;
    }

	if (nil != taskShouldStartInvocation) {
        BOOL shouldStart;
        [taskShouldStartInvocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:YES];
        [taskShouldStartInvocation getReturnValue:&shouldStart];
        
        if (NO == shouldStart) {
            OFSimpleUnlock(&processingLock);
            [pool release];
            return NO;
        }
	}

    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.hasLTB);
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.hasLaTeX);
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.hasPDFData);
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.hasRTFData);
    
	// make sure the PATH environment variable is set correctly
    NSString *pdfTeXBinPathDir = [[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKTeXBinPathKey] stringByDeletingLastPathComponent];

    if(![pdfTeXBinPathDir isEqualToString:binDirPath]){
        [binDirPath release];
        binDirPath = [pdfTeXBinPathDir retain];
        NSString *original_path = [NSString stringWithCString: getenv("PATH")];
        NSString *new_path = [NSString stringWithFormat: @"%@:%@", original_path, binDirPath];
        setenv("PATH", [new_path cString], 1);
    }
        
    rv = ([self writeTeXFile:(flag == BDSKGenerateLTB)] &&
          [self writeBibTeXFile:bibStr] &&
          [self runTeXTasksForLaTeX]);
    
    if(rv){
		if (flag == BDSKGenerateLTB)
            OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.hasLTB);
		else
            OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.hasLaTeX);
		
		if(flag > BDSKGenerateLaTeX){
            rv = [self runTeXTasksForPDF];
			
			if(rv){

                OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.hasPDFData);
				
				if(flag > BDSKGeneratePDF){
						rv = [self runTeXTaskForRTF];
					
					if(rv){
                        OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.hasRTFData);
					}
				}
			}
		}
	}
	
	if (nil != taskFinishedInvocation) {
        [taskFinishedInvocation setArgument:&rv atIndex:3];
        [taskFinishedInvocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
	}

	OFSimpleUnlock(&processingLock);
    
	[pool release];
    return rv;
}

#pragma mark Data accessors

- (NSString *)logFileString{
    NSString *logString = nil;
    NSString *blgString = nil;
    if(0 == pthread_rwlock_tryrdlock(&dataFileLock)) {
        // @@ unclear if log files will always be written with ASCII encoding
        // these will be nil if the file doesn't exist
        logString = [NSString stringWithContentsOfFile:logFilePath encoding:NSASCIIStringEncoding error:NULL];
        blgString = [NSString stringWithContentsOfFile:blgFilePath encoding:NSASCIIStringEncoding error:NULL];
        pthread_rwlock_unlock(&dataFileLock);
    }
    
    NSMutableString *toReturn = [NSMutableString string];
    [toReturn setString:@"---------- TeX log file ----------\n"];
    [toReturn appendFormat:@"File: \"%@\"\n", logFilePath];
    [toReturn appendFormat:@"%@\n\n", logString];
    [toReturn appendString:@"---------- BibTeX log file -------\n"];
    [toReturn appendFormat:@"File: \"%@\"\n", blgFilePath];
    [toReturn appendFormat:@"%@\n\n", blgString];
    [toReturn appendString:@"---------- BibDesk info ----------\n"];
    [toReturn appendString:[self description]];
    return toReturn;
}    

// the .bbl file contains either a LaTeX style bilbiography or an Amsrefs ltb style bibliography
// which one was generated depends on the generatedTypes argument, and can be seen from the hasLTB and hasLaTeX flags
- (NSString *)LTBString{
    NSString *string = nil;
    if([self hasLTB] && 0 == pthread_rwlock_tryrdlock(&dataFileLock)) {
        string = [NSString stringWithContentsOfFile:bblFilePath encoding:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKTeXPreviewFileEncodingKey] error:NULL];
        pthread_rwlock_unlock(&dataFileLock);
        unsigned start, end;
        start = [string rangeOfString:@"\\bib{"].location;
        end = [string rangeOfString:@"\\end{biblist}" options:NSBackwardsSearch].location;
        if (start != NSNotFound && end != NSNotFound)
            string = [string substringWithRange:NSMakeRange(start, end - start)];
    }
    return string;    
}

- (NSString *)LaTeXString{
    NSString *string = nil;
    if([self hasLaTeX] && 0 == pthread_rwlock_tryrdlock(&dataFileLock)) {
        string = [NSString stringWithContentsOfFile:bblFilePath encoding:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKTeXPreviewFileEncodingKey] error:NULL];
        pthread_rwlock_unlock(&dataFileLock);
        unsigned start, end;
        start = [string rangeOfString:@"\\bibitem"].location;
        end = [string rangeOfString:@"\\end{thebibliography}" options:NSBackwardsSearch].location;
        if (start != NSNotFound && end != NSNotFound)
            string = [string substringWithRange:NSMakeRange(start, end - start)];
    }
    return string;
}

- (NSData *)PDFData{
    NSData *data = nil;
    if ([self hasPDFData] && 0 == pthread_rwlock_tryrdlock(&dataFileLock)) {
        data = [NSData dataWithContentsOfFile:pdfFilePath];
        pthread_rwlock_unlock(&dataFileLock);
    }
    return data;
}

- (NSData *)RTFData{
    NSData *data = nil;
    if ([self hasRTFData] && 0 == pthread_rwlock_tryrdlock(&dataFileLock)) {
        data = [NSData dataWithContentsOfFile:rtfFilePath];
        pthread_rwlock_unlock(&dataFileLock);
    }
    return data;
}

- (NSString *)logFilePath{
    return logFilePath;
}

- (NSString *)LTBFilePath{
    return [self hasLTB] ? bblFilePath : nil;
}

- (NSString *)LaTeXFilePath{
    return [self hasLaTeX] ? bblFilePath : nil;
}

- (NSString *)PDFFilePath{
    return [self hasPDFData] ? pdfFilePath : nil;
}

- (NSString *)RTFFilePath{
    return [self hasRTFData] ? rtfFilePath : nil;
}

- (BOOL)hasLTB{
    return 1 == flags.hasLTB;
}

- (BOOL)hasLaTeX{
    return 1 == flags.hasLaTeX;
}

- (BOOL)hasPDFData{
    return 1 == flags.hasPDFData;
}

- (BOOL)hasRTFData{
    return 1 == flags.hasRTFData;
}

- (BOOL)isProcessing{
	// just see if we can get the lock, otherwise we are processing
    if(OFSimpleLockTry(&processingLock)){
		OFSimpleUnlock(&processingLock);
		return NO;
	}
	return YES;
}

@end


@implementation BDSKTeXTask (Private)

- (void)writeHelperFiles{
    UKDirectoryEnumerator *enumerator = [UKDirectoryEnumerator enumeratorWithPath:applicationSupportPath];
    [enumerator setDesiredInfo:kFSCatInfoNodeFlags];
    
	NSString *path = nil;
    NSString *pathExt = nil;
    
    NSURL *dstURL = [NSURL fileURLWithPath:workingDirPath];
    NSError *error;
		
	// copy all user .cfg and .sty files from application support
	while(path = [enumerator nextObjectFullPath]){
        pathExt = [path pathExtension];
		if([enumerator isDirectory] == NO &&
		   ([pathExt isEqual:@"cfg"] ||
		    [pathExt isEqual:@"sty"])){
			
			if(![[NSFileManager defaultManager] copyObjectAtURL:[NSURL fileURLWithPath:path] toDirectoryAtURL:dstURL error:&error])
                NSLog(@"unable to copy helper file %@ to %@; error %@", path, workingDirPath, [error localizedDescription]);
		}
	}
}

- (BOOL)writeTeXFile:(BOOL)ltb{
    
    NSMutableString *texFile = nil;
    NSString *style = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKBTStyleKey];
    NSStringEncoding encoding = [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKTeXPreviewFileEncodingKey];
    NSError *error = nil;
    BOOL didWrite = NO;

	if (ltb) {
		texFile = [[NSMutableString alloc] initWithString:@"\\documentclass{article}\n\\usepackage{amsrefs}\n\\begin{document}\n\\nocite{*}\n\\bibliography{<<File>>}\n\\end{document}\n"];
	} else {
		texFile = [[NSMutableString alloc] initWithContentsOfFile:texTemplatePath encoding:encoding error:&error];
    }
    
    if (nil != texFile) {
	
        [texFile replaceOccurrencesOfString:@"<<File>>" withString:fileName options:NSCaseInsensitiveSearch range:NSMakeRange(0,[texFile length])];
        [texFile replaceOccurrencesOfString:@"<<Style>>" withString:style options:NSCaseInsensitiveSearch range:NSMakeRange(0,[texFile length])];

        // overwrites the old tmpbib.tex file, replacing the previous bibliographystyle
        didWrite = [[texFile dataUsingEncoding:encoding] writeToFile:texFilePath atomically:YES];
        if(NO == didWrite)
            NSLog(@"error writing TeX file with encoding %@ for task %@", [NSString localizedNameOfStringEncoding:encoding], self);
	
        [texFile release];
    } else {
        NSLog(@"Unable to read preview template using encoding %@ for task %@", [NSString localizedNameOfStringEncoding:encoding], self);
        NSLog(@"Foundation reported error %@", error);
    }
    
	return didWrite;
}

- (BOOL)writeBibTeXFile:(NSString *)bibStr{
    
    NSStringEncoding encoding = [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKTeXPreviewFileEncodingKey];
    NSError *error;
    
    // this should likely be the same encoding as our other files; presumably it's here because the user can have a default @preamble or something that's relevant?
    NSMutableString *bibTemplate = [[NSMutableString alloc] initWithContentsOfFile:
                                    [[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKOutputTemplateFileKey] stringByStandardizingPath] encoding:encoding error:&error];
    
    if (nil == bibTemplate) {
        NSLog(@"unable to read file %@ in task %@", [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKOutputTemplateFileKey], self);
        NSLog(@"Foundation reported error %@", error);
        bibTemplate = [[NSMutableString alloc] init];
    }
    
	[bibTemplate appendString:@"\n"];
    [bibTemplate appendString:bibStr];
    [bibTemplate appendString:@"\n"];
        
    BOOL didWrite;
    didWrite = [bibTemplate writeToFile:bibFilePath atomically:NO encoding:encoding error:&error];
    if(NO == didWrite) {
        NSLog(@"error writing BibTeX file with encoding %@ for task %@", [NSString localizedNameOfStringEncoding:encoding], self);
        NSLog(@"Foundation reported error %@", error);
    }
	
	[bibTemplate release];
	return didWrite;
}

// caller must have acquired wrlock on dataFileLock
- (void)removeOutputFilesFromPreviousRun{
    // use FSDeleteObject for thread safety
    const FSRef fileRef;
    NSArray *filesToRemove = [NSArray arrayWithObjects:pdfFilePath, rtfFilePath, bblFilePath, logFilePath, nil];
    NSEnumerator *e = [filesToRemove objectEnumerator];
    NSString *path;
    CFAllocatorRef alloc = CFRetain(CFAllocatorGetDefault());
    CFURLRef fileURL;
    
    while(path = [e nextObject]){
        fileURL = CFURLCreateWithFileSystemPath(alloc, (CFStringRef)path, kCFURLPOSIXPathStyle, FALSE);
        if(fileURL){
            if(CFURLGetFSRef(fileURL, (struct FSRef *)&fileRef))
                FSDeleteObject(&fileRef);
            CFRelease(fileURL);
        }
    }
    CFRelease(alloc);
}

- (BOOL)runTeXTasksForLaTeX{
    volatile int lockStatus;
    volatile BOOL rv;
    rv = YES;
    
    lockStatus = pthread_rwlock_wrlock(&dataFileLock);
    if(lockStatus){
        NSLog(@"error %d occurred locking in %@", lockStatus, self);
        return NO;
    }

    // nuke the data files, otherwise we always return yes for hasData calls, even if the TeX run failed
    [self removeOutputFilesFromPreviousRun];
        
    if(![self runPDFTeXTask] ||
       ![self runBibTeXTask]){
        rv = NO;
	}
    
    lockStatus = pthread_rwlock_unlock(&dataFileLock);
    if(lockStatus){
        NSLog(@"error %d occurred locking in %@", lockStatus, self);  
        rv = NO;
    }
    
	return rv;
}

- (BOOL)runTeXTasksForPDF{
    volatile int lockStatus;
    volatile BOOL rv;
    rv = YES;
    
    lockStatus = pthread_rwlock_wrlock(&dataFileLock);
    if(lockStatus){
        NSLog(@"error %d occurred locking in %@", lockStatus, self);
        return NO;
    }
        
    if(![self runPDFTeXTask] ||
       ![self runPDFTeXTask]){
        rv = NO;
	}
    
    lockStatus = pthread_rwlock_unlock(&dataFileLock);
    if(lockStatus){
        NSLog(@"error %d occurred locking in %@", lockStatus, self);  
        rv = NO;
    }
    
	return rv;
}

- (BOOL)runTeXTaskForRTF{
    volatile int lockStatus;
    volatile BOOL rv;
    rv = YES;
    
    lockStatus = pthread_rwlock_wrlock(&dataFileLock);
    if(lockStatus){
        NSLog(@"error %d occurred locking in %@", lockStatus, self);
        return NO;
    }
        
    if(![self runLaTeX2RTFTask]){
        rv = NO;
    }
    
    lockStatus = pthread_rwlock_unlock(&dataFileLock);
    if(lockStatus){
        NSLog(@"error %d occurred locking in %@", lockStatus, self);  
        rv = NO;
    }
    
	return rv;
}

- (BOOL)runPDFTeXTask{
    NSString *command = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKTeXBinPathKey];

    NSArray *argArray = [BDSKShellCommandFormatter argumentsFromCommand:command];
    NSString *pdftexbinpath = [BDSKShellCommandFormatter pathByRemovingArgumentsFromCommand:command];
    NSMutableArray *args = [NSMutableArray arrayWithObject:@"-interaction=batchmode"];
    [args addObjectsFromArray:argArray];
    [args addObject:fileName];
    
    // This task runs latex on our tex file 
    return [self runTask:pdftexbinpath withArguments:args];
}

- (BOOL)runBibTeXTask{
    NSString *command = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKBibTeXBinPathKey];
	
    NSArray *argArray = [BDSKShellCommandFormatter argumentsFromCommand:command];
    NSString *bibtexbinpath = [BDSKShellCommandFormatter pathByRemovingArgumentsFromCommand:command];
    NSMutableArray *args = [NSMutableArray array];
    [args addObjectsFromArray:argArray];
    [args addObject:fileName];
    
    // This task runs bibtex on our bib file 
    return [self runTask:bibtexbinpath withArguments:args];
}

- (BOOL)runLaTeX2RTFTask{
    NSString *latex2rtfpath = [[NSBundle mainBundle] pathForResource:@"latex2rtf" ofType:nil];
    
    // This task runs latex2rtf on our tex file to generate tmpbib.rtf
    // the arguments: it needs -P "path" which is the path to the cfg files in the app wrapper
    return [self runTask:latex2rtfpath withArguments:[NSArray arrayWithObjects:@"-P", [[NSBundle mainBundle] resourcePath], fileName, nil]];
}

- (BOOL)runTask:(NSString *)binPath withArguments:(NSArray *)arguments{
    currentTask = [[NSTask alloc] init];
    [currentTask setCurrentDirectoryPath:workingDirPath];
    [currentTask setLaunchPath:binPath];
    [currentTask setArguments:arguments];
    [currentTask setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [currentTask setStandardError:[NSFileHandle fileHandleWithNullDevice]];
        
    BOOL success = YES;
    
    @try {
        [currentTask launch];
    }
    @catch(id exception) {
        if([currentTask isRunning])
            [currentTask terminate];
        NSLog(@"%@ %@ failed", [currentTask description], [currentTask launchPath]);
        success = NO;
    }
    
    NSDate *hardLimit = [[NSDate alloc] initWithTimeIntervalSinceNow:10];
    BOOL isRunning = [currentTask isRunning];
    
    while (isRunning){
        NSDate *limit = [[NSDate alloc] initWithTimeIntervalSinceNow:1]; // runs about 2x per second
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:limit];
        [limit release];
        if([(NSDate *)[NSDate date] compare:hardLimit] == NSOrderedDescending){
            // no single task should take this long, so we'll bail out
            // this appears to happen occasionally if you're changing selection continuously
            [currentTask terminate];
            success = NO;
            break;
        }
        isRunning = [currentTask isRunning];
    }
    [hardLimit release];
    
    if (0 != [currentTask terminationStatus])
        success = NO;
    
    [currentTask release];
    currentTask = nil;

    return success;
}

@end
