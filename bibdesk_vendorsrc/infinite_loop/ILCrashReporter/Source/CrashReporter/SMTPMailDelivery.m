//
//  SMTPMailDelivery.m
//  ILCrashReporter
//
//  Created by Claus Broch on 17/08/2004.
//  Copyright 2004 Infinite Loop. All rights reserved.
//

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <netdb.h>
#include <unistd.h>
#include <arpa/nameser.h>
#include <resolv.h>
#include <dns_util.h>

#import "SMTPMailDelivery.h"

/*
 **  The standard udp packet size PACKETSZ (512) is not sufficient for some
 **  nameserver answers containing very many resource records. The resolver
 **  may switch to tcp and retry if it detects udp packet overflow.
 **  Also note that the resolver routines res_query and res_search return
 **  the size of the *un*truncated answer in case the supplied answer buffer
 **  it not big enough to accommodate the entire answer.
 */

# ifndef MAXPACKET
#  define MAXPACKET 8192	/* max packet size used internally by BIND */
# endif /* ! MAXPACKET */

typedef union
{
	dns_header_t	qb1;
	unsigned char	qb2[MAXPACKET];
} querybuf;

#define MAXMXHOSTS	100		/* max # of MX records for one host */

# ifndef MXHOSTBUFSIZE
#  define MXHOSTBUFSIZE	(128 * MAXMXHOSTS)
# endif /* ! MXHOSTBUFSIZE */

static char	MXHostBuf[MXHOSTBUFSIZE];
#if (MXHOSTBUFSIZE < 2) || (MXHOSTBUFSIZE >= INT_MAX/2)
error: _MXHOSTBUFSIZE is out of range
#endif /* (MXHOSTBUFSIZE < 2) || (MXHOSTBUFSIZE >= INT_MAX/2) */

void base64ChunkFor3Characters(char *buf, const char *inBuf, int numChars);

@interface SMTPMailDelivery(Private)

- (BOOL)_connectToServer:(NSString*)server onPort:(int)port;
- (void)_closeConnection;
- (BOOL)_writeEnvelopeTo:(NSString*)to from:(NSString*)from;
- (BOOL)_writeContent:(NSData*)content;
- (NSArray*)_mailServersForDomain:(NSString*)domain;
+ (NSStringEncoding)_encodingForString:(NSString*)string;
+ (NSString*)_mimeNameForEncoding:(NSStringEncoding)encoding;
+ (NSData*)_header:(NSString*)header withValue:(NSString*)value;
+ (NSData*)_encodeBase64:(NSData*)theData lineLength:(int)numChars;
+ (NSMutableData*)_replaceLFWithCRLFforMessage:(NSData*)message;
+ (void)_encodeLeadingPeriods:(NSMutableData*)data;

@end

@implementation SMTPMailDelivery

- (id)init
{
    self = [super init];
	if(self)
	{
		_serverSocket = -1;
	}
	
	return self;
}

- (void)dealloc
{
	[self _closeConnection];
	
    [super dealloc];
}

+ (BOOL)sendMail:(NSData*)mail to:(NSString*)to from:(NSString*)from
{
	BOOL	sent = NO;
	id		sender;
	
	sender = [[[self class] alloc] init];
	if(sender)
	{
		sent = [sender sendMail:mail to:to from:from];
		[sender release];
	}
	
	return sent;
}

