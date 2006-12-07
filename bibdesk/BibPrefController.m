/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BibPrefController.h"

NSString *BDSKDefaultBibFilePathKey = @"Default Bib File";
NSString *BDSKStartupBehaviorKey = @"Startup Behavior";
NSString *BDSKAutoCheckForUpdates = @"Check for updates when starting";
NSString *BDSKShouldUseTemplateFile = @"Write template file when saving";
NSString *BDSKSnoopDrawerContentKey = @"Snoop Drawer Content";
NSString *BDSKBibEditorAutocompletionFields = @"Enabled for autocompletion in BibEditor";
NSString *BDSKPreviewPaneFontFamily = @"Font family to use for RTF preview display";
NSString *BDSKFilterFieldHistory = @"Open using filter command history";

NSString *BDSKUseUnicodeBibTeXParser = @"Use Unicode BibTeX Parser"; // deprecated in 0.99
NSString *BDSKUseThreadedFileLoading = @"Load files in background"; // deprecated in 0.99
NSString *BDSKDefaultStringEncoding = @"Default string encoding for opening and saving";
NSString *BDSKShouldTeXifyWhenSavingAndCopying = @"TeXify characters when saving or copying BibTeX";
NSString *BDSKTeXPreviewFileEncoding = @"Character encoding for TeX preview file";

NSString *BDSKTeXBinPathKey = @"TeX Binary Path";
NSString *BDSKBibTeXBinPathKey = @"BibTeX Binary Path";
NSString *BDSKBTStyleKey = @"BibTeX Style";
NSString *BDSKUsesTeXKey = @"Uses TeX";

NSString *BDSKDragCopyKey = @"Drag and Copy";
NSString *BDSKEditOnPasteKey = @"Edit on Paste";
NSString *BDSKSeparateCiteKey = @"Separate Cite";
NSString *BDSKCiteStringKey = @"Cite String";
NSString *BDSKCiteStartBracketKey = @"Citation Start Bracket";
NSString *BDSKCiteEndBracketKey = @"Citation End Bracket";

NSString *BDSKCiteKeyFormatKey = @"Cite Key Format";
NSString *BDSKCiteKeyFormatPresetKey = @"Cite Key Format Preset";
NSString *BDSKCiteKeyAutogenerateKey = @"Cite Key Autogenerate";
NSString *BDSKCiteKeyLowercaseKey = @"Cite Key Generate Lowercase";

NSString *BDSKShowColsKey = @"Shown Columns";
NSString *BDSKShownColsNamesKey = @"Shown Column Names";
NSString *BDSKColumnWidthsKey = @"Column Widths by Name";
NSString *BDSKColumnOrderKey = @"Column Names in Order";

NSString *BDSKShowStatusBarKey = @"Show Status Bar";
NSString *BDSKShowEditorStatusBarKey = @"Show Editor Status Bar";

NSString *BDSKTableViewFontKey = @"TableView Font";
NSString *BDSKTableViewFontSizeKey = @"TableView Font Size";
NSString *BDSKPreviewDisplayKey = @"Preview Pane Displays What?";
NSString *BDSKPreviewMaxNumberKey = @"Maximum Number of Items in Preview Pane";

NSString *BDSKPreviewPDFScaleFactorKey = @"Preview PDF Scale Factor";
NSString *BDSKPreviewRTFScaleFactorKey = @"Preview RTF Scale Factor";

NSString *BDSKDefaultFieldsKey = @"Default Fields";
NSString *BDSKOutputTemplateFileKey = @"Output Template File";

NSString *BDSKCustomCiteStringsKey = @"Custom CiteStrings";
NSString *BDSKAutoSaveAsRSSKey = @"Auto-save as RSS";
NSString *BDSKRSSDescriptionFieldKey = @"Field to use as Description in RSS";

NSString *BDSKPubTypeKey = @"Current Publication Type";
NSString *BDSKPubTypeStringKey = @"Current Publication Type String";

NSString *BDSKShowWarningsKey = @"Show Warnings in Error Panel";

NSString *BDSKCurrentQuickSearchKey = @"Current Quick Search Key";
NSString *BDSKCurrentQuickSearchTextDict = @"Current Quick Search Text Dictionary";
NSString *BDSKQuickSearchKeys = @"Quick Search Keys";
NSString *BDSKRowColorRedKey = @"RedComponentColor of alternating rows Key";
NSString *BDSKRowColorGreenKey = @"GreenComponentColor of alternating rows Key";
NSString *BDSKRowColorBlueKey = @"BlueComponentColor of alternating rows Key";

