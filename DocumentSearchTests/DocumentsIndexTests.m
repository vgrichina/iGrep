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

- (void)doTestAddDocument
{
    NSString *url = [[[[NSBundle bundleForClass:[Document class]] bundleURL]
                      URLByAppendingPathComponent:@"maildir/mcconnell-m/_sent_mail/1."] absoluteString];
    Document *document = [[Document alloc] initWithURI:url];

    STAssertTrue([self.index addDocument:document], @"Document added");
    STAssertFalse([self.index addDocument:document], @"Document added");
}

- (void)doTestSearchDocuments
{
    [self doTestAddDocument];

    STAssertEquals([self.index searchDocuments:@"wow" order:DocumentsIndexSearchOrderDate].count, 1u, @"Single document found");
}

- (void)doTestPerformance
{
    NSDate *start = [NSDate date];
    puts("\n\n");
    NSLog(@"Running testPerformance");

    // Index documents
    NSString *mailPath = [[[NSBundle bundleForClass:[DocumentsIndex class]] bundlePath] stringByAppendingPathComponent:@"maildir/mcconnell-m/_sent_mail/"];
    NSEnumerator *filesEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:mailPath];

    int totalIndexed = 0;
    NSString *file;
    while (file = [filesEnumerator nextObject]) {
        file = [mailPath stringByAppendingPathComponent:file];

        BOOL isDir;
        if ([[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:&isDir] && !isDir) {
            putc('.', stdout);
            totalIndexed++;

            @autoreleasepool {
                Document *doc = [[Document alloc] initWithURI:[[NSURL fileURLWithPath:file] absoluteString]];
                STAssertTrue([self.index addDocument:doc], @"Indexed successfully");
            }
        }
    }

    puts("\n");
    int timePassed = (int)-[start timeIntervalSinceNow];
    NSLog(@"Indexed %d files in %d seconds", totalIndexed, timePassed);
    NSLog(@"Indexing single document takes: %.3f seconds", (float) timePassed / totalIndexed);
    puts("\n\n");

    // Try some searches too
    NSArray *queries = [NSArray arrayWithObjects:@"monday", @"gonzales", @"appointment", @"meeting", @"eric meeting", nil];

    // tf*idf
    for (NSString *query in queries) {
        NSLog(@"Searching: %@", query);
        NSArray *documents = [self.index searchDocuments:query order:DocumentsIndexSearchOrderTfIdf];
        STAssertTrue(documents.count > 0, @"Should find some documents for query: %@", query);
    }

    // Time sort
    for (NSString *query in queries) {
        NSLog(@"Searching: %@", query);
        NSArray *documents = [self.index searchDocuments:query order:DocumentsIndexSearchOrderDate];
        STAssertTrue(documents.count > 0, @"Should find some documents for query: %@", query);
    }
}

@end
