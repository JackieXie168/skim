//
//  BDSKRemoteSource.h
//  Bibdesk
//
//  Created by Michael McCracken on 2/11/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BibCollection.h"

/*!
    @class BDSKRemoteSource
    @abstract   A superclass for sources.
    @discussion (description)
*/
@interface BDSKRemoteSource : BibCollection {
	NSMutableDictionary *data;
}

	/*!
	* @method data
	 * @abstract the getter corresponding to setData
	 * @result returns value for data
	 */
- (NSMutableDictionary *)data;
	/*!
	* @method setData
	 * @abstract sets data to the param
	 * @discussion 
	 * @param aData 
	 */
- (void)setData:(NSMutableDictionary *)aData;


    /*!
    @method     settingsView
     @abstract   returns a view that contains controls for setting up the source
     @discussion (description)
     @result     (description)
     */
- (NSView *)settingsView;

- (void)refresh;

@end
