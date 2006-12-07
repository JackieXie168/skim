// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniAppKit/OAInspector.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import "NSBundle-OAExtensions.h"
#import "NSImage-OAExtensions.h"
#import "OAInspectorButtonCell.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Inspector.subproj/OAInspector.m,v 1.70 2003/03/27 07:38:12 rick Exp $")

@interface OAInspector (Private)
- (void)_showInspector;
- (void)_hideInspector;
- (void)_updateInspector;
- (void)_inspectMainWindow;
- (void)_inspectWindow:(NSWindow *)window;
- (void)_recalculateInspectorsAndInspectWindow;
- (void)_selectionMightHaveChangedNotification:(NSNotification *)notification;
- (void)_inspectWindowNotification:(NSNotification *)notification;
- (void)_uninspectWindowNotification:(NSNotification *)notification;
- (void)loadInterface;
- (void)morphViews:(NSMutableArray *)oldViews toViews:(NSArray *)newViews andResizeWindow:(BOOL)resizeWindow;
@end


NSString *OAInspectorSelectionDidChangeNotification = @"OAInspectorSelectionDidChangeNotification";
NSString *OAInspectorShowInspectorDefaultKey = @"OAShowInspector";

static NSString *windowFrameSaveName = @"Info";

static OAInspector *sharedInspector = nil;
static id multipleSelectionObject;
static NSMutableDictionary *registeredInspectors = nil;
static NSMutableArray *orderedInspectors = nil;
static NSMutableDictionary *classForInspectorNamed = nil;
static NSImage *_expandedImage, *_collapsedImage;
static BOOL simpleInspectorMode = YES;
static NSTimeInterval morphInterval;

@implementation OAInspector

+ (void)setSimpleInspectorMode:(BOOL)yn;
{
    simpleInspectorMode = yn;
}

+ (void)initialize;
{
    static BOOL initialized = NO;
    NSBundle *myBundle;

    [super initialize];
    if (initialized)
        return;
    initialized = YES;

    // Allocate shared instance on first messsage to class.
    registeredInspectors = [[NSMutableDictionary alloc] init];
    orderedInspectors = [[NSMutableArray alloc] init];
    classForInspectorNamed = [[NSMutableDictionary alloc] init];
    multipleSelectionObject = [[NSObject alloc] init];
    myBundle = [self bundle];
    _expandedImage = [[NSImage imageNamed:@"OAExpanded" inBundle:myBundle] retain];
    _collapsedImage = [[NSImage imageNamed:@"OACollapsed" inBundle:myBundle] retain];
    morphInterval = /* Animations ? 0.20 : */ 0.0;
}

+ (void)didLoad;
{
    // Allows us to bring up the Inspector panel if it was up when the app closed previously.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controllerStartRunning:) name:NSApplicationDidFinishLaunchingNotification object:nil];
}

+ (void)controllerStartRunning:(NSNotification *)notification
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:OAInspectorShowInspectorDefaultKey])
        [self showInspector];
}

