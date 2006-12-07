//
//  BibAppController.h
//  Bibdesk
//
//  Created by Michael McCracken on Sat Jan 19 2002.
//  Copyright (c) 2001 Michael McCracken. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "BibPrefController.h";
#import "BibFinder.h";
#import "BDSKFormCellFormatter.h";

/*!
    @class BibAppController
    @abstract The application delegate.
    @discussion This (intended as a singleton) object handles various tasks that require global knowledge, such
 as showing & hiding the finder & preferences window, and the preview. <br>
 This class also performs the complete citation service.
*/
@interface BibAppController : NSObject {
    BOOL showingPreviewPanel;
    BibPrefController *prefController;
    BibFinder *_finder;

    // error-handling stuff:
    IBOutlet NSPanel* errorPanel;
    IBOutlet NSTableView *errorTableView;
    NSMutableArray *_errors;
    IBOutlet NSTextView *sourceEditTextView;
    IBOutlet NSWindow *sourceEditWindow;
    NSString *currentFileName;
    
    // global auto-completion dictionary:
    NSMutableDictionary *_autoCompletionDict;
    NSMutableDictionary *_formatters;
}

/*!
@method addString:forCompletionEntry:
    @abstract 
    @discussion 
    
*/
- (void)addString:(NSString *)string forCompletionEntry:(NSString *)entry;

/*!
    @method formatterForEntry
    @abstract returns the singleton formatter for a particular entry
    @discussion «discussion»
    
*/
- (NSFormatter *)formatterForEntry:(NSString *)entry;

/*!
    @method stringsForCompletionEntry
    @abstract returns all strings registered for a particular entry.
    @discussion «discussion»
    
*/
- (NSArray *)stringsForCompletionEntry:(NSString *)entry;

- (IBAction)toggleShowingErrorPanel:(id)sender;
- (IBAction)hideErrorPanel:(id)sender;
- (IBAction)showErrorPanel:(id)sender;
- (void)removeErrorsFromFileName:(NSString *)fileName;
- (IBAction)gotoError:(id)sender;
- (IBAction)gotoErrorObj:(id)errObj;
- (IBAction)openEditWindowWithFile:(NSString *)fileName;

- (IBAction)reopenDocument:(id)sender;

- (IBAction)visitWebSite:(id)sender;
- (IBAction)checkForUpdates:(id)sender;

- (IBAction)showPreferencePanel:(id)sender;
- (IBAction)showFindPanel:(id)sender;
- (IBAction)showPreviewPanel:(id)sender;
- (IBAction)toggleShowingPreviewPanel:(id)sender;


// ----------------------------------------------------------------------------------------
// A first attempt at a service.
// This allows you to type a substring of a title and hit a key to
//    have it complete into the appropriate citekey(s), with a comment containing the full title(s)
// Alternately, you can write key = text , and have it search for text in key.
// ----------------------------------------------------------------------------------------

/*!
@method completeCitationFromSelection:userData:error
 @abstract The service method
 @discussion  Performs the service. <br>
 Called when user selects Complete Citation.  <br>
 You the programmer should never have to call this explicitly (There is a better way)
    @param pboard The pasteboard that we read from & write to for the service.
*/
- (void)completeCitationFromSelection:(NSPasteboard *)pboard
                             userData:(NSString *)userData
                                error:(NSString **)error;

@end