+ (NSData*)mailMessage:(NSString*)message withSubject:(NSString*)subject to:(NSString*)to from:(NSString*)from attachments:(NSArray*)attachments
{
	NSMutableData	*rawMessage;
	NSData			*temp;
	NSMutableData	*mutTemp;
	NSString		*xMailer;
	CFUUIDRef		uuid;
	CFStringRef		uuidString;
	NSString		*date;
	NSDictionary	*locale;
	NSString		*senderDomain;
	BOOL			useMime;
	NSString		*mimeDelimiter = nil;
	NSStringEncoding	encoding;
	NSString		*encodingName = nil;
	
	rawMessage = [NSMutableData data];
	
	encoding = [self _encodingForString:message];
	encodingName = [self _mimeNameForEncoding:encoding];
	//
	// Generate the headers
	//
	
	[rawMessage appendData:[self _header:@"Mime-Version" withValue:@"1.0"]];
	useMime = attachments && ([attachments count] > 0);
	if(useMime)
	{
		mimeDelimiter = [NSString stringWithFormat:@"----_=_NextPart_%8.8X_%8.8X", random(), random()];
		
		[rawMessage appendData:
			[self _header:@"Content-Type" 
				withValue:[NSString stringWithFormat:@"multipart/mixed; boundary=\"%@\"", mimeDelimiter]]];
	}
	else
	{
		[rawMessage appendData:
			[self _header:@"Content-Transfer-Encoding" 
				withValue:[NSString stringWithFormat:@"%dbit", (encoding == NSASCIIStringEncoding) ? 7 : 8]]];
		[rawMessage appendData:
			[self _header:@"Content-Type"
				withValue:[NSString stringWithFormat:@"text/plain; charset=%@; format=flowed", encodingName]]];
	}
	
	uuid = CFUUIDCreate(kCFAllocatorDefault);
	uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuid);
	senderDomain = [[from componentsSeparatedByString:@"@"] lastObject];	
	temp = [self _header:@"Message-ID" withValue:[NSString stringWithFormat:@"<%@@%@>", uuidString, senderDomain]];
	[rawMessage appendData:temp];
	CFRelease(uuidString);
	CFRelease(uuid);
	
	// Need to override the abbrevated names since they might be localized
	locale = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle bundleForClass: [NSObject class]]
							  pathForResource: @"en"
									   ofType: nil
								  inDirectory: @"Languages"] ];
	if(!locale)
		locale = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle bundleForClass: [NSObject class]]
							  pathForResource: @"English"
									   ofType: nil
								  inDirectory: @"Languages"] ];
	date = [[NSCalendarDate calendarDate] descriptionWithCalendarFormat:@"%a, %e %b %Y %H:%M:%S %z" locale:locale];
	[rawMessage appendData:[self _header:@"Date" withValue:[date description]]];
	[rawMessage appendData:[self _header:@"Subject" withValue:subject]];
	[rawMessage appendData:[self _header:@"To" withValue:to]];
	[rawMessage appendData:[self _header:@"From" withValue:from]];
	xMailer = [NSString stringWithFormat:@"ILCrashReporter (v%@)",
		[[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey]];
	[rawMessage appendData:[self _header:@"X-Mailer" withValue:xMailer]];
	[rawMessage appendData:[@"\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
	
	// Generate the body
	if(useMime)
	{
		[rawMessage appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", mimeDelimiter] dataUsingEncoding:NSASCIIStringEncoding]];
		[rawMessage appendData:
			[self _header:@"Content-Transfer-Encoding" 
				withValue:[NSString stringWithFormat:@"%dbit", (encoding == NSASCIIStringEncoding) ? 7 : 8]]];
		[rawMessage appendData:
			[self _header:@"Content-Type"
				withValue:[NSString stringWithFormat:@"text/plain; charset=%@; format=flowed", encodingName]]];
		[rawMessage appendData:[@"\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
	}
	
	temp = [message dataUsingEncoding:encoding allowLossyConversion:YES];
	mutTemp = [self _replaceLFWithCRLFforMessage:temp];
	[self _encodeLeadingPeriods:mutTemp];
	[rawMessage appendData:mutTemp];
	[rawMessage appendData:[@"\r\n" dataUsingEncoding:NSASCIIStringEncoding]];

	// Attach the file(s)
	if(attachments && ([attachments count] > 0))
	{
		NSEnumerator	*enumer;
		NSFileWrapper	*attachment;
		
		enumer = [attachments objectEnumerator];
		while((attachment = [enumer nextObject]))
		{
			NSData	*base64coded;
			
			[rawMessage appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", mimeDelimiter] dataUsingEncoding:NSASCIIStringEncoding]];
			[rawMessage appendData:
				[self _header:@"Content-Type"
					withValue:[NSString stringWithFormat:@"application/octet-stream;\r\n\tname=\"%@\"", [attachment filename]]]];
			[rawMessage appendData:
				[self _header:@"Content-Disposition" 
					withValue:[NSString stringWithFormat:@"attachment;\r\n\tfilename=\"%@\"", [attachment filename]]]];
			[rawMessage appendData:[self _header:@"Content-Transfer-Encoding" withValue:@"base64"]];
			[rawMessage appendData:[@"\r\n" dataUsingEncoding:NSASCIIStringEncoding]];

			base64coded = [self _encodeBase64:[attachment regularFileContents] lineLength:76];
			[rawMessage appendData:base64coded];
			[rawMessage appendData:[@"\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
		}
			
	}
	
	if(useMime)
	{
		[rawMessage appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", mimeDelimiter] dataUsingEncoding:NSASCIIStringEncoding]];
	}
	
	return rawMessage;
}

- (BOOL)sendMail:(NSData*)mail to:(NSString*)to from:(NSString*)from
{
	NSArray			*servers;
	NSString		*server;
	NSEnumerator	*enumer;
	BOOL			sent = NO;
	NSString		*domain;
	
	domain = [[to componentsSeparatedByString:@"@"] lastObject];	
	servers = [self _mailServersForDomain:domain];
	enumer = [servers objectEnumerator];
	while(!sent && (server = [enumer nextObject]))
	{
		// Try each server in turn until one succeeds
		sent = [self sendMail:mail to:to from:from usingServer:server onPort:25];
	}
	
	if(!sent && ![servers count])
		NSLog(@"No mail servers for domain %@", domain);
	
	return sent;
}

- (BOOL)sendMail:(NSData*)mail to:(NSString*)to from:(NSString*)from usingServer:(NSString*)server onPort:(int)port
{
	BOOL	sent = NO;
	
	if(server && [self _connectToServer:server onPort:port])
	{
		if([self _writeEnvelopeTo:to from:from])
			sent = [self _writeContent:mail];
	}
	
	return sent;
}

@end

@implementation SMTPMailDelivery(Private)

- (BOOL)_connectToServer:(NSString*)server onPort:(int)port
{
	struct sockaddr_in	serverSockAddr;
	in_addr_t			hostAddr;
	struct hostent		*serverHostEnt;
	int					err;
	int					n;
	char				buffer[512+1];

	// Close down any previous connection
	[self _closeConnection];
	
	memset(&serverSockAddr, 0, sizeof(serverSockAddr));
	err = 0;
	
	// Get IP address of server
	hostAddr = inet_addr([server cString]);
	if(hostAddr != INADDR_NONE)
	{
		serverSockAddr.sin_addr.s_addr = hostAddr;
		serverSockAddr.sin_family = AF_INET;
	}
	else
	{
		// Lookup host by name to get the IP
		serverHostEnt = gethostbyname([server cString]);
		if(serverHostEnt)
		{
			memcpy(&serverSockAddr.sin_addr, serverHostEnt->h_addr, serverHostEnt->h_length);
			serverSockAddr.sin_family = serverHostEnt->h_addrtype;
		}
		else
		{
			err++;
			NSLog(@"Could not locate server: %@", server);
		}
	}

	if(err == 0)
	{
		// Create a socket for communicating with the server on the specified port (25 is default smtp)
		serverSockAddr.sin_port = htons(port);
		_serverSocket = socket(AF_INET, SOCK_STREAM, 0);
		if(!(_serverSocket > 0))
		{
			err++;
			NSLog(@"Failed to create socket: %d", errno);
		}
	}
	
	if(err == 0)
	{
		// Open a connection to the server
		if(connect(_serverSocket, (struct sockaddr*)&serverSockAddr, sizeof(serverSockAddr)) == -1)
		{
			err++;
			NSLog(@"Failed to connect to server: %d", errno);
		}
	}
	
	if(err == 0)
	{
		// Handshake with the server
		n = read(_serverSocket, buffer, 512);
		buffer[n] = 0;
#if DEBUG
		NSLog(@"<- %s", buffer);
#endif
		if([[NSString stringWithCString:buffer] hasPrefix:@"220"])
		{
			char	hostname[256];
			
			// Greet the server
			if(gethostname(hostname, 256) == 0)
				sprintf(buffer, "HELO %s\r\n", hostname);
			else
				strcpy(buffer, "HELO localhost\r\n");
			write(_serverSocket, buffer, strlen(buffer));
#if DEBUG
			NSLog(@"-> %s", buffer);
#endif

			// Await accept from the server
			n = read(_serverSocket, buffer, 512);
			buffer[n] = 0;
#if DEBUG
			NSLog(@"<- %s", buffer);
#endif
			if([[NSString stringWithCString:buffer] hasPrefix:@"250"])
				_isConnected = YES;
			else
				NSLog(@"Unexpected greeting reply from server:\n  %s", buffer);
		}
		else
			NSLog(@"Unexpected connection reply from server:\n  %s", buffer);
	}
	
	return err == 0 ? _isConnected : NO;
}

- (void)_closeConnection
{
	if(_serverSocket != -1)
	{
		shutdown(_serverSocket,2);
		close(_serverSocket);
		_serverSocket = -1;
	}
}

- (BOOL)_writeEnvelopeTo:(NSString*)to from:(NSString*)from
{
	int					err = 0;
	int					n;
	char				buffer[512+1];
	BOOL				success = NO;
	
	// Set the sender
	sprintf(buffer, "MAIL FROM:<%s>\r\n", [from cString]);
	if((n = write(_serverSocket, buffer, strlen(buffer))) < 0)
		err++;
#if DEBUG
	NSLog(@"-> %s", buffer);
#endif
	if(err == 0)
	{
		// Await accept from the server
		n = read(_serverSocket, buffer, 512);
		buffer[n] = 0;
#if DEBUG
		NSLog(@"<- %s", buffer);
#endif
		if(![[NSString stringWithCString:buffer] hasPrefix:@"250"])
		{
			err++;
			NSLog(@"Sender not accepted by server:\n  %s", buffer);
		}
	}
	
	if(err == 0)
	{
		// Set the recipient
		sprintf(buffer, "RCPT TO:<%s>\r\n", [to cString]);
		if((n = write(_serverSocket, buffer, strlen(buffer))) < 0)
			err++;
#if DEBUG
		NSLog(@"-> %s", buffer);
#endif
		if(err == 0)
		{
			// Await accept from the server
			n = read(_serverSocket, buffer, 512);
			buffer[n] = 0;
#if DEBUG
			NSLog(@"<- %s", buffer);
#endif
			if([[NSString stringWithCString:buffer] hasPrefix:@"250"] ||
			   [[NSString stringWithCString:buffer] hasPrefix:@"251"])
				success = YES;
			else
				NSLog(@"Recipient not accepted by server:\n  %s", buffer);
		}
	}
	
	return success;
}

- (BOOL)_writeContent:(NSData*)content
{
	int					err = 0;
	int					n;
	char				buffer[512+1];
	BOOL				success = NO;
	
	// Set the sender
	strcpy(buffer, "DATA\r\n");
	if((n = write(_serverSocket, buffer, strlen(buffer))) < 0)
		err++;
#if DEBUG
	NSLog(@"-> %s", buffer);
#endif
	if(err == 0)
	{
		// Await accept from the server
		n = read(_serverSocket, buffer, 512);
		buffer[n] = 0;
#if DEBUG
		NSLog(@"<- %s", buffer);
#endif
		if(![[NSString stringWithCString:buffer] hasPrefix:@"354"])
		{
			err++;
			NSLog(@"Server not accepting data:\n  %s", buffer);
		}
	}
	
	if(err == 0)
	{
		// Send the mail content XXX
		if((n = write(_serverSocket, [content bytes], [content length])) < 0)
		{
			err++;
			NSLog(@"Error sending mail content: %d", errno);
		}
	}
	
	if(err == 0)
	{
		strcpy(buffer, "\r\n.\r\n");
		if((n = write(_serverSocket, buffer, strlen(buffer))) < 0)
		{
			err++;
			NSLog(@"Error sending mail content: %d", errno);
		}
		
#if DEBUG
		NSLog(@"-> %s", buffer);
#endif
		if(err == 0)
		{
			// Await accept from the server
			n = read(_serverSocket, buffer, 512);
			buffer[n] = 0;
#if DEBUG
			NSLog(@"<- %s", buffer);
#endif
			if([[NSString stringWithCString:buffer] hasPrefix:@"250"])
			{
				success = YES;
			}
			else
			{
				NSLog(@"Error sending mail content:\n  %s", buffer);
#if DEBUG
				[content writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"badmailcontent.txt"] atomically:YES];
#endif
			}
		}
	}			
	
	return success;
}

- (NSArray*)_mailServersForDomain:(NSString*)domain
{
	querybuf		answer;
	int				i, j, n;
	unsigned char	*eom = NULL, *cp = NULL;
	char			*bp;
	int				qdCount, anCount, bufLen;
	NSMutableArray	*mailExchangers = nil;
	BOOL			valid = NO;
	int				nmx = 0;
	unsigned short	prefs[MAXMXHOSTS];
	int				weight[MAXMXHOSTS];
	char			*mxhosts[MAXMXHOSTS];
	unsigned short	pref, type;
	int				ttl = 0;

	n = res_query([domain cString], C_IN, T_MX, answer.qb2, sizeof(answer));
	if(n > 0)
	{
		if(n > sizeof(answer))
			n = sizeof(answer);
		
		// Find first satisfactory answer
		valid = YES;
		cp = answer.qb2 + HFIXEDSZ;
		eom = answer.qb2 + n;
		for(qdCount = ntohs((unsigned short)answer.qb1.qdcount); qdCount--; cp += n + QFIXEDSZ)
		{
			if ((n = dn_skipname(cp, eom)) < 0)
			{
				valid = NO;
				break;
			}
		}
	}
	
	if(valid)
	{
		bufLen = sizeof(MXHostBuf) - 1;
		bp = MXHostBuf;
		anCount = ntohs((unsigned short)answer.qb1.ancount);

		while (--anCount >= 0 && cp < eom && nmx < MAXMXHOSTS - 1)
		{
			if ((n = dn_expand(answer.qb2, eom, cp, (char*) bp, bufLen)) < 0)
				break;
			cp += n;
			type = _getshort(cp);
			cp += INT16SZ;
			cp += INT16SZ;		/* skip over class */
			ttl = _getlong(cp);
			cp += INT32SZ;
			n = _getshort(cp);
			cp += INT16SZ;
			if (type != T_MX)
			{
				cp += n;
				continue;
			}
			pref = _getshort(cp);
			cp += INT16SZ;
			if ((n = dn_expand(answer.qb2, eom, cp, (char*) bp, bufLen)) < 0)
				break;
			cp += n;
			n = strlen(bp);
			weight[nmx] = rand();
			prefs[nmx] = pref;
			mxhosts[nmx++] = bp;
			bp += n;
			if (bp[-1] != '.')
			{
				*bp++ = '.';
				n++;
			}
			*bp++ = '\0';
			if (bufLen < n + 1)
			{
				/* don't want to wrap buflen */
				break;
			}
			bufLen -= n + 1;
		}

		/* sort the records */
		for (i = 0; i < nmx; i++)
		{
			for (j = i + 1; j < nmx; j++)
			{
				if (prefs[i] > prefs[j] ||
					(prefs[i] == prefs[j] && weight[i] > weight[j]))
				{
					int temp;
					char *temp1;
					
					temp = prefs[i];
					prefs[i] = prefs[j];
					prefs[j] = temp;
					temp1 = mxhosts[i];
					mxhosts[i] = mxhosts[j];
					mxhosts[j] = temp1;
					temp = weight[i];
					weight[i] = weight[j];
					weight[j] = temp;
				}
			}
		}
		
		/* delete duplicates from list (yes, some bozos have duplicates) */
		for (i = 0; i < nmx - 1; )
		{
			if (strcasecmp(mxhosts[i], mxhosts[i + 1]) != 0)
				i++;
			else
			{
				/* compress out duplicate */
				for (j = i + 1; j < nmx; j++)
				{
					mxhosts[j] = mxhosts[j + 1];
					prefs[j] = prefs[j + 1];
				}
				nmx--;
			}
		}
		
		if(nmx)
		{
			mailExchangers = [NSMutableArray arrayWithCapacity:nmx];
			for(i = 0; i < nmx; i++)
				[mailExchangers addObject:[NSString stringWithCString:mxhosts[i]]];
		}
	}
	
	return mailExchangers;
}

+ (NSData*)_header:(NSString*)header withValue:(NSString*)value
{
	NSString			*temp;
	NSStringEncoding	encoding;
	
	encoding = [self _encodingForString:value];
	if(encoding != NSASCIIStringEncoding)
	{
		NSString	*encodingName;
		NSData		*encodedPart;
		
		encodingName = [self _mimeNameForEncoding:encoding];
		// XXX should check for ISO-8859-x for 'Q' encoding
		
		encodedPart = [value dataUsingEncoding:encoding allowLossyConversion:YES];
		encodedPart = [self _encodeBase64:encodedPart lineLength:0];
		
		// Encode using Base64 encoding
		value = [NSString stringWithFormat:@"=?%@?B?%@?=",
			encodingName,
			[[[NSString alloc] initWithData:encodedPart encoding:NSASCIIStringEncoding] autorelease]];
	}
	
	temp = [NSString stringWithFormat:@"%@: %@\r\n", header, value];
	return [temp dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
}

+ (NSStringEncoding)_encodingForString:(NSString*)string
{
	NSStringEncoding	encoding[] = { 
		NSASCIIStringEncoding, 
		NSISOLatin1StringEncoding,
		NSISOLatin2StringEncoding, 
		CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin3),
		CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin4),
		CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinCyrillic),
		CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinArabic),
		CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinGreek),
		CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinHebrew),
		CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin5),
		CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin6),
		CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinThai),
		CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin7),
		CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin8),
		CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin9),
		CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingKOI8_R),
		CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingHZ_GB_2312),
		NSISO2022JPStringEncoding,
		NSUTF8StringEncoding,
		0 };
	int				i;

	for(i = 0; encoding[i]; i++)
	{
		if([string canBeConvertedToEncoding:encoding[i]])
			return encoding[i];
	}
	
	// Couldn't find a suitable encoding - return something "meaningful"
	return NSUTF8StringEncoding;
}