static NSComparisonResult sortByDisplayOrder(id a, id b, void *context)
{
    int aOrder = [a displayOrder];
    int bOrder = [b displayOrder];
    
    if (aOrder < bOrder)
        return NSOrderedAscending;
    else if (aOrder > bOrder)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

+ (void)registerInspector:(id <OAInspector>)inspector forClass:(Class)aClass;
{
    [registeredInspectors setObject:inspector forKey:aClass];
        
    if ([inspector respondsToSelector:@selector(displayOrder)]) {
        [classForInspectorNamed setObject:aClass forKey:[inspector inspectorName]];
        [orderedInspectors addObject:inspector];
        [orderedInspectors sortUsingFunction:sortByDisplayOrder context:nil];
    }
}

+ (OAInspector *)sharedInspector;
{
    if (!sharedInspector)
        sharedInspector = [[self alloc] init];
    return sharedInspector;
}

+ (BOOL)isInspectorVisible;
{
    return [[self sharedInspector] isInspectorVisible];
}

+ (void)showInspector
{
    [[self sharedInspector] _showInspector];
}

+ (void)hideInspector;
{
    [[self sharedInspector] _hideInspector];
}

+ (void)updateInspector
{
    [[self sharedInspector] _updateInspector];
}

+ (id)multipleSelectionObject;
{
    return multipleSelectionObject;
}

// Init

- init
{
    [super init];

    isOnScreen = NO;
    objectsByClass = [[NSMutableDictionary alloc] init];
    buttonsForInspectors = [[NSMutableDictionary alloc] init];
    return self;
}

- (id <OAInspectableController, NSObject>)currentInspectableController;
{
    return currentInspectableController;
}

- (id)inspectedObject;
{
    return [inspectedObjects count] ? [inspectedObjects objectAtIndex:0] : nil;
}

- (NSArray *)inspectedObjects;
{
    return inspectedObjects;
}

- (BOOL)isInspectorVisible
{
    return isOnScreen;
}

// NSWindow delegate methods.

- (void)windowWillClose:(NSNotification *)notification;
{
    NSNotificationCenter *center;

    // Make sure we end editing on anything we're inspecting before letting the window close
    [inspectorWindow makeFirstResponder:inspectorWindow];

    // Unsubscribe for the notifications we signed up for in -_showInspector
    center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:NSWindowDidBecomeMainNotification object:nil];
    [center removeObserver:self name:OAInspectorSelectionDidChangeNotification object:nil];

    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:OAInspectorShowInspectorDefaultKey];
    
    [inspectedObjects release];
    inspectedObjects = nil;
    
    [orderedInspectors makeObjectsPerformSelector:@selector(inspectObject:) withObject:nil];
    [activeInspector inspectObject:nil];
    activeInspector = nil;
    isOnScreen = NO;
}

- (void)windowDidResignKey:(NSNotification *)notification;
{
    [inspectorWindow makeFirstResponder:inspectorWindow];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)aWindow;
{
    NSWindow *window;
    NSResponder *nextResponder;
    NSUndoManager *undoManager = nil;

    window = [NSApp mainWindow];
    nextResponder = [window firstResponder];
    if (nextResponder == nil)
        nextResponder = window;

    do {
        if ([nextResponder respondsToSelector:@selector(undoManager)])
            undoManager = [nextResponder undoManager];
        else if ([nextResponder respondsToSelector:@selector(delegate)] && [[(id)nextResponder delegate] respondsToSelector:@selector(undoManager)])
            undoManager = [[(id)nextResponder delegate] undoManager];
        nextResponder = [nextResponder nextResponder];
    } while (nextResponder && !undoManager);
    
    return undoManager;
}

// View notification

- (void)inspectorViewFrameDidChange:(NSNotification *)notification;
{
    if (!isMorphingViews)
        [self morphViews:inspectorViews toViews:inspectorViews andResizeWindow:YES];
}

@end


//
// Private API.
//

@implementation OAInspector (Private)

- (void)_showInspector;
{
    NSNotificationCenter *defaultNotificationCenter;

    if (isOnScreen) {
        [inspectorWindow makeKeyAndOrderFront:nil];
        return;
    }

    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:OAInspectorShowInspectorDefaultKey];

    if (!inspectorWindow)
        [self loadInterface];

    // While the Inspector is visible, watch for any window to become main.  When that happens, determine if that window's delegate responds to the OAInspectableControllerProtocol, and act accordingly.
    defaultNotificationCenter = [NSNotificationCenter defaultCenter];
    [defaultNotificationCenter addObserver:self selector:@selector(_inspectWindowNotification:) name:NSWindowDidBecomeMainNotification object:nil];
    [defaultNotificationCenter addObserver:self selector:@selector(_uninspectWindowNotification:) name:NSWindowDidResignMainNotification object:nil];
    [defaultNotificationCenter addObserver:self selector:@selector(_selectionMightHaveChangedNotification:) name:OAInspectorSelectionDidChangeNotification object:nil];


    // Since we were just asked to be shown, jumpstart ourselves by inspecting the main window.
    isOnScreen = YES; // Otherwise, _inspectMainWindow will short-circuit
    [self _inspectMainWindow];
    [inspectorWindow makeKeyAndOrderFront:nil];
}

