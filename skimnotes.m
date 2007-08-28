#import <Foundation/Foundation.h>
#import "NSFileManager_ExtendedAttributes.h"

#define SKIM_NOTES_KEY @"net_sourceforge_skim-app_notes"
#define SKIM_RTF_NOTES_KEY @"net_sourceforge_skim-app_rtf_notes"
#define SKIM_TEXT_NOTES_KEY @"net_sourceforge_skim-app_text_notes"

static char *usageStr = "Usage:\n skimnotes set PDF_FILE [SKIM_FILE|-]\n skimnotes get [-format skim|text|rtf] PDF_FILE [SKIM_FILE|RTF_FILE|TEXT_FILE|-]\n skimnotes remove PDF_FILE\n skimnotes help";
static char *versionStr = "SkimNotes command-line client, version 0.3.";

enum {
    SKNActionGet,
    SKNActionSet,
    SKNActionRemove
};

enum {
    SKNFormatAuto,
    SKNFormatSkim,
    SKNFormatText,
    SKNFormatRTF
};

static inline NSString *SKNNormalizedPath(NSString *path, NSString *basePath) {
    if ([path isEqualToString:@"-"] == NO) {
        unichar ch = [path length] ? [path characterAtIndex:0] : 0;
        if (basePath && ch != '/' && ch != '~')
            path = [basePath stringByAppendingPathComponent:path];
        path = [path stringByStandardizingPath];
    }
    return path;
}

static inline void SKNWriteUsageAndVersion() {
    fprintf (stderr, "%s\n%s\n", usageStr, versionStr);
}

int main (int argc, const char * argv[]) {
	int action = 0;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
 
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    
    if (argc < 3) {
        if (argc == 2 && ([[args objectAtIndex:1] isEqualToString:@"-h"] || [[args objectAtIndex:1] isEqualToString:@"-help"] || [[args objectAtIndex:1] isEqualToString:@"help"])) {
            SKNWriteUsageAndVersion();
            exit (0);
        } else {
            SKNWriteUsageAndVersion();
            exit (1);
        }
    } 
    
    NSString *actionString = [args objectAtIndex:1];
    if ([actionString isEqualToString:@"get"]) {
        action = SKNActionGet;
    } else if ([actionString isEqualToString:@"set"]) {
        action = SKNActionSet;
    } else if ([actionString isEqualToString:@"remove"]) {
        action = SKNActionRemove;
    } else {
        SKNWriteUsageAndVersion();
        exit (1);
    }
    
    NSString *formatString = nil;
    int format = SKNFormatAuto;
    int offset = 2;
    
    if ([[args objectAtIndex:2] isEqualToString:@"-format"]) {
        if (argc < 5) {
            SKNWriteUsageAndVersion();
            exit (1);
        }
        offset = 4;
        formatString = [args objectAtIndex:3];
        if ([formatString caseInsensitiveCompare:@"skim"] == NSOrderedSame)
            format = SKNFormatSkim;
        if ([formatString caseInsensitiveCompare:@"text"] == NSOrderedSame || [formatString caseInsensitiveCompare:@"txt"] == NSOrderedSame)
            format = SKNFormatText;
        if ([formatString caseInsensitiveCompare:@"rtf"] == NSOrderedSame)
            format = SKNFormatRTF;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL success = NO;
    NSString *currentDir = [fm currentDirectoryPath];
    NSString *pdfPath = SKNNormalizedPath([args objectAtIndex:offset], currentDir);
    NSString *notesPath = argc < offset + 2 ? nil : SKNNormalizedPath([args objectAtIndex:offset + 1], currentDir);
    BOOL isDir = NO;
    
    if (action != SKNActionRemove && notesPath == nil) {
        notesPath = [[pdfPath stringByDeletingPathExtension] stringByAppendingPathExtension:format == SKNFormatText ? @"txt" : format == SKNFormatRTF ? @"rtf" : @"skim"];
    }
    
    if ([[pdfPath pathExtension] caseInsensitiveCompare:@"pdf"] == NSOrderedSame && 
        ([fm fileExistsAtPath:pdfPath isDirectory:&isDir] == NO || isDir))
        pdfPath = [pdfPath stringByAppendingPathExtension:@"pdf"];
    
    if ([fm fileExistsAtPath:pdfPath isDirectory:&isDir] == NO || isDir) {
    } else if (action == SKNActionGet) {
        NSError *error = nil;
        NSData *data = nil;
        if (format == SKNFormatAuto) {
            NSString *extension = [notesPath pathExtension];
            if ([extension caseInsensitiveCompare:@"rtf"] == NSOrderedSame)
                format = SKNFormatRTF;
            else if ([[notesPath pathExtension] caseInsensitiveCompare:@"txt"] == NSOrderedSame || [[notesPath pathExtension] caseInsensitiveCompare:@"text"] == NSOrderedSame)
                format = SKNFormatText;
            else
                format = SKNFormatSkim;
        }
        if (format == SKNFormatSkim) {
            NSError *error = nil;
            data = [fm extendedAttributeNamed:SKIM_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error];
            if (data == nil && [error code] == ENOATTR)
                data = [NSKeyedArchiver archivedDataWithRootObject:[NSArray array]];
        } else if (format == SKNFormatText) {
            NSError *error = nil;
            NSString *string = [fm propertyListFromExtendedAttributeNamed:SKIM_TEXT_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error];
            data = [string dataUsingEncoding:NSUTF8StringEncoding];
            if (string == nil && [error code] == ENOATTR)
                data = [NSData data];
        } else if (format == SKNFormatRTF) {
            data = [fm extendedAttributeNamed:SKIM_RTF_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error];
            if (data == nil && [error code] == ENOATTR)
                data = [NSData data];
        }
        if (data) {
            if ([notesPath isEqualToString:@"-"]) {
                [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:data];
                success = YES;
            } else {
                success = [data writeToFile:notesPath atomically:YES];
            }
        }
    } else if (action == SKNActionSet && notesPath && ([notesPath isEqualToString:@"-"] || ([fm fileExistsAtPath:notesPath isDirectory:&isDir] && isDir == NO))) {
        NSData *data = nil;
        NSError *error = nil;
        if ([notesPath isEqualToString:@"-"])
            data = [[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
        else
            data = [NSData dataWithContentsOfFile:notesPath];
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
