// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFXMLDocument.h>

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniBase/rcsid.h>

#import <CoreFoundation/CFXMLParser.h>
#import <OmniFoundation/OFXMLCursor.h>
#import <OmniFoundation/OFXMLElement.h>
#import <OmniFoundation/OFXMLString.h>
#import <OmniFoundation/CFArray-OFExtensions.h>
#import <OmniFoundation/CFDictionary-OFExtensions.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/XML/OFXMLDocument.m,v 1.31 2004/02/10 04:07:49 kc Exp $");


static void *createXMLStructure(CFXMLParserRef parser, CFXMLNodeRef nodeDesc, void *_info);
static void addChild(CFXMLParserRef parser, void *parent, void *child, void *_info);
static void endXMLStructure(CFXMLParserRef parser, void *xmlType, void *_info);
static CFDataRef resolveExternalEntity(CFXMLParserRef parser, CFXMLExternalID *extID, void *_info);
static Boolean handleError(CFXMLParserRef parser, CFXMLParserStatusCode error, void *_info);

static NSDictionary *entityReplacements; // amp -> &, etc.

typedef struct _OFMLDocumentParseState {
    OFXMLDocument  *doc;
    NSMutableArray *whitespaceBehaviorStack;
    BOOL            rootElementFinished;
} OFMLDocumentParseState;

static void _OFMLDocumentParseStateRelease(const void *info)
{
    OFMLDocumentParseState *state = (OFMLDocumentParseState *)info;
    [state->whitespaceBehaviorStack release];
}

@interface OFXMLDocument (PrivateAPI)
- (void) _preInit;
- (void) _postInit;
@end

@implementation OFXMLDocument (PrivateAPI)
- (void) _preInit;
{
    [self clearIdentifiers];
    _elementStack = [[NSMutableArray alloc] init];
    _processingInstructions = [[NSMutableArray alloc] init];
}

- (void) _postInit;
{
    if (!_rootElement) {
        [self release];
        [NSException raise: NSInvalidArgumentException format: @"No root element was found"];
    }

    OBASSERT([_elementStack count] == 1);
    OBASSERT([_elementStack objectAtIndex: 0] == _rootElement);
}
@end

@implementation OFXMLDocument

+ (void) initialize;
{
    OBINITIALIZE;

    entityReplacements = [[NSDictionary alloc] initWithObjectsAndKeys:
        @"&", @"amp",
        @"<", @"lt",
        @">", @"gt",
        @"'", @"apos",
        @"\"", @"quot",
        nil];
}

- initWithRootElementName: (NSString *) rootElementName
              dtdSystemID: (CFURLRef) dtdSystemID
              dtdPublicID: (NSString *) dtdPublicID
       whitespaceBehavior: (OFXMLWhitespaceBehavior *) whitespaceBehavior
           stringEncoding: (CFStringEncoding) stringEncoding;
{
    [self _preInit];

    NSString *encodingName = (NSString *)CFStringConvertEncodingToIANACharSetName(stringEncoding);
    if (!encodingName) {
        [self release];
        [NSException raise:NSInvalidArgumentException format:@"Unable to determine the IANA character set name for the CFStringEncoding %d", stringEncoding];
    }

    // Convert the encoding name to lowercase for compatibility with an older version of OFXMLDocument (regression tests...)
    NSString *xmlPI = [NSString stringWithFormat:@"version=\"1.0\" encoding=\"%@\" standalone=\"no\"", [encodingName lowercaseString]];
    [self addProcessingInstructionNamed:@"xml" value:xmlPI];

    if (dtdSystemID)
        _dtdSystemID = CFRetain(dtdSystemID);
    _dtdPublicID = [dtdPublicID copy];
    
    _stringEncoding = stringEncoding;
    _rootElement = [[OFXMLElement alloc] initWithName: rootElementName];
    _whitespaceBehavior = [whitespaceBehavior retain];

    [_elementStack addObject: _rootElement];
    
    [self _postInit];
    
    return self;
}

- initWithContentsOfFile: (NSString *) path whitespaceBehavior: (OFXMLWhitespaceBehavior *) whitespaceBehavior;
{
    return [self initWithData: [NSData dataWithContentsOfFile: path] whitespaceBehavior: whitespaceBehavior];
}