- (void)_hideInspector;
{
    if (!isOnScreen) {
        return;
    }

    [inspectorWindow performClose:nil];
}

// DON'T Make ourselves key here
- (void)_updateInspector;
{
    if (!isOnScreen)
        [self _showInspector];
    else
        [self _inspectMainWindow];
}

- (void)_inspectMainWindow;
{
    [self _inspectWindow:[NSApp mainWindow]];
}

- (void)_inspectWindow:(NSWindow *)window;
{
    if (!isInspectionQueued) {
        [self queueSelector:@selector(_recalculateInspectorsAndInspectWindow)];
        isInspectionQueued = YES;
    }
    lastWindowAskedToInspect = window;
}

- (void)_getInspectedObjects;
{
    NSWindow *window;
    NSResponder *nextResponder;
    id <OAInspectableController> inspectableController;

    window = lastWindowAskedToInspect;
        
    // Get the controller and inspected objects...
    nextResponder = [window firstResponder];
    if (nextResponder == nil)
        nextResponder = window;
    inspectableController = nil;
    do {
        if ([nextResponder conformsToProtocol:@protocol(OAInspectableController)])
            inspectableController = (id)nextResponder;
        else if ([nextResponder respondsToSelector:@selector(delegate)] && [[(id)nextResponder delegate] conformsToProtocol:@protocol(OAInspectableController)])
            inspectableController = [(id)nextResponder delegate];
        else
            nextResponder = [nextResponder nextResponder];
    } while (nextResponder != nil && inspectableController == nil);

    [currentInspectableController release];
    [inspectedObjects release];

    if (inspectableController) {
        currentInspectableController = [inspectableController retain];
        if ([inspectableController respondsToSelector:@selector(inspectedObjects)]) {
            inspectedObjects = [[(id <OAComplexInspectableController>)inspectableController inspectedObjects] retain];
        } else {
            id object = [inspectableController inspectedObject];
            
            if (object)
                inspectedObjects = [[NSArray arrayWithObject:object] retain];
            else
                inspectedObjects = nil;
        }
    } else {
        currentInspectableController = nil;
        inspectedObjects = nil;
    }
}

