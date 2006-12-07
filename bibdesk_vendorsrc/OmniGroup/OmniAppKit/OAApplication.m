// Copyright 1997-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/OAApplication.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import <Carbon/Carbon.h>

#import "NSView-OAExtensions.h"
#import "NSImage-OAExtensions.h"
#import "OAAppKitQueueProcessor.h"
#import "OAPreferenceController.h"
#import "OASheetRequest.h"
#import "OAScriptMenuItem.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OAApplication.m 78738 2006-08-25 20:47:11Z rachael $")

NSString *OAFlagsChangedNotification = @"OAFlagsChangedNotification";

@interface OAApplication (Private)
+ (unsigned int)_currentModifierFlags;
- (void)processMouseButtonsChangedEvent:(NSEvent *)event;
+ (void)_setupDynamicMenus:(NSMenu *)aMenu;
+ (void)_makeDynamicItemGroupInMenu:(NSMenu *)aMenu forRangeOfItems:(NSRange)aRange;
+ (void)_activateFontsFromAppWrapper;
- (void)_scheduleModalPanelWithInvocation:(NSInvocation *)modalInvocation;
- (void)_rescheduleModalPanel:(NSTimer *)timer;
@end

static unsigned int launchModifierFlags;

@implementation OAApplication

+ (void)initialize;
{
    OBINITIALIZE;

    launchModifierFlags = [self _currentModifierFlags];
}

+ (void)setupOmniApplication;
{
    [OBObject self]; // Trigger +[OBPostLoader processClasses]
    
    // make these images available to client nibs and whatnot
    [NSImage imageNamed:@"OAHelpIcon" inBundleForClass:[OAApplication class]];
    [NSImage imageNamed:@"OACautionIcon" inBundleForClass:[OAApplication class]];
}

+ (NSApplication *)sharedApplication;
{
    static OAApplication *omniApplication = nil;

    if (omniApplication)
        return omniApplication;

    omniApplication = (id)[super sharedApplication];
    [self setupOmniApplication];
    return omniApplication;
}

- (void)dealloc;
{
    [exceptionCheckpointDate release];
    [windowsForSheets release];
    [sheetQueue release];
    [super dealloc];
}

- (void)finishLaunching;
{
    windowsForSheets = [[NSMutableDictionary alloc] init];
    sheetQueue = [[NSMutableArray alloc] init];

    [[OFController sharedController] addObserver:(id)[OAApplication class]];
    [super finishLaunching];
}

- (void)setMainMenu:(NSMenu *)mainMenu;
{
    if ([OAScriptMenuItem disabled]) {
	unsigned int itemIndex = [mainMenu numberOfItems];
	while (itemIndex--) {
	    id <NSMenuItem> item = [mainMenu itemAtIndex:itemIndex];
	    if ([item isKindOfClass:[OAScriptMenuItem class]])
		[mainMenu removeItemAtIndex:itemIndex];
	}
    }
    
    [super setMainMenu:mainMenu];
}

- (void)run;
{
    exceptionCount = 0;
    exceptionCheckpointDate = [[NSDate alloc] init];
    do {
        NS_DURING {
            [super run];
            NS_VOIDRETURN;
        } NS_HANDLER {
            if (++exceptionCount >= 300) {
                if ([exceptionCheckpointDate timeIntervalSinceNow] >= -3.0) {
                    // 300 unhandled exceptions in 3 seconds: abort
                    fprintf(stderr, "Caught 300 unhandled exceptions in 3 seconds, aborting\n");
                    return;
                }
                [exceptionCheckpointDate release];
                exceptionCheckpointDate = [[NSDate alloc] init];
                exceptionCount = 0;
            }
            if (localException) {
                if (_appFlags._hasBeenRun)
                    [self handleRunException:localException];
                else
                    [self handleInitException:localException];
            }
        } NS_ENDHANDLER;
    } while (_appFlags._hasBeenRun);
}

