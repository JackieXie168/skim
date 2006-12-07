//
//  BibFiler.m
//  BibDesk
//
//  Created by Michael McCracken on Fri Apr 30 2004.
/*
 This software is Copyright (c) 2004,2005,2006
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

#import "BibFiler.h"
#import "NSImage+Toolbox.h"
#import "BDSKScriptHookManager.h"
#import "BDSKPathColorTransformer.h"
#import <OmniAppKit/NSTableView-OAExtensions.h>
#import "BibDocument.h"
#import "BibDocument_Actions.h"
#import "BibAppController.h"
#import "NSFileManager_BDSKExtensions.h"
#import "BDSKAlert.h"

static BibFiler *sharedFiler = nil;

@implementation BibFiler

+ (void)initialize {
	// register transformer class
	[NSValueTransformer setValueTransformer:[[[BDSKOldPathColorTransformer alloc] init] autorelease]
									forName:@"BDSKOldPathColorTransformer"];
	[NSValueTransformer setValueTransformer:[[[BDSKNewPathColorTransformer alloc] init] autorelease]
									forName:@"BDSKNewPathColorTransformer"];
}

+ (BibFiler *)sharedFiler{
	if(!sharedFiler){
		sharedFiler = [[BibFiler alloc] init];
	}
	return sharedFiler;
}

- (id)init{
	if(self = [super init]){
		errorInfoDicts = [[NSMutableArray alloc] initWithCapacity:10];
	}
	return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[errorInfoDicts release];
	[super dealloc];
}

#pragma mark Auto file methods

- (void)filePapers:(NSArray *)papers fromDocument:(BibDocument *)doc check:(BOOL)check{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *papersFolderPath = [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKPapersFolderPathKey];
	BOOL isDir;
	int rv;

	if(![NSString isEmptyString:papersFolderPath] && !([fm fileExistsAtPath:[fm resolveAliasesInPath:papersFolderPath] isDirectory:&isDir] && isDir)){
		// The directory isn't there or isn't a directory, so pop up an alert.
		rv = NSRunAlertPanel(NSLocalizedString(@"Papers Folder doesn't exist", @"Message in alert dialog when unable to find Papers Folder"),
							 NSLocalizedString(@"The Papers Folder you've chosen either doesn't exist or isn't a folder. Any files you have dragged in will be linked to in their original location. Press \"Go to Preferences\" to set the Papers Folder.", @"Informative text in alert dialog"),
							 NSLocalizedString(@"OK", @"Button title"),NSLocalizedString(@"Go to Preferences", @"Button title"),nil);
		if (rv == NSAlertAlternateReturn){
				[[BDSKPreferenceController sharedPreferenceController] showPreferencesPanel:self];
				[[BDSKPreferenceController sharedPreferenceController] setCurrentClientByClassName:@"BibPref_AutoFile"];
		}
		return;
	}
	
    int mask = BDSKInitialAutoFileOptionMask;
    if (check == YES) mask |= BDSKCheckCompleteAutoFileOptionMask;
	[self movePapers:papers forField:BDSKLocalUrlString fromDocument:doc options:mask];
}

- (void)movePapers:(NSArray *)paperInfos forField:(NSString *)field fromDocument:(BibDocument *)doc options:(int)mask{
	NSFileManager *fm = [NSFileManager defaultManager];
    int numberOfPapers = [paperInfos count];
	NSEnumerator *paperEnum = [paperInfos objectEnumerator];
	id paperInfo = nil;
	BibItem *paper = nil;
	NSString *path = nil;
	NSString *newPath = nil;
	NSMutableArray *fileInfoDicts = [NSMutableArray arrayWithCapacity:numberOfPapers];
	NSMutableDictionary *info = nil;
	BOOL useRelativePath = [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKAutoFileUsesRelativePathKey];
    NSString *papersFolderPath = [[[NSApp delegate] folderPathForFilingPapersFromDocument:doc] stringByAppendingString:@"/"];
	NSError *error = nil;
    
    BOOL initial = (mask & BDSKInitialAutoFileOptionMask);
    BOOL force = (mask & BDSKForceAutoFileOptionMask);
    BOOL check = (initial == YES) && (force == NO) && (mask & BDSKCheckCompleteAutoFileOptionMask);
    
	if (numberOfPapers == 0)
		return;
	
	if (initial && [field isEqualToString:BDSKLocalUrlString] == NO)
        [NSException raise:BDSKUnimplementedException format:@"%@ is only implemented for the Local-Url field for initial moves.",NSStringFromSelector(_cmd)];
	
	if (numberOfPapers > 1) {
        if (progressSheet == nil)
            [NSBundle loadNibNamed:@"AutoFileProgress" owner:self];
		[progressIndicator setMaxValue:numberOfPapers];
		[progressIndicator setDoubleValue:0.0];
        [progressCloseButton setEnabled:NO];
		[NSApp beginSheet:progressSheet
		   modalForWindow:[doc windowForSheet]
			modalDelegate:nil
		   didEndSelector:NULL
			  contextInfo:nil];
	}
	
	BDSKScriptHook *scriptHook = [[BDSKScriptHookManager sharedManager] makeScriptHookWithName:BDSKWillAutoFileScriptHookName];
	NSMutableArray *papers = nil;
	NSMutableArray *oldValues = nil;
	NSMutableArray *newValues = nil;
	NSString *oldValue = nil;
	NSString *newValue = nil;
	
	if(scriptHook){
		papers = [NSMutableArray arrayWithCapacity:[paperInfos count]];
		while (paperInfo = [paperEnum nextObject]) {
			if(initial)
				[papers addObject:paperInfo];
			else
				[papers addObject:[paperInfo objectForKey:@"paper"]];
		}
		// we don't set the old/new values as the newValues are not reliable
		[scriptHook setField:field];
		[[BDSKScriptHookManager sharedManager] runScriptHook:scriptHook forPublications:papers document:doc];
	}
	
	scriptHook = [[BDSKScriptHookManager sharedManager] makeScriptHookWithName:BDSKDidAutoFileScriptHookName];
	if(scriptHook){
		papers = [NSMutableArray arrayWithCapacity:[paperInfos count]];
		oldValues = [NSMutableArray arrayWithCapacity:[paperInfos count]];
		newValues = [NSMutableArray arrayWithCapacity:[paperInfos count]];
	}
	
	paperEnum = [paperInfos objectEnumerator];
	while (paperInfo = [paperEnum nextObject]) {
		
		if(initial){
			// autofile action: an array of BibItems
			paper = (BibItem *)paperInfo;
			path = [paper localUrlPathInheriting:NO];
			newPath = [[NSURL URLWithString:[paper suggestedLocalUrl]] path];
		}else{
			// an explicit move, possibly from undo: a list of info dictionaries
			paper = [paperInfo objectForKey:@"paper"];
			path = [paperInfo objectForKey:@"oldPath"];
			newPath = [paperInfo objectForKey:@"newPath"];
		}
		
		if(numberOfPapers > 1){
			[progressIndicator incrementBy:1.0];
			[progressIndicator displayIfNeeded];
		}
			
		if([NSString isEmptyString:path] || [NSString isEmptyString:newPath] || 
		   [path isEqualToString:newPath])
			continue;
		
		info = [NSMutableDictionary dictionaryWithCapacity:6];
		[info setObject:paper forKey:@"paper"];
        error = nil;
        oldValue  = [[NSURL fileURLWithPath:path] absoluteString]; // we don't use the field value, as we might have already changed it in undo or find/replace
        
        if(check && ![paper canSetLocalUrl]){
            
            [info setObject:NSLocalizedString(@"Incomplete information to generate file name.",@"") forKey:@"status"];
            [info setObject:[NSNumber numberWithInt:BDSKIncompleteFieldsErrorMask] forKey:@"flag"];
            [info setObject:NSLocalizedString(@"Move anyway.",@"") forKey:@"fix"];
            [info setObject:path forKey:@"oldPath"];
            [info setObject:newPath forKey:@"newPath"];
            [self insertObject:info inErrorInfoDictsAtIndex:[self countOfErrorInfoDicts]];
            
        }else if(![fm movePath:path toPath:newPath force:force error:&error]){ 
            
            NSDictionary *errorInfo = [error userInfo];
            NSString *fix = [errorInfo objectForKey:NSLocalizedRecoverySuggestionErrorKey];
            if (fix != nil)
                [info setObject:fix forKey:@"fix"];
            [info setObject:[errorInfo objectForKey:NSLocalizedDescriptionKey] forKey:@"status"];
            [info setObject:[NSNumber numberWithInt:[error code]] forKey:@"flag"];
            [info setObject:path forKey:@"oldPath"];
            [info setObject:newPath forKey:@"newPath"];
            [self insertObject:info inErrorInfoDictsAtIndex:[self countOfErrorInfoDicts]];
            
		}else{
			
			newValue  = [[NSURL fileURLWithPath:newPath] absoluteString];
			if(initial) {// otherwise will be done by undo of setField:
                if(useRelativePath){
                    NSString *relativePath = newPath;
                    if ([newPath hasPrefix:papersFolderPath])
                        relativePath = [newPath substringFromIndex:[papersFolderPath length]];
                    [paper setField:field toValue:relativePath];
                }else{
                    [paper setField:field toValue:newValue];
                }
			}else{
                // make sure the UI is notified that the linked file has changed, as this is often called after setField:toValue:
                NSString *value = [paper valueOfField:field];
                NSDictionary *notifInfo = [NSDictionary dictionaryWithObjectsAndKeys:value, @"value", field, @"key", @"Change", @"type", doc, @"owner", value, @"oldValue", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:BDSKBibItemChangedNotification
                                                                    object:paper
                                                                  userInfo:notifInfo];
            }
            if(scriptHook){
				[papers addObject:paper];
				[oldValues addObject:oldValue];
				[newValues addObject:newValue];
			}
			// switch them as this is used in undo
            [info setObject:path forKey:@"newPath"];
            [info setObject:newPath forKey:@"oldPath"];
			[fileInfoDicts addObject:info];
            
		}
	}
	
	if(scriptHook){
		[scriptHook setField:field];
		[scriptHook setOldValues:oldValues];
		[scriptHook setNewValues:newValues];
		[[BDSKScriptHookManager sharedManager] runScriptHook:scriptHook forPublications:papers document:doc];
	}
	
	if(numberOfPapers > 1){
		[progressSheet orderOut:nil];
		[NSApp endSheet:progressSheet returnCode:0];
        // enable the close button in case the progress sheet was queued and is not attached at this point
        [progressCloseButton setEnabled:YES];
	}
	
	NSUndoManager *undoManager = [doc undoManager];
	[[undoManager prepareWithInvocationTarget:self] 
		movePapers:fileInfoDicts forField:field fromDocument:doc options:0];
	
	if([self countOfErrorInfoDicts] > 0){
        document = [doc retain];
        fieldName = [field retain];
        options = mask;
		[self showProblems];
    }
}

- (IBAction)closeProgress:(id)sender{
    [progressSheet orderOut:nil];
    [NSApp endSheet:progressSheet returnCode:0];
}

#pragma mark Error reporting

- (void)showProblems{
    if (window == nil) {
        if([NSBundle loadNibNamed:@"AutoFile" owner:self] == NO){
            NSRunCriticalAlertPanel(NSLocalizedString(@"Error loading AutoFile window module.", @"Message in alert dialog when unable to load window"),
                                    NSLocalizedString(@"There was an error loading the AutoFile window module. BibDesk will still run, and automatically filing papers that are dragged in should still work fine. Please report this error to the developers. Sorry!", @"Informative text in alert dialog"),
                                    NSLocalizedString(@"OK", @"Button title"),nil,nil);
            return;
        }
	}
    [tv reloadData];
    if (options & BDSKInitialAutoFileOptionMask)
        [infoTextField setStringValue:NSLocalizedString(@"There were problems moving the following files to the location generated using the format string. You can retry to move items selected in the first column.",@"description string")];
    else
        [infoTextField setStringValue:NSLocalizedString(@"There were problems moving the following files to the target location. You can retry to move items selected in the first column.",@"description string")];
	[iconView setImage:[NSImage imageNamed:@"NSApplicationIcon"]];
	[tv setDoubleAction:@selector(showFile:)];
	[tv setTarget:self];
    [forceCheckButton setState:NSOffState];
	[window makeKeyAndOrderFront:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:window];
}

- (IBAction)done:(id)sender{
    [window close];
}

- (IBAction)tryAgain:(id)sender{
	NSDictionary *info = nil;
    int i, count = [self countOfErrorInfoDicts];
	NSMutableArray *fileInfoDicts = [NSMutableArray arrayWithCapacity:count];
    
    for (i = 0; i < count; i++) {
        info = [self objectInErrorInfoDictsAtIndex:i];
        if ([[info objectForKey:@"select"] boolValue] == YES) {
            if (options & BDSKInitialAutoFileOptionMask) {
                [fileInfoDicts addObject:[info objectForKey:@"paper"]];
            } else {
                [fileInfoDicts addObject:info];
            }
        }
    }
    
    if ([fileInfoDicts count] == 0) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Nothing Selected", @"Message in alert dialog when retrying to autofile without selection")
                                         defaultButton:NSLocalizedString(@"OK", @"Button title")
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"Please select the items you want to auto file again or press Done.", @"Informative text in alert dialog")];
        [alert beginSheetModalForWindow:window
                          modalDelegate:nil
                         didEndSelector:NULL 
                            contextInfo:NULL];
        return;
    }
    
    BibDocument *doc = [[document retain] autorelease];
    NSString *field = [[fieldName retain] autorelease];
    int mask = (options & BDSKInitialAutoFileOptionMask);
    mask |= ([forceCheckButton state]) ? BDSKForceAutoFileOptionMask : (options & BDSKCheckCompleteAutoFileOptionMask);
    
    [window close];
    
    [self movePapers:fileInfoDicts forField:field fromDocument:doc options:mask];
}

- (IBAction)dump:(id)sender{
    NSMutableString *string = [NSMutableString string];
	NSDictionary *info = nil;
    int i, count = [self countOfErrorInfoDicts];
    
    for (i = 0; i < count; i++) {
        info = [self objectInErrorInfoDictsAtIndex:i];
        [string appendStrings:NSLocalizedString(@"Publication key: ", @"Label for autofile dump"),
                              [[info objectForKey:@"paper"] citeKey], @"\n", 
                              NSLocalizedString(@"Original path: ", @"Label for autofile dump"),
                              [info objectForKey:@"oldPath"], @"\n", 
                              NSLocalizedString(@"New path: ", @"Label for autofile dump"),
                              [info objectForKey:@"newPath"], @"\n", 
                              NSLocalizedString(@"Status: ",@"Label for autofile dump"),
                              [info objectForKey:@"status"], @"\n", 
                              NSLocalizedString(@"Fix: ", @"Label for autofile dump"),
                              (([info objectForKey:@"fix"] == nil) ? NSLocalizedString(@"Cannot fix.", @"Cannot fix AutoFile error") : [info objectForKey:@"fix"]),
                              @"\n\n", nil];
    }
    
    NSString *fileName = NSLocalizedString(@"BibDesk AutoFile Errors", @"Filename for dumped autofile errors.");
    NSString *path = [[NSFileManager defaultManager] desktopDirectory];
    if (path == nil)
        return;
    path = [[[NSFileManager defaultManager] uniqueFilePath:[path stringByAppendingPathComponent:fileName] createDirectory:NO] stringByAppendingPathExtension:@"txt"];
    
    [string writeToFile:path atomically:YES];
}

- (void)windowWillClose:(NSNotification *)notification{
    if ([[notification object] isEqual:window]) {
        [[self mutableArrayValueForKey:@"errorInfoDicts"] removeAllObjects];
        [tv reloadData]; // this is necessary to avoid an exception
        [document release];
        document = nil;
        [fieldName release];
        fieldName = nil;
        options = 0;
    }
}

#pragma mark Accessors

- (NSArray *)errorInfoDicts {
    return errorInfoDicts;
}

- (unsigned)countOfErrorInfoDicts {
    return [errorInfoDicts count];
}

- (id)objectInErrorInfoDictsAtIndex:(unsigned)index {
    return [errorInfoDicts objectAtIndex:index];
}

- (void)insertObject:(id)obj inErrorInfoDictsAtIndex:(unsigned)index {
    [errorInfoDicts insertObject:obj atIndex:index];
}

- (void)removeObjectFromErrorInfoDictsAtIndex:(unsigned)index {
    [errorInfoDicts removeObjectAtIndex:index];
}

#pragma mark table view stuff

// dummy dataSource implementation
- (int)numberOfRowsInTableView:(NSTableView *)tView{ return 0; }
- (id)tableView:(NSTableView *)tView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{ return nil; }

- (NSString *)tableView:(NSTableView *)tableView toolTipForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	NSString *tcid = [tableColumn identifier];
    if ([tcid isEqualToString:@"select"]) {
        return NSLocalizedString(@"Select items to Try Again or to Force.", @"Tool tip message");
    }
    return [[self objectInErrorInfoDictsAtIndex:row] objectForKey:tcid];
}

- (IBAction)showFile:(id)sender{
    int row = [tv selectedRow];
    if (row == -1)
        return;
    NSDictionary *dict = [self objectInErrorInfoDictsAtIndex:row];
    int statusFlag = [[dict objectForKey:@"flag"] intValue];
    NSString *tcid = nil;
    NSString *path = nil;
    BibItem *pub = nil;
    int type = -1;

    if(sender == tv){
        int column = [tv clickedColumn];
        if(column == -1)
            return;
        tcid = [[[tv tableColumns] objectAtIndex:column] identifier];
        if([tcid isEqualToString:@"oldPath"] || [tcid isEqualToString:@"icon"]){
            type = 0;
        }else if([tcid isEqualToString:@"newPath"]){
            type = 1;
        }else if([tcid isEqualToString:@"status"] || [tcid isEqualToString:@"fix"]){
            type = 2;
        }
    }else if([sender isKindOfClass:[NSMenuItem class]]){
        type = [sender tag];
    }
    
    switch(type){
        case 0:
            if(statusFlag & BDSKSourceFileDoesNotExistErrorMask)
                return;
            path = [[dict objectForKey:@"oldPath"] stringByExpandingTildeInPath];
            [[NSWorkspace sharedWorkspace]  selectFile:path inFileViewerRootedAtPath:nil];
            break;
        case 1:
            if(!(statusFlag & BDSKTargetFileExistsErrorMask))
                return;
            path = [[dict objectForKey:@"newPath"] stringByExpandingTildeInPath];
            [[NSWorkspace sharedWorkspace]  selectFile:path inFileViewerRootedAtPath:nil];
            break;
        case 2:
            pub = [dict objectForKey:@"paper"];
            // at this moment we have the document set
            [document editPub:pub];
            break;
	}
}

- (NSMenu *)tableView:(NSTableView *)tableView contextMenuForRow:(int)row column:(int)column{
    return contextMenu;
}

@end


@implementation NSFileManager (BibFilerExtensions)

- (BOOL)movePath:(NSString *)path toPath:(NSString *)newPath force:(BOOL)force error:(NSError **)error{
    NSString *resolvedPath = nil;
    NSString *resolvedNewPath = nil;
    NSString *comment = nil;
    NSString *status = nil;
    NSString *fix = nil;
    int statusFlag = BDSKNoError;
    BOOL ignoreMove = NO;
    
    // filemanager needs aliases resolved for moving and existence checks
    // ...however we want to move aliases, not their targets
    // so we resolve aliases in the path to the containing folder
    NS_DURING
        resolvedNewPath = [[self resolveAliasesInPath:[newPath stringByDeletingLastPathComponent]] 
                     stringByAppendingPathComponent:[newPath lastPathComponent]];
    NS_HANDLER
        NSLog(@"Ignoring exception %@ raised while resolving aliases in %@", [localException name], newPath);
        status = NSLocalizedString(@"Unable to resolve aliases in path.", @"AutoFile error message");
        statusFlag =  BDSKCannotResolveAliasErrorMask;
    NS_ENDHANDLER
    
    NS_DURING
        resolvedPath = [[self resolveAliasesInPath:[path stringByDeletingLastPathComponent]] 
                  stringByAppendingPathComponent:[path lastPathComponent]];
    NS_HANDLER
        NSLog(@"Ignoring exception %@ raised while resolving aliases in %@", [localException name], path);
        status = NSLocalizedString(@"Unable to resolve aliases in path.", @"AutoFile error message");
        statusFlag = BDSKCannotResolveAliasErrorMask;
    NS_ENDHANDLER
    
    if(statusFlag == BDSKNoError){
        if([self fileExistsAtPath:resolvedNewPath]){
            if([self fileExistsAtPath:resolvedPath]){
                if(force){
                    NSString *backupPath = [[self desktopDirectory] stringByAppendingPathComponent:[resolvedNewPath lastPathComponent]];
                    backupPath = [self uniqueFilePath:backupPath createDirectory:NO];
                    if(![self movePath:resolvedNewPath toPath:backupPath force:NO error:NULL] && 
                        [self fileExistsAtPath:resolvedNewPath] && 
                        ![self removeFileAtPath:resolvedNewPath handler:nil]){
                        status = NSLocalizedString(@"Unable to remove existing file at target location.", @"AutoFile error message");
                        statusFlag = BDSKTargetFileExistsErrorMask | BDSKCannotRemoveFileErrorMask;
                        // cleanup: move back backup
                        if(![self movePath:backupPath toPath:resolvedNewPath handler:nil] && [self fileExistsAtPath:resolvedNewPath]){
                            [self removeFileAtPath:backupPath handler:nil];
                        }
                    }
                }else{
                    if([self isDeletableFileAtPath:resolvedNewPath]){
                        status = NSLocalizedString(@"File exists at target location.", @"AutoFile error message");
                        fix = NSLocalizedString(@"Overwrite existing file.", @"AutoFile fix");
                    }else{
                        status = NSLocalizedString(@"Undeletable file exists at target location.", @"AutoFile error message");
                    }
                    statusFlag = BDSKTargetFileExistsErrorMask;
                }
            }else{
                if(force){
                    ignoreMove = YES;
                }else{
                    status = NSLocalizedString(@"Original file does not exist, file exists at target location.", @"AutoFile error message");
                    fix = NSLocalizedString(@"Use existing file at target location.", @"AutoFile fix");
                    statusFlag = BDSKSourceFileDoesNotExistErrorMask | BDSKTargetFileExistsErrorMask;
                }
            }
        }else if(![self fileExistsAtPath:resolvedPath]){
            status = NSLocalizedString(@"Original file does not exist.", @"AutoFile error message");
            statusFlag = BDSKSourceFileDoesNotExistErrorMask;
        }else if(![self isDeletableFileAtPath:resolvedPath]){
            if(force == NO){
                status = NSLocalizedString(@"Unable to move read-only file.", @"AutoFile error message");
                fix = NSLocalizedString(@"Copy original file.", @"AutoFile fix");
                statusFlag = BDSKCannotMoveFileErrorMask;
            }
        }
        if(statusFlag == BDSKNoError && ignoreMove == NO){
            // get the Finder comment (spotlight comment)
            comment = [self commentForURL:[NSURL fileURLWithPath:resolvedPath]];
            NSString *fileType = [[self fileAttributesAtPath:resolvedPath traverseLink:NO] objectForKey:NSFileType];
            NS_DURING
                [self createPathToFile:resolvedNewPath attributes:nil]; // create parent directories if necessary (OmniFoundation)
            NS_HANDLER
                NSLog(@"Ignoring exception %@ raised while creating path %@", [localException name], resolvedNewPath);
                status = NSLocalizedString(@"Unable to create parent directory.", @"AutoFile error message");
                statusFlag = BDSKCannotCreateParentErrorMask;
            NS_ENDHANDLER
            if(statusFlag == BDSKNoError){
                if([fileType isEqualToString:NSFileTypeDirectory] && force == NO && 
                   [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKWarnOnMoveFolderKey]){
                    BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Really Move Folder?", @"Message in alert dialog when trying to auto file a folder")
                                                         defaultButton:NSLocalizedString(@"Move", @"Button title")
                                                       alternateButton:NSLocalizedString(@"Don't Move", @"Button title") 
                                                           otherButton:nil
                                             informativeTextWithFormat:NSLocalizedString(@"AutoFile is about to move the folder \"%@\" to \"%@\". Do you want to move the folder?", @"Informative text in alert dialog"), path, newPath];
                    [alert setHasCheckButton:YES];
                    [alert setCheckValue:NO];
                    ignoreMove = (NSAlertAlternateReturn == [alert runModal]);
                    if([alert checkValue] == YES)
                        [[OFPreferenceWrapper sharedPreferenceWrapper] setBool:NO forKey:BDSKWarnOnMoveFolderKey];
                }
                if(ignoreMove){
                    status = NSLocalizedString(@"Shouldn't move folder.", @"AutoFile error message");
                    fix = NSLocalizedString(@"Move anyway.", @"AutoFile fix");
                    statusFlag = BDSKCannotMoveFileErrorMask;
                }else{
                    // unfortunately NSFileManager cannot reliably move symlinks...
                    if([fileType isEqualToString:NSFileTypeSymbolicLink]){
                        NSString *pathContent = [self pathContentOfSymbolicLinkAtPath:resolvedPath];
                        if(![pathContent hasPrefix:@"/"]){// it links to a relative path
                            pathContent = [[resolvedPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:pathContent];
                        }
                        if(![self createSymbolicLinkAtPath:resolvedNewPath pathContent:pathContent]){
                            status = NSLocalizedString(@"Unable to move symbolic link.", @"AutoFile error message");
                            statusFlag = BDSKCannotMoveFileErrorMask;
                        }else{
                            if(![self removeFileAtPath:resolvedPath handler:self]){
                                if (force == NO){
                                    status = NSLocalizedString(@"Unable to remove original.", @"AutoFile error message");
                                    fix = NSLocalizedString(@"Copy original file.", @"AutoFile fix");
                                    statusFlag = BDSKCannotRemoveFileErrorMask;
                                    //cleanup: remove new file
                                    [self removeFileAtPath:resolvedNewPath handler:nil];
                                }
                            }
                        }
                    }else if(![self movePath:resolvedPath toPath:resolvedNewPath handler:self]){
                        if([self fileExistsAtPath:resolvedNewPath]){ // error remove original file
                            if(force == NO){
                                status = NSLocalizedString(@"Unable to remove original file.", @"AutoFile error message");
                                fix = NSLocalizedString(@"Copy original file.", @"AutoFile fix");
                                statusFlag = BDSKCannotRemoveFileErrorMask;
                                // cleanup: move back
                                if(![self movePath:resolvedNewPath toPath:resolvedPath handler:nil] && [self fileExistsAtPath:resolvedPath]){
                                    [self removeFileAtPath:resolvedNewPath handler:nil];
                                }
                            }
                        }else{ // other error while moving file
                            status = NSLocalizedString(@"Unable to move file.", @"AutoFile error message");
                            statusFlag = BDSKCannotMoveFileErrorMask;
                        }
                    }
                }
            }
        }
    }
    
    if(statusFlag != BDSKNoError){
        if(error){
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:status, NSLocalizedDescriptionKey, nil];
            if (fix != nil)
                [userInfo setObject:fix forKey:NSLocalizedRecoverySuggestionErrorKey];
            *error = [NSError errorWithDomain:@"BibFilerErrorDomain" code:statusFlag userInfo:userInfo];
            //NSLog(@"error \"%@\" occurred; suggested fix is \"%@\"", *error, fix);
        }
        return NO;
    }else if([NSString isEmptyString:comment] == NO){
        // set the Finder comment (spotlight comment)
        [self setComment:comment forURL:[NSURL fileURLWithPath:resolvedNewPath]];
    }
    return YES;
}

@end
