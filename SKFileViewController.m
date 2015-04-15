//
//  SKFileViewController.m
//  SkimMobile
//
//  Created by Sylvain Bouchard on 2014-10-24.
//  Copyright (c) 2014 Sylvain Bouchard. All rights reserved.
//

#import "SKFileViewController.h"
#import "SKPDFViewController.h"
#import "SKDjvuViewController.h"

@interface SKFileViewController ()

@end

@implementation SKFileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationController.navigationBar.translucent = NO;
    
    // Set application document directory
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    self.appDocumentsDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:appName];
    
    // Create it if it does not exist
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.appDocumentsDirectory])
    {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:self.appDocumentsDirectory
                                             withIntermediateDirectories:NO
                                             attributes:nil error:&error])
        {
            NSLog(@"Create app directory error: %@", error);
        }
    }
    self.contents = [[NSMutableArray alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.contents count];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
