//
//  OATypeAheadSelectionHelper Extensions.h
//  Bibdesk
//
//  Created by Michael McCracken on Sun Jul 07 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OmniFoundation/OFScheduler.h>
#import <OmniAppKit/OATypeAheadSelectionHelper.h>

@interface OATypeAheadSelectionHelper (BDSKExtensions)

- (void)newProcessKeyDownCharacter:(unichar)character;
- (int)_indexOfItemWithSubstring:(NSString *)substring afterIndex:(int)selectedIndex;
@end
