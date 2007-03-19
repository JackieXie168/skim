#import "BDSKFileMatchConfigController.h"
#import "BibDocument.h"
#import "BDSKOrphanedFilesFinder.h"

@implementation BDSKFileMatchConfigController

- (id)init
{
    self = [super init];
    if (self) {
        documents = [NSMutableArray new];
        files = [NSMutableArray new];
        useOrphanedFiles = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentAddRemove:) name:BDSKDocumentControllerRemoveDocumentNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentAddRemove:) name:BDSKDocumentControllerAddDocumentNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [documents release];
    [files release];
    [super dealloc];
}


- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSOKButton)
		[[self mutableArrayValueForKey:@"files"] addObjectsFromArray:[panel URLs]];
}

- (IBAction)add:(id)sender;
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setPrompt:NSLocalizedString(@"Choose", @"")];
    [openPanel beginSheetForDirectory:nil file:nil types:nil modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction)remove:(id)sender;
{
    [fileArrayController removeSelectedObjects:[fileArrayController selectedObjects]];
}

- (IBAction)selectAllDocuments:(id)sender;
{
    BOOL flag = (BOOL)[sender tag];
    [documents setValue:[NSNumber numberWithBool:flag] forKeyPath:@"useDocument"];
}

- (void)handleDocumentAddRemove:(NSNotification *)note
{
    NSArray *docs = [[NSDocumentController sharedDocumentController] documents];
    NSEnumerator *e = [docs objectEnumerator];
    NSMutableArray *array = [NSMutableArray array];
    NSDocument *doc;
    while (doc = [e nextObject]) {
        NSString *docType = [[[NSDocumentController sharedDocumentController] fileExtensionsFromType:[doc fileType]] lastObject];
        if (nil == docType)
            docType = @"";
        NSDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[doc displayName], OATextWithIconCellStringKey, [NSImage imageForFileType:docType], OATextWithIconCellImageKey, [NSNumber numberWithBool:NO], @"useDocument", doc, @"document", nil];
        [array addObject:dict];
    }
    [self setDocuments:array];
}

- (void)awakeFromNib
{
    [self handleDocumentAddRemove:nil];
    [fileTableView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
}

// fix a zombie issue
- (void)windowWillClose:(NSNotification *)note
{
    [documentTableView setDataSource:nil];
    [documentTableView setDelegate:nil];
    [fileTableView setDataSource:nil];
    [fileTableView setDelegate:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setDocuments:(NSArray *)docs;
{
    [documents autorelease];
    documents = [docs mutableCopy];
}

- (NSArray *)documents { return documents; }

- (void)setFiles:(NSArray *)newFiles;
{
    [files autorelease];
    files = [newFiles mutableCopy];
}

- (NSArray *)files { return files; }

- (NSArray *)publications;
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"useDocument == YES"];
    return [[documents filteredArrayUsingPredicate:predicate] valueForKeyPath:@"@unionOfArrays.document.publications"];
}

- (BOOL)useOrphanedFiles;
{
    return useOrphanedFiles;
}

- (void)setUseOrphanedFiles:(BOOL)flag;
{
    useOrphanedFiles = flag;
    if (flag)
        [[self mutableArrayValueForKey:@"files"] addObjectsFromArray:[[BDSKOrphanedFilesFinder sharedFinder] orphanedFiles]];
    else
        [[self mutableArrayValueForKey:@"files"] removeObjectsInArray:[[BDSKOrphanedFilesFinder sharedFinder] orphanedFiles]];
}
    
- (NSString *)windowNibName { return @"FileMatcherConfigSheet"; }

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    [tv setDropRow:-1 dropOperation:NSTableViewDropOn];
    return NSDragOperationLink;
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op;
{
    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *types = [pboard types];
    if ([types containsObject:NSFilenamesPboardType]) {
        NSArray *newFiles = [pboard propertyListForType:NSFilenamesPboardType];
        if ([newFiles count]) {
            NSMutableArray *URLs = [NSMutableArray array];
            NSEnumerator *e = [newFiles objectEnumerator];
            NSString *path;
            while (path = [e nextObject]) 
                [URLs addObject:[NSURL fileURLWithPath:path]];
            [[self mutableArrayValueForKey:@"files"] addObjectsFromArray:URLs];
        }
        return YES;
    }
    return NO;
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView { return 0; }
- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tc row:(int)r { return nil; }

@end
