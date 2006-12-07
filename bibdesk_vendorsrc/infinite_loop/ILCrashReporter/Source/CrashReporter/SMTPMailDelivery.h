//
//  SMTPMailDelivery.h
//  ILCrashReporter
//
//  Created by Claus Broch on 17/08/2004.
//  Copyright 2004 Infinite Loop. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SMTPMailDelivery : NSObject
{
@private
	int		_serverSocket;
	BOOL	_isConnected;
}

+ (BOOL)sendMail:(NSData*)mail to:(NSString*)to from:(NSString*)from;
+ (NSData*)mailMessage:(NSString*)message withSubject:(NSString*)subject to:(NSString*)to from:(NSString*)from attachments:(NSArray*)attachments;

- (BOOL)sendMail:(NSData*)mail to:(NSString*)to from:(NSString*)from;
- (BOOL)sendMail:(NSData*)mail to:(NSString*)to from:(NSString*)from usingServer:(NSString*)server onPort:(int)port;

@end
