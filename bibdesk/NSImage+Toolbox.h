//
//  NSImage+Toolbox.h
//  Bibdesk
//
//  Created by Sven-S. Porst on Thu Jul 29 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

@interface NSImage (Toolbox)
+ (NSImage*) imageWithLargeIconForToolboxCode:(OSType) code;

@end
