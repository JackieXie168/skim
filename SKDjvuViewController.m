//
//  SKDjvuViewController.m
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-06-11.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import "SKDjvuViewController.h"
#import "SKDjvuParser.h"
#import "SKTextArea.h"
#import "SKDjvuView.h"

@interface SKDjvuViewController ()
{
    // Bounding boxes for all words in the document
    NSMutableArray* wordsBoundingBoxes;
}
@end

@implementation SKDjvuViewController

@synthesize djvuView = _djvuView, djvuParser = _djvuParser;
@synthesize djvuFilePath = _djvuFilePath;

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
        
    if(_djvuFilePath)
    {
        wordsBoundingBoxes = [NSMutableArray array];
        _djvuParser = [[SKDjvuParser alloc]initWithPath:_djvuFilePath];
        
        // Display first page now
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
    // Ask the DJVU parser to generate the image for the given page number
    djvuPageImage = [_djvuParser imageForPage:pageNumber ofSize:CGSizeZero];
    
    // Determine the size of the DJVU page.
    CGRect pageRect = CGRectMake(0, 0, djvuPageImage.size.width, djvuPageImage.size.height);
    
    // Compute scaling separately for width and height
    djvuScale.width = [[UIScreen mainScreen] bounds].size.width/pageRect.size.width;
    djvuScale.height = [[UIScreen mainScreen] bounds].size.height/pageRect.size.height;
    
    // Pass the image to the view so that it can be displayed at the given scale
    [(SKDjvuView *)self.view setDjvuPage:djvuPageImage.CGImage withScale:djvuScale];
    
    // Extract page text
    NSMutableArray* allExtractedTextAreas = [NSMutableArray array];
    [_djvuParser textForPage:pageNumber returnAreas:allExtractedTextAreas];
    
    // Keep only the areas of type "word"
    [wordsBoundingBoxes removeAllObjects];
    for(SKTextArea* aTextArea in allExtractedTextAreas)
    {
        if(aTextArea.type == TextAreaWord)
        {
            // Adjust word bounding box coordinates
            [aTextArea apply2DScalingOf:djvuScale];
            [self flipUpsideDown:aTextArea];

            [wordsBoundingBoxes addObject:aTextArea];
        }
    }
    
    // Pass the areas to the view so that they can be displayed
    [self.djvuView setTextBoundingRects:wordsBoundingBoxes];
    
    // Clear text selection view
    [self.djvuView clearSelections];
    
    [super openPage:pageNumber];
}


#pragma mark -
#pragma mark private

- (void)flipUpsideDown:(SKTextArea*)textArea
{
    CGAffineTransform af = CGAffineTransformMakeTranslation(0.0, [[UIScreen mainScreen] bounds].size.height);
    af = CGAffineTransformScale(af, 1.0, -1.0);
    
    textArea.boundingRect = CGRectApplyAffineTransform(textArea.boundingRect, af);
}

@end
