/* Inspired by and somewhat copied from Calendar by
 */


#import <AppKit/AppKit.h>
#import "BDSKComplexString.h"


@interface MacroTextFieldWindowController : NSWindowController {
    IBOutlet NSTextField *textField;
    IBOutlet NSTextField *expandedValueTextField;
    IBOutlet NSTextField *infoLine;
    NSString *originalInfoLineValue;
    NSString *fieldName;
    id macroResolver;
    NSString *startString;
    BOOL notifyingChanges;
}
// Public
- (void)startEditingValue:(NSString *) string
               atLocation:(NSPoint)point
                    width:(float)width
                 withFont:(NSFont*)font
                fieldName:(NSString *)aFieldName
			macroResolver:(id<BDSKMacroResolver>)aMacroResolver;

// Private
- (void)controlTextDidEndEditing:(NSNotification *)aNotification;
- (void)notifyNewValueAndOrderOut;
- (NSString *)startString;
- (void)setStartString:(NSString *)string;
- (NSString *)stringValue;
@end