- initWithData:(NSData *)xmlData whitespaceBehavior:(OFXMLWhitespaceBehavior *)whitespaceBehavior;
{
    if (!xmlData)
        // CFXMLParser will crash if we feed it nil.
        [NSException raise:NSInvalidArgumentException format:@"Attempted to create a OFXMLDocument from a nil XML data."];
    
    [self _preInit];

    _whitespaceBehavior = [whitespaceBehavior retain];

    // TODO: Add support for passing along the source URL
    // We want whitespace reported since we may or may not keep it depending on our whitespaceBehavior input.

    CFXMLParserCallBacks callbacks;
    memset(&callbacks, 0, sizeof(callbacks));
    callbacks.createXMLStructure    = createXMLStructure;
    callbacks.addChild              = addChild;
    callbacks.endXMLStructure       = endXMLStructure;
    callbacks.resolveExternalEntity = resolveExternalEntity;
    callbacks.handleError           = handleError;

    OFMLDocumentParseState state;
    memset(&state, 0, sizeof(state));
    state.doc                     = self;
    state.whitespaceBehaviorStack = OFCreateIntegerArray();
    state.rootElementFinished     = NO;

    // Preserve whitespace by default
    [state.whitespaceBehaviorStack addObject: (id)OFXMLWhitespaceBehaviorTypePreserve];

    CFXMLParserContext context;
    memset(&context, 0, sizeof(context));
    context.info    = &state;
    context.release = _OFMLDocumentParseStateRelease;
    
    CFXMLParserRef parser = CFXMLParserCreate(kCFAllocatorDefault, (CFDataRef)xmlData, NULL, kCFXMLParserNoOptions, kCFXMLNodeCurrentVersion, &callbacks, &context);
    if (!parser) {
        [self release];
        [NSException raise: NSInvalidArgumentException format: @"Unable to create XML parser"];
    }
    if (!CFXMLParserParse(parser)) {
        NSString              *error;
        CFXMLParserStatusCode  status;
        CFIndex                location, line;
        
        error = [(NSString *)CFXMLParserCopyErrorDescription(parser) autorelease];
        status = CFXMLParserGetStatusCode(parser);
        location = CFXMLParserGetLocation(parser);
        line = CFXMLParserGetLineNumber(parser);
        CFRelease(parser);
        [self release];
        [NSException raise: NSInvalidArgumentException format: @"Unable to parse XML (status=%d, index=%d, line=%d, error=%@)", status, location, line, error];
    }

    OBASSERT(_rootElement);
    OBASSERT(state.rootElementFinished);
    OBASSERT([state.whitespaceBehaviorStack count] == 2); // The default and the one for the root element
    CFRelease(parser);

    [self _postInit];
    return self;
}

- (void) dealloc;
{
    [_processingInstructions release];
    if (_dtdSystemID)
        CFRelease(_dtdSystemID);
    [_dtdPublicID release];
    [_idToObject release];
    [_objectToID release];
    [_rootElement release];
    [_elementStack release];
    [_whitespaceBehavior release];
    [_userObjects release];
    [super dealloc];
}

- (OFXMLWhitespaceBehavior *) whitespaceBehavior;
{
    return _whitespaceBehavior;
}

- (CFURLRef) dtdSystemID;
{
    return _dtdSystemID;
}

- (NSString *) dtdPublicID;
{
    return _dtdPublicID;
}

- (CFStringEncoding) stringEncoding;
{
    return _stringEncoding;
}

- (NSData *) xmlData;
{
    return [self xmlDataForElements: [NSArray arrayWithObjects: _rootElement, nil] asFragment: NO];
}

- (NSData *) xmlDataAsFragment;
{
    return [self xmlDataForElements: [NSArray arrayWithObjects: _rootElement, nil] asFragment: YES];
}

