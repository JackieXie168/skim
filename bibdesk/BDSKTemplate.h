//
//  BDSKTemplate.h
//  Bibdesk
//
//  Created by Adam Maxwell on 05/23/06.
/*
 This software is Copyright (c) 2006,2007
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

#import <Cocoa/Cocoa.h>
#import "BDSKTreeNode.h"

typedef enum _BDSKTemplateFormat {
    BDSKUnknownTemplateFormat = 0,
    BDSKTextTemplateFormat = 1, // any plain text template
    BDSKRichHTMLTemplateFormat = 2, // HTML template edited as wysiwyg
    BDSKRTFTemplateFormat = 4,
    BDSKRTFDTemplateFormat = 8,
    BDSKDocTemplateFormat = 16,
    BDSKRichTextTemplateFormat = 30 // Rich HTML, RTF, RTFD or Doc
} BDSKTemplateFormat;

extern NSString *BDSKTemplateRoleString;
extern NSString *BDSKTemplateNameString;
extern NSString *BDSKTemplateFileURLString;
extern NSString *BDSKExportTemplateTree;
extern NSString *BDSKServiceTemplateTree;

extern NSString *BDSKTemplateAccessoryString;
extern NSString *BDSKTemplateMainPageString;
extern NSString *BDSKTemplateDefaultItemString;
extern NSString *BDSKTemplateScriptString;

// concrete subclass with specific accessors for the template tree
@interface BDSKTemplate : BDSKTreeNode
{
}

// default templates
+ (NSArray *)defaultExportTemplates;
+ (NSArray *)defaultServiceTemplates;

// all templates
+ (NSArray *)exportTemplates;
+ (NSArray *)serviceTemplates;

// known export style names
+ (NSArray *)allStyleNames;
+ (NSArray *)allFileTypes;
+ (NSArray *)allStyleNamesForFileType:(NSString *)fileType;
+ (NSArray *)allStyleNamesForFormat:(BDSKTemplateFormat)format;
+ (NSString *)defaultStyleNameForFileType:(NSString *)fileType;

// export templates
+ (BDSKTemplate *)templateForStyle:(NSString *)styleName;

// service templates
+ (BDSKTemplate *)templateForCiteService;
+ (BDSKTemplate *)templateForTextService;
+ (BDSKTemplate *)templateForRTFService;

// top-level template accessors

- (BDSKTemplateFormat)templateFormat;
- (NSString *)fileExtension;

- (NSString *)mainPageString;
- (NSAttributedString *)mainPageAttributedStringWithDocumentAttributes:(NSDictionary **)docAttributes;
- (NSString *)scriptPath;

// returns the contents of a child for the given type or of the default template
// (pass nil for the type if you explicitly desire the default template content)
// encoding should be either Unicode, UTF-8, or defaultCStringEncoding
- (NSString *)stringForType:(NSString *)type;
- (NSAttributedString *)attributedStringForType:(NSString *)type;

- (NSURL *)mainPageTemplateURL;
- (NSURL *)defaultItemTemplateURL;
- (NSURL *)templateURLForType:(NSString *)pubType;
- (NSArray *)accessoryFileURLs;
- (NSURL *)scriptURL;

// child template accessors
- (NSURL *)representedFileURL;
- (void)setRepresentedFileURL:(NSURL *)aURL;

// other methods
- (BOOL)addChildWithURL:(NSURL *)fileURL role:(NSString *)role;
- (id)childForRole:(NSString *)role;
- (NSColor *)representedColorForKey:(NSString *)key;

@end