- (void)beginSheet:(NSWindow *)sheet modalForWindow:(NSWindow *)docWindow modalDelegate:(id)modalDelegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo;
{
    if ([[windowsForSheets allValues] indexOfObjectIdenticalTo:docWindow] != NSNotFound) {
        // This window already has a sheet, we need to wait for it to finish
        [sheetQueue addObject:[OASheetRequest sheetRequestWithSheet:sheet modalForWindow:docWindow modalDelegate:modalDelegate didEndSelector:didEndSelector contextInfo:contextInfo]];
    } else {
        if (docWindow != nil)
            [windowsForSheets setObject:docWindow forKey:sheet];
        [super beginSheet:sheet modalForWindow:docWindow modalDelegate:modalDelegate didEndSelector:didEndSelector contextInfo:contextInfo];
    }
}

- (void)endSheet:(NSWindow *)sheet returnCode:(int)returnCode;
{
    NSWindow *docWindow;
    OASheetRequest *queuedSheet = nil;
    unsigned int requestIndex, requestCount;

    // End this sheet
    [super endSheet:sheet returnCode:returnCode]; // Note: This runs the event queue itself until the sheet finishes retracting

    // Find the document window associated with the sheet we just ended
    docWindow = [[windowsForSheets objectForKey:sheet] retain];
    [windowsForSheets removeObjectForKey:sheet];

    // See if we have another sheet queued for this document window
    requestCount = [sheetQueue count];
    for (requestIndex = 0; requestIndex < requestCount; requestIndex++) {
        OASheetRequest *request;

        request = [sheetQueue objectAtIndex:requestIndex];
        if ([request docWindow] == docWindow) {
            queuedSheet = [request retain];
            [sheetQueue removeObjectAtIndex:requestIndex];
            break;
        }
    }
    [docWindow release];

    // Start the queued sheet
    [queuedSheet beginSheet];
    [queuedSheet release];
}

#ifdef CustomScrollWheelHandling

#define MAXIMUM_LINE_FACTOR 12.0
#define PAGE_FACTOR MAXIMUM_LINE_FACTOR * 2.0 * 2.0 * 2.0
#define ACCELERATION 2.0
#define MAX_SCALE_SETTINGS 12

static struct {
    float targetScrollFactor;
    float timeSinceLastScroll;
} mouseScaling[MAX_SCALE_SETTINGS] = {
    {1.0, 0.0}
};

static void OATargetScrollFactorReadFromDefaults(void)
{
    NSArray *values;
    unsigned int settingIndex, valueCount;
    NSString *defaultsKey;

    defaultsKey = @"OAScrollWheelTargetScrollFactor";
    values = [[NSUserDefaults standardUserDefaults] arrayForKey:defaultsKey];
    if (values == nil)
        return;
    valueCount = [values count];
    for (settingIndex = 0; settingIndex < MAX_SCALE_SETTINGS; settingIndex++) {
        unsigned int factorValueIndex;
        float factor, cutoff;

        factorValueIndex = settingIndex * 2;
        factor = factorValueIndex < valueCount ? [[values objectAtIndex:factorValueIndex] floatValue] : 0.0;
        cutoff = factorValueIndex + 1 < valueCount ? (1.0 / [[values objectAtIndex:factorValueIndex + 1] floatValue]) : 0.0;
        mouseScaling[settingIndex].targetScrollFactor = factor;
        mouseScaling[settingIndex].timeSinceLastScroll = cutoff;
    }
}

static float OATargetScrollFactorForTimeInterval(NSTimeInterval timeSinceLastScroll)
{
    static BOOL alreadyInitialized = NO;
    unsigned int mouseScalingIndex;

    if (!alreadyInitialized) {
        OATargetScrollFactorReadFromDefaults();
        alreadyInitialized = YES;
    }
    for (mouseScalingIndex = 0;
         mouseScalingIndex < MAX_SCALE_SETTINGS && MAX(0.0, timeSinceLastScroll) < mouseScaling[mouseScalingIndex].timeSinceLastScroll;
         mouseScalingIndex++) {
    }

    return mouseScaling[mouseScalingIndex].targetScrollFactor;
}

