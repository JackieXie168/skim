//
//  BDSKShellTask.m
//  Bibdesk
//
//  Created by Michael McCracken on Sat Dec 14 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "BDSKShellTask.h"


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
    NSString *shellScriptPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
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

    [task launch];

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

    [task release];

    return [output autorelease];
}

- (void)stdoutNowAvailable:(NSNotification *)notification {
    // This is the notification method that executeBinary:inDirectory:withArguments:environment:inputString: registers to get called when all the data has been read. It just grabs the data and stuffs it in an ivar.  The setting of this ivar signals the main method that the output is complete and available.
    NSData *outputData = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    stdoutData = (outputData ? [outputData retain] : [[NSData allocWithZone:[self zone]] init]);
}


@end
