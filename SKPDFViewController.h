//
//  SKViewController.h
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-05-09.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SKViewController.h"

@interface SKPDFViewController : SKViewController
{
    CGPDFDocumentRef pdfDocument;
}

@property (strong, nonatomic) NSString* pdfFilePath;

- (void)openPage:(int)pageNumber;

@end
