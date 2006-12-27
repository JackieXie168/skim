//
//  Controller.m
//  z3950Test
//
//  Created by Adam Maxwell on 12/25/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "Controller.h"
#import <yaz/BDSKZoom.h>

@implementation Controller

- (void)awakeFromNib
{
    _connection = [[BDSKZoomConnection alloc] initWithHost:@"z3950.loc.gov:7090/Voyager" port:0];
    [BDSKZoomRecord setFallbackEncoding:NSISOLatin1StringEncoding];
    
    connection = ZOOM_connection_create(0);
    ZOOM_connection_option_set(connection, "preferredRecordSyntax", "USMARC");
    ZOOM_connection_option_set(connection, "charset", "UTF-8");
    ZOOM_connection_option_set(connection, "lang", "en-US");
    ZOOM_connection_connect(connection, "z3950.loc.gov:7090/Voyager", 0);
    
    [_popup removeAllItems];
    [_popup addItemsWithTitles:[BDSKZoomRecord validKeys]];
    [_popup selectItemAtIndex:0];
    _currentType = [[[BDSKZoomRecord validKeys] objectAtIndex:0] copy];
}

- (void)dealloc
{
    [_connection release];
    [_currentType release];
    [super dealloc];
}

- (void)applicationWillTerminate:(NSNotification *)notification;
{
    ZOOM_connection_destroy(connection);
}

/*
 use e.g. "render;charset=ISO-8859-1" to specify the record's charset; will be converted to UTF-8
 */

- (IBAction)search:(id)sender;
{
    NSString *searchString = [sender stringValue];
    if (nil == searchString || [searchString isEqualToString:@""]) {
        [_textView setString:@""];
    } else {
        
        BDSKZoomResultSet *resultSet = [_connection resultsForCCLQuery:searchString];
        
        unsigned int count = [resultSet countOfRecords];
        [_textView setString:[NSString stringWithFormat:@"%d results found for \"%@\"", count, searchString]];
        
        if (count) {
            unsigned i, iMax = MIN(5, count);
            NSMutableString *mutableString = [[_textView textStorage] mutableString];
            BDSKZoomRecord *record;

            for (i = 0; i < iMax; i++) {
                [mutableString appendString:@"\n\n"];
                [mutableString appendFormat:@"***** RECORD %d *****\n", i];
                record = [resultSet recordAtIndex:i];
                [mutableString appendString:[record valueForKey:_currentType]];
            }
        }
    }
}   

- (IBAction)changeType:(id)sender;
{
    [_currentType release];
    _currentType = [[sender titleOfSelectedItem] copy];
    [self search:_searchField];
}

- (void)doNothing:(id)sender
{
    ZOOM_resultset r;
    const char *rec;
    
    NSString *searchString = [sender stringValue];
    // r = ZOOM_connection_search_pqf(connection, [[sender stringValue] UTF8String]);
    
    if (nil == searchString || [searchString isEqualToString:@""]) {
        [_textView setString:@""];
    } else {
        ZOOM_query query = ZOOM_query_create();
        const char *errstring;
        int error, errorPosition;
        if (ZOOM_query_ccl2rpn(query, [searchString UTF8String], "term t=l,r s=al\n" "ti u=4 s=pw\n", &error, &errstring, &errorPosition) == 0) {
            r = ZOOM_connection_search(connection, query);
            
            [_textView setString:[NSString stringWithFormat:@"%d results found for \"%@\"", ZOOM_resultset_size(r), searchString]];
            [[[_textView textStorage] mutableString] appendString:@"\n\n"];

            ZOOM_record zrecord = ZOOM_resultset_record(r, 0);
            
            // string "ventin" produces error
            rec = ZOOM_record_get(zrecord, "render", NULL);
            NSString *record = (rec ? [NSString stringWithCString:rec encoding:NSUTF8StringEncoding] : @"Nothing found");
            
            if (nil == record) {
                record = @"Unable to convert c string to NSString";
                record = [record stringByAppendingFormat:@"\n\n%@", [NSString stringWithCString:rec encoding:NSISOLatin1StringEncoding]];
            }
            
            if ([@"" isEqualToString:record])
                record = @"Empty description of record";
            
            [[[_textView textStorage] mutableString] appendString:record];
        } else {
            [_textView setString:@"Unable to translate ccl query"];
        }
        ZOOM_query_destroy(query);
        [[_textView textStorage] addAttribute:NSFontAttributeName value:[NSFont userFixedPitchFontOfSize:10.0] range:NSMakeRange(0, [[_textView textStorage] length])];
    }
}

@end