- (NSData *) xmlDataForElements: (NSArray *) elements asFragment: (BOOL) asFragment;
{
    OBPRECONDITION(asFragment || (_dtdSystemID && _dtdPublicID)); // Otherwise CFXMLParser will generate an error on load (which we'll ignore, but still...)
    OBPRECONDITION([_elementStack count] == 1); // should just have the root element -- i.e., all nested push/pops have finished
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    CFXMLTreeRef child, docTree;
    CFXMLNodeRef node;

    // Create document
    {
        CFXMLDocumentInfo docInfo;
        memset(&docInfo, 0, sizeof(docInfo));
        docInfo.encoding = _stringEncoding;
        node = CFXMLNodeCreate(kCFAllocatorDefault, kCFXMLNodeTypeDocument, NULL, &docInfo, kCFXMLNodeCurrentVersion);
        docTree = CFXMLTreeCreateWithNode(kCFAllocatorDefault, node);
        CFRelease(node);
    }

    if (!asFragment) {
        // Add processing instructions
        {
            unsigned int piIndex, piCount;

            piCount = [_processingInstructions count];
            for (piIndex = 0; piIndex < piCount; piIndex++) {
                NSArray *pi = [_processingInstructions objectAtIndex:piIndex];

                CFXMLProcessingInstructionInfo procInstr;
                memset(&procInstr, 0, sizeof(procInstr));
                procInstr.dataString = (CFStringRef)[pi objectAtIndex:1];
                node = CFXMLNodeCreate(kCFAllocatorDefault, kCFXMLNodeTypeProcessingInstruction, (CFStringRef)[pi objectAtIndex:0], &procInstr, kCFXMLNodeCurrentVersion);
                child = CFXMLTreeCreateWithNode(kCFAllocatorDefault, node);
                CFTreeAppendChild(docTree, child);
                CFRelease(child);
                CFRelease(node);
            }
        }

        // Newline
        {
            child = [OFXMLElement createNewlineTree];
            CFTreeAppendChild(docTree, child);
            CFRelease(child);
        }

        // Add doctype specification
        {
            CFXMLDocumentTypeInfo dtd;
            memset(&dtd, 0, sizeof(dtd));
            dtd.externalID.systemID = _dtdSystemID;
            dtd.externalID.publicID = (CFStringRef)_dtdPublicID;
            node = CFXMLNodeCreate(kCFAllocatorDefault, kCFXMLNodeTypeDocumentType, (CFStringRef)[_rootElement name], &dtd, kCFXMLNodeCurrentVersion);
            child = CFXMLTreeCreateWithNode(kCFAllocatorDefault, node);
            CFTreeAppendChild(docTree, child);
            CFRelease(child);
            CFRelease(node);
        }

        // Newline
        {
            child = [OFXMLElement createNewlineTree];
            CFTreeAppendChild(docTree, child);
            CFRelease(child);
        }
    }
    
    // Add elements
    unsigned int elementIndex, elementCount;
    elementCount = [elements count];
    for (elementIndex = 0; elementIndex < elementCount; elementIndex++) {
        // TJW: Should try to unify this with the copy of this logic for children in OFXMLElement
        id element = [elements objectAtIndex: elementIndex];
        child = [OFXMLElement createTreeForValue: element parentWhiteSpaceBehavior: OFXMLWhitespaceBehaviorTypePreserve document: self level: 0];
        if (child) {
            CFTreeAppendChild(docTree, child);
            CFRelease(child);
        }
    }

    if (!asFragment) {
        // Newline
        {
            child = [OFXMLElement createNewlineTree];
            CFTreeAppendChild(docTree, child);
            CFRelease(child);
        }
    }

    NSData *data = (NSData *)CFXMLTreeCreateXMLData(kCFAllocatorDefault, docTree);
    CFRelease(docTree);
    [pool release];
    return [data autorelease];
}

- (BOOL) writeToFile: (NSString *) path;
{
    return [[self xmlData] writeToFile: path atomically: YES];
}

- (unsigned int)processingInstructionCount;
{
    return [_processingInstructions count];
}

- (NSString *)processingInstructionNameAtIndex:(unsigned int)piIndex;
{
    return [[_processingInstructions objectAtIndex:piIndex] objectAtIndex:0];
}

- (NSString *)processingInstructionValueAtIndex:(unsigned int)piIndex;
{
    return [[_processingInstructions objectAtIndex:piIndex] objectAtIndex:1];
}

- (void)addProcessingInstructionNamed:(NSString *)piName value:(NSString *)piValue;
{
    if (!piName || !piValue)
        // Have to check ourselves since -initWithObjects: would just make a short array otherwise
        [NSException raise:NSInvalidArgumentException format:@"Both the name and value of a processing instruction must be non-nil."];
    
    NSArray *pi = [[NSArray alloc] initWithObjects:piName, piValue, nil];
    [_processingInstructions addObject:pi];
    [pi release];
}

