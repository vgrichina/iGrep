//
//  RawFileIndex.m
//  DocumentSearch
//
//  Created by Vladimir Grichina on 08.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RawFileIndexTests.h"

#import "RawFileIndex.h"

@implementation RawFileIndexTests

- (void)setUp
{
    NSString *indexPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"index.bin"];
    [[NSFileManager defaultManager] removeItemAtPath:indexPath error:NULL];
    self.index = [[RawFileIndex alloc] initWithFile:indexPath];
    NSLog(@"Index path: %@", indexPath);
}

- (void)testAddDocument
{
    [self doTestAddDocument];
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
