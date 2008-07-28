#import <Foundation/Foundation.h>
#import "NSFileManager_SKNToolExtensions.h"
#import "SKNAgentListener.h"
#import "SKNUtilities.h"

static char *usageStr = "Usage:\n skimnotes get [-format skim|text|rtf] PDF_FILE [NOTES_FILE|-]\n skimnotes set PDF_FILE [SKIM_FILE|-] [TEXT_FILE] [RTF_FILE]\n skimnotes remove PDF_FILE\n skimnotes convert IN_PDF_FILE [OUT_PDF_FILE]\n skimnotes agent [SERVER_NAME]\n skimnotes protocol\n skimnotes help [VERB]\n skimnotes version";
static char *versionStr = "SkimNotes command-line client, version 2.3.1";

static char *getHelpStr = "skimnotes get: read Skim notes from a PDF\nUsage: skimnotes get [-format skim|text|rtf] PDF_FILE [NOTES_FILE|-]\n\nReads Skim, Text, or RTF notes from extended attributes of PDF_FILE or the contents of PDF bundle PDF_FILE and writes to NOTES_FILE or standard output.\nUses notes file with same base name as PDF_FILE if SKIM_FILE is not provided.\nReads Skim notes when no format is provided.";
static char *setHelpStr = "skimnotes set: write Skim notes to a PDF\nUsage: skimnotes set PDF_FILE [SKIM_FILE|-] [TEXT_FILE] [RTF_FILE]\n\nWrites notes to extended attributes of PDF_FILE or the contents of PDF bundle PDF_FILE from SKIM_FILE or standard input.\nUses notes file with same base name as PDF_FILE if SKIM_FILE is not provided. Writes a default form for the text formats based on the contents of SKIM_FILE if TEXT_FILE and/or RTF_FILE are not provided.";
static char *removeHelpStr = "skimnotes remove: delete Skim notes from a PDF\nUsage: skimnotes remove PDF_FILE\n\nRemoves the Skim notes from the extended attributes of PDF_FILE or from the contents of PDF bundle PDF_FILE.";
static char *convertHelpStr = "skimnotes convert: convert between a PDF file and a PDF bundle\nUsage: skimnotes convert IN_PDF_FILE [OUT_PDF_FILE]\n\nConverts a PDF file IN_PDF_FILE to a PDF bundle OUT_PDF_FILE or a PDF bundle IN_PDF_FILE to a PDF file OUT_PDF_FILE.\nUses a file with same base name as IN_PDF_FILE if OUT_PDF_FILE is not provided.";
static char *agentHelpStr = "skimnotes agent: run the Skim Notes agent\nUsage: skimnotes agent [SERVER_NAME]\n\nRuns a Skim Notes agent server with server name SERVER_NAME, to which a Cocoa application can connect using DO.\nWhen SERVER_NAME is not provided, a unique name is generated and returned on standard output.\nThe DO server conforms to the following formal protocol.\n\n@protocol SKNAgentListenerProtocol\n- (bycopy NSData *)SkimNotesAtPath:(in bycopy NSString *)aFile;\n- (bycopy NSData *)RTFNotesAtPath:(in bycopy NSString *)aFile;\n- (bycopy NSData *)textNotesAtPath:(in bycopy NSString *)aFile encoding:(NSStringEncoding)encoding;\n@end";
static char *protocolHelpStr = "skimnotes protocol: write the DO server protocol to standard output\nUsage: skimnotes protocol\n\nWrite the DO server protocol for the agent to standard output.";
static char *helpHelpStr = "skimnotes help: get help on the skimnotes tool\nUsage: skimnotes help [VERB]\n\nGet help on the verb VERB.";
static char *versionHelpStr = "skimnotes version: get version of the skimnotes tool\nUsage: skimnotes version\n\nGet the version of the tool and exit.";

static char *protocolStr = "@protocol SKNAgentListenerProtocol\n- (bycopy NSData *)SkimNotesAtPath:(in bycopy NSString *)aFile;\n- (bycopy NSData *)RTFNotesAtPath:(in bycopy NSString *)aFile;\n- (bycopy NSData *)textNotesAtPath:(in bycopy NSString *)aFile encoding:(NSStringEncoding)encoding;\n@end";

