//
//  DocumentsIndex.m
//  DocumentSearch
//
//  Created by Vladimir Grichina on 04.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DocumentsIndex.h"

#import "MACollectionUtilities.h"

static BOOL IsOk(sqlite3 *db, int result) {
    if (result != SQLITE_OK) {
        NSLog(@"Database error: %s", sqlite3_errmsg(db));
        return NO;
    }

    return YES;
}

typedef int (^RowBlock)(int, char **, char **);

static int WithBlock(void *arg, int numColumns, char **columnValues, char **columnNames)
{
    int (^block)(int, char **, char **) = (__bridge RowBlock)arg;

    return block(numColumns, columnValues, columnNames);
}

static RowBlock nop = ^(int numColumns, char **columnValues, char **columnNames) {
    return 0;
};

static BOOL Exec(sqlite3 *db, NSString *sql, RowBlock block)
{
    char *error;
    if (sqlite3_exec(db, sql.UTF8String, WithBlock, (__bridge void *) block, &error) != SQLITE_OK) {
        NSLog(@"Error while executing queries: %s", error);
        sqlite3_free(error);
        return NO;
    }

    return YES;
}

@implementation DocumentsIndex

- (id)initWithDatabase:(NSString *)database
{
    if ((self = [super init])) {
        if (sqlite3_open(database.UTF8String, &db)) {
            NSLog(@"Cannot open database: %s", sqlite3_errmsg(db));
            sqlite3_close(db);
            return nil;
        }

        if (!Exec(db,
            @"CREATE TABLE IF NOT EXISTS terms (term TEXT PRIMARY KEY, num_documents INTEGER); \
              CREATE TABLE IF NOT EXISTS documents (uri TEXT PRIMARY KEY); \
              CREATE TABLE IF NOT EXISTS documents_terms (term_id INTEGER, document_id INTEGER, occurences INTEGER); \
              CREATE INDEX IF NOT EXISTS term_idx ON terms (term); \
              CREATE INDEX IF NOT EXISTS documents_terms_idx ON documents_terms (term_id, document_id); \
            ", nop)) {
            return nil;
        }

        if (!IsOk(db, sqlite3_prepare_v2(db, "INSERT OR REPLACE INTO terms (term, num_documents) \
                                                VALUES(?, COALESCE((SELECT num_documents + 1 FROM terms WHERE term = ?), 1))", -1,
                                         &updateTermStmt, NULL))) {
            return nil;
        }

        if (!IsOk(db, sqlite3_prepare_v2(db, "INSERT INTO documents_terms (term_id, document_id, occurences) VALUES(?, ?, ?)", -1,
                                         &insertDocumentTermStmt, NULL))) {
            return nil;
        }
    }

    return self;
}

- (void)dealloc
{
    sqlite3_close(db);
}

- (BOOL)addDocument:(Document *)document
{
    // Check if document is present
    __block BOOL found = NO;
    if (!Exec(db, [NSString stringWithFormat: @"SELECT COUNT(*) FROM documents WHERE uri = '%@'", document.uri],
              ^(int numColumns, char **columnValues, char **columnNames) {
        found = atoi(columnValues[0]) > 0;

        return 0;
    })) {
        return NO;
    };

    if (found) {
        return NO;
    }

    // Insert document
    if (!Exec(db, [NSString stringWithFormat: @"INSERT INTO documents (uri) VALUES ('%@')", document.uri], nop)) {
        return NO;
    }
    sqlite3_int64 documentId = sqlite3_last_insert_rowid(db);

    for (NSString *term in document.terms.allKeys) {
        // Update or insert term
        sqlite3_int64 termId;
        if (IsOk(db, sqlite3_reset(updateTermStmt)) && IsOk(db, sqlite3_clear_bindings(updateTermStmt)) &&
            IsOk(db, sqlite3_bind_text(updateTermStmt, 1, term.UTF8String, -1, SQLITE_TRANSIENT)) &&
            IsOk(db, sqlite3_bind_text(updateTermStmt, 2, term.UTF8String, -1, SQLITE_TRANSIENT))) {

            // TODO: Check error
            sqlite3_step(updateTermStmt);
            termId = sqlite3_last_insert_rowid(db);
        } else {
            // TODO: Rollback
            return NO;
        }

        // Insert relation between document and term
        if (IsOk(db, sqlite3_reset(insertDocumentTermStmt)) && IsOk(db, sqlite3_clear_bindings(insertDocumentTermStmt)) &&
            IsOk(db, sqlite3_bind_int64(insertDocumentTermStmt, 1, termId)) &&
            IsOk(db, sqlite3_bind_int64(insertDocumentTermStmt, 2, documentId)) &&
            IsOk(db, sqlite3_bind_int64(insertDocumentTermStmt, 3, [[document.terms objectForKey:term] intValue]))) {

            sqlite3_step(insertDocumentTermStmt);
        } else {
            // TODO: Rollback
            return NO;
        }
    }

    return YES;
}

- (NSArray *)findDocuments:(NSString *)query
{
    // Parse query
    NSArray *queryTerms = MAP([query componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]], [obj lowercaseString]);

    // Build SQL string

    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT uri FROM documents"];
    int i = 0;
    for (NSString *term in queryTerms) {
        [sql appendFormat:@", terms as t%d, documents_terms as dt%d", i, i];
        i++;
    }

    [sql appendString:@" WHERE 1"];
    i = 0;
    for (NSString *term in queryTerms) {
        [sql appendFormat:@" AND t%d.term = '%@' AND t%d.rowid = dt%d.term_id AND dt%d.document_id = documents.rowid", i, term, i, i, i];
        i++;
    }

    [sql appendString:@" LIMIT 10"];

    NSLog(@"sql: %@", sql);

    // Search documents
    NSMutableArray *uris = [NSMutableArray array];
    if (Exec(db, sql, ^int(int numColums, char **columnValues, char **columnNames) {
        [uris addObject:
         [NSString stringWithUTF8String:columnValues[0]]];
        return 0;
    })) {
        return MAP(uris, [[Document alloc] initWithURI:[NSURL URLWithString:obj]]);
    } else {
        return nil;
    }
}

@end
