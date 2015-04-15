//
//  SKPDFView.h
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-04-27.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SKPDFView : UIScrollView <UIScrollViewDelegate>

- (void)setPDFPage:(CGPDFPageRef)PDFPage;

@end