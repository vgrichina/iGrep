//
//  HtmlDocumentTests.m
//  iGrep
//
//  Created by Vladimir Grichina on 23.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import "HtmlDocumentTests.h"

@implementation HtmlDocumentTests

@synthesize document;

- (void)setUp
{
    NSString *url = [[[[NSBundle bundleForClass:[CXHtmlDocument class]] bundleURL]
                      URLByAppendingPathComponent:@"tfidf.html"] absoluteString];
    self.document = [[CXHtmlDocument alloc] initWithURI:url];
}

- (void)testContent
{
    STAssertEquals(self.document.content.length, 48601u, @"Has expected length");
}

- (void)testTextContent
{
    NSLog(@"%@", self.document.textContent);
    STAssertEquals(self.document.textContent.length, 8586u, @"Has expected length");
}

- (void)testDate
{
    STAssertEqualObjects(self.document.date, nil, @"Has expected date");
}

- (void)testTokens
{
    STAssertEquals(self.document.tokens.count, 1291u, @"Has expected number of tokens");
}

- (void)testTerms
{
    NSLog(@"terms: %@", self.document.terms);
    STAssertEquals(self.document.terms.count, 533u, @"Has expected number of terms");
    STAssertEquals([[self.document.terms objectForKey:@"wikipedia"] intValue], 8, @"Term 'wikipedia' occurs expected number of times");
}

- (void)testTitle
{
    STAssertEqualObjects(self.document.title, @"tf*idf - Wikipedia, the free encyclopedia", @"Has expected title");
}

@end
