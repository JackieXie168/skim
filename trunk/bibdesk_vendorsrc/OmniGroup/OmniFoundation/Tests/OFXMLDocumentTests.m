// Copyright 2003-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFStringDecoder.h>
#import <OmniFoundation/OFXMLDocument.h>
#import <OmniFoundation/OFXMLElement.h>
#import <OmniFoundation/OFXMLWhitespaceBehavior.h>
#import <OmniFoundation/NSData-OFExtensions.h>
#import <OmniFoundation/NSObject-OFExtensions.h>
#import <OmniFoundation/NSString-OFExtensions.h>

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>
#define STEnableDeprecatedAssertionMacros
#import <SenTestingKit/SenTestingKit.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/Tests/OFXMLDocumentTests.m 79087 2006-09-07 23:37:02Z kc $");

static NSString *DTDName = @"root-element";
static CFURLRef dtdURL = NULL;

#define SAVE_AND_COMPARE(expectedString) \
do { \
    NSString *fileName = [[NSString alloc] initWithFormat: @"/tmp/%@-%@.xml", NSStringFromClass(isa), NSStringFromSelector(_cmd)]; \
    BOOL res = [doc writeToFile: fileName]; \
    should(res); \
    \
    NSData *data = [[NSData alloc] initWithContentsOfFile:fileName]; \
    [fileName release]; \
    should(data != nil); \
    \
    NSString *string = (NSString *)CFStringCreateFromExternalRepresentation(kCFAllocatorDefault, (CFDataRef)data, [doc stringEncoding]); \
    [data release]; \
    \
    STAssertEqualObjects(string, expectedString, @"SAVE_AND_COMPARE"); \
    [string release]; \
} while (0)

@interface OFXMLDocumentTests : SenTestCase
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

    SAVE_AND_COMPARE(@"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\"?>\n"
                     @"<!DOCTYPE root-element PUBLIC \"-//omnigroup.com//XML Document Test//EN\" \"root-element.dtd\">\n"
                     @"<root-element/>\n");
    
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

    SAVE_AND_COMPARE(@"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\"?>\n"
                     @"<!DOCTYPE root-element PUBLIC \"-//omnigroup.com//XML Document Test//EN\" \"root-element.dtd\">\n"
                     @"<root-element>\n"
                     @"  <child name=\"value\">\n"
                     @"    <grandchild name2=\"value2\"/>\n"
                     @"  </child>\n"
                     @"</root-element>\n");

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

    SAVE_AND_COMPARE(@"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\"?>\n"
                     @"<!DOCTYPE root-element PUBLIC \"-//omnigroup.com//XML Document Test//EN\" \"root-element.dtd\">\n"
                     @"<root-element>\n"
                     @"  <child name=\"value\">\n"
                     @"    <p>some text <b>bold</b></p>\n"
                     @"  </child>\n"
                     @"</root-element>\n");
    
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
    should(doc != nil);

    NSData *expectedData = [[NSData alloc] initWithContentsOfFile:inputFile];
    NSString *expectedString = (NSString *)CFStringCreateFromExternalRepresentation(kCFAllocatorDefault, (CFDataRef)expectedData, [doc stringEncoding]);
    [expectedData release];
    
    should(expectedString != nil);
    [expectedString release];
    [doc release];
}

- (void) testEntityWriting_ASCII;
{
    OFXMLDocument *doc;
    NSString *stringElementName = @"s";

    doc = [[OFXMLDocument alloc] initWithRootElementName: DTDName
                                             dtdSystemID: dtdURL
                                             dtdPublicID: @"-//omnigroup.com//XML Document Test//EN"
                                      whitespaceBehavior: nil
                                          stringEncoding: kCFStringEncodingASCII];

    NSString *supplementalChararacter1 = [NSString stringWithCharacter:0x12345];
    NSString *supplementalChararacter2 = [NSString stringWithCharacter:0xFEDCB];

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
    ATTR(supplementalChararacter1);
    ATTR(supplementalChararacter2);
    ATTR(@"a&b");
    ATTR(@"a & b");
#undef ATTR

    NSData *xmlData = [doc xmlDataAsFragment];
    NSString *resultString;
    resultString = [(NSString *)CFStringCreateFromExternalRepresentation(kCFAllocatorDefault, (CFDataRef)xmlData, [doc stringEncoding]) autorelease];

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
        @"<s attr=\"&#74565;\">&#74565;</s>"
        @"<s attr=\"&#1043915;\">&#1043915;</s>"
        @"<s attr=\"a&amp;b\">a&amp;b</s>"
        @"<s attr=\"a &amp; b\">a &amp; b</s>"
        @"</root-element>";
    shouldBeEqual(resultString, expectedOutput);
}

