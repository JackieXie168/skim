#import <Foundation/Foundation.h>
#import "SKNExtendedAttributeManager.h"
#import "SKNAgentListener.h"

#define SKIM_NOTES_KEY @"net_sourceforge_skim-app_notes"
#define SKIM_RTF_NOTES_KEY @"net_sourceforge_skim-app_rtf_notes"
#define SKIM_TEXT_NOTES_KEY @"net_sourceforge_skim-app_text_notes"

static char *usageStr = "Usage:\n skimnotes set PDF_FILE [SKIM_FILE|-]\n skimnotes get [-format skim|text|rtf] PDF_FILE [SKIM_FILE|RTF_FILE|TEXT_FILE|-]\n skimnotes remove PDF_FILE\n skimnotes agent [SERVER_NAME]\n skimnotes protocol\n skimnotes help [VERB]\n skimnotes version";
static char *versionStr = "SkimNotes command-line client, version 2.2.1";

static char *setHelpStr = "skimnotes set: write Skim notes to a PDF\nUsage: skimnotes set PDF_FILE [SKIM_FILE|-]\n\nWrites notes to extended attributes of PDF_FILE from SKIM_FILE or standard input.\nUses notes file with same base name as PDF_FILE if SKIM_FILE is not provided.";
static char *getHelpStr = "skimnotes get: read Skim notes from a PDF\nUsage: skimnotes get [-format skim|text|rtf] PDF_FILE [NOTES_FILE|-]\n\nReads Skim, Text, or RTF notes from extended attributes of PDF_FILE and writes to NOTES_FILE or standard output.\nUses notes file with same base name as PDF_FILE if SKIM_FILE is not provided.\nReads Skim notes when no format is provided.";
static char *removeHelpStr = "skimnotes remove: delete Skim notes from a PDF\nUsage: skimnotes remove PDF_FILE\n\nRemoves the Skim notes from the extended attributes of PDF_FILE.";
static char *agentHelpStr = "skimnotes agent: run the Skim Notes agent\nUsage: skimnotes agent [SERVER_NAME]\n\nRuns a Skim Notes agent server with server name SERVER_NAME, to which a Cocoa application can connect using DO.\nWhen SERVER_NAME is not provided, a unique name is generated and returned on standard output.\nThe DO server conforms to the following formal protocol.\n\n@protocol SKNAgentListenerProtocol\n- (bycopy NSData *)SkimNotesAtPath:(in bycopy NSString *)aFile;\n- (bycopy NSData *)RTFNotesAtPath:(in bycopy NSString *)aFile;\n- (bycopy NSData *)textNotesAtPath:(in bycopy NSString *)aFile encoding:(NSStringEncoding)encoding;\n@end";
static char *protocolHelpStr = "skimnotes protocol: write the DO server protocol to standard output\nUsage: skimnotes protocol\n\nWrite the DO server protocol for the agent to standard output.";
static char *helpHelpStr = "skimnotes help: get help on the skimnotes tool\nUsage: skimnotes help [VERB]\n\nGet help on the verb VERB.";
static char *versionHelpStr = "skimnotes version: get version of the skimnotes tool\nUsage: skimnotes version\n\nGet the version of the tool and exit.";

static char *protocolStr = "@protocol SKNAgentListenerProtocol\n- (bycopy NSData *)SkimNotesAtPath:(in bycopy NSString *)aFile;\n- (bycopy NSData *)RTFNotesAtPath:(in bycopy NSString *)aFile;\n- (bycopy NSData *)textNotesAtPath:(in bycopy NSString *)aFile encoding:(NSStringEncoding)encoding;\n@end";

enum {
    SKNActionUnknown,
    SKNActionGet,
    SKNActionSet,
    SKNActionRemove,
    SKNActionAgent,
    SKNActionProtocol,
    SKNActionVersion,
    SKNActionHelp
};

enum {
    SKNFormatAuto,
    SKNFormatSkim,
    SKNFormatText,
    SKNFormatRTF
};

