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
    
    /* Should create plists for these, but I don't feel like it */
    
    /* standard server */
    /*
    _hostname = [@"z3950.loc.gov" copy];
    _port = 7090;
    _database = [@"voyager" copy];  
     */
    
    /* copac has XML only */
    /*
    _hostname = [@"z3950.copac.ac.uk" copy];
    _port = 2100;
    _database = [@"copac" copy];
     */
    
    /* http://www.ub.unibas.ch/lib/aleph/z3950.htm */
    /* USMARC as MARC-8 */
    /*
    _hostname = [@"aleph.unibas.ch" copy];
    _port = 9909;
    _database = [@"IDS_ANSEL" copy];    
    */
    
    /* USMARC as UTF-8 */
    /*
    _hostname = [@"aleph.unibas.ch" copy];
    _port = 9909;
    _database = [@"IDS_UTF" copy];    
     */
    
    _hostname = [@"biblio.unizh.ch" copy];
    _port = 9909;
    _database = [@"ids_utf" copy];
    _options = [[NSDictionary alloc] initWithObjectsAndKeys:@"z39", @"user", @"z39", @"password", nil];
    
    [_addressField setStringValue:_hostname];
    [_dbaseField setStringValue:_database];
    [_portField setIntValue:_port];
    
    [ZOOMRecord setFallbackEncoding:NSISOLatin1StringEncoding];
    
    [_popup removeAllItems];
    [_popup addItemsWithTitles:[ZOOMRecord validKeys]];
    [_popup selectItemAtIndex:0];
    _currentType = [[[ZOOMRecord validKeys] objectAtIndex:0] copy];
    _syntaxType = USMARC;
    
    [_searchField setDelegate:self];
    [_searchField setFormatter:[[[ZOOMCCLQueryFormatter alloc] init] autorelease]];
    
    [_syntaxPopup removeAllItems];
    [_syntaxPopup addItemsWithTitles:[NSArray arrayWithObjects:@"USMARC", @"GRS-1", @"SUTRS", @"XML", @"UKMARC", nil]];
    [_syntaxPopup selectItemAtIndex:0];
    
    _connectionNeedsReset = YES;
    
    NSArray *charsets = [NSArray arrayWithObjects:@"MARC-8", @"UTF-8", @"ISO-8859-1", nil];
    [_charSetPopup removeAllItems];
    [_charSetPopup addItemsWithTitles:charsets];
    [_charSetPopup selectItemAtIndex:0];
    _currentCharSet = [[charsets objectAtIndex:0] copy];
    
}

- (void)dealloc
{
    [_connection release];
    [_currentType release];
    [super dealloc];
}

- (IBAction)changeCharSet:(id)sender;
{
    [_currentCharSet autorelease];
    _currentCharSet = [[sender titleOfSelectedItem] copy];
    [_connection setResultEncodingToIANACharSetName:_currentCharSet];
    [self search:_searchField];
}

- (IBAction)changeSyntaxType:(id)sender;
{
    _syntaxType = [ZOOMRecord syntaxTypeWithString:[sender titleOfSelectedItem]];
    [_connection setPreferredRecordSyntax:_syntaxType];
    [self search:_searchField];
    NSLog(@"%@", [_connection propertyList]);
}

- (void)makeNewConnection
{
    [_connection release];
    _connection = [[ZOOMConnection alloc] initWithHost:_hostname port:_port database:_database];
    [_connection setPreferredRecordSyntax:_syntaxType];
    _connectionNeedsReset = NO;
    NSEnumerator *keyE = [_options keyEnumerator];
    NSString *key;
    while (key = [keyE nextObject])
        [_connection setOption:[_options objectForKey:key] forKey:key];
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
        
        ZOOMResultSet *resultSet = [_connection resultsForCCLQuery:searchString];
        
        unsigned int count = [resultSet countOfRecords];
        [_textView setString:[NSString stringWithFormat:@"%d results found for \"%@\"", count, searchString]];
        
        if (count) {
            unsigned i, iMax = MIN(5, count);
            NSMutableString *mutableString = [[_textView textStorage] mutableString];
            ZOOMRecord *record;

            for (i = 0; i < iMax; i++) {
                [mutableString appendString:@"\n\n"];
                [mutableString appendFormat:@"***** RECORD %d *****\n", i];
                record = [resultSet recordAtIndex:i];
                [mutableString appendFormat:@"Syntax: %@\n", [ZOOMRecord stringWithSyntaxType:[record syntaxType]]];
                
                NSString *value = [record stringValueForKey:_currentType];
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

@end