NSString *BDSKPapersFolderPathKey = @"Path to the papers folder";
NSString *BDSKFilePapersAutomaticallyKey = @"File papers into the papers folder automatically";
NSString *BDSKKeepPapersFolderOrganizedKey = @"Keep files in the papers folder organized";
NSString *BDSKLocalUrlFormatKey = @"Local-Url Format";
NSString *BDSKLocalUrlFormatPresetKey = @"Local-Url Format Preset";
NSString *BDSKLocalUrlLowercaseKey = @"Local-Url Generate Lowercase";

NSString *BDSKLastVersionLaunched = @"Last launched version number";
NSString *BDSKSnoopDrawerSavedSize = @"Saved size of BibEditor document snoop drawer";
NSString *BDSKShouldSaveNormalizedAuthorNames = @"Save normalized names in BibTeX files";

#pragma mark Field name strings

NSString *BDSKCiteKeyString = @"Cite Key";
NSString *BDSKAnnoteString = @"Annote";
NSString *BDSKAbstractString = @"Abstract";
NSString *BDSKRssDescriptionString = @"Rss-Description";
NSString *BDSKLocalUrlString = @"Local-Url";
NSString *BDSKUrlString = @"Url";
NSString *BDSKAuthorString = @"Author";
NSString *BDSKEditorString = @"Editor";
NSString *BDSKTitleString = @"Title";
NSString *BDSKYearString = @"Year";
NSString *BDSKMonthString = @"Month";
NSString *BDSKKeywordsString = @"Keywords";
NSString *BDSKJournalString = @"Journal";
NSString *BDSKVolumeString = @"Volume";
NSString *BDSKNumberString = @"Number";
NSString *BDSKPagesString = @"Pages";
NSString *BDSKBooktitleString = @"Booktitle";
NSString *BDSKPublisherString = @"Publisher";
NSString *BDSKDateCreatedString = @"Date-Added";
NSString *BDSKDateModifiedString = @"Date-Modified";
NSString *BDSKDateString = @"Date";
NSString *BDSKBibtexString = @"BibTeX";
NSString *BDSKFirstAuthorString = @"1st Author";
NSString *BDSKSecondAuthorString = @"2nd Author";
NSString *BDSKThirdAuthorString = @"3rd Author";
NSString *BDSKItemNumberString = @"Item Number";
NSString *BDSKTypeString = @"Type";


#pragma mark ||  Notification name strings
NSString *BDSKDocumentWillSaveNotification = @"Document Will Save Notification";
NSString *BDSKDocumentWindowWillCloseNotification = @"Document Window Will Close Notification";
NSString *BDSKDocumentUpdateUINotification = @"General UI update Notification";
NSString *BDSKTableViewFontChangedNotification = @"Tableview font selection is changing Notification";
NSString *BDSKPreviewDisplayChangedNotification = @"Preview Pane Preference Change Notification";
NSString *BDSKCustomStringsChangedNotification = @"CustomStringsChangedNotification";
NSString *BDSKPreviewNeedsUpdateNotification = @"Preview Needs Update Notification";
NSString *BDSKTableColumnChangedNotification = @"TableColumnChangedNotification";
NSString *BDSKBibItemChangedNotification = @"BibItem Changed notification";
NSString *BDSKDocAddItemNotification = @"Added a bibitem to a document";
NSString *BDSKDocWillRemoveItemNotification = @"Will remove a bibitem from a document";
NSString *BDSKDocDelItemNotification = @"Removed a bibitem from a document";
NSString *BDSKAuthorPubListChangedNotification = @"added to or deleted a pub from an author";
NSString *BDSKParserErrorNotification = @"A parsing error occurred";
NSString *BDSKBibDocMacroKeyChangedNotification = @"changed the key of a macro";
NSString *BDSKBibDocMacroDefinitionChangedNotification = @"changed the value of a macro";
NSString *BDSKMacroTextFieldWindowWillCloseNotification = @"Macro TextField Window Will Close Notification";
NSString *BDSKPreviewPaneFontChangedNotification = @"Changed the RTF preview pane font family";
NSString *BDSKComplexStringChangedNotification = @"Changed the key or value of a complex string";
NSString *BDSKBibTypeInfoChangedNotification = @"TypeInfo Changed Notification";

#pragma mark BDSKLibrary notifications
NSString *BDSKBibLibrarySelectedItemsChangedNotification = @"BibLibraryController's selected items has changed";
NSString *BDSKBibCollectionItemAddedNotification = @"added an item to a collection";
NSString *BDSKBibCollectionItemRemovedNotification = @"removed an item from a collection";

