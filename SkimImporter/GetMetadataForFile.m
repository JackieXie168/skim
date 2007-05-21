#include <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>


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
    
    if (UTTypeEqual(contentTypeUTI, CFSTR("net.sourceforge.skim-app.skimnotes"))) {
        NSData *data = [[NSData alloc] initWithContentsOfFile:(NSString *)pathToFile options:0 error:NULL];
        if (data) {
            NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            if (array) {
                NSEnumerator *noteEnum = [array objectEnumerator];
                NSDictionary *note;
                NSMutableString *string = [[NSMutableString alloc] init];
                NSMutableArray *notes = [[NSMutableArray alloc] init];
                while (note = [noteEnum nextObject]) {
                    NSString *contents = [note objectForKey:@"contents"];
                    if (contents) {
                        if ([string length])
                            [string appendString:@"\n\n"];
                        [string appendString:contents];
                        [notes addObject:contents];
                    }
                    contents = [[note objectForKey:@"text"] string];
                    if (contents) {
                        if ([string length])
                            [string appendString:@"\n\n"];
                        [string appendString:contents];
                    }
                }
                [(NSMutableDictionary *)attributes setObject:string forKey:(NSString *)kMDItemTextContent];
                [(NSMutableDictionary *)attributes setObject:notes forKey:@"net_sourceforge_skim-app_notes"];
                [string release];
                [notes release];
            }
        }
        
        [(NSMutableDictionary *)attributes setObject:@"Skim" forKey:(NSString *)kMDItemCreator];
        
        NSString *pdfFile = [[(NSString *)pathToFile stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:pdfFile])
            [(NSMutableDictionary *)attributes setObject:[NSArray arrayWithObjects:pdfFile, nil] forKey:(NSString *)kMDItemWhereFroms];
        
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:(NSString *)pathToFile traverseLink:YES];
        NSDate *date;
        if (date = [fileAttributes objectForKey:NSFileModificationDate])
            [(NSMutableDictionary *)attributes setObject:date forKey:(NSString *)kMDItemContentModificationDate];
        if (date = [fileAttributes objectForKey:NSFileCreationDate])
            [(NSMutableDictionary *)attributes setObject:date forKey:(NSString *)kMDItemContentCreationDate];
        
        success = TRUE;
    } else {
        NSLog(@"Importer asked to handle unknown UTI %@ at path", contentTypeUTI, pathToFile);
    }
    
    [pool release];
    
    return success;
}
