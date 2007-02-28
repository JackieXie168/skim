// Copyright 2000-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFCodeFragment.h>

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/CoreServicesExtensions/OFCodeFragment.m 66170 2005-07-28 17:40:10Z kc $")


// Adapted from code from Doug Davidson at Apple.  This builds a new blob of memory given the instruction template below.  This loads a 32-bit address for the given tvector into a volatile register and then loads the instruction pointer of the code into the count register, the RTOC value into r2 and jumps through the counter.
static UInt32 templateCode[6] = {0x3D800000, 0x618C0000, 0x800C0000, 0x804C0004, 0x7C0903A6, 0x4E800420};


@interface OFCodeFragment (PrivateAPI)
- (void *) _symbolNamed: (NSString *) symbolName symbolClass: (CFragSymbolClass *) symbolClass;
@end

@implementation OFCodeFragment

- initWithContentsOfFile: (NSString *) aPath;
{
    CFURLRef url;
    FSRef fsRef;
    FSSpec fsSpec;
    OSErr err;
    Boolean success;
    Str255 errMessage;

    path = [aPath copy];
    OFBulkBlockPoolInitialize(&locked_functionBlockPool, sizeof(templateCode));
    OFSimpleLockInit(&lock);
    locked_functionTable = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks, NSNonOwnedPointerMapValueCallBacks, 0);
    
    url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)path, kCFURLPOSIXPathStyle, false);
    success = CFURLGetFSRef(url, &fsRef);
    CFRelease(url);
    if (!success) {
        [self release];
        [NSException raise: NSInvalidArgumentException format: @"Unable to get a FSRef from the path %@.", aPath];
    }
    
    err = FSGetCatalogInfo(&fsRef, kFSCatInfoNone, NULL, NULL, &fsSpec, NULL);
    if (err != noErr) {
        [self release];
        [NSException raise: NSInvalidArgumentException format: @"Unable to get a FSSpec from the path %@.", aPath];
    }
    
    // Since we specify kLoadCFrag here, if the code is already loaded, we'll just get a new copy of any connection specific data.
    err = GetDiskFragment(&fsSpec,
                        0,
                        kCFragGoesToEOF,
                        NULL,
                        kLoadCFrag,
                        &connectionID,
                        &mainAddress,
                        errMessage);
    if (err != noErr) {
        [self release];
        [NSException raise: NSInvalidArgumentException format: @"Error loading code fragment at path '%@', %@, err = %d", aPath, [NSString stringWithCString: (char *)&errMessage[1] length: errMessage[0]], err];
    }

    return self;
}


- (void) dealloc;
{
    OSErr err;

    [path release];

    // If this is the last connection to the fragment, the code will get unloaded.
    if (connectionID) {
        err = CloseConnection(&connectionID);
        if (err != noErr)
            NSLog(@"Error closing Code Fragment Manager connection for path '%@'", path);
    }

    OFSimpleLockFree(&lock);
    
    // This will deallocate the pages held by the pool which will erase the executable bit
    OFBulkBlockPoolDeallocateAllBlocks(&locked_functionBlockPool);
    NSFreeMapTable(locked_functionTable);
    [locked_symbolNames release];
    
    [super dealloc];
}

- (NSString *) path;
{
    return path;
}

- (NSArray *) symbolNames;
{
    NSMutableArray *newNames;
    long symbolIndex, symbolCount;
    OSErr err;

    if (locked_symbolNames)
        return locked_symbolNames;
    
    OFSimpleLock(&lock);
    if (locked_symbolNames) {
        OFSimpleUnlock(&lock);
        return locked_symbolNames;
    }
    
    err = CountSymbols(connectionID, &symbolCount);
    if (err != noErr) {
        OFSimpleUnlock(&lock);
        [NSException raise: NSInternalInconsistencyException format: @"Unable to determine number of symbols in code fragment at path '%@', err = %d", path, err];
    }
    
    newNames = [NSMutableArray arrayWithCapacity: symbolCount];
    
    for (symbolIndex = 0; symbolIndex < symbolCount; symbolIndex++) {
        Str255 name;
        NSString *nameString;
        
        err = GetIndSymbol(connectionID, symbolIndex, name, NULL, NULL);
        if (err != noErr) {
            OFSimpleUnlock(&lock);
            [NSException raise: NSInternalInconsistencyException format: @"Unable to get symbol name at index %d in code fragment at path '%@', err = %d", symbolIndex, path, err];
        }
        
        nameString = [[NSString alloc] initWithCString: (const char *)&name[1] length: name[0]];
        [newNames addObject: nameString];
        [nameString release];
    }
    
    locked_symbolNames = [[NSArray alloc] initWithArray: newNames];
    OFSimpleUnlock(&lock);
    
    return locked_symbolNames;
}

