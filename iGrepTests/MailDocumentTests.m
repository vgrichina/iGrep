//
//  DocumentTests.m
//  iGrep
//
//  Created by Vladimir Grichina on 04.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import "MailDocumentTests.h"

#import <sqlite3.h>

@implementation MailDocumentTests

@synthesize document;

- (void)setUp
{
    NSString *url = [[[[NSBundle bundleForClass:[CXMailDocument class]] bundleURL]
                      URLByAppendingPathComponent:@"maildir/mcconnell-m/_sent_mail/1."] absoluteString];
    self.document = [[CXMailDocument alloc] initWithURI:url];
}

- (void)testContent
{
    STAssertEquals(self.document.content.length, 551u, @"Has expected length");
}

- (void)testDate
{
    STAssertEqualObjects(self.document.date, [NSDate dateWithTimeIntervalSince1970:991895340 + 7 * 3600], @"Has expected date");
}

- (void)testTokens
{
    STAssertEquals(self.document.tokens.count, 82u, @"Has expected number of tokens");
}

- (void)testTerms
{
    NSLog(@"terms: %@", self.document.terms);
    STAssertEquals(self.document.terms.count, 63u, @"Has expected number of terms");
}

@end
