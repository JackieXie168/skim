//
//  SKViewController.h
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-06-13.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SKViewControllerNavigatable.h"

@interface SKViewController : UIViewController<SKViewControllerNavigatable>
{
    int currentPageNumber;
    int historyPositionIndex;
    NSMutableArray* pageNumberHistory;
}

- (void)openPage:(int)pageNumber;
- (void)nextPage;
- (void)previousPage;
- (void)nextPageInHistory;
- (void)previousPageInHistory;

@end
