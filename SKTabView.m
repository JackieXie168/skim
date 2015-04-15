//
//  SKTabView.m
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-04-27.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import "SKTabView.h"

@implementation SKTabView

@synthesize tabButtonNormal = _tabButtonNormal;
@synthesize tabButtonHighlight = _tabButtonHighlight;
@synthesize tabButton = _tabButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _tabButtonNormal = [UIImage imageNamed:@"UnselectedButton"];
        _tabButtonHighlight = [UIImage imageNamed:@"PushedDownButton"];
        
        [_tabButton setBackgroundImage:_tabButtonNormal forState:UIControlStateNormal];
        [_tabButton setBackgroundImage:_tabButtonHighlight forState:UIControlStateHighlighted];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _imageView.frame = self.bounds;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