static float OAScrollFactorForWheelEvent(NSEvent *event)
{
    static NSTimeInterval lastScrollWheelTimeInterval = 0.0;
    static float scrollFactor = 100.0;
    NSTimeInterval timestamp;
    NSTimeInterval timeSinceLastScroll;
    float targetScrollFactor;
    
    timestamp = [event timestamp];
    timeSinceLastScroll = timestamp - lastScrollWheelTimeInterval;
    targetScrollFactor = OATargetScrollFactorForTimeInterval(timeSinceLastScroll);
    lastScrollWheelTimeInterval = timestamp;
    if (scrollFactor == targetScrollFactor) {
        // Do nothing
    } else if (timeSinceLastScroll > 0.5) {
        // If it's been more than half a second, just start over at the target factor
        scrollFactor = targetScrollFactor;
    } else if (scrollFactor * (1.0 / ACCELERATION) > targetScrollFactor) {
        // Reduce our scroll factor
        scrollFactor *= (1.0 / ACCELERATION);
    } else if (scrollFactor * ACCELERATION < targetScrollFactor) {
        // Increase our scroll factor
        scrollFactor *= ACCELERATION;
    } else {
        // The target is near, just jump to it
        scrollFactor = targetScrollFactor;
    }
    return scrollFactor;
}
#endif

#define OASystemDefinedEvent_MouseButtonsChangedSubType 7

- (void)sendEvent:(NSEvent *)event;
{
    // The -timestamp method on NSEvent doesn't seem to return an NSTimeInterval based off the same reference date as NSDate (which is what we want).
    lastEventTimeInterval = [NSDate timeIntervalSinceReferenceDate];

    NS_DURING {
        switch ([event type]) {
            case NSSystemDefined:
                if ([event subtype] == OASystemDefinedEvent_MouseButtonsChangedSubType)
                    [self processMouseButtonsChangedEvent:event];
                [super sendEvent:event];
                break;
            case NSFlagsChanged:
                [super sendEvent:event];
                [[NSNotificationCenter defaultCenter] postNotificationName:OAFlagsChangedNotification object:event];
                break;
            case NSLeftMouseDown:
            {
                unsigned int modifierFlags = [event modifierFlags];
                BOOL justControlDown = (modifierFlags & NSControlKeyMask) && !(modifierFlags & NSShiftKeyMask) && !(modifierFlags & NSCommandKeyMask) && !(modifierFlags & NSAlternateKeyMask);
                
                if (justControlDown) {
                    NSView *contentView = [[event window] contentView];
                    NSView *viewUnderMouse = [contentView hitTest:[event locationInWindow]];
                    
                    if (viewUnderMouse != nil && [viewUnderMouse respondsToSelector:@selector(controlMouseDown:)]) {
                        [viewUnderMouse controlMouseDown:event];
                        NS_VOIDRETURN;
                    }
                }
                [super sendEvent:event];
                    
                break;
            }
                        
            default:
                [super sendEvent:event];
                break;
        }
    } NS_HANDLER {
        if ([[localException name] isEqualToString:NSAbortModalException] || [[localException name] isEqualToString:NSAbortPrintingException])
            [localException raise];
        [self handleRunException:localException];
    } NS_ENDHANDLER;
}

- (void)handleInitException:(NSException *)anException;
{
    id delegate;

    delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(handleInitException:)]) {
        [delegate handleInitException:anException];
    } else {
        NSLog(@"%@", [anException reason]);
    }
}

