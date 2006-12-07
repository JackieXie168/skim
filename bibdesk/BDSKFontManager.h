//
//  BDSKFontManager.h
//  Bibdesk
//
//  Created by Adam Maxwell on 02/25/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BibPrefController.h"


@interface BDSKFontManager : NSObject {
    NSDictionary *cachedFontsForPreviewPane;
}

/*!
    @method     sharedFontManager
    @abstract   Returns the shared instance.
    @discussion (comprehensive description)
    @result     (description)
*/
+ (BDSKFontManager *)sharedFontManager;
- (void)setupFonts; // private method

/*!
    @method     cachedFontsForPreviewPane
    @abstract   Returns a cached font dictionary for the RTF preview (currently used by BibItem).
    @discussion (comprehensive description)
    @result     (description)
*/
- (NSDictionary *)cachedFontsForPreviewPane;

@end
