//
//  Controller.m
//  z3950Test
//
//  Created by Adam Maxwell on 12/25/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "Controller.h"
@implementation Controller

- (void)awakeFromNib
{
    //_connection = [[BDSKZoomConnection alloc] initWithHost:@"z3950.loc.gov:7090/Voyager" port:0];
    
    _hostname = [@"z3950.copac.ac.uk" copy];
    _port = 2100;
    _database = [@"copac" copy];
    
    [_addressField setStringValue:_hostname];
    [_dbaseField setStringValue:_database];
    [_portField setIntValue:_port];
    
    [BDSKZoomRecord setFallbackEncoding:NSWindowsCP1252StringEncoding];
    
    [_popup removeAllItems];
    [_popup addItemsWithTitles:[BDSKZoomRecord validKeys]];
    [_popup selectItemAtIndex:0];
    _currentType = [[[BDSKZoomRecord validKeys] objectAtIndex:0] copy];
    _syntaxType = XML; //USMARC;
    
    [_searchField setDelegate:self];
    [_searchField setFormatter:[[[BDSKZoomCCLQueryFormatter alloc] init] autorelease]];
    
    [_syntaxPopup removeAllItems];
    [_syntaxPopup addItemsWithTitles:[NSArray arrayWithObjects:@"USMARC", @"GRS-1", @"SUTRS", @"XML", @"UKMARC", nil]];
    [_syntaxPopup selectItemAtIndex:3];
    
    _connectionNeedsReset = YES;
    
}

- (void)dealloc
{
    [_connection release];
    [_currentType release];
    [super dealloc];
}

- (IBAction)changeSyntaxType:(id)sender;
{
    _syntaxType = [BDSKZoomRecord syntaxTypeWithString:[sender titleOfSelectedItem]];
    [_connection setPreferredRecordSyntax:_syntaxType];
    [self search:_searchField];
    NSLog(@"%@", [_connection propertyList]);
}

- (void)makeNewConnection
{
    [_connection release];
    _connection = [[BDSKZoomConnection alloc] initWithHost:_hostname port:_port database:_database];
    [_connection setPreferredRecordSyntax:_syntaxType];
    _connectionNeedsReset = NO;
    NSLog(@"%@", [_connection propertyList]);
}

- (IBAction)changeAddress:(id)sender;
{
    [_hostname release];
    _hostname = [[sender stringValue] copy];
    _connectionNeedsReset = YES;
}

- (IBAction)changePort:(id)sender;
{
    _port = [sender intValue];
    _connectionNeedsReset = YES;
}

- (IBAction)changeDbase:(id)sender;
{
    [_database release];
    _database = [[sender stringValue] copy];
    _connectionNeedsReset = YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification;
{
    ZOOM_connection_destroy(connection);
}

- (BOOL)control:(NSControl *)control didFailToFormatString:(NSString *)string errorDescription:(NSString *)error
{
    NSBeginAlertSheet(@"Invalid query string", nil, nil, nil, [_textView window], nil, NULL, NULL, NULL, error);
    return NO;
}
/*
 use e.g. "render;charset=ISO-8859-1" to specify the record's charset; will be converted to UTF-8
 */

static NSString *joinedArrayComponents(NSArray *arrayOfXMLNodes)
{
    NSArray *strings = [arrayOfXMLNodes valueForKeyPath:@"stringValue"];
    return [strings componentsJoinedByString:@"; "];
}

- (NSArray *)dictionariesWithXMLString:(NSString *)xmlString
{
    NSError *error = nil;
    NSXMLDocument *doc = [[NSXMLDocument alloc] initWithXMLString:xmlString options:0 error:&error];
    
    NSXMLElement *root = [doc rootElement];
    
    NSMutableArray *arrayOfPubs = [NSMutableArray array];
    unsigned i, iMax = [root childCount];
    NSXMLNode *node;
    for (i = 0; i < iMax; i++) {
        
        node = [root childAtIndex:i];
        NSMutableDictionary *pubDict = [[NSMutableDictionary alloc] initWithCapacity:5];

        NSArray *array = [node nodesForXPath:@"title" error:NULL];
        [pubDict setObject:joinedArrayComponents(array) forKey:@"Title"];
        
        array = [node nodesForXPath:@"creator" error:NULL];
        [pubDict setObject:joinedArrayComponents(array) forKey:@"Author"];

        array = [node nodesForXPath:@"subject" error:NULL];
        [pubDict setObject:joinedArrayComponents(array) forKey:@"Keywords"];

        array = [node nodesForXPath:@"publisher" error:NULL];
        [pubDict setObject:joinedArrayComponents(array) forKey:@"Publisher"];

        array = [node nodesForXPath:@"location" error:NULL];
        [pubDict setObject:joinedArrayComponents(array) forKey:@"Location"];
        
        [arrayOfPubs addObject:pubDict];
        [pubDict release];
    }

    [doc release];
    
    return arrayOfPubs;
}
    
    

- (IBAction)search:(id)sender;
{
    NSString *searchString = [sender stringValue];
    
    if (_connectionNeedsReset)
        [self makeNewConnection];
    
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
                [mutableString appendFormat:@"Syntax: %@\n", [BDSKZoomRecord stringWithSyntaxType:[record syntaxType]]];
                
                NSString *value = [record valueForKey:_currentType];
                [mutableString appendString:(value ? value : [NSString stringWithFormat:@"record returned nil for %@", _currentType])];
                NSLog(@"%@", [self dictionariesWithXMLString:value]);
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
