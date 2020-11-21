//
//  SUSignatures.h
//  Sparkle
//
//  Created by Kornel on 15/09/2018.
//  Copyright © 2018 Sparkle Project. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __MAC_OS_X_VERSION_MAX_ALLOWED < 1090
typedef NS_OPTIONS(NSUInteger, NSDataBase64DecodingOptions) {
    NSDataBase64DecodingIgnoreUnknownCharacters = 1UL << 0
}
@interface NSData (SUDSAVerifier)
- (id)initWithBase64Encoding:(NSString *)base64String;
- (id)initWithBase64EncodedString:(NSString *)base64String options:(NSDataBase64DecodingOptions)options;
@end
#endif

NS_ASSUME_NONNULL_BEGIN

@interface SUSignatures : NSObject {
    unsigned char ed25519_signature[64];
}
@property (strong, readonly, nullable) NSData *dsaSignature;
@property (readonly, nullable, nonatomic) const unsigned char *ed25519Signature;

- (instancetype)initWithDsa:(NSString * _Nullable)dsa ed:(NSString * _Nullable)ed;
@end


@interface SUPublicKeys : NSObject {
    unsigned char ed25519_public_key[32];
}
@property (strong, readonly, nullable) NSString *dsaPubKey;
@property (readonly, nullable, nonatomic) const unsigned char *ed25519PubKey;

- (instancetype)initWithDsa:(NSString * _Nullable)dsa ed:(NSString * _Nullable)ed;
- (BOOL) isEqualToKey:(SUPublicKeys *)key;

@end

NS_ASSUME_NONNULL_END