- (void)_setupSimpleInspector;
{
    id object;
    id <OAInspector> inspector;
    NSView *view;
    
    if ([inspectedObjects count]) {
        object = [inspectedObjects objectAtIndex:0];
        inspector = [registeredInspectors objectForKey:[object class]];
    } else {
        object = nil;
        inspector = nil;
    }
    
    if (inspector != activeInspector) {
        [activeInspector inspectObject:nil];
    }
    activeInspector = inspector;
    
    if (activeInspector) {
        view = [inspector inspectorView];
        [inspectorWindow setTitle:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ Info", @"OmniAppKit", [OAInspector bundle], "info panel title format"), [activeInspector inspectorName]]];
    } else {
        if (object == multipleSelectionObject)
            view = multiInspectorBox;
        else
            view = noInspectorBox;
        [inspectorWindow setTitle:NSLocalizedStringFromTableInBundle(@"Info", @"OmniAppKit", [OAInspector bundle], "generic title of inspector panel if what you are inspecting has no title of its own")];
    }
    
    [view setFrame:[[inspectorWindow contentView] frame]];
            
    if ([inspectorViews count]) {
        NSView *old = [inspectorViews objectAtIndex:0];
        if (old != view) {
            [old removeFromSuperview];
            [[inspectorWindow contentView] addSubview:view];
        }
    } else
        [[inspectorWindow contentView] addSubview:view];
        
    [inspectorViews removeAllObjects];
    [inspectorViews addObject:view];
    [activeInspector inspectObject:object];
}

- (void)_buildComplexInspectorViews;
{
    int inspectorIndex, inspectorCount;
    id <OAInspector> inspector;
    NSString *name;
    NSArray *active;

    expandedInspectors = [[NSMutableSet alloc] init];    
    if ((active = [[NSUserDefaults standardUserDefaults] arrayForKey:@"OAExpandedInspectors"])) {
        [expandedInspectors addObjectsFromArray:active];
    } else {
        // if user has no preference, open first inspector...
        [expandedInspectors addObject:[[orderedInspectors objectAtIndex:0] inspectorName]];
    }

    [inspectorWindow setTitle:NSLocalizedStringFromTableInBundle(@"Info", @"OmniAppKit", [OAInspector bundle], "generic title of inspector panel if what you are inspecting has no title of its own")];

    inspectorCount = [orderedInspectors count];
    for (inspectorIndex = 0; inspectorIndex < inspectorCount; inspectorIndex++) {
        NSView *button;
        NSButton *realButton;

        inspector = [orderedInspectors objectAtIndex:inspectorIndex];
        name = [inspector inspectorName];
        realButton = [[NSButton alloc] initWithFrame:NSMakeRect(2.0, 1.0, 175.0, 15.0)];
        ((OAInspector *)[realButton cell])->isa = [OAInspectorButtonCell class];
        [realButton setTitle:name];
        [realButton setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
       // [[realButton cell] setControlSize:NSSmallControlSize];
        [[realButton cell] setGradientType:NSGradientConvexStrong];
        [realButton setButtonType:NSMomentaryLight];
        if ([expandedInspectors member:name])
            [realButton setImage:_expandedImage];
        else
            [realButton setImage:_collapsedImage];
        [realButton setImagePosition:NSImageLeft];
        [realButton setAlignment:NSLeftTextAlignment];
        [realButton setBezelStyle:NSShadowlessSquareBezelStyle];
        [realButton setTarget:self];
        [realButton setAction:@selector(_toggleActiveInspector:)];
        [realButton setTag:inspectorIndex];
        [realButton sizeToFit];
        [realButton setFrameSize:NSMakeSize(175.0, 17.0)];
        [realButton setAutoresizingMask: NSViewWidthSizable];
        button = [[NSView alloc] initWithFrame:NSInsetRect([realButton frame], -2.0, -1.0)];
        [button addSubview:realButton];
        [buttonsForInspectors setObject:button forKey:name];
        [realButton release];
        [button release];
            
        // Add the button to the view array...
        [inspectorViews addObject:button];
                        
        // If the inspector is expanded, add it to the view array...
        if ([expandedInspectors member:name]) {
            NSView *view = [inspector inspectorView];
            
            [view setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin]; // make sure it isn't vertically resizable
            [inspectorViews addObject:view];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inspectorViewFrameDidChange:) name:NSViewFrameDidChangeNotification object:view];      
        }
    }
}

- (void)_recalculateInspectorsAndInspectWindow;
{
    unsigned int index, count;
    unsigned int inspectorIndex, inspectorCount;
    id <OAInspector> inspector;
    NSString *name;
    NSMutableArray *list;
    
    isInspectionQueued = NO;
    [self _getInspectedObjects];

    if (simpleInspectorMode) {
        [self _setupSimpleInspector];
        return;
    }

    if (![inspectorViews count]) {
        [self _buildComplexInspectorViews];
        [self morphViews:[NSArray array] toViews:inspectorViews andResizeWindow:YES];
    }

    // Sort inspected objects by their class
    [objectsByClass removeAllObjects];
    count = [inspectedObjects count];
    for (index = 0; index < count; index++) {
        id object;

        object = [inspectedObjects objectAtIndex:index];
        list = [objectsByClass objectForKey:[object class]];
        if (!list) {
            list = [[NSMutableArray alloc] init];
            [objectsByClass setObject:list forKey:[object class]];
            [list release];
        }
        [list addObject:object];
    }
    
    // tell the inspectors to inspect the appropriate objects 
    inspectorCount = [orderedInspectors count];
    for (inspectorIndex = 0; inspectorIndex < inspectorCount; inspectorIndex++) {
        inspector = [orderedInspectors objectAtIndex:inspectorIndex];
        name = [inspector inspectorName];
        list = [objectsByClass objectForKey:[classForInspectorNamed objectForKey:name]];
        
        if (list) {
            if ([expandedInspectors member:name]) {
                if ([inspector respondsToSelector:@selector(handlesMultipleSelections)] && [(id)inspector handlesMultipleSelections])
                    [inspector inspectObject:list];
                else
                    [inspector inspectObject:[list objectAtIndex:0]];
            } 
        } else {
            [inspector inspectObject:nil];
        }
    }
}

