// BibPrefController 
/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <Cocoa/Cocoa.h>
#import <OmniFoundation/OFPreference.h>
#import <OmniAppKit/OmniAppKit.h>

#pragma mark ||  User Defaults Key String Declarations

/*! @const BDSKTeXBinPathKey
@discussion Key for the user default:  the path to tex.
<br> I don't think these are respected yet. why not?
*/
extern NSString *BDSKTeXBinPathKey;

/*! @const BDSKBibTeXBinPathKey 
@discussion Key for the user default: the path to bibtex
*/
extern NSString *BDSKBibTeXBinPathKey;

/*! @const BDSKBTStyleKey Key for user default: The style file name to be inserted into the tex template for preview. */
extern NSString *BDSKBTStyleKey;
extern NSString *BDSKDefaultBibFilePathKey;
extern NSString *BDSKStartupBehaviorKey;
extern NSString *BDSKDragCopyKey;
extern NSString *BDSKUsesTeXKey;
extern NSString *BDSKEditOnPasteKey;
extern NSString *BDSKSeparateCiteKey;
extern NSString *BDSKShowColsKey;
extern NSString *BDSKShownColsNamesKey;
extern NSString *BDSKDefaultFieldsKey;
extern NSString *BDSKOutputTemplateFileKey;
extern NSString *BDSKTableViewFontKey;
extern NSString *BDSKTableViewFontSizeKey;
extern NSString *BDSKPreviewDisplayKey;
extern NSString *BDSKCustomCiteStringsKey;
extern NSString *BDSKCiteStringKey;
extern NSString *BDSKCiteStartBracketKey;
extern NSString *BDSKCiteEndBracketKey;

extern NSString *BDSKAutoSaveAsRSSKey;
extern NSString *BDSKRSSDescriptionFieldKey;

extern NSString *BDSKColumnWidthsKey;
extern NSString *BDSKColumnOrderKey;

extern NSString *BDSKViewByKey;

extern NSString *BDSKPubTypeKey;
extern NSString *BDSKPubTypeStringKey;
extern NSString *BDSKShowWarningsKey;

extern NSString *BDSKCurrentQuickSearchKey;
extern NSString *BDSKCurrentQuickSearchTextDict;
extern NSString *BDSKQuickSearchKeys;

extern NSString *BDSKRowColorRedKey;
extern NSString *BDSKRowColorGreenKey;
extern NSString *BDSKRowColorBlueKey;

#pragma mark ||  Notification name strings
extern NSString *BDSKDocumentUpdateUINotification;
extern NSString *BDSKTableViewFontChangedNotification;
extern NSString *BDSKPreviewDisplayChangedNotification;
extern NSString *BDSKCustomStringsChangedNotification;
extern NSString *BDSKTableColumnChangedNotification;
