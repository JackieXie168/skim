//
//  SKMultiTabViewController.h
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-06-05.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SKMultiTabViewController : UITabBarController

@property (weak, nonatomic) IBOutlet UISegmentedControl *leftRightSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *upDownSegmentedControl;

- (void)leftRightControlAction:(id)sender forEvent:(UIEvent *)event;
- (void)upDownControlAction:(id)sender forEvent:(UIEvent *)event;

@end