- (void)handleRunException:(NSException *)anException;
{
    if (currentRunExceptionPanel) {
        // Already handling an exception!
        NSLog(@"Ignoring exception raised while displaying previous exception: %@", anException);
        return;
    }

    NS_DURING {
        id delegate = [self delegate];
        if ([delegate respondsToSelector:@selector(handleRunException:)]) {
            [delegate handleRunException:anException];
        } else {
            NSLog(@"%@", [anException reason]);

            // Do NOT use NSRunAlertPanel.  If another exception happens while NSRunAlertPanel is going, the alert will be removed from the screen and the user will not be able to report the original exception!
            // NSGetAlertPanel will not have a default button if we pass nil.
            NSString *okString = NSLocalizedStringFromTableInBundle(@"OK", @"OmniAppKit", [OAApplication bundle], "unhandled exception panel button");
            currentRunExceptionPanel = NSGetAlertPanel(nil, @"%@", okString, nil, nil, [anException reason]);
            [currentRunExceptionPanel center];
            [currentRunExceptionPanel makeKeyAndOrderFront:self];

            // The documentation for this method says that -endModalSession: must be before the NS_ENDHANDLER.
            NSModalSession modalSession = [self beginModalSessionForWindow:currentRunExceptionPanel];

            int ret = NSAlertErrorReturn;
            while (ret != NSAlertDefaultReturn) {
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                NS_DURING {
                    // Might be NSAlertErrorReturn or NSRunContinuesResponse experimental evidence shows that it returns NSRunContinuesResponse if an exception was raised inside calling it (and it doesn't re-raise the exception since it returns).  We'll not assume this, though and we'll put this in a handler.
                    ret = [self runModalSession:modalSession];
                } NS_HANDLER {
                    // Exception might get caught and passed to us by some other code (since this method is public).  So, our nesting avoidance is at the top of the method instead of in this handler block.
                    [self handleRunException:localException];
                    ret = NSAlertErrorReturn;
                } NS_ENDHANDLER;

                // Since we keep looping until the user clicks the button (rather than hiding the error panel at the first sign of trouble), we don't want to eat all the CPU needlessly.
                [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
                [pool release];
            }
            
            [self endModalSession:modalSession];
            [currentRunExceptionPanel orderOut:nil];
            NSReleaseAlertPanel(currentRunExceptionPanel);
            currentRunExceptionPanel = nil;
        }
    } NS_HANDLER {
        // Exception might get caught and passed to us by some other code (since this method is public).  So, our nesting avoidance is at the top of the method instead of in this handler block.
        [self handleRunException:localException];
    } NS_ENDHANDLER;
}

- (NSPanel *)currentRunExceptionPanel;
{
    return currentRunExceptionPanel;
}

- (NSTimeInterval)lastEventTimeInterval;
{
    return lastEventTimeInterval;
}

- (BOOL)mouseButtonIsDownAtIndex:(unsigned int)mouseButtonIndex;
{
    return (mouseButtonState & (1 << mouseButtonIndex)) != 0;
}

- (BOOL)scrollWheelButtonIsDown;
{
    return [self mouseButtonIsDownAtIndex:2];
}

- (unsigned int)currentModifierFlags;
{
    return [isa _currentModifierFlags];
}

- (BOOL)checkForModifierFlags:(unsigned int)flags;
{
    return ([self currentModifierFlags] & flags) != 0;
}

- (unsigned int)launchModifierFlags;
{
    return launchModifierFlags;
}

- (void)scheduleModalPanelForTarget:(id)modalController selector:(SEL)modalSelector userInfo:(id)userInfo;
{
    OBPRECONDITION(modalController != nil);
    OBPRECONDITION([modalController respondsToSelector:modalSelector]);
    
    // Create an invocation out of this request
    NSMethodSignature *modalSignature = [modalController methodSignatureForSelector:modalSelector];
    if (modalSignature == nil)
        return;
    NSInvocation *modalInvocation = [NSInvocation invocationWithMethodSignature:modalSignature];
    [modalInvocation setTarget:modalController];
    [modalInvocation setSelector:modalSelector];
    
    // Pass userInfo if modalSelector takes it
    if ([modalSignature numberOfArguments] > 2) // self, _cmd
        [modalInvocation setArgument:&userInfo atIndex:2];

    [self _scheduleModalPanelWithInvocation:modalInvocation];
}

// Prefix the URL string with "anchor:" if the string is the name of an anchor in the help files. Prefix it with "search:" to search for the string in the help book.
- (void)showHelpURL:(NSString *)helpURL;
{
    id applicationDelegate = [NSApp delegate];
    if ([applicationDelegate respondsToSelector:@selector(openAddressWithString:)]) {
        // We're presumably in OmniWeb, in which case we display our help internally
        NSString *omniwebHelpBaseURL = @"omniweb:/Help/";
        if([helpURL isEqualToString:@"anchor:SoftwareUpdatePreferences_Help"])
            helpURL = @"reference/preferences/Update.html";
        [applicationDelegate performSelector:@selector(openAddressWithString:) withObject:[omniwebHelpBaseURL stringByAppendingString:helpURL]];
    } else {
	NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *bookName = [mainBundle localizedStringForKey:@"CFBundleHelpBookName" value:@"" table:@"InfoPlist"];
        if (![bookName isEqualToString:@"CFBundleHelpBookName"]) {
            // We've got Apple Help.  First, make sure the help book is registered.  NSHelpManager would do this for us, but we use AHGotoPage, which it doesn't cover.
	    static BOOL helpBookRegistered = NO;
	    if (!helpBookRegistered) {
		helpBookRegistered = YES;
		NSURL *appBundleURL = [NSURL fileURLWithPath:[mainBundle bundlePath]];
		FSRef appBundleRef;
		if (!CFURLGetFSRef((CFURLRef)appBundleURL, &appBundleRef))
		    NSLog(@"Unable to get FSRef for app bundle URL of '%@' for bundle '%@'", appBundleURL, mainBundle);
		else
		    AHRegisterHelpBook(&appBundleRef);
	    }
	    
	    
            OSStatus err;
            NSRange range = [helpURL rangeOfString:@"search:"];
            if ((range.length != 0) || (range.location == 0))
                err = AHSearch((CFStringRef)bookName, (CFStringRef)[helpURL substringFromIndex:NSMaxRange(range)]);
            else {
                range = [helpURL rangeOfString:@"anchor:"];
                if ((range.length != 0) || (range.location == 0))
                    err = AHLookupAnchor((CFStringRef)bookName, (CFStringRef)[helpURL substringFromIndex:NSMaxRange(range)]);
                else
                    err = AHGotoPage((CFStringRef)bookName, (CFStringRef)helpURL, NULL);
            }
            
            if (err != noErr)	
                NSLog(@"Apple Help error: %d", err);
        } else {
            // We can let the system decide who to open the URL with
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:helpURL]];
        }
    }
}