- (void)_selectionMightHaveChangedNotification:(NSNotification *)notification;
{
    [self _inspectMainWindow];
}

- (void)_inspectWindowNotification:(NSNotification *)notification;
{
    [self _inspectWindow:(NSWindow *)[notification object]];
}

- (void)_uninspectWindowNotification:(NSNotification *)notification;
{
    [self _inspectWindow:nil];
}

- (void)_toggleActiveInspector:sender;
{
    id <OAInspector> inspector;
    NSString *name;
    NSMutableArray *newViews;
    NSArray *list;
    NSView *view;
    
    inspector = [orderedInspectors objectAtIndex:[sender tag]];
    name = [inspector inspectorName];
    newViews = [[NSMutableArray alloc] initWithArray:inspectorViews];
    
    if (![expandedInspectors member:name]) {
        [expandedInspectors addObject:name];
        view = [inspector inspectorView];
        [view setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin]; // make sure it isn't vertically resizable
        [newViews insertObject:[inspector inspectorView] atIndex:([inspectorViews indexOfObject:[sender superview]] + 1)];
        list = [objectsByClass objectForKey:[classForInspectorNamed objectForKey:name]];
        if ([inspector respondsToSelector:@selector(handlesMultipleSelections)] && [(id)inspector handlesMultipleSelections])
            [inspector inspectObject:list];
        else
            [inspector inspectObject:[list objectAtIndex:0]]; 
        [sender setImage:_expandedImage];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inspectorViewFrameDidChange:) name:NSViewFrameDidChangeNotification object:view];      
    } else {
        [expandedInspectors removeObject:name];
        view = [inspector inspectorView];
        [newViews removeObject:view];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:view];      
        [inspector inspectObject:nil];
        [sender setImage:_collapsedImage];
        list = [objectsByClass objectForKey:[classForInspectorNamed objectForKey:name]];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[expandedInspectors allObjects] forKey:@"OAExpandedInspectors"];
    [inspectorWindow makeFirstResponder:inspectorWindow];
    [self morphViews:inspectorViews toViews:newViews andResizeWindow:YES];
    [inspectorViews release];
    inspectorViews = newViews;
    
    [originallyExpandedInspectors release];
    originallyExpandedInspectors = nil;
}

