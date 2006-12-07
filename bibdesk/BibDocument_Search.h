//
//  BibDocument_Search.h
//  Bibdesk
//
/*
 This software is Copyright (c) 2001,2002,2003,2004,2005,2006
 Michael O. McCracken. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Michael O. McCracken nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>
#import "BibDocument.h"

@interface BibDocument (Search)

/*!
@method     setupSearchField
 @abstract   Sets up quick search field.
 @discussion This method is called from awakeFromNib. 
 */
- (void)setupSearchField;

/*!
@method     searchFieldMenu
 @abstract   builds the quick search menu template for the NSSearchField
 @discussion this is only used in setupSearchField if not BDSK_USING_JAGUAR. 
 It is for the NSSearchField only, and it's only the template. 
 It shouldn't get called more than once, really.
 @result     An NSMenu for the NSSearchField to use as the template.
 */
- (NSMenu *)searchFieldMenu;

- (NSString*) filterField;

- (void)setFilterField:(NSString*) filterterm;

    /*!
    @method     makeSearchFieldKey:
     @abstract   action to highlight the search field
     */
- (IBAction)makeSearchFieldKey:(id)sender;

    /*!
    @method searchFieldChangeKey
     @abstract Changed what we look for in quicksearch
     @discussion This is called when we change what key to look for. It's the target of the nssearchfield.
     @param sender the sender. 
     
     */

- (IBAction)searchFieldChangeKey:(id)sender;

- (void)setSelectedSearchFieldKey:(NSString *)newKey;


    /*!
    @method quickSearchAddField
     @abstract adds a field to the quicksearchMenu.
     @discussion 
     
     */
- (IBAction)quickSearchAddField:(id)sender;

- (IBAction)quickSearchRemoveField:(id)sender;

- (IBAction)searchFieldAction:(id)sender;

    /*!
    @method     hidePublicationsWithoutSubstring:inField:
     @abstract Hides all pubs without substring in field.
     @discussion This manipulates the shownPublications array.
     */

- (void)hidePublicationsWithoutSubstring:(NSString *)substring inField:(NSString *)field;
    /*!
   @method     publicationsWithSubstring:inField:forArray:
     @abstract   Returns an array of publications matching the search term in the given field and array of BibItems.
     @discussion This method does all of the work in searching through a publications array for BibItems with a given
     substring, in a particular field or all fields.  A Boolean-type search is possible, by using AND and OR
     keywords (all caps), although it appears to be flaky under some conditions.
     @param      substring The string to search for.
     @param      field The BibItem field to search in (e.g. Author).
     @param      arrayToSearch The array of BibItems to search in, typically the documents publications ivar.
     @result     Returns an array of BibItems which matched the given search terms.
     */
- (NSArray *)publicationsWithSubstring:(NSString *)substring inField:(NSString *)field forArray:(NSArray *)arrayToSearch;

#pragma mark Content search

- (IBAction)searchByContent:(id)sender;

- (void)_restoreDocumentStateByRemovingSearchView:(NSView *)view;

#pragma mark Find panel

- (NSString *)selectedStringForFind;
- (IBAction)performFindPanelAction:(id)sender;

@end