static NSInteger SKNActionForName(NSString *actionString) {
    if ([actionString caseInsensitiveCompare:@"get"] == NSOrderedSame)
        return SKNActionGet;
    else if ([actionString caseInsensitiveCompare:@"set"] == NSOrderedSame)
        return SKNActionSet;
    else if ([actionString caseInsensitiveCompare:@"remove"] == NSOrderedSame)
        return SKNActionRemove;
    else if ([actionString caseInsensitiveCompare:@"agent"] == NSOrderedSame)
        return SKNActionAgent;
    else if ([actionString caseInsensitiveCompare:@"protocol"] == NSOrderedSame)
        return SKNActionProtocol;
    else if ([actionString caseInsensitiveCompare:@"version"] == NSOrderedSame)
        return SKNActionVersion;
    else if ([actionString caseInsensitiveCompare:@"help"] == NSOrderedSame)
        return SKNActionHelp;
    else
        return SKNActionUnknown;
}

static inline NSString *SKNNormalizedPath(NSString *path) {
    if ([path isEqualToString:@"-"] == NO) {
        if ([path isAbsolutePath] == NO) {
            NSString *basePath = [[NSFileManager defaultManager] currentDirectoryPath];
            if (basePath)
                path = [basePath stringByAppendingPathComponent:path];
        }
        path = [path stringByStandardizingPath];
    }
    return path;
}

