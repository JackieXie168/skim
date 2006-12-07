//
//  NSImage+Toolbox.h
//  BibDesk
//
//  Created by Sven-S. Porst on Thu Jul 29 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

@interface NSImage (Toolbox)

+ (NSImage *)imageWithLargeIconForToolboxCode:(OSType) code;
+ (NSImage *)cautionIconImage;

@end
