//
//  SKCloudViewController.m
//  SkimMobile
//
//  Created by Sylvain Bouchard on 2014-10-24.
//  Copyright (c) 2014 Sylvain Bouchard. All rights reserved.
//

#import "SKCloudViewController.h"
#import <DropboxSDK/DropboxSDK.h>

@interface SKCloudViewController () <DBRestClientDelegate>

@property (nonatomic, readonly) DBRestClient *restClient;

@end

@implementation SKCloudViewController

@synthesize restClient = _restClient;
@synthesize currentDirectory = _currentDirectory;

- (DBRestClient *)restClient {
    if (!_restClient) {
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    if (![[DBSession sharedSession] isLinked])
    {
        [[DBSession sharedSession] linkFromController:self];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    if(_currentDirectory == nil)
    {
        [[self restClient] loadMetadata:@"/"];
    }
    else
    {
        NSString* path = [NSString stringWithFormat:@"/%@", _currentDirectory];
        [[self restClient] loadMetadata:path];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CloudFileCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    DBMetadata* file = (DBMetadata*)[self.contents objectAtIndex:indexPath.row];
    cell.textLabel.text = file.filename;

    return cell;
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DBMetadata* file = (DBMetadata*)[self.contents objectAtIndex:indexPath.row];
    
    if(file.isDirectory)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
        SKCloudViewController *cloudViewController = [storyboard instantiateViewControllerWithIdentifier:@"SKCloudViewController"];
        cloudViewController.currentDirectory = file.filename;
        
        [self.navigationController pushViewController:cloudViewController animated:TRUE];
    }
    else
    {
        // Download file
        NSString *filePath = [self.appDocumentsDirectory stringByAppendingPathComponent:file.filename];
        
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
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
        
        NSSortDescriptor *sortDescriptor;
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"path" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        [self.contents sortUsingDescriptors:sortDescriptors];
        
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

@end
