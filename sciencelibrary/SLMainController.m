#import "SLMainController.h"
#import "SLFolderItem.h"
#import "reference.h"
#import "ImageAndTextCell.h"

@implementation SLMainController

-(id) init {
    if (self =[super init]) {
        
            }
    return self;
}

-(void) awakeFromNib {
    
    NSMutableArray *saveObject=[[NSMutableArray alloc] init];
    [saveObject addObjectsFromArray:[[NSKeyedUnarchiver unarchiveObjectWithFile:[NSString stringWithFormat:@"%@%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"libraryLocation"],@"/Science Library Database"]] retain]];
   
    NSTableColumn *tableColumn = nil;
    ImageAndTextCell *imageAndTextCell = nil;

    tableColumn = [sourceTableView tableColumnWithIdentifier: @"Source"];
    imageAndTextCell = [[[ImageAndTextCell alloc] init] autorelease];
    [imageAndTextCell setEditable: YES];
    [tableColumn setDataCell:imageAndTextCell];
    
    
    if ([saveObject count]==0) {
        SLFolderItem *libraryFolderItem;
        SLFolderItem *pubmedFolderItem;
        libraryFolderItem=[[SLFolderItem alloc] init];
        pubmedFolderItem=[[SLFolderItem alloc] init];
	

        [libraryFolderItem setFolderName:@"Library"];
	[libraryFolderItem setEditable:0];
        [pubmedFolderItem setFolderName:@"PubMed"];
	[pubmedFolderItem setEditable:0];

        [SLSourceArrayController addObject:libraryFolderItem];
        [SLSourceArrayController addObject:pubmedFolderItem];

        [libraryFolderItem release];
        [pubmedFolderItem release];
	
    }
    else {
	[SLSourceArrayController addObjects:[saveObject objectAtIndex:0]];
	[SLPubmedSearchArrayController addObjects:[saveObject objectAtIndex:1]];
	[SLKeywordListController addObjects: [saveObject objectAtIndex:2]];
    }
    [sourceTableView registerForDraggedTypes: [NSArray arrayWithObjects:@"PBType", nil]];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"libraryLocation"]==nil) {
	
	[[NSUserDefaults standardUserDefaults] setObject:@"100" forKey:@"maxRefsToRetrieve"];
	//[self openSetupWindow];
    }
    
    [SLSourceArrayController setSelectionIndex:0];
    [SLPubmedSearchArrayController setSelectionIndex:0];
    [self populatePopMenu];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"libraryLocation"]==nil) {
	
	
	[NSApp beginSheet: setupWindow
	   modalForWindow: mainWindow
            modalDelegate: nil
	   didEndSelector: nil
              contextInfo: nil];
	[NSApp runModalForWindow: setupWindow];
	// Sheet is up here.
	[NSApp endSheet: setupWindow];
	[setupWindow orderOut: self];

	
	//[setupWindow makeKeyAndOrderFront:self];
	//[self openSetupWindow];
    }
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if ([[tableColumn identifier] isEqualToString: @"Source"]) {
	// Make sure the image and text cell has an image. 
	if (row==0) {
	[(ImageAndTextCell*)cell setImage: [NSImage imageNamed:@"LibraryIcon.tif"]];
	}
	else if (row==1) {
	    [(ImageAndTextCell*)cell setImage: [NSImage imageNamed:@"PubmedIcon.tif"]];
	}
	else if (row>1) {
	    [(ImageAndTextCell*)cell setImage: [NSImage imageNamed:@"FolderIcon.tif"]];

	}
    }
}


-(void) openSetupWindow {
    NSLog(@"setup window");
    [setupWindow makeKeyAndOrderFront:self];
}
-(void) closeSetupWindow:(id)sender {
    [NSApp stopModal];

}

-(IBAction)editKeywordList:(id)sender {
    NSLog(@"editkeyword");
    if ([[sender selectedCell] title]==@"Edit keywords...") {
	[keywordsWindow makeKeyAndOrderFront:self];
    }
}



