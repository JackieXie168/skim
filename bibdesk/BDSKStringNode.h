//
//  BDSKStringNode.h
//  Bibdesk
//
// Created by Michael McCracken, 2004
/*
 This software is Copyright (c) 2004,2005,2006
 Michael O. McCracken. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Michael O. McCracken nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>


typedef enum{
    BSN_STRING = 0,
    BSN_NUMBER = 1,
    BSN_MACRODEF = 2
} BDSKStringNodeType;

@interface BDSKStringNode : OFObject <NSCopying, NSCoding>{
    @public
    BDSKStringNodeType type; 
    NSString *value;
}

/*!
@method     nodeWithQuotedString:
 @abstract   Returns a newly allocated and initialized string node for a quoted string. The string is expected to be valid, i.e. it should not contain unbalanced braces. Error checking is not performed. 
 @discussion (description)
 @param		s The string value without the quotes. 
 @result     A newly allocated string node of string type. 
 */
+ (BDSKStringNode *)nodeWithQuotedString:(NSString *)s;

    /*!
        @method     nodeWithNumberString:
     @abstract   Returns a newly allocated and initialized string node for a raw number. The string is expected to be valid, i.e. it should contain only numbers. Error checking is not performed. 
     @discussion (description)
     @param		s The number value as a string. 
     @result     A newly allocated string node of number type. 
     */
+ (BDSKStringNode *)nodeWithNumberString:(NSString *)s;

    /*!
         @method     nodeWithMacroString:
     @abstract   Returns a newly allocated and initialized string node for a macro string. The string is expected to be valid, i.e. it should not contain special characters. Error checking is not performed. 
     @discussion (description)
     @param		s The macro string. 
     @result     A newly allocated string node of macro type. 
     */
+ (BDSKStringNode *)nodeWithMacroString:(NSString *)s;

    /*!
       @method     initWithQuotedString:
     @abstract   Returns a newly allocated and initialized string node for a quoted string. The string is expected to be valid, i.e. it should not contain unbalanced braces. Error checking is not performed.
     @discussion (comprehensive description)
     @param      s The string value without the quotes. 
     @result     A newly allocated string node of string type. 
     */
- (BDSKStringNode *)initWithQuotedString:(NSString *)s;

    /*!
        @method     initWithNumberString:
     @abstract   Returns a newly allocated and initialized string node for a raw number. The string is expected to be valid, i.e. it should contain only numbers. Error checking is not performed.
     @discussion (comprehensive description)
     @param      s The number value as a string. 
     @result     A newly allocated string node of number type. 
     */
- (BDSKStringNode *)initWithNumberString:(NSString *)s;

    /*!
         @method     initWithMacroString:
     @abstract   Returns a newly allocated and initialized string node for a quoted string. The string is expected to be valid, i.e. it should not contain unbalanced braces. Error checking is not performed.
     @discussion (comprehensive description)
     @param      s The string value without the quotes. 
     @result     A newly allocated string node of string type. 
     */
- (BDSKStringNode *)initWithMacroString:(NSString *)s;

    /*!
               @method     initWithType:value:
     @abstract   Initializes a new string node with the given type and value. This is the designated initializer.
     @discussion (description)
     @param		aType The type.
     @param		s The value string. 
     @result     An initialized string node. 
     */
- (id)initWithType:(BDSKStringNodeType)aType value:(NSString *)s;

    /*!
    @method     isEqual:
     @abstract   Returns YES if the receiver and the argument are a string nodes of the same type with equal values.  
     @discussion (description)
     @param		other The string node to compare with.
     @result     -
     */
- (BOOL)isEqual:(BDSKStringNode *)other;

    /*!
    @method     compareNode:
     @abstract   Invokes compareNode:options: with no options.
     @discussion (description)
     @param		aNode The string node to compare with.
     @result     -
     */
- (NSComparisonResult)compareNode:(BDSKStringNode *)aNode;

    /*!
          @method     compareNode:options:
     @abstract   Compares the receiver to aNode. First compares the type of the nodes, and for nodes of the same type, compares their values using mask for comparison options. 
     @discussion (description)
     @param		aNode The string node to compare with.
     @param		mask The search options used in the comparison. These are the same as for string compare methods. 
     @result     -
     */
- (NSComparisonResult)compareNode:(BDSKStringNode *)aNode options:(unsigned)mask;

    /*!
    @method     type
     @abstract   The type of the string node. This can be BSN_STRING, BSN_NUMBER, or BSN_MACRODEF. 
     @discussion (description)
     @result     -
     */
- (BDSKStringNodeType)type;

    /*!
    @method     value
     @abstract   The value of the string node. 
     @discussion (description)
     @result     -
     */
- (NSString *)value;

@end
