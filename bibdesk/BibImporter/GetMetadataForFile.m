#include <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
//  Created by Adam Maxwell on 09/26/04.
/*
 This software is Copyright (c) 2005,2006
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
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE
*/

/* -----------------------------------------------------------------------------
   Step 1
   Set the UTI types the importer supports
  
   Modify the CFBundleDocumentTypes entry in Info.plist to contain
   an array of Uniform Type Identifiers (UTI) for the LSItemContentTypes 
   that your importer can handle
  
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 2 
   Implement the GetMetadataForFile function
  
   Implement the GetMetadataForFile function below to scrape the relevant
   metadata from your document and return it as a CFDictionary using standard keys
   (defined in MDItem.h) whenever possible.
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 3 (optional) 
   If you have defined new attributes, update the schema.xml file
  
   Edit the schema.xml file to include the metadata keys that your importer returns.
   Add them to the <allattrs> and <displayattrs> elements.
  
   Add any custom types that your importer requires to the <attributes> element
  
   <attribute name="com_mycompany_metadatakey" type="CFString" multivalued="true"/>
  
   ----------------------------------------------------------------------------- */



/* -----------------------------------------------------------------------------
    Get metadata attributes from file
   
   This function's job is to extract useful information your file format supports
   and return it as a dictionary
   ----------------------------------------------------------------------------- */

Boolean GetMetadataForFile(void* thisInterface, 
			   CFMutableDictionaryRef attributes, 
			   CFStringRef contentTypeUTI,
			   CFStringRef pathToFile)
{
    /* Pull any available metadata from the file at the specified path */
    /* Return the attribute keys and attribute values in the dict */
    /* Return TRUE if successful, FALSE if there was no data provided */
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    Boolean success = FALSE;
    id savedException = nil;
    
    NSString *exceptionString = @"BDSKGenericImportFailureException";
    
    CFStringRef cacheUTI = CFSTR("net.sourceforge.bibdesk.bdskcache");
    CFStringRef bibtexUTI = CFSTR("edu.ucsd.cs.mmccrack.bibdesk.bib");
    CFStringRef risUTI = CFSTR("edu.ucsd.cs.mmccrack.bibdesk.ris");
    
    @try{
        if(UTTypeEqual(contentTypeUTI, cacheUTI)){
            
            NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfFile:(NSString *)pathToFile];
            
            if(dictionary == nil)
                @throw exceptionString;
            
            [(NSMutableDictionary *)attributes addEntriesFromDictionary:dictionary];
            [(NSMutableDictionary *)attributes removeObjectForKey:@"FileAlias"]; // don't index this, since it's not useful to mds
            [dictionary release];

            success = TRUE;
            
        } else if(UTTypeEqual(contentTypeUTI, bibtexUTI) || UTTypeEqual(contentTypeUTI, risUTI)){
            
            NSStringEncoding encoding;
            NSError *error = nil;
            
            // try to interpret as Unicode, then default C encoding (likely MacOSRoman)
            NSString *fileString = [[NSString alloc] initWithContentsOfFile:(NSString *)pathToFile usedEncoding:&encoding error:&error];
            
            if(fileString == nil || error != nil){
                // read file as data instead
                NSData *data = [[NSData alloc] initWithContentsOfFile:(NSString *)pathToFile];
                if(data == nil || [data length] == 0)
                    @throw exceptionString;
                
                // try UTF-8 next (covers ASCII as well)
                fileString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                // last-ditch effort: ISO-8859-1
                if(fileString == nil)
                    fileString = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
                
                // done with this, whether we succeeded or not
                [data release];
                
                // could use TEC here, but that seems like overkill
                if(fileString == nil)
                    @throw exceptionString;
            }
            
            [(NSMutableDictionary *)attributes setObject:fileString forKey:(NSString *)kMDItemTextContent];
            [fileString release];
            
            success = TRUE;
        } else
            @throw exceptionString;
    }
    
    @catch(id exception){

        success = FALSE;

        if([[exception description] isEqualToString:exceptionString] == NO){
            savedException = [exception retain];
            @throw;
        }
    }
    
    // this gets executed on all exit paths
    @finally{
        [pool release];
        [savedException autorelease];
    }
    
    return success;
    
}