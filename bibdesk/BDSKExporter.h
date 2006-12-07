//
//  BDSKExporter.h
//  Bibdesk
//
//  Created by Michael McCracken on 1/11/05.
//

#import <Cocoa/Cocoa.h>
#import "BibPrefController.h"

/*!
@class BDSKExporter
@abstract   superclass for objects that export or publish collections.
@discussion This superclass defines methods that should be implemented in subclasses.
It also handles some bookkeeping that registers available classes of exporters
and defines class methods that let you find a list of available exporters.
*/

@interface BDSKExporter : NSObject {
    NSMutableDictionary *data;
}

- (void)encodeWithCoder:(NSCoder *)coder;

- (id)initWithCoder:(NSCoder *)coder;


/*!
@method data
@abstract the getter corresponding to setData
@result returns value for data
*/
- (NSMutableDictionary *)data;

/*!
@method setData
@abstract sets data to the param
@discussion 
@param newData 
*/
- (void)setData:(NSMutableDictionary *)newData;



/*!
@method     name
 @abstract   The name of the exporter
 @discussion (description)
 @result     The localized name as an nsstring
 */
+ (NSString *)displayName;



    /*!
    @method     settingsView
     @abstract   returns a view that contains controls for setting up the
     @discussion (description)
     @result     (description)
     */
- (NSView *)settingsView;

    /*!
    @method     exportPublicationsInArray:
     @abstract   exports
     @discussion userInfo is stored in the document that contains the 
     pubs and might contain for instance a file name to save the pubs to.
     
     @param      pubs BibItems to export
     @param      userInfo info that the exporter needs to do the export.
     
     @result returns YES if no error occurred.
     */
- (BOOL)exportPublicationsInArray:(NSArray *)pubs;


/*!
    @method     availableExporters
    @abstract   gets what subclasses are available 
    @discussion 
    @result     classnames from nsclassfromstring
*/
+ (NSArray *)availableExporterClassNames;   

/*!
    @method     availableExporterNames
    @abstract   (description)
    @discussion (description)
    @result     descriptive names.
*/
+ (NSArray *)availableExporterNames;

@end