- (OFXMLElement *) rootElement;
{
    return _rootElement;
}

//
// XML identifier management
//
- (void) clearIdentifiers;
{
    // The id->object dictionary uses object equality comparison and retains the objects
    [_idToObject release];
    _idToObject = (NSMutableDictionary *)CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &OFNSObjectDictionaryKeyCallbacks, &OFNSObjectDictionaryValueCallbacks);

    // The object->id dictionary uses pointer equality comparison and doesn't retain the objects
    [_objectToID release];
    _objectToID = (NSMutableDictionary *)CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &OFNonOwnedPointerDictionaryKeyCallbacks, &OFNonOwnedPointerDictionaryValueCallbacks);
}

- (BOOL)setPreferedIdentifier:(NSString *)identifier forObject:(id)object;
{
    NSString *previousIdentifier;
    if ((previousIdentifier = [_objectToID objectForKey:object]))
        // We already have an identifier registered for this object.
        return [previousIdentifier isEqualToString: identifier];

    id previousObject;
    if ((previousObject = [_idToObject objectForKey:identifier]))
        // Another object already owns this identifier
        return NO;

    // -setObject:forKey: would call -copyWithZone:, which we don't want
    CFDictionarySetValue((CFMutableDictionaryRef)_objectToID, object, identifier);
    [_idToObject setObject:object forKey:identifier];
    return YES;
}

- (id) objectForIdentifier:(NSString *)identifier;
{
    return [_idToObject objectForKey: identifier];
}

- (NSString *)generateIdentifierForObject:(id)object;
{
    NSString *identifier;

    identifier = [_objectToID objectForKey: object];
    if (!identifier) {
        // Any identifiers that were supposed to be reserved should have been set up already
        while (YES) {
            identifier = [[NSString alloc] initWithFormat: @"_%d", _nextID];
            if (![_idToObject objectForKey: identifier])
                // not in use!
                break;
            [identifier release];
            _nextID++;
        }

        // -setObject:forKey: would call -copyWithZone:, which we don't want
        CFDictionarySetValue((CFMutableDictionaryRef)_objectToID, object, identifier);
        [_idToObject setObject: object forKey: identifier];
        [identifier release];
    }

    return identifier;
}

- (BOOL)identifierRegisteredForObject:(id)object;
{
    return [_objectToID objectForKey: object] != nil;
}

//
// User objects
//
- (id)userObjectForKey:(NSString *)key;
{
    return [_userObjects objectForKey:key];
}

- (void)setUserObject:(id)object forKey:(NSString *)key;
{
    if (!_userObjects && object)
        _userObjects = [[NSMutableDictionary alloc] init];
    if (object)
        [_userObjects setObject:object forKey:key];
    else
        [_userObjects removeObjectForKey:key];
}

//
// Writing conveniences
//
- (OFXMLElement *) pushElement: (NSString *) elementName;
{
    OFXMLElement *child, *top;

    child  = [[OFXMLElement alloc] initWithName: elementName];
    top = [_elementStack lastObject];
    OBASSERT([top isKindOfClass: [OFXMLElement class]]);
    [top appendChild: child];
    [_elementStack addObject: child];
    [child release];

    return child;
}

- (void) popElement;
{
    OBPRECONDITION([_elementStack count] > 1);  // can't pop the root element
    [_elementStack removeLastObject];
}

- (OFXMLElement *) topElement;
{
    return [_elementStack lastObject];
}

- (void) appendString: (NSString *) string;
{
    OFXMLElement *top = [self topElement];
    OBASSERT([top isKindOfClass: [OFXMLElement class]]);
    [top appendChild: string];
}

- (void) appendString: (NSString *) string quotingMask: (unsigned int) quotingMask newlineReplacment: (NSString *) newlineReplacment;
{
    OFXMLElement *top = [self topElement];
    OBASSERT([top isKindOfClass: [OFXMLElement class]]);

    OFXMLString *xmlString = [[OFXMLString alloc] initWithString:string quotingMask:quotingMask newlineReplacment:newlineReplacment];
    [top appendChild: xmlString];
    [xmlString release];
}

