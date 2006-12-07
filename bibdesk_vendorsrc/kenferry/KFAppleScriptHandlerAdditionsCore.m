//
// KFAppleScriptHandlerAdditionsCore.m
// KFAppleScriptHandlerAdditions v. 2.3, 12/31, 2004
//
// Copyright (c) 2003-2004 Ken Ferry. Some rights reserved.
// http://homepage.mac.com/kenferry/software.html
//
// This work is licensed under a Creative Commons license:
// http://creativecommons.org/licenses/by-nc/1.0/
//
// Send me an email if you have any problems (after you've read what there is to read).


#import "KFAppleScriptHandlerAdditionsCore.h"
#import "KFASHandlerAdditions-TypeTranslation.h"

// these are from the OpenScripting carbon framework, but I'd rather not require linking it
#ifndef kASSubroutineEvent
#define kASSubroutineEvent 'psbr'
#endif
#ifndef kASPrepositionalSubroutine
#define kASPrepositionalSubroutine 'psbr'
#endif
#ifndef kASAppleScriptSuite
#define kASAppleScriptSuite 'ascr'
#endif
#ifndef keyASSubroutineName
#define keyASSubroutineName 'snam'
#endif
#ifndef keyASUserRecordFields
#define keyASUserRecordFields 'usrf'
#endif
#ifndef keyASPrepositionGiven
#define keyASPrepositionGiven 'givn'
#endif

NSString *KFASException = @"KFASException";

@implementation NSAppleScript (KFAppleScriptHandlerAdditions)

// All other execute methods cascade down to this or the next one.
- (NSAppleEventDescriptor *)kfExecuteWithoutTranslationHandler:(NSString *)handlerName
                                                         error:(NSDictionary **)errorInfo
                                            withParametersDesc:(NSAppleEventDescriptor *)argumentsDesc
{
    NSAppleEventDescriptor* event;
    NSAppleEventDescriptor* targetAddress;
    NSAppleEventDescriptor* subroutineDescriptor;
    NSAppleEventDescriptor* resultDesc;
    
    int pid = [[NSProcessInfo processInfo] processIdentifier];
    targetAddress = [NSAppleEventDescriptor descriptorWithDescriptorType:typeKernelProcessID
                                                                   bytes:&pid
                                                                  length:sizeof(pid)];
    event = [[NSAppleEventDescriptor alloc] initWithEventClass:kASAppleScriptSuite
                                                       eventID:kASSubroutineEvent
                                              targetDescriptor:targetAddress
                                                      returnID:kAutoGenerateReturnID
                                                 transactionID:kAnyTransactionID];
    
    // set up the handler
    subroutineDescriptor = [NSAppleEventDescriptor descriptorWithString:[handlerName lowercaseString]];
    [event setParamDescriptor:subroutineDescriptor  forKeyword:keyASSubroutineName];
    
    // set up the arguments
    [event setParamDescriptor:argumentsDesc forKeyword:keyDirectObject];
    
    // execute
    resultDesc = [self executeAppleEvent:event error:errorInfo];
    
    // cleanup
    [event release];
    
    return(resultDesc);
}

// for routines with labeled parameters
- (NSAppleEventDescriptor *)kfExecuteWithoutTranslationHandler:(NSString *)handlerName
													   eventID:(AEEventID)eventID
													 fromSuite:(AEEventClass)suiteID
                                                         error:(NSDictionary **)errorInfo
												withFirstLabel:(AEKeyword)aKeyWord
										   parametersAndLabels:(va_list)anArgList
{
    NSAppleEventDescriptor* event;
    NSAppleEventDescriptor* targetAddress;
    NSAppleEventDescriptor* resultDesc;
    
    int pid = [[NSProcessInfo processInfo] processIdentifier];
    targetAddress = [NSAppleEventDescriptor descriptorWithDescriptorType:typeKernelProcessID
                                                                   bytes:&pid
                                                                  length:sizeof(pid)];
    event = [[NSAppleEventDescriptor alloc] initWithEventClass:suiteID
                                                       eventID:eventID
                                              targetDescriptor:targetAddress
                                                      returnID:kAutoGenerateReturnID
                                                 transactionID:kAnyTransactionID];
    
    // set up the handler
	if ( handlerName != nil )
	{
		NSAppleEventDescriptor* subroutineDescriptor = [NSAppleEventDescriptor descriptorWithString:[handlerName lowercaseString]];
		[event setParamDescriptor:subroutineDescriptor  forKeyword:keyASSubroutineName];
    }
	
    // set up the arguments
	do
	{
		id theObject = va_arg( anArgList, id );

		if( aKeyWord == keyASPrepositionGiven )
		{
			NSAppleEventDescriptor *theUserRecord = [NSAppleEventDescriptor listDescriptor];
			if( theUserRecord )
			{
				unsigned int theIndex = 1;
				do
				{
					NSString* theKey = va_arg( anArgList, id );
					NSParameterAssert( theKey != nil );
					[theUserRecord insertDescriptor:[[theKey description] aeDescriptorValue] atIndex:theIndex++];
					[theUserRecord insertDescriptor:[theObject aeDescriptorValue] atIndex:theIndex++];
				}
				while( (theObject = va_arg( anArgList, id ) ) != nil );
			}

			[event setParamDescriptor:[theUserRecord aeDescriptorValue] forKeyword:keyASUserRecordFields];
			break; // all the arguments have been passed
		}
		else
			[event setParamDescriptor:[theObject aeDescriptorValue] forKeyword:aKeyWord];
	}
	while( (aKeyWord = va_arg( anArgList, AEKeyword ) ) != nil );
    
    // execute
    resultDesc = [self executeAppleEvent:event error:errorInfo];
    
    // cleanup
    [event release];
    
    return(resultDesc);
}