// Application Support directory
- (NSArray *)supportDirectoriesInDomain:(NSSearchPathDomainMask)domains;
{
    // TODO: Cache this?
    NSArray *appSupp;
    NSString *appSupportDirectory = nil;
    
    if (appSupportDirectory == nil) {
        id appDelegate = [NSApp delegate];
        if (appDelegate != nil && [appDelegate respondsToSelector:@selector(applicationSupportDirectoryName)])
            appSupportDirectory = [appDelegate applicationSupportDirectoryName];
        
        if (appSupportDirectory == nil)
            appSupportDirectory = [[NSProcessInfo processInfo] processName];
    }
    
    OBASSERT(appSupportDirectory != nil);
    
    appSupp = nil;
#if MAC_OS_X_VERSION_10_4 <= MAC_OS_X_VERSION_MAX_ALLOWED
    // Unfortunately, calling NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, ...) on 10.3 doesn't return a reasonable failure, like nil or something --- it returns an array containing some garbage paths. So we check the Foundation version number here.
#ifndef NSFoundationVersionNumber10_4
#define NSFoundationVersionNumber10_4 501  // Unknown. Apple doesn't declare it anywhere. But 10.3.9 is 500.59.
#endif
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber10_4) {
        appSupp = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, domains, YES);
    }
#endif
    
    if (appSupp == nil) {
        NSArray *library = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, domains, YES);
        if (library == nil)
            return nil;
        appSupp = [library arrayByPerformingSelector:@selector(stringByAppendingPathComponent:) withObject:@"Application Support"];
    }
        
    return [appSupp arrayByPerformingSelector:@selector(stringByAppendingPathComponent:) withObject:appSupportDirectory];
}

- (NSArray *)readableSupportDirectoriesInDomain:(NSSearchPathDomainMask)domains withComponents:(NSString *)subdir, ...;
{
    NSArray *paths = [self supportDirectoriesInDomain:domains];
    unsigned int pathCount = [paths count], pathIndex;
    NSFileManager *filemgr = [NSFileManager defaultManager];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:pathCount];
    for(pathIndex = 0; pathIndex < pathCount; pathIndex ++) {
        va_list varg;
        BOOL isDir;
        va_start(varg, subdir);
        NSString *component = subdir;
        NSString *path = [paths objectAtIndex:pathIndex];
        while(component != nil) {
            path = [path stringByAppendingPathComponent:component];
            component = va_arg(varg, NSString *);
        }
        va_end(varg);
        if ([filemgr fileExistsAtPath:path isDirectory:&isDir] && isDir)
            [result addObject:path];
    }
    return result;
}

