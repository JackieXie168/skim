//
//  BDSKErrorEditor.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 8/21/06.
/*
 This software is Copyright (c) 2006,2007
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

#import "BDSKErrorEditor.h"
#import <OmniBase/assertions.h>
#import <OmniAppKit/OAFindControllerTargetProtocol.h>
#import "BDSKErrorManager.h"
#import "NSTextView_BDSKExtensions.h"
#import "NSString_BDSKExtensions.h"
#import "NSFileManager_BDSKExtensions.h"
#import "BibDocument.h"
#import "BibAppController.h"
#import "BDSKStringEncodingManager.h"

@implementation BDSKErrorEditor

+ (void)initialize;
{
    OBINITIALIZE;
    [self setKeys:[NSArray arrayWithObjects:@"manager", nil] triggerChangeNotificationsForDependentKey:@"displayName"];
}

- (id)initWithFileName:(NSString *)aFileName pasteDragData:(NSData *)aData;
{
    if(self = [super init]){
        manager = nil;
        fileName = [aFileName retain];
        data = [aData copy];
        isPasteDrag = NO;
        enableSyntaxHighlighting = YES;
        invalidSyntaxHighlightMark = NSNotFound;
        changeCount = 0;
    }
    return self;
}

- (id)initWithFileName:(NSString *)aFileName;
{
    self = [self initWithFileName:aFileName pasteDragData:nil];
    return self;
}

- (id)initWithPasteDragData:(NSData *)aData;
{
    if(self = [self initWithFileName:nil pasteDragData:aData]){
        isPasteDrag = YES;
    }
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [fileName release];
    [data release];
    [super dealloc];
}

- (NSString *)windowNibName;
{
    return @"BDSKErrorEditWindow";
}

- (void)awakeFromNib;
{
    // set the frame from prefs first, or setFrameAutosaveName: will overwrite the prefs with the nib values if it returns NO
    [[self window] setFrameUsingName:@"Edit Source Window"];
    // we should only cascade windows if we have multiple documents open; bug #1299305
    // the default cascading does not reset the next location when all windows have closed, so we do cascading ourselves
    static NSPoint nextWindowLocation = {0.0, 0.0};
    [self setShouldCascadeWindows:NO];
    if ([[self window] setFrameAutosaveName:@"Edit Source Window"]) {
        NSRect windowFrame = [[self window] frame];
        nextWindowLocation = NSMakePoint(NSMinX(windowFrame), NSMaxY(windowFrame));
    }
    nextWindowLocation = [[self window] cascadeTopLeftFromPoint:nextWindowLocation];
    
    if(isPasteDrag)
        [reopenButton setEnabled:NO];
    
    [[textView textStorage] setDelegate:self];
    [syntaxHighlightCheckbox setState:NSOnState];
    
    [self loadFile:self];
    
    NSString *prefix = (isPasteDrag) ? NSLocalizedString(@"Edit Paste/Drag", @"Partial window title") : NSLocalizedString(@"Edit Source", @"Partial window title");
    
    OBASSERT(fileName);
    [[self window] setRepresentedFilename:fileName];
	[[self window] setTitle:[NSString stringWithFormat:@"%@: %@", prefix, [manager displayName]]];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleSelectionDidChangeNotification:)
												 name:NSTextViewDidChangeSelectionNotification
											   object:textView];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleUndoManagerChangeUndoneNotification:)
												 name:NSUndoManagerDidUndoChangeNotification
											   object:[[self window] undoManager]];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleUndoManagerChangeDoneNotification:)
												 name:NSUndoManagerDidRedoChangeNotification
											   object:[[self window] undoManager]];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleUndoManagerChangeDoneNotification:)
												 name:NSUndoManagerWillCloseUndoGroupNotification
											   object:[[self window] undoManager]];
}

- (void)windowWillClose:(NSNotification *)notification{
    if ([manager sourceDocument] == nil)
        [manager removeEditor:self];
}

#pragma mark Accessors

- (BDSKErrorManager *)manager;
{
    return manager;
}

- (void)setManager:(BDSKErrorManager *)newManager;
{
    if(manager != newManager){
        if(manager)
            [manager removeObserver:self forKeyPath:@"displayName"];
        manager = newManager;
        if(manager)
            [manager addObserver:self forKeyPath:@"displayName" options:0 context:NULL];
    }
}

- (NSString *)fileName;
{
    return fileName;
}

- (void)setFileName:(NSString *)newFileName;
{
    if (fileName != newFileName) {
        [fileName release];
        fileName = [newFileName retain];
    }
}

- (NSString *)displayName;
{
    NSString *displayName = [manager displayName];
    return (isPasteDrag) ? [NSString stringWithFormat:@"[%@]", displayName] : displayName;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if(object == manager && [keyPath isEqualToString:@"displayName"]){
        [self willChangeValueForKey:@"displayName"];
        [self didChangeValueForKey:@"displayName"];
        
        NSString *prefix = (isPasteDrag) ? NSLocalizedString(@"Edit Paste/Drag", @"Partial window title") : NSLocalizedString(@"Edit Source", @"Partial window title");
        [[self window] setTitle:[NSString stringWithFormat:@"%@: %@", prefix, [manager displayName]]];
    }
}

- (NSData *)pasteDragData;
{
    return data;
}

- (BOOL)isPasteDrag;
{
    return isPasteDrag;
}

#pragma mark Editing

- (id <OAFindControllerTarget>)omniFindControllerTarget { return textView; }

- (IBAction)loadFile:(id)sender{
    BibDocument *document = [manager sourceDocument];
    
    if(fileName == nil){
        OBASSERT(data != nil && document != nil);
        [self setFileName:[[NSApp delegate] temporaryFilePath:[document displayName] createDirectory:NO]];
        [data writeToFile:fileName atomically:YES];
        [data release];
        data = nil;
    }
    
    NSFileManager *dfm = [NSFileManager defaultManager];
    if (!fileName) return;
    
    NSStringEncoding encoding = [manager documentStringEncoding];
        
    if ([dfm fileExistsAtPath:fileName]) {
        NSString *fileStr = [[NSString alloc] initWithContentsOfFile:fileName encoding:encoding guessEncoding:YES];;
        if(!fileStr)
            fileStr = [[NSString alloc] initWithString:NSLocalizedString(@"Unable to determine the correct character encoding.", @"Message when unable to determine encoding for error editor")];
        [textView setString:fileStr];
        [fileStr release];
    }
    if (changeCount != 0)
        [[self window] setDocumentEdited:NO];
	[[[self window] undoManager] removeAllActions];
    changeCount = 0;
}

- (IBAction)reopenDocument:(id)sender{
    NSString *expandedFileName = [[self fileName] stringByExpandingTildeInPath];
    
    expandedFileName = [[NSFileManager defaultManager] uniqueFilePath:expandedFileName createDirectory:NO];
    
    // write this out with the user's default encoding, so the openDocumentWithContentsOfFile is more likely to succeed
    NSData *fileData = [[textView string] dataUsingEncoding:[BDSKStringEncodingManager defaultEncoding] allowLossyConversion:NO];
    [fileData writeToFile:expandedFileName atomically:YES];
    
    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:expandedFileName display:YES];
}

- (IBAction)changeSyntaxHighlighting:(id)sender;
{
    enableSyntaxHighlighting = !enableSyntaxHighlighting;
        
    NSTextStorage *textStorage = [textView textStorage];
    if(enableSyntaxHighlighting == NO){
        [textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, [textStorage length])];
    }else{
        invalidSyntaxHighlightMark = NSNotFound;
        [textStorage edited:NSTextStorageEditedAttributes range:NSMakeRange(0, [textStorage length]) changeInLength:0];
    }
}

- (IBAction)changeLineNumber:(id)sender{
    int lineNumber = [sender intValue];
    if (lineNumber > 0)
        [self gotoLine:lineNumber];
    else
        NSBeep();
}

- (void)gotoLine:(int)lineNumber{
    // we're not using getLineStart:end:contentsEnd:forRange: because btparse only recognized \n as a newline
    static NSCharacterSet *newlineCharacterSet = nil;
    
    if(newlineCharacterSet == nil)
        newlineCharacterSet = [[NSCharacterSet characterSetWithRange:NSMakeRange('\n', 1)] retain];
    
    int i = 0;
    NSString *string = [textView string];
    unsigned start = 0;
    unsigned end = 0;
    unsigned length = [string length];
    NSRange range;
    
    while (++i <= lineNumber) {
        start = end;
        range = [string rangeOfCharacterFromSet:newlineCharacterSet options:NSLiteralSearch range:NSMakeRange(start, length - start)];
        if (range.location == NSNotFound) {
            end = length;
            if (i < lineNumber)
                start = length;
            break;
        }
        end = NSMaxRange(range);
    }
    range.location = start;
    range.length = (end - start);
    [textView setSelectedRange:range];
    [textView scrollRangeToVisible:range];
}

- (void)handleSelectionDidChangeNotification:(NSNotification *)notification{
    static NSCharacterSet *newlineCharacterSet = nil;
    
    if(newlineCharacterSet == nil)
        newlineCharacterSet = [[NSCharacterSet characterSetWithRange:NSMakeRange('\n', 1)] retain];
    
    NSRange selectedRange = [textView selectedRange];
    
    int lineNumber = 0;
    NSString *string = [textView string];
    unsigned location = selectedRange.location;
    NSRange range = NSMakeRange(0, 0);
    
    while (range.location != NSNotFound) {
        ++lineNumber;
        range = [string rangeOfCharacterFromSet:newlineCharacterSet options:NSLiteralSearch range:NSMakeRange(NSMaxRange(range), location - NSMaxRange(range))];
    }
    
    [lineNumberField setIntValue:lineNumber];
    
    if(enableSyntaxHighlighting && invalidSyntaxHighlightMark < NSMaxRange(selectedRange))
        [[textView textStorage] edited:NSTextStorageEditedAttributes range:selectedRange changeInLength:0];
}

- (void)handleUndoManagerChangeUndoneNotification:(NSNotification *)notification;
{
    changeCount++;
    if(changeCount == 0) [[self window] setDocumentEdited:NO];
    if(changeCount == 1) [[self window] setDocumentEdited:YES];
}

- (void)handleUndoManagerChangeDoneNotification:(NSNotification *)notification;
{
    changeCount--;
    if(changeCount == 0) [[self window] setDocumentEdited:NO];
    if(changeCount == -1) [[self window] setDocumentEdited:YES];
}

#pragma mark Syntax highlighting

static inline Boolean isLeftBrace(UniChar ch) { return ch == '{'; }
static inline Boolean isRightBrace(UniChar ch) { return ch == '}'; }
static inline Boolean isDoubleQuote(UniChar ch) { return ch == '"'; }
static inline Boolean isAt(UniChar ch) { return ch == '@'; }
static inline Boolean isPercent(UniChar ch) { return ch == '%'; }
static inline Boolean isHash(UniChar ch) { return ch == '#'; }
static inline Boolean isBackslash(UniChar ch) { return ch == '\\'; }
static inline Boolean isCommentOrQuotedColor(NSColor *color) { return [color isEqual:[NSColor brownColor]] || [color isEqual:[NSColor grayColor]]; }

// extend the edited range of the textview to include the previous and next newline; including the previous/next delimiter is less reliable
- (NSRange)invalidatedRange:(NSRange)proposedRange{
    
    static NSCharacterSet *delimSet = nil;
    if(delimSet == nil)
         delimSet = [[NSCharacterSet characterSetWithCharactersInString:@"@{}\"%"] retain];
    
    NSTextStorage *textStorage = [textView textStorage];
    NSString *string = [textStorage string];
    
    // see if we need to extend the range; coloring won't change unless this is a delimiter
    if([string rangeOfCharacterFromSet:delimSet].length == 0)
        return proposedRange;
    
    NSCharacterSet *newlineSet = [NSCharacterSet newlineCharacterSet];
    
    unsigned start = MIN(proposedRange.location, invalidSyntaxHighlightMark);
    unsigned end = NSMaxRange(proposedRange);
    unsigned length = [string length];
    
    // quoted or commented text can have multiple lines
    do {
        start = [string rangeOfCharacterFromSet:newlineSet options:NSBackwardsSearch|NSLiteralSearch range:NSMakeRange(0, start)].location;
        if(start == NSNotFound)
            start = 0;
    } while (start > 0 && isCommentOrQuotedColor([textStorage attribute:NSForegroundColorAttributeName atIndex:start - 1 effectiveRange:NULL]));
        
    do {
        end = NSMaxRange([string rangeOfCharacterFromSet:newlineSet options:NSLiteralSearch range:NSMakeRange(end, length - end)]);
        if(end == NSNotFound)
            end = length;
    } while (end < length && isCommentOrQuotedColor([textStorage attribute:NSForegroundColorAttributeName atIndex:end effectiveRange:NULL]));
    
    return NSMakeRange(start, end - start);
}
    
#define SetColor(color, start, length) [textStorage addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(editedRange.location + start, length)];


- (void)textStorageDidProcessEditing:(NSNotification *)notification{
    
    if(enableSyntaxHighlighting == NO)
        return;
    
    NSCharacterSet *newlineSet = [NSCharacterSet newlineCharacterSet];
    
    NSTextStorage *textStorage = [notification object];    
    CFStringRef string = (CFStringRef)[textStorage string];
    CFIndex length = CFStringGetLength(string);
    
    NSRange editedRange = [textStorage editedRange];
    
    if(invalidSyntaxHighlightMark != NSNotFound && editedRange.location < invalidSyntaxHighlightMark)
        invalidSyntaxHighlightMark = MAX(invalidSyntaxHighlightMark + [textStorage changeInLength], editedRange.location);
    
    // see what range we should actually invalidate; if we're not adding any special characters, the default edited range is probably fine
    editedRange = [self invalidatedRange:editedRange];
    
    CFIndex cnt = editedRange.location;
    
    CFStringInlineBuffer inlineBuffer;
    CFStringInitInlineBuffer(string, &inlineBuffer, CFRangeMake(cnt, editedRange.length));
    
    SetColor([NSColor blackColor], 0, editedRange.length)
    
    // inline buffer only covers the edited range, starting from 0; adjust length to length of buffer
    length = editedRange.length;
    UniChar ch;
    CFIndex lbmark, atmark, percmark;
    
    NSColor *braceColor = [NSColor blueColor];
    NSColor *typeColor = [NSColor purpleColor];
    NSColor *quotedColor = [NSColor brownColor];
    NSColor *commentColor = [NSColor grayColor];
    NSColor *hashColor = [NSColor magentaColor];
    CFStringRef commentString = CFSTR("comment");
    
    CFIndex braceDepth = 0;
     
    // This is fairly crude; I don't think it's worthwhile to implement a full BibTeX parser here, since we need this to be fast (and it won't be used that often).
    // remember that cnt and length determine the index and length of the inline buffer, not the textStorage
    for(cnt = 0; cnt < length; cnt++){
        ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
        if(isAt(ch)){
            atmark = cnt;
            while(++cnt < length){
                ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
                if(isLeftBrace(ch)){
                    SetColor(braceColor, cnt, 1);
                    break;
                }
            }
            SetColor(typeColor, atmark, cnt - atmark);
            // in fact whitespace is allowed at the end of "comment", but harder to check
            if(cnt - atmark == 8 && CFStringCompareWithOptions(string, commentString, CFRangeMake(editedRange.location + atmark + 1, 7), kCFCompareCaseInsensitive) == kCFCompareEqualTo){
                braceDepth = 1;
                SetColor(braceColor, cnt, 1)
                lbmark = cnt + 1;
                while(++cnt < length){
                    if(isBackslash(ch)){ // ignore escaped braces
                        ch = 0;
                        continue;
                    }
                    ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
                    if(isRightBrace(ch)){
                        braceDepth--;
                        if(braceDepth == 0){
                            SetColor(braceColor, cnt, 1);
                            break;
                        }
                    } else if(isLeftBrace(ch)){
                        braceDepth++;
                    }
                }
                SetColor(commentColor, lbmark, cnt - lbmark);
            }
            // sneaky hack: don't rewind here, since cite keys don't have a closing brace (of course)
        }else if(isPercent(ch)){
            percmark = cnt;
            while(++cnt < length){
                ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
                if([newlineSet characterIsMember:ch]){
                    break;
                }
            }
            SetColor(commentColor, percmark, cnt - percmark);
        }else if(isLeftBrace(ch)){
            braceDepth = 1;
            SetColor(braceColor, cnt, 1)
            lbmark = cnt + 1;
            while(++cnt < length){
                if(isBackslash(ch)){ // ignore escaped braces
                    ch = 0;
                    continue;
                }
                ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
                if(isRightBrace(ch)){
                    braceDepth--;
                    if(braceDepth == 0){
                        SetColor(braceColor, cnt, 1);
                        break;
                    }
                } else if(isLeftBrace(ch)){
                    braceDepth++;
                }
            }
            SetColor(quotedColor, lbmark, cnt - lbmark);
        }else if(isDoubleQuote(ch)){
            braceDepth = 1;
            SetColor(braceColor, cnt, 1)
            lbmark = cnt + 1;
            while(++cnt < length){
                if(isBackslash(ch)){ // ignore escaped braces
                    ch = 0;
                    continue;
                }
                ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
                if(isDoubleQuote(ch)){
                    braceDepth--;
                    SetColor(braceColor, cnt, 1);
                    break;
                }
            }
            SetColor(quotedColor, lbmark, cnt - lbmark);
        }else if(isRightBrace(ch)){
            SetColor(braceColor, cnt, 1);
        }else if(isHash(ch)){
            SetColor(hashColor, cnt, 1);
        }
    }
    if(braceDepth > 0){
        invalidSyntaxHighlightMark = editedRange.location + length;
    } else if(invalidSyntaxHighlightMark <= editedRange.location + length){
        invalidSyntaxHighlightMark = NSNotFound;
    }
}

@end
