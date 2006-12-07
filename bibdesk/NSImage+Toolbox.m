//
//  NSImage+Toolbox.m
//  Bibdesk
//
//  Created by Sven-S. Porst on Thu Jul 29 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "NSImage+Toolbox.h"
/* ssp: 30-07-2004 

	A category on NSImage that creates an NSImage containing an icon from the system specified by an OSType.
	LIMITATION: This always creates 32x32 images as are useful for toolbars.
 
	Code taken from http://cocoa.mamasam.com/MACOSXDEV/2002/01/2/22427.php
*/

@implementation NSImage (Toolbox)
+ (NSImage*) imageWithLargeIconForToolboxCode:(OSType) code {
	int width = 32;
	int height = 32;
	IconRef iconref;
	OSErr myErr = GetIconRef (kOnSystemDisk, 'macs', code, &iconref);
	
	NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(width,height)]; 
	[image lockFocus]; 
	
	CGRect rect =  CGRectMake(0,0,width,height);
	
	PlotIconRefInContext((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort],
						&rect,
						 kAlignNone,
						 kTransformNone,
						 NULL /*inLabelColor*/,
						 kPlotIconRefNormalFlags,
						 iconref); 
	[image unlockFocus]; 
	
	myErr = ReleaseIconRef(iconref);
	
	 [image autorelease];	
	 return image;
}
@end