- (NSString *)writableSupportDirectoryInDomain:(NSSearchPathDomainMask)domains withComponents:(NSString *)subdir, ...;
{
    NSArray *paths = [self supportDirectoriesInDomain:domains];
    unsigned int pathCount = [paths count], pathIndex;
    NSFileManager *filemgr = [NSFileManager defaultManager];
    for(pathIndex = 0; pathIndex < pathCount; pathIndex ++) {
        va_list varg;
        BOOL isDir;
        va_start(varg, subdir);
        NSString *component = subdir;
        NSString *path = [paths objectAtIndex:pathIndex];
        while(component != nil) {
            path = [path stringByAppendingPathComponent:component];
            component = va_arg(varg, NSString *);
        }
        va_end(varg);
        if ([filemgr fileExistsAtPath:path isDirectory:&isDir]) {
            if(isDir && [filemgr isWritableFileAtPath:path])
                return path;
        } else {
            if ([filemgr createDirectoryAtPath:path attributes:nil])
                return path;
        }
    }
    return nil;
}

// Actions

- (IBAction)closeAllMainWindows:(id)sender;
{
    NSArray *windows;
    unsigned int windowIndex, windowCount;
    
    windows = [[NSArray alloc] initWithArray:[self orderedWindows]];
    windowCount = [windows count];
    for (windowIndex = 0; windowIndex < windowCount; windowIndex++) {
        NSWindow *window;

        window = [windows objectAtIndex:windowIndex];
        if ([window canBecomeMainWindow])
            [window performClose:nil];
    }
    [windows release];
}

- (IBAction)cycleToNextMainWindow:(id)sender;
{
    NSWindow *mainWindow;
    NSArray *orderedWindows;
    unsigned int windowIndex, windowCount;
    
    mainWindow = [NSApp mainWindow];
    orderedWindows = [NSApp orderedWindows];
    windowCount = [orderedWindows count];
    for (windowIndex = 0; windowIndex < windowCount; windowIndex++) {
        NSWindow *window;

        window = [orderedWindows objectAtIndex:windowIndex];
        if (window != mainWindow && [window canBecomeMainWindow] && ![NSStringFromClass([window class]) isEqualToString:@"NSDrawerWindow"]) {
            [window makeKeyAndOrderFront:nil];
            [mainWindow orderBack:nil];
            return;
        }
    }
    // There's one (or less) window which can potentially be main, make it key and bring it forward.
    [mainWindow makeKeyAndOrderFront:nil];
}

- (IBAction)cycleToPreviousMainWindow:(id)sender;
{
    NSWindow *mainWindow;
    NSArray *orderedWindows;
    unsigned int windowIndex;
    
    mainWindow = [NSApp mainWindow];
    orderedWindows = [NSApp orderedWindows];
    windowIndex = [orderedWindows count];
    while (windowIndex--) {
        NSWindow *window;

        window = [orderedWindows objectAtIndex:windowIndex];
        if (window != mainWindow && [window canBecomeMainWindow] && ![NSStringFromClass([window class]) isEqualToString:@"NSDrawerWindow"]) {
            [window makeKeyAndOrderFront:nil];
            return;
        }
    }
    // There's one (or less) window which can potentially be main, make it key and bring it forward.
    [mainWindow makeKeyAndOrderFront:nil];
}

- (IBAction)showPreferencesPanel:(id)sender;
{
    [[OAPreferenceController sharedPreferenceController] showPreferencesPanel:nil];
}

static NSArray *overrideWindows = nil;

- (NSArray *)windows;
{
    if (overrideWindows)
        return overrideWindows;
    return [super windows];
}

- (void)miniaturizeWindows:(NSArray *)windows;
{
    overrideWindows = windows;
    @try {
        [super miniaturizeAll:nil];
    } @finally {
        overrideWindows = nil;
    }
}

// OFController observer informal protocol

+ (void)controllerStartedRunning:(OFController *)controller;
{
    [self _setupDynamicMenus:[NSApp mainMenu]];
    [self _activateFontsFromAppWrapper];
}