#define ACTION_GET_STRING       @"get"
#define ACTION_SET_STRING       @"set"
#define ACTION_REMOVE_STRING    @"remove"
#define ACTION_CONVERT_STRING   @"convert"
#define ACTION_AGENT_STRING     @"agent"
#define ACTION_PROTOCOL_STRING  @"protocol"
#define ACTION_VERSION_STRING   @"version"
#define ACTION_HELP_STRING      @"help"

#define FORMAT_OPTION_STRING    @"-format"

#define FORMAT_SKIM_STRING  @"skim"
#define FORMAT_TEXT_STRING  @"text"
#define FORMAT_TXT_STRING   @"txt"
#define FORMAT_RTF_STRING   @"rtf"

#define STD_IN_OUT_FILE @"-"

#define WRITE_OUT(msg)         fprintf(stdout, "%s\n", msg)
#define WRITE_OUT_VERSION(msg) fprintf(stdout, "%s\n%s\n", msg, versionStr)
#define WRITE_ERROR            fprintf(stderr, "%s\n%s\n", usageStr, versionStr)

enum {
    SKNActionUnknown,
    SKNActionGet,
    SKNActionSet,
    SKNActionRemove,
    SKNActionConvert,
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
    if ([actionString caseInsensitiveCompare:ACTION_GET_STRING] == NSOrderedSame)
        return SKNActionGet;
    else if ([actionString caseInsensitiveCompare:ACTION_SET_STRING] == NSOrderedSame)
        return SKNActionSet;
    else if ([actionString caseInsensitiveCompare:ACTION_REMOVE_STRING] == NSOrderedSame)
        return SKNActionRemove;
    else if ([actionString caseInsensitiveCompare:ACTION_CONVERT_STRING] == NSOrderedSame)
        return SKNActionConvert;
    else if ([actionString caseInsensitiveCompare:ACTION_AGENT_STRING] == NSOrderedSame)
        return SKNActionAgent;
    else if ([actionString caseInsensitiveCompare:ACTION_PROTOCOL_STRING] == NSOrderedSame)
        return SKNActionProtocol;
    else if ([actionString caseInsensitiveCompare:ACTION_VERSION_STRING] == NSOrderedSame)
        return SKNActionVersion;
    else if ([actionString caseInsensitiveCompare:ACTION_HELP_STRING] == NSOrderedSame)
        return SKNActionHelp;
    else
        return SKNActionUnknown;
}

