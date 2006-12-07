//
//  BDSKScriptHook.h
//  Bibdesk
//
//  Created by Christiaan Hofman on 17/10/05.
/*
 This software is Copyright (c) 2005,2006
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

@class BibDocument;

@interface BDSKScriptHook : NSObject {
	NSString *name;
	NSNumber *uniqueID;
	NSAppleScript *script;
	NSString *field;
	NSArray *oldValues;
	NSArray *newValues;
    BibDocument *document;
}

/*!
	@method initWithName:scriptPath:
	@abstract Initializes and returns a new script hook instance with a name and script. 
	@discussion This is the designated initializer. Returns nil if there is no script.
	@param aName The name for the script hook.
	@param aScript The script for the script hook.
*/
- (id)initWithName:(NSString *)aName script:(NSAppleScript *)aScript;

/*!
	@method name
	@abstract Returns the name of the script hook.
	@discussion -
*/
- (NSString *)name;

/*!
	@method uniqueID
	@abstract Returns the unique ID of the script hook.
	@discussion -
*/
- (NSNumber *)uniqueID;

/*!
	@method field
	@abstract Returns the field name for the script hook event.
	@discussion -
*/
- (NSString *)field;

/*!
	@method setField:
	@abstract Set the field name for the script hook event.
	@discussion -
	@param newField The field name to set.
*/
- (void)setField:(NSString *)newField;

/*!
	@method oldValues
	@abstract Returns the array of old values for the field of the script hook event.
	@discussion -
*/
- (NSArray *)oldValues;

/*!
	@method setOldValue:
	@abstract Set the array of old values for the field of the script hook event.
	@discussion -
	@param values The array of values to set.
*/
- (void)setOldValues:(NSArray *)values;

/*!
	@method newValues
	@abstract Returns the array of new values for the field of the script hook event.
	@discussion -
*/
- (NSArray *)newValues;

/*!
	@method setNewValues:
	@abstract Set the array of new values for the field of the script hook event.
	@discussion -
	@param values The array of values to set.
*/
- (void)setNewValues:(NSArray *)values;

/*!
	@method document
	@abstract Returns the document of the script hook event.
	@discussion -
*/
- (BibDocument *)document;

/*!
	@method setDocument:
	@abstract Set the array of new values for the field of the script hook event.
	@discussion -
	@param values The array of values to set.
*/
- (void)setDocument:(BibDocument *)newDocument;

/*!
	@method script
	@abstract Returns the script to execute by the script hook.
	@discussion -
*/
- (NSAppleScript *)script;

/*!
	@method executeForPublications:
	@abstract Execute the script file for the script hook passing the publication.
	@discussion -
	@param items An array of publications passed to the script for the script hook.
	@result Boolean indicating whether the script was executed sucessfully. 
*/
- (BOOL)executeForPublications:(NSArray *)item document:(BibDocument *)aDocument;

@end
