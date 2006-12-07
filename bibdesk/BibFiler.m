//
//  BibFiler.m
//  BibDesk
//
//  Created by Michael McCracken on Fri Apr 30 2004.
/*
 This software is Copyright (c) 2004,2005
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
#import <OmniAppKit/OATextWithIconCell.h>
#import <OmniAppKit/NSTableView-OAExtensions.h>

static BibFiler *sharedFiler = nil;

@implementation BibFiler

+ (BibFiler *)sharedFiler{
	if(!sharedFiler){
		sharedFiler = [[BibFiler alloc] init];
	}
	return sharedFiler;
}

- (id)init{
	if(self = [super init]){
		errorInfoDicts = [[NSMutableArray arrayWithCapacity:10] retain];
	}
	return self;
}

- (void)dealloc{
	[errorInfoDicts release];
	[super dealloc];
}

- (void)awakeFromNib{
	// this isn't set properly in the nib because OATextWithIconCell does not override initWithCoder
	OATextWithIconCell *cell = [[tv tableColumnWithIdentifier:@"oloc"] dataCell];
	[cell setDrawsHighlight:YES];
	[cell setImagePosition:NSImageLeft];
	cell = [[tv tableColumnWithIdentifier:@"nloc"] dataCell];
	[cell setDrawsHighlight:YES];
	[cell setImagePosition:NSImageLeft];
}

#pragma mark Auto file methods

- (void)filePapers:(NSArray *)papers fromDocument:(BibDocument *)doc ask:(BOOL)ask{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *papersFolderPath = [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKPapersFolderPathKey];
	BOOL isDir;
	int rv;
	BOOL check = NO;

	if(!([fm fileExistsAtPath:[fm resolveAliasesInPath:papersFolderPath] isDirectory:&isDir] && isDir)){
		// The directory isn't there or isn't a directory, so pop up an alert.
		rv = NSRunAlertPanel(NSLocalizedString(@"Papers Folder doesn't exist",@""),
							 NSLocalizedString(@"The Papers Folder you've chosen either doesn't exist or isn't a folder. Any files you have dragged in will be linked to in their original location. Press \"Go to Preferences\" to set the Papers Folder.",@""),
							 NSLocalizedString(@"OK",@"OK"),NSLocalizedString(@"Go to Preferences",@""),nil);
		if (rv == NSAlertAlternateReturn){
				[[OAPreferenceController sharedPreferenceController] showPreferencesPanel:self];
				[[OAPreferenceController sharedPreferenceController] setCurrentClientByClassName:@"BibPref_AutoFile"];
		}
		return;
	}
	
	if(ask){
		rv = NSRunAlertPanel(NSLocalizedString(@"Consolidate Linked Files",@""),
							 NSLocalizedString(@"This will put all files linked to the selected items in your Papers Folder, according to the format string. Do you want me to generate a new location for all linked files, or only for those for which all the bibliographical information used in the generated file name has been set?",@""),
							 NSLocalizedString(@"Move All",@"Move All"),
							 NSLocalizedString(@"Cancel",@"Cancel"), 
							 NSLocalizedString(@"Move Complete Only",@"Move Complete Only"));
		if(rv == NSAlertOtherReturn){
			check = YES;
		}else if(rv == NSAlertAlternateReturn){
			return;
		}
	}
	
	[self movePapers:papers fromDocument:doc checkComplete:check];
}

- (void)movePapers:(NSArray *)paperInfos fromDocument:(BibDocument *)doc checkComplete:(BOOL)check{
	NSFileManager *fm = [NSFileManager defaultManager];
	int numberOfPapers = [paperInfos count];
	NSEnumerator *paperEnum = [paperInfos objectEnumerator];
	id paperInfo = nil;
	BibItem *paper = nil;
	NSString *path = nil;
	NSString *newPath = nil;
	NSString *resolvedPath = nil;
	NSString *resolvedNewPath = nil;
	NSMutableArray *fileInfoDicts = [NSMutableArray arrayWithCapacity:numberOfPapers];
	NSMutableDictionary *info = nil;
	NSString *status = nil;
	int statusFlag = BDSKNoErrorMask;
	
	if (numberOfPapers == 0)
		return;
	
	if (numberOfPapers > 1 && [NSBundle loadNibNamed:@"AutoFileProgress" owner:self]) {
		[NSApp beginSheet:progressSheet
		   modalForWindow:[doc windowForSheet]
			modalDelegate:self
		   didEndSelector:NULL
			  contextInfo:nil];
		[progressIndicator setMaxValue:numberOfPapers];
		[progressIndicator setDoubleValue:0.0];
		[progressIndicator displayIfNeeded];
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
			if([paperInfo isKindOfClass:[BibItem class]])
				[papers addObject:paperInfo];
			else
				[papers addObject:[paperInfo objectForKey:@"paper"]];
		}
		// we don't set the fieldName and the old/new values as the newValues are not reliable
		[[BDSKScriptHookManager sharedManager] runScriptHook:scriptHook forPublications:papers];
	}
	
	scriptHook = [[BDSKScriptHookManager sharedManager] makeScriptHookWithName:BDSKDidAutoFileScriptHookName];
	if(scriptHook){
		papers = [NSMutableArray arrayWithCapacity:[paperInfos count]];
		oldValues = [NSMutableArray arrayWithCapacity:[paperInfos count]];
		newValues = [NSMutableArray arrayWithCapacity:[paperInfos count]];
	}
	
	paperEnum = [paperInfos objectEnumerator];
	while (paperInfo = [paperEnum nextObject]) {
		
		if([paperInfo isKindOfClass:[BibItem class]]){
			// autofile action: an array of BibItems
			paper = (BibItem *)paperInfo;
			path = [paper localURLPathInheriting:NO];
			newPath = [[NSURL URLWithString:[paper suggestedLocalUrl]] path];
		}else{
			// undo: a list of info dictionaries. We should move the file back!
			paper = [paperInfo objectForKey:@"paper"];
			path = [paperInfo objectForKey:@"nloc"];
			newPath = [paperInfo objectForKey:@"oloc"];
		}
		
		if(progressSheet){
			[progressIndicator incrementBy:1.0];
			[progressIndicator displayIfNeeded];
		}
			
		if([NSString isEmptyString:path] || [NSString isEmptyString:newPath] || 
		   [path isEqualToString:newPath])
			continue;
		
		info = [NSMutableDictionary dictionaryWithCapacity:5];
		[info setObject:paper forKey:@"paper"];
		[info setObject:path forKey:@"oloc"];
		[info setObject:newPath forKey:@"nloc"];
		status = nil;
		statusFlag = BDSKNoErrorMask;
		// filemanager needs aliases resolved for moving and existence checks
		// ...however we want to move aliases, not their targets
		// so we resolve aliases in the path to the containing folder
		NS_DURING
			resolvedNewPath = [[fm resolveAliasesInPath:[newPath stringByDeletingLastPathComponent]] 
						 stringByAppendingPathComponent:[newPath lastPathComponent]];
		NS_HANDLER
			NSLog(@"Ignoring exception %@ raised while resolving aliases in %@", [localException name], newPath);
			status = NSLocalizedString(@"Unable to resolve aliases in path.", @"");
			statusFlag = statusFlag | BDSKUnableToResolveAliasMask;
		NS_ENDHANDLER
		
		NS_DURING
			resolvedPath = [[fm resolveAliasesInPath:[path stringByDeletingLastPathComponent]] 
					  stringByAppendingPathComponent:[path lastPathComponent]];
		NS_HANDLER
			NSLog(@"Ignoring exception %@ raised while resolving aliases in %@", [localException name], path);
			status = NSLocalizedString(@"Unable to resolve aliases in path.", @"");
			statusFlag = statusFlag | BDSKUnableToResolveAliasMask;
		NS_ENDHANDLER
		
		if(check && ![paper canSetLocalUrl]){
			status = NSLocalizedString(@"Incomplete information to generate the file name.",@"");
			statusFlag = statusFlag | BDSKIncompleteFieldsMask;
		}
		
		if(statusFlag == BDSKNoErrorMask){
			if([fm fileExistsAtPath:resolvedNewPath]){
				statusFlag = statusFlag | BDSKGeneratedFileExistsMask;
				if([fm fileExistsAtPath:resolvedPath]){
					status = NSLocalizedString(@"A file already exists at the generated location.",@"");
				}else{
					status = NSLocalizedString(@"The linked file does not exists, while a file already exists at the generated location.", @"");
					statusFlag = statusFlag | BDSKOldFileDoesNotExistMask;
				}
			}else if(![fm fileExistsAtPath:resolvedPath]){
				status = NSLocalizedString(@"The linked file does not exist.", @"");
				statusFlag = statusFlag | BDSKOldFileDoesNotExistMask;
			}else if(![fm isDeletableFileAtPath:resolvedPath]){
				status = NSLocalizedString(@"Could not move read-only file.", @"");
				statusFlag = statusFlag | BDSKMoveErrorMask;
			}else{
				NSString *fileType = [[fm fileAttributesAtPath:resolvedPath traverseLink:NO] objectForKey:NSFileType];
				NS_DURING
					[fm createPathToFile:resolvedNewPath attributes:nil]; // create parent directories if necessary (OmniFoundation)
				NS_HANDLER
					NSLog(@"Ignoring exception %@ raised while creating path %@", [localException name], resolvedNewPath);
					status = NSLocalizedString(@"Unable to create the parent directory structure.", @"");
					statusFlag = statusFlag | BDSKUnableToCreateParentMask;
				NS_ENDHANDLER
				if(statusFlag == BDSKNoErrorMask){
					// unfortunately NSFileManager cannot reliably move symlinks...
					if([fileType isEqualToString:NSFileTypeSymbolicLink]){
						NSString *pathContent = [fm pathContentOfSymbolicLinkAtPath:resolvedPath];
						if(![pathContent hasPrefix:@"/"]){// it links to a relative path
							pathContent = [[resolvedPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:pathContent];
						}
						if(![fm createSymbolicLinkAtPath:resolvedNewPath pathContent:pathContent]){
							status = NSLocalizedString(@"Could not move symbolic link.", @"");
							statusFlag = statusFlag | BDSKMoveErrorMask;
						}else{
							if(![fm removeFileAtPath:resolvedPath handler:self]){
								// error remove original file
								// should we remove the new symlink and not set Local-Url?
								status = [errorString autorelease];
								statusFlag = statusFlag | BDSKMoveErrorMask;
							}
							oldValue  = [paper valueOfField:BDSKLocalUrlString inherit:NO];
							newValue  = [[NSURL fileURLWithPath:newPath] absoluteString];
							[paper setField:BDSKLocalUrlString toValue:newValue];
							if(scriptHook){
								[papers addObject:paper];
								[oldValues addObject:oldValue];
								[newValues addObject:newValue];
							}
							//status = NSLocalizedString(@"Successfully moved.",@"");
						}
					}else if([fm movePath:resolvedPath toPath:resolvedNewPath handler:self]){
						oldValue  = [paper valueOfField:BDSKLocalUrlString inherit:NO];
						newValue  = [[NSURL fileURLWithPath:newPath] absoluteString];
						[paper setField:BDSKLocalUrlString toValue:newValue];
						if(scriptHook){
							[papers addObject:paper];
							[oldValues addObject:oldValue];
							[newValues addObject:newValue];
						}
						//status = NSLocalizedString(@"Successfully moved.",@"");
					}else{ // error while moving file
						// if the new file was created, should we set the Local-Url and run the scripthook, or remove it?
						status = [errorString autorelease];
						statusFlag = statusFlag | BDSKMoveErrorMask;
					}
				}
			}
		}
		
		if(statusFlag == BDSKNoErrorMask){
			[fileInfoDicts addObject:info];
		}else{
			[info setObject:status forKey:@"status"];
			[info setObject:[NSNumber numberWithInt:statusFlag] forKey:@"flag"];
			[errorInfoDicts addObject:info];
		}
	}
	
	if(scriptHook){
		[scriptHook setField:BDSKLocalUrlString];
		[scriptHook setOldValues:oldValues];
		[scriptHook setNewValues:newValues];
		[[BDSKScriptHookManager sharedManager] runScriptHook:scriptHook forPublications:papers];
	}
	
	if(progressSheet){
		[progressSheet orderOut:nil];
		[NSApp endSheet:progressSheet returnCode:0];
	}
	
	NSUndoManager *undoManager = [doc undoManager];
	[[undoManager prepareWithInvocationTarget:self] 
		movePapers:fileInfoDicts fromDocument:doc checkComplete:NO];
	
	if([errorInfoDicts count] > 0){
		[self showProblems];
	}
}

- (void)showProblems{
	BOOL success = [NSBundle loadNibNamed:@"AutoFile" owner:self];
	if(!success){
		NSRunCriticalAlertPanel(NSLocalizedString(@"Error loading AutoFile window module.",@""),
								NSLocalizedString(@"There was an error loading the AutoFile window module. BibDesk will still run, and automatically filing papers that are dragged in should still work fine. Please report this error to the developers. Sorry!",@""),
								NSLocalizedString(@"OK",@"OK"),nil,nil);
		return;
	}

	[tv reloadData];
	[infoTextField setStringValue:NSLocalizedString(@"There were problems moving the following files to the generated file location, according to the format string.",@"description string")];
	[iconView setImage:[NSImage imageNamed:@"NSApplicationIcon"]];
	[tv setDoubleAction:@selector(showFile:)];
	[tv setTarget:self];
	[window makeKeyAndOrderFront:self];
}

- (IBAction)done:(id)sender{
	[window close];
	[errorInfoDicts removeAllObjects];
	[tv reloadData]; // this is necessary to avoid an exception
}

- (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo{
	errorString = [[errorInfo objectForKey:@"Error"] retain];
	return NO;
}

#pragma mark table view stuff

- (int)numberOfRowsInTableView:(NSTableView *)tableView{
	return [errorInfoDicts count]; 
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	NSString *tcid = [tableColumn identifier];
	NSDictionary *dict = [errorInfoDicts objectAtIndex:row];
	
	if([tcid isEqualToString:@"oloc"]){
		NSString *path = [dict objectForKey:@"oloc"];
		if(path && [[NSFileManager defaultManager] fileExistsAtPath:path]){
			return [NSDictionary dictionaryWithObjectsAndKeys:
						[path stringByAbbreviatingWithTildeInPath], OATextWithIconCellStringKey, 
						[NSImage smallImageForFile:path], OATextWithIconCellImageKey, nil];
		} else {
			return [path stringByAbbreviatingWithTildeInPath];
		}
	}else if([tcid isEqualToString:@"nloc"]){
		NSString *path = [dict objectForKey:@"nloc"];
		if(path && [[NSFileManager defaultManager] fileExistsAtPath:path]){
			return [NSDictionary dictionaryWithObjectsAndKeys:
						[path stringByAbbreviatingWithTildeInPath], OATextWithIconCellStringKey, 
						[NSImage smallImageForFile:path], OATextWithIconCellImageKey, nil];
		} else {
			return [path stringByAbbreviatingWithTildeInPath];
		}
	}else if([tcid isEqualToString:@"status"]){
		return [dict objectForKey:@"status"];
	}
	return nil;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	NSString *tcid = [tableColumn identifier];
	NSDictionary *dict = [errorInfoDicts objectAtIndex:row];
	int statusFlag = [[dict objectForKey:@"flag"] intValue];
		
	if([tcid isEqualToString:@"oloc"]){
		if(statusFlag & BDSKOldFileDoesNotExistMask){
			[cell setTextColor:[NSColor grayColor]];
		}else{
			[cell setTextColor:[NSColor blackColor]];
		}
	}else if([tcid isEqualToString:@"nloc"]){
		if(statusFlag & BDSKGeneratedFileExistsMask){
			[cell setTextColor:[NSColor blackColor]];
		}else if(statusFlag & BDSKIncompleteFieldsMask){
			[cell setTextColor:[NSColor redColor]];
		}else{
			[cell setTextColor:[NSColor grayColor]];
		}
	}
}

- (NSString *)tableView:(NSTableView *)tableView tooltipForRow:(int)row column:(int)column{
	NSString *tcid = [[[tv tableColumns] objectAtIndex:column] identifier];
	return [[errorInfoDicts objectAtIndex:row] objectForKey:tcid];
}

- (IBAction)showFile:(id)sender{
	int column = [tv clickedColumn];
	NSString *tcid;
	NSDictionary *dict = [errorInfoDicts objectAtIndex:[tv clickedRow]];
	NSString *path;
	int statusFlag = [[dict objectForKey:@"flag"] intValue];

	if(column == -1)
		return;
	
	tcid = [[[tv tableColumns] objectAtIndex:column] identifier];
	if([tcid isEqualToString:@"oloc"] || [tcid isEqualToString:@"icon"]){
		if(statusFlag & BDSKOldFileDoesNotExistMask)
			return;
		path = [[dict objectForKey:@"oloc"] stringByExpandingTildeInPath];
		[[NSWorkspace sharedWorkspace]  selectFile:path inFileViewerRootedAtPath:nil];
	}else if([tcid isEqualToString:@"nloc"]){
		if(!(statusFlag & BDSKGeneratedFileExistsMask))
			return;
		path = [[dict objectForKey:@"nloc"] stringByExpandingTildeInPath];
		[[NSWorkspace sharedWorkspace]  selectFile:path inFileViewerRootedAtPath:nil];
	}else if([tcid isEqualToString:@"status"]){
		BibItem *pub = [dict objectForKey:@"paper"];
		[[pub document] editPub:pub];
	}
}

@end
