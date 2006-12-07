//
//  BibFiler.m
//  Bibdesk
//
//  Created by Michael McCracken on Fri Apr 30 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BibFiler.h"

static BibFiler *_sharedFiler = nil;

@implementation BibFiler

+ (BibFiler *)sharedFiler{
	if(!_sharedFiler){
		_sharedFiler = [[BibFiler alloc] init];
	}
	return _sharedFiler;
}

- (id)init{
	if(self = [super init]){
		_fileInfoDicts = [[NSMutableArray arrayWithCapacity:10] retain];
		
	}
	return self;
}

- (void)dealloc{
	[_fileInfoDicts release];
	[super dealloc];
}

#pragma mark Preview / Postmortem Info

- (void)showPreviewForPapers:(NSArray *)papers fromDocument:(BibDocument *)doc{
	
	NSString *papersFolderPath = [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKPapersFolderPathKey];

	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir;
	
	if(!([fm fileExistsAtPath:papersFolderPath isDirectory:&isDir] && isDir)){
		// The directory isn't there or isn't a directory, so pop up an alert.
		int rv = NSRunAlertPanel(NSLocalizedString(@"Papers Folder doesn't exist",@""),
								 NSLocalizedString(@"The Papers Folder you've chosen either doesn't exist or isn't a folder. Press \"Go to Preferences\" to set the Papers Folder.",@""),
								 NSLocalizedString(@"OK",@""),NSLocalizedString(@"Go to Preferences",@""),nil);
		if (rv == NSAlertAlternateReturn){
			[[OAPreferenceController sharedPreferenceController] showPreferencesPanel:self];
			[[OAPreferenceController sharedPreferenceController] setCurrentClientByClassName:@"BibPref_AutoFile"];
		}
		return;
	}
	
	
	BOOL success = [NSBundle loadNibNamed:@"AutoFile" owner:self];
	if(!success){
		NSRunCriticalAlertPanel(NSLocalizedString(@"Error loading AutoFile window module.",@""),
								NSLocalizedString(@"There was an error loading the AutoFile window module. BibDesk will still run, and automatically filing papers that are dragged in should still work fine. Please report this error to the developers. Sorry!",@""),
								NSLocalizedString(@"OK",@""),nil,nil);
		return;
	}
	_currentPapers = papers;
	_currentDocument = doc;
	[self file:NO papers:papers fromDocument:doc];

	if(_movableCount == 0){
		NSRunAlertPanel(NSLocalizedString(@"No files to consolidate",@""),
						NSLocalizedString(@"All the linked files point to the Papers Folder.",@""),
						NSLocalizedString(@"OK",@""),nil,nil);
		return;
	}
	
	[tv reloadData];
	
	[infoTextField setStringValue:[NSString stringWithFormat:
		NSLocalizedString(@"These files that will be moved to %@.\nScan this list for errors, because this operation cannot be undone.",@"description string"), [papersFolderPath stringByAbbreviatingWithTildeInPath]]];
	[window makeKeyAndOrderFront:self];	
}

- (void)doMoveAction:(id)sender{
	[self file:YES papers:_currentPapers fromDocument:_currentDocument];
	
	NSRunAlertPanel(NSLocalizedString(@"Files Consolidated", @""),
					NSLocalizedString(@"%d of %d eligible files were moved.\n%d links were fixed, %d duplicate files were deleted.",@""),
					NSLocalizedString(@"OK",@"OK"),
					nil, nil, _moveCount, _movableCount, _cleanupChangeCount, _deletedCount);
	
	[self doCleanup];
}

- (IBAction)cancelFromPreview:(id)sender{
	[self doCleanup];
}

- (void)doCleanup{
	_currentPapers = nil;
	_currentDocument = nil;
	[window close];
}