/*
-(IBAction)imageViewURLChanged:(id)sender {
    NSMutableString *newPath=[[NSMutableString alloc] init];
    [SLArticleController setValue:[sender valueForKey:@"url"]
						      forKeyPath:@"selection.URLToPDFFile"];
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"renameFiles"] boolValue]==YES) {
	[[[SLArticleController selectedObjects] objectAtIndex:0] renameFile];
    }
    NSLog(@"done renaming");
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"consolidateLibrary"] boolValue]==YES ) {
	NSLog(@"consolidating");
	[newPath appendString:[[NSUserDefaults standardUserDefaults] valueForKey:@"libraryLocation"]];
	NSLog(@"newPath=%@",newPath);
	newPath=[newPath stringByAppendingPathComponent:[[SLArticleController valueForKeyPath:@"selection.articleAuthors"] lastObject]];
	[[NSFileManager defaultManager] createDirectoryAtPath:newPath attributes:nil];

	newPath=[newPath stringByAppendingPathComponent:[[SLArticleController valueForKeyPath:@"selection.URLToPDFFile"] lastPathComponent]];
	NSLog(@"newPath=%@",newPath);

	[[NSFileManager defaultManager] movePath:[SLArticleController valueForKeyPath:@"selection.URLToPDFFile"] toPath:newPath handler:nil];
	[SLArticleController setValue:[NSURL fileURLWithPath:newPath] forKeyPath:@"selection.URLToPDFFile"];
	
	//[sender setValue:newPath forKeyPath:@"url"];
    }
    [sender setValue:[SLArticleController valueForKeyPath:@"selection.URLToPDFFile"] forKey:@"url"];
}


-(void)renameFile:(id)sender {
    [[[SLArticleController selectedObjects] objectAtIndex:0] renameFile];
}
*/

- (void)populatePopMenu {
    NSLog(@"populating");
    int         i;
    NSString    *itemTitle;
    
    [SLKeywordPopupButton removeAllItems];
    NSLog(@"removed items");

    for(i = 0; i < [[SLKeywordListController arrangedObjects] count]; i++){
	NSLog(@"for loop");

        itemTitle = [[SLKeywordListController arrangedObjects] objectAtIndex:i];
        if([itemTitle length] > 0){
            [SLKeywordPopupButton addItemWithTitle:itemTitle];
            [[SLKeywordPopupButton itemAtIndex:i] setTag:i];
        }
    }
    NSLog(@"adding separator");
    [[SLKeywordPopupButton menu] addItem:[NSMenuItem separatorItem]];
    [SLKeywordPopupButton addItemWithTitle:@"Edit keywords..."];
    
}


-(IBAction)addArticle:(id)sender {
    NSLog(@"adding article");
    reference *newArticle=[[reference alloc] init];
    
    [SLArticleController addObject:newArticle];
    
    if ([SLSourceArrayController selectionIndex]!=0) {
	[[[[SLSourceArrayController arrangedObjects] objectAtIndex:0] articleListArray] addObject:newArticle];
    }
    
    [newArticle autorelease];

}