// probably could use a little work.  Don't currently use NSAppleScriptErrorRange, code could be tighter.
- (void)kfHandleASError:(NSDictionary *)error
{
    if (error != nil)
    {
        NSString *errorMessage, *briefErrorMessage, *reason;
        NSNumber *errorNumber;
        
        if ((errorMessage = [error objectForKey:NSAppleScriptErrorMessage]) != nil)
        {
            reason = errorMessage;
        }
        else if ((briefErrorMessage = [error objectForKey:NSAppleScriptErrorBriefMessage]) != nil)
        {
            reason = briefErrorMessage;
        }
        else if ((errorNumber = [error objectForKey:NSAppleScriptErrorNumber]) != nil)
        {
            reason = [NSString stringWithFormat:@"Error number %@.", errorNumber];
        }
        else
        {
            reason = @"AppleScript error, no further info.";
        }
        
        NSException *exception = [NSException exceptionWithName:KFASException
                                                         reason:reason
                                                       userInfo:error];
        [exception raise];
    }
}

// these next four execute methods make up the recommended API for subroutines with positional parameters.
// Each calls upon the next and the last calls kfExecuteWithoutTranslationHandler:error:withParametersDesc:.
- (id)executeHandler:(NSString *)handlerName
{
    return([self executeHandler:handlerName
                 withParameters:nil]);
}

- (id)executeHandler:(NSString *)handlerName
       withParameter:(id)arg
{
    if (arg == nil)
    {
        [NSException raise:NSInvalidArgumentException format:@"Parameter cannot be nil."];
    }
    
    return([self executeHandler:handlerName
                 withParameters:arg, nil]);
}

- (id)executeHandler:(NSString *)handlerName
      withParameters:(id)firstArg, ...
{
    NSMutableArray *argumentsArray;
    va_list argList;
    id anArg;
    
    argumentsArray = [NSMutableArray array];
    if (firstArg != nil)
    {
        [argumentsArray addObject:firstArg];
        va_start(argList, firstArg);
        while((anArg = va_arg(argList, id)) != nil)
            [argumentsArray addObject:anArg];
        va_end(argList);
    }
    
    return([self executeHandler:handlerName
        withParametersFromArray:argumentsArray]);
}

- (id)executeHandler:(NSString *)handlerName
withParametersFromArray:(NSArray *)argumentsArray
{
    NSAppleEventDescriptor *resultDesc;
    NSDictionary *errorInfo = nil;
    resultDesc = [self kfExecuteWithoutTranslationHandler:handlerName
                                                    error:&errorInfo
                                       withParametersDesc:[argumentsArray aeDescriptorValue]];
    if (errorInfo != nil)
    {
        [self kfHandleASError:errorInfo];
    }
    
    return([resultDesc objCObjectValue]);
}

// these next four execute methods make up the recommended API for subroutines with labeled parameters.
// The first and third one call upon the next which calls kfExecuteWithoutTranslationHandler:eventID:fromSuite:error:withFirstLabel:parametersAndLabels:.
- (id)executeHandler:(NSString *)handlerName
		   withLabel:(AEKeyword)keyWord
		andParameter:(id)arg
{
    if (arg == nil)
    {
        [NSException raise:NSInvalidArgumentException format:@"Parameter cannot be nil."];
    }
    
    return([self executeHandler:handlerName
		withLabelsAndParameters:keyWord, arg, nil]);
}

