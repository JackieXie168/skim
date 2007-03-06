#import <Foundation/Foundation.h>
#import "NSFileManager_ExtendedAttributes.h"

#define SKIM_NOTES_KEY @"net_sourceforge_skim_notes"

static char *usageStr = "Usage: skimnotes get|set file.pdf file.skim";
static char *versionStr = "SkimNotes command-line client, version 0.1.";

int main (int argc, const char * argv[]) {
	BOOL get = YES; 
    
    if (argc == 2 &&  (strcmp("-h", argv[1]) == 0 || strcmp("-help", argv[1]) == 0)) {
        fprintf (stderr, "%s\n%s\n", usageStr, versionStr);
        exit (0);
    } else if (argc < 4 ) {
        fprintf (stderr, "%s\n%s\n", usageStr, versionStr);
        exit (1);
    } else if (strcmp("get", argv[1]) == 0) {
        get = YES;
    } else if (strcmp("set", argv[1]) == 0) {
        get = NO;
    } else {
        fprintf (stderr, "%s\n%s\n", usageStr, versionStr);
        exit (1);
    }
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
 
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL success = NO;
    NSString *pdfPath = [[[[NSProcessInfo processInfo] arguments] objectAtIndex:2] stringByStandardizingPath];
    NSString *notesPath = [[[[NSProcessInfo processInfo] arguments] objectAtIndex:3] stringByStandardizingPath];
    BOOL isDir = NO;
    
    if ([fm fileExistsAtPath:pdfPath isDirectory:&isDir] == NO || isDir) {
    } else if (get) {
        NSData *data = [fm extendedAttributeNamed:SKIM_NOTES_KEY atPath:pdfPath traverseLink:YES error:NULL];
        if (data)
            success = [data writeToFile:notesPath atomically:YES];
    } else if (notesPath && [fm fileExistsAtPath:notesPath isDirectory:&isDir] && isDir == NO) {
        NSData *data = [NSData dataWithContentsOfFile:notesPath];
        if (data) {
            success = [fm removeExtendedAttribute:SKIM_NOTES_KEY atPath:pdfPath traverseLink:YES error:NULL] &&
                      [fm setExtendedAttributeNamed:SKIM_NOTES_KEY toValue:data atPath:pdfPath options:0 error:NULL];
        }
    }
    
    [pool release];
    
    return success ? 0 : 1;
}
