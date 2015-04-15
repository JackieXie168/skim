//
//  SKDjvuViewController.h
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-06-11.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SKViewController.h"

@class SKDjvuView;
@class SKDjvuParser;
@class SKDjvuTextSelectionView;

@interface SKDjvuViewController : SKViewController
{
    // Image representing the current page
    UIImage* djvuPageImage;
    
    // Current DJVU image zoom scale
    CGSize djvuScale;    
}

@property (strong, nonatomic) SKDjvuParser* djvuParser;
@property (strong, nonatomic) IBOutlet SKDjvuView *djvuView;
@property (strong, nonatomic) NSString* djvuFilePath;

- (void)openPage:(int)pageNumber;

@end