int main (int argc, const char * argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
 
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    
    if (argc < 2) {
        fprintf (stderr, "%s\n%s\n", usageStr, versionStr);
        [pool release];
        exit (1);
    }
    
    NSInteger action = SKNActionForName([args objectAtIndex:1]);
    
    BOOL success = NO;
    
    if (action == SKNActionAgent) {
        
        NSString *serverName = [args count] > 2 ? [args lastObject] : nil;
        SKNAgentListener *listener = [[SKNAgentListener alloc] initWithServerName:serverName];

        NSRunLoop *rl = [NSRunLoop currentRunLoop];
        BOOL didRun;
        NSDate *distantFuture = [NSDate distantFuture];
        
        do {
            [pool release];
            pool = [NSAutoreleasePool new];
            didRun = [rl runMode:NSDefaultRunLoopMode beforeDate:distantFuture];
        } while (listener && didRun);
        
        [listener release];
        
        success = YES;
        
    } else if (action == SKNActionProtocol) {
        
        fprintf (stdout, "%s\n", protocolStr);
        
    } else if (action == SKNActionHelp) {
        
        NSInteger helpAction = SKNActionForName([args count] > 2 ? [args objectAtIndex:2] : @"");
        
        switch (helpAction) {
            case SKNActionUnknown:
                fprintf (stdout, "%s\n%s\n", usageStr, versionStr);
                break;
            case SKNActionGet:
                fprintf (stdout, "%s\n", getHelpStr);
                break;
            case SKNActionSet:
                fprintf (stdout, "%s\n", setHelpStr);
                break;
            case SKNActionRemove:
                fprintf (stdout, "%s\n", removeHelpStr);
                break;
            case SKNActionAgent:
                fprintf (stdout, "%s\n", agentHelpStr);
                break;
            case SKNActionProtocol:
                fprintf (stdout, "%s\n", protocolHelpStr);
                break;
            case SKNActionVersion:
                fprintf (stdout, "%s\n", versionHelpStr);
                break;
            case SKNActionHelp:
                fprintf (stdout, "%s\n", helpHelpStr);
                break;
        }
        success = YES;
        
    } else if (action == SKNActionVersion) {
        
        fprintf (stdout, "%s\n", versionStr);
        
    } else {
        
        if (argc < 3) {
            fprintf (stderr, "%s\n%s\n", usageStr, versionStr);
            [pool release];
            exit (1);
        }
        
        NSString *formatString = nil;
        NSInteger format = SKNFormatAuto;
        int offset = 2;
        
        if ([[args objectAtIndex:2] isEqualToString:@"-format"]) {
            if (argc < 5) {
                fprintf (stderr, "%s\n%s\n", usageStr, versionStr);
                [pool release];
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
        NSString *pdfPath = SKNNormalizedPath([args objectAtIndex:offset]);
        NSString *notesPath = argc < offset + 2 ? nil : SKNNormalizedPath([args objectAtIndex:offset + 1]);
        BOOL isDir = NO;
        NSError *error = nil;
        
        if (action != SKNActionRemove && notesPath == nil) {
            notesPath = [[pdfPath stringByDeletingPathExtension] stringByAppendingPathExtension:format == SKNFormatText ? @"txt" : format == SKNFormatRTF ? @"rtf" : @"skim"];
        }
        
        if ([[pdfPath pathExtension] caseInsensitiveCompare:@"pdf"] == NSOrderedSame && 
            ([fm fileExistsAtPath:pdfPath isDirectory:&isDir] == NO || isDir))
            pdfPath = [pdfPath stringByAppendingPathExtension:@"pdf"];
        
        if ([fm fileExistsAtPath:pdfPath isDirectory:&isDir] == NO || isDir) {
            error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"PDF file does not exist", NSLocalizedDescriptionKey, nil]];
        } else if (action == SKNActionGet) {
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
            SKNExtendedAttributeManager *eam = [SKNExtendedAttributeManager sharedManager];
            if (format == SKNFormatSkim) {
                data = [eam extendedAttributeNamed:SKIM_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error];
                if (data == nil && [error code] == ENOATTR)
                    data = [NSData data];
            } else if (format == SKNFormatText) {
                NSString *string = [eam propertyListFromExtendedAttributeNamed:SKIM_TEXT_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error];
                data = [string dataUsingEncoding:NSUTF8StringEncoding];
                if (string == nil && [error code] == ENOATTR)
                    data = [NSData data];
            } else if (format == SKNFormatRTF) {
                data = [eam extendedAttributeNamed:SKIM_RTF_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error];
                if (data == nil && [error code] == ENOATTR)
                    data = [NSData data];
            }
            if (data) {
                if ([notesPath isEqualToString:@"-"]) {
                    if ([data length])
                        [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:data];
                    success = YES;
                } else {
                    if ([data length]) {
                        success = [data writeToFile:notesPath options:NSAtomicWrite error:&error];
                    } else if ([fm fileExistsAtPath:notesPath isDirectory:&isDir] && isDir == NO) {
                        success = [fm removeFileAtPath:notesPath handler:nil];
                        if (success = NO)
                            error = [NSError errorWithDomain:NSPOSIXErrorDomain code:EACCES userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unable to remove file", NSLocalizedDescriptionKey, nil]];
                    } else {
                        success = YES;
                    }
                }
            }
        } else if (action == SKNActionSet && notesPath && ([notesPath isEqualToString:@"-"] || ([fm fileExistsAtPath:notesPath isDirectory:&isDir] && isDir == NO))) {
            NSData *data = nil;
            if ([notesPath isEqualToString:@"-"])
                data = [[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
            else
                data = [NSData dataWithContentsOfFile:notesPath];
            if (data) {
                SKNExtendedAttributeManager *eam = [SKNExtendedAttributeManager sharedManager];
                success = [eam removeExtendedAttribute:SKIM_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error] || [error code] == ENOATTR;
                if (success && [data length])
                    success = [eam setExtendedAttributeNamed:SKIM_NOTES_KEY toValue:data atPath:pdfPath options:0 error:&error];
            }
        } else if (action == SKNActionRemove) {
            SKNExtendedAttributeManager *eam = [SKNExtendedAttributeManager sharedManager];
            BOOL success1 = [eam removeExtendedAttribute:SKIM_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error];
            if (success1 == NO && [error code] == ENOATTR)
                success1 = YES;
            BOOL success2 = [eam removeExtendedAttribute:SKIM_RTF_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error];
            if (success2 == NO && [error code] == ENOATTR)
                success2 = YES;
            BOOL success3 = [eam removeExtendedAttribute:SKIM_TEXT_NOTES_KEY atPath:pdfPath traverseLink:YES error:&error];
            if (success3 == NO && [error code] == ENOATTR)
                success3 = YES;
            success = success1 && success2 && success3;
        }
        
        if (success == NO && error)
            [(NSFileHandle *)[NSFileHandle fileHandleWithStandardError] writeData:[[error localizedDescription] dataUsingEncoding:NSUTF8StringEncoding]];
        
    }
    
    [pool release];
    
    return success ? 0 : 1;
}
