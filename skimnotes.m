#import <Foundation/Foundation.h>
#import "NSFileManager_ExtendedAttributes.h"

#define SKIM_NOTES_KEY @"net_sourceforge_skim-app_notes"
#define SKIM_RTF_NOTES_KEY @"net_sourceforge_skim-app_rtf_notes"
#define SKIM_TEXT_NOTES_KEY @"net_sourceforge_skim-app_text_notes"

static char *usageStr = "Usage:\n skimnotes set PDF_FILE [SKIM_FILE]\n skimnotes get PDF_FILE [SKIM_FILE|RTF_FILE|TEXT_FILE]\n skimnotes remove PDF_FILE";
static char *versionStr = "SkimNotes command-line client, version 0.2.";

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
        NSData *data = nil;
        if ([[notesPath pathExtension] caseInsensitiveCompare:@"rtf"] == NSOrderedSame) {
            data = [fm extendedAttributeNamed:SKIM_RTF_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error];
            if (data == nil && [error code] == ENOATTR)
                data = [NSData data];
        } else if ([[notesPath pathExtension] caseInsensitiveCompare:@"txt"] == NSOrderedSame || [[notesPath pathExtension] caseInsensitiveCompare:@"text"] == NSOrderedSame) {
            NSError *error = nil;
            data = [fm extendedAttributeNamed:SKIM_TEXT_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error];
            if (data == nil && [error code] == ENOATTR)
                data = [NSData data];
        } else {
            NSError *error = nil;
            data = [fm extendedAttributeNamed:SKIM_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error];
            if (data == nil && [error code] == ENOATTR)
                data = [NSKeyedArchiver archivedDataWithRootObject:[NSArray array]];
        }
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
        BOOL success1 = [fm removeExtendedAttribute:SKIM_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error];
        if (success1 == NO && [error code] == ENOATTR)
            success1 = YES;
        BOOL success2 = [fm removeExtendedAttribute:SKIM_RTF_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error];
        if (success2 == NO && [error code] == ENOATTR)
            success2 = YES;
        BOOL success3 = [fm removeExtendedAttribute:SKIM_TEXT_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error];
        if (success3 == NO && [error code] == ENOATTR)
            success3 = YES;
        success = success1 && success2 && success3;
    }
    
    [pool release];
    
    return success ? 0 : 1;
}