- (void)loadInterface;
{    
    inspectorViews = [[NSMutableArray alloc] init];

    // This is from a category in NSBundle-OAExtensions; it raises an exception if the nib can't be loaded
    [[OAInspector bundle] loadNibNamed:@"OAInspector.nib" owner:self];

    if (simpleInspectorMode) {
        NSView *view = [inspectorWindow contentView];
        [view setAutoresizesSubviews:YES];
        [view setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
    } else {
        //[inspectorWindow setShowsResizeIndicator:NO];
        [inspectorWindow setMinSize:NSMakeSize([inspectorWindow minSize].width, 1.0)];
    }
    [inspectorWindow setFrameUsingName:windowFrameSaveName];
    [inspectorWindow setFrameAutosaveName:windowFrameSaveName];
}

#define MIN_MORPH_DIST (10.0)
#define TOP_BOTTOM_WINDOW_BORDER (1.0)

- (void)morphViews:(NSMutableArray *)oldViews toViews:(NSArray *)newViews andResizeWindow:(BOOL)resizeWindow;
{
    float width;
    float oldHeight, newHeight;
    NSRect frame;
    NSRect *newLocations;
    NSView *view;
    NSMutableArray *additions;
    NSTimeInterval start, current, elapsed;
    int index, oldIndex;
    float delta, done;
    NSRect oldWindowRect, newWindowRect;
    
    isMorphingViews = YES;
    
    // Rip out old views that are no longer there
    index = [oldViews count];
    while (index--) {
        view = [oldViews objectAtIndex:index];
        if (![newViews containsObject:view]) {
            [oldViews removeObjectAtIndex:index];
            [view removeFromSuperview];
        }
    }
    
    // Setup
    oldWindowRect = [inspectorWindow frame];
    width = [[inspectorWindow contentView] frame].size.width;
    newLocations = alloca(sizeof(NSRect) * [oldViews count]);
    additions = [NSMutableArray array];
    oldHeight = [[inspectorWindow contentView] frame].size.height;
    
    // Split the new views into additions and existing views and set their final locations
    newHeight = TOP_BOTTOM_WINDOW_BORDER;
    index = [newViews count];
    while (index--) {
        view = [newViews objectAtIndex:index];
        frame = [view frame];
        
        if ((oldIndex = [oldViews indexOfObject:view]) == NSNotFound) {
            [additions addObject:view];
            [view setFrame:NSMakeRect(0, newHeight, width, frame.size.height)];
        } else {
            newLocations[oldIndex] = NSMakeRect(0, newHeight, width, frame.size.height);
        }
        newHeight += frame.size.height;
    }
    newHeight += TOP_BOTTOM_WINDOW_BORDER;
    
    delta = newHeight - oldHeight;
    newWindowRect.origin.x = oldWindowRect.origin.x;
    newWindowRect.origin.y = oldWindowRect.origin.y - delta;
    newWindowRect.size.width = oldWindowRect.size.width;
    newWindowRect.size.height = oldWindowRect.size.height + delta;
    
    // If nothing interesting is going on, just jump to the end state
    if ((ABS(delta) > MIN_MORPH_DIST) && [inspectorWindow isVisible]) {
        done = 0.0;
        start = [NSDate timeIntervalSinceReferenceDate];    
        while (YES) {
            float  ratio;
            float  doNow, amount;
            NSRect stepFrame;
            
            current = [NSDate timeIntervalSinceReferenceDate];
            elapsed = current - start;
            if (elapsed >= morphInterval)
                break;
    
            ratio = elapsed / morphInterval;
            doNow = floor(ratio * delta);
            amount = doNow - done;
            
            // Move views...
            index = [oldViews count];
            while (index--) {
                float difference;
                
                view = [oldViews objectAtIndex:index];
                frame = [view frame];
                difference = newLocations[index].origin.y - frame.origin.y;
                if (difference > 0) {
                    frame.origin.y += MIN(amount, difference);
                    [view setFrame:frame];
                } else if (difference < 0) {
                    frame.origin.y += MAX(amount, difference);
                    [view setFrame:frame];
                }
            }
            
            // Move windows...            
            stepFrame.origin.x = oldWindowRect.origin.x;
            stepFrame.origin.y = oldWindowRect.origin.y - doNow;
            stepFrame.size.width = oldWindowRect.size.width;
            stepFrame.size.height = oldWindowRect.size.height + doNow;
            [inspectorWindow setFrame:stepFrame display:YES];
            done = doNow;
        }
    }
    
    // Set final positions and add new views
    index = [oldViews count];
    while (index--) {
        view = [oldViews objectAtIndex:index];
        [view setFrame:newLocations[index]];
    }
    index = [additions count];
    while (index--) {
        [[inspectorWindow contentView] addSubview:[additions objectAtIndex:index]];
    }
    
    // Make sure we don't end up with round off errors   
    if (resizeWindow)
        [inspectorWindow setFrame:newWindowRect display:YES];
        
    isMorphingViews = NO;
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
    NSRect currentFrame;
    NSSize result;
    float additionalSpace, useSpace;
    float viewHeight;
    int index, count, buttonViewIndex;
    id <OAInspector> inspector;
    NSString *name;
    NSView *view, *button;
    NSMutableArray *newViews;
    NSArray *list;
    
    if (simpleInspectorMode || ![inspectorViews count])
        return proposedFrameSize;
        
    if (!originallyExpandedInspectors) {
        originallyExpandedInspectors = [expandedInspectors mutableCopy];
    }
    
    currentFrame = [sender frame];
    result = currentFrame.size;
    additionalSpace = proposedFrameSize.height - currentFrame.size.height;
    useSpace = 0.0;
    newViews = [NSMutableArray arrayWithArray:inspectorViews];
    count = [orderedInspectors count];

    if (additionalSpace > 0) {
        for (index = 0; index < count; index++) {
            inspector = [orderedInspectors objectAtIndex:index];
            name = [inspector inspectorName];
            if ([expandedInspectors member:name]) 
                continue;

            view = [inspector inspectorView];
            viewHeight = [view frame].size.height;
            if ((viewHeight / 2.0) <= additionalSpace) {
                button = [buttonsForInspectors objectForKey:name];
                buttonViewIndex = [newViews indexOfObject:button];
                [expandedInspectors addObject:name];                
                [[[button subviews] objectAtIndex:0] setImage:_expandedImage];
                [newViews insertObject:view atIndex:buttonViewIndex+1];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inspectorViewFrameDidChange:) name:NSViewFrameDidChangeNotification object:view];      
                list = [objectsByClass objectForKey:[classForInspectorNamed objectForKey:name]];
                if ([inspector respondsToSelector:@selector(handlesMultipleSelections)] && [(id)inspector handlesMultipleSelections])
                    [inspector inspectObject:list];
                else
                    [inspector inspectObject:[list objectAtIndex:0]]; 
                useSpace += viewHeight;
                additionalSpace -= viewHeight;
            } else
                break;
        }
    } else {
        BOOL allCollapsed;
        
        allCollapsed = YES;
        additionalSpace = -additionalSpace;
        
        // first run through, skipping any originally expanded inspectors
        for (index = count - 1; index >= 0; index--) {
            inspector = [orderedInspectors objectAtIndex:index];
            name = [inspector inspectorName];
            if ([originallyExpandedInspectors member:name] || ![expandedInspectors member:name]) 
                continue;

            view = [inspector inspectorView];
            viewHeight = [view frame].size.height;
            if ((viewHeight / 2.0) < additionalSpace) {
                button = [buttonsForInspectors objectForKey:name];
                buttonViewIndex = [newViews indexOfObject:button];
                [expandedInspectors removeObject:name];
                [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:view];
                [[[button subviews] objectAtIndex:0] setImage:_collapsedImage];
                [newViews removeObjectAtIndex:buttonViewIndex+1];
                [inspector inspectObject:nil];
                useSpace -= viewHeight;
                additionalSpace -= viewHeight;
            } else {
                allCollapsed = NO;
                break;
            }
        }
        
        // then run through a second time, allowing the collapse of originally expanded inspectors, but only if all others are collapsed
        if (allCollapsed) {
            for (index = count - 1; index >= 0; index--) {
                inspector = [orderedInspectors objectAtIndex:index];
                name = [inspector inspectorName];
                if (![expandedInspectors member:name]) 
                    continue;
    
                view = [inspector inspectorView];
                viewHeight = [view frame].size.height;
                if ((viewHeight / 2.0) < additionalSpace) {
                    button = [buttonsForInspectors objectForKey:name];
                    buttonViewIndex = [newViews indexOfObject:button];
                    [expandedInspectors removeObject:name];                
                    [originallyExpandedInspectors removeObject:name];
                    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:view];
                    [[[button subviews] objectAtIndex:0] setImage:_collapsedImage];
                    [newViews removeObjectAtIndex:buttonViewIndex+1];
                    [inspector inspectObject:nil];
                    useSpace -= viewHeight;
                    additionalSpace -= viewHeight;
                } else
                    break;
            }
        }
    }
    
    if (useSpace != 0.0) {
        result.height = currentFrame.size.height + useSpace;
        [self morphViews:inspectorViews toViews:newViews andResizeWindow:NO];
        [inspectorViews release];
        inspectorViews = [newViews retain];
    }
    return result;
}

@end

