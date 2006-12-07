// Copyright 1997-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <AppKit/NSView.h>

#import <AppKit/NSNibDeclarations.h> // For IBAction
#import <OmniAppKit/OAShelfViewDelegateProtocol.h>
#import <OmniAppKit/OAShelfViewDragSupportProtocol.h>
#import <OmniAppKit/OAShelfViewFormatterProtocol.h>

@class NSArray, NSMutableArray;

@interface OAShelfView : NSView 
{
    id <OAShelfViewDelegate> delegate;
    id <OAShelfViewDragSupport> dragSupport;
    id <OAShelfViewFormatter> formatter;
    id <NSObject> *contents;
    BOOL *selected;
    NSSize spaceSize;
    unsigned int spacesAcross, spacesDown, totalSpaces;
    NSPoint dragPoint;
    NSArray *draggingObjects;
    id <NSObject> dragOutObject;
    struct {
	unsigned int moveOnDrag:1;
    } flags;
}

// setup
- (void)setSpaceSize:(NSSize)size;
- (void)setDelegate:(id <OAShelfViewDelegate>)aDelegate;
- (void)setFormatter:(id <OAShelfViewFormatter>)aFormatter;
- (void)setDragSupport:(id <OAShelfViewDragSupport>)aDragSupport;
- (void)setMoveOnDrag:(BOOL)newMoveOnDrag;
- (void)setEntry:(id <NSObject>)anEntry selected:(BOOL)isSelected atRow:(unsigned int)row andColumn:(unsigned int)column;
- (void)addEntries:(NSArray *)entries selected:(BOOL)isSelected atRow:(unsigned int)row andColumn:(unsigned int)column;

- (BOOL)moveOnDrag;
- (NSSize)spaceSize;
- (NSMutableArray *)selection;
- (id <OAShelfViewFormatter>)formatter;
- (id <OAShelfViewDelegate>)delegate;

- (IBAction)selectAll:(id)sender;
- (IBAction)cut:(id)sender;
- (IBAction)copy:(id)sender;
- (IBAction)paste:(id)sender;
- (IBAction)delete:(id)sender;

// Get state out for saving

- (unsigned int)rows;
- (unsigned int)columns;
- (id <NSObject>)entryAtRow:(unsigned int)aRow column:(unsigned int)aColumn;
- (BOOL)selectedAtRow:(unsigned int)aRow column:(unsigned int)aColumn;

@end
