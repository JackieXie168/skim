// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniFoundation/OFUtilities.h>

#import <Foundation/Foundation.h>
#import <objc/objc-runtime.h>
#import <OmniBase/OmniBase.h>

#import <OmniFoundation/NSString-OFExtensions.h>
#import <OmniFoundation/OFObject.h>
#import <pthread.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFUtilities.m,v 1.28 2003/03/25 21:31:31 len Exp $")

#define OF_GET_INPUT_CHUNK_LENGTH 80

void OFLog(NSString *messageFormat, ...)
{
    va_list argList;
    NSString *message;

    va_start(argList, messageFormat);
    message = [[[NSString alloc] initWithFormat:messageFormat arguments:argList] autorelease];
    va_end(argList);

    fputs([message cString], stdout);
}

NSString *OFGetInput(NSString *promptFormat, ...)
{
    va_list argList;
    NSString *prompt;
    NSString *input;
    char buf[OF_GET_INPUT_CHUNK_LENGTH];

    va_start(argList, promptFormat);
    prompt = [[[NSString alloc] initWithFormat:promptFormat arguments:argList] autorelease];
    va_end(argList);

    printf("%s", [prompt cString]);
    input = [NSString string];
    while (!ferror(stdin)) {
        memset(buf, 0, sizeof(buf));
        fgets(buf, sizeof(buf), stdin);
        input = [input stringByAppendingString:[NSString stringWithCString:buf]];
        if ([input hasSuffix:@"\n"])
            break;
    }

    if ([input length])
        return [input substringToIndex:[input length] - 1];

    return nil;
}

void OFSetIvar(NSObject *object, NSString *ivarName, NSObject *ivarValue)
{
    Ivar ivar;
    id *ivarSlot;

    // TODO:At some point, this function should take a void * and should look at the type of the ivar and deal with scalar values correctly.

    ivar = class_getInstanceVariable(*(Class *) object, [ivarName cString]);
    OBASSERT(ivar);

    ivarSlot = (id *)((char *)object + ivar->ivar_offset);

    if (*ivarSlot != ivarValue) {
	[*ivarSlot release];
	*ivarSlot = [ivarValue retain];
    }
}

NSObject *OFGetIvar(NSObject *object, NSString *ivarName)
{
    Ivar ivar;
    id *ivarSlot;

    ivar = class_getInstanceVariable(*(Class *) object, [ivarName cString]);
    OBASSERT(ivar);

    ivarSlot = (id *)((char *)object + ivar->ivar_offset);

    return *ivarSlot;
}

static const char *hexTable = "0123456789abcdef";

char *OFNameForPointer(id object, char *pointerName)
{
    char firstChar, *p = pointerName;
    const char *className;
    unsigned long pointer;

    if (!object) {
	*pointerName++ = '*';
	*pointerName++ = 'N';
	*pointerName++ = 'I';
	*pointerName++ = 'L';
	*pointerName++ = '*';
	*pointerName++ = '\0';
	return p;
    }

    if (OBPointerIsClass(object)) {
	firstChar = '+';
        pointer = (unsigned long)object;
    } else {
	firstChar = '-';
	pointer = (unsigned long)object->isa;
    }

    // Rather than calling sprintf, we'll just format the string by hand.  This is much faster.

    // Mark whether it is an instance or not
    *pointerName++ = firstChar;

    // Write the class name
    // BUG: We don't actually enforce the name length limit
    if (!(className = ((Class)pointer)->name))
	className = "Bogus name!";

    while ((*pointerName++ = *className++))
	;

    // Back up over the trailing null
    pointerName--;
    *pointerName++ = ' ';
    *pointerName++ = '(';

    // Write the pointer as hex
    *pointerName++ = '0';
    *pointerName++ = 'x';

    pointer = (unsigned long) object;
    pointerName += 7;

    // 8
    *pointerName-- = hexTable[pointer & 0xf];
    pointer >>= 4;

    // 7
    *pointerName-- = hexTable[pointer & 0xf];
    pointer >>= 4;

    // 6
    *pointerName-- = hexTable[pointer & 0xf];
    pointer >>= 4;

    // 5
    *pointerName-- = hexTable[pointer & 0xf];
    pointer >>= 4;

    // 4
    *pointerName-- = hexTable[pointer & 0xf];
    pointer >>= 4;

    // 3
    *pointerName-- = hexTable[pointer & 0xf];
    pointer >>= 4;

    // 2
    *pointerName-- = hexTable[pointer & 0xf];
    pointer >>= 4;

    // 1
    *pointerName-- = hexTable[pointer & 0xf];

    pointerName += 9;

    *pointerName++ = ')';
    *pointerName++ = '\0';

    return p;
}

