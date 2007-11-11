//
//  main.m


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/5/06.
//  Copyright Michael O. McCracken 2006 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

int main(int argc, char *argv[])
{
    // Runtime check for system version
    // - uses Carbon dialog since we don't have NSApp yet
    // - uses Gestalt so we can check for a specific minor version (if it gets this far, anyway)
    // - Gestalt header says to read a plist, but mailing lists (and Ali Ozer) say to avoid that
    long version;
    OSStatus err = Gestalt(gestaltSystemVersion, &version);
    
    if (noErr != err || version < 0x00001040) {
        DialogRef alert;
        
        // pool required for NSLocalizedString
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
        AlertStdCFStringAlertParamRec alertParamRec = {
            kStdCFStringAlertVersionOne,
            TRUE,
            FALSE,
            (CFStringRef)NSLocalizedString(@"Quit", @""),
            NULL, // cancel button text
            NULL, // other button text
            kAlertStdAlertOKButton,
            kAlertStdAlertCancelButton,
            kWindowDefaultPosition,
            0
        };
        
        err = CreateStandardAlert(kAlertStopAlert, (CFStringRef)NSLocalizedString(@"Unsupported System Version", @""), (CFStringRef)NSLocalizedString(@"This version of Skim requires Mac OS X 10.4 or greater to run.", @""), &alertParamRec, &alert);
        DialogItemIndex idx;
        
        if (noErr == err) {
            // this will dispose of the alert (not that a leak is a big deal at this point)
            err = RunStandardAlert(alert, NULL, &idx);
        }
        [pool release];
        return err;
    }
    return NSApplicationMain(argc, (const char **) argv);
}
