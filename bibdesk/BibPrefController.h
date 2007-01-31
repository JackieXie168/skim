// BibPrefController 
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
#import <OmniFoundation/OFPreference.h>
#import <OmniAppKit/OmniAppKit.h>

#pragma mark Global CPP macros

#define foreach(object, enumerator) \
id mjtForeachEnumerator ## object = (enumerator); \
if ( [mjtForeachEnumerator ## object respondsToSelector:@selector(objectEnumerator)] ) \
mjtForeachEnumerator ## object = [mjtForeachEnumerator ## object objectEnumerator]; \
SEL mjtNextObjectSEL ## object = @selector(nextObject); \
IMP mjtNextObjectIMP ## object = [mjtForeachEnumerator ## object methodForSelector:mjtNextObjectSEL ## object]; \
id object; \
while ( object = mjtNextObjectIMP ## object(mjtForeachEnumerator ## object, mjtNextObjectSEL ## object) )

#pragma mark ||  User Defaults Key String Declarations

@interface OAPreferenceController (HelpLookup)

// this category can be used to load localized strings for global access, since everything imports this header
extern NSString *BDSKAllFieldsString;

@end


extern NSString *BDSKTeXBinPathKey;
extern NSString *BDSKBibTeXBinPathKey;
extern NSString *BDSKBTStyleKey;
extern NSString *BDSKStringEncodingsKey;
extern NSString *BDSKDefaultStringEncodingKey;
extern NSString *BDSKShouldTeXifyWhenSavingAndCopyingKey;
extern NSString *BDSKTeXPreviewFileEncodingKey;
extern NSString *BDSKDefaultBibFileAliasKey;
extern NSString *BDSKStartupBehaviorKey;
extern NSString *BDSKLastOpenFileNamesKey;
extern NSString *BDSKAutoCheckForUpdatesKey;
extern NSString *BDSKEmailTemplateKey;
extern NSString *BDSKDragCopyTypesKey;
extern NSString *BDSKUsesTeXKey;
extern NSString *BDSKEditOnPasteKey;
extern NSString *BDSKSeparateCiteKey;
extern NSString *BDSKShownColsNamesKey;
extern NSString *BDSKShowStatusBarKey;
extern NSString *BDSKShowEditorStatusBarKey;
extern NSString *BDSKShowFindStatusBarKey;
extern NSString *BDSKDefaultFieldsKey;
extern NSString *BDSKLocalFileFieldsKey;
extern NSString *BDSKRemoteURLFieldsKey;
extern NSString *BDSKRatingFieldsKey;
extern NSString *BDSKBooleanFieldsKey;
extern NSString *BDSKTriStateFieldsKey;
extern NSString *BDSKCitationFieldsKey;
extern NSString *BDSKPersonFieldsKey;
extern NSString *BDSKOutputTemplateFileKey;
extern NSString *BDSKMainTableViewFontNameKey;
extern NSString *BDSKMainTableViewFontSizeKey;
extern NSString *BDSKGroupTableViewFontNameKey;
extern NSString *BDSKGroupTableViewFontSizeKey;
extern NSString *BDSKPersonTableViewFontNameKey;
extern NSString *BDSKPersonTableViewFontSizeKey;
extern NSString *BDSKEditorFontNameKey;
extern NSString *BDSKEditorFontSizeKey;
extern NSString *BDSKFileContentSearchTableViewFontNameKey;
extern NSString *BDSKFileContentSearchTableViewFontSizeKey;
extern NSString *BDSKOrphanedFilesTableViewFontNameKey;
extern NSString *BDSKOrphanedFilesTableViewFontSizeKey;
extern NSString *BDSKPreviewDisplayKey;
extern NSString *BDSKPreviewMaxNumberKey;
extern NSString *BDSKPreviewTemplateStyleKey;
extern NSString *BDSKPreviewPDFScaleFactorKey;
extern NSString *BDSKPreviewRTFScaleFactorKey;
extern NSString *BDSKCustomCiteStringsKey;
extern NSString *BDSKCitePrependTildeKey;
extern NSString *BDSKCiteStringKey;
extern NSString *BDSKCiteStartBracketKey;
extern NSString *BDSKCiteEndBracketKey;
extern NSString *BDSKShouldUseTemplateFile;
extern NSString *BDSKShowingPreviewKey;
extern NSString *BDSKSnoopDrawerContentKey;
extern NSString *BDSKPreviewPaneFontFamilyKey;
extern NSString *BDSKFilterFieldHistoryKey;
extern NSString *BDSKEditorShouldCheckSpellingContinuouslyKey;
extern NSString *BDSKIgnoredSortTermsKey;
extern NSString *BDSKEditorFormShouldAutoCompleteKey;
extern NSString *BDSKReadExtendedAttributesKey;
extern NSString *BDSKShouldUsePDFMetadata;
extern NSString *BDSKShouldWritePDFMetadata;
extern NSString *BDSKIntersectGroupsKey;

extern NSString *BDSKCiteKeyFormatKey;
extern NSString *BDSKCiteKeyFormatPresetKey;
extern NSString *BDSKCiteKeyAutogenerateKey;
extern NSString *BDSKCiteKeyLowercaseKey;
extern NSString *BDSKCiteKeyCleanOptionKey;

extern NSString *BDSKDuplicateBooktitleKey;
extern NSString *BDSKForceDuplicateBooktitleKey;
extern NSString *BDSKTypesForDuplicateBooktitleKey;
extern NSString *BDSKWarnOnEditInheritedKey;
extern NSString *BDSKAutoSortForCrossrefsKey;

extern NSString *BDSKExportTemplateStyleKey;

extern NSString *BDSKColumnWidthsKey;
extern NSString *BDSKDefaultSortedTableColumnKey;
extern NSString *BDSKDefaultSortedTableColumnIsDescendingKey;
extern NSString *BDSKSortGroupsKey;
extern NSString *BDSKSortGroupsDescendingKey;

extern NSString *BDSKPubTypeStringKey;
extern NSString *BDSKShowWarningsKey;
extern NSString *BDSKWarnOnDeleteKey;
extern NSString *BDSKWarnOnRenameGroupKey;
extern NSString *BDSKWarnOnRemovalFromGroupKey;

extern NSString *BDSKCurrentQuickSearchKey;
extern NSString *BDSKQuickSearchKeys;

extern NSString *BDSKPapersFolderPathKey;
extern NSString *BDSKFilePapersAutomaticallyKey;
extern NSString *BDSKAutoFileUsesRelativePathKey;
extern NSString *BDSKLocalUrlFormatKey;
extern NSString *BDSKLocalUrlFormatPresetKey;
extern NSString *BDSKLocalUrlLowercaseKey;
extern NSString *BDSKLocalUrlCleanOptionKey;
extern NSString *BDSKWarnOnMoveFolderKey;

extern NSString *BDSKLastVersionLaunchedKey;
extern NSString *BDSKSnoopDrawerSavedSizeKey;
extern NSString *BDSKShouldSaveNormalizedAuthorNamesKey;
extern NSString *BDSKSaveAnnoteAndAbstractAtEndOfItemKey;
extern NSString *BDSKBibStyleMacroDefinitionsKey;
extern NSString *BDSKGlobalMacroDefinitionsKey;
extern NSString *BDSKGlobalMacroFilesKey;

extern NSString *BDSKFindControllerLastFindAndReplaceFieldKey;
extern NSString *BDSKPreviewBaseFontSizeKey;
extern NSString *BDSKShouldAutosaveDocumentKey;
extern NSString *BDSKAutosaveTimeIntervalKey;
extern NSString *BDSKFileContentSearchSortDescriptorKey;
extern NSString *BDSKScriptHooksKey;
extern NSString *BDSKGroupFieldsKey;
extern NSString *BDSKCurrentGroupFieldKey;
extern NSString *BDSKDefaultGroupFieldSeparatorKey;
extern NSString *BDSKGroupFieldSeparatorCharactersKey;
extern NSString *BDSKTableHeaderImagesKey;
extern NSString *BDSKTableHeaderTitlesKey;
extern NSString *BDSKCiteseerHostKey;
extern NSString *BDSKShouldShareFilesKey;
extern NSString *BDSKShouldLookForSharedFilesKey;
extern NSString *BDSKSharingRequiresPasswordKey;
extern NSString *BDSKSharingNameKey;
extern NSString *BDSKWarnOnCiteKeyChangeKey;

extern NSString *BDSKAuthorNameDisplayKey;

extern NSString *BDSKUpdateCheckIntervalKey;
extern NSString *BDSKUpdateCheckLastDateKey;
extern NSString *BDSKUpdateLatestNotifiedVersionKey;
extern NSString *BDSKSpotlightVersionInfo;

extern NSString *BDSKShouldShowWebGroupPrefKey;


#pragma mark Field name strings

extern NSString *BDSKCiteKeyString;
extern NSString *BDSKAnnoteString;
extern NSString *BDSKAbstractString;
extern NSString *BDSKRssDescriptionString;
extern NSString *BDSKLocalUrlString;
extern NSString *BDSKUrlString;
extern NSString *BDSKAuthorString;
extern NSString *BDSKEditorString;
extern NSString *BDSKTitleString;
extern NSString *BDSKChapterString;
extern NSString *BDSKContainerString;
extern NSString *BDSKYearString;
extern NSString *BDSKMonthString;
extern NSString *BDSKKeywordsString;
extern NSString *BDSKJournalString;
extern NSString *BDSKVolumeString;
extern NSString *BDSKNumberString;
extern NSString *BDSKSeriesString;
extern NSString *BDSKPagesString;
extern NSString *BDSKBooktitleString;
extern NSString *BDSKVolumetitleString;
extern NSString *BDSKPublisherString;
extern NSString *BDSKDateAddedString;
extern NSString *BDSKDateModifiedString;
extern NSString *BDSKDateString;
extern NSString *BDSKPubDateString;
extern NSString *BDSKCrossrefString;
extern NSString *BDSKRatingString;
extern NSString *BDSKReadString;
extern NSString *BDSKBibtexString;
extern NSString *BDSKFirstAuthorString;
extern NSString *BDSKSecondAuthorString;
extern NSString *BDSKThirdAuthorString;
extern NSString *BDSKLastAuthorString;
extern NSString *BDSKFirstAuthorEditorString;
extern NSString *BDSKSecondAuthorEditorString;
extern NSString *BDSKThirdAuthorEditorString;
extern NSString *BDSKAuthorEditorString;
extern NSString *BDSKLastAuthorEditorString;
extern NSString *BDSKItemNumberString;
extern NSString *BDSKImportOrderString;
extern NSString *BDSKTypeString;
extern NSString *BDSKAddressString;
extern NSString *BDSKDoiString;
extern NSString *BDSKCiteseerUrlString;
extern NSString *BDSKPubTypeString;
extern NSString *BDSKArticleString;
extern NSString *BDSKBookString;
extern NSString *BDSKInbookString;
extern NSString *BDSKIncollectionString;
extern NSString *BDSKInproceedingsString;
extern NSString *BDSKProceedingsString;
extern NSString *BDSKBookletString;
extern NSString *BDSKManualString;
extern NSString *BDSKTechreportString;
extern NSString *BDSKCommentedString;
extern NSString *BDSKConferenceString;
extern NSString *BDSKMiscString;

#pragma mark ||  Notification name strings
extern NSString *BDSKFinalizeChangesNotification;
extern NSString *BDSKPreviewDisplayChangedNotification;
extern NSString *BDSKTableSelectionChangedNotification;
extern NSString *BDSKGroupTableSelectionChangedNotification;
extern NSString *BDSKGroupFieldChangedNotification;
extern NSString *BDSKGroupFieldAddRemoveNotification;
extern NSString *BDSKBibItemChangedNotification;
extern NSString *BDSKNeedsToBeFiledChangedNotification;
extern NSString *BDSKDocSetPublicationsNotification;
extern NSString *BDSKDocAddItemNotification;
extern NSString *BDSKDocWillRemoveItemNotification;
extern NSString *BDSKDocDelItemNotification;
extern NSString *BDSKAuthorPubListChangedNotification;
extern NSString *BDSKMacroDefinitionChangedNotification;
extern NSString *BDSKMacroTextFieldWindowWillCloseNotification;
extern NSString *BDSKBibTypeInfoChangedNotification;
extern NSString *BDSKCustomFieldsChangedNotification;
extern NSString *BDSKFilterChangedNotification;
extern NSString *BDSKGroupNameChangedNotification;
extern NSString *BDSKStaticGroupChangedNotification;
extern NSString *BDSKSharedGroupsChangedNotification;
extern NSString *BDSKSharedGroupUpdatedNotification;
extern NSString *BDSKURLGroupUpdatedNotification;
extern NSString *BDSKScriptGroupUpdatedNotification;
extern NSString *BDSKSearchGroupUpdatedNotification;
extern NSString *BDSKWebGroupUpdatedNotification;
extern NSString *BDSKDidAddRemoveGroupNotification;
extern NSString *BDSKWillAddRemoveGroupNotification;
extern NSString *BDSKClientConnectionsChangedNotification;
extern NSString *BDSKSharingNameChangedNotification;
extern NSString *BDSKSharingPasswordChangedNotification;
extern NSString *BDSKDocumentControllerAddDocumentNotification;
extern NSString *BDSKDocumentControllerRemoveDocumentNotification;
extern NSString *BDSKDocumentControllerDidChangeMainDocumentNotification;
extern NSString *BDSKSearchIndexInfoChangedNotification;
extern NSString *BDSKEncodingsListChangedNotification;

#pragma mark Exception name strings
extern NSString *BDSKComplexStringException;
extern NSString *BDSKUnimplementedException;

#pragma mark Error name strings
extern const char *BDSKParserError;
extern const char *BDSKNetworkError;

extern NSString *BDSKParserPasteDragString;
