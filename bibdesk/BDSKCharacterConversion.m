//
//  BDSKCharacterConversion.m
//  BibDesk
//
//  Created by Christiaan Hofman on 5/4/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKCharacterConversion.h"
#import "BibAppController.h"
#import "BDSKConverter.h"

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
		
		oneWayDict = [[NSMutableDictionary alloc] initWithCapacity:1];
		twoWayDict = [[NSMutableDictionary alloc] initWithCapacity:1];
		romanSet = [[NSMutableSet alloc] initWithCapacity:1];
		texSet = [[NSMutableSet alloc] initWithCapacity:1];
		currentDict = twoWayDict;
		
		ignoreEdit = NO;
		
		[self updateDicts];
		
	}
    return self;
}

- (void)dealloc
{
    [oneWayDict release];
    [twoWayDict release];
	[currentArray release];
	[texFormatter release];
	[romanSet release];
	[texSet release];
    [super dealloc];
}

- (void)awakeFromNib {
	texFormatter = [[BDSKTeXFormatter alloc] init];
    NSTableColumn *tc = [tableView tableColumnWithIdentifier:@"roman"];
    [[tc dataCell] setFormatter:[[[BDSKRomanCharacterFormatter alloc] init] autorelease]];
	tc = [tableView tableColumnWithIdentifier:@"tex"];
	[[tc dataCell] setFormatter:texFormatter];
	[self updateButtons];
}

- (void)updateDicts {
	// try to read the user file in the Application Support directory
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *applicationSupportPath = [[fm applicationSupportDirectory:kUserDomain] stringByAppendingPathComponent:@"BibDesk"];
	NSString *charConvPath = [applicationSupportPath stringByAppendingPathComponent:CHARACTER_CONVERSION_FILENAME];
	NSDictionary *tmpDict = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:CHARACTER_CONVERSION_FILENAME]];
	
	[oneWayDict removeAllObjects];
	[twoWayDict removeAllObjects];
	[romanSet removeAllObjects];
	[texSet removeAllObjects];
	
	[romanSet addObjectsFromArray:[[tmpDict objectForKey:ONE_WAY_CONVERSION_KEY] allKeys]];
	[romanSet addObjectsFromArray:[[tmpDict objectForKey:ROMAN_TO_TEX_KEY] allKeys]];
	[texSet addObjectsFromArray:[[tmpDict objectForKey:TEX_TO_ROMAN_KEY] allKeys]];
	
	if ([fm fileExistsAtPath:charConvPath]) {
		tmpDict = [NSDictionary dictionaryWithContentsOfFile:charConvPath];
		
		[oneWayDict addEntriesFromDictionary:[tmpDict objectForKey:ONE_WAY_CONVERSION_KEY]];
		[twoWayDict addEntriesFromDictionary:[tmpDict objectForKey:ROMAN_TO_TEX_KEY]];
		
		[romanSet addObjectsFromArray:[oneWayDict allKeys]];
		[romanSet addObjectsFromArray:[twoWayDict allKeys]];
		[texSet addObjectsFromArray:[twoWayDict allValues]];
	}
	
	[currentArray autorelease];
	currentArray = [[currentDict allKeys] mutableCopy];
	
	validRoman = YES;
	validTex = YES;
	
	[self setDocumentEdited:NO];
}

#pragma mark Acessors

- (int)listType {
    return (currentDict == oneWayDict)? 1 : 2;
}

- (void)setListType:(int)listType {
	if ([self listType] == listType)
		return;
	if (!validRoman || !validTex) {
		NSBeginAlertSheet(NSLocalizedString(@"Invalid Conversion", @""),
						  NSLocalizedString(@"OK", @"OK"),
						  nil,nil, [self window],self, NULL, NULL, NULL,
						  NSLocalizedString(@"The last item you entered is invalid or a duplicate. Please first edit it.",@""), nil);
		[listButton selectItemAtIndex:[listButton indexOfItemWithTag:[self listType]]];
		return;
	}
	
	currentDict = (listType == 1)? oneWayDict : twoWayDict;
	[currentArray autorelease];
	currentArray = [[currentDict allKeys] mutableCopy];
	
	validRoman = YES;
	validTex = YES;
	
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
    [self finalizeChangesIgnoringEdit:YES]; // commit edit before reloading
	[self updateDicts];
    [tableView reloadData];
	[self close];
}

- (IBAction)saveChanges:(id)sender {
    [self finalizeChangesIgnoringEdit:NO]; // commit edit before saving
	
	if (!validRoman || !validTex) {
		NSBeginAlertSheet(NSLocalizedString(@"Invalid Conversion", @""),
						  NSLocalizedString(@"OK", @"OK"),
						  nil,nil, [self window],self, NULL, NULL, NULL,
						  NSLocalizedString(@"The last item you entered is invalid or a duplicate. Please first edit it.",@""), nil);
		return;
	}
	
	NSString *error = nil;
	NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
	
	NSMutableDictionary *reverseDict = [NSMutableDictionary dictionaryWithCapacity:[twoWayDict count]];
	NSEnumerator *rEnum = [twoWayDict keyEnumerator];
	NSString *roman;
	while (roman = [rEnum nextObject]) {
		[reverseDict setObject:roman forKey:[twoWayDict objectForKey:roman]];
	}
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:oneWayDict, ONE_WAY_CONVERSION_KEY, 
																	twoWayDict, ROMAN_TO_TEX_KEY,
																	reverseDict, TEX_TO_ROMAN_KEY, nil];
	
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
	
	[self setDocumentEdited:NO];
	
	[self close];
}

