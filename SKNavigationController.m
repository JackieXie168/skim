//
//  SKNavigationController.m
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-08-05.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import "SKNavigationController.h"
#import "SKViewController.h"
#import "UIImage_SKExtensions.h"

@interface SKNavigationController ()

@end

@implementation SKNavigationController

@synthesize leftRightSegmentedControl = _leftRightSegmentedControl;
@synthesize upDownSegmentedControl = _upDownSegmentedControl;
@synthesize selectedViewController = _selectedViewController;

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

    NSArray *items = [[NSArray alloc] initWithObjects:[UIImage imageNamed:@"UpArrow.png"], [UIImage imageNamed:@"DownArrow.png"], nil];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    segmentedControl.momentary = YES;
    [segmentedControl addTarget:self action:@selector(segmentedControlTapped:) forControlEvents:UIControlEventValueChanged];
    
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    [self.navigationItem setRightBarButtonItem:rightBarButton animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)leftRightControlAction:(id)sender forEvent:(UIEvent *)event
{
    if([sender isKindOfClass:[UISegmentedControl class]])
    {
        UISegmentedControl *segmentedControl = (UISegmentedControl *) sender;
        NSInteger selectedSegment = segmentedControl.selectedSegmentIndex;
        
        NSLog(@"Segmented Control event received: %@:%@", sender, event);
        NSLog(@"Segment selected: %d", selectedSegment);
        
        if(selectedSegment == 0)
        {
            [_selectedViewController previousPageInHistory];
        }
        else if(selectedSegment == 1)
        {
            [_selectedViewController nextPageInHistory];
        }
    }
}

- (void)upDownControlAction:(id)sender forEvent:(UIEvent *)event
{
    if([sender isKindOfClass:[UISegmentedControl class]])
    {
        UISegmentedControl *segmentedControl = (UISegmentedControl *) sender;
        NSInteger selectedSegment = segmentedControl.selectedSegmentIndex;
        
        if(selectedSegment == 0)
        {
            [_selectedViewController previousPage];
        }
        else if(selectedSegment == 1)
        {
            [_selectedViewController nextPage];
        }
    }
}

@end
