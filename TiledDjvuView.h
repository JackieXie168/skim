//
//  TiledDjvuView.h
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-06-12.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SKDjvuTextLayer.h"

@interface TiledDjvuView : UIView

- (id)initWithFrame:(CGRect)frame;
- (void)setPage:(CGImageRef)newPage;

@property (atomic) CGFloat scale;
@property (atomic, readonly) SKDjvuTextLayer* textLayer;

@end