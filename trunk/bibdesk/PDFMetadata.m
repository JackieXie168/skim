//
//  PDFMetadata.m
//  Bibdesk
//
//  Created by Adam Maxwell on 02/17/06.
/*
 This software is Copyright (c) 2006,2007
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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

#import "PDFMetadata.h"
#import <Quartz/Quartz.h>
#import "NSURL_BDSKExtensions.h"

static NSDictionary *translator = nil;

// The key names were taken from the Voyeur sample code, since the linker fails using the PDFKit constant names
// rdar://problem/4450214
NSString *BDSKPDFDocumentTitleAttribute = @"Title";				        // NSString containing document title.
NSString *BDSKPDFDocumentAuthorAttribute = @"Author";			        // NSString containing document author.
NSString *BDSKPDFDocumentCreationDateAttribute = @"CreationDate";		// NSDate representing document creation date.
NSString *BDSKPDFDocumentKeywordsAttribute = @"Keywords";			    // NSArray of NSStrings containing document keywords.

/* The purpose of this class is to provide an easy interface to set and get the attributes of a PDF document in bulk, acting an an intermediary between our model objects and the PDFDocument (or whatever we eventually use). */

@implementation PDFMetadata

+ (void)initialize
{
    // provides a dictionary of key paths matched to the PDFDocument keys
    if(translator == nil)
        translator = [[NSDictionary alloc] initWithObjectsAndKeys:@"pubAuthorsForDisplay", BDSKPDFDocumentAuthorAttribute, @"keywordsArray", BDSKPDFDocumentKeywordsAttribute, @"title.stringByRemovingTeX", BDSKPDFDocumentTitleAttribute, @"date", BDSKPDFDocumentCreationDateAttribute, nil];
}

// an "item" is some object that is KVC compliant for the keys in the translator; nominally a BibItem
+ (id)metadataWithBibItem:(id)anItem;
{
    PDFMetadata *metadata = [[[self allocWithZone:[self zone]] init] autorelease];
    id value = nil;
    
    value = [anItem valueForKeyPath:[translator objectForKey:BDSKPDFDocumentTitleAttribute]];
    if(value != nil)
        [metadata setValue:value forKey:BDSKPDFDocumentTitleAttribute];
    
    value = [anItem valueForKeyPath:[translator objectForKey:BDSKPDFDocumentAuthorAttribute]];
    if(value != nil)
        [metadata setValue:value forKey:BDSKPDFDocumentAuthorAttribute];
    
    value = [anItem valueForKeyPath:[translator objectForKey:BDSKPDFDocumentKeywordsAttribute]];
    if(value != nil)
        [metadata setValue:value forKey:BDSKPDFDocumentKeywordsAttribute];
    
    // docs say this is an NSString, but the PDFDocument returns an NSCFDate (header says it's an NSDate) rdar://problem:/4450219
    value = [anItem valueForKeyPath:[translator objectForKey:BDSKPDFDocumentCreationDateAttribute]];
    if(value != nil)
        [metadata setValue:value forKey:BDSKPDFDocumentCreationDateAttribute];
    
    return metadata;
}

+ (id)metadataForURL:(NSURL *)fileURL error:(NSError **)outError;
{
    
    NSParameterAssert(fileURL != nil);

    PDFMetadata *metadata = nil;
    // check file type first?
    NSError *error = nil;
    NSString *errMsg = @"";
    NSString *privateException = NSStringFromSelector(_cmd);
    PDFDocument *document = nil;
    
    @try {
        
        fileURL = [fileURL fileURLByResolvingAliases];
        if(fileURL == nil){
            errMsg = NSLocalizedString(@"File does not exist.", @"Error description");
            @throw privateException;
        }
        
        document = [[PDFDocument alloc] initWithURL:fileURL];
        if(document == nil){
            errMsg = NSLocalizedString(@"Unable to read as PDF file.", @"Error description");
            @throw privateException;
        }
        
        NSDictionary *attributes = [document documentAttributes];
        
        if(attributes){
            // have to use NSClassFromString unless we link with PDFMetadata
            metadata = [[[self alloc] init] autorelease];
            [metadata setDictionary:attributes];
        } else {
            errMsg = NSLocalizedString(@"No PDF document attributes for file.", @"Error description");
            @throw privateException;
        }
        
    }
    
    @catch(id exception){
        
        if([exception isEqual:privateException]){
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
            if([fileURL path])
                [userInfo setObject:[fileURL path] forKey:NSFilePathErrorKey];
            if(errMsg != nil)
                [userInfo setObject:errMsg forKey:NSLocalizedDescriptionKey];
            if(error != nil)
                [userInfo setObject:error forKey:NSUnderlyingErrorKey];
            error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:userInfo];
        } else @throw;
    }
    
    @finally {
        [document release];
    }
    
    if(outError)
        *outError = error;
    else
        NSLog(@"%@ %@", self, error);
    return metadata; // may be nil
}

// the keys in the metadata dictionary must be PDFDocument keys
- (id)init
{
    if(self = [super init]){
        dictionary = [[NSMutableDictionary alloc] initWithCapacity:5];
    }
    return self;
}

- (void)dealloc
{
    [dictionary release];
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", [self class], dictionary];
}

// these keys are /always/ PDFDocument keys
- (id)valueForUndefinedKey:(NSString *)key { return [dictionary valueForKey:key]; }
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {  [dictionary setValue:value forKey:key]; }

- (NSDictionary *)dictionary { return dictionary; }

- (void)setDictionary:(NSDictionary *)newDictionary;
{
    if(newDictionary != dictionary){
        [dictionary release];
        dictionary = [newDictionary mutableCopy];
    }
}

- (BOOL)addToURL:(NSURL *)fileURL error:(NSError **)outError;
{
    NSParameterAssert(fileURL != nil);
    
    // check file type first?
    NSError *error = nil;
    NSString *errMsg = @"";
    NSString *privateException = NSStringFromSelector(_cmd);
    
    @try {
        
        fileURL = [fileURL fileURLByResolvingAliases];
        if(fileURL == nil){
            errMsg = NSLocalizedString(@"File does not exist.", @"Error description");
            @throw privateException;
        }
        
        PDFDocument *document = [[PDFDocument alloc] initWithURL:fileURL];
        if(document == nil){
            errMsg = NSLocalizedString(@"Unable to read as PDF file.", @"Error description");
            @throw privateException;
        }
        
        [document setDocumentAttributes:dictionary];
        
        // -[PDFDocument writeToURL:] returns YES even if it fails rdar://problem/4475062
        if([[document dataRepresentation] writeToURL:fileURL options:NSAtomicWrite error:&error] == NO){
            errMsg = NSLocalizedString(@"Unable to save PDF file.", @"Error description");
            [document release];
            @throw privateException;
        }
        
        [document release];
    }
    @catch(id exception){
        
        if([exception isEqual:privateException]){
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
            if([fileURL path])
                [userInfo setObject:[fileURL path] forKey:NSFilePathErrorKey];
            if(errMsg != nil)
                [userInfo setObject:errMsg forKey:NSLocalizedDescriptionKey];
            if(error != nil)
                [userInfo setObject:error forKey:NSUnderlyingErrorKey];
            error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:userInfo];
            if(outError)
                *outError = error;
            else
                NSLog(@"%@ %@", self, error);
            return NO;
        } else @throw;
    }
    
    return YES;
}

@end