- (IBAction)changeList:(id)sender {
    [self finalizeChangesIgnoringEdit:NO]; // commit edit before switching
	[self setListType:[[sender selectedItem] tag]];
}

- (IBAction)add:(id)sender {
    [self finalizeChangesIgnoringEdit:NO]; // make sure we are not editing
	
	NSString *newRoman = [NSString stringWithFormat:@"%C",0x00E4];
    NSString *newTex = [NSString stringWithString:@"{\\\"a}"];
	
	[currentArray addObject:newRoman];
	[currentDict setObject:newTex forKey:newRoman];
	[romanSet addObject:newRoman];
	if ([self listType] == 2)
		[texSet addObject:newTex];
	
	validRoman = NO;
	validTex = ([self listType] == 1);
	
    [tableView reloadData];
	
    int row = [currentArray indexOfObject:newRoman];
    [tableView selectRow:row byExtendingSelection:NO];
    [tableView editColumn:0 row:row withEvent:nil select:YES];
	
	[self setDocumentEdited:YES];
}

- (IBAction)remove:(id)sender {
    [self finalizeChangesIgnoringEdit:YES]; // make sure we are not editing
	
	int row = [tableView selectedRow];
	if (row == -1) return;
	NSString *oldRoman = [currentArray objectAtIndex:row];
	[currentArray removeObject:oldRoman];
	[currentDict removeObjectForKey:oldRoman];
	
	validRoman = YES;
	validTex = YES;
	
    [tableView reloadData];
	
    [tableView deselectAll:nil];
	
	[self setDocumentEdited:YES];
}

#pragma mark UI methods

- (void)updateButtons {
	[addButton setEnabled:(validRoman && validTex)];
	[removeButton setEnabled:[tableView selectedRow] != -1];
}

- (void)finalizeChangesIgnoringEdit:(BOOL)flag {
	ignoreEdit = flag;
	[[self window] makeFirstResponder:nil];
	ignoreEdit = NO;
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
	if (ignoreEdit) return;
	
	NSString *roman = [currentArray objectAtIndex:row];
	NSString *tex = [currentDict objectForKey:roman];
	
	if ([[tableColumn identifier] isEqualToString:@"roman"]) {
		if (!validRoman || ![object isEqualToString:roman]) {
			if ([romanSet containsObject:object]) {
				NSBeginAlertSheet(NSLocalizedString(@"Duplicate Unicode Character", @""),
								  NSLocalizedString(@"OK", @"OK"),
								  nil,nil, [self window],self, NULL, NULL, NULL,
								  [NSString stringWithFormat:NSLocalizedString(@"The character %@ you entered already has a TeX conversion. This could have been defined in the internal data.",@""), object], nil);
				
				[tableView reloadData];
			} else {
				[currentArray replaceObjectAtIndex:row withObject:object];
				[currentDict setObject:tex forKey:object];
				[currentDict removeObjectForKey:roman];
				[romanSet removeObject:roman];
				[romanSet addObject:object];
				
				validRoman = YES;
				
				[self setDocumentEdited:YES];
				[self updateButtons];
			}
		}
	}
	else {
		if (!validTex || ![object isEqualToString:tex]) {
			if ([self listType] == 2 && [texSet containsObject:object]) {
				NSBeginAlertSheet(NSLocalizedString(@"Duplicate TeX Conversion", @""),
								  NSLocalizedString(@"OK", @"OK"),
								  nil,nil, [self window],self, NULL, NULL, NULL,
								  [NSString stringWithFormat:NSLocalizedString(@"The TeX conversion %@ you entered already has a Unicode conversion. This could have been defined in the internal data.",@""), object], nil);
				
				[tableView reloadData];
			} else {
				[currentDict setObject:object forKey:roman];
				[texSet removeObject:tex];
				[texSet addObject:object];
				
				validTex = YES;
				
				[self setDocumentEdited:YES];
				[self updateButtons];
			}
		}
	}
}

#pragma mark NSTableView delegate methods

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)tv {
	if (!validRoman || !validTex) { // we force selection of an invalid row
		return NO;
	}
	return YES;
}

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
		[partialString characterAtIndex:[partialString length] - 1] == '}') {
		
		return YES;
	}
	
	if ([origString length] >= 3 &&
		[[origString substringToIndex:2] isEqualToString:@"{\\"] &&
		[origString characterAtIndex:[origString length] - 1] == '}') {
		
		*partialStringPtr = [[origString copy] autorelease]; // don't know why I need to do this, seems a bug
	} else {
		*partialStringPtr = @"{\\}";
	}
	
	*proposedSelRangePtr = NSMakeRange(2, [*partialStringPtr length] - 3);
	return NO;
}

@end