BOOL OFInstanceIsKindOfClass(id instance, Class aClass)
{
    Class sourceClass = instance->isa;

    while (sourceClass) {
        if (sourceClass == aClass)
            return YES;
        sourceClass = sourceClass->super_class;
    }
    return NO;
}

NSString *OFDescriptionForObject(id object, NSDictionary *locale, unsigned indentLevel)
{
    if ([object isKindOfClass:[NSString class]])
        return object;
    else if ([object respondsToSelector:@selector(descriptionWithLocale:indent:)])
        return [(id)object descriptionWithLocale:locale indent:indentLevel + 1];
    else  if ([object respondsToSelector:@selector(descriptionWithLocale:)])
        return [(id)object descriptionWithLocale:locale];
    else
        return [NSString stringWithFormat: @"%@%@",
            [NSString spacesOfLength:(indentLevel + 1) * 4],
            [object description]];
}


/*"
Ensures that the given selName maps to a registered selector.  If it doesn't, a copy of the string is made and it is registered with the runtime.  The registered selector is returned, in any case.
"*/
SEL OFRegisterSelectorIfAbsent(const char *selName)
{
    SEL sel;

    if (!(sel = sel_getUid(selName))) {
        unsigned int                len;
        char                       *newSel;

        // On NS4.0 and later, sel_registerName copies the selector name.  But
        // we won't assume that is the case -- we'll make a temporary copy
        // and get the assertion rather than crashing the runtime (in case they
        // change this in the future).
        len = strlen(selName);
        newSel = (char *)NSZoneMalloc(NULL, len + 1);
        strcpy(newSel, selName);
        OBASSERT(newSel[len] == '\0');
        sel = sel_registerName(newSel);

        // Make sure the copy happened
        OBASSERT((void *)sel_getUid(selName) != (void *)newSel);
        OBASSERT((void *)sel != (void *)newSel);

        NSZoneFree(NULL, newSel);
    }

    return sel;
}

/*" This returns the largest of the rects lying to the left, right, top or bottom of the child rect inside the parent rect.  If the two rects do not intersect, parentRect is returned.  If they are the same (or childRect actually contains parentRect), NSZeroRect is returned.  Note that if you which to avoid multiple rects, repeated use of this algorithm is not guaranteed to return the largest non-intersecting rect). "*/

NSRect OFLargestRectAvoidingRect(NSRect parentRect, NSRect childRect)
{
    NSRect rect, bestRect;
    float size, bestSize;
    
    childRect = NSIntersectionRect(parentRect, childRect);
    if (NSIsEmptyRect(childRect)) {
        // If the child rect doesn't intersect the parent rect, then all of the
        // parent rect avoids the inside rect
        return parentRect;
    }
    
    // Initialize the result so that if the two rects are equal, we'll
    // return a zero rect.
    bestRect = NSZeroRect;
    bestSize = 0.0;
    
    // Test the left rect
    rect.origin = parentRect.origin;
    rect.size.width = NSMinX(childRect) - NSMinX(parentRect);
    rect.size.height = NSHeight(parentRect);
    
    size = rect.size.height * rect.size.width;
    if (size > bestSize) {
        bestSize = size;
        bestRect = rect;
    }
    
    // Test the right rect
    rect.origin.x = NSMaxX(childRect);
    rect.origin.y = NSMinY(parentRect);
    rect.size.width = NSMaxX(parentRect) - NSMaxX(childRect);
    rect.size.height = NSHeight(parentRect);

    size = rect.size.height * rect.size.width;
    if (size > bestSize) {
        bestSize = size;
        bestRect = rect;
    }
    
    // Test the top rect
    rect.origin.x = NSMinX(parentRect);
    rect.origin.y = NSMaxY(childRect);
    rect.size.width = NSWidth(parentRect);
    rect.size.height = NSMaxY(parentRect) - NSMaxY(childRect);
    
    size = rect.size.height * rect.size.width;
    if (size > bestSize) {
        bestSize = size;
        bestRect = rect;
    }
    
    // Test the bottom rect
    rect.origin = parentRect.origin;
    rect.size.width = NSWidth(parentRect);
    rect.size.height = NSMinY(childRect) - NSMinY(parentRect);

    size = rect.size.height * rect.size.width;
    if (size > bestSize) {
        bestSize = size;
        bestRect = rect;
    }
    
    return bestRect;
}

