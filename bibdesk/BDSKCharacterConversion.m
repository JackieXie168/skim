//
//  BDSKCharacterConversion.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 5/4/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKCharacterConversion.h"
#import "BibAppController.h"
#import "BDSKConverter.h"

#define CHARACTER_CONVERSION_FILENAME	@"CharacterConversion.plist"
#define ONE_WAY_CONVERSION_KEY			@"One-Way Conversions"
#define TWO_WAY_CONVERSION_KEY			@"Roman to TeX"

static BDSKCharacterConversion *sharedConversionEditor;

@implementation BDSKCharacterConversion

+ (BDSKCharacterConversion *)sharedConversionEditor{
    if (!sharedConversionEditor) {
        sharedConversionEditor = [[BDSKCharacterConversion alloc] init];
    }
    return sharedConversionEditor;
}

- (id)init
{
    if (self = [super initWithWindowNibName:@"BDSKCharacterConversion"]) {    
		
		// try to read the user file in the Application Support directory
		NSFileManager *fm = [NSFileManager defaultManager];
		NSString *applicationSupportPath = [[fm applicationSupportDirectory:kUserDomain] stringByAppendingPathComponent:@"BibDesk"];
		NSString *charConvPath = [applicationSupportPath stringByAppendingPathComponent:CHARACTER_CONVERSION_FILENAME];
		
		if ([fm fileExistsAtPath:charConvPath]) {
			NSDictionary *tmpDict = [NSDictionary dictionaryWithContentsOfFile:charConvPath];
			oneWayDict = [[tmpDict objectForKey:ONE_WAY_CONVERSION_KEY] mutableCopy];
			twoWayDict = [[tmpDict objectForKey:TWO_WAY_CONVERSION_KEY] mutableCopy];
		}
		if (oneWayDict == nil) {
			oneWayDict = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
		}
		if (twoWayDict == nil) {
			twoWayDict = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
		}
		
        [self setListType:2];
    }
    return self;
}

- (void)dealloc
{
    [oneWayDict release];
    [twoWayDict release];
	[currentArray autorelease];
	[texFormatter autorelease];
    [super dealloc];
}

- (void)awakeFromNib {
	texFormatter = [[BDSKTeXFormatter alloc] init];
    NSTableColumn *tc = [tableView tableColumnWithIdentifier:@"roman"];
    [[tc dataCell] setFormatter:[[[BDSKRomanCharacterFormatter alloc] init] autorelease]];
	if ([self listType] == 2) {
		tc = [tableView tableColumnWithIdentifier:@"tex"];
		[[tc dataCell] setFormatter:texFormatter];
	}
	[self updateButtons];
}

#pragma mark Acessors

- (int)listType {
    return (currentDict == oneWayDict)? 1 : 2;
}

- (void)setListType:(int)listType {
	currentDict = (listType == 1)? oneWayDict : twoWayDict;
	[currentArray autorelease];
	currentArray = [[currentDict allKeys] mutableCopy];
	
	NSTableColumn *tc = [tableView tableColumnWithIdentifier:@"tex"];
	if (listType == 2) {
		[[tc dataCell] setFormatter:texFormatter];
	} else {
		[[tc dataCell] setFormatter:nil];
	}
	[tableView reloadData];
}

- (NSDictionary *)oneWayDict {
    return [[oneWayDict copy] autorelease];
}

- (void)setOneWayDict:(NSDictionary *)newOneWayDict {
    if (oneWayDict != newOneWayDict) {
        [oneWayDict release];
        oneWayDict = [newOneWayDict mutableCopy];
    }
}

- (NSDictionary *)twoWayDict {
    return [[twoWayDict copy] autorelease];
}

- (void)setTwoWayDict:(NSDictionary *)newTwoWayDict {
    if (twoWayDict != newTwoWayDict) {
        [twoWayDict release];
        twoWayDict = [newTwoWayDict mutableCopy];
    }
}

#pragma mark Actions

- (IBAction)cancel:(id)sender {
	[self close];
}

