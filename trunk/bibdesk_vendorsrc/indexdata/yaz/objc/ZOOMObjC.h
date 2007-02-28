/*
 *  ZOOM.h
 *  yaz
 *
 *  Created by Adam Maxwell on 12/26/06.
 *
 */

#import <yaz/zoom.h>
#import "ZOOMConnection.h"
#import "ZOOMResultSet.h"
#import "ZOOMRecord.h"
#import "ZOOMQuery.h"

/*!
    @header ZOOMObjC
    @abstract   Umbrella header for the ZOOM Objective-C API.
    @discussion Only this header should be included in your project.  Here is the obligatory sample program demonstrating the basic usage of the API.  This will not compile unless you put the framework in a location where the system can find it and change the install path, but the sample program (z3950Test) included with the framework will compile and embed the framework correctly.

<code>
#define DEFAULT_SEARCH @"bob dylan" <br />
#define MAX_RESULTS 5

int main (int argc, char const* argv[])
{
        
&nbsp;&nbsp;NSAutoreleasePool *pool = [NSAutoreleasePool new];
 
&nbsp;&nbsp;NSArray *args = [[NSProcessInfo processInfo] arguments];

&nbsp;&nbsp;ZOOMConnection *conn = [[ZOOMConnection alloc] initWithHost:@"biblio.unizh.ch" database:@"ids_utf" port:9909]; <br />
&nbsp;&nbsp;[conn setUsername:@"z39"]; <br />
&nbsp;&nbsp;[conn setPassword:@"z39"]; <br />
&nbsp;&nbsp;[conn setPreferredRecordSyntax:USMARC]; <br />
&nbsp;&nbsp;[conn setResultEncodingToIANACharSetName:@"utf-8"];
    
&nbsp;&nbsp;[BDSKZoomRecord setFallbackEncoding:NSISOLatin1StringEncoding];
    
&nbsp;&nbsp;NSString *searchString = [args count] > 1 ? [args objectAtIndex:1] : DEFAULT_SEARCH;
    
&nbsp;&nbsp;BDSKZoomResultSet *resultSet = [conn resultsForCCLQuery:searchString]; <br />
&nbsp;&nbsp;unsigned int count = [resultSet countOfRecords]; <br />
    
&nbsp;&nbsp;NSLog(@"%d results found for \"%@\"", count, searchString);
    
&nbsp;&nbsp;if (count) { <br />
&nbsp;&nbsp;&nbsp;&nbsp;unsigned i, iMax = MIN(MAX_RESULTS, count); <br />
&nbsp;&nbsp;&nbsp;&nbsp;NSMutableString *mutableString = [NSMutableString string]; <br />
&nbsp;&nbsp;&nbsp;&nbsp;BDSKZoomRecord *record;
        
&nbsp;&nbsp;&nbsp;&nbsp;for (i = 0; i < iMax; i++) { <br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[mutableString appendFormat:@"\n***** RECORD %d *****\n", i]; <br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;record = [resultSet recordAtIndex:i]; <br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[mutableString appendFormat:@"Syntax: %@\n", [BDSKZoomRecord stringWithSyntaxType:[record syntaxType]]]; <br /> 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[mutableString appendString:[record rawString]]; <br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[mutableString appendString:@"\n"]; <br />
&nbsp;&nbsp;&nbsp;&nbsp;} <br />
&nbsp;&nbsp;&nbsp;&nbsp;NSLog(@"%@", mutableString); <br />
&nbsp;&nbsp;}
    
&nbsp;&nbsp;[conn release]; <br />
&nbsp;&nbsp;[pool release]; <br />
    
&nbsp;&nbsp;return 0; <br />
}
</code>
 
*/
