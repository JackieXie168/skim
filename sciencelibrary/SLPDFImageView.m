#import "SLPDFImageView.h"
#import "reference.h"
@implementation SLPDFImageView
//delegate methods for PDFImageView

-(void) awakeFromNib {
    [self registerForDraggedTypes: [NSArray arrayWithObjects:NSURLPboardType,NSFilenamesPboardType, nil]];

}

-(void)mouseDown:(NSEvent *)event {
    if([event clickCount]==2) {
	[[NSWorkspace sharedWorkspace] openURL:[SLArticleController valueForKeyPath:@"selection.URLToPDFFile"]];
    }
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    NSLog(@"draggingEntered");
    if ([[pboard types] containsObject:NSURLPboardType] ) {
	NSLog(@"pboard has URL");
        
            return NSDragOperationLink;
        
    }
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
	NSLog(@"pboard has filenames");
	return NSDragOperationLink;
    }
    
    return NSDragOperationNone;
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSURLPboardType] ) {
        NSURL *fileURL = [NSURL URLFromPasteboard:pboard];
        //[[[SLArticleController arrangedObjects] objectAtIndex:[SLArticleController selectionIndex]] setURLToPDFFile:fileURL];
	[fileURL autorelease];
	return YES;

    }
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:[[pboard propertyListForType:NSFilenamesPboardType] objectAtIndex:0]];
	[self setValue:fileURL forKey:@"url"];
	//[SLMainController imageViewURLChanged:self];

	//[SLArticleController setValue:fileURL forKeyPath:@"selection.URLToPDFFile"];
	
        //NSLog(@"kvc: %@",[SLArticleController valueForKeyPath:@"selection.URLToPDFFile"]);
	
	
	[fileURL release];

	return YES;
	
    }
    return NO;
    
}

// - url:
- (NSURL *)url { return url; }

    // - setUrl:
- (void)setUrl:(NSURL *)newUrl
{
    if (url != newUrl)
    {
        [url release];
        url = [newUrl copy];
    }
}

@end
