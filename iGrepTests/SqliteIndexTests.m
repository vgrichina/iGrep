//
//  SqliteIndexTests.m
//  iGrep
//
//  Created by Vladimir Grichina on 08.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import "SqliteIndexTests.h"

#import "CXSqliteDocumentsIndex.h"

@implementation SqliteIndexTests

- (void)setUp
{
    NSString *dbPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"index.sqlite"];
    [[NSFileManager defaultManager] removeItemAtPath:dbPath error:NULL];
    self.index = [[CXSqliteDocumentsIndex alloc] initWithDatabase:dbPath];
    NSLog(@"Database path: %@", dbPath);
}

- (void)testAddDocument
{
    [self doTestAddDocument];
}

- (void)testAddDocumentFromZip
{
    [self doTestAddDocumentFromZip];
}

- (void)testSearchDocuments
{
    [self doTestSearchDocuments];
}

- (void)testPerformance
{
    [self doTestPerformance];
}

@end
