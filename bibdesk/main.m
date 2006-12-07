//  main.m

//  Created by Michael McCracken on Mon Dec 17 2001.
/*
This software is Copyright (c) 2001,2002,2003,2004,2005,2006 Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <Cocoa/Cocoa.h>
int main(int argc, const char *argv[])
{
    // Runtime check for system version
    // - uses Carbon dialog since we don't have NSApp yet
    // - uses Gestalt so we can check for a specific minor version (if it gets this far, anyway)
    // - Gestalt header says to read a plist, but mailing lists (and Ali Ozer) say to avoid that
    long version;
    OSStatus err = Gestalt(gestaltSystemVersion, &version);
    
    if (noErr != err || version < 0x00001040) {
        DialogRef alert;
        OSStatus err;
        
        // pool required for NSLocalizedString
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
        AlertStdCFStringAlertParamRec alertParamRec = {
            kStdCFStringAlertVersionOne,
            TRUE,
            FALSE,
            (CFStringRef)NSLocalizedString(@"Quit", @""),
            (CFStringRef)NSLocalizedString(@"Download and Quit", @""),
            NULL, // other button text
            1,    // default button is 1
            2,    // cancel is button 2
            kWindowDefaultPosition,
            0
        };
        
        err = CreateStandardAlert(kAlertStopAlert, (CFStringRef)NSLocalizedString(@"Unsupported System Version", @""), (CFStringRef)NSLocalizedString(@"This version of BibDesk requires Mac OS X 10.4 or greater to run.  Older versions of BibDesk are still available for download.  Would you like to download an older version or quit now?", @""), &alertParamRec, &alert);
        DialogItemIndex index;
        
        if (noErr == err) {
            
            // this will dispose of the alert (not that a leak is a big deal at this point)
            err = RunStandardAlert(alert, NULL, &index);
            if (2 == index) {
                
                // the home page should have a link to the previous versions
                CFURLRef homeURL = CFURLCreateWithString(NULL, CFSTR("http://bibdesk.sourceforge.net"), NULL);
                
                if (NULL == homeURL)
                    err = coreFoundationUnknownErr;
                
                if (noErr == err)
                    err = LSOpenCFURLRef(homeURL, NULL);
                
                if (homeURL) CFRelease(homeURL);
            }
        }
        [pool release];
        return err;
    }
    return NSApplicationMain(argc, argv);
}
