//
//  BDSKShellTask.h
//  Bibdesk
//
//  Created by Michael McCracken on Sat Dec 14 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/stat.h>

@interface BDSKShellTask : NSObject {
    // data used to store stdOut from the filter
    NSData *stdoutData;
}

+ (BDSKShellTask *)shellTask;

- (NSString *)runShellCommand:(NSString *)cmd withInputString:(NSString *)input;
- (NSString *)executeBinary:(NSString *)executablePath inDirectory:(NSString *)currentDirPath withArguments:(NSArray *)args environment:(NSDictionary *)env inputString:(NSString *)input;
- (void)stdoutNowAvailable:(NSNotification *)notification;
@end
