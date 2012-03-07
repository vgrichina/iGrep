//
//  DocumentsIndex.h
//  DocumentSearch
//
//  Created by Vladimir Grichina on 04.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Document.h"

typedef enum {
    DocumentsIndexSearchOrderDate = 0,
    DocumentsIndexSearchOrderTfIdf
} DocumentsIndexSearchOrder;

@interface DocumentsIndex : NSObject

- (BOOL)addDocument:(Document *)document;

- (NSArray *)searchDocuments:(NSString *)query order:(DocumentsIndexSearchOrder)order;

- (NSArray *)searchDocumentsWithTerms:(NSArray *)queryTerms order:(DocumentsIndexSearchOrder)order;

@end
