//
//  BDSKLibrary.h

#import <Cocoa/Cocoa.h>
#import "BDSKLibraryController.h"
#import "BibPrefController.h"
#import "BibCollection.h"
#import "BibItem.h"
#import "BibAuthor.h"
#import "BibNote.h"
#import "BDSKRemoteSource.h"

@interface BDSKLibrary : NSDocument {
    BibCollection *publications;    // holds all the publications
	BibCollection *authors;  
    BibCollection *notes;       // free-form note storage
    BibCollection *sources;     // external sources of publications, not represented in library (aka the publications collection)
	
}


/*!
    @method     addPublicationToLibrary:
    @abstract   adds a single pub to the top-level library
    @discussion (description)
    @param      pub (description)
*/
- (void)addPublicationToLibrary:(BibItem *)pub;

/*!
* @method publications
 * @abstract the getter corresponding to setPublications
 * @result returns value for publications
 */
- (BibCollection *)publications;
	/*!
	* @method setPublications
	 * @abstract sets publications to the param
	 * @discussion 
	 * @param aPublications 
	 */
- (void)setPublications:(BibCollection *)aPublications;


	/*!
	* @method authors
	 * @abstract the getter corresponding to setAuthors
	 * @result returns value for authors
	 */
- (BibCollection *)authors;
	/*!
	* @method setAuthors
	 * @abstract sets authors to the param
	 * @discussion 
	 * @param anAuthors 
	 */
- (void)setAuthors:(BibCollection *)anAuthors;


	/*!
	* @method notes
	 * @abstract the getter corresponding to setNotes
	 * @result returns value for notes
	 */
- (BibCollection *)notes;
	/*!
	* @method setNotes
	 * @abstract sets notes to the param
	 * @discussion 
	 * @param aNotes 
	 */
- (void)setNotes:(BibCollection *)aNotes;


	/*!
	* @method sources
	 * @abstract the getter corresponding to setSources
	 * @result returns value for sources
	 */
- (BibCollection *)sources;
	/*!
	* @method setSources
	 * @abstract sets sources to the param
	 * @discussion 
	 * @param aSources 
	 */
- (void)setSources:(BibCollection *)aSources;




@end
