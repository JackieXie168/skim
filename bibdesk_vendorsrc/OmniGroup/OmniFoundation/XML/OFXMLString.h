// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniFoundation/XML/OFXMLString.h 66043 2005-07-25 21:17:05Z kc $

#import <Foundation/NSObject.h>

#import <CoreFoundation/CFString.h>
#import <CoreFoundation/CFXMLParser.h>
#import <OmniFoundation/OFXMLWhitespaceBehavior.h>

@class NSMutableString;
@class OFXMLDocument;

/*
 This class gives you more control over how the XML string will be encoded than if you just append a NSString to the OFXMLDocument.  Much of this code was inherited from OmniOutliner.
 */

@interface OFXMLString : NSObject
{
    NSString      *_unquotedString;
    unsigned int   _quotingMask;
    NSString      *_newlineReplacement;
}

- initWithString: (NSString *) unquotedString quotingMask: (unsigned int) quotingMask newlineReplacment: (NSString *) newlineReplacment;

- (NSString *) unquotedString;

// Writing support called from OFXMLDocument
- (void)appendXML:(struct _OFXMLBuffer *)xml withParentWhiteSpaceBehavior: (OFXMLWhitespaceBehaviorType) parentBehavior document: (OFXMLDocument *) doc level: (unsigned int) level;

@end


#define OFXMLMinimalEntityMask  (0x00) // &lt; and &amp;
#define OFXMLGtEntityMask       (0x01) // &gt;
#define OFXMLAposEntityMask     (0x02) // &apos;
#define OFXMLQuotEntityMask     (0x04) // &quot;
#define OFXMLNewlineEntityMask  (0x10) // something special for newlines
#define OFXMLAposAlternateEntityMask (0x20) // &12345; // HTML doesn't have &apos;

#define OFXMLBasicEntityMask (OFXMLGtEntityMask|OFXMLAposEntityMask|OFXMLQuotEntityMask)
#define OFXMLBasicWithNewlinesEntityMask (OFXMLBasicEntityMask|OFXMLNewlineEntityMask)

// &apos; is part of XML, which was created after HTML, so HTML 4 doesn't have that entity.
// TODO (2002-09-24): When do we need to quote '?
#define OFXMLHTMLEntityMask (OFXMLGtEntityMask|OFXMLQuotEntityMask|OFXMLAposAlternateEntityMask)
#define OFXMLHTMLWithNewlinesEntityMask (OFXMLHTMLEntityMask|OFXMLNewlineEntityMask)

extern NSString *OFXMLCreateStringWithEntityReferencesInCFEncoding(NSString *sourceString, unsigned int entityMask, NSString *optionalNewlineString, CFStringEncoding anEncoding);
extern NSString *OFXMLCreateParsedEntityString(NSString *sourceString);
extern NSString *OFStringForEntityName(NSString *entityName);

