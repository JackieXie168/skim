// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniAppKit/OAApplication.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import <Carbon/Carbon.h>

#import "NSView-OAExtensions.h"
#import "NSImage-OAExtensions.h"
#import "OAAppKitQueueProcessor.h"
#import "OAInspector.h"
#import "OAPreferenceController.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OAApplication.m,v 1.86 2003/04/17 01:50:00 rick Exp $")

DEFINE_NSSTRING(OAFlagsChangedNotification);

static OFBundledClass *SoftwareUpdateUIClass;

@interface OAApplication (Private)
- (void)processMouseButtonsChangedEvent:(NSEvent *)event;
+ (void)_setupDynamicMenus:(NSMenu *)aMenu;
+ (void)_makeDynamicItemGroupInMenu:(NSMenu *)aMenu forRangeOfItems:(NSRange)aRange;
+ (void)_activateFontsFromAppWrapper;
@end

@implementation OAApplication

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
    [OAApplication setupOmniApplication];
    return omniApplication;
}

- (void)finishLaunching;
{
    // If nobody is registering to handle software update notifications, we shouldn't schedule them.
    if (SoftwareUpdateUIClass != nil)
        [[OFSoftwareUpdateChecker sharedUpdateChecker] setTarget:self];

    [[OFController sharedController] addObserver:[OAApplication class]];
    [super finishLaunching];
}

- (void)run;
{
    BOOL stillRunning = YES;

    exceptionCount = 0;
    exceptionCheckpointDate = [[NSDate alloc] init];
    do {
        NS_DURING {
            [super run];
            stillRunning = NO;
        } NS_HANDLER {
            if (++exceptionCount % 300 == 0) {
                if ([exceptionCheckpointDate timeIntervalSinceNow] > -3.0)
                    stillRunning = NO; // 300 exceptions in 3 seconds: abort
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
    } while (stillRunning && _appFlags._hasBeenRun);
}

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
            case NSScrollWheel:
            {
                NSView *contentView;
                NSView *viewUnderMouse;
                NSScrollView *scrollView;
                BOOL scrollWheelButtonIsDown;
    
                contentView = [[event window] contentView];
                viewUnderMouse = [contentView hitTest:[contentView convertPoint:[event locationInWindow] fromView:nil]];
                scrollView = [viewUnderMouse enclosingScrollView];
                if (([event modifierFlags] & NSCommandKeyMask) == 0) {
                    NSScrollView *idealScrollView;

                    // TODO:  when scrollwheels let you scroll in both directions simultaneously, we'll need to rewrite this block to handle that
                    idealScrollView = scrollView;
                    if ([event deltaY] != 0.0) {
                        while (idealScrollView != nil && ![idealScrollView hasVerticalScroller])
                            idealScrollView = [idealScrollView enclosingScrollView];
                    }
                    if ([event deltaX] != 0.0) {
                        while (idealScrollView != nil && ![idealScrollView hasHorizontalScroller])
                            idealScrollView = [idealScrollView enclosingScrollView];
                    }
                    if (idealScrollView != nil)
                        scrollView = idealScrollView;
                }
                scrollWheelButtonIsDown = [self scrollWheelButtonIsDown];
                if (scrollView == nil || [scrollView methodForSelector:@selector(scrollWheel:)] != [NSScrollView instanceMethodForSelector:@selector(scrollWheel:)]) {
                    // We're not over a scroll view, or the scroll view has a custom implementation of -scrollWheel:.
                    [super sendEvent:event];
                } else {
                    float deltaX, deltaY;

                    deltaX = -[event deltaX];
                    deltaY = -[event deltaY];
                    if (scrollWheelButtonIsDown) {
                        [scrollView scrollRightByPages:deltaX];
                        [scrollView scrollDownByPages:deltaY];
                    } else {
                        float scrollFactor;

                        scrollFactor = OAScrollFactorForWheelEvent(event);
                        if (scrollFactor >= PAGE_FACTOR) {
                            [scrollView scrollRightByPages:deltaX];
                            [scrollView scrollDownByPages:deltaY];
                        } else {
                            [scrollView scrollRightByLines:MIN(scrollFactor, MAXIMUM_LINE_FACTOR) * deltaX];
                            [scrollView scrollDownByLines:MIN(scrollFactor, MAXIMUM_LINE_FACTOR) * deltaY];
                        }
                    }
                }
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
    id delegate;

    delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(handleRunException:)]) {
        [delegate handleRunException:anException];
    } else {
        NSLog(@"%@", [anException reason]);
        NSRunAlertPanel(nil, @"%@", nil, nil, nil, [anException reason]);
    }
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

// based on a contribution from Axel Wefers (www.fruitz-of-dojo.de)
- (BOOL)checkForModifierFlags:(unsigned int)flags;
{
    NSEvent *myEvent;
    BOOL gotFlags = NO;
    
    // post fake shift-down an shift-up events so we can find out what other modifers are down "right now".
    CGPostKeyboardEvent((CGCharCode) 0xffff, (CGKeyCode) 56, YES); // 56 = Shift. Not defined as a constant anywhere!?
    CGPostKeyboardEvent((CGCharCode) 0xffff, (CGKeyCode) 56, NO);

    while (1) {
        myEvent = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:YES];

        // we are finished when no events are left
        if (!myEvent)
            break;

        // see if our shift down event has the other flags we want
        [NSApp sendEvent:myEvent];
        if ([myEvent keyCode] == 56 && [myEvent modifierFlags] & flags)
            gotFlags = YES;
    }
    return gotFlags;
}