+ (NSString*)_mimeNameForEncoding:(NSStringEncoding)encoding
{
	NSDictionary *mimeNames = [NSDictionary dictionaryWithObjectsAndKeys:
		@"US-ASCII", [NSString stringWithFormat:@"%d", NSASCIIStringEncoding],
		@"ISO-8859-1", [NSString stringWithFormat:@"%d", NSISOLatin1StringEncoding],
		@"ISO-8859-2", [NSString stringWithFormat:@"%d", NSISOLatin2StringEncoding],
		@"ISO-8859-3", [NSString stringWithFormat:@"%d", CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin3)],
		@"ISO-8859-4", [NSString stringWithFormat:@"%d", CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin4)],
		@"ISO-8859-5", [NSString stringWithFormat:@"%d", CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinCyrillic)],
		@"ISO-8859-6", [NSString stringWithFormat:@"%d", CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinArabic)],
		@"ISO-8859-7", [NSString stringWithFormat:@"%d", CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinGreek)],
		@"ISO-8859-8", [NSString stringWithFormat:@"%d", CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinHebrew)],
		@"ISO-8859-9", [NSString stringWithFormat:@"%d", CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin5)],
		@"ISO-8859-10", [NSString stringWithFormat:@"%d", CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin6)],
		@"ISO-8859-11", [NSString stringWithFormat:@"%d", CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinThai)],
		@"ISO-8859-13", [NSString stringWithFormat:@"%d", CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin7)],
		@"ISO-8859-14", [NSString stringWithFormat:@"%d", CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin8)],
		@"ISO-8859-15", [NSString stringWithFormat:@"%d", CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin9)],
		@"KOI8-R", [NSString stringWithFormat:@"%d", CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingKOI8_R)],
		@"HZ-GB-2312", [NSString stringWithFormat:@"%d", CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingHZ_GB_2312)],
		@"ISO-2022-JP", [NSString stringWithFormat:@"%d", NSISO2022JPStringEncoding],
		@"UTF-8", [NSString stringWithFormat:@"%d", NSUTF8StringEncoding],
		nil];
	
	return [mimeNames objectForKey:[NSString stringWithFormat:@"%d", encoding]];
}

