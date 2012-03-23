//
//  CXSqliteDocumentsIndex.h
//  iGrep
//
//  Created by Vladimir Grichina on 07.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CXDocumentsIndex.h"

#import <sqlite3.h>

@interface CXSqliteDocumentsIndex : CXDocumentsIndex {
    sqlite3 *db;
    sqlite3_stmt *selectTermStmt;
    sqlite3_stmt *insertTermStmt;
    sqlite3_stmt *updateTermStmt;
    sqlite3_stmt *insertDocumentTermStmt;

    NSMutableDictionary *termsCache;
}

- (id)initWithDatabase:(NSString *)database;

@end