- (void) testEntityWriting_UTF8;
{
    OFXMLDocument *doc;
    NSString *stringElementName = @"s";

    doc = [[OFXMLDocument alloc] initWithRootElementName: DTDName
                                             dtdSystemID: dtdURL
                                             dtdPublicID: @"-//omnigroup.com//XML Document Test//EN"
                                      whitespaceBehavior: nil
                                          stringEncoding: kCFStringEncodingUTF8];

    NSString *supplementalChararacter1 = [NSString stringWithCharacter:0x12345];
    NSString *supplementalChararacter2 = [NSString stringWithCharacter:0xFEDCB];
#define SUPP1_UTF8_LEN 4
    const char supplementalCharacter1UTF8[SUPP1_UTF8_LEN] = { 0xF0, 0x92, 0x8D, 0x85 };
#define SUPP2_UTF8_LEN 4
    const char supplementalCharacter2UTF8[SUPP2_UTF8_LEN] = { 0xF3, 0xBE, 0xB7, 0x8B };

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
    ATTR(supplementalChararacter1);
    ATTR(supplementalChararacter2);
    ATTR(@"a&b");
    ATTR(@"a & b");
#undef ATTR

    NSData *xmlData = [doc xmlDataAsFragment];

    NSString *expectedOutputFormat =
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
        @"<s attr=\"%@\">%@</s>"
        @"<s attr=\"%@\">%@</s>"
        @"<s attr=\"a&amp;b\">a&amp;b</s>"
        @"<s attr=\"a &amp; b\">a &amp; b</s>"
        @"</root-element>";
        
    // Test that the result, as data, is what we expect it to be (this ensures that we're getting the correct UTF8 byte sequence for the supplementary characters)
    NSMutableData *expectedData = [[[expectedOutputFormat dataUsingEncoding:NSASCIIStringEncoding] mutableCopy] autorelease];
    NSData *patternData = [@"%@" dataUsingEncoding:NSASCIIStringEncoding];
    [expectedData replaceBytesInRange:[expectedData rangeOfData:patternData] withBytes:supplementalCharacter1UTF8 length:SUPP1_UTF8_LEN];
    [expectedData replaceBytesInRange:[expectedData rangeOfData:patternData] withBytes:supplementalCharacter1UTF8 length:SUPP1_UTF8_LEN];
    [expectedData replaceBytesInRange:[expectedData rangeOfData:patternData] withBytes:supplementalCharacter2UTF8 length:SUPP2_UTF8_LEN];
    [expectedData replaceBytesInRange:[expectedData rangeOfData:patternData] withBytes:supplementalCharacter2UTF8 length:SUPP2_UTF8_LEN];
    shouldBeEqual(xmlData, expectedData);
    
    
    // Test that the result, converted to a string, is the same as we think it should be
    NSString *resultString, *expectedResultString;
    resultString = [(NSString *)CFStringCreateFromExternalRepresentation(kCFAllocatorDefault, (CFDataRef)xmlData, [doc stringEncoding]) autorelease];
    expectedResultString = [NSString stringWithFormat:expectedOutputFormat,
        supplementalChararacter1, supplementalChararacter1,
        supplementalChararacter2, supplementalChararacter2];
    shouldBeEqual(resultString, expectedResultString);
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
        @"<s attr=\"&#65536;\">&#65536;</s>"
        @"<s attr=\"&#x10000;\">&#x10000;</s>"
        @"<s attr=\"a&amp;b\">a&amp;b</s>"
        @"<s attr=\"a &amp; b\">a &amp; b</s>"
        @"</root-element>";
    NSData *xmlData;

    xmlData = [sourceString dataUsingEncoding: NSUTF8StringEncoding];
    OFXMLDocument *doc = [[OFXMLDocument alloc] initWithData:xmlData whitespaceBehavior:nil];

    NSArray *elements = [[doc rootElement] children];

    NSString *composedSequence = [NSString stringWithCharacter:0x10000];
    //NSLog(@"composedSequence = %@", composedSequence);
    
#define CHECK(i, s) STAssertEqualObjects([[elements objectAtIndex:i] childAtIndex:0], s, @"child node"); STAssertEqualObjects([[elements objectAtIndex:i] attributeNamed:@"attr"], s, @"attribute value")
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
    CHECK(12, composedSequence);
    CHECK(13, composedSequence);
    CHECK(14, @"a&b");
    CHECK(15, @"a & b");
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
    should(doc != nil);
    
    NSData *inputData = [[NSData alloc] initWithContentsOfFile:inputFile];
    NSString *inputString = (NSString *)CFStringCreateFromExternalRepresentation(kCFAllocatorDefault, (CFDataRef)inputData, [doc stringEncoding]);
    [inputData release];

    SAVE_AND_COMPARE(inputString);
    [inputString release];

    [doc release];
}

@end