#import <SystemConfiguration/SystemConfiguration.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

unsigned int OFLocalIPv4Address(void)
{
    SCDynamicStoreRef store;
    CFStringRef interfacesKey;
    NSDictionary *interfacesDictionary;
    NSArray *interfaces;
    unsigned int interfaceIndex, interfaceCount;

    store = SCDynamicStoreCreate(NULL, (CFStringRef)[[NSProcessInfo processInfo] processName], NULL, NULL);
    interfacesKey = SCDynamicStoreKeyCreateNetworkInterface(NULL, kSCDynamicStoreDomainState);
    interfacesDictionary = (NSDictionary *)SCDynamicStoreCopyValue(store, interfacesKey);
    interfaces = [interfacesDictionary objectForKey:(NSString *)kSCDynamicStorePropNetInterfaces];
    interfaceCount = [interfaces count];
    for (interfaceIndex = 0; interfaceIndex < interfaceCount; interfaceIndex++) {
        CFStringRef interfaceName;
        CFStringRef ipv4Key, linkKey;
        NSDictionary *ipv4Dictionary, *linkDictionary;
        NSNumber *activeValue;
        NSArray *ipAddresses;

        interfaceName = (CFStringRef)[interfaces objectAtIndex:interfaceIndex];
        linkKey = SCDynamicStoreKeyCreateNetworkInterfaceEntity(NULL, kSCDynamicStoreDomainState, interfaceName, kSCEntNetLink);
        linkDictionary = (NSDictionary *)SCDynamicStoreCopyValue(store, linkKey);
        activeValue = [linkDictionary objectForKey:(NSString *)kSCPropNetLinkActive];
        if (activeValue == nil || ![activeValue boolValue])
            continue;
        ipv4Key = SCDynamicStoreKeyCreateNetworkInterfaceEntity(NULL, kSCDynamicStoreDomainState, interfaceName, kSCEntNetIPv4);
        ipv4Dictionary = (NSDictionary *)SCDynamicStoreCopyValue(store, ipv4Key);
        ipAddresses = [ipv4Dictionary objectForKey:(NSString *)kSCPropNetIPv4Addresses];
        if ([ipAddresses count] != 0) {
            NSString *ipAddressString;
            unsigned long int address;

            ipAddressString = [ipAddresses objectAtIndex:0];
            address = inet_addr([ipAddressString cString]);
            if (address != (unsigned int)-1)
                return address;
        }
    }
    return (unsigned int)INADDR_LOOPBACK; // Localhost (127.0.0.1)
}


NSString *OFISOLanguageCodeForEnglishName(NSString *languageName)
{
    return NSLocalizedStringFromTableInBundle(languageName, @"EnglishToISO", [NSBundle bundleForClass:[OFObject class]], no comment);
}

NSString *OFLocalizedNameForISOLanguageCode(NSString *languageCode)
{
    return NSLocalizedStringFromTableInBundle(languageCode, @"Language", [NSBundle bundleForClass:[OFObject class]], no comment);
}


// Adapted from OmniNetworking. May be replaced by something cleaner in the future.

#import <sys/ioctl.h>
#import <sys/socket.h>
#import <net/if.h>
#import <net/if_dl.h>         // for 'struct sockaddr_dl'
#import <unistd.h>		// for close()

