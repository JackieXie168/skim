//
//  SKMultiTabViewController.m
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-06-05.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import "SKMultiTabViewController.h"
#import "SKViewController.h"
#import "UIImage_SKExtensions.h"

@interface SKMultiTabViewController ()

@end

@implementation SKMultiTabViewController

@synthesize leftRightSegmentedControl = _leftRightSegmentedControl;
@synthesize upDownSegmentedControl = _upDownSegmentedControl;

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
    
    // Create raster image icons
    [UIImage makeImages];
    
    [self.leftRightSegmentedControl setImage:toolbarBackImage forSegmentAtIndex:0];
    [self.leftRightSegmentedControl setImage:toolbarForwardImage forSegmentAtIndex:1];
    [self.upDownSegmentedControl setImage:toolbarPageUpImage forSegmentAtIndex:1];
    [self.upDownSegmentedControl setImage:toolbarPageDownImage forSegmentAtIndex:0];

    self.leftRightSegmentedControl.momentary = TRUE;
    self.upDownSegmentedControl.momentary = TRUE;
    
    [self.leftRightSegmentedControl addTarget:self action:@selector(leftRightControlAction:forEvent:)
                            forControlEvents:UIControlEventValueChanged];
    [self.upDownSegmentedControl addTarget:self action:@selector(upDownControlAction:forEvent:)
                             forControlEvents:UIControlEventValueChanged];
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
        
        // Get a reference on current root view controller
        SKViewController* selectedController = (SKViewController*)self.selectedViewController;
        if(selectedSegment == 0)
        {
            [selectedController previousPageInHistory];
        }
        else if(selectedSegment == 1)
        {
            [selectedController nextPageInHistory];
        }
    }
}

- (void)upDownControlAction:(id)sender forEvent:(UIEvent *)event
{
    if([sender isKindOfClass:[UISegmentedControl class]])
    {
        UISegmentedControl *segmentedControl = (UISegmentedControl *) sender;
        NSInteger selectedSegment = segmentedControl.selectedSegmentIndex;
                
        // Get a reference on current root view controller
        SKViewController* selectedController = (SKViewController*)self.selectedViewController;
        if(selectedSegment == 0)
        {
            [selectedController previousPage];
        }
        else if(selectedSegment == 1)
        {
            [selectedController nextPage];
        }
    }
}

@end