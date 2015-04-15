//
//  SKLocalViewController.m
//  SkimMobile
//
//  Created by Sylvain Bouchard on 2014-10-24.
//  Copyright (c) 2014 Sylvain Bouchard. All rights reserved.
//

#import "SKLocalViewController.h"

@interface SKLocalViewController ()

@end

@implementation SKLocalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated
{
    // Reset contents
    [self.contents removeAllObjects];
    
    int Count;
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.appDocumentsDirectory
                                                                                    error:NULL];
    for (Count = 0; Count < (int)[directoryContent count]; Count++)
    {
        NSString* fileName = [directoryContent objectAtIndex:Count];
        [self.contents addObject:fileName];
    }
    
    // Refresh tableview
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LocalFileCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [self.contents objectAtIndex:indexPath.row];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* fileName = [self.contents objectAtIndex:indexPath.row];
    NSString* filePath = [self.appDocumentsDirectory stringByAppendingPathComponent:fileName];

    // Remove the actual file in store
    NSError *error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        if (![[NSFileManager defaultManager] removeItemAtPath:filePath error:&error])
        {
            NSLog(@"Delete file error: %@", error);
        }
    }
    
    // Update tableview file list
    [self.contents removeObjectAtIndex:indexPath.row];
    
    // Refresh tableview
    [self.tableView reloadData];
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* fileName = [self.contents objectAtIndex:indexPath.row];
    NSString* filePath = [self.appDocumentsDirectory stringByAppendingPathComponent:fileName];
    [self loadFileInController:filePath];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
