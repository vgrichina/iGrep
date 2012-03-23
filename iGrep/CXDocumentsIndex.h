//
//  CXDocumentsIndex.h
//  iGrep
//
//  Created by Vladimir Grichina on 04.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CXDocument.h"

typedef enum {
    CXDocumentsIndexSearchOrderDate = 0,
    CXDocumentsIndexSearchOrderTfIdf
} CXDocumentsIndexSearchOrder;

@interface CXDocumentsIndex : NSObject

- (BOOL)addDocument:(CXDocument *)document;

- (NSArray *)searchDocuments:(NSString *)query order:(CXDocumentsIndexSearchOrder)order;

- (NSArray *)searchDocumentsWithTerms:(NSArray *)queryTerms order:(CXDocumentsIndexSearchOrder)order;

@end