// We'll guess that this is wildly larger than the maximum number of interfaces on the machine.  I don't see that there is a way to get the number of interfaces so that you don't have to have a hard-coded value here.  Sucks.
#define MAX_INTERFACES 100

#define IFR_NEXT(ifr)	\
    ((struct ifreq *) ((char *) (ifr) + sizeof(*(ifr)) + \
                   MAX(0, (int) (ifr)->ifr_addr.sa_len - (int) sizeof((ifr)->ifr_addr))))

static NSDictionary *InterfaceAddresses = nil;

NSDictionary *OFLinkLayerInterfaceAddresses()
{
    struct ifreq requestBuffer[MAX_INTERFACES], *linkInterface;
    struct ifconf ifc;
    int interfaceSocket;
    NSMutableDictionary *interfaceAddresses;

    if (InterfaceAddresses != nil) // only need to do this once
        return InterfaceAddresses;

    interfaceAddresses = [NSMutableDictionary dictionary];
    
    ifc.ifc_len = sizeof(requestBuffer);
    ifc.ifc_buf = (caddr_t)requestBuffer;

    if ((interfaceSocket = socket(AF_INET, SOCK_DGRAM, 0)) < 0) 
        [NSException raise:NSGenericException format:@"Unable to create temporary socket, errno = %d", OMNI_ERRNO()];

    if (ioctl(interfaceSocket, SIOCGIFCONF, &ifc) != 0)
        [NSException raise:NSGenericException format:@"Unable to get list of network interfaces, errno = %d", OMNI_ERRNO()];

    linkInterface = (struct ifreq *) ifc.ifc_buf;
    while ((char *) linkInterface < &ifc.ifc_buf[ifc.ifc_len]) {
        // The ioctl returns both the entries having the address (AF_INET) and the link layer entries (AF_LINK).  The AF_LINK entry has the link layer address which contains the interface type.  This is the only way I can see to get this information.  We cannot assume that we will get both an AF_LINK and AF_INET entry since the interface may not be configured.  For example, if you have a 10Mb port on the motherboard and a 100Mb card, you may not configure the motherboard port.

        // For each AF_LINK entry...
        if (linkInterface->ifr_addr.sa_family == AF_LINK) {
            unsigned int nameLength;
            NSString *ifname;
            struct sockaddr_dl *linkSocketAddress;
            int linkLayerAddressLength;

            for (nameLength = 0; nameLength < IFNAMSIZ; nameLength++)
                if (linkInterface->ifr_name[nameLength] == '\0')
                    break;
            ifname = [NSString stringWithCString:linkInterface->ifr_name length:nameLength];
            // get the link layer address (for ethernet, this is the MAC address)
            linkSocketAddress = (struct sockaddr_dl *)&linkInterface->ifr_addr;
            linkLayerAddressLength = linkSocketAddress->sdl_alen;
            if (linkLayerAddressLength > 0) {
                const unsigned char *bytes;
                int byteIndex;
                NSMutableString *addressString;

                bytes = (unsigned char *)LLADDR(linkSocketAddress);
                addressString = [NSMutableString string];
                for (byteIndex = 0; byteIndex < linkLayerAddressLength; byteIndex++) {
                    unsigned int byteValue;

                    if (byteIndex > 0)
                        [addressString appendString:@":"];
                    byteValue = (unsigned int)bytes[byteIndex];
                    [addressString appendFormat:@"%02x", byteValue];
                }
                [interfaceAddresses setObject:addressString forKey:ifname];
            }
        }
        linkInterface = IFR_NEXT(linkInterface);
    }

    close(interfaceSocket);
    InterfaceAddresses = [interfaceAddresses copy];
    return InterfaceAddresses;
}

NSString *OFUniqueMachineIdentifier()
{
    return [OFLinkLayerInterfaceAddresses() objectForKey:@"en0"];
}

size_t OFRemainingStackSize()
{
#if !TARGET_CPU_PPC
#warning Do not know how stack grows on this platform
#endif
    char *low;
    char stack;

    // The stack grows negatively on PPC
    low = pthread_get_stackaddr_np(pthread_self()) - pthread_get_stacksize_np(pthread_self());
    return &stack - low;
}
