//  BibAppController.h

//  Created by Michael McCracken on Sat Jan 19 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006,2007
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

@class BibDocument;
@protocol BDSKOwner;

/*!
    @class BibAppController
    @abstract The application delegate.
    @discussion This (intended as a singleton) object handles various tasks that require global knowledge, such
 as showing & hiding the finder & preferences window, and the preview. <br>
 This class also performs the complete citation service.
*/


@interface BibAppController : NSObject {
	
    // global auto-completion dictionary:
    NSMutableDictionary *autoCompletionDict;
	
	// auto generation format
	NSArray *requiredFieldsForCiteKey;
	NSArray *requiredFieldsForLocalUrl;
    
	IBOutlet NSMenu *columnsMenu;
	IBOutlet NSMenu *groupSortMenu;
	IBOutlet NSMenu *copyAsTemplateMenu;

    NSLock *metadataCacheLock;
    int32_t canWriteMetadata __attribute__ ((aligned (4)));
    OFMessageQueue *metadataMessageQueue;
    NSConnection *completionConnection;
}

- (void)copyAllExportTemplatesToApplicationSupportAndOverwrite:(BOOL)overwrite;
- (NSString *)temporaryFilePath:(NSString *)fileName createDirectory:(BOOL)create;

- (NSMenu *)groupSortMenu;
	
- (NSArray *)requiredFieldsForCiteKey;
- (void)setRequiredFieldsForCiteKey:(NSArray *)newFields;
- (NSArray *)requiredFieldsForLocalUrl;
- (void)setRequiredFieldsForLocalUrl:(NSArray *)newFields;

- (NSString *)folderPathForFilingPapersFromDocument:(id<BDSKOwner>)owner;

- (void)addNamesForCompletion:(NSArray *)name;
/*!
@method addString:forCompletionEntry:
    @abstract 
    @discussion 
    
*/
- (void)addString:(NSString *)string forCompletionEntry:(NSString *)entry;

/*!
    @method stringsForCompletionEntry
    @abstract returns all strings registered for a particular entry.
    @discussion «discussion»
    
*/
- (NSSet *)stringsForCompletionEntry:(NSString *)entry;

- (NSRange)entry:(NSString *)entry rangeForUserCompletion:(NSRange)charRange ofString:(NSString *)fullString;

/*!
    @method     entry:completions:forPartialWordRange:ofString:indexOfSelectedItem:
    @abstract   Returns an array of possible completions for the substring in charRange of fullString.
    @discussion Used in control:textView:completions:forPartialWordRange:indexOfSelectedItem: delegate methods
    @result     
*/
- (NSArray *)entry:(NSString *)entry completions:(NSArray *)words forPartialWordRange:(NSRange)charRange ofString:(NSString *)fullString indexOfSelectedItem:(int *)index;

- (NSRange)rangeForUserCompletion:(NSRange)charRange forBibTeXString:(NSString *)fullString;
- (NSArray *)possibleMatches:(NSDictionary *)definitions forBibTeXString:(NSString *)fullString partialWordRange:(NSRange)charRange indexOfBestMatch:(int *)index;

- (IBAction)visitWebSite:(id)sender;
- (IBAction)checkForUpdates:(id)sender;

- (IBAction)showPreferencePanel:(id)sender;
- (IBAction)toggleShowingErrorPanel:(id)sender;
- (IBAction)toggleShowingPreviewPanel:(id)sender;

- (IBAction)showReadMeFile:(id)sender;
- (IBAction)showRelNotes:(id)sender;
- (BOOL)isInputManagerInstalledAndCurrent:(BOOL *)current;
- (void)showInputManagerUpdateAlert;

- (IBAction)toggleShowingOrphanedFilesPanel:(id)sender;

// ----------------------------------------------------------------------------------------
// A first attempt at a service.
// This allows you to type a substring of a title and hit a key to
//    have it complete into the appropriate citekey(s), with a comment containing the full title(s)
// Alternately, you can write key = text , and have it search for text in key.
// ----------------------------------------------------------------------------------------

// helper method
- (NSDictionary *)constraintsFromString:(NSString *)string;

/*!
@method completeCitationFromSelection:userData:error
 @abstract The service method
 @discussion  Performs the service. <br>
 Called when user selects Complete Citation.  <br>
 You the programmer should never have to call this explicitly (There is a better way)
    @param pboard The pasteboard that we read from & write to for the service.
*/
- (void)completeCitationFromSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;

- (void)completeTextBibliographyFromSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;

- (void)completeRichBibliographyFromSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;

- (void)completeCiteKeyFromSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;

- (void)showPubWithKey:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;

- (void)newDocumentFromSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;

- (void)addPublicationsFromSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;

/*!
    @method     itemsMatchingSearchConstraints:
    @abstract   Search across all open documents for items matching the given search constraints.  Returns a set of BibItems.
    @discussion Searches are performed by intersecting the search constraints, so all object/key pairs will be matched in any single item returned.
    @param      constraints Dictionary of the form @"objectToSearchFor" forKey:@"BibTeXFieldName".
    @result     NSSet of BibItems.
*/
- (NSSet *)itemsMatchingSearchConstraints:(NSDictionary *)constraints;
/*!
    @method     itemsMatchingCiteKey:
    @abstract   Search across all open documents for items with the given cite key.  Returns a set of BibItems.
    @discussion (comprehensive description)
    @param      citeKeyString (description)
    @result     (description)
*/
- (NSSet *)itemsMatchingCiteKey:(NSString *)citeKeyString;

/*!
    @method     rebuildMetadataCache:
    @abstract   Rebuilds the metadata cache for a userInfo object which must be key-value coding compliant for the keys fileName and publications (BibDocument).
    @discussion (comprehensive description)
    @param      document (description)
*/
- (void)rebuildMetadataCache:(id)userInfo;
/*!
    @method     privateRebuildMetadataCache:
    @abstract   Private method; do not use this, but use the public rebuildMetadataCache which queues this method properly.
    @discussion (comprehensive description)
    @param      userInfo (description)
*/
- (void)privateRebuildMetadataCache:(id)userInfo;

/*!
    @method     doSpotlightImportIfNeeded
    @abstract   Reruns the bundled metadata importer when a new app version or OS version is detected.
    @discussion (comprehensive description)
*/
- (void)doSpotlightImportIfNeeded;

@end