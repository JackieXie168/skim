#import <Foundation/Foundation.h>
#import "NSFileManager_ExtendedAttributes.h"

#define SKIM_NOTES_KEY @"net_sourceforge_skim-app_notes"

static char *usageStr = "Usage:\n skimnotes set PDF_FILE [SKIM_FILE]\n skimnotes get PDF_FILE [SKIM_FILE]\n skimnotes remove PDF_FILE";
static char *versionStr = "SkimNotes command-line client, version 0.1.";

enum {
    SKNActionGet,
    SKNActionSet,
    SKNActionRemove
};

static inline NSString *SKNNormalizedPath(NSString *path, NSString *basePath) {
    unichar ch = [path length] ? [path characterAtIndex:0] : 0;
    if (basePath && ch != '/' && ch != '~')
        path = [basePath stringByAppendingPathComponent:path];
    return [path stringByStandardizingPath];
}

int main (int argc, const char * argv[]) {
	int action = 0;
    
    if (argc == 2 && (strcmp("-h", argv[1]) == 0 || strcmp("-help", argv[1]) == 0)) {
        fprintf (stderr, "%s\n%s\n", usageStr, versionStr);
        exit (0);
    } else if (argc > 2 && strcmp("get", argv[1]) == 0) {
        action = SKNActionGet;
    } else if (argc > 2 && strcmp("set", argv[1]) == 0) {
        action = SKNActionSet;
    } else if (argc > 2 && strcmp("remove", argv[1]) == 0) {
        action = SKNActionRemove;
    } else {
        fprintf (stderr, "%s\n%s\n", usageStr, versionStr);
        exit (1);
    }
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
 
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL success = NO;
    NSString *currentDir = [fm currentDirectoryPath];
    NSString *pdfPath = SKNNormalizedPath([[[NSProcessInfo processInfo] arguments] objectAtIndex:2], currentDir);
    NSString *notesPath = argc < 4 ? nil : SKNNormalizedPath([[[NSProcessInfo processInfo] arguments] objectAtIndex:3], currentDir);
    BOOL isDir = NO;
    
    if (action != SKNActionRemove && notesPath == nil) {
        if ([[pdfPath pathExtension] caseInsensitiveCompare:@"pdf"] == NSOrderedSame)
            notesPath = [[pdfPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"skim"];
        else
            notesPath = [pdfPath stringByAppendingPathExtension:@"skim"];
    }
    
    if ([[pdfPath pathExtension] caseInsensitiveCompare:@"pdf"] == NSOrderedSame && 
        ([fm fileExistsAtPath:pdfPath isDirectory:&isDir] == NO || isDir))
        pdfPath = [pdfPath stringByAppendingPathExtension:@"pdf"];
    
    if ([fm fileExistsAtPath:pdfPath isDirectory:&isDir] == NO || isDir) {
    } else if (action == SKNActionGet) {
        NSError *error = nil;
        NSData *data = [fm extendedAttributeNamed:SKIM_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error];
        if (data == nil && [error code] == ENOATTR)
            data = [NSKeyedArchiver archivedDataWithRootObject:[NSArray array]];
        if (data)
            success = [data writeToFile:notesPath atomically:YES];
    } else if (action == SKNActionSet && notesPath && [fm fileExistsAtPath:notesPath isDirectory:&isDir] && isDir == NO) {
        NSData *data = [NSData dataWithContentsOfFile:notesPath];
        NSError *error = nil;
        if (data) {
            success = [fm removeExtendedAttribute:SKIM_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error];
            if (success || [error code] == ENOATTR)
                success = [fm setExtendedAttributeNamed:SKIM_NOTES_KEY toValue:data atPath:pdfPath options:0 error:NULL];
        }
    } else if (action == SKNActionRemove) {
        NSError *error = nil;
        success = [fm removeExtendedAttribute:SKIM_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error];
        if (success == NO && [error code] == ENOATTR)
            success = YES;
    }
    
    [pool release];
    
    return success ? 0 : 1;
}
