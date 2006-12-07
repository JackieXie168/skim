//
//  BibFiler.m
//  Bibdesk
//
//  Created by Michael McCracken on Fri Apr 30 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BibFiler.h"
#import "NSImage+Toolbox.h"

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
		fileInfoDicts = [[NSMutableArray arrayWithCapacity:10] retain];
		
	}
	return self;
}

- (void)dealloc{
	[fileInfoDicts release];
	[super dealloc];
}

#pragma mark Auto file methods

- (void)filePapers:(NSArray *)papers fromDocument:(BibDocument *)doc ask:(BOOL)ask{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *papersFolderPath = [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKPapersFolderPathKey];
	BOOL isDir;
	int rv;
	BOOL moveAll = YES;

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
			moveAll = NO;
		}else if(rv == NSAlertAlternateReturn){
			return;
		}
	}
	
	NSString *path = nil;
	NSString *newPath = nil;
	
	[self prepareMoveForDocument:doc number:[NSNumber numberWithInt:[papers count]]];
	
	foreach(paper , papers){
		path = [paper localURLPath];
		newPath = [[NSURL URLWithString:[paper suggestedLocalUrl]] path];
		[self movePath:path toPath:newPath forPaper:paper fromDocument:doc moveAll:moveAll];
	}
	
	[self finishMoveForDocument:doc];
}

- (void)movePath:(NSString *)path toPath:(NSString *)newPath forPaper:(BibItem *)paper fromDocument:(BibDocument *)doc moveAll:(BOOL)moveAll{
	if (progressSheet) {
		[progressIndicator incrementBy:1.0];
		[progressIndicator displayIfNeeded];
	}
        
	if(path == nil || [path isEqualToString:@""] |
	   newPath == nil || [newPath isEqualToString:@""] || 
	   [path isEqualToString:newPath])
		return;
	
	NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			[path stringByAbbreviatingWithTildeInPath], @"oloc", 
			[newPath stringByAbbreviatingWithTildeInPath], @"nloc", nil];
	NSString *status = nil;
	int statusFlag = BDSKNoErrorMask;
	NSFileManager *fm = [NSFileManager defaultManager];
	// filemanager needs aliases resolved for moving and existence checks
	// ...however we want to move aliases, not their targets
    NSString *resolvedNewPath = nil;
    NS_DURING
		resolvedNewPath = [[fm resolveAliasesInPath:[newPath stringByDeletingLastPathComponent]] 
					 stringByAppendingPathComponent:[newPath lastPathComponent]];
    NS_HANDLER
        NSLog(@"Ignoring exception %@ raised while resolving aliases in %@", [localException name], newPath);
        status = NSLocalizedString(@"Unable to resolve aliases in path.", @"");
        statusFlag = statusFlag | BDSKUnableToResolveAliasMask;
    NS_ENDHANDLER
    
    NSString *resolvedPath = nil;
    NS_DURING
        resolvedPath = [[fm resolveAliasesInPath:[path stringByDeletingLastPathComponent]] 
                  stringByAppendingPathComponent:[path lastPathComponent]];
    NS_HANDLER
        NSLog(@"Ignoring exception %@ raised while resolving aliases in %@", [localException name], path);
        status = NSLocalizedString(@"Unable to resolve aliases in path.", @"");
        statusFlag = statusFlag | BDSKUnableToResolveAliasMask;
    NS_ENDHANDLER
	
	if( (moveAll || [paper canSetLocalUrl]) && statusFlag == BDSKNoErrorMask){
		if([fm fileExistsAtPath:resolvedNewPath]){
			statusFlag = statusFlag | BDSKGeneratedFileExistsMask;
			if([fm fileExistsAtPath:resolvedPath]){
				status = NSLocalizedString(@"A file already exists at the generated location.",@"");
			}else{
				status = NSLocalizedString(@"The linked file does not exists, while a file already exists at the generated location.", @"");
				statusFlag = statusFlag | BDSKOldFileDoesNotExistMask;
			}
		}else{
			if([fm fileExistsAtPath:resolvedPath]){
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
						if([fm createSymbolicLinkAtPath:resolvedNewPath pathContent:pathContent]){
							if(![fm removeFileAtPath:resolvedPath handler:self]){
								status = [errorString autorelease];
								statusFlag = statusFlag | BDSKMoveErrorMask;
							}
							[paper setField:@"Local-Url" toValue:[[NSURL fileURLWithPath:newPath] absoluteString]];
							//status = NSLocalizedString(@"Successfully moved.",@"");
							
							NSUndoManager *undoManager = [doc undoManager];
							[[undoManager prepareWithInvocationTarget:self] 
								movePath:newPath toPath:path forPaper:paper fromDocument:doc moveAll:YES];
							moveCount++;
						}else{
							status = NSLocalizedString(@"Could not move symbolic link.", @"");
							statusFlag = statusFlag | BDSKMoveErrorMask;
						}
					}else if([fm movePath:resolvedPath toPath:resolvedNewPath handler:self]){
						[paper setField:@"Local-Url" toValue:[[NSURL fileURLWithPath:newPath] absoluteString]];
						//status = NSLocalizedString(@"Successfully moved.",@"");
						
						NSUndoManager *undoManager = [doc undoManager];
						[[undoManager prepareWithInvocationTarget:self] 
							movePath:newPath toPath:path forPaper:paper fromDocument:doc moveAll:YES];
						moveCount++;
					}else{
						status = [errorString autorelease];
						statusFlag = statusFlag | BDSKMoveErrorMask;
					}
				}
			}else{
				status = NSLocalizedString(@"The linked file does not exist.", @"");
				statusFlag = statusFlag | BDSKOldFileDoesNotExistMask;
			}
		}
	}else{
		status = NSLocalizedString(@"Incomplete information to generate the file name.",@"");
		statusFlag = statusFlag | BDSKIncompleteFieldsMask;
	}
	movableCount++;
	
	if(statusFlag != BDSKNoErrorMask){
		[info setObject:status forKey:@"status"];
		[info setObject:[NSNumber numberWithInt:statusFlag] forKey:@"flag"];
		[fileInfoDicts addObject:info];
	}
}

