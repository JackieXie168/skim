//
//  NSFileManager_SKExtendedAttributes.h
//
//  Created by Adam R. Maxwell on 05/12/05.
//  Copyright 2005-2008 Adam R. Maxwell. All rights reserved.
//
/*
 
 Redistribution and use in source and binary forms, with or without modification, 
 are permitted provided that the following conditions are met:
 - Redistributions of source code must retain the above copyright notice, this 
 list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or 
 other materials provided with the distribution.
 - Neither the name of Adam R. Maxwell nor the names of any contributors may be
 used to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>

typedef UInt32 BDSKXattrFlags;
enum {
    kBDSKXattrDefault     = 0,       /* create or replace, follow symlinks, split data    */
    kBDSKXattrNoFollow    = 1L << 1, /* don't follow symlinks                             */
    kBDSKXattrCreateOnly  = 1L << 2, /* setting will fail if the attribute already exists */
    kBDSKXattrReplaceOnly = 1L << 3, /* setting will fail if the attribute does not exist */
    kBDSKXattrNoSplitData = 1L << 4  /* don't split data objects into segments            */
};

/*!
    @category    NSFileManager (SKExtendedAttributes)
    @abstract    Provides an Objective-C wrapper for the low-level BSD functions dealing with file attributes.
    @discussion  (comprehensive description)
*/
@interface NSFileManager (SKExtendedAttributes)

/*!
    @method     extendedAttributeNamesAtPath:traverseLink:
    @abstract   Return a list of extended attributes for the given file.
    @discussion Calls <tt>listxattr(2)</tt> to determine all of the extended attributes, and returns them as
                an array of NSString objects.  Returns nil if an error occurs.    
    @param      path Path to the object in the file system.
    @param      follow Follow symlinks (<tt>listxattr(2)</tt> does this by default, so typically you should pass YES).
    @param      error Error object describing the error if nil was returned.
    @result     Array of strings or nil.
*/
- (NSArray *)extendedAttributeNamesAtPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;

/*!
    @method     extendedAttributeNamed:atPath:traverseLink:error:
    @abstract   Return the extended attribute named <tt>attr</tt> for a given file.
    @discussion Calls <tt>getxattr(2)</tt> to determine the extended attribute, and returns it as data.
    @param      attr The attribute name.
    @param      path Path to the object in the file system.
    @param      follow Follow symlinks (<tt>getxattr(2)</tt> does this by default, so typically you should pass YES).
    @param      error Error object describing the error if nil was returned.
    @result     Data object representing the extended attribute or nil if an error occurred.
*/
- (NSData *)extendedAttributeNamed:(NSString *)attr atPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;

/*!
    @method     allExtendedAttributesAtPath:traverseLink:error:
    @abstract   Returns all extended attributes for the given file, each as an NSData object.
    @discussion (comprehensive description)
    @param      path (description)
    @param      follow (description)
    @param      error (description)
    @result     (description)
*/
- (NSArray *)allExtendedAttributesAtPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;

/*!
    @method     propertyListFromExtendedAttributeNamed:atPath:traverseLink:error:
    @abstract   Returns a property list using NSPropertyListSerialization.
    @discussion (comprehensive description)
    @param      attr (description)
    @param      path (description)
    @param      traverse (description)
    @param      outError (description)
    @result     (description)
*/
- (id)propertyListFromExtendedAttributeNamed:(NSString *)attr atPath:(NSString *)path traverseLink:(BOOL)traverse error:(NSError **)outError;

/*!
    @method     setExtendedAttributeNamed:toValue:atPath:options:error:
    @abstract   Sets the value of attribute named <tt>attr</tt> to <tt>value</tt>, which is an NSData object.
    @discussion Calls <tt>setxattr(2)</tt> to set the attributes for the file.
    @param      attr The attribute name.
    @param      value The value of the attribute as NSData.
    @param      path Path to the object in the file system.
    @param      options see BDSKXattrFlags
    @param      error Error object describing the error if NO was returned.
    @result     Returns NO if an error occurred.
*/
- (BOOL)setExtendedAttributeNamed:(NSString *)attr toValue:(NSData *)value atPath:(NSString *)path options:(BDSKXattrFlags)options error:(NSError **)error;

/*!
    @method     setExtendedAttributeNamed:toPropertyListValue:atPath:options:error:
    @abstract   Sets the extended attribute named <tt>attr</tt> to the specified property list.  The plist is converted to NSData using NSPropertyListSerialization.
    @discussion (comprehensive description)
    @param      attr (description)
    @param      plist (description)
    @param      path (description)
    @param      options (description)
    @param      error (description)
    @result     (description)
*/
- (BOOL)setExtendedAttributeNamed:(NSString *)attr toPropertyListValue:(id)plist atPath:(NSString *)path options:(BDSKXattrFlags)options error:(NSError **)error;

/*!
    @method     removeExtendedAttribute:atPath:followLinks:error:
    @abstract   Removes the given attribute <tt>attr</tt> from the named file at <tt>path</tt>.
    @discussion Calls <tt>removexattr(2)</tt> to remove the given attribute from the file.
    @param      attr The attribute name.
    @param      path Path to the object in the file system.
    @param      follow Follow symlinks (<tt>removexattr(2)</tt> does this by default, so typically you should pass YES).
    @param      error Error object describing the error if nil was returned.
    @result     Returns NO if an error occurred.
*/
- (BOOL)removeExtendedAttribute:(NSString *)attr atPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;

/*!
    @method     removeAllExtendedAttributesAtPath:traverseLink:error:
    @abstract   Removes all extended attributes at the specified path.
    @discussion (comprehensive description)
    @param      path (description)
    @param      follow (description)
    @param      error (description)
    @result     (description)
*/
- (BOOL)removeAllExtendedAttributesAtPath:(NSString *)path traverseLink:(BOOL)follow error:(NSError **)error;

@end