- (IBAction)saveChanges:(id)sender {
	NSString *error = nil;
	NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
	
	NSMutableDictionary *reverseDict = [NSMutableDictionary dictionaryWithCapacity:[twoWayDict count]];
	NSEnumerator *rEnum = [twoWayDict keyEnumerator];
	NSString *roman;
	while (roman = [rEnum nextObject]) {
		[reverseDict setObject:roman forKey:[twoWayDict objectForKey:roman]];
	}
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:oneWayDict, @"One-Way Conversions", 
																	twoWayDict, @"Roman to TeX",
																	reverseDict, @"TeX to Roman", nil];
	
	NSData *data = [NSPropertyListSerialization dataFromPropertyList:dict
															  format:format 
													errorDescription:&error];
	if (error) {
		NSLog(@"Error writing: %@", error);
	} else {
		NSString *applicationSupportPath = [[[NSFileManager defaultManager] applicationSupportDirectory:kUserDomain] stringByAppendingPathComponent:@"BibDesk"]; 
		NSString *charConvPath = [applicationSupportPath stringByAppendingPathComponent:CHARACTER_CONVERSION_FILENAME];
		[data writeToFile:charConvPath atomically:YES];
	}
	
	// tell the converter to reload its dictionaries
	[[BDSKConverter sharedConverter] loadDict];
	
	[self close];
}

- (IBAction)changeList:(id)sender {
	[self setListType:[[sender selectedItem] tag]];
}

- (IBAction)add:(id)sender {
    NSString *newRoman = [NSString stringWithFormat:@"%C",0x00E4];
    NSString *newTex = [NSString stringWithString:@"{\\\"a}"];
    [currentArray addObject:newRoman];
    [currentDict setObject:newTex forKey:newRoman];
	
    [tableView reloadData];
	
    int row = [currentArray indexOfObject:newRoman];
    [tableView selectRow:row byExtendingSelection:NO];
    [tableView editColumn:0 row:row withEvent:nil select:YES];
}

- (IBAction)remove:(id)sender {
	int row = [tableView selectedRow];
	if (row == -1) return;
	NSString *oldRoman = [currentArray objectAtIndex:row];
	[currentArray removeObject:oldRoman];
	[currentDict removeObjectForKey:oldRoman];
	
    [tableView reloadData];
	
    [tableView deselectAll:nil];
}

#pragma mark UI methods

- (void)updateButtons {
	[addButton setEnabled:YES];
	[removeButton setEnabled:[tableView selectedRow] != -1];
}

#pragma mark NSTableview Datasource

- (int)numberOfRowsInTableView:(NSTableView *)tv {
	return [currentArray count];
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	NSString *roman = [currentArray objectAtIndex:row];
	if ([[tableColumn identifier] isEqualToString:@"roman"]) {
		return roman;
	}
	else {
		return [currentDict objectForKey:roman];
	}
}

- (void)tableView:(NSTableView *)tv setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	NSString *roman = [currentArray objectAtIndex:row];
	if ([[tableColumn identifier] isEqualToString:@"roman"]) {
		if (![object isEqualToString:roman]) {
			if (![currentArray containsObject:object]) {
				[currentArray replaceObjectAtIndex:row withObject:object];
				[currentDict setObject:[currentDict objectForKey:roman] forKey:object];
				[currentDict removeObjectForKey:roman];
			} else {
				NSLog(@"Try to set duplicate Roman conversion %@",object);
				[tableView reloadData];
			}
		}
	}
	else {
		if (![object isEqualToString:[currentDict objectForKey:roman]]) {
			if ([self listType] == 2 && [[currentDict allKeysForObject:object] count] > 0) {
				NSLog(@"Try to set duplicate TeX conversion %@",object);
				[tableView reloadData];
			} else {
				[currentDict setObject:object forKey:roman];
			}
		}
	}
}

#pragma mark NSTableView delegate methods

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	[self updateButtons];
}

@end


@implementation BDSKRomanCharacterFormatter

- (NSString *)stringForObjectValue:(id)obj{
    return obj;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)obj withDefaultAttributes:(NSDictionary *)attrs{
    // NSLog(@"attributed string for obj");
    return [[[NSAttributedString alloc] initWithString:[self stringForObjectValue:obj]] autorelease];
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error{
    *obj = string;
    return YES;
}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString **)error{
    return ([*partialStringPtr length] < 2);
}

@end


@implementation BDSKTeXFormatter

- (NSString *)stringForObjectValue:(id)obj{
    return obj;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)obj withDefaultAttributes:(NSDictionary *)attrs{
    // NSLog(@"attributed string for obj");
    return [[[NSAttributedString alloc] initWithString:[self stringForObjectValue:obj]] autorelease];
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error{
    *obj = string;
    return YES;
}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString **)error{
	NSString *partialString = *partialStringPtr;
	if ([partialString length] >= 3 &&
		[[partialString substringToIndex:2] isEqualToString:@"{\\"] &&
		[partialString characterAtIndex:[partialString length] - 1] == '}') 
		return YES;
	return NO;
}

@end
