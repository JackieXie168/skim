#include <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

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
    
    CFStringRef cacheUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, CFSTR("bdskcache"), NULL);
    CFStringRef bibtexUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, CFSTR("bib"), NULL);

    @try{
        if(UTTypeEqual(contentTypeUTI, cacheUTI)){
            
            NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfFile:(NSString *)pathToFile];
            
            if(dictionary == nil)
                @throw exceptionString;
            
            [(NSMutableDictionary *)attributes addEntriesFromDictionary:dictionary];
            [(NSMutableDictionary *)attributes removeObjectForKey:@"FileAlias"]; // don't index this, since it's not useful to mds
            [dictionary release];

            success = TRUE;
            
        } else if(UTTypeEqual(contentTypeUTI, bibtexUTI)){
            
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
        if(cacheUTI) CFRelease(cacheUTI);
        if(bibtexUTI) CFRelease(bibtexUTI);
        [pool release];
        [savedException autorelease];
    }
    
    return success;
    
}