//
//  SKMainWindowController_Actions.h
//  Skim
//
//  Created by Christiaan Hofman on 2/14/09.
/*
 This software is Copyright (c) 2009-2014
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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
#import "SKMainWindowController.h"


@interface SKMainWindowController (Actions)

- (IBAction)changeColor:(id)sender;
- (IBAction)changeFont:(id)sender;
- (IBAction)changeAttributes:(id)sender;
- (IBAction)alignLeft:(id)sender;
- (IBAction)alignRight:(id)sender;
- (IBAction)alignCenter:(id)sender;
- (IBAction)createNewNote:(id)sender;
- (IBAction)editNote:(id)sender;
- (IBAction)toggleHideNotes:(id)sender;
- (IBAction)takeSnapshot:(id)sender;
- (IBAction)changeDisplaySinglePages:(id)sender;
- (IBAction)changeDisplayContinuous:(id)sender;
- (IBAction)changeDisplayMode:(id)sender;
- (IBAction)toggleDisplayAsBook:(id)sender;
- (IBAction)toggleDisplayPageBreaks:(id)sender;
- (IBAction)changeDisplayBox:(id)sender;
- (IBAction)doGoToNextPage:(id)sender;
- (IBAction)doGoToPreviousPage:(id)sender;
- (IBAction)doGoToFirstPage:(id)sender;
- (IBAction)doGoToLastPage:(id)sender;
- (IBAction)allGoToNextPage:(id)sender;
- (IBAction)allGoToPreviousPage:(id)sender;
- (IBAction)allGoToFirstPage:(id)sender;
- (IBAction)allGoToLastPage:(id)sender;
- (IBAction)doGoToPage:(id)sender;
- (IBAction)doGoBack:(id)sender;
- (IBAction)doGoForward:(id)sender;
- (IBAction)goToMarkedPage:(id)sender;
- (IBAction)markPage:(id)sender;
- (IBAction)doZoomIn:(id)sender;
- (IBAction)doZoomOut:(id)sender;
- (IBAction)doZoomToActualSize:(id)sender;
- (IBAction)doZoomToPhysicalSize:(id)sender;
- (IBAction)doZoomToFit:(id)sender;
- (IBAction)alternateZoomToFit:(id)sender;
- (IBAction)doZoomToSelection:(id)sender;
- (IBAction)doAutoScale:(id)sender;
- (IBAction)toggleAutoScale:(id)sender;
- (IBAction)rotateRight:(id)sender;
- (IBAction)rotateLeft:(id)sender;
- (IBAction)rotateAllRight:(id)sender;
- (IBAction)rotateAllLeft:(id)sender;
- (IBAction)crop:(id)sender;
- (IBAction)cropAll:(id)sender;
- (IBAction)autoCropAll:(id)sender;
- (IBAction)smartAutoCropAll:(id)sender;
- (IBAction)autoSelectContent:(id)sender;
- (IBAction)getInfo:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)paste:(id)sender;
- (IBAction)alternatePaste:(id)sender;
- (IBAction)pasteAsPlainText:(id)sender;
- (IBAction)copy:(id)sender;
- (IBAction)cut:(id)sender;
- (IBAction)deselectAll:(id)sender;
- (IBAction)changeToolMode:(id)sender;
- (IBAction)changeAnnotationMode:(id)sender;
- (IBAction)toggleLeftSidePane:(id)sender;
- (IBAction)toggleRightSidePane:(id)sender;
- (IBAction)changeLeftSidePaneState:(id)sender;
- (IBAction)changeRightSidePaneState:(id)sender;
- (IBAction)changeFindPaneState:(id)sender;
- (IBAction)toggleStatusBar:(id)sender;
- (IBAction)toggleSplitPDF:(id)sender;
- (IBAction)toggleReadingBar:(id)sender;
- (IBAction)searchPDF:(id)sender;
- (IBAction)toggleFullscreen:(id)sender;
- (IBAction)togglePresentation:(id)sender;
- (IBAction)performFit:(id)sender;
- (IBAction)password:(id)sender;
- (IBAction)savePDFSettingToDefaults:(id)sender;
- (IBAction)chooseTransition:(id)sender;
- (IBAction)toggleCaseInsensitiveSearch:(id)sender;
- (IBAction)toggleWholeWordSearch:(id)sender;
- (IBAction)toggleCaseInsensitiveNoteSearch:(id)sender;
- (IBAction)performFindPanelAction:(id)sender;

@end
