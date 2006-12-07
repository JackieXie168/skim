// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFXMLDocument.h>
#import <OmniFoundation/OFXMLElement.h>
#import <OmniFoundation/OFXMLWhitespaceBehavior.h>
#import <OmniFoundation/NSObject-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>
#import <SenTestingKit/SenTestingKit.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/Tests/OFXMLDocumentTests.m,v 1.15 2004/02/10 04:07:48 kc Exp $");

static NSString *DTDName = @"root-element";
static CFURLRef dtdURL = NULL;

static inline BOOL _SAVE(Class cls, SEL sel, OFXMLDocument *doc)
{
    NSString *fileName = [[NSString alloc] initWithFormat: @"/tmp/%@-%@.xml", NSStringFromClass(cls), NSStringFromSelector(sel)];
    BOOL res = [doc writeToFile: fileName];
    [fileName release];
    return res;
}

#define SAVE _SAVE(isa, _cmd, doc)

@interface OFXMLDocumentTests : SenTestCase
{
}

@end

@implementation OFXMLDocumentTests

+ (void) initialize;
{
    [super initialize];
    if (dtdURL)
        return;

    dtdURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)[DTDName stringByAppendingPathExtension: @"dtd"], kCFURLPOSIXPathStyle, false);
}

- (void) testWriteEmptyDocument;
{
    OFXMLDocument *doc;
    OFXMLWhitespaceBehavior *whitespace;

    whitespace = [[OFXMLWhitespaceBehavior alloc] init];
    [whitespace setBehavior: OFXMLWhitespaceBehaviorTypeIgnore forElementName: DTDName];
    
    doc = [[OFXMLDocument alloc] initWithRootElementName: DTDName
                                             dtdSystemID: dtdURL
                                             dtdPublicID: @"-//omnigroup.com//XML Document Test//EN"
                                      whitespaceBehavior: whitespace
                                          stringEncoding: kCFStringEncodingUTF8];
    [whitespace release];
    
    should(SAVE);
    [doc release];
}

- (void) testWriteDocumentWithOneChild;
{
    OFXMLDocument *doc;
    OFXMLWhitespaceBehavior *whitespace;

    whitespace = [[OFXMLWhitespaceBehavior alloc] init];
    [whitespace setBehavior: OFXMLWhitespaceBehaviorTypeIgnore forElementName: DTDName];

    doc = [[OFXMLDocument alloc] initWithRootElementName: DTDName
                                             dtdSystemID: dtdURL
                                             dtdPublicID: @"-//omnigroup.com//XML Document Test//EN"
                                      whitespaceBehavior: whitespace
                                          stringEncoding: kCFStringEncodingUTF8];
    [whitespace release];

    [doc pushElement: @"child"];
    {
        [doc setAttribute: @"name" value: @"value"];
        [doc pushElement: @"grandchild"];
        {
            [doc setAttribute: @"name2" value: @"value2"];
        }
        [doc popElement];
    }
    [doc popElement];

    should(SAVE);
    [doc release];
}

- (void) testWriteSpacePreservation;
{
    OFXMLDocument *doc;
    OFXMLWhitespaceBehavior *whitespace;

    whitespace = [[OFXMLWhitespaceBehavior alloc] init];
    [whitespace setBehavior: OFXMLWhitespaceBehaviorTypeIgnore forElementName: DTDName];
    [whitespace setBehavior: OFXMLWhitespaceBehaviorTypePreserve forElementName: @"p"];

    doc = [[OFXMLDocument alloc] initWithRootElementName: DTDName
                                             dtdSystemID: dtdURL
                                             dtdPublicID: @"-//omnigroup.com//XML Document Test//EN"
                                      whitespaceBehavior: whitespace
                                          stringEncoding: kCFStringEncodingUTF8];
    [whitespace release];

    [doc pushElement: @"child"];
    {
        [doc setAttribute: @"name" value: @"value"];
        [doc pushElement: @"p"];
        {
            [doc appendString: @"some text "];
            [doc pushElement: @"b"];
            {
                [doc appendString: @"bold"];
            }
            [doc popElement];
        }
        [doc popElement];
    }
    [doc popElement];

    should(SAVE);
    [doc release];
}

- (void) testReadingFile;
{
    NSString *inputFile;
    OFXMLDocument *doc;

    inputFile = [[self bundle] pathForResource:@"0000-CreateDocument" ofType:@"xmloutline"];
    should(inputFile != nil);

    // Just preserve whitespace exactly was we find it.
    doc = [[OFXMLDocument alloc] initWithContentsOfFile: inputFile whitespaceBehavior: nil];
    should(doc);
    should(SAVE);
    [doc release];
}