- (void)showHelpURL:(NSString *)helpURL;
{
    id applicationDelegate;
        
    applicationDelegate = [NSApp delegate];
    if ([applicationDelegate respondsToSelector:@selector(openAddressWithString:)]) {
        // We're presumably in OmniWeb, in which case we display our help internally
        NSString *omniwebHelpBaseURL = @"omniweb:/Help/";
        [applicationDelegate performSelector:@selector(openAddressWithString:) withObject:[omniwebHelpBaseURL stringByAppendingString:helpURL]];
    } else {
        NSString *bookName;

        bookName = NSLocalizedStringFromTable(@"CFBundleHelpBookName", @"InfoPlist", "localized version of the help book name");
        if (bookName != nil) {
            // We've got Apple Help
            OSStatus err;

            err = AHGotoPage((CFStringRef)bookName, (CFStringRef)helpURL, NULL);
            if (err != noErr)	
                NSLog(@"Apple Help error: %d", err);
        } else {
            // We can let the system decide who to open the URL with
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:helpURL]];
        }
    }
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

- (IBAction)miniaturizeAll:(id)sender;
{
    NSArray *windows;
    unsigned int windowIndex, windowCount;
    
    windows = [[NSArray alloc] initWithArray:[self orderedWindows]];
    windowCount = [windows count];
    for (windowIndex = 0; windowIndex < windowCount; windowIndex++) {
        NSWindow *window;

        window = [windows objectAtIndex:windowIndex];
        [window performMiniaturize:nil];
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

- (IBAction)showInspectorPanel:(id)sender;
{
    [OAInspector showInspector];
}

- (IBAction)toggleInspectorPanel:(id)sender;
{
    if ([OAInspector isInspectorVisible]) {
        [OAInspector hideInspector];
    } else {
        [OAInspector showInspector];
    }
}

- (IBAction)showPreferencesPanel:(id)sender;
{
    [[OAPreferenceController sharedPreferenceController] showPreferencesPanel:nil];
}

// Check for new version of this application on Omni's web site. Triggered by direct user action.
- (IBAction)checkForNewVersion:(id)sender;
{
    if (SoftwareUpdateUIClass != nil)
        [[SoftwareUpdateUIClass bundledClass] checkSynchronouslyWithUIAttachedToWindow:nil];
}

- (void)newVersionAvailable:(NSDictionary *)versionInfo;
{
    if (SoftwareUpdateUIClass != nil)
        [[SoftwareUpdateUIClass bundledClass] newVersionAvailable:versionInfo];
}


// OFController observer informal protocol

+ (void)controllerStartedRunning:(OFController *)controller;
{
    [self _setupDynamicMenus:[NSApp mainMenu]];
    [self _activateFontsFromAppWrapper];
}


// OFBundleRegistryTarget

+ (void)registerItemName:(NSString *)itemName bundle:(NSBundle *)bundle description:(NSDictionary *)descriptionDict;
{
    if ([[descriptionDict objectForKey:@"SoftwareUpdateUI"] boolValue] == YES)
        SoftwareUpdateUIClass = [OFBundledClass createBundledClassWithName:itemName bundle:bundle description:descriptionDict];
    // should there be some sort of precendence rule here?
}


// NSMenuValidation

- (BOOL)validateMenuItem:(NSMenuItem *)item;
{
    SEL action;

    action = [item action];
    if (action == @selector(toggleInspectorPanel:)) {
        if (![OAInspector isInspectorVisible]) {
            [item setTitle:NSLocalizedStringFromTableInBundle(@"Show Info", @"OmniAppKit", [self bundle], "show the info panel")];
        } else {
            [item setTitle:NSLocalizedStringFromTableInBundle(@"Hide Info", @"OmniAppKit", [self bundle], "hide the info panel")];
        }
        return YES;
    }

    return [super validateMenuItem:item];
}

@end

@implementation OAApplication (Private)

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
        NSMenuItem *currentItem;

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
    int item;
    
    menu = _NSGetCarbonMenu(aMenu);
    aRange.location++; // Carbon menu indices include the menu itself at index 0:  skip past it
    for (item = aRange.location; item < aRange.location + aRange.length; item++)
        ChangeMenuItemAttributes(menu, item, kMenuItemAttrDynamic, 0);
}

+ (void)_activateFontsFromAppWrapper;
{
    NSString *fontsDirectory;
    FSRef myFSRef;
    FSSpec myFSSpec;

    fontsDirectory = [[[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Fonts"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fontsDirectory])
        if (FSPathMakeRef([fontsDirectory fileSystemRepresentation], &myFSRef, NULL) == noErr)
            if (FSGetCatalogInfo(&myFSRef, kFSCatInfoNone, NULL, NULL, &myFSSpec, NULL) == noErr)
                FMActivateFonts(&myFSSpec, NULL, NULL, kFMLocalActivationContext);
}

@end
