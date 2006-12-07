// Copyright 2003-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/XML/OFXMLString.h 79079 2006-09-07 22:35:32Z kc $

#import <Foundation/NSObject.h>

#import <CoreFoundation/CFString.h>
#import <CoreFoundation/CFXMLParser.h>
#import <OmniFoundation/OFXMLWhitespaceBehavior.h>

@class NSMutableString;
@class OFXMLElement, OFXMLDocument;

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


// &apos; is part of XML, which was created after HTML, so HTML 4 doesn't have that entity.
// Each of ' and " has three options; XML entity, character entity or unquoed.
#define OFXMLAposCharacterOptionsShift (8)
#define OFXMLQuotCharacterOptionsShift (16)
#define OFXMLCharacterOptionsMask      (0xff)

#define OFXMLCharacterFlagWriteNamedEntity       (0x00)
#define OFXMLCharacterFlagWriteCharacterEntity   (0x01)
#define OFXMLCharacterFlagWriteUnquotedCharacter (0x02)

#define OFXMLMinimalEntityMask  (0x00) // &lt; and &amp;
#define OFXMLGtEntityMask       (0x01) // &gt;
#define OFXMLNewlineEntityMask  (0x02) // write the optional newline string instead of the newline itself

#define OFXMLAposEntityMask     (OFXMLCharacterFlagWriteNamedEntity << OFXMLAposCharacterOptionsShift) // default to writing &apos;
#define OFXMLQuotEntityMask     (OFXMLCharacterFlagWriteNamedEntity << OFXMLQuotCharacterOptionsShift) // default to writing &quot;

#define OFXMLBasicEntityMask (OFXMLGtEntityMask|OFXMLAposEntityMask|OFXMLQuotEntityMask)
#define OFXMLBasicWithNewlinesEntityMask (OFXMLBasicEntityMask|OFXMLNewlineEntityMask)

// &apos; is part of XML, which was created after HTML, so HTML 4 doesn't have that entity.
// TODO (2002-09-24): When do we need to quote '?
#define OFXMLHTMLEntityMask (OFXMLGtEntityMask|OFXMLQuotEntityMask|(OFXMLCharacterFlagWriteCharacterEntity << OFXMLAposCharacterOptionsShift))
#define OFXMLHTMLWithNewlinesEntityMask (OFXMLHTMLEntityMask|OFXMLNewlineEntityMask)

extern NSString *OFXMLCreateStringWithEntityReferencesInCFEncoding(NSString *sourceString, unsigned int entityMask, NSString *optionalNewlineString, CFStringEncoding anEncoding);
extern NSString *OFXMLCreateParsedEntityString(NSString *sourceString);
extern NSString *OFStringForEntityName(NSString *entityName);

extern NSString *OFCharacterDataFromXMLTree(CFXMLTreeRef aTree);
extern NSString *OFCharacterDataFromElement(OFXMLElement *element);
