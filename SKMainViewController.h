//
//  SKMainViewController.h
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-11-17.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SKMainViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)linkToDropbox:(id)sender;
- (IBAction)uploadToDropbox:(id)sender;
- (IBAction)listFiles:(id)sender;
- (void)loadFileInController:(NSString*)localPath;

@end