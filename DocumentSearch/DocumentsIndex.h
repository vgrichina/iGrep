//
//  DocumentsIndex.h
//  DocumentSearch
//
//  Created by Vladimir Grichina on 04.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <sqlite3.h>

#import "Document.h"

typedef enum {
    DocumentsIndexSearchOrderDate = 0,
    DocumentsIndexSearchOrderTfIdf
} DocumentsIndexSearchOrder;

@interface DocumentsIndex : NSObject {
    sqlite3 *db;
    sqlite3_stmt *selectTermStmt;
    sqlite3_stmt *insertTermStmt;
    sqlite3_stmt *updateTermStmt;
    sqlite3_stmt *insertDocumentTermStmt;

    NSMutableDictionary *termsCache;
}

- (id)initWithDatabase:(NSString *)database;
- (BOOL)addDocument:(Document *)document;

- (NSArray *)searchDocuments:(NSString *)query order:(DocumentsIndexSearchOrder)order;

@end
