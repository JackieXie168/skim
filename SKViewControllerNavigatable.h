//
//  SKViewController.h
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-06-13.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SKViewControllerNavigatable <NSObject>

- (void)openPage:(int)pageNumber;
- (void)nextPage;
- (void)previousPage;
- (void)nextPageInHistory;
- (void)previousPageInHistory;

@end