- (void)prepareMoveForDocument:(BibDocument *)doc number:(NSNumber *)number{
	NSUndoManager *undoManager = [doc undoManager];
	[[undoManager prepareWithInvocationTarget:self] finishMoveForDocument:doc];
	
	moveCount = 0;
	movableCount = 0;
	[fileInfoDicts removeAllObjects];
	
	if ([number intValue] > 1 && [NSBundle loadNibNamed:@"AutoFileProgress" owner:self]) {
		[NSApp beginSheet:progressSheet
		   modalForWindow:[doc windowForSheet]
			modalDelegate:self
		   didEndSelector:NULL
			  contextInfo:nil];
		[progressIndicator setMaxValue:[number doubleValue]];
		[progressIndicator setDoubleValue:0.0];
		[progressIndicator displayIfNeeded];
	}
}

- (void)finishMoveForDocument:(BibDocument *)doc{
	NSUndoManager *undoManager = [doc undoManager];
	[[undoManager prepareWithInvocationTarget:self] prepareMoveForDocument:doc number:[NSNumber numberWithInt:moveCount]];
	
	if (progressSheet) {
		[progressSheet orderOut:nil];
		[NSApp endSheet:progressSheet returnCode:0];
	}
	
	if([fileInfoDicts count] > 0){
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
	[iconView setImage:[NSImage imageWithLargeIconForToolboxCode:kAlertNoteIcon]];
	[tv setDoubleAction:@selector(showFile:)];
	[tv setTarget:self];
	[window makeKeyAndOrderFront:self];
}

- (IBAction)done:(id)sender{
	[self doCleanup];
}

- (void)doCleanup{
	currentPapers = nil;
	currentDocument = nil;
	[window close];
}

- (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo{
	errorString = [[errorInfo objectForKey:@"Error"] retain];
	return NO;
}

#pragma mark table view stuff

- (int)numberOfRowsInTableView:(NSTableView *)tableView{
	return [fileInfoDicts count]; 
}

- (id)tableView:(NSTableView *)tableView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
			row:(int)row{
	NSString *tcid = [tableColumn identifier];
	NSDictionary *dict = [fileInfoDicts objectAtIndex:row];
	
	if([tcid isEqualToString:@"oloc"]){
		return [dict objectForKey:@"oloc"];
	}else if([tcid isEqualToString:@"nloc"]){
		return [dict objectForKey:@"nloc"];
	}else if([tcid isEqualToString:@"status"]){
		return [dict objectForKey:@"status"];
	}else if([tcid isEqualToString:@"icon"]){
		NSString *path = [[dict objectForKey:@"oloc"] stringByExpandingTildeInPath];
		NSString *extension = [path pathExtension];
		if(path && [[NSFileManager defaultManager] fileExistsAtPath:path]){
				if(![extension isEqualToString:@""]){
						// use the NSImage method, as it seems to be faster, but only for files with extensions
						return [NSImage imageForFileType:extension];
				} else {
						return [[NSWorkspace sharedWorkspace] iconForFile:path];
				}
		}else{
				return nil;
		}
	}
	else return @"??";
}

- (void)tableView:(NSTableView *)tableView
  willDisplayCell:(id)cell
   forTableColumn:(NSTableColumn *)tableColumn 
			  row:(int)row{
	NSString *tcid = [tableColumn identifier];
	NSDictionary *dict = [fileInfoDicts objectAtIndex:row];
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

- (IBAction)showFile:(id)sender{
	NSString *tcid;
	NSDictionary *dict = [fileInfoDicts objectAtIndex:[tv clickedRow]];
	NSString *path;
	int statusFlag = [[dict objectForKey:@"flag"] intValue];

	if([tv clickedColumn] != -1){
		tcid = [[[tv tableColumns] objectAtIndex:[tv clickedColumn]] identifier];
	}else{
		tcid = @"";
	}

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
		NSRunAlertPanel(nil,
						[dict objectForKey:@"status"],
						NSLocalizedString(@"OK",@"OK"),nil,nil);
	}
}

@end
