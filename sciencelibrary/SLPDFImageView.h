/* SLPDFImageView */

#import <Cocoa/Cocoa.h>

@interface SLPDFImageView : NSImageView
{
    NSURL *url;
    IBOutlet NSArrayController *SLArticleController;
    //IBOutlet id *SLMainController;
}

- (NSURL *)url;
- (void)setUrl:(NSURL *)newUrl;

@end
