//
//  main.m


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/5/06.
//  Copyright Michael O. McCracken 2006 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
    // Runtime check for system version
    // - uses Carbon dialog since we don't have NSApp yet
    // - uses Gestalt so we can check for a specific minor version (if it gets this far, anyway)
    // - Gestalt header says to read a plist, but mailing lists (and Ali Ozer) say to avoid that
    SInt32 version;
    OSStatus err = Gestalt(gestaltSystemVersion, &version);
    
    if (noErr != err || version < 0x00001050) {
        NSLog(@"Incompatible version. Skim requires Mac OSX 10.5 or later.");
        return err;
    }
    return NSApplicationMain(argc, (const char **) argv);
}
