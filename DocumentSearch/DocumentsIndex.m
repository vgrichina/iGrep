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

        // Disable fsync to improve performance
        if (!Exec(db, @"PRAGMA synchronous=off", nop)) {
            return nil;
        }

        if (!Exec(db,
            @"CREATE TABLE IF NOT EXISTS terms (term TEXT COLLATE NOCASE, num_documents INTEGER); \
              CREATE TABLE IF NOT EXISTS documents (uri TEXT, date INTEGER); \
              CREATE TABLE IF NOT EXISTS documents_terms (term_id INTEGER, document_id INTEGER, occurences INTEGER); \
              CREATE INDEX IF NOT EXISTS term_idx ON terms (term); \
              CREATE INDEX IF NOT EXISTS document_uri_idx ON documents (uri); \
              CREATE INDEX IF NOT EXISTS document_date_idx ON documents (date); \
              CREATE INDEX IF NOT EXISTS documents_terms_idx_term ON documents_terms (term_id); \
              CREATE INDEX IF NOT EXISTS documents_terms_idx_document ON documents_terms (document_id); \
            ", nop)) {
            return nil;
        }

        if (!IsOk(db, sqlite3_prepare_v2(db, "SELECT rowid FROM terms WHERE term = ?", -1,
                                         &selectTermStmt, NULL))) {
            return nil;
        }

        if (!IsOk(db, sqlite3_prepare_v2(db, "UPDATE terms SET num_documents = num_documents + 1 WHERE term = ?", -1,
                                         &updateTermStmt, NULL))) {
            return nil;
        }

        if (!IsOk(db, sqlite3_prepare_v2(db, "INSERT INTO terms (term, num_documents) VALUES(?, 1)", -1,
                                         &insertTermStmt, NULL))) {
            return nil;
        }

        if (!IsOk(db, sqlite3_prepare_v2(db, "INSERT INTO documents_terms (term_id, document_id, occurences) VALUES(?, ?, ?)", -1,
                                         &insertDocumentTermStmt, NULL))) {
            return nil;
        }

        termsCache = [NSMutableDictionary dictionary];
    }

    return self;
}

- (void)dealloc
{
    sqlite3_close(db);
}

- (BOOL)addDocument:(Document *)document
{
    // Start transaction
    if (!Exec(db, @"BEGIN", nop)) {
        return NO;
    }

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
    if (!Exec(db, [NSString stringWithFormat: @"INSERT INTO documents (uri, date) VALUES ('%@', %ld)",
                   document.uri, (long long)[document.date timeIntervalSince1970]], nop)) {
        Exec(db, @"ROLLBACK", nop);
        return NO;
    }
    sqlite3_int64 documentId = sqlite3_last_insert_rowid(db);

    for (NSString *term in document.terms.allKeys) {
        sqlite3_int64 termId = -1;

        if ([termsCache objectForKey:term]) {
            termId = [[termsCache objectForKey:term] intValue];
        } else {

            // TODO: Check why incorrect rowid returned by INSERT OR REPLACE
            // Get term id
            if (IsOk(db, sqlite3_reset(selectTermStmt)) && IsOk(db, sqlite3_clear_bindings(selectTermStmt)) &&
                IsOk(db, sqlite3_bind_text(selectTermStmt, 1, term.UTF8String, -1, SQLITE_TRANSIENT))) {
                if (sqlite3_step(selectTermStmt) == SQLITE_ROW) {
                    termId = sqlite3_column_int64(selectTermStmt, 0);
                }
            }
        }

        if (termId > 0) {
            // Update term
            if (IsOk(db, sqlite3_reset(updateTermStmt)) && IsOk(db, sqlite3_clear_bindings(updateTermStmt)) &&
                IsOk(db, sqlite3_bind_text(updateTermStmt, 1, term.UTF8String, -1, SQLITE_TRANSIENT))) {

                // TODO: Check error
                sqlite3_step(updateTermStmt);
            } else {
                Exec(db, @"ROLLBACK", nop);
                return NO;
            }
        } else {
            // Insert term
            if (IsOk(db, sqlite3_reset(insertTermStmt)) && IsOk(db, sqlite3_clear_bindings(insertTermStmt)) &&
                IsOk(db, sqlite3_bind_text(insertTermStmt, 1, term.UTF8String, -1, SQLITE_TRANSIENT))) {

                // TODO: Check error
                sqlite3_step(insertTermStmt);
                termId = sqlite3_last_insert_rowid(db);
            } else {
                Exec(db, @"ROLLBACK", nop);
                return NO;
            }
        }
        [termsCache setObject:[NSNumber numberWithInt:termId] forKey:term];


        // Insert relation between document and term
        if (IsOk(db, sqlite3_reset(insertDocumentTermStmt)) && IsOk(db, sqlite3_clear_bindings(insertDocumentTermStmt)) &&
            IsOk(db, sqlite3_bind_int64(insertDocumentTermStmt, 1, termId)) &&
            IsOk(db, sqlite3_bind_int64(insertDocumentTermStmt, 2, documentId)) &&
            IsOk(db, sqlite3_bind_int64(insertDocumentTermStmt, 3, [[document.terms objectForKey:term] intValue]))) {

            sqlite3_step(insertDocumentTermStmt);
        } else {
            Exec(db, @"ROLLBACK", nop);
            return NO;
        }
    }

    // Commit transaction
    if (!Exec(db, @"COMMIT", nop)) {
        return NO;
    }

    return YES;
}

