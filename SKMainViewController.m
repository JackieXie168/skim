//
//  SKMainViewController.m
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-11-17.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import "SKMainViewController.h"
#import "SKDjvuViewController.h"
#import "SKPDFViewController.h"
#import "SKAppDelegate.h"
#import "DropboxSDK/DropboxSDK.h"

@interface SKMainViewController () <DBRestClientDelegate>

@property (nonatomic, retain) NSMutableArray *contents;
@property (nonatomic, retain) UITableViewCell *loadingCell;
@property (nonatomic, assign) BOOL loadingFiles;
@property (nonatomic, readonly) DBRestClient *restClient;

@end

@implementation SKMainViewController

@synthesize restClient = _restClient;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (DBRestClient *)restClient {
    if (!_restClient) {
        _restClient =
        [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIViewController methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.contents count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
	static NSString *CellIdentifier = @"SettingsCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if(!cell)
    {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
    
    DBMetadata* file = (DBMetadata*)[self.contents objectAtIndex:indexPath.row];
    cell.textLabel.text = file.filename;

	return cell;
}

- (IBAction)linkToDropbox:(id)sender
{
    if (![[DBSession sharedSession] isLinked])
    {
        SKAppDelegate* appDelegate = (SKAppDelegate*)[[UIApplication sharedApplication] delegate];
        [[DBSession sharedSession] linkFromController:[appDelegate.window rootViewController]];
    }
}

- (IBAction)uploadToDropbox:(id)sender
{
    NSString *localPath = [[NSBundle mainBundle] pathForResource:@"Introduction to stochastic processes" ofType:@"djvu"];
    NSString *filename = @"Introduction to stochastic processes.djvu";
    NSString *destDir = @"/";
    [[self restClient] uploadFile:filename toPath:destDir withParentRev:nil fromPath:localPath];
}

- (IBAction)listFiles:(id)sender
{
    [[self restClient] loadMetadata:@"/"];
}

#pragma mark - DBRestClientDelegate

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata
{
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error
{
    NSLog(@"File upload failed with error - %@", error);
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
    if (metadata.isDirectory)
    {
        self.contents = [NSMutableArray arrayWithArray:metadata.contents];
        [self.contents sortUsingFunction:sortFileInfos context:NULL];
        
        [self.tableView reloadData];
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
    NSLog(@"Error loading metadata: %@", error);
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath contentType:(NSString*)contentType metadata:(DBMetadata*)metadata
{
    NSLog(@"File loaded into path: %@", localPath);
    
    [self loadFileInController:localPath];
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
{
    NSLog(@"There was an error loading the file - %@", error);
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DBMetadata* file = (DBMetadata*)[self.contents objectAtIndex:indexPath.row];
    
    // Download file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents directory
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:file.filename];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    if(!fileExists)
    {
        [self.restClient loadFile:file.path intoPath:filePath];
    }
    else
    {
        [self loadFileInController:filePath];
    }
}

#pragma mark - private methods

NSInteger sortFileInfos(id obj1, id obj2, void *ctx)
{
	return [[obj1 path] compare:[obj2 path]];
}

-(void)loadFileInController:(NSString*)localPath
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
    if([localPath rangeOfString:@"djvu"].location != NSNotFound)
    {
        SKDjvuViewController *djvuViewController = [storyboard instantiateViewControllerWithIdentifier:@"DjvuViewController"];
        djvuViewController.djvuFilePath = localPath;
        
        [self.navigationController pushViewController:djvuViewController animated:TRUE];
    }
    else if([localPath rangeOfString:@"pdf"].location != NSNotFound)
    {
        SKPDFViewController *pdfViewController = [storyboard instantiateViewControllerWithIdentifier:@"PdfViewController"];
        pdfViewController.pdfFilePath = localPath;
        
        [self.navigationController pushViewController:pdfViewController animated:TRUE];
    }
}

@end