- (void) appendElement: (NSString *) elementName;
{
    [self pushElement: elementName];
    [self popElement];
}

- (void) setAttribute: (NSString *) name string: (NSString *) value;
{
    [[self topElement] setAttribute: name string: value];
}

- (void) setAttribute: (NSString *) name value: (id) value;
{
    [[self topElement] setAttribute: name value: value];
}

- (void) setAttribute: (NSString *) name integer: (int) value;
{
    [[self topElement] setAttribute: name integer: value];
}

- (void) setAttribute: (NSString *) name real: (float) value;  // "%g"
{
    [[self topElement] setAttribute: name real: value format: @"%g"];
}

- (void) setAttribute: (NSString *) name real: (float) value format: (NSString *) formatString;
{
    [[self topElement] setAttribute: name real: value format: formatString];
}

- (void) appendElement: (NSString *) elementName containingString: (NSString *) contents;
{
    [[self topElement] appendElement: elementName containingString: contents];
}

- (void) appendElement: (NSString *) elementName containingInteger: (int) contents;
{
    [[self topElement] appendElement: elementName containingInteger: contents];
}

- (void) appendElement: (NSString *) elementName containingReal: (float) contents; // "%g"
{
    [[self topElement] appendElement: elementName containingReal: contents];
}

- (void) appendElement: (NSString *) elementName containingReal: (float) contents format: (NSString *) formatString;
{
    [[self topElement] appendElement: elementName containingReal: contents format: formatString];
}

// Reading conveniences

- (OFXMLCursor *) createCursor;
/*.doc. Returns a new retained cursor on the receiver.  As with most enumerator classes, it is not valid to access the cursor after having modified the document.  In this case, since the cursor doesn't care about the attributes, you can modify the attributes; just not the element tree. */
{
    return [[OFXMLCursor alloc] initWithDocument: self];
}



//
// Debugging
//

- (NSMutableDictionary *) debugDictionary;
{
    NSMutableDictionary *debugDictionary;

    debugDictionary = [super debugDictionary];
    if (_processingInstructions)
        [debugDictionary setObject: _processingInstructions forKey: @"_processingInstructions"];
    if (_dtdSystemID)
        [debugDictionary setObject: (NSString *)CFURLGetString(_dtdSystemID) forKey: @"_dtdSystemID"];
    if (_dtdPublicID)
        [debugDictionary setObject: _dtdPublicID forKey: @"_dtdPublicID"];


    // Really only want the element addresses to be displayed here.
    [debugDictionary setObject: _idToObject forKey: @"_idToObject"];
    [debugDictionary setObject: _objectToID forKey: @"_objectToID"];
    [debugDictionary setObject: _elementStack forKey: @"_elementStack"];

    [debugDictionary setObject: _rootElement forKey: @"_rootElement"];

    [debugDictionary setObject: [NSString stringWithFormat: @"0x%08x", _stringEncoding] forKey: @"_stringEncoding"];
    [debugDictionary setObject: [NSString stringWithFormat: @"%d", _nextID] forKey: @"_nextID"];

    if (_whitespaceBehavior)
        [debugDictionary setObject: _whitespaceBehavior forKey: @"_whitespaceBehavior"];

    return debugDictionary;
}

@end



@interface OFXMLDocument (XMLReadingSupport)
- (void) _setSourceURL: (CFURLRef) url encoding: (CFStringEncoding) encoding;
- (void) _setRootElementName: (NSString *) rootElementName systemID: (CFURLRef) systemID publicID: (CFStringRef) publicID;
- (void) _elementStarted: (OFXMLElement *) element;
- (BOOL) _elementEnded: (OFXMLElement *) element;
- (void) _addString: (NSString *) str;
#ifdef OMNI_ASSERTIONS_ON
- (unsigned int) _elementStackDepth;
#endif
@end

@implementation OFXMLDocument (XMLReadingSupport)
- (void) _setSourceURL: (CFURLRef) url encoding: (CFStringEncoding) encoding;
{
    // Ignoring the source URL for now
    _stringEncoding = encoding;
}

