//
//  SLFolderItem.m
//  Science Library
//
//  Created by Kurt Marek on Sun Jul 20 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "SLFolderItem.h"
#import "ImageAndTextCell.h"

@implementation SLFolderItem

-(id) init {
    articleListArray=[[NSMutableArray alloc] init];
    folderName=[[NSString alloc] initWithString:@"New Folder"];
    [self setEditable:1];
    return self;
}

- (NSString *) folderName {
    return folderName;
}

- (void) setFolderName:(NSString *)newFolderName {
    [newFolderName retain];
    [folderName release];
    folderName=newFolderName;
}

- (NSMutableArray *) articleListArray {
    return articleListArray;
}

- (void) setArticleListArray:(NSMutableArray *)newArticleListArray {
    [newArticleListArray retain];
    [articleListArray release];
    articleListArray=newArticleListArray;
}

-(BOOL) editable {
    return editable;
}
-(void) setEditable:(BOOL)editYN {
    editable=editYN;
}


//Encoding Methods

- (void) encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:folderName forKey:@"folderName"];
    [coder encodeObject:articleListArray forKey:@"articleListArray"];   
    [coder encodeBool:editable forKey:@"editable"];
}

- (id) initWithCoder:(NSCoder *) coder {
    if (self=[super init]) {
        folderName=[[coder decodeObjectForKey:@"folderName"] retain];
        articleListArray=[[coder decodeObjectForKey:@"articleListArray"] retain];
	editable=[coder decodeBoolForKey:@"editable"];
    }
    return self;
}


@end
