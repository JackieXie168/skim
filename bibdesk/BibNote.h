//
//  BibNote.h
//  Bibdesk
//

#import <Cocoa/Cocoa.h>


@interface BibNote : NSObject {
	NSString *title;
	NSAttributedString *string;
	NSArray *keywords;
	NSURL *url;
}

- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

/*!
* @method title
 * @abstract the getter corresponding to setTitle
 * @result returns value for title
 */
- (NSString *)title;
	/*!
	* @method setTitle
	 * @abstract sets title to the param
	 * @discussion 
	 * @param aTitle 
	 */
- (void)setTitle:(NSString *)aTitle;


	/*!
	* @method string
	 * @abstract the getter corresponding to setString
	 * @result returns value for string
	 */
- (NSAttributedString *)string;
	/*!
	* @method setString
	 * @abstract sets string to the param
	 * @discussion 
	 * @param aString 
	 */
- (void)setString:(NSAttributedString *)aString;


	/*!
	* @method keywords
	 * @abstract the getter corresponding to setKeywords
	 * @result returns value for keywords
	 */
- (NSArray *)keywords;
	/*!
	* @method setKeywords
	 * @abstract sets keywords to the param
	 * @discussion 
	 * @param aKeywords 
	 */
- (void)setKeywords:(NSArray *)aKeywords;


	/*!
	* @method url
	 * @abstract the getter corresponding to setUrl
	 * @result returns value for url
	 */
- (NSURL *)url;
	/*!
	* @method setUrl
	 * @abstract sets url to the param
	 * @discussion 
	 * @param anUrl 
	 */
- (void)setUrl:(NSURL *)anUrl;



@end