- (id)executeHandler:(NSString *)handlerName
withLabelsAndParameters:(AEKeyword)firstKeyWord, ...
{
    NSAppleEventDescriptor* resultDesc;
    NSDictionary* errorInfo = nil;
	va_list	theArgList;
	va_start( theArgList, firstKeyWord );
    resultDesc = [self kfExecuteWithoutTranslationHandler:handlerName
												  eventID:kASPrepositionalSubroutine
												fromSuite:kASAppleScriptSuite
                                                    error:&errorInfo
										   withFirstLabel:firstKeyWord
									  parametersAndLabels:theArgList];
	va_end( theArgList );
    if (errorInfo != nil)
    {
        [self kfHandleASError:errorInfo];
    }
    
    return([resultDesc objCObjectValue]);
}

- (id)executeHandler:(AEEventID)handlerID
		   fromSuite:(AEEventClass)suiteID
		   withLabel:(AEKeyword)keyWord
		andParameter:(id)arg
{
    if (arg == nil)
    {
        [NSException raise:NSInvalidArgumentException format:@"Parameter cannot be nil."];
    }
    
    return([self executeHandler:handlerID
					  fromSuite:suiteID
		withLabelsAndParameters:keyWord, arg, nil]);
}

- (id)executeHandler:(AEEventID)handlerID
		   fromSuite:(AEEventClass)suiteID
withLabelsAndParameters:(AEKeyword)firstKeyWord, ...
{
    NSAppleEventDescriptor* resultDesc;
    NSDictionary* errorInfo = nil;
	va_list	theArgList;
	va_start( theArgList, firstKeyWord );
    resultDesc = [self kfExecuteWithoutTranslationHandler:nil
												  eventID:handlerID
												fromSuite:suiteID
                                                    error:&errorInfo
										   withFirstLabel:firstKeyWord
									  parametersAndLabels:theArgList];
	va_end( theArgList );
    if (errorInfo != nil)
    {
        [self kfHandleASError:errorInfo];
    }
    
    return([resultDesc objCObjectValue]);
}

// compatibility methods.  It'd be a little strong to call these deprecated, but I think 
// the above batch are more convenient.  Who wants to deal with an error dictionary?  
// Exceptions are much nicer, and you can retrieve the error dict with -[NSException userInfo]
// if you want.
//
// Each method here calls the next, and the last calls up to executeHandler:withParametersFromArray:.
// Thus changes made to the recommended methods will effect the compatibility methods.

- (id)executeHandler:(NSString *)handlerName
               error:(NSDictionary **)errorInfo
{
    return([self executeHandler:handlerName
                          error:errorInfo
                 withParameters:nil]);
}

- (id)executeHandler:(NSString *)handlerName
               error:(NSDictionary **)errorInfo
       withParameter:(id)arg
{
    return([self executeHandler:handlerName
                          error:errorInfo
                 withParameters:arg, nil]);
}

- (id)executeHandler:(NSString *)handlerName
               error:(NSDictionary **)errorInfo
      withParameters:(id)firstArg, ...
{
    NSMutableArray *argumentsArray;
    va_list argList;
    id anArg;
    
    argumentsArray = [NSMutableArray array];
    if (firstArg != nil)
    {
        [argumentsArray addObject:firstArg];
        va_start(argList, firstArg);
        while((anArg = va_arg(argList, id)) != nil)
            [argumentsArray addObject:anArg];
        va_end(argList);
    }

    return([self executeHandler:handlerName
                          error:errorInfo
        withParametersFromArray:argumentsArray]);
}

- (id)executeHandler:(NSString *)handlerName
               error:(NSDictionary **)errorInfo
withParametersFromArray:(NSArray *)argumentsArray
{
    NSAppleEventDescriptor *resultDesc = nil;
    
    // If we use @try @catch it is necessary to use -fobjc-exceptions.
    // Save some email by using the old style exception handling.
    NS_DURING
        resultDesc = [self executeHandler:handlerName
                  withParametersFromArray:argumentsArray];
    NS_HANDLER
        if ([[localException name] isEqualToString:KFASException])
        {
            *errorInfo = [localException userInfo];
        }
        else
        {
            [localException raise];
        }
    NS_ENDHANDLER
    
    
    return resultDesc;
}

@end
