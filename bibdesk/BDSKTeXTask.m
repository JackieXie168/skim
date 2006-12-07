//
//  BDSKTeXTask.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 6/8/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//
/*
 This software is Copyright (c) 2005
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

@interface BDSKTeXTask (Private) 

- (void)writeHelperFiles;

- (BOOL)writeTeXFile;

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
		if (![fm fileExistsAtPath:workingDirPath])
			[fm createDirectoryAtPath:workingDirPath attributes:nil];
		
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
		
		[self writeHelperFiles];
		
		delegate = nil;
        currentTask = nil;
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
	[[NSFileManager defaultManager] removeFileAtPath:workingDirPath handler:NULL];
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

- (id)delegate {
    return delegate;
}

- (void)setDelegate:(id)newDelegate {
	delegate = newDelegate;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification{
    // this is not effective if the user does a copy command that calls a TeX task, then quits the app before pasting, since the pasteboard asks for the data after NSApplicationWillTerminate
    [self terminate];
}

- (void)terminate{
     
    if(![self isProcessing])
        return;
    
    NSDate *referenceDate = [NSDate date];
    
    while ([self isProcessing] && currentTask){
        // if the task is still running after 2 seconds, kill it; we can't sleep here, because the main thread (usually this one) may be updating the UI for a task
        if([referenceDate timeIntervalSinceNow] > -2 && OFSimpleLockTry(&currentTaskLock)){
            [currentTask terminate];
            currentTask = nil;
            OFSimpleUnlock(&currentTaskLock);
            break;
        } else if([referenceDate timeIntervalSinceNow] > -2.1){ // just in case this ever happens
            NSLog(@"failed to lock for task %@", currentTask);
            [currentTask terminate];
            break;
        }
    }    
}

#pragma mark TeX Tasks

- (BOOL)runWithBibTeXString:(NSString *)bibStr{
	[self runWithBibTeXString:bibStr generatedTypes:BDSKGenerateRTF];
}

- (BOOL)runWithBibTeXString:(NSString *)bibStr generatedTypes:(int)flag{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    volatile BOOL rv = YES;

    if(!OFSimpleLockTry(&processingLock)){
        NSLog(@"couldn't get processing lock");
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
        rv = ([self writeTeXFile] &&
              [self writeBibTeXFile:bibStr] &&
              [self runTeXTasksForLaTeX]);
    NS_HANDLER
        NSLog(@"Failed to perform TeX tasks for LaTeX: %@", [localException reason]);
        rv = NO;
    NS_ENDHANDLER
    
    if(rv){
		OFSimpleLock(&hasDataLock);
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

    NSString *string = [[NSString alloc] initWithData:data encoding:[NSString defaultCStringEncoding]];
    [data release];
    
    return [string autorelease];
}

- (NSString *)LaTeXString{
	if (![self hasLaTeX])
		return nil;
    if(pthread_rwlock_tryrdlock(&dataFileLock))
        return nil;
    NSString *string = [NSString stringWithContentsOfFile:bblFilePath];
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
	NSFileManager *fm = [NSFileManager defaultManager];
	NSEnumerator *fileEnum = nil;
	NSString *file = nil;
	NSString *path = nil;
    NSString *pathExt = nil;
    
	BOOL isDir;
		
	// copy all user .cfg and .sty files from application support
	fileEnum = [[fm directoryContentsAtPath:applicationSupportPath] objectEnumerator];
	while(file = [fileEnum nextObject]){
		path = [applicationSupportPath stringByAppendingPathComponent:file];
        pathExt = [file pathExtension];
		if([fm fileExistsAtPath:path isDirectory:&isDir] && !isDir &&
		   ([pathExt isEqualToString:@"cfg"] ||
		    [pathExt isEqualToString:@"sty"])){
			
			if(![fm copyPath:path toPath:[workingDirPath stringByAppendingPathComponent:file] handler:nil])
                NSLog(@"unable to copy helper file %@ to %@", file, workingDirPath);
		}
	}
}

- (BOOL)writeTeXFile{
    NSMutableString *texFile = [[NSMutableString alloc] initWithContentsOfFile:texTemplatePath];
    NSString *style = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKBTStyleKey];
	
	[texFile replaceOccurrencesOfString:@"<<File>>" withString:fileName options:NSCaseInsensitiveSearch range:NSMakeRange(0,[texFile length])];
	[texFile replaceOccurrencesOfString:@"<<Style>>" withString:style options:NSCaseInsensitiveSearch range:NSMakeRange(0,[texFile length])];

    // overwrites the old tmpbib.tex file, replacing the previous bibliographystyle
    if(![[texFile dataUsingEncoding:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKTeXPreviewFileEncodingKey]] writeToFile:texFilePath atomically:YES]){
        NSLog(@"error replacing texfile");
		[texFile release];
		return NO;
	}
	
	[texFile release];
	return YES;
}

- (BOOL)writeBibTeXFile:(NSString *)bibStr{
    NSMutableString *bibTemplate = [[NSMutableString alloc] initWithContentsOfFile:
        [[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKOutputTemplateFileKey] stringByExpandingTildeInPath]];
    
	[bibTemplate appendString:@"\n"];
    [bibTemplate appendString:bibStr];
    if(![[bibTemplate dataUsingEncoding:[[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKTeXPreviewFileEncodingKey]] writeToFile:bibFilePath atomically:YES]){
        NSLog(@"Error replacing bibfile.");
		[bibTemplate release];
		return NO;
	}
	
	[bibTemplate release];
	return YES;
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
    NSString *pdftexbinpath = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKTeXBinPathKey];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:pdftexbinpath]){
        NSLog(@"runPDFTeXTask cannot continue: %@ not found", pdftexbinpath);
        return NO;    
    }
    
    // This task runs the latex on our tex file 
    return [self runTask:pdftexbinpath withArguments:[NSArray arrayWithObjects:@"-interaction=batchmode", fileName, nil ]];
}

- (BOOL)runBibTeXTask{
    NSString *bibtexbinpath = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKBibTeXBinPathKey];

    if(![[NSFileManager defaultManager] fileExistsAtPath:bibtexbinpath]){        
        NSLog(@"runBibTeXTask cannot continue: %@ not found", bibtexbinpath);
        return NO;     
    }    
	
    // This task runs bibtex on our bib file 
    return [self runTask:bibtexbinpath withArguments:[NSArray arrayWithObject:fileName]];
}

- (BOOL)runLaTeX2RTFTask{
    NSString *latex2rtfpath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"latex2rtf"];
    
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
