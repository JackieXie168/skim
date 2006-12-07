//
//  BDSKItemDisplayController.h
//  Bibdesk
//
//  Created by Michael McCracken on 2/11/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "BibPrefController.h"

/*!
@protocol BDSKItemDisplayController
@abstract   protocol for objects that display an item.
@discussion The items a displaycontroller can display are, for example, bibitem, bibnote, bibauthor...
*/

@protocol BDSKItemDisplayController

/*!
@method     displayName
 @abstract   The name of the controller
 @discussion (description)
 @result     The localized name as an nsstring
 */
- (NSString *)displayName;


/*!
    @method     compatibleTypes
    @abstract   returns types as class name strings that the controller can display
    @discussion (description)
    @result     (description)
*/
- (NSArray *)compatibleTypes;

    /*!
    @method     view
     @abstract   returns an nsview that the controller uses to display.
     @discussion (description)
     @result     (description)
     */
- (NSView *)view;

/*!
    @method     setItemSource:
    @abstract   sets the object the controller will get its items from
    @discussion (description)
    @param      source (description)
*/
- (void)setItemSource:(id)source;

/*!
    @method     itemSource
    @abstract   (description)
    @discussion (description)
    @result     (description)
*/
- (id)itemSource;

@end
