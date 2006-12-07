#import "SLArticleArrayController.h"
#import "reference.h"
@implementation SLArticleArrayController

-(void)awakeFromNib {
    [articleTable setAction:nil];

    [articleTable setDoubleAction:@selector(openReferenceInBrowser:)];
}

- (BOOL) tableView: (NSTableView *) view
         writeRows: (NSArray *) rows
      toPasteboard: (NSPasteboard *) pboard
{
    NSLog(@"dragging");
    id object=[[self arrangedObjects] objectAtIndex: [[rows lastObject] intValue]];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: object];
    
    [pboard declareTypes: [NSArray arrayWithObject:@"PBtype"]
								    owner: nil];
    [pboard setData: data forType:@"PBType"];
    return YES;
}

- (void)search:(id)sender {
    [self rearrangeObjects];    
}

- (NSArray *)arrangeObjects:(NSArray *)objects {
    NSMutableArray *arrangedObjects;
    id item;
    int index, count;
    NSString *searchString = [searchField stringValue];
    
    if ([searchString isEqual:@""]) {
        return [super arrangeObjects:objects];   
    }
    count = [objects count];
    arrangedObjects = [NSMutableArray arrayWithCapacity:count];
    
    for (index=0; index < count; index++) {
        item = [objects objectAtIndex:index];
        if ([[item valueForKeyPath:@"articleYear"] rangeOfString:searchString].location != NSNotFound) {
            [arrangedObjects addObject:item];
        }
	else if ([[item valueForKeyPath:@"articleTitle"] rangeOfString:searchString].location != NSNotFound) {
	    [arrangedObjects addObject:item];
	}
	else if ([[item valueForKeyPath:@"articleAuthorsAsString"] rangeOfString:searchString].location != NSNotFound) {
	    [arrangedObjects addObject:item];
	}
	else if ([[item valueForKeyPath:@"articleJournal"] rangeOfString:searchString].location != NSNotFound) {
	    [arrangedObjects addObject:item];
	}
    }
    
    return [super arrangeObjects:arrangedObjects];
}

- (void)associatePDFFileWithArticle:(id)sender {
    NSMutableString *newPath=[[NSMutableString alloc] init];

    NSString *result;
    NSOpenPanel *panel=[NSOpenPanel openPanel];
    result = [panel runModalForDirectory:NSHomeDirectory()
                                    file:nil types:[NSImage imageFileTypes]];
    
    if (result !=NSCancelButton) {
        [[[self arrangedObjects] objectAtIndex:[self selectionIndex]] setURLToPDFFile:[[panel URLs] objectAtIndex:0]];
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"renameFiles"] boolValue]==YES) {
	    [[[self selectedObjects] objectAtIndex:0] renameFile];
	}
	NSLog(@"done renaming");
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"consolidateLibrary"] boolValue]==YES ) {
	    NSLog(@"consolidating");
	    [newPath appendString:[[NSUserDefaults standardUserDefaults] valueForKey:@"libraryLocation"]];
	    NSLog(@"newPath=%@",newPath);
	    newPath=[newPath stringByAppendingPathComponent:[[self valueForKeyPath:@"selection.articleAuthors"] lastObject]];
	    [[NSFileManager defaultManager] createDirectoryAtPath:newPath attributes:nil];
	    
	    newPath=[newPath stringByAppendingPathComponent:[[self valueForKeyPath:@"selection.URLToPDFFile"] lastPathComponent]];
	    NSLog(@"newPath=%@",newPath);
	    
	    [[NSFileManager defaultManager] movePath:[self valueForKeyPath:@"selection.URLToPDFFile"] toPath:newPath handler:nil];
	    [self setValue:[NSURL fileURLWithPath:newPath] forKeyPath:@"selection.URLToPDFFile"];
	    
	    //[sender setValue:newPath forKeyPath:@"url"];
	}
        NSLog(@"filename=%@",[[panel URLs] objectAtIndex:0]);
    }
}

-(IBAction)imageViewURLChanged:(id)sender {
    NSMutableString *newPath=[[NSMutableString alloc] init];
    [self setValue:[sender valueForKey:@"url"] forKeyPath:@"selection.URLToPDFFile"];
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"renameFiles"] boolValue]==YES) {
	[[[self selectedObjects] objectAtIndex:0] renameFile];
    }
    NSLog(@"done renaming");
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"consolidateLibrary"] boolValue]==YES ) {
	NSLog(@"consolidating");
	[newPath appendString:[[NSUserDefaults standardUserDefaults] valueForKey:@"libraryLocation"]];
	NSLog(@"newPath=%@",newPath);
	newPath=[newPath stringByAppendingPathComponent:[[self valueForKeyPath:@"selection.articleAuthors"] lastObject]];
	[[NSFileManager defaultManager] createDirectoryAtPath:newPath attributes:nil];
	
	newPath=[newPath stringByAppendingPathComponent:[[self valueForKeyPath:@"selection.URLToPDFFile"] lastPathComponent]];
	NSLog(@"newPath=%@",newPath);
	
	[[NSFileManager defaultManager] movePath:[self valueForKeyPath:@"selection.URLToPDFFile"] toPath:newPath handler:nil];
	[self setValue:[NSURL fileURLWithPath:newPath] forKeyPath:@"selection.URLToPDFFile"];
	
	//[sender setValue:newPath forKeyPath:@"url"];
    }
    [sender setValue:[self valueForKeyPath:@"selection.URLToPDFFile"] forKey:@"url"];
}

-(void)renameFile:(id)sender {
    [[[self selectedObjects] objectAtIndex:0] renameFile];
}


-(void)openReferenceInBrowser:(id)sender {
    NSLog(@"double Clicked article ref");
    NSString *referenceLink=[NSString stringWithFormat:@"http://www.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=pubmed&id=%@&retmode=ref&cmd=prlinks",[[self selection] valueForKey:@"referencePMID"]];
    
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:referenceLink]];
}

@end