- (void)file:(BOOL)doFile papers:(NSArray *)papers fromDocument:(BibDocument *)doc{

	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *papersFolderPath = [[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKPapersFolderPathKey];
	
	BOOL isDir;
	// Because we don't call file:papers: from the preview window unless the directory exists,
	// this will only be executed if we're not coming from there. We won't get a repeat error.
	
	BOOL fileExists = [fm fileExistsAtPath:papersFolderPath isDirectory:&isDir];
		
	if(!([fm fileExistsAtPath:papersFolderPath isDirectory:&isDir] && isDir)){
		// The directory isn't there or isn't a directory, so pop up an alert.
		int rv = NSRunAlertPanel(NSLocalizedString(@"Papers Folder doesn't exist",@""),
								 NSLocalizedString(@"The Papers Folder you've chosen either doesn't exist or isn't a folder. Any files you have dragged in will be linked to in their original location. Press \"Go to Preferences\" to set the Papers Folder.",@""),
								 NSLocalizedString(@"OK",@""),NSLocalizedString(@"Go to Preferences",@""),nil);
		if (rv == NSAlertAlternateReturn){
			[[OAPreferenceController sharedPreferenceController] showPreferencesPanel:self];
			[[OAPreferenceController sharedPreferenceController] setCurrentClientByClassName:@"BibPref_AutoFile"];
		}
		return;
		
	}
	
	_moveCount = 0;
	_movableCount = 0;
	_deletedCount = 0;
	_cleanupChangeCount = 0;
	[_fileInfoDicts removeAllObjects];
	
	foreach(paper , papers){
		NSString *path = [paper localURLPathRelativeTo:[[(NSDocument *)doc fileName] stringByDeletingLastPathComponent]];
		NSString *fileName = [path lastPathComponent];
		NSString *newPath = [papersFolderPath stringByAppendingPathComponent:fileName];
		
		NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:[path stringByAbbreviatingWithTildeInPath], @"oloc", 
			newPath, @"nloc", nil];
		NSString *status = nil;
	
		if(path){
			NSString *fileURLString = [[NSURL fileURLWithPath:newPath] absoluteString];

			if(![path isEqualToString:newPath]){
				if([fm fileExistsAtPath:newPath]){
					BOOL pathExists = [fm fileExistsAtPath:path];
					if(pathExists){
						status = NSLocalizedString(@"A copy of the linked file is in your Papers Folder.",@"");
					}else{
						status = NSLocalizedString(@"The linked file does not exist, but a file with the same name is in the Papers Folder.", @"");
					}
					if(doFile){
						if(pathExists && [deleteCheckBox state] == NSOnState){
							[fm removeFileAtPath:path handler:nil];
							_deletedCount++;
						}
						if([cleanupCheckBox state] == NSOnState){
							[paper setField:@"Local-Url" toValue:fileURLString];
							_cleanupChangeCount++;
						}
					}
				}else{
					if(doFile){
						if([fm movePath:path toPath:newPath handler:self]){
							[paper setField:@"Local-Url" toValue:fileURLString];
							status = NSLocalizedString(@"success", @"success"); // won't appear
							_moveCount++;
						}else{
							status = [_errorString autorelease];
						}
					}else{
						status = NSLocalizedString(@"OK to move", @"ok to move");
					}
				}
				_movableCount++;
				[info setObject:status forKey:@"status"];
				[_fileInfoDicts addObject:info];
			}
		}
			
	}
	if(_moveCount > 0 || _deletedCount > 0 || _cleanupChangeCount > 0){
		//[doc updateChangeCount:NSChangeDone];
	}

}

- (BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo{
	_errorString = [[errorInfo objectForKey:@"Error"] retain];
	return NO;
}

- (IBAction)handleCleanupLinksAction:(id)sender{
	if([sender state] == NSOnState){
		[deleteCheckBox setEnabled:YES];
	}else{
		[deleteCheckBox setEnabled:NO];
	}
}

#pragma mark table view stuff

- (int)numberOfRowsInTableView:(NSTableView *)tableView{
	return [_fileInfoDicts count]; 
}

- (id)tableView:(NSTableView *)tableView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
			row:(int)row{
	NSString *tcid = [tableColumn identifier];
	NSDictionary *dict = [_fileInfoDicts objectAtIndex:row];
	
	if([tcid isEqualToString:@"icon"]){
		return @"-";
	}else if([tcid isEqualToString:@"oloc"]){
		return [dict objectForKey:@"oloc"];
	}else if([tcid isEqualToString:@"nloc"]){
		return [dict objectForKey:@"nloc"];
	}else if([tcid isEqualToString:@"status"]){
		return [dict objectForKey:@"status"];
	}
	else return @"??";
}

@end
