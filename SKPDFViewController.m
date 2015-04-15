//
//  SKViewController.m
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-05-09.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import "SKPDFViewController.h"
#import "SKPDFView.h"

@interface SKPDFViewController ()

@end

@implementation SKPDFViewController

@synthesize pdfFilePath = _pdfFilePath;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(_pdfFilePath)
    {
        NSURL* pdfURL = [[NSURL alloc] initFileURLWithPath:_pdfFilePath];
        pdfDocument = CGPDFDocumentCreateWithURL((__bridge CFURLRef)pdfURL);
        
        // Open initial page
        [self openPage:1];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark SKViewControllerNavigation

- (void)openPage:(int)pageNumber
{
    CGPDFPageRef PDFPage = CGPDFDocumentGetPage(pdfDocument, pageNumber);
    [(SKPDFView *)self.view setPDFPage:PDFPage];
    
    [super openPage:pageNumber];
}

@end