- (void (*)()) mainAddress;
{
    return [self wrapperFunctionForCFMTVector: (void *)mainAddress];
}

- (void (*)()) functionNamed: (NSString *) symbolName;
{
    CFragSymbolClass symbolClass;
    void *tvector;
    
    tvector = [self _symbolNamed: symbolName symbolClass: &symbolClass];
    if (tvector == NULL)
        return NULL;
    
    if (symbolClass != kTVectorCFragSymbol)
        [NSException raise: NSInternalInconsistencyException format: @"Was expecting a tvector symbol named '%@' in code fragment at path '%@', but got a symbol with class %d", symbolName, path, symbolClass];

    return [self wrapperFunctionForCFMTVector: tvector];
}

- (void (*)()) wrapperFunctionForCFMTVector: (void *) tvector;
{
    void (*func)();

    if (!tvector)
        return NULL;
    
    OFSimpleLock(&lock);
    
    // Return a cached result if we have one
    func = NSMapGet(locked_functionTable, tvector);
    if (!func) {
        UInt32 *words;
        
        words = (UInt32 *)OFBulkBlockPoolAllocate(&locked_functionBlockPool);
        words[0] = templateCode[0] | ((UInt32)tvector >> 16);
        words[1] = templateCode[1] | ((UInt32)tvector & 0xFFFF);
        words[2] = templateCode[2];
        words[3] = templateCode[3];
        words[4] = templateCode[4];
        words[5] = templateCode[5];
        
        // This Carbon function (used by Doug Davidson at Apple) will presumably make the whole page executable.  This is OK since we're using an OFBulkBlockPool and these pages only contain our code (and some linked lists).  This should  also flush he page from the icache, but I haven't verified that.
        MakeDataExecutable(words, sizeof(templateCode));

        func = (void (*)())words;
        NSMapInsertKnownAbsent(locked_functionTable, tvector, func);
    }
    
    OFSimpleUnlock(&lock);
    
    return func;
}

@end


@implementation OFCodeFragment (PrivateAPI)

- (void *) _symbolNamed: (NSString *) symbolName symbolClass: (CFragSymbolClass *) symbolClass;
{
    unsigned char name[257];  // one for length + 255 + one for null added by NSString below
    OSErr err;
    unsigned int nameLength;
    Ptr symbolAddress;
    
    nameLength = [symbolName length];
    if (!nameLength || nameLength > 255)
        [NSException raise: NSInvalidArgumentException format: @"The symbol name '%@' has a length outside the valid range of 0..255.", symbolName];

    // Build a pascal string from the NSString.  Length in first byte.
    *name = nameLength;
    
    // Then up to 255 characters, plus NSString will add a null (which is useless here).
    [symbolName getCString: (char *)&name[1] maxLength: nameLength];
    
    err = FindSymbol(connectionID, name, &symbolAddress, symbolClass);
    if (err == cfragNoSymbolErr) {
        // Indicate a missing symbol by returning NULL.
        return NULL;
    } else if (err != noErr) {
        NSLog(@"symbolNames = %@", [self symbolNames]);
        [NSException raise: NSInternalInconsistencyException format: @"Error %d returned when looking for symbol named '%@' in code fragment at path '%@'", err, symbolName, path];
    }
    
    return symbolAddress;
}

@end


