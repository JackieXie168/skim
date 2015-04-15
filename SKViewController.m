//
//  SKViewController.m
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-06-13.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import "SKViewController.h"
#import "UIImage_SKExtensions.h"

@interface SKViewController ()

@end

@implementation SKViewController

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

    [UIImage makeImages];
    
    // Init page history
    pageNumberHistory = [NSMutableArray array];
    
    // Create the segmented control
    NSArray* itemArray = [NSArray arrayWithObjects:toolbarPageUpImage, toolbarPageDownImage, nil];
    UISegmentedControl* segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar; segmentedControl.momentary = YES;
    [segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    
    // Add it to the navigation bar
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    [self.navigationItem setRightBarButtonItem:rightButtonItem];
    
    // Add swipe gesture
    UISwipeGestureRecognizer *aSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGesture:)];
    [aSwipeGesture setDirection:UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight];
    aSwipeGesture.numberOfTouchesRequired = 2;
    [self.view addGestureRecognizer:aSwipeGesture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)openPage:(int)pageNumber
{
    currentPageNumber = pageNumber;
    
    // Keep track of navigation in history
    [pageNumberHistory addObject:@(pageNumber)];
}

- (void)segmentAction:(id)sender
{
    if([sender isKindOfClass:[UISegmentedControl class]])
    {
        UISegmentedControl *segmentedControl = (UISegmentedControl *) sender;
        NSInteger selectedSegment = segmentedControl.selectedSegmentIndex;
        
        if(selectedSegment == 0)
        {
            [self previousPage];
        }
        else if(selectedSegment == 1)
        {
            [self nextPage];
        }
    }
}

- (void)swipeGesture:(UISwipeGestureRecognizer *)sender
{
    NSLog(@"Swipe received.");
    if(sender.direction == UISwipeGestureRecognizerDirectionLeft)
    {
        NSLog(@"swipe left");
    }
    else if(sender.direction == UISwipeGestureRecognizerDirectionRight)
    {
        NSLog(@"swipe right");
    }
}

- (void)nextPage
{
    [self openPage:++currentPageNumber];
}

- (void)previousPage
{
    if(currentPageNumber > 0)
    {
        [self openPage:--currentPageNumber];
    }
}

- (void)nextPageInHistory
{
    if(historyPositionIndex < (pageNumberHistory.count - 1))
    {
        historyPositionIndex++;
        
        int pageNumber = [[pageNumberHistory objectAtIndex:historyPositionIndex] intValue];
        [self openPage:pageNumber];
    }
}

- (void)previousPageInHistory
{
    if(historyPositionIndex > 0)
    {
        historyPositionIndex--;
        
        int pageNumber = [[pageNumberHistory objectAtIndex:historyPositionIndex] intValue];
        [self openPage:pageNumber];
    }
}

@end
