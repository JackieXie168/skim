//
//  BibDocument+Adding.m
//  Bibdesk
//
//  Created by Sven-S. Porst on Mon Jul 19 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BibDocument+Adding.h"


@implementation BibDocument (Adding)

/* ssp: 2004-07-18
An attempt to unify the adding of BibItems from the pasteboard
This takes the structural code from the original drag and drop handling code and breaks out the parts for handling file and text pasteboards.
As an experiment, we also try to pass errors back.
Would it be advisable to also give access to the newly added records?
*/
- (BOOL) addPublicationsFromPasteboard:(NSPasteboard*) pb error:(NSString**) error{
	NSArray * types = [pb types];

	if([pb containsFiles]) {
        NSArray * pbArray = [pb propertyListForType:NSFilenamesPboardType]; // we will get an array
		return [self addPublicationsForFiles:pbArray error:error];
    }
	else if([types containsObject:NSStringPboardType]){
        NSData * pbData = [pb dataForType:NSStringPboardType]; 	
		NSString * str = [[[NSString alloc] initWithData:pbData encoding:NSUTF8StringEncoding] autorelease];
		return [self addPublicationsForString:str error:error];
    }
	else {
		*error = NSLocalizedString(@"didn't find anything appropriate on the pasteboard", @"Bibdesk couldn't find any files or bibliography information in the data it received.");
		return NO;
    }	
}


/* ssp: 2004-07-19
'TeXify' the string, convert to data and insert then.
Taken from original -paste: method
Originally, drag and drop and services didn't seem to 'TeXify'
I hope this is the right thing to do.
There may be a bit too much conversion Data->String->Data going on.
*/
- (BOOL) addPublicationsForString:(NSString*) string error:(NSString**) error {
	NSString * TeXifiedString = [BDSKConverter stringByTeXifyingString:string];
	NSData * data = [TeXifiedString dataUsingEncoding:NSUTF8StringEncoding];

	return [self addPublicationsForData:data error:error];
}


/* ssp: 2004-07-18
Broken out of  original drag and drop handling
Runs the data it receives through BiBTeXParser and add the BibItems it receives.
Error handling is quasi-nonexistant. 
We don't even have the error handling that used to exist in the -paste: method yet. Did that actually help?
Shouldn't there be some kind of safeguard against opening too many pub editors?
*/
- (BOOL) addPublicationsForData:(NSData*) data error:(NSString**) error {
	BOOL hadProblems = NO;
	NSArray * newPubs = [BibTeXParser itemsFromData:data error:&hadProblems];

	if(hadProblems || ![newPubs count]) {
		// a slight attempt at indicating where the problem is
		*error = NSLocalizedString(@"couldn't analyse string", @"Bibdesk couldn't find bibliography data in the text it received.");
		return NO;
	}

	NSEnumerator * newPubE = [newPubs objectEnumerator];
	BibItem * newBI = nil;

	while(newBI = [newPubE nextObject]){		
		[publications addObject:newBI];
		[shownPublications addObject:newBI];
		[self updateUI];
		[self updateChangeCount:NSChangeDone];
		if([[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKEditOnPasteKey] == NSOnState) {
			[self editPub:newBI forceChange:YES];
		}
	}
	return YES;
}




/* ssp: 2004-07-18
Broken out of  original drag and drop handling
Takes an array of file paths and adds them to the document if possible.
This method always returns YES. Even if some or many operations fail.
*/
- (BOOL) addPublicationsForFiles:(NSArray*) filenames error:(NSString**) error {
	OFPreferenceWrapper *pw = [OFPreferenceWrapper sharedPreferenceWrapper];

	NSEnumerator * fileNameEnum = [filenames objectEnumerator];
	NSString * fnStr = nil;
	NSURL * url = nil;
	
	while(fnStr = [fileNameEnum nextObject]){
		if(url = [NSURL fileURLWithPath:fnStr]){
			BibItem * newBI = [[BibItem alloc] initWithType:[pw stringForKey:BDSKPubTypeStringKey]
										 fileType:@"BibTeX"
										  authors:[NSMutableArray arrayWithCapacity:0]];
			
			[self addPublication:newBI];
			
			NSString *newUrl = [[NSURL fileURLWithPath:
				[fnStr stringByExpandingTildeInPath]]absoluteString];
			
			[newBI setField:@"Local-Url" toValue:newUrl];	
			
			if([pw boolForKey:BDSKFilePapersAutomaticallyKey]){
				[[BibFiler sharedFiler] file:YES papers:[NSArray arrayWithObject:newBI]
								fromDocument:self];
			}
			
			[self updateUI];
			[self updateChangeCount:NSChangeDone];
			
			if([pw integerForKey:BDSKEditOnPasteKey] == NSOnState){
				[self editPub:newBI forceChange:YES];
				//[[newBI editorObj] fixEditedStatus];  - deprecated
			}
		}
	}
	return YES;
}



/* ssp: 2004-07-18
Stripped down/refactored version of the original method fromm BibDocument_DataSource.m
*/
- (BOOL)tableView:(NSTableView*)tv
       acceptDrop:(id <NSDraggingInfo>)info
              row:(int)row
    dropOperation:(NSTableViewDropOperation)op{
	
    NSPasteboard *pb;
	
    if(tv == (NSTableView *)ccTableView){
        return NO; // can't drag into that tv.
    }
    
	if([info draggingSource]){
        pb = localDragPboard;     // it's really local, so use the local pboard.
    }else{
        pb = [info draggingPasteboard];
    }
	
	NSString * myError;
	BOOL result = [self addPublicationsFromPasteboard:pb error:&myError];
    
    if (result) [self updateUI];
    return result;
}



/* ssp: 2004-07-19
Stripped down version from BibDocument
*/ 
- (IBAction)paste:(id)sender{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
	NSString * error;

	if (![self addPublicationsFromPasteboard:pasteboard error:&error]) {
			// an error occured
		//Display error message or simply Beep?
		NSBeep();
	}
}

@end



/* ssp: 2004-07-18
Service to import selected BibTeX entry
Should probably be merged into the BibAppController class properly

This relies on the refactored code for adding BibItems from a Pasteboard.
*/
@implementation BibAppController (BibImportService)


/* ssp: 2004-07-18
Implements service to import selection
*/
- (void)addPublicationsFromSelection:(NSPasteboard *)pboard
						   userData:(NSString *)userData
							  error:(NSString **)error{	
	
	// add to the frontmost bibliography
	BibDocument * doc = [[NSApp orderedDocuments] objectAtIndex:0];
    if (!doc) {
		// if there are no open documents, give an error. 
		// Or rather create a new document and add the entry there? Would anybody want that?
		*error = NSLocalizedString(@"Error: No open document", @"Bibdesk couldn't import the selected information because there is no open bibliography file to add it to. Please create or open a bibliography file and try again.");
		return;
	}
	
	[doc addPublicationsFromPasteboard:pboard error:error];
}

@end
