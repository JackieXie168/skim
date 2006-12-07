//
//  BDSKShellTask.m
//  BibDesk
//
//  Created by Michael McCracken on Sat Dec 14 2002.
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

#import "BDSKShellTask.h"
#import "BibAppController.h"

volatile int caughtSignal = 0;

@implementation BDSKShellTask

+ (BDSKShellTask *)shellTask{
    return [[[BDSKShellTask alloc] init] autorelease];
}

//
// The following three methods are borrowed from Mike Ferris' TextExtras.
// For the real versions of them, check out http://www.lorax.com/FreeStuff/TextExtras.html
// - mmcc

// was runWithInputString in TextExtras' TEPipeCommand class.
- (NSString *)runShellCommand:(NSString *)cmd withInputString:(NSString *)input{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *shellPath = @"/bin/sh";
    NSString *shellScriptPath = [[NSApp delegate] temporaryFilePath:@"shellscript" createDirectory:NO];
    NSString *script;
    NSData *scriptData;
    NSMutableDictionary *currentAttributes;
    unsigned long currentMode;
    NSString *output;

    // ---------- Check the shell and create the script ----------
    if (![fm isExecutableFileAtPath:shellPath]) {
        NSLog(@"Filter Pipes: Shell path for Pipe panel does not exist or is not executable. (%@)", shellPath);
        return nil;
    }
    if (!cmd){
        return nil;
    }
    script = [NSString stringWithFormat:@"#!%@\n\n%@\n", shellPath, cmd];
    // Use UTF8... and write out the shell script and make it exectuable
    scriptData = [script dataUsingEncoding:NSUTF8StringEncoding];
    if (![scriptData writeToFile:shellScriptPath atomically:YES]) {
        NSLog(@"Filter Pipes: Failed to write temporary script file. (%@)", shellScriptPath);
        return nil;
    }
    currentAttributes = [[[fm fileAttributesAtPath:shellScriptPath traverseLink:NO] mutableCopyWithZone:[self zone]] autorelease];
    if (!currentAttributes) {
        NSLog(@"Filter Pipes: Failed to get attributes of temporary script file. (%@)", shellScriptPath);
        return nil;
    }
    currentMode = [currentAttributes filePosixPermissions];
    currentMode |= S_IRWXU;
    [currentAttributes setObject:[NSNumber numberWithUnsignedLong:currentMode] forKey:NSFilePosixPermissions];
    if (![fm changeFileAttributes:currentAttributes atPath:shellScriptPath]) {
        NSLog(@"Filter Pipes: Failed to get attributes of temporary script file. (%@)", shellScriptPath);
        return nil;
    }

    // ---------- Execute the script ----------

    // MF:!!! The current working dir isn't too appropriate
    output = [self executeBinary:shellScriptPath inDirectory:[shellScriptPath stringByDeletingLastPathComponent] withArguments:nil environment:nil inputString:input];

    // ---------- Remove the script file ----------
    if (![fm removeFileAtPath:shellScriptPath handler:nil]) {
        NSLog(@"Filter Pipes: Failed to delete temporary script file. (%@)", shellScriptPath);
    }

    return output;
}

// This method and the little notification method following implement synchronously running a task with input piped in from a string and output piped back out and returned as a string.   They require only a stdoutData instance variable to function.
- (NSString *)executeBinary:(NSString *)executablePath inDirectory:(NSString *)currentDirPath withArguments:(NSArray *)args environment:(NSDictionary *)env inputString:(NSString *)input {
    NSTask *task;
    NSPipe *inputPipe;
    NSPipe *outputPipe;
    NSFileHandle *inputFileHandle;
    NSFileHandle *outputFileHandle;
    NSString *output = nil;

    task = [[NSTask allocWithZone:[self zone]] init];    
    [task setLaunchPath:executablePath];
    if (currentDirPath) {
        [task setCurrentDirectoryPath:currentDirPath];
    }
    if (args) {
        [task setArguments:args];
    }
    if (env) {
        [task setEnvironment:env];
    }

    inputPipe = [NSPipe pipe];
    inputFileHandle = [inputPipe fileHandleForWriting];
    [task setStandardInput:inputPipe];
    outputPipe = [NSPipe pipe];
    outputFileHandle = [outputPipe fileHandleForReading];
    [task setStandardOutput:outputPipe];
    
    // ignore SIGPIPE, as it causes a crash (seems to happen if the binaries don't exist and you try writing to the pipe)
    signal(SIGPIPE, SIG_IGN);

    [task launch];

    NS_DURING
    if ([task isRunning]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stdoutNowAvailable:) name:NSFileHandleReadToEndOfFileCompletionNotification object:outputFileHandle];
        [outputFileHandle readToEndOfFileInBackgroundAndNotifyForModes:[NSArray arrayWithObject:@"BDSKSpecialPipeServiceRunLoopMode"]];

        if (input) {
            [inputFileHandle writeData:[input dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        }
        [inputFileHandle closeFile];

        // Now loop the runloop in the special mode until we've processed the notification.
        stdoutData = nil;
        while (stdoutData == nil) {
            // Run the run loop, briefly, until we get the notification...
            [[NSRunLoop currentRunLoop] runMode:@"BDSKSpecialPipeServiceRunLoopMode" beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        }
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:outputFileHandle];

        [task waitUntilExit];

        output = [[NSString allocWithZone:[self zone]] initWithData:stdoutData encoding:NSUTF8StringEncoding];
        if(!output){
            output = [[NSString allocWithZone:[self zone]] initWithData:stdoutData encoding:NSASCIIStringEncoding];
        }
        
        [stdoutData release];
        stdoutData = nil;
    } else {
        NSLog(@"Failed to launch task or task exited without accepting input.  Termination status was %d", [task terminationStatus]);
    }
    NS_HANDLER
        // if the pipe failed, we catch an exception here and ignore it
        NSLog(@"exception %@ encountered while trying to launch task %@", [localException name], executablePath);
    NS_ENDHANDLER
    
    // reset signal handling to default behavior
    signal(SIGPIPE, SIG_DFL);
    [task release];

    return [output autorelease];
}

- (void)stdoutNowAvailable:(NSNotification *)notification {
    // This is the notification method that executeBinary:inDirectory:withArguments:environment:inputString: registers to get called when all the data has been read. It just grabs the data and stuffs it in an ivar.  The setting of this ivar signals the main method that the output is complete and available.
    NSData *outputData = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    stdoutData = (outputData ? [outputData retain] : [[NSData allocWithZone:[self zone]] init]);
}


@end