- (void) testEntityWriting;
{
    OFXMLDocument *doc;
    NSString *stringElementName = @"s";

    doc = [[OFXMLDocument alloc] initWithRootElementName: DTDName
                                             dtdSystemID: dtdURL
                                             dtdPublicID: @"-//omnigroup.com//XML Document Test//EN"
                                      whitespaceBehavior: nil
                                          stringEncoding: kCFStringEncodingUTF8];

    // Test writing various entities as CDATA and attributes.
#define ATTR(s) [doc pushElement: stringElementName]; { [doc setAttribute:@"attr" string:s]; [doc appendString:s]; } [doc popElement];
    ATTR(@"&");
    ATTR(@"&amp;");
    ATTR(@"<");
    ATTR(@"&lt;");
    ATTR(@">");
    ATTR(@"&gt;");
    ATTR(@"'");
    ATTR(@"&apos;");
    ATTR(@"\"");
    ATTR(@"&quot;");
    ATTR(@"a&b");
    ATTR(@"a & b");
#undef ATTR
    
    NSString *resultString;
    resultString = [[[NSString alloc] initWithData:[doc xmlDataAsFragment] encoding: [doc stringEncoding]] autorelease];

    NSString *expectedOutput =
        @"<root-element>"
        @"<s attr=\"&amp;\">&amp;</s>"
        @"<s attr=\"&amp;amp;\">&amp;amp;</s>"
        @"<s attr=\"&lt;\">&lt;</s>"
        @"<s attr=\"&amp;lt;\">&amp;lt;</s>"
        @"<s attr=\"&gt;\">&gt;</s>"
        @"<s attr=\"&amp;gt;\">&amp;gt;</s>"
        @"<s attr=\"&apos;\">&apos;</s>"
        @"<s attr=\"&amp;apos;\">&amp;apos;</s>"
        @"<s attr=\"&quot;\">&quot;</s>"
        @"<s attr=\"&amp;quot;\">&amp;quot;</s>"
        @"<s attr=\"a&amp;b\">a&amp;b</s>"
        @"<s attr=\"a &amp; b\">a &amp; b</s>"
        @"</root-element>";
    shouldBeEqual(resultString, expectedOutput);
}

- (void) testEntityReading;
{
    NSString *sourceString;

    sourceString =
        @"<root-element>"
        @"<s attr=\"&amp;\">&amp;</s>"
        @"<s attr=\"&amp;amp;\">&amp;amp;</s>"
        @"<s attr=\"&lt;\">&lt;</s>"
        @"<s attr=\"&amp;lt;\">&amp;lt;</s>"
        @"<s attr=\"&gt;\">&gt;</s>"
        @"<s attr=\"&amp;gt;\">&amp;gt;</s>"
        @"<s attr=\"&apos;\">&apos;</s>"
        @"<s attr=\"&amp;apos;\">&amp;apos;</s>"
        @"<s attr=\"&quot;\">&quot;</s>"
        @"<s attr=\"&amp;quot;\">&amp;quot;</s>"
        @"<s attr=\"&#35;\">&#35;</s>"
        @"<s attr=\"&#x35;\">&#x35;</s>"
        @"<s attr=\"a&amp;b\">a&amp;b</s>"
        @"<s attr=\"a &amp; b\">a &amp; b</s>"
        @"</root-element>";
    NSData *xmlData;

    xmlData = [sourceString dataUsingEncoding: NSUTF8StringEncoding];
    OFXMLDocument *doc = [[OFXMLDocument alloc] initWithData:xmlData whitespaceBehavior:nil];

    NSArray *elements = [[doc rootElement] children];

#define CHECK(i, s) shouldBeEqual([[elements objectAtIndex:i] childAtIndex:0], s); shouldBeEqual([[elements objectAtIndex:i] attributeNamed:@"attr"], s)
    CHECK( 0, @"&");
    CHECK( 1, @"&amp;");
    CHECK( 2, @"<");
    CHECK( 3, @"&lt;");
    CHECK( 4, @">");
    CHECK( 5, @"&gt;");
    CHECK( 6, @"'");
    CHECK( 7, @"&apos;");
    CHECK( 8, @"\"");
    CHECK( 9, @"&quot;");
    CHECK(10, @"#");
    CHECK(11, @"5");
    CHECK(12, @"a&b");
    CHECK(13, @"a & b");
#undef CHECK
}

// Copied from OO3
static OFXMLWhitespaceBehavior *_OOXMLWhitespaceBehavior(void)
{
    static OFXMLWhitespaceBehavior *whitespace = nil;

    if (!whitespace) {
        whitespace = [[OFXMLWhitespaceBehavior alloc] init];
        [whitespace setBehavior: OFXMLWhitespaceBehaviorTypeIgnore forElementName: @"outline"];

        // Anything that contains rich text in OO needs to consider whitespace important when writing XML (i.e., don't pretty-print the tree structure)
        [whitespace setBehavior: OFXMLWhitespaceBehaviorTypePreserve forElementName: @"rich-text"];
        //[whitespace setBehavior: OFXMLWhitespaceBehaviorTypePreserve forElementName: @"note"]; // These can directly contain rich text data w/o a 'rich-text' wrapper right now.  Probably a bug.
        [whitespace setBehavior: OFXMLWhitespaceBehaviorTypePreserve forElementName: @"header"];
        [whitespace setBehavior: OFXMLWhitespaceBehaviorTypePreserve forElementName: @"footer"];
    }
    return whitespace;
}

- (void) testReadingFileWithWhitespaceHandling;
{
    NSString *inputFile;
    OFXMLDocument *doc;

    inputFile = [[self bundle] pathForResource:@"0000-CreateDocument" ofType:@"xmloutline"];
    should(inputFile != nil);
    
    // Use the same whitespace handling rules as OO3 itself.  This should still produce identical output, but the intermediate document object should have whitespace stripped where it would be ignored anyway.
    doc = [[OFXMLDocument alloc] initWithContentsOfFile: inputFile
                                     whitespaceBehavior: _OOXMLWhitespaceBehavior()];
    should(doc);
    should(SAVE);
    [doc release];
}

@end
