//
//  skimnotes.m
//  SkimNotes
//
//  Created by Christiaan Hofman on 18/06/08.
/*
 This software is Copyright (c) 2008-2017
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

#import <Foundation/Foundation.h>
#import "NSFileManager_SKNToolExtensions.h"
#import "SKNAgentListener.h"
#import "SKNUtilities.h"

static char *usageStr = "Usage:\n"
                        " skimnotes get [-format skim|text|rtf] PDF_FILE [NOTES_FILE|-]\n"
                        " skimnotes set PDF_FILE [SKIM_FILE|-] [TEXT_FILE] [RTF_FILE]\n"
                        " skimnotes remove PDF_FILE\n"
                        " skimnotes test PDF_FILE\n"
                        " skimnotes convert IN_PDF_FILE [OUT_PDF_FILE]\n"
                        " skimnotes offset DX DY IN_SKIM_FILE|- [OUT_SKIM_FILE|-]\n"
                        " skimnotes agent [SERVER_NAME]\n"
                        " skimnotes protocol\n"
                        " skimnotes help [VERB]\n"
                        " skimnotes version";
static char *versionStr = "SkimNotes command-line client, version 2.7";

static char *getHelpStr = "skimnotes get: read Skim notes from a PDF\n"
                          "Usage: skimnotes get [-format skim|text|rtf] PDF_FILE [NOTES_FILE|-]\n\n"
                          "Reads Skim, Text, or RTF notes from extended attributes of PDF_FILE or the contents of PDF bundle PDF_FILE and writes to NOTES_FILE or standard output.\n"
                          "Uses notes file with same base name as PDF_FILE if SKIM_FILE is not provided.\n"
                          "Reads Skim notes when no format is provided.";
static char *setHelpStr = "skimnotes set: write Skim notes to a PDF\n"
                          "Usage: skimnotes set PDF_FILE [SKIM_FILE|-] [TEXT_FILE] [RTF_FILE]\n\n"
                          "Writes notes to extended attributes of PDF_FILE or the contents of PDF bundle PDF_FILE from SKIM_FILE or standard input.\n"
                          "Uses notes file with same base name as PDF_FILE if SKIM_FILE is not provided. Writes a default form for the text formats based on the contents of SKIM_FILE if TEXT_FILE and/or RTF_FILE are not provided.";
static char *removeHelpStr = "skimnotes remove: delete Skim notes from a PDF\n"
                             "Usage: skimnotes remove PDF_FILE\n\n"
                             "Removes the Skim notes from the extended attributes of PDF_FILE or from the contents of PDF bundle PDF_FILE.";
static char *testHelpStr = "skimnotes test: Tests whether a PDF file has Skim notes\n"
                           "Usage: skimnotes test PDF_FILE\n\n"
                           "Returns a zero (true) exit status when the extended attributes of PDF_FILE or the contents of PDF bundle PDF_FILE contain Skim notes, otherwise return 1 (false).";
static char *convertHelpStr = "skimnotes convert: convert between a PDF file and a PDF bundle\n"
                              "Usage: skimnotes convert IN_PDF_FILE [OUT_PDF_FILE]\n\n"
                              "Converts a PDF file IN_PDF_FILE to a PDF bundle OUT_PDF_FILE or a PDF bundle IN_PDF_FILE to a PDF file OUT_PDF_FILE.\n"
                              "Uses a file with same base name as IN_PDF_FILE if OUT_PDF_FILE is not provided.";
static char *offsetHelpStr = "skimnotes offsets: offsets all notes in a SKIM file by a fixed amount\n"
                             "Usage: skimnotes offset DX DY IN_SKIM_FILE|- [OUT_SKIM_FILE|-]\n\n"
                             "Offsets all notes in IN_SKIM_FILE or standard input by an amount (DX, DY) and writes the result to OUT_SKIM_FILE or standard output.\n"
                             "Writes back to IN_SKIM_FILE (or standard output) if OUT_SKIM_FILE is not provided.";
static char *agentHelpStr = "skimnotes agent: run the Skim Notes agent\n"
                            "Usage: skimnotes agent [SERVER_NAME]\n\n"
                            "Runs a Skim Notes agent server with server name SERVER_NAME, to which a Cocoa application can connect using DO.\n"
                            "When SERVER_NAME is not provided, a unique name is generated and returned on standard output.\n"
                            "The DO server conforms to the following formal protocol.\n\n"
                            "@protocol SKNAgentListenerProtocol\n"
                            "- (bycopy NSData *)SkimNotesAtPath:(in bycopy NSString *)aFile;\n"
                            "- (bycopy NSData *)RTFNotesAtPath:(in bycopy NSString *)aFile;\n"
                            "- (bycopy NSData *)textNotesAtPath:(in bycopy NSString *)aFile encoding:(NSStringEncoding)encoding;\n"
                            "@end";
static char *protocolHelpStr = "skimnotes protocol: write the DO server protocol to standard output\n"
                               "Usage: skimnotes protocol\n\n"
                               "Write the DO server protocol for the agent to standard output.";
static char *helpHelpStr = "skimnotes help: get help on the skimnotes tool\n"
                           "Usage: skimnotes help [VERB]\n\n"
                           "Get help on the verb VERB.";
static char *versionHelpStr = "skimnotes version: get version of the skimnotes tool\n"
                              "Usage: skimnotes version\n\n"
                              "Get the version of the tool and exit.";

static char *protocolStr = "@protocol SKNAgentListenerProtocol\n"
                           "- (bycopy NSData *)SkimNotesAtPath:(in bycopy NSString *)aFile;\n"
                           "- (bycopy NSData *)RTFNotesAtPath:(in bycopy NSString *)aFile;\n"
                           "- (bycopy NSData *)textNotesAtPath:(in bycopy NSString *)aFile encoding:(NSStringEncoding)encoding;\n"
                           "@end";

#define ACTION_GET_STRING       @"get"
#define ACTION_SET_STRING       @"set"
#define ACTION_REMOVE_STRING    @"remove"
#define ACTION_TEST_STRING      @"test"
#define ACTION_CONVERT_STRING   @"convert"
#define ACTION_OFFSET_STRING    @"offset"
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
    SKNActionTest,
    SKNActionConvert,
    SKNActionOffset,
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
    else if ([actionString caseInsensitiveCompare:ACTION_OFFSET_STRING] == NSOrderedSame)
        return SKNActionOffset;
    else if ([actionString caseInsensitiveCompare:ACTION_TEST_STRING] == NSOrderedSame)
        return SKNActionTest;
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
            case SKNActionTest:
                WRITE_OUT(testHelpStr);
                break;
            case SKNActionConvert:
                WRITE_OUT(convertHelpStr);
                break;
            case SKNActionOffset:
                WRITE_OUT(offsetHelpStr);
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
        CGFloat dx = 0.0, dy = 0.0;
        int offset = 2;
        
        if (action == SKNActionGet && [[args objectAtIndex:2] isEqualToString:FORMAT_OPTION_STRING]) {
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
        } else if (action == SKNActionOffset) {
            if (argc < 5) {
                WRITE_ERROR;
                [pool release];
                exit(EXIT_FAILURE);
            }
            offset = 4;
            dx = [[args objectAtIndex:2] doubleValue];
            dy = [[args objectAtIndex:3] doubleValue];
        }
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *inPath = SKNNormalizedPath([args objectAtIndex:offset]);
        NSString *outPath = argc < offset + 2 ? nil : SKNNormalizedPath([args objectAtIndex:offset + 1]);
        BOOL isBundle = NO;
        BOOL isDir = NO;
        BOOL isStdIn = NO;
        NSError *error = nil;
        
        if (action == SKNActionOffset) {
            if ([inPath isEqualToString:STD_IN_OUT_FILE])
                isStdIn = YES;
            else if ([[inPath pathExtension] caseInsensitiveCompare:SKIM_EXTENSION] != NSOrderedSame)
                inPath = [[inPath stringByDeletingPathExtension] stringByAppendingPathExtension:SKIM_EXTENSION];
        } else if ([[inPath pathExtension] caseInsensitiveCompare:PDFD_EXTENSION] == NSOrderedSame) {
            isBundle = YES;
        } else if ([[inPath pathExtension] caseInsensitiveCompare:PDF_EXTENSION] != NSOrderedSame) {
            inPath = [[inPath stringByDeletingPathExtension] stringByAppendingPathExtension:PDF_EXTENSION];
        }
        
        if (action != SKNActionRemove && outPath == nil) {
            outPath = [inPath stringByDeletingPathExtension];
            if (action == SKNActionConvert)
                outPath = [outPath stringByAppendingPathExtension:isBundle ? PDF_EXTENSION : PDFD_EXTENSION];
            else if (action == SKNActionOffset)
                outPath = inPath;
            else
                outPath = [outPath stringByAppendingPathExtension:format == SKNFormatText ? TXT_EXTENSION : format == SKNFormatRTF ? RTF_EXTENSION : SKIM_EXTENSION];
        }
        
        if ((action != SKNActionOffset || isStdIn == NO) && ([fm fileExistsAtPath:inPath isDirectory:&isDir] == NO || isBundle != isDir)) {
            
            error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:action == SKNActionOffset ? @"Skim file does not exist" : isBundle ? @"PDF bundle does not exist" : @"PDF file does not exist", NSLocalizedDescriptionKey, nil]];
            
        } else if (action == SKNActionGet) {
            
            NSData *data = nil;
            if (format == SKNFormatAuto) {
                NSString *extension = [outPath pathExtension];
                if ([extension caseInsensitiveCompare:RTF_EXTENSION] == NSOrderedSame)
                    format = SKNFormatRTF;
                else if ([extension caseInsensitiveCompare:TXT_EXTENSION] == NSOrderedSame || [extension caseInsensitiveCompare:TEXT_EXTENSION] == NSOrderedSame)
                    format = SKNFormatText;
                else
                    format = SKNFormatSkim;
            }
            if (format == SKNFormatSkim)
                data = [fm SkimNotesAtPath:inPath error:&error];
            else if (format == SKNFormatText)
                data = [[fm SkimTextNotesAtPath:inPath error:&error] dataUsingEncoding:NSUTF8StringEncoding];
            else if (format == SKNFormatRTF)
                data = [fm SkimRTFNotesAtPath:inPath error:&error];
            if (data) {
                if ([outPath isEqualToString:STD_IN_OUT_FILE]) {
                    if ([data length])
                        [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:data];
                    success = YES;
                } else {
                    if ([data length]) {
                        success = [data writeToFile:outPath options:NSAtomicWrite error:&error];
                    } else if ([fm fileExistsAtPath:outPath isDirectory:&isDir] && isDir == NO) {
                        success = [fm removeItemAtPath:outPath error:NULL];
                        if (success == NO)
                            error = [NSError errorWithDomain:NSPOSIXErrorDomain code:EACCES userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unable to remove file", NSLocalizedDescriptionKey, nil]];
                    } else {
                        success = YES;
                    }
                }
            }
            
        } else if (action == SKNActionSet) {
            
            if (outPath && ([outPath isEqualToString:STD_IN_OUT_FILE] || ([fm fileExistsAtPath:outPath isDirectory:&isDir] && isDir == NO))) {
                NSData *data = nil;
                NSString *textString = nil;
                NSData *rtfData = nil;
                if ([outPath isEqualToString:STD_IN_OUT_FILE])
                    data = [[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
                else
                    data = [NSData dataWithContentsOfFile:outPath];
                if (argc > offset + 2) {
                    NSString *outPath2 = SKNNormalizedPath([args objectAtIndex:offset + 2]);
                    NSString *outPath3 = argc < offset + 4 ? nil : SKNNormalizedPath([args objectAtIndex:offset + 3]);
                    if ([[outPath2 pathExtension] caseInsensitiveCompare:TXT_EXTENSION] == NSOrderedSame || [[outPath2 pathExtension] caseInsensitiveCompare:TEXT_EXTENSION] == NSOrderedSame)
                        textString = [NSString stringWithContentsOfFile:outPath2 encoding:NSUTF8StringEncoding error:NULL];
                    else if ([[outPath3 pathExtension] caseInsensitiveCompare:TXT_EXTENSION] == NSOrderedSame || [[outPath3 pathExtension] caseInsensitiveCompare:TEXT_EXTENSION] == NSOrderedSame)
                        textString = [NSString stringWithContentsOfFile:outPath3 encoding:NSUTF8StringEncoding error:NULL];
                    if ([[outPath3 pathExtension] caseInsensitiveCompare:RTF_EXTENSION] == NSOrderedSame)
                        rtfData = [NSData dataWithContentsOfFile:outPath3];
                    else if ([[outPath2 pathExtension] caseInsensitiveCompare:RTF_EXTENSION] == NSOrderedSame)
                        rtfData = [NSData dataWithContentsOfFile:outPath2];
                }
                if ([data length])
                    success = [fm writeSkimNotes:data textNotes:textString RTFNotes:rtfData atPath:inPath error:&error];
                else if (data)
                    success = [fm removeSkimNotesAtPath:inPath error:&error];
            } else {
                error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Notes file does not exist", NSLocalizedDescriptionKey, nil]];
            }
            
        } else if (action == SKNActionRemove) {
            
            success = [fm removeSkimNotesAtPath:inPath error:&error];
            
        } else if (action == SKNActionTest) {
            
            success = [fm hasSkimNotesAtPath:inPath];
            
        } else if (action == SKNActionConvert) {
            
            if (isBundle) {
                NSString *pdfFilePath = nil;
                NSArray *files = [fm subpathsAtPath:inPath];
                NSString *filename = [[[inPath lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:PDF_EXTENSION];
                if ([files containsObject:filename] == NO) {
                    NSUInteger idx = [[files valueForKeyPath:@"pathExtension.lowercaseString"] indexOfObject:PDF_EXTENSION];
                    filename = idx == NSNotFound ? nil : [files objectAtIndex:idx];
                }
                if (filename)
                    pdfFilePath = [inPath stringByAppendingPathComponent:filename];
                success = [fm copyItemAtPath:pdfFilePath toPath:outPath error:NULL];
            } else {
                success = [fm createDirectoryAtPath:outPath withIntermediateDirectories:NO attributes:nil error:NULL];
                if (success) {
                    NSString *pdfFilePath = [outPath stringByAppendingPathComponent:[[[outPath lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:PDF_EXTENSION]];
                    success = [[NSData dataWithContentsOfFile:inPath options:0 error:&error] writeToFile:pdfFilePath options:0 error:&error];
                }
            }
            if (success) {
                NSData *notesData = [fm SkimNotesAtPath:inPath error:&error];
                NSString *textNotes = [fm SkimTextNotesAtPath:inPath error:&error];
                NSData *rtfNotesData = [fm SkimRTFNotesAtPath:inPath error:&error];
                if (notesData)
                    success = [fm writeSkimNotes:notesData textNotes:textNotes RTFNotes:rtfNotesData atPath:outPath error:&error];
            }
            
        } else if (action == SKNActionOffset) {
            
            NSData *data;
            if (isStdIn)
                data = [(NSFileHandle *)[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
            else
                data = [NSData dataWithContentsOfFile:inPath];
            if (data) {
                NSArray *inNotes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                if ([inNotes isKindOfClass:[NSArray class]]) {
                    NSMutableArray *outNotes = [NSMutableArray array];
                    for (NSDictionary *inNote in inNotes) {
                        if ([inNote isKindOfClass:[NSDictionary class]]) {
                            NSMutableDictionary *outNote = [inNote mutableCopy];
                            NSString *boundsString = [inNote objectForKey:@"bounds"];
                            if ([boundsString isKindOfClass:[NSString class]]) {
                                NSRect bounds = NSRectFromString(boundsString);
                                bounds = NSOffsetRect(bounds, dx, dy);
                                [outNote setObject:NSStringFromRect(bounds) forKey:@"bounds"];
                            }
                            [outNotes addObject:outNote];
                        } else {
                            [outNotes addObject:inNote];
                        }
                    }
                    data = [NSKeyedArchiver archivedDataWithRootObject:outNotes];
                    if (data) {
                        if ([outPath isEqualToString:STD_IN_OUT_FILE]) {
                            [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:data];
                            success = YES;
                        } else {
                            success = [data writeToFile:outPath options:NSAtomicWrite error:&error];
                        }
                    }
                }
            }
            
        }
        
        if (success == NO && error)
            [(NSFileHandle *)[NSFileHandle fileHandleWithStandardError] writeData:[[[error localizedDescription] stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        
    }
    
    [pool release];
    
    return success ? EXIT_SUCCESS : EXIT_FAILURE;
}
