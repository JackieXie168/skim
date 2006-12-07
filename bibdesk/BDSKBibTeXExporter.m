//
//  BDSKBibTeXExporter.m
//  Bibdesk
//
//  Created by Michael McCracken on 1/11/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKBibTeXExporter.h"


@implementation BDSKBibTeXExporter

+ (NSString *)displayName{
    return NSLocalizedString(@"BibTeX File Exporter", @"bibtex exporter name");
}

- (id)init{
    self = [super init];
    if(self){
        outFileName = @"";
        outputEncoding = NSASCIIStringEncoding;
    }
    return self;
}

- (void)awakeFromNib{
    // TODO: populate encoding popup
    [fileNameTextField setStringValue:[self outFileName]];
    NSLog(@"Awake from nib");
}

- (void)dealloc {
    [outFileName release];
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];

    [coder encodeObject:[NSNumber numberWithUnsignedInt:outputEncoding] forKey:@"outputEncoding"];
    [coder encodeObject:outFileName forKey:@"outFileName"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if ([super initWithCoder:coder]) {

        [self setOutputEncoding:[[coder decodeObjectForKey:@"outputEncoding"] unsignedIntValue]];
        [self setOutFileName:[coder decodeObjectForKey:@"outFileName"]];
    }
    return self;
}

- (NSStringEncoding)outputEncoding { return outputEncoding; }


- (void)setOutputEncoding:(NSStringEncoding)newOutputEncoding {
    //NSLog(@"in -setOutputEncoding, old value of outputEncoding: (null), changed to: (null)", outputEncoding, newOutputEncoding);
    
    outputEncoding = newOutputEncoding;
}


- (NSString *)outFileName { return [[outFileName retain] autorelease]; }


- (void)setOutFileName:(NSString *)newOutFileName {
    //NSLog(@"in -setOutFileName:, old value of outFileName: %@, changed to: %@", outFileName, newOutFileName);
    
    if (outFileName != newOutFileName) {
        [outFileName release];
        outFileName = [newOutFileName copy];
    }
}

- (NSView *)settingsView{
    if(!enclosingView){
        [NSBundle loadNibNamed:@"BibTexExporterSettings" owner:self];
    }
    return enclosingView;
}

- (BOOL)exportPublicationsInArray:(NSArray *)pubs{
    
    BibItem *tmp;
    NSEnumerator *e = [[pubs sortedArrayUsingSelector:@selector(fileOrderCompare:)] objectEnumerator];
    NSMutableData *d = [NSMutableData data];
    NSMutableString *templateFile = [NSMutableString stringWithContentsOfFile:[[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKOutputTemplateFileKey] stringByExpandingTildeInPath]];
    
    [templateFile appendFormat:@"\n%%%% Created for %@ at %@ \n\n", NSFullUserName(), [NSCalendarDate calendarDate]];
    
    NSAssert ( outputEncoding != nil, @"Document does not have a specified string encoding." );
    
    NSString *encodingName = [[BDSKStringEncodingManager sharedEncodingManager] displayedNameForStringEncoding:outputEncoding];
    
    [templateFile appendFormat:@"\n%%%% Saved with string encoding %@ \n\n", encodingName];
    
    [d appendData:[templateFile dataUsingEncoding:outputEncoding allowLossyConversion:YES]];
   // [d appendData:[frontMatter dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    
    while(tmp = [e nextObject]){
        [d appendData:[[NSString stringWithString:@"\n\n"] dataUsingEncoding:outputEncoding  allowLossyConversion:YES]];
        [d appendData:[[tmp bibTeXString] dataUsingEncoding:outputEncoding allowLossyConversion:YES]];
    }
    
    [d writeToFile:[self outFileName] atomically:YES];
    
        
    return NO;
}

@end