@end

@implementation OAApplication (Private)

+ (unsigned int)_currentModifierFlags;
{
    unsigned int flags = 0;
    UInt32 currentKeyModifiers = GetCurrentKeyModifiers();
    if (currentKeyModifiers & cmdKey)
        flags |= NSCommandKeyMask;
    if (currentKeyModifiers & shiftKey)
        flags |= NSShiftKeyMask;
    if (currentKeyModifiers & optionKey)
        flags |= NSAlternateKeyMask;
    if (currentKeyModifiers & controlKey)
        flags |= NSControlKeyMask;
    
    return flags;
}

- (void)processMouseButtonsChangedEvent:(NSEvent *)event;
{
    mouseButtonState = [event data2];
}

+ (void)_setupDynamicMenus:(NSMenu *)aMenu;
{
    unsigned int itemIndex, itemCount;
    NSRange dynamicItemGroupRange;

    dynamicItemGroupRange = NSMakeRange(0, 0);
    itemCount = [aMenu numberOfItems];
    for (itemIndex = 0; itemIndex < itemCount; itemIndex++) {
        id <NSMenuItem> currentItem;

        currentItem = [aMenu itemAtIndex:itemIndex];
        if ([currentItem hasSubmenu])
            [self _setupDynamicMenus:[currentItem submenu]];
        if ([currentItem tag] == 1) {
            if (dynamicItemGroupRange.length == 0) // If we don't have a group open
                dynamicItemGroupRange.location = itemIndex; // Start the group here
            dynamicItemGroupRange.length++; // Extend the group
        } else if (dynamicItemGroupRange.length != 0 && [currentItem tag] == 0) {
            // We've reached the end of the group, process it
            [self _makeDynamicItemGroupInMenu:aMenu forRangeOfItems:dynamicItemGroupRange];
            dynamicItemGroupRange.length = 0;
        }
    }

    // If we ended with a dynamic group, process it
    if (dynamicItemGroupRange.length != 0)
        [self _makeDynamicItemGroupInMenu:aMenu forRangeOfItems:dynamicItemGroupRange];
}

+ (void)_makeDynamicItemGroupInMenu:(NSMenu *)aMenu forRangeOfItems:(NSRange)aRange;
{
    extern MenuRef _NSGetCarbonMenu(NSMenu *);
    MenuRef menu;
    unsigned int item;
    
    menu = _NSGetCarbonMenu(aMenu);
    aRange.location++; // Carbon menu indices include the menu itself at index 0:  skip past it
    for (item = aRange.location; item < aRange.location + aRange.length; item++)
        ChangeMenuItemAttributes(menu, item, kMenuItemAttrDynamic, 0);
}

+ (void)_activateFontsFromAppWrapper;
{
    FSRef myFSRef;
    FSSpec myFSSpec;

    NSString *fontsDirectory = [[[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Fonts"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fontsDirectory])
        if (FSPathMakeRef((UInt8 *)[fontsDirectory fileSystemRepresentation], &myFSRef, NULL) == noErr)
            if (FSGetCatalogInfo(&myFSRef, kFSCatInfoNone, NULL, NULL, &myFSSpec, NULL) == noErr)
                ATSFontActivateFromFileSpecification(&myFSSpec, kATSFontContextLocal, kATSFontFormatUnspecified, NULL, kATSOptionFlagsDefault, NULL);
}

- (void)_scheduleModalPanelWithInvocation:(NSInvocation *)modalInvocation;
{
    OBPRECONDITION(modalInvocation != nil);
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    if ([[runLoop currentMode] isEqualToString:NSModalPanelRunLoopMode]) {
        NSTimer *timer = [NSTimer timerWithTimeInterval:0.0 target:self selector:@selector(_rescheduleModalPanel:) userInfo:modalInvocation repeats:NO];
        [runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
    } else {
        [modalInvocation invoke];
    }
}

- (void)_rescheduleModalPanel:(NSTimer *)timer;
{
    OBPRECONDITION(timer != nil);
    
    NSInvocation *invocation = [timer userInfo];
    OBASSERT(invocation != nil);
    
    [self _scheduleModalPanelWithInvocation:invocation];
}

@end