// We ignore the root element name right now.  Instead, we pick it up when the first element is added.
// NOTE: If we ever do use rootElementName here, we can't just retain it due to the way CFXMLParser uses memory.
- (void) _setRootElementName: (NSString *) rootElementName systemID: (CFURLRef) systemID publicID: (CFStringRef) publicID;
{
    OBPRECONDITION(rootElementName);
    // TODO: What happens if we read a fragment: we should default to having a non-nil processing instructions in which case these assertions are invalid
    OBPRECONDITION(!_dtdSystemID);
    OBPRECONDITION(!_dtdPublicID);
    
    if (systemID)
        _dtdSystemID = CFRetain(systemID);
    _dtdPublicID = [(id)publicID copy];
}

- (void) _elementStarted: (OFXMLElement *) element;
{
    if (!_rootElement) {
        _rootElement = [element retain];
        OBASSERT([_elementStack count] == 0);
        [_elementStack addObject: _rootElement];
    } else {
        OBASSERT([_elementStack count] != 0);
        [[_elementStack lastObject] appendChild: element];
        [_elementStack addObject: element];
    }
}

- (BOOL) _elementEnded: (OFXMLElement *) element;
{
    OBPRECONDITION([_elementStack count] != 0);
    OBPRECONDITION([_elementStack lastObject] == element);

    if (_rootElement == element)
        return YES;
    else {
        [_elementStack removeLastObject];
        return NO;
    }
}

// If the last child of the top element is a string, replace it with the concatenation of the two strings.
// TODO: Later we should have OFXMLString be an array of strings that is lazily concatenated to avoid slow degenerate cases (and then replace the last string with a OFXMLString with the two elements).  Actually, it might be better to just stick in an NSMutableArray of strings and then clean it up when the element is finished.
- (void) _addString: (NSString *) str;
{
    OFXMLElement *top      = [self topElement];
    NSArray      *children = [top children];
    unsigned int  count    = [children count];

    if (count) {
        id lastChild = [children objectAtIndex: count - 1];
        if ([lastChild isKindOfClass: [NSString class]]) {
            NSString *newString = [[NSString alloc] initWithFormat: @"%@%@", lastChild, str];
            [top removeChildAtIndex: count - 1];
            [top appendChild: newString];
            [newString release];
            return;
        }
    }

    [top appendChild: str];
}

#ifdef OMNI_ASSERTIONS_ON
- (unsigned int) _elementStackDepth;
{
    return [_elementStack count];
}
#endif

@end


