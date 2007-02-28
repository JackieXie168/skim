//
//  CrashReporterController.h
//  ILCrashReporter
//
//  Created by Claus Broch on Sun Jul 11 2004.
//  Copyright 2004 Infinite Loop. All rights reserved.
//

#import <AppKit/NSWindowController.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSButton.h>


@interface CrashReporterController : NSWindowController
{
	IBOutlet NSTextField	*descriptionHeader;
	IBOutlet NSTextView		*descriptionTextView;
	IBOutlet NSTextView		*crashLogTextView;
	IBOutlet NSTextView		*consoleLogTextView;
	IBOutlet NSTextField	*nameField;
	IBOutlet NSTextField	*nameLabelField;
	IBOutlet NSTextField	*emailField;
	IBOutlet NSTextField	*emailLabelField;
	IBOutlet NSImageView	*crashedAppImageView;
	IBOutlet NSTabView		*reportsTabView;
	IBOutlet NSButton		*submitButton;
	
	id		_delegate;
	BOOL	_hasSubmittedReport;
}

- (void)prepareReportForApplication:(NSString*)appName process:(int)processID companyName:(NSString*)companyName;
- (IBAction)submitReport:(id)sender;

- (void)setDelegate:(id)delegate;

@end

@interface NSObject(CrashReporterControllerDelegate)

- (void)userDidSubmitCrashReport:(NSDictionary*)report;
- (void)userDidCancelCrashReport;

@end