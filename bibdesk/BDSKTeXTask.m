//
//  BDSKTeXTask.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 6/8/05.
//
/*
 This software is Copyright (c) 2005,2006
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
		hasLTB = NO;
		hasLaTeX = NO;
		hasPDFData = NO;
		hasRTFData = NO;
        OFSimpleLockInit(&processingLock);
        OFSimpleLockInit(&hasDataLock);
        OFSimpleLockInit(&currentTaskLock);
        pthread_rwlock_init(&dataFileLock, NULL);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
        
	}
	return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    OFSimpleLockFree(&processingLock);
    OFSimpleLockFree(&hasDataLock);
    OFSimpleLockFree(&currentTaskLock);
    pthread_rwlock_destroy(&dataFileLock);
	[super dealloc];
}

- (NSString *)description{
    NSMutableString *temporaryDescription = [[NSMutableString alloc] initWithString:[super description]];
    [temporaryDescription appendFormat:@" {\nivars:\n\tdelegate = \"%@\"\n\tfile name = \"%@\"\n\ttemplate = \"%@\"\n\tTeX file = \"%@\"\n\tBibTeX file = \"%@\"\n\tTeX binary path = \"%@\"\n\nenvironment:\n\tSHELL = \"%s\"\n\tBIBINPUTS = \"%s\"\n\tBSTINPUTS = \"%s\"\n\tPATH = \"%s\" }", delegate, fileName, texTemplatePath, texFilePath, bibFilePath, binDirPath, getenv("SHELL"), getenv("BIBINPUTS"), getenv("BSTINPUTS"), getenv("PATH")];
    NSString *description = [temporaryDescription copy];
    [temporaryDescription release];
    return [description autorelease];
}

- (id)delegate {
    return delegate;
}

- (void)setDelegate:(id)newDelegate {
	delegate = newDelegate;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification{
    // this is not effective if the user does a copy command that calls a TeX task, then quits the app before pasting, since the pasteboard asks for the data after NSApplicationWillTerminate
    [self terminate];
    [[NSFileManager defaultManager] deleteObjectAtFileURL:[NSURL fileURLWithPath:workingDirPath] error:NULL];
}

- (void)terminate{
    
    NSDate *referenceDate = [NSDate date];
    
    while ([self isProcessing] && currentTask){
        // if the task is still running after 2 seconds, kill it; we can't sleep here, because the main thread (usually this one) may be updating the UI for a task
        if([referenceDate timeIntervalSinceNow] > -2 && OFSimpleLockTry(&currentTaskLock)){
            [currentTask terminate];
            currentTask = nil;
            OFSimpleUnlock(&currentTaskLock);
            break;
        } else if([referenceDate timeIntervalSinceNow] > -2.1){ // just in case this ever happens
            NSLog(@"%@ failed to lock for task %@", self, currentTask);
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
    volatile BOOL rv = YES;

    if(!OFSimpleLockTry(&processingLock)){
        NSLog(@"%@ couldn't get processing lock", self);
		[pool release];
        return NO;
    }

	if ([[self delegate] respondsToSelector:@selector(texTaskShouldStartRunning:)] &&
		![[self delegate] texTaskShouldStartRunning:self]){
		OFSimpleUnlock(&processingLock);
		[pool release];
		return NO;
	}

    OFSimpleLock(&hasDataLock);
	hasLTB = NO;
	hasLaTeX = NO;
	hasPDFData = NO;
	hasRTFData = NO;
	OFSimpleUnlock(&hasDataLock);
    
	// make sure the PATH environment variable is set correctly
    NSString *pdfTeXBinPathDir = [[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKTeXBinPathKey] stringByDeletingLastPathComponent];

    if(![pdfTeXBinPathDir isEqualToString:binDirPath]){
        [binDirPath release];
        binDirPath = [pdfTeXBinPathDir retain];
        NSString *original_path = [NSString stringWithCString: getenv("PATH")];
        NSString *new_path = [NSString stringWithFormat: @"%@:%@", original_path, binDirPath];
        setenv("PATH", [new_path cString], 1);
    }
        
    NS_DURING
        rv = ([self writeTeXFile:(flag == BDSKGenerateLTB)] &&
              [self writeBibTeXFile:bibStr] &&
              [self runTeXTasksForLaTeX]);
    NS_HANDLER
        NSLog(@"Failed to perform TeX tasks for LaTeX: %@", [localException reason]);
        rv = NO;
    NS_ENDHANDLER
    
    if(rv){
		OFSimpleLock(&hasDataLock);
		if (flag == BDSKGenerateLTB)
			hasLTB = YES;
		else
			hasLaTeX = YES;
		OFSimpleUnlock(&hasDataLock);
		
		if(flag > BDSKGenerateLaTeX){
			NS_DURING
				rv = [self runTeXTasksForPDF];
			NS_HANDLER
				NSLog(@"Failed to perform TeX task for PDF: %@", [localException reason]);
				rv = NO;
			NS_ENDHANDLER
			
			if(rv){
				OFSimpleLock(&hasDataLock);
				hasPDFData = YES;
				OFSimpleUnlock(&hasDataLock);
				
				if(flag > BDSKGeneratePDF){
					NS_DURING
						rv = [self runTeXTaskForRTF];
					NS_HANDLER
						NSLog(@"Failed to perform TeX task for RTF: %@", [localException reason]);
						rv = NO;
					NS_ENDHANDLER
					
					if(rv){
						OFSimpleLock(&hasDataLock);
						hasRTFData = YES;
						OFSimpleUnlock(&hasDataLock);
					}
				}
			}
		}
	}
	
	if ([[self delegate] respondsToSelector:@selector(texTask:finishedWithResult:)]){
		[[self delegate] texTask:self finishedWithResult:rv];
	}

	OFSimpleUnlock(&processingLock);
    
	[pool release];
    return rv;
}

#pragma mark Data accessors

- (NSString *)logFileString{
    
    if(pthread_rwlock_tryrdlock(&dataFileLock))
        return nil;
    NSData *data = [[NSData alloc] initWithContentsOfFile:logFilePath];
    pthread_rwlock_unlock(&dataFileLock);

    // @@ log files written using defaultCStringEncoding?  likely always ascii anyway...
    NSString *string = [[NSString alloc] initWithData:data encoding:[NSString defaultCStringEncoding]];
    [data release];
    
    return [string autorelease];
}

// the .bbl file contains either a LaTeX style bilbiography or an Amsrefs ltb style bibliography
// which one was generated depends on the generatedTypes argument, and can be seen from the hasLTB and hasLaTeX flags
- (NSString *)LTBString{
	if (![self hasLTB])
		return nil;
    if(pthread_rwlock_tryrdlock(&dataFileLock))
        return nil;
    NSData *data = [[NSData alloc] initWithContentsOfFile:bblFilePath];
    NSString *string = [[[NSString alloc] initWithData:data encoding:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKTeXPreviewFileEncodingKey]] autorelease];
    [data release];
    pthread_rwlock_unlock(&dataFileLock);
    return string;
}

- (NSString *)LaTeXString{
	if (![self hasLaTeX])
		return nil;
    if(pthread_rwlock_tryrdlock(&dataFileLock))
        return nil;
    NSData *data = [[NSData alloc] initWithContentsOfFile:bblFilePath];
    NSString *string = [[[NSString alloc] initWithData:data encoding:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKTeXPreviewFileEncodingKey]] autorelease];
    [data release];
    pthread_rwlock_unlock(&dataFileLock);
    return string;
}

- (NSData *)PDFData{
	if (![self hasPDFData])
		return nil;
    if(pthread_rwlock_tryrdlock(&dataFileLock))
        return nil;
    NSData *data = [NSData dataWithContentsOfFile:pdfFilePath];
    pthread_rwlock_unlock(&dataFileLock);
    return data;
}

- (NSData *)RTFData{
	if (![self hasRTFData])
		return nil;
    if(pthread_rwlock_tryrdlock(&dataFileLock))
        return nil;
    NSData *data = [NSData dataWithContentsOfFile:rtfFilePath];
    pthread_rwlock_unlock(&dataFileLock);
    return data;
}

- (BOOL)hasLTB{
    volatile BOOL status = OFSimpleLockTry(&hasDataLock);
    if(!status)
        return NO;
    status = hasLTB;
    OFSimpleUnlock(&hasDataLock);
    return status;
}

- (BOOL)hasLaTeX{
    volatile BOOL status = OFSimpleLockTry(&hasDataLock);
    if(!status)
        return NO;
    status = hasLaTeX;
    OFSimpleUnlock(&hasDataLock);
    return status;
}

- (BOOL)hasPDFData{
    volatile BOOL status = OFSimpleLockTry(&hasDataLock);
    if(!status)
        return NO;
    status = hasPDFData;
    OFSimpleUnlock(&hasDataLock);
    return status;
}

- (BOOL)hasRTFData{
    volatile BOOL status = OFSimpleLockTry(&hasDataLock);
    if(!status)
        return NO;
    status = hasRTFData;
    OFSimpleUnlock(&hasDataLock);
    return status;
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
	
	if (ltb)
		texFile = [[NSMutableString alloc] initWithString:@"\\documentclass{article}\n\\usepackage{amsrefs}\n\\begin{document}\n\\nocite{*}\n\\bibliography{<<File>>}\n\\end{document}\n"];
	else
		texFile = [[NSMutableString alloc] initWithContentsOfFile:texTemplatePath];
	
	[texFile replaceOccurrencesOfString:@"<<File>>" withString:fileName options:NSCaseInsensitiveSearch range:NSMakeRange(0,[texFile length])];
	[texFile replaceOccurrencesOfString:@"<<Style>>" withString:style options:NSCaseInsensitiveSearch range:NSMakeRange(0,[texFile length])];

    // overwrites the old tmpbib.tex file, replacing the previous bibliographystyle
    NSStringEncoding encoding = [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKTeXPreviewFileEncodingKey];
    BOOL didWrite;
    didWrite = [[texFile dataUsingEncoding:encoding] writeToFile:texFilePath atomically:YES];
    if(NO == didWrite)
        NSLog(@"error writing TeX file with encoding %@ for task %@", [NSString localizedNameOfStringEncoding:encoding], self);
	
	[texFile release];
	return didWrite;
}

- (BOOL)writeBibTeXFile:(NSString *)bibStr{
    NSMutableString *bibTemplate = [[NSMutableString alloc] initWithContentsOfFile:
        [[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKOutputTemplateFileKey] stringByExpandingTildeInPath]];
    
	[bibTemplate appendString:@"\n"];
    [bibTemplate appendString:bibStr];
    NSStringEncoding encoding = [[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKTeXPreviewFileEncodingKey];
    
    BOOL didWrite;
    didWrite = [[bibTemplate dataUsingEncoding:encoding] writeToFile:bibFilePath atomically:YES];
    if(NO == didWrite)
        NSLog(@"error writing BibTeX file with encoding %@ for task %@", [NSString localizedNameOfStringEncoding:encoding], self);
	
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

    NSString *argString = [BDSKShellCommandFormatter argumentsFromCommand:command];
    NSString *pdftexbinpath = [BDSKShellCommandFormatter pathByRemovingArgumentsFromCommand:command];
    NSMutableArray *args = [NSMutableArray arrayWithObject:@"-interaction=batchmode"];
    if (argString)
        [args addObject:argString];
    [args addObject:fileName];
    
    // This task runs latex on our tex file 
    return [self runTask:pdftexbinpath withArguments:args];
}

- (BOOL)runBibTeXTask{
    NSString *command = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKBibTeXBinPathKey];
	
    NSString *argString = [BDSKShellCommandFormatter argumentsFromCommand:command];
    NSString *bibtexbinpath = [BDSKShellCommandFormatter pathByRemovingArgumentsFromCommand:command];
    NSMutableArray *args = [NSMutableArray array];
    if (argString)
        [args addObject:argString];
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
    NSTask *task = [[NSTask alloc] init];
    [task setCurrentDirectoryPath:workingDirPath];
    [task setLaunchPath:binPath];
    [task setArguments:arguments];
    [task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];
    
    OFSimpleLock(&currentTaskLock);
    currentTask = task;
    OFSimpleUnlock(&currentTaskLock);
    
    volatile BOOL success = YES;
    
    NS_DURING
        [task launch];
    NS_HANDLER
        if([task isRunning])
            [task terminate];
        NSLog(@"%@ %@ failed", [task description], [task launchPath]);
        success = NO;
    NS_ENDHANDLER
    
    NSDate *hardLimit = [[NSDate alloc] initWithTimeIntervalSinceNow:10];
    while ([task isRunning]){
        NSDate *limit = [[NSDate alloc] initWithTimeIntervalSinceNow:1]; // runs about 2x per second
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:limit];
        [limit release];
        if([(NSDate *)[NSDate date] compare:hardLimit] == NSOrderedDescending){
            // no single task should take this long, so we'll bail out
            // this appears to happen occasionally if you're changing selection continuously
            [task terminate];
            success = NO;
            break;
        }
    }
    [hardLimit release];
    
    OFSimpleLock(&currentTaskLock);
    currentTask = nil;
    OFSimpleUnlock(&currentTaskLock);        

    [task release];
    return success;
}

@end
