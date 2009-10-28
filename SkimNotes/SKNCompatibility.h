//
// Used in the prefix header for all source files to define Leopard symbols in a Tiger environment.
//

#ifndef NSINTEGER_DEFINED
    #ifdef NS_BUILD_32_LIKE_64
        typedef long NSInteger;
        typedef unsigned long NSUInteger;
    #else
        typedef int NSInteger;
        typedef unsigned int NSUInteger;
    #endif
    #define NSIntegerMax    LONG_MAX
    #define NSIntegerMin    LONG_MIN
    #define NSUIntegerMax   ULONG_MAX
    #define NSINTEGER_DEFINED 1
#endif
