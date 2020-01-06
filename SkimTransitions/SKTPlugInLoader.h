//
//  SKTPlugInLoader.h
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/05/2019.
//  Copyright © 2019-2020 Skim. All rights reserved.
//

#import <QuartzCore/CoreImage.h>

@interface SKTPlugInLoader : NSObject <CIPlugInRegistration>

- (BOOL)load:(void *)host;

@end
