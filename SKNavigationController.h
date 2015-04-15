//
//  SKNavigationController.h
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-08-05.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SKViewController;

@interface SKNavigationController : UINavigationController

@property (strong, nonatomic) UISegmentedControl *leftRightSegmentedControl;
@property (strong, nonatomic) UISegmentedControl *upDownSegmentedControl;
@property (strong, nonatomic) SKViewController *selectedViewController;

- (void)leftRightControlAction:(id)sender forEvent:(UIEvent *)event;
- (void)upDownControlAction:(id)sender forEvent:(UIEvent *)event;

@end