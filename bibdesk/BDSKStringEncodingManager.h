//
//  BDSKStringEncodingManager.h
//  Bibdesk
//
//  Created by Adam Maxwell on 03/01/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BDSKStringEncodingManager : NSObject {
    NSDictionary *encodingsDict;
}

/*!
    @method     sharedEncodingManager
    @abstract   Returns the shared instance of the encoding manager.
    @discussion The encoding manager maintains a list of all supported string encodings in a displayable format suitable for populating
                a popup button, and is able to match the displayable names with NSStringEncodings.
    @result     (description)
*/
+ (BDSKStringEncodingManager *)sharedEncodingManager;

/*!
    @method     availableEncodings
    @abstract   Returns a dictionary of all available encodings, stored as NSNumber objects.  Keys are the display names for each encoding.
    @discussion Don't use this directly; use one of the wrapper methods. 
    @result     (description)
*/
- (NSDictionary *)availableEncodings;

/*!
    @method     availableEncodingDisplayedNames
    @abstract   Returns a sorted array of encodings as human-readable names, based on Apple's documentation.
    @discussion Useful for populating popup buttons with string encodings.  Some of the names are less readable than others.
    @result     (description)
*/
- (NSArray *)availableEncodingDisplayedNames;


/*!
    @method     encodingNumberForDisplayedName:
    @abstract   Returns the string encoding as an NSNumber object, based on the displayed name.
    @discussion Convenience for storing in preferences or archiving.
    @param      Displayed name.
    @result     (description)
*/
- (NSNumber *)encodingNumberForDisplayedName:(NSString *)name;

/*!
    @method     stringEncodingForDisplayedName:
    @abstract   Returns the actual NSStringEncoding for a given displayed name.
    @discussion (comprehensive description)
    @param      The displayed name, as defined in the internal dictionary (accessed from <tt>availableEncodingDisplayedNames</tt>).
    @result     (description)
*/
- (NSStringEncoding)stringEncodingForDisplayedName:(NSString *)name;

/*!
    @method     displayedNameForStringEncoding:
    @abstract   Given an NSStringEncoding, returns the displayed name for it.
    @discussion (comprehensive description)
    @param      encoding (description)
    @result     (description)
*/
- (NSString *)displayedNameForStringEncoding:(NSStringEncoding)encoding;

@end
