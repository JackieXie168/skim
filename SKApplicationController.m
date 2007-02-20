//
//  SKApplicationController.m


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/6/06.
//  Copyright 2006 Michael O. McCracken. All rights reserved.
//

#import "SKApplicationController.h"
#import "SKPreferenceController.h"
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

- (IBAction)showPreferencePanel:(id)sender{
    [[SKPreferenceController sharedPrefenceController] showWindow:self];
}

@end
