//
//  SKFileViewController.h
//  SkimMobile
//
//  Created by Sylvain Bouchard on 2014-10-24.
//  Copyright (c) 2014 Sylvain Bouchard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SKFileViewController : UITableViewController

@property (nonatomic, retain) NSMutableArray *contents;
@property (nonatomic, retain) NSString* appDocumentsDirectory;

-(void)loadFileInController:(NSString*)localPath;

@end