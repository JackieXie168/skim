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
    
    if([(NSString *)contentTypeUTI isEqualToString:@"net.sourceforge.bibdesk.bdskcache"]){
        
        NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfFile:(NSString *)pathToFile];
        
        if(!dictionary){
            [pool release];
            return FALSE;
        }
        
        [(NSMutableDictionary *)attributes addEntriesFromDictionary:dictionary];
        [(NSMutableDictionary *)attributes removeObjectForKey:@"FileAlias"]; // don't index this, since it's not useful to mds
        [dictionary release];
        
        [pool release];
        return TRUE;
    }
    
    if([(NSString *)contentTypeUTI isEqualToString:@"edu.ucsd.cs.mmccrack.bibdesk.bib"]){
        
        NSStringEncoding encoding;
        NSError *error = nil;
        
        NSString *fileString = [[NSString alloc] initWithContentsOfFile:(NSString *)pathToFile usedEncoding:&encoding error:&error];
        
        if(!fileString || error != nil){
            [pool release];
            return FALSE;
        }
        
        [(NSMutableDictionary *)attributes setObject:fileString forKey:(NSString *)kMDItemTextContent];
        [fileString release];

        [pool release];
        return TRUE;
    }
    
    return FALSE; // no recognized UTI
    
}