/* Inspired by and somewhat copied from Calendar by
 */


#import <AppKit/AppKit.h>
#import "BDSKComplexString.h"

extern NSString *BDSKMacroTextFieldWindowWillCloseNotification;

@interface MacroTextFieldWindowController : NSWindowController {
    IBOutlet NSTextField *textField;
    IBOutlet NSTextField *expandedValueTextField;
    NSString *fieldName;
    BDSKComplexString *currentComplexString;
}
// Public
- (void)startEditingValue:(BDSKComplexString *) string
               atLocation:(NSPoint)point
                    width:(float)width
                 withFont:(NSFont*)font
                fieldName:(NSString *)aFieldName;

// Private
- (void)controlTextDidEndEditing:(NSNotification *)aNotification;
- (void)notifyNewValueAndOrderOut;
- (BDSKComplexString *)complexStringValue;
@end