static void *createXMLStructure(CFXMLParserRef parser, CFXMLNodeRef nodeDesc, void *_info)
{
    OFMLDocumentParseState *state = _info;
    OFXMLDocument *doc = state->doc;
    
    CFXMLNodeTypeCode  typeCode = CFXMLNodeGetTypeCode(nodeDesc);
    NSString          *str      = (NSString *)CFXMLNodeGetString(nodeDesc);
    const void        *data     = CFXMLNodeGetInfoPtr(nodeDesc);

    switch (typeCode) {
        case kCFXMLNodeTypeDocument: {
            const CFXMLDocumentInfo *docInfo = data;
            //NSLog(@"document: sourceURL:%@ encoding:0x%08x", docInfo->sourceURL, docInfo->encoding);
            [doc _setSourceURL: docInfo->sourceURL encoding: docInfo->encoding];
            return doc;
        }
        case kCFXMLNodeTypeProcessingInstruction: {
            const CFXMLProcessingInstructionInfo *procInstr = data;
            NSString *value = (NSString *)procInstr->dataString ? (NSString *)procInstr->dataString : @"";
            [doc addProcessingInstructionNamed:str value:value];
            //NSLog(@"proc instr: %@ value=%@", str, value);
            return nil;  // This has no children
        }
        case kCFXMLNodeTypeElement: {
            const CFXMLElementInfo *elementInfo = data;

            OBINVARIANT([state->whitespaceBehaviorStack count] == [doc _elementStackDepth] + 1); // always have the default behavior on the stack!

            // -initWithName:elementInfo: takes the CFXMLParser memory usage issues 
            OFXMLElement *element;
            element = [[OFXMLElement alloc] initWithName: str elementInfo: elementInfo];
            [doc _elementStarted: element];

            OFXMLWhitespaceBehaviorType oldBehavior = (OFXMLWhitespaceBehaviorType)[state->whitespaceBehaviorStack lastObject];
            OFXMLWhitespaceBehaviorType newBehavior = [[doc whitespaceBehavior] behaviorForElementName: str];

            if (newBehavior == OFXMLWhitespaceBehaviorTypeAuto)
                newBehavior = oldBehavior;
            
            [state->whitespaceBehaviorStack addObject: (id) newBehavior];


            OBINVARIANT([state->whitespaceBehaviorStack count] == [doc _elementStackDepth] + 1); // always have the default behavior on the stack!
            
            [element release]; // document will be retaining it for us one way or another
            return element;
        }
        case kCFXMLNodeTypeDocumentType: {
            const CFXMLDocumentTypeInfo *docType = data;
            //NSLog(@"dtd: %@ systemID=%@ publicIDs=%@", str, docType->externalID.systemID, docType->externalID.publicID);
            [doc _setRootElementName: str systemID: docType->externalID.systemID publicID: docType->externalID.publicID];
            return nil;  // This has no children that we care about
        }
        case kCFXMLNodeTypeWhitespace: {
            OBINVARIANT([state->whitespaceBehaviorStack count] == [doc _elementStackDepth] + 1); // always have the default behavior on the stack!

            // Only add the whitespace if our current behavior dictates that we do so (and we are actually inside the root element)
            OFXMLWhitespaceBehaviorType currentBehavior = (OFXMLWhitespaceBehaviorType)[state->whitespaceBehaviorStack lastObject];

            if (currentBehavior == OFXMLWhitespaceBehaviorTypePreserve) {
                OFXMLElement *root = [doc rootElement];
                if (root && !state->rootElementFinished) {
                    // -appendChild normally just retains the input, but we need to copy it to avoid CFXMLParser stomping on it
                    // Note that we are not calling -_addString: here since that does string merging but whitespace should (I think) only be reported in cases where we don't want it merged or it can't be merged.  This needs more investigation and test cases, etc.
                    NSString *copy = [str copy];
                    [[doc topElement] appendChild: copy];
                    [copy release];
                    return nil;
                }
            }
            
            return nil; // No children
        }
        case kCFXMLNodeTypeText:
        case kCFXMLNodeTypeCDATASection: {
            // Ignore text outside of the root element
            OFXMLElement *root = [doc rootElement];
            if (root && !state->rootElementFinished) {
                // -_addString: might just retain the input, but we need to copy it to avoid CFXMLParser stomping on it
                NSString *copy = [str copy];
                [doc _addString: copy];
                [copy release];
            }
            return nil; // No children
        }
        case kCFXMLNodeTypeEntityReference: {
            const CFXMLEntityReferenceInfo *entityInfo = data;
            NSString *replacement = nil;

            OFXMLElement *root = [doc rootElement];

            if (entityInfo->entityType == kCFXMLEntityTypeParsedInternal) {
                // Ignore text outside of the root element
                if (!root || state->rootElementFinished)
                    return nil;
                replacement = [[entityReplacements objectForKey: str] retain];
            } else if (entityInfo->entityType == kCFXMLEntityTypeCharacter) {
                // Ignore text outside of the root element
                if (!root || state->rootElementFinished)
                    return nil;

                // We expect something like '#35' or '#xab'.  Maximum Unicode value is 65535 (5 digits decimal) 
                unsigned int index, length = [str length];

                // CFXML should have already caught these, but it is easy to do ourselves, so...
                if (length <= 1 || [str characterAtIndex: 0] != '#') {
                    CFXMLParserAbort(parser, kCFXMLErrorMalformedCharacterReference, (CFStringRef)[NSString stringWithFormat: @"Malformed character reference '%@'", str]);
                    return nil;
                }

                unsigned int sum = 0;  // not unichar -- want to detect if we go >=65536
                if ([str characterAtIndex: 1] == 'x') {
                    if (length <= 2 || length > 6) { // Max is '#xFFFF' for 16-bit Unicode characters.  Dunno what to do about 32-bit values; we certainly don't handle them.
                        CFXMLParserAbort(parser, kCFXMLErrorMalformedCharacterReference, (CFStringRef)[NSString stringWithFormat: @"Malformed character reference '%@'", str]);
                        return nil;
                    }

                    for (index = 2; index < length; index++) {
                        unichar x = [str characterAtIndex: index];
                        if (x >= '0' && x <= '9')
                            sum = 16*sum + (x - '0');
                        else if (x >= 'a' && x <= 'f')
                            sum = 16*sum + (x - 'a') + 0xa;
                        else if (x >= 'A' && x <= 'F')
                            sum = 16*sum + (x - 'A') + 0xA;
                        else {
                            CFXMLParserAbort(parser, kCFXMLErrorMalformedCharacterReference, (CFStringRef)[NSString stringWithFormat: @"Malformed character reference '%@'", str]);
                            return nil;
                        }
                    }
                } else {
                    if (length > 7) { // Max is '#65535' for 16-bit Unicode characters.  Dunno what to do about 32-bit values; we certainly don't handle them.
                        CFXMLParserAbort(parser, kCFXMLErrorMalformedCharacterReference, (CFStringRef)[NSString stringWithFormat: @"Malformed character reference '%@'", str]);
                        return nil;
                    }
                    for (index = 1; index < length; index++) {
                        unichar x = [str characterAtIndex: index];
                        if (x >= '0' && x <= '9')
                            sum = 10*sum + (x - '0');
                        else {
                            CFXMLParserAbort(parser, kCFXMLErrorMalformedCharacterReference, (CFStringRef)[NSString stringWithFormat: @"Malformed character reference '%@'", str]);
                            return nil;
                        }
                    }
                }

                if (sum > 65535) { // Max is '#65535' for 16-bit Unicode characters.  Dunno what to do about 32-bit values; we certainly don't handle them.
                    CFXMLParserAbort(parser, kCFXMLErrorMalformedCharacterReference, (CFStringRef)[NSString stringWithFormat: @"Malformed character reference '%@'", str]);
                    return nil;
                }

                unichar ch = sum;
                replacement = [[NSString alloc] initWithCharacters: &ch length: 1];
            } else {
#ifdef DEBUG
                NSLog(@"typeCode:%d entityType=%d string:%@", typeCode, entityInfo->entityType, str);
                OBASSERT(NO); // We should opt out on this on a case by case basis
#endif
            }
            
            [doc _addString: replacement];
            return nil; // No children
        }
        case kCFXMLNodeTypeComment:
            // Ignore
            return nil;
        default:
#ifdef DEBUG
            NSLog(@"typeCode:%d nodeDesc:0x%08x string:%@", typeCode, (int)nodeDesc, str);
            OBASSERT(NO); // We should opt out on this on a case by case basis
#endif
            return nil; // Ignore stuff we don't understand
    }
}

