//
//  DocumentsIndexTests.m
//  DocumentSearch
//
//  Created by Vladimir Grichina on 04.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DocumentsIndexTests.h"

@implementation DocumentsIndexTests

@synthesize index;

- (void)setUp
{
    NSString *dbPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"index.sqlite"];
    [[NSFileManager defaultManager] removeItemAtPath:dbPath error:NULL];
    self.index = [[DocumentsIndex alloc] initWithDatabase:dbPath];
    NSLog(@"Database path: %@", dbPath);
}

- (void)testAddDocument
{
    NSURL *url = [[[NSBundle bundleForClass:[Document class]] bundleURL] URLByAppendingPathComponent:@"maildir/mcconnell-m/_sent_mail/1."];
    Document *document = [[Document alloc] initWithURI:url];

    STAssertTrue([self.index addDocument:document], @"Document added");
    STAssertFalse([self.index addDocument:document], @"Document added");
}

- (void)testFindDocuments
{
    [self testAddDocument];

    STAssertEquals([self.index searchDocuments:@"wow"].count, 1u, @"Single document found");
}

@end
