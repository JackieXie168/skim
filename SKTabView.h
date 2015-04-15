//
//  SKTabView.h
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-04-27.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SKTabView : UIView

@property (nonatomic, strong) UIImage *tabButtonNormal;
@property (nonatomic, strong) UIImage *tabButtonHighlight;

@property (nonatomic, strong) UIButton *tabButton;
@property (nonatomic, strong) UIImageView *imageView;

@end