-(IBAction)changeLibraryLocation:(id)sender {
    
    NSString *result;
    NSOpenPanel *panel=[NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    result = [panel runModalForDirectory:[[NSUserDefaults standardUserDefaults] objectForKey:@"libraryLocation"]
                                    file:nil types:nil];
    if (result !=NSCancelButton) {
        [[NSUserDefaults standardUserDefaults] setObject:[panel directory] forKey:@"libraryLocation"];
        
    }
}

-(IBAction)setInitialLibraryLocation:(id)sender {
    
    NSString *result;
    NSMutableString *newDirectory=[[NSMutableString alloc] init];
    NSOpenPanel *panel=[NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    result = [panel runModalForDirectory:[[NSUserDefaults standardUserDefaults] objectForKey:@"libraryLocation"]
                                    file:nil types:nil];
    if (result !=NSCancelButton) {
	[newDirectory appendString:[panel directory]];
	[newDirectory appendString:@"/Science Library"];
	[[NSFileManager defaultManager] createDirectoryAtPath:newDirectory attributes:nil];
        [[NSUserDefaults standardUserDefaults] setObject:newDirectory forKey:@"libraryLocation"];
        
    }
}


//delegate methods for sourceTable
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    
    if ([sourceTableView selectedRow]==1) {
        [articleView retain];
        [[articleView superview] replaceSubview:(NSView *)articleView with:(NSView *)pubMedView];

    }
    else {
        [pubMedView retain];
        [[pubMedView superview] replaceSubview:(NSView *)pubMedView with:(NSView *) articleView];
    }
}

- (NSDragOperation) tableView: (NSTableView *) view
				      validateDrop: (id <NSDraggingInfo>) info
					      proposedRow: (int) row
	       proposedDropOperation: (NSTableViewDropOperation) operation
{
    
    NSLog(@"row=%d",row);
    if (row > [[SLSourceArrayController arrangedObjects] count])
	return NSDragOperationNone;
    
    if (nil == [info draggingSource]) // From other application
    {
	return NSDragOperationNone;
    }
    
    else if (sourceTableView == [info draggingSource]) // From self
    {
	return NSDragOperationNone;
    }
    
    if ([info draggingSource]==articleTableView && row<2) {
	return NSDragOperationNone;
    }
    
    if ([info draggingSource]==pubmedArticleTableView && row==1) {
	return NSDragOperationNone;
    }
    
    else // From other documents 
    {
	[view setDropRow:row dropOperation: NSTableViewDropOn];
	return NSDragOperationCopy;
    }
}

- (BOOL) tableView: (NSTableView *) view
	       acceptDrop: (id <NSDraggingInfo>) info
			     row: (int) row
     dropOperation: (NSTableViewDropOperation) operation
{
    NSLog(@"dropped on destination row %d",row);
    NSPasteboard *pboard = [info draggingPasteboard];
    NSData *data = [pboard dataForType: @"PBType"];
    
    if (row > [[SLSourceArrayController arrangedObjects] count] || row==1)
	return NO;
    
    if ([info draggingSource]==articleTableView) {
	 if (row==0 || row==1) {
	return NO;
	 }
	else {
	    reference *draggedReference = [NSKeyedUnarchiver unarchiveObjectWithData: data];
	    NSLog(@"draggedReferenceissue=%@",[draggedReference valueForKey:@"articleIssue"]);
	    [[[[SLSourceArrayController arrangedObjects] objectAtIndex:row] articleListArray] addObject:draggedReference];
	    return YES;
	}
    }
    
    if (nil == [info draggingSource]) // From other application
    {
	return NO;
    }
    else if (sourceTableView == [info draggingSource]) // From self
    {
	return NO;
    }
    else  if (row==0) // Dragged to Library
    {
	reference *draggedReference = [NSKeyedUnarchiver unarchiveObjectWithData: data];
	[[[[SLSourceArrayController arrangedObjects] objectAtIndex:0] articleListArray] addObject:draggedReference];
	
	return YES;
    }
    else if (row>1) {
	reference *draggedReference = [NSKeyedUnarchiver unarchiveObjectWithData: data];
	NSLog(@"draggedReferenceissue=%@",[draggedReference valueForKey:@"articleIssue"]);
	NSLog(@"draggedReferenceyear=%@",[draggedReference valueForKey:@"articleYear"]);

	[[[[SLSourceArrayController arrangedObjects] objectAtIndex:row] articleListArray] addObject:draggedReference];
	[[[[SLSourceArrayController arrangedObjects] objectAtIndex:0] articleListArray] addObject:draggedReference];
    return YES;
    }
    else {
	return NO;
    }
}





//Quitting
-(IBAction)applicationWillTerminate:(id)sender {
    NSLog(@"quitting");
    NSMutableArray *saveObject=[[NSMutableArray alloc] init];
    [saveObject addObject:[SLSourceArrayController arrangedObjects]];
    [saveObject addObject:[SLPubmedSearchArrayController arrangedObjects]];
    [saveObject addObject:[SLKeywordListController arrangedObjects]];
    [NSKeyedArchiver archiveRootObject:saveObject toFile:[NSString stringWithFormat:@"%@%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"libraryLocation"],@"/Science Library Database"]];
    [saveObject release];
}

-(void)dealloc {
    
    [super dealloc];
}


//Saving
-(IBAction)save:(id)sender {
    NSLog(@"saving");
    NSMutableArray *saveObject=[[NSMutableArray alloc] init];
    [saveObject addObject:[SLSourceArrayController arrangedObjects]];
    [saveObject addObject:[SLPubmedSearchArrayController arrangedObjects]];
    [saveObject addObject:[SLKeywordListController arrangedObjects]];

    [NSKeyedArchiver archiveRootObject:saveObject toFile:[NSString stringWithFormat:@"%@%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"libraryLocation"],@"/Science Library Database"]];
    [saveObject release];
}


@end
