//
//  BDSKTeXTask.h
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

#import <Cocoa/Cocoa.h>
#import <OmniFoundation/OFWeakRetainConcreteImplementation.h>

enum {
	BDSKGenerateLTB = 0,
	BDSKGenerateLaTeX = 1,
	BDSKGeneratePDF = 2,
	BDSKGenerateRTF = 3,
};

typedef struct _BDSKTeXTaskFlags {
    volatile int32_t hasLTB __attribute__ ((aligned (4)));
    volatile int32_t hasLaTeX __attribute__ ((aligned (4)));
    volatile int32_t hasPDFData __attribute__ ((aligned (4)));
    volatile int32_t hasRTFData __attribute__ ((aligned (4)));
} BDSKTeXTaskFlags;

@interface BDSKTeXTask : NSObject {
	NSString *workingDirPath;
    NSString *applicationSupportPath;
	
    NSString *texTemplatePath;
	NSString *fileName;
    NSString *texFilePath;
    NSString *bibFilePath;
    NSString *bblFilePath;
    NSString *pdfFilePath;
    NSString *rtfFilePath;
    NSString *logFilePath;
    NSString *binDirPath;
	
	id delegate;
    NSInvocation *taskShouldStartInvocation;
    NSInvocation *taskFinishedInvocation;
    NSTask *currentTask;
	
    BDSKTeXTaskFlags flags;

    OFSimpleLockType processingLock;    
    pthread_rwlock_t dataFileLock;
}

- (id)init;
- (id)initWithFileName:(NSString *)fileName;
- (id)initWithWorkingDirPath:(NSString *)dirPath fileName:(NSString *)fileName;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

// the next few methods are thread-unsafe

- (BOOL)runWithBibTeXString:(NSString *)bibStr;
- (BOOL)runWithBibTeXString:(NSString *)bibStr generatedTypes:(int)flag;

- (void)terminate;

// these methods are thread-safe

- (NSString *)logFileString;
- (NSString *)LTBString;
- (NSString *)LaTeXString;
- (NSData *)PDFData;
- (NSData *)RTFData;

- (NSString *)logFilePath;
- (NSString *)LTBFilePath;
- (NSString *)LaTeXFilePath;
- (NSString *)PDFFilePath;
- (NSString *)RTFFilePath;

- (BOOL)hasLTB;
- (BOOL)hasLaTeX;
- (BOOL)hasPDFData;
- (BOOL)hasRTFData;

- (BOOL)isProcessing;

@end

@interface NSObject (BDSKTeXTaskDelegate)
- (BOOL)texTaskShouldStartRunning:(BDSKTeXTask *)texTask;
- (void)texTask:(BDSKTeXTask *)texTask finishedWithResult:(BOOL)success;
@end
