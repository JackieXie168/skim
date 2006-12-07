//
//  SLFolderItem.h
//  Science Library
//
//  Created by Kurt Marek on Sun Jul 20 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ImageAndTextCell;


@interface SLFolderItem : NSObject {
    
    NSString *folderName;
    NSMutableArray *articleListArray;
    BOOL editable;
}

-(BOOL) editable;
-(void) setEditable:(BOOL)editYN;

- (NSString *) folderName;
- (void) setFolderName:(NSString *)newFolderName;

- (NSMutableArray *) articleListArray;
- (void) setArticleListArray:(NSMutableArray *)newArticleListArray;

- (void) encodeWithCoder:(NSCoder *)coder;
- (id) initWithCoder:(NSCoder *) coder;

@end
