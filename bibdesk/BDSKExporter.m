//
//  BDSKExporter.m
//  Bibdesk
//
//  Created by Michael McCracken on 1/11/05.
//

#import "BDSKExporter.h"

static NSMutableArray *availableExporterClassNames;

@implementation BDSKExporter

+ (void)initialize{
    // add class names for the available exporters to this array:
    availableExporterClassNames = [[NSArray alloc] initWithObjects:@"BDSKBibTeXExporter", nil];
}

+ (NSArray *)availableExporterClassNames{
    return availableExporterClassNames;
}

+ (NSArray *)availableExporterNames{
    NSMutableArray *availableExporterNames = [NSMutableArray arrayWithCapacity:1];
    
    foreach(className, availableExporterClassNames){
        NSString *displayName = [NSClassFromString(className) displayName];
        [availableExporterNames addObject:displayName];
    }
    return availableExporterNames;
}

+ (NSString *)displayName{
    [NSException raise:NSInternalInconsistencyException format:@"Must implement a complete subclass, including overriding displayName."];
    return nil;
}

- (id)init{
    self = [super init];
    if(self){
        
        [self setData:[[NSMutableDictionary alloc] initWithCapacity:5]];

    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:[self data] forKey:@"data"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if ([super initWithCoder:coder]) {
        [self setData:[coder decodeObjectForKey:@"data"]];
    }
    return self;
}


- (void)dealloc {
    [data release];
    [super dealloc];
}


- (NSMutableDictionary *)data { return [[data retain] autorelease]; }


- (void)setData:(NSMutableDictionary *)newData {
    //NSLog(@"in -setData:, old value of data: %@, changed to: %@", data, newData);
    
    if (data != newData) {
        [data release];
        data = [newData copy];
    }
}

- (NSView *)settingsView{
    [NSException raise:NSInternalInconsistencyException format:@"Must implement a complete subclass."];
    return nil;
}

- (BOOL)exportPublicationsInArray:(NSArray *)pubs{
    [NSException raise:NSInternalInconsistencyException format:@"Must implement a complete subclass."];
    return NO;
}



@end
