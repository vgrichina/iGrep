//
//  RawFileIndex.m
//  iGrep
//
//  Created by Vladimir Grichina on 08.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import "RawFileIndexTests.h"

#import "CXRawFileIndex.h"

@implementation RawFileIndexTests

- (void)setUp
{
    NSString *indexPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"index.bin"];
    [[NSFileManager defaultManager] removeItemAtPath:indexPath error:NULL];
    self.index = [[CXRawFileIndex alloc] initWithFile:indexPath];
    NSLog(@"Index path: %@", indexPath);
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
