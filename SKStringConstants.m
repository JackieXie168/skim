//
//  SKStringConstants.m
//  Skim
//
//  Created by Michael McCracken on 1/5/07.
/*
 This software is Copyright (c) 2007-2014
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

#import "SKStringConstants.h"

NSString *SKAutoCheckFileUpdateKey = @"SKAutoCheckFileUpdate";
NSString *SKTeXEditorPresetKey = @"SKTeXEditorPreset";
NSString *SKTeXEditorArgumentsKey = @"SKTeXEditorArguments";
NSString *SKTeXEditorCommandKey = @"SKTeXEditorCommand";
NSString *SKBackgroundColorKey = @"SKBackgroundColor";
NSString *SKFullScreenBackgroundColorKey = @"SKFullScreenBackgroundColor";
NSString *SKPageBackgroundColorKey = @"SKPageBackgroundColor";
NSString *SKLastOpenFileNamesKey = @"SKLastOpenFileNames";
NSString *SKOpenContentsPaneOnlyForTOCKey = @"SKOpenContentsPaneOnlyForTOC";
NSString *SKInitialWindowSizeOptionKey = @"SKInitialWindowSizeOption";
NSString *SKReopenLastOpenFilesKey = @"SKReopenLastOpenFiles";
NSString *SKRememberLastPageViewedKey = @"SKRememberLastPageViewed";
NSString *SKRememberSnapshotsKey = @"SKRememberSnapshots";
NSString *SKAutoSaveSkimNotesKey = @"SKAutoSaveSkimNotes";
NSString *SKSnapshotsOnTopKey = @"SKSnapshotsOnTop";
NSString *SKSnapshotThumbnailSizeKey = @"SKSnapshotThumbnailSize";
NSString *SKThumbnailSizeKey = @"SKThumbnailSize";
NSString *SKLastToolModeKey = @"SKLastToolMode";
NSString *SKLastAnnotationModeKey = @"SKLastAnnotationMode";
NSString *SKShouldAntiAliasKey = @"SKShouldAntiAlias";
NSString *SKImageInterpolationKey = @"SKImageInterpolation";
NSString *SKGreekingThresholdKey = @"SKGreekingThreshold";
NSString *SKReadingBarColorKey = @"SKReadingBarColor";
NSString *SKReadingBarInvertKey = @"SKReadingBarInvert";
NSString *SKFreeTextNoteFontNameKey = @"SKFreeTextNoteFontName";
NSString *SKFreeTextNoteFontSizeKey = @"SKFreeTextNoteFontSize";
NSString *SKAnchoredNoteFontNameKey = @"SKAnchoredNoteFontName";
NSString *SKAnchoredNoteFontSizeKey = @"SKAnchoredNoteFontSize";
NSString *SKFreeTextNoteColorKey = @"SKFreeTextNoteColor";
NSString *SKAnchoredNoteColorKey = @"SKAnchoredNoteColor";
NSString *SKCircleNoteColorKey = @"SKCircleNoteColor";
NSString *SKSquareNoteColorKey = @"SKSquareNoteColor";
NSString *SKHighlightNoteColorKey = @"SKHighlightNoteColor";
NSString *SKUnderlineNoteColorKey = @"SKUnderlineNoteColor";
NSString *SKStrikeOutNoteColorKey = @"SKStrikeOutNoteColor";
NSString *SKLineNoteColorKey = @"SKLineNoteColor";
NSString *SKInkNoteColorKey = @"SKInkNoteColor";
NSString *SKCircleNoteInteriorColorKey = @"SKCircleNoteInteriorColor";
NSString *SKSquareNoteInteriorColorKey = @"SKSquareNoteInteriorColor";
NSString *SKLineNoteInteriorColorKey = @"SKLineNoteInteriorColor";
NSString *SKFreeTextNoteFontColorKey = @"SKFreeTextNoteFontColor";
NSString *SKFreeTextNoteAlignmentKey = @"SKFreeTextNoteAlignment";
NSString *SKFreeTextNoteLineWidthKey = @"SKFreeTextNoteLineWidth";
NSString *SKAnchoredNoteIconTypeKey = @"SKAnchoredNoteIconType";
NSString *SKFreeTextNoteLineStyleKey = @"SKFreeTextNoteLineStyle";
NSString *SKFreeTextNoteDashPatternKey = @"SKFreeTextNoteDashPattern";
NSString *SKCircleNoteLineWidthKey = @"SKCircleNoteLineWidth";
NSString *SKCircleNoteLineStyleKey = @"SKCircleNoteLineStyle";
NSString *SKCircleNoteDashPatternKey = @"SKCircleNoteDashPattern";
NSString *SKSquareNoteLineWidthKey = @"SKSquareNoteLineWidth";
NSString *SKSquareNoteLineStyleKey = @"SKSquareNoteLineStyle";
NSString *SKSquareNoteDashPatternKey = @"SKSquareNoteDashPattern";
NSString *SKLineNoteLineWidthKey = @"SKLineNoteLineWidth";
NSString *SKLineNoteDashPatternKey = @"SKLineNoteDashPattern";
NSString *SKLineNoteLineStyleKey = @"SKLineNoteLineStyle";
NSString *SKLineNoteStartLineStyleKey = @"SKLineNoteStartLineStyle";
NSString *SKLineNoteEndLineStyleKey = @"SKLineNoteEndLineStyle";
NSString *SKInkNoteLineWidthKey = @"SKInkNoteLineWidth";
NSString *SKInkNoteDashPatternKey = @"SKInkNoteDashPattern";
NSString *SKInkNoteLineStyleKey = @"SKInkNoteLineStyle";
NSString *SKDefaultNoteWidthKey = @"SKDefaultNoteWidth";
NSString *SKDefaultNoteHeightKey = @"SKDefaultNoteHeight";
NSString *SKSwatchColorsKey = @"SKSwatchColors";
NSString *SKDefaultPDFDisplaySettingsKey = @"SKDefaultPDFDisplaySettings";
NSString *SKDefaultFullScreenPDFDisplaySettingsKey = @"SKDefaultFullScreenPDFDisplaySettings";
NSString *SKShowStatusBarKey = @"SKShowStatusBar";
NSString *SKShowBookmarkStatusBarKey = @"SKShowBookmarkStatusBar";
NSString *SKShowNotesStatusBarKey = @"SKShowNotesStatusBar";
NSString *SKEnableAppleRemoteKey = @"SKEnableAppleRemote";
NSString *SKAppleRemoteSwitchIndicationTimeoutKey = @"SKAppleRemoteSwitchIndicationTimeout";
NSString *SKReadMissingNotesFromSkimFileOptionKey = @"SKReadMissingNotesFromSkimFileOption";
NSString *SKSavePasswordOptionKey = @"SKSavePasswordOption";
NSString *SKBlankAllScreensInFullScreenKey = @"SKBlankAllScreensInFullScreen";
NSString *SKFullScreenNavigationOptionKey = @"SKFullScreenNavigationOption";
NSString *SKPresentationNavigationOptionKey = @"SKPresentationNavigationOption";
NSString *SKAutoHidePresentationContentsKey = @"SKAutoHidePresentationContents";
NSString *SKUseNormalLevelForPresentationKey = @"SKUseNormalLevelForPresentation";
NSString *SKAutoOpenDownloadsWindowKey = @"SKAutoOpenDownloadsWindow";
NSString *SKAutoRemoveFinishedDownloadsKey = @"SKAutoRemoveFinishedDownloads";
NSString *SKAutoCloseDownloadsWindowKey = @"SKAutoCloseDownloadsWindow";
NSString *SKShouldSetCreatorCodeKey = @"SKShouldSetCreatorCode";
NSString *SKTableFontSizeKey = @"SKTableFontSize";
NSString *SKSequentialPageNumberingKey = @"SKSequentialPageNumbering";
NSString *SKDisablePinchZoomKey = @"SKDisablePinchZoom";
NSString *SKDisableModificationDateKey = @"SKDisableModificationDate";
NSString *SKDisableAnimationsKey = @"SKDisableAnimations";
NSString *SKDisableUpdateContentsFromEnclosedTextKey = @"SKDisableUpdateContentsFromEnclosedText";
NSString *SKCaseInsensitiveSearchKey = @"SKCaseInsensitiveSearch";
NSString *SKWholeWordSearchKey = @"SKWholeWordSearch";
NSString *SKCaseInsensitiveNoteSearchKey = @"SKCaseInsensitiveNoteSearch";
NSString *SKCaseInsensitiveFindKey = @"SKCaseInsensitiveFind";
NSString *SKDownloadsDirectoryKey = @"SKDownloadsDirectory";
NSString *SKDisableSearchAfterSpotlighKey = @"SKDisableSearchAfterSpotligh";
