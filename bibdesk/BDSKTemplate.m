//
//  BDSKTemplate.m
//  Bibdesk
//
//  Created by Adam Maxwell on 05/23/06.
/*
 This software is Copyright (c) 2006
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BDSKTemplate.h"
#import "BDAlias.h"
#import "NSFileManager_BDSKExtensions.h"
#import "NSURL_BDSKExtensions.h"

NSString *BDSKTemplateRoleString = @"role";
NSString *BDSKTemplateNameString = @"name";
NSString *BDSKTemplateFileURLString = @"representedFileURL";
NSString *BDSKExportTemplateTree = @"BDSKExportTemplateTree";
NSString *BDSKServiceTemplateTree = @"BDSKServiceTemplateTree";

NSString *BDSKTemplateAccessoryString = @"Accessory File";
NSString *BDSKTemplateMainPageString = @"Main Page";
NSString *BDSKTemplateDefaultItemString = @"Default Item";

static inline NSString *itemTemplateSubstring(NSString *templateString){
    int start, end, length = [templateString length];
    NSRange range = [templateString rangeOfString:@"<$publications>"];
    start = NSMaxRange(range);
    if (start != NSNotFound) {
        range = [templateString rangeOfTrailingEmptyLineInRange:NSMakeRange(start, length - start)];
        if (range.location != NSNotFound)
            start = NSMaxRange(range);
        range = [templateString rangeOfString:@"</$publications>" options:0 range:NSMakeRange(start, length - start)];
        end = range.location;
        if (end != NSNotFound) {
            range = [templateString rangeOfString:@"<?$publications>" options:0 range:NSMakeRange(start, end - start)];
            if (range.location != NSNotFound)
                end = range.location;
            range = [templateString rangeOfLeadingEmptyLineInRange:NSMakeRange(start, end - start)];
            if (range.location != NSNotFound)
                end = range.location;
        } else
            return nil;
    } else
        return nil;
    return [templateString substringWithRange:NSMakeRange(start, end - start)];
}

@implementation BDSKTemplate

#pragma mark Class methods

+ (NSArray *)defaultExportTemplates
{
    NSMutableArray *itemNodes = [[NSMutableArray alloc] initWithCapacity:4];
    NSString *appSupportPath = [[NSFileManager defaultManager] currentApplicationSupportPathForCurrentUser];
    NSString *templatesPath = [appSupportPath stringByAppendingPathComponent:@"Templates"];
    BDSKTemplate *template = nil;
    NSURL *fileURL = nil;
    
    // HTML template
    template = [[BDSKTemplate alloc] init];
    [template setValue:@"Default HTML template" forKey:BDSKTemplateNameString];
    [template setValue:@"html" forKey:BDSKTemplateRoleString];
    [itemNodes addObject:template];
    [template release];
            
    // main page template
    fileURL = [NSURL fileURLWithPath:[templatesPath stringByAppendingPathComponent:@"htmlExportTemplate.html"]];
    [template addChildWithURL:fileURL role:BDSKTemplateMainPageString];
    
    // a user could potentially have templates for multiple BibTeX types; we could add all of those, as well
    fileURL = [NSURL fileURLWithPath:[templatesPath stringByAppendingPathComponent:@"htmlItemExportTemplate.html"]];
    [template addChildWithURL:fileURL role:BDSKTemplateDefaultItemString];
    
    fileURL = [NSURL fileURLWithPath:[templatesPath stringByAppendingPathComponent:@"htmlExportStyleSheet.css"]];
    [template addChildWithURL:fileURL role:BDSKTemplateAccessoryString];
    
    // RTF template
    template = [[BDSKTemplate alloc] init];
    [template setValue:@"Default RTF template" forKey:BDSKTemplateNameString];
    [template setValue:@"rtf" forKey:BDSKTemplateRoleString];
    [itemNodes addObject:template];
    [template release];
    fileURL = [NSURL fileURLWithPath:[templatesPath stringByAppendingPathComponent:@"rtfExportTemplate.rtf"]];
    [template addChildWithURL:fileURL role:BDSKTemplateMainPageString];
    
    // RTFD template
    template = [[BDSKTemplate alloc] init];
    [template setValue:@"Default RTFD template" forKey:BDSKTemplateNameString];
    [template setValue:@"rtfd" forKey:BDSKTemplateRoleString];
    [itemNodes addObject:template];
    [template release];
    fileURL = [NSURL fileURLWithPath:[templatesPath stringByAppendingPathComponent:@"rtfdExportTemplate.rtfd"]];
    [template addChildWithURL:fileURL role:BDSKTemplateMainPageString];
        
    // RSS template
    template = [[BDSKTemplate alloc] init];
    [template setValue:@"Default RSS template" forKey:BDSKTemplateNameString];
    [template setValue:@"rss" forKey:BDSKTemplateRoleString];
    [itemNodes addObject:template];
    [template release];
    fileURL = [NSURL fileURLWithPath:[templatesPath stringByAppendingPathComponent:@"rssExportTemplate.rss"]];
    [template addChildWithURL:fileURL role:BDSKTemplateMainPageString];    
        
    // Doc template
    template = [[BDSKTemplate alloc] init];
    [template setValue:@"Default Doc template" forKey:BDSKTemplateNameString];
    [template setValue:@"doc" forKey:BDSKTemplateRoleString];
    [itemNodes addObject:template];
    [template release];
    fileURL = [NSURL fileURLWithPath:[templatesPath stringByAppendingPathComponent:@"docExportTemplate.doc"]];
    [template addChildWithURL:fileURL role:BDSKTemplateMainPageString];  
            
    return [itemNodes autorelease];
}

+ (NSArray *)defaultServiceTemplates
{
    NSMutableArray *itemNodes = [[NSMutableArray alloc] initWithCapacity:2];
    NSString *appSupportPath = [[NSFileManager defaultManager] currentApplicationSupportPathForCurrentUser];
    BDSKTemplate *template = nil;
    NSURL *fileURL = nil;
    
    // Citation template
    template = [[BDSKTemplate alloc] init];
    [template setValue:@"Citation Service template" forKey:BDSKTemplateNameString];
    [template setValue:@"txt" forKey:BDSKTemplateRoleString];
    [itemNodes addObject:template];
    [template release];
    fileURL = [NSURL fileURLWithPath:[appSupportPath stringByAppendingPathComponent:@"Templates/citeServiceTemplate.txt"]];
    [template addChildWithURL:fileURL role:BDSKTemplateMainPageString];
    
    // Text template
    template = [[BDSKTemplate alloc] init];
    [template setValue:@"Text Service template" forKey:BDSKTemplateNameString];
    [template setValue:@"txt" forKey:BDSKTemplateRoleString];
    [itemNodes addObject:template];
    [template release];
    fileURL = [NSURL fileURLWithPath:[appSupportPath stringByAppendingPathComponent:@"Templates/textServiceTemplate.txt"]];
    [template addChildWithURL:fileURL role:BDSKTemplateMainPageString];
    
    // RTF template
    template = [[BDSKTemplate alloc] init];
    [template setValue:@"RTF Service template" forKey:BDSKTemplateNameString];
    [template setValue:@"rtf" forKey:BDSKTemplateRoleString];
    [itemNodes addObject:template];
    [template release];
    fileURL = [NSURL fileURLWithPath:[appSupportPath stringByAppendingPathComponent:@"Templates/rtfServiceTemplate.rtf"]];
    [template addChildWithURL:fileURL role:BDSKTemplateMainPageString];
    fileURL = [NSURL fileURLWithPath:[appSupportPath stringByAppendingPathComponent:@"Templates/rtfServiceTemplate default item.rtf"]];
    [template addChildWithURL:fileURL role:BDSKTemplateDefaultItemString];
    fileURL = [NSURL fileURLWithPath:[appSupportPath stringByAppendingPathComponent:@"Templates/rtfServiceTemplate book.rtf"]];
    [template addChildWithURL:fileURL role:BDSKBookString];
            
    return [itemNodes autorelease];
}

+ (NSArray *)exportTemplates{
    NSData *prefData = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKExportTemplateTree];
    if ([prefData length])
        return [NSKeyedUnarchiver unarchiveObjectWithData:prefData];
    else 
        return [BDSKTemplate defaultExportTemplates];
}

+ (NSArray *)serviceTemplates{
    NSData *prefData = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKServiceTemplateTree];
    if ([prefData length])
        return [NSKeyedUnarchiver unarchiveObjectWithData:prefData];
    else 
        return [BDSKTemplate defaultServiceTemplates];
}

+ (NSArray *)allStyleNames;
{
    NSMutableArray *names = [NSMutableArray array];
    NSEnumerator *nodeE = [[self exportTemplates] objectEnumerator];
    id aNode;
    NSString *name;
    while(aNode = [nodeE nextObject]){
        if([aNode isLeaf] == NO && [aNode mainPageTemplateURL] != nil){
            name = [aNode valueForKey:BDSKTemplateNameString];
            if(name != nil)
                [names addObject:name];
        }
    }
    return names;
}

+ (NSArray *)allFileTypes;
{
    NSMutableArray *fileTypes = [NSMutableArray array];
    NSEnumerator *nodeE = [[self exportTemplates] objectEnumerator];
    id aNode;
    NSString *fileType;
    while(aNode = [nodeE nextObject]){
        if([aNode isLeaf] == NO && [aNode mainPageTemplateURL] != nil){
            fileType = [aNode valueForKey:BDSKTemplateRoleString];
            if(fileType != nil)
                [fileTypes addObject:fileType];
        }
    }
    return fileTypes;
}

+ (NSArray *)allStyleNamesForFileType:(NSString *)fileType;
{
    NSMutableArray *names = [NSMutableArray array];
    NSEnumerator *nodeE = [[self exportTemplates] objectEnumerator];
    id aNode;
    NSString *aFileType;
    NSString *name;
    while(aNode = [nodeE nextObject]){
        if([aNode isLeaf] == NO && [aNode mainPageTemplateURL] != nil){
            name = [aNode valueForKey:BDSKTemplateNameString];
            aFileType = [aNode valueForKey:BDSKTemplateRoleString];
            if([aFileType caseInsensitiveCompare:fileType] == NSOrderedSame && name != nil)
                [names addObject:name];
        }
    }
    return names;
}

+ (NSArray *)allStyleNamesForFormat:(BDSKTemplateFormat)format;
{
    NSMutableArray *names = [NSMutableArray array];
    NSEnumerator *nodeE = [[self exportTemplates] objectEnumerator];
    id aNode;
    NSString *name;
    while(aNode = [nodeE nextObject]){
        if([aNode isLeaf] == NO && [aNode mainPageTemplateURL] != nil){
            name = [aNode valueForKey:BDSKTemplateNameString];
            if(name != nil && [aNode templateFormat] & format)
                [names addObject:name];
        }
    }
    return names;
}

+ (NSString *)defaultStyleNameForFileType:(NSString *)fileType;
{
    NSArray *names = [self  allStyleNamesForFileType:fileType];
    if ([names count] > 0)
        return [names objectAtIndex:0];
    else
        return nil;
}

// accesses the node array in prefs
+ (BDSKTemplate *)templateForStyle:(NSString *)styleName;
{
    NSEnumerator *nodeE = [[self exportTemplates] objectEnumerator];
    id aNode = nil;
    
    while(aNode = [nodeE nextObject]){
        if(NO == [aNode isLeaf] && [[aNode valueForKey:BDSKTemplateNameString] isEqualToString:styleName])
            break;
    }
    return aNode;
}

+ (BDSKTemplate *)templateForCiteService;
{
    return [[self serviceTemplates] objectAtIndex:0];
}

+ (BDSKTemplate *)templateForTextService;
{
    return [[self serviceTemplates] objectAtIndex:1];
}

+ (BDSKTemplate *)templateForRTFService;
{
    return [[self serviceTemplates] lastObject];
}

#pragma mark Instance methods

- (BDSKTemplateFormat)templateFormat;
{
    OBASSERT([self isLeaf] == NO);
    NSString *extension = [[self valueForKey:BDSKTemplateRoleString] lowercaseString];
    NSURL *url = [self mainPageTemplateURL];
    BDSKTemplateFormat format = BDSKUnknownTemplateFormat;
    
    if (extension == nil || url == nil) {
        format = BDSKUnknownTemplateFormat;
    } else if ([extension isEqualToString:@"rtf"]) {
        format = BDSKRTFTemplateFormat;
    } else if ([extension isEqualToString:@"rtfd"]) {
        format = BDSKRTFDTemplateFormat;
    } else if ([extension isEqualToString:@"doc"]) {
        format = BDSKDocTemplateFormat;
    } else if ([extension isEqualToString:@"html"] || [extension isEqualToString:@"htm"]) {
        NSString *htmlString = [[[NSString alloc] initWithData:[NSData dataWithContentsOfURL:url] encoding:NSUTF8StringEncoding] autorelease];
        if (htmlString == nil)
            format = BDSKUnknownTemplateFormat;
        else if ([htmlString rangeOfString:@"<$"].location != NSNotFound)
            format = BDSKTextTemplateFormat;
        else
            format = BDSKRichHTMLTemplateFormat;
    } else {
        format = BDSKTextTemplateFormat;
    }
    return format;
}

- (NSString *)fileExtension;
{
    OBASSERT([self isLeaf] == NO);
    return [self valueForKey:BDSKTemplateRoleString];
}

- (NSString *)mainPageString;
{
    OBASSERT([self isLeaf] == NO);
    return [NSString stringWithContentsOfURL:[self mainPageTemplateURL]];
}

- (NSAttributedString *)mainPageAttributedStringWithDocumentAttributes:(NSDictionary **)docAttributes;
{
    OBASSERT([self isLeaf] == NO);
    return [[[NSAttributedString alloc] initWithURL:[self mainPageTemplateURL] documentAttributes:docAttributes] autorelease];
}

- (NSString *)stringForType:(NSString *)type;
{
    OBASSERT([self isLeaf] == NO);
    NSURL *theURL = nil;
    if(nil != type)
        theURL = [self templateURLForType:type];
    // return default template string if no type or no type-specific template
    if(nil == theURL)
        theURL = [self defaultItemTemplateURL];
    if(nil != theURL)
        return [NSString stringWithContentsOfURL:theURL];
    if([type isEqualToString:BDSKTemplateMainPageString] == NO)
        return nil;
    // get the item template from the main page template
    theURL = [self mainPageTemplateURL];
    return itemTemplateSubstring([NSString stringWithContentsOfURL:theURL]);
}

- (NSAttributedString *)attributedStringForType:(NSString *)type;
{
    OBASSERT([self isLeaf] == NO);
    NSURL *theURL = nil;
    if(nil != type)
        theURL = [self templateURLForType:type];
    // return default template string if no type or no type-specific template
    if(nil == theURL)
        theURL = [self defaultItemTemplateURL];
    return [[[NSAttributedString alloc] initWithURL:theURL documentAttributes:NULL] autorelease];
}

- (NSURL *)mainPageTemplateURL;
{
    OBASSERT([self isLeaf] == NO);
    return [self templateURLForType:BDSKTemplateMainPageString];
}

- (NSURL *)defaultItemTemplateURL;
{
    OBASSERT([self isLeaf] == NO);
    return [self templateURLForType:BDSKTemplateDefaultItemString];
}

- (NSURL *)templateURLForType:(NSString *)pubType;
{
    OBASSERT([self isLeaf] == NO);
    NSParameterAssert(nil != pubType);
    return [[self childForRole:pubType] representedFileURL];
}

- (NSArray *)accessoryFileURLs;
{
    OBASSERT([self isLeaf] == NO);
    NSMutableArray *fileURLs = [NSMutableArray array];
    NSEnumerator *childE = [[self children] objectEnumerator];
    BDSKTemplate *aChild;
    NSURL *fileURL;
    while(aChild = [childE nextObject]){
        if([[aChild valueForKey:BDSKTemplateRoleString] isEqualToString:BDSKTemplateAccessoryString]){
            fileURL = [aChild representedFileURL];
            if(fileURL)
                [fileURLs addObject:fileURL];
        }
    }
    return fileURLs;
}

- (BOOL)addChildWithURL:(NSURL *)fileURL role:(NSString *)role;
{
    BOOL retVal;
    retVal = [[NSFileManager defaultManager] objectExistsAtFileURL:fileURL];
    BDSKTemplate *newChild = [[BDSKTemplate alloc] init];
    
    [newChild setValue:fileURL forKey:BDSKTemplateFileURLString];
    [newChild setValue:role forKey:BDSKTemplateRoleString];
    [self addChild:newChild];
    [newChild release];
    if([newChild representedFileURL] == nil)
        retVal = NO;
    return retVal;
}

- (id)childForRole:(NSString *)role;
{
    OBASSERT([self isLeaf] == NO);
    NSParameterAssert(nil != role);
    NSEnumerator *nodeE = [[self children] objectEnumerator];
    id aNode = nil;
    
    // assume roles are unique by grabbing the first one; this works for any case except the accessory files
    while(aNode = [nodeE nextObject]){
        if([[aNode valueForKey:BDSKTemplateRoleString] isEqualToString:role])
            break;
    }
    return aNode;
}

- (void)setRepresentedFileURL:(NSURL *)aURL;
{
    OBASSERT([self isLeaf]);
    BDAlias *alias = nil;
    alias = [[BDAlias alloc] initWithURL:aURL];
    
    if(alias){
        [self setValue:[alias aliasData] forKey:@"_BDAlias"];
        
        [self setValue:[aURL lastPathComponent] forKey:BDSKTemplateNameString];
        
        NSString *extension = [[aURL path] pathExtension];
        if ([NSString isEmptyString:extension] == NO && [[self parent] valueForKey:BDSKTemplateRoleString] == nil) 
            [[self parent] setValue:extension forKey:BDSKTemplateRoleString];
    }
    [alias release];
}

- (NSURL *)representedFileURL;
{
    OBASSERT([self isLeaf]);
    BDAlias *alias = [[BDAlias alloc] initWithData:[self valueForKey:@"_BDAlias"]];
    NSURL *theURL = [alias fileURLNoUI];
    [alias release];
    return theURL;
}

- (NSColor *)representedColorForKey:(NSString *)key;
{
    NSColor *color = [NSColor controlTextColor];
    if([key isEqualToString:BDSKTemplateNameString] && [self isLeaf]){
        if(nil == [self representedFileURL])
            color = [NSColor redColor];
    }else if(nil == [self valueForKey:key]){
        color = [NSColor redColor];
    }
    return color;
}

@end
