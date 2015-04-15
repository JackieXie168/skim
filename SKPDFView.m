//
//  SKPDFView.m
//  SkimMobile
//
//  Created by Sylvain Bouchard on 13-04-27.
//  Copyright (c) 2013 Sylvain Bouchard. All rights reserved.
//

#import "SKPDFView.h"
#import "TiledPDFView.h"

@interface SKPDFView()

// A low resolution image of the PDF page that is displayed until the TiledPDFView renders its content.
@property (nonatomic, weak) UIImageView *backgroundImageView;

// The TiledPDFView that is currently front most.
@property (nonatomic, weak) TiledPDFView *tiledPDFView;

// The old TiledPDFView that we draw on top of when the zooming stops.
@property (nonatomic, weak) TiledPDFView *oldTiledPDFView;

@end

@implementation SKPDFView
{
    CGPDFPageRef _PDFPage;
    
    // Current PDF zoom scale.
    CGFloat _PDFScale;
}

@synthesize backgroundImageView = _backgroundImageView, tiledPDFView = _tiledPDFView, oldTiledPDFView = _oldTiledPDFView;

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;
    }
    return self;
}

- (void)setPDFPage:(CGPDFPageRef)PDFPage
{
    CGPDFPageRetain(PDFPage);
    CGPDFPageRelease(_PDFPage);
    _PDFPage = PDFPage;
    
    // Determine the size of the PDF page.
    CGRect pageRect = CGPDFPageGetBoxRect(_PDFPage, kCGPDFMediaBox);
    _PDFScale = self.frame.size.width/pageRect.size.width;
    pageRect.size = CGSizeMake(pageRect.size.width*_PDFScale, pageRect.size.height*_PDFScale);
    
    // Create the TiledPDFView based on the size of the PDF page and scale it to fit the view.
    TiledPDFView *tiledPDFView = [[TiledPDFView alloc] initWithFrame:pageRect scale:_PDFScale];
    [tiledPDFView setPage:_PDFPage];
    
    [self addSubview:tiledPDFView];
    self.tiledPDFView = tiledPDFView;
}

- (void)dealloc
{
    // Clean up.
    CGPDFPageRelease(_PDFPage);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Center the image as it becomes smaller than the size of the screen.
    
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.tiledPDFView.frame;
    
    // Center horizontally.
    
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // Center vertically.
    
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    self.tiledPDFView.frame = frameToCenter;
    
    /*
     To handle the interaction between CATiledLayer and high resolution screens, set the tiling view's contentScaleFactor to 1.0.
     If this step were omitted, the content scale factor would be 2.0 on high resolution screens, which would cause the CATiledLayer to ask for tiles of the wrong scale.
     */
    self.tiledPDFView.contentScaleFactor = 1.0;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.tiledPDFView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    // Remove back tiled view.
    [self.oldTiledPDFView removeFromSuperview];
    
    // Set the current TiledPDFView to be the old view.
    self.oldTiledPDFView = self.tiledPDFView;
    [self addSubview:self.oldTiledPDFView];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    // Set the new scale factor for the TiledPDFView.
    _PDFScale *= scale;
    
    // Calculate the new frame for the new TiledPDFView.
    CGRect pageRect = CGPDFPageGetBoxRect(_PDFPage, kCGPDFMediaBox);
    pageRect.size = CGSizeMake(pageRect.size.width*_PDFScale, pageRect.size.height*_PDFScale);
    
    // Create a new TiledPDFView based on new frame and scaling.
    TiledPDFView *tiledPDFView = [[TiledPDFView alloc] initWithFrame:pageRect scale:_PDFScale];
    [tiledPDFView setPage:_PDFPage];
    
    // Add the new TiledPDFView to the PDFScrollView.
    [self addSubview:tiledPDFView];
    self.tiledPDFView = tiledPDFView;
}

@end