- (NSArray *)termCompletions:(NSString *)termStart {
    NSString *sql = [NSString stringWithFormat:@"SELECT term FROM terms WHERE term LIKE'%@%%' ORDER BY num_documents DESC LIMIT 5", termStart];

    NSMutableArray *terms = [NSMutableArray array];
    if (Exec(db, sql, ^int(int numColums, char **columnValues, char **columnNames) {
        [terms addObject:
         [NSString stringWithUTF8String:columnValues[0]]];
        return 0;
    })) {
        return terms;
    } else {
        return nil;
    }
}

- (NSArray *)searchDocuments:(NSString *)query order:(DocumentsIndexSearchOrder)order
{
    // Parse query
    NSArray *queryTerms = MAP([query componentsSeparatedByCharactersInSet:
                               [[NSCharacterSet letterCharacterSet] invertedSet]], [obj lowercaseString]);
    queryTerms = SELECT(queryTerms, [obj length] > 0);
    if (queryTerms.count == 0) {
        return [NSArray array];
    }

    // Search best completions for last term
    NSArray *lastTerms = [self termCompletions:[queryTerms lastObject]];

    // Build SQL string

    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT DISTINCT uri FROM"];

    [sql appendString:@"(SELECT uri"];
    int i = 0;

    if (order == DocumentsIndexSearchOrderTfIdf) {
        for (NSString *term in queryTerms) {
            [sql appendFormat:@", t%d.num_documents as t%dnd, dt%d.occurences as dt%do", i, i, i, i];
            i++;
        }
    } else {
        [sql appendString: @", date"];
    }

    [sql appendString:@" FROM documents"];
    i = 0;
    for (NSString *term in queryTerms) {
        [sql appendFormat:@", terms as t%d, documents_terms as dt%d", i, i];
        i++;
    }

    [sql appendString:@" WHERE 1"];
    i = 0;
    for (NSString *term in queryTerms) {
        if (i == queryTerms.count - 1) {
            [sql appendFormat:@" AND t%d.term IN (%@)", i,
             [MAP(lastTerms, [NSString stringWithFormat:@"'%@'", obj]) componentsJoinedByString:@", "]];
        } else {
            [sql appendFormat:@" AND t%d.term = '%@'", i, term];
        }
        [sql appendFormat:@" AND t%d.rowid = dt%d.term_id AND dt%d.document_id = documents.rowid", i, i, i];
        i++;
    }

    [sql appendFormat:@" LIMIT 1000)"];

    if (order == DocumentsIndexSearchOrderDate) {
        [sql appendFormat:@" ORDER BY DATE DESC"];
    } else {
        [sql appendFormat:@" ORDER BY "];
        __block int i = 0;
        NSArray *parts = MAP(queryTerms,
                             [NSString stringWithFormat:
                              @"(dt%do * t%dnd / (SELECT COUNT(*) FROM documents))", i, i++]);
        [sql appendString:[parts componentsJoinedByString:@" + "]];
        [sql appendFormat:@" DESC"];
    }

    [sql appendString:@" LIMIT 30"];

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