+ (NSData*)_encodeBase64:(NSData*)theData lineLength:(int)numChars
{
	NSData *result;
	const char *inBytes = [theData bytes];
	const char *inBytesPtr = inBytes;
	int inLength = [theData length];
	
	char *outBytes = malloc(sizeof(char)*inLength*2);
	char *outBytesPtr = outBytes;
	
	int numWordsPerLine = numChars/4;
	int wordCounter = 0;
	
	// We memset 0 our buffer so with are sure to not have
	// any garbage in it.
	memset(outBytes, 0, sizeof(char)*inLength*2);
	
	while (inLength > 0)
    {
		base64ChunkFor3Characters(outBytesPtr, inBytesPtr, inLength);
		outBytesPtr += 4;
		inBytesPtr += 3;
		inLength -= 3;
		
		wordCounter ++;
		
		if (numChars && wordCounter == numWordsPerLine)
		{
			wordCounter = 0;
			*outBytesPtr++ = '\r';
			*outBytesPtr++ = '\n';
		}
    }
	
	result = [[NSData alloc] initWithBytesNoCopy: outBytes
										  length: (outBytesPtr-outBytes)];
	
	return [result autorelease];
}

+ (NSMutableData *)_replaceLFWithCRLFforMessage:(NSData*)message
{
	NSMutableData *aMutableData;
	unsigned char *bytes, *bi, *bo;
	int delta, i, length;

	//
	// According to RFC 2821 section 4.1.1.4, all bare <LF> must be
	// converted to <CRLF>. 
	//
	
	bi = bytes = (unsigned char*)[message bytes];
	length = [message length];
	delta = 0;
	
	if ( bi[0] == '\n' )
    {
		delta++;
    }
	
	bi++;
	
	for (i = 1; i < length; i++, bi++)
    {
		if ( (bi[0] == '\n') && (bi[-1] != '\r') )
		{
			delta++;
		}
    }
	
	bi = bytes;
	aMutableData = [[NSMutableData alloc] initWithLength: (length+delta)];
	bo = [aMutableData mutableBytes];
	
	for (i = 0; i < length; i++, bi++, bo++)
    {
		if ( (i+1 < length) && (bi[0] == '\r') && (bi[1] == '\n') )
		{
			*bo = *bi;
			bo++;
			bi++;
			i++;
		}
		else if ( *bi == '\n' )
		{
			*bo = '\r';
			bo++;
		}
		
		*bo = *bi;
    }
	
	return [aMutableData autorelease];
}

