//
//  SKDetailViewController.h
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-08-05.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SKDetailViewController : UIViewController <UIPopoverControllerDelegate, UISplitViewControllerDelegate>

@property (nonatomic, retain) UIPopoverController *popoverController;

@end