static void addChild(CFXMLParserRef parser, void *parent, void *child, void *_info)
{
    // We don't actually use this callback.  We have our own stack stuff.
}

static void endXMLStructure(CFXMLParserRef parser, void *xmlType, void *_info)
{
    OFMLDocumentParseState *state = _info;
    OFXMLDocument *doc = state->doc;
    id value = (id)xmlType;

    if ([value isKindOfClass: [OFXMLElement class]]) {
        OBINVARIANT([state->whitespaceBehaviorStack count] == [doc _elementStackDepth] + 1); // always have the default behavior on the stack!
        state->rootElementFinished = [doc _elementEnded: value];
        if (!state->rootElementFinished)
            // Leave the behavior for the root element on the stack to keep our invariant alive
            [state->whitespaceBehaviorStack removeLastObject];
        OBINVARIANT([state->whitespaceBehaviorStack count] == [doc _elementStackDepth] + 1); // always have the default behavior on the stack!
    } else {
#ifdef DEBUG
        NSLog(@"%s: xmlType=0x%08x", __FUNCTION__, (int)xmlType);
        OBASSERT(NO);
#endif
    }
}

static CFDataRef resolveExternalEntity(CFXMLParserRef parser, CFXMLExternalID *extID, void *_info)
{
#ifdef DEBUG
    NSLog(@"%s:", __FUNCTION__);
    OBASSERT(NO);
#endif
    return NULL;
}

static Boolean handleError(CFXMLParserRef parser, CFXMLParserStatusCode error, void *_info)
{
#ifdef DEBUG
    NSLog(@"%s:", __FUNCTION__);
#endif

    return false; // stops parsing
}