+ (void)_encodeLeadingPeriods:(NSMutableData*)data
{
	NSRange		range;
	unsigned	length;
	unsigned	i;
	char		*bytes;
	
	//
	// According to RFC 2821 section 4.5.2, we must check for the character
	// sequence "<CRLF>.<CRLF>"; any occurrence have its period duplicated
	// to avoid data transparency. 
	//

	// Special case for the first line since it have no preceding <CRLF>
	if(((char*)[data bytes])[0] == '.')
	{
		range = NSMakeRange(0, 1);
		[data replaceBytesInRange:range withBytes:".." length:2];
	}
	
	length = [data length];
	bytes = [data mutableBytes];
	
	// Run through the message looking for leading periods.
	// If any is found add another
	for(i = 2; i < length; i++)
	{
		if((bytes[i] == '.') && (bytes[i-1] == '\n') && (bytes[i-2] == '\r'))
		{
			range = NSMakeRange(i, 1);
			[data replaceBytesInRange:range withBytes:".." length:2];
			length++;
		}
	}
}

@end

static char basis_64[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

void base64ChunkFor3Characters(char *buf, const char *inBuf, int numChars)
{
	if (numChars >= 3)
    {
		buf[0] = basis_64[inBuf[0]>>2 & 0x3F];
		buf[1] = basis_64[(((inBuf[0] & 0x3)<< 4) | ((inBuf[1] & 0xF0) >> 4)) & 0x3F];
		buf[2] = basis_64[(((inBuf[1] & 0xF) << 2) | ((inBuf[2] & 0xC0) >>6)) & 0x3F];
		buf[3] = basis_64[inBuf[2] & 0x3F];
    }
	else if(numChars == 2)
    {
		buf[0] = basis_64[inBuf[0]>>2 & 0x3F];
		buf[1] = basis_64[(((inBuf[0] & 0x3)<< 4) | ((inBuf[1] & 0xF0) >> 4)) & 0x3F];
		buf[2] = basis_64[(((inBuf[1] & 0xF) << 2) | ((0 & 0xC0) >>6)) & 0x3F];
		buf[3] = '=';
    }
	else
    {
		buf[0] = basis_64[inBuf[0]>>2 & 0x3F];
		buf[1] = basis_64[(((inBuf[0] & 0x3)<< 4) | ((0 & 0xF0) >> 4)) & 0x3F];
		buf[2] = '=';
		buf[3] = '=';
    }
}
