//
//  SKApplicationController.m
//  Skim
//
//  Created by Michael McCracken on 12/6/06.
/*
 This software is Copyright (c) 2006,2007
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

#import "SKApplicationController.h"
#import "SKPreferenceController.h"
#import "SKUpdateChecker.h"
#import "SKStringConstants.h"
#import "SKDocument.h"
#import "SKMainWindowController.h"
#import "BDAlias.h"
#import <Quartz/Quartz.h>


@implementation SKApplicationController

+ (void)initialize{
    [self setupDefaults];
}
   
+ (void)setupDefaults{
    
    NSString *userDefaultsValuesPath;
    NSDictionary *userDefaultsValuesDict;
    NSDictionary *initialValuesDict;
    NSArray *resettableUserDefaultsKeys;
    
    // load the default values for the user defaults
    userDefaultsValuesPath = [[NSBundle mainBundle] pathForResource:@"InitialUserDefaults" 
                                                           ofType:@"plist"];
    userDefaultsValuesDict = [NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
    
    // set them in the standard user defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsValuesDict];
    
    // if your application supports resetting a subset of the defaults to 
    // factory values, you should set those values 
    // in the shared user defaults controller
    resettableUserDefaultsKeys = [userDefaultsValuesDict objectForKey:@"SKResettableKeys"];
    
    initialValuesDict = [userDefaultsValuesDict dictionaryWithValuesForKeys:resettableUserDefaultsKeys];
    
    // Set the initial values in the shared user defaults controller 
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValuesDict];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender{
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKReopenLastOpenFilesKey]) {
        NSArray *files = [[NSUserDefaults standardUserDefaults] objectForKey:SKLastOpenFileNamesKey];
        NSEnumerator *fileEnum = [files objectEnumerator];
        NSDictionary *dict;
        NSURL *fileURL;
        SKDocument *document;
        
        while (dict = [fileEnum nextObject]){ 
            fileURL = [[BDAlias aliasWithData:[dict objectForKey:@"_BDAlias"]] fileURL];
            if(fileURL == nil)
                fileURL = [NSURL fileURLWithPath:[dict objectForKey:@"fileName"]];
            if(fileURL && (document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL display:NO error:NULL])) {
                [document makeWindowControllers];
                [[document mainWindowController] setupWindow:dict];
                [document showWindows];
            }
        }
    }
    
    return NO;
}    

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    [[SKUpdateChecker sharedChecker] scheduleUpdateCheckIfNeeded];
}

- (IBAction)checkForUpdates:(id)sender{
    [[SKUpdateChecker sharedChecker] checkForUpdates:sender];  
}

- (IBAction)showPreferencePanel:(id)sender{
    [[SKPreferenceController sharedPrefenceController] showWindow:self];
}

@end