static inline NSString *SKNNormalizedPath(NSString *path) {
    if ([path isEqualToString:STD_IN_OUT_FILE] == NO) {
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
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
 
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    
    if (argc < 2) {
        WRITE_ERROR;
        [pool release];
        exit(EXIT_FAILURE);
    }
    
    NSInteger action = SKNActionForName([args objectAtIndex:1]);
    
    BOOL success = NO;
    
    if (action == SKNActionUnknown) {
        
        WRITE_ERROR;
        [pool release];
        exit(EXIT_FAILURE);
        
    } else if (action == SKNActionAgent) {
        
        NSString *serverName = [args count] > 2 ? [args lastObject] : nil;
        SKNAgentListener *listener = [[SKNAgentListener alloc] initWithServerName:serverName];
        
        NSRunLoop *rl = [NSRunLoop currentRunLoop];
        BOOL didRun;
        
        do {
            [pool release];
            pool = [NSAutoreleasePool new];
            didRun = [rl runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (listener && didRun);
        
        [listener release];
        
        success = YES;
        
    } else if (action == SKNActionProtocol) {
        
        WRITE_OUT(protocolStr);
        
    } else if (action == SKNActionHelp) {
        
        NSInteger helpAction = SKNActionForName([args count] > 2 ? [args objectAtIndex:2] : @"");
        
        switch (helpAction) {
            case SKNActionUnknown:
                WRITE_OUT_VERSION(usageStr);
                break;
            case SKNActionGet:
                WRITE_OUT(getHelpStr);
                break;
            case SKNActionSet:
                WRITE_OUT(setHelpStr);
                break;
            case SKNActionRemove:
                WRITE_OUT(removeHelpStr);
                break;
            case SKNActionConvert:
                WRITE_OUT(convertHelpStr);
                break;
            case SKNActionAgent:
                WRITE_OUT(agentHelpStr);
                break;
            case SKNActionProtocol:
                WRITE_OUT(protocolHelpStr);
                break;
            case SKNActionVersion:
                WRITE_OUT(versionHelpStr);
                break;
            case SKNActionHelp:
                WRITE_OUT(helpHelpStr);
                break;
        }
        success = YES;
        
    } else if (action == SKNActionVersion) {
        
        WRITE_OUT(versionStr);
        
    } else {
        
        if (argc < 3) {
            WRITE_ERROR;
            [pool release];
            exit(EXIT_FAILURE);
        }
        
        NSString *formatString = nil;
        NSInteger format = SKNFormatAuto;
        int offset = 2;
        
        if ([[args objectAtIndex:2] isEqualToString:FORMAT_OPTION_STRING]) {
            if (argc < 5) {
                WRITE_ERROR;
                [pool release];
                exit(EXIT_FAILURE);
            }
            offset = 4;
            formatString = [args objectAtIndex:3];
            if ([formatString caseInsensitiveCompare:FORMAT_SKIM_STRING] == NSOrderedSame)
                format = SKNFormatSkim;
            if ([formatString caseInsensitiveCompare:FORMAT_TEXT_STRING] == NSOrderedSame || [formatString caseInsensitiveCompare:FORMAT_TXT_STRING] == NSOrderedSame)
                format = SKNFormatText;
            if ([formatString caseInsensitiveCompare:FORMAT_RTF_STRING] == NSOrderedSame)
                format = SKNFormatRTF;
        }
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *pdfPath = SKNNormalizedPath([args objectAtIndex:offset]);
        NSString *notesPath = argc < offset + 2 ? nil : SKNNormalizedPath([args objectAtIndex:offset + 1]);
        BOOL isBundle = NO;
        BOOL isDir = NO;
        NSError *error = nil;
        
        if ([[pdfPath pathExtension] caseInsensitiveCompare:PDFD_EXTENSION] == NSOrderedSame)
            isBundle = YES;
        else if ([[pdfPath pathExtension] caseInsensitiveCompare:PDF_EXTENSION] != NSOrderedSame)
            pdfPath = [[pdfPath stringByDeletingPathExtension] stringByAppendingPathExtension:PDF_EXTENSION];
        
        if (action != SKNActionRemove && notesPath == nil) {
            notesPath = [pdfPath stringByDeletingPathExtension];
            if (action == SKNActionConvert)
                notesPath = [notesPath stringByAppendingPathExtension:isBundle ? PDF_EXTENSION : PDFD_EXTENSION];
            else
                notesPath = [notesPath stringByAppendingPathExtension:format == SKNFormatText ? TXT_EXTENSION : format == SKNFormatRTF ? RTF_EXTENSION : SKIM_EXTENSION];
        }
        
        if ([fm fileExistsAtPath:pdfPath isDirectory:&isDir] == NO || isBundle != isDir) {
            
            error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:isBundle ? @"PDF bundle does not exist" : @"PDF file does not exist", NSLocalizedDescriptionKey, nil]];
            
        } else if (action == SKNActionGet) {
            
            NSData *data = nil;
            if (format == SKNFormatAuto) {
                NSString *extension = [notesPath pathExtension];
                if ([extension caseInsensitiveCompare:RTF_EXTENSION] == NSOrderedSame)
                    format = SKNFormatRTF;
                else if ([extension caseInsensitiveCompare:TXT_EXTENSION] == NSOrderedSame || [extension caseInsensitiveCompare:TEXT_EXTENSION] == NSOrderedSame)
                    format = SKNFormatText;
                else
                    format = SKNFormatSkim;
            }
            if (format == SKNFormatSkim)
                data = [fm SkimNotesAtPath:pdfPath error:&error];
            else if (format == SKNFormatText)
                data = [[fm SkimTextNotesAtPath:pdfPath error:&error] dataUsingEncoding:NSUTF8StringEncoding];
            else if (format == SKNFormatRTF)
                data = [fm SkimRTFNotesAtPath:pdfPath error:&error];
            if (data) {
                if ([notesPath isEqualToString:STD_IN_OUT_FILE]) {
                    if ([data length])
                        [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:data];
                    success = YES;
                } else {
                    if ([data length]) {
                        success = [data writeToFile:notesPath options:NSAtomicWrite error:&error];
                    } else if ([fm fileExistsAtPath:notesPath isDirectory:&isDir] && isDir == NO) {
                        success = [fm removeFileAtPath:notesPath handler:nil];
                        if (success == NO)
                            error = [NSError errorWithDomain:NSPOSIXErrorDomain code:EACCES userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unable to remove file", NSLocalizedDescriptionKey, nil]];
                    } else {
                        success = YES;
                    }
                }
            }
            
        } else if (action == SKNActionSet) {
            
            if (notesPath && ([notesPath isEqualToString:STD_IN_OUT_FILE] || ([fm fileExistsAtPath:notesPath isDirectory:&isDir] && isDir == NO))) {
                NSData *data = nil;
                NSString *textString = nil;
                NSData *rtfData = nil;
                if ([notesPath isEqualToString:STD_IN_OUT_FILE])
                    data = [[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
                else
                    data = [NSData dataWithContentsOfFile:notesPath];
                if (argc > offset + 2) {
                    NSString *notesPath2 = SKNNormalizedPath([args objectAtIndex:offset + 2]);
                    NSString *notesPath3 = argc < offset + 4 ? nil : SKNNormalizedPath([args objectAtIndex:offset + 3]);
                    if ([[notesPath2 pathExtension] caseInsensitiveCompare:TXT_EXTENSION] == NSOrderedSame || [[notesPath2 pathExtension] caseInsensitiveCompare:TEXT_EXTENSION] == NSOrderedSame)
                        textString = [NSString stringWithContentsOfFile:notesPath2 encoding:NSUTF8StringEncoding error:NULL];
                    else if ([[notesPath3 pathExtension] caseInsensitiveCompare:TXT_EXTENSION] == NSOrderedSame || [[notesPath3 pathExtension] caseInsensitiveCompare:TEXT_EXTENSION] == NSOrderedSame)
                        textString = [NSString stringWithContentsOfFile:notesPath3 encoding:NSUTF8StringEncoding error:NULL];
                    if ([[notesPath3 pathExtension] caseInsensitiveCompare:RTF_EXTENSION] == NSOrderedSame)
                        rtfData = [NSData dataWithContentsOfFile:notesPath3];
                    else if ([[notesPath2 pathExtension] caseInsensitiveCompare:RTF_EXTENSION] == NSOrderedSame)
                        rtfData = [NSData dataWithContentsOfFile:notesPath2];
                }
                if ([data length])
                    success = [fm writeSkimNotes:data textNotes:textString RTFNotes:rtfData atPath:pdfPath error:&error];
                else if (data)
                    success = [fm removeSkimNotesAtPath:pdfPath error:&error];
            } else {
                error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Notes file does not exist", NSLocalizedDescriptionKey, nil]];
            }
            
        } else if (action == SKNActionRemove) {
            
            success = [fm removeSkimNotesAtPath:pdfPath error:&error];
            
        } else if (action == SKNActionConvert) {
            
            if (isBundle) {
                success = [fm createDirectoryAtPath:notesPath attributes:nil];
            } else {
                NSString *pdfFilePath = nil;
                NSArray *files = [fm subpathsAtPath:pdfPath];
                NSString *filename = [[[pdfPath lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:PDF_EXTENSION];
                if ([files containsObject:filename] == NO) {
                    NSUInteger idx = [[files valueForKeyPath:@"pathExtension.lowercaseString"] indexOfObject:PDF_EXTENSION];
                    filename = idx == NSNotFound ? nil : [files objectAtIndex:idx];
                }
                if (filename)
                    pdfFilePath = [pdfPath stringByAppendingPathComponent:filename];
                success = [fm copyPath:pdfFilePath toPath:notesPath handler:nil];
            }
            if (success) {
                NSData *notesData = [fm SkimNotesAtPath:pdfPath error:&error];
                NSString *textNotes = [fm SkimTextNotesAtPath:pdfPath error:&error];
                NSData *rtfNotesData = [fm SkimRTFNotesAtPath:pdfPath error:&error];
                if (notesData)
                    success = [fm writeSkimNotes:notesData textNotes:textNotes RTFNotes:rtfNotesData atPath:notesPath error:&error];
            }
        }
        
        if (success == NO && error)
            [(NSFileHandle *)[NSFileHandle fileHandleWithStandardError] writeData:[[error localizedDescription] dataUsingEncoding:NSUTF8StringEncoding]];
        
    }
    
    [pool release];
    
    return success ? EXIT_SUCCESS : EXIT_FAILURE;
}
