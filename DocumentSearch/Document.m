//
//  Document.m
//  DocumentSearch
//
//  Created by Vladimir Grichina on 04.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Document.h"

#import "MACollectionUtilities.h"

#import "ZipFile.h"
#import "FileInZipInfo.h"
#import "ZipReadStream.h"

@implementation Document

@synthesize uri = _uri;

- (id)initWithURI:(NSString *)uri
{
    if ((self = [super init])) {
        _uri = uri;
    }

    return self;
}

- (id)initWithURI:(NSString *)uri data:(NSData *)data
{
    if ((self = [super init])) {
        _uri = uri;
        _content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }

    return self;
}

- (id)initWithURI:(NSString *)uri title:(NSString *)title date:(NSDate *)date {
    if ((self = [super init])) {
        _uri = uri;
        _title = title;
        _date = date;
    }

    return self;
}


- (NSString *)content
{
    if (!_content) {
        if ([self.uri hasPrefix:@"zip:"]) {
            NSDate *date = [NSDate new];

            NSArray *comps = [[self.uri substringFromIndex:4] componentsSeparatedByString:@"!"];
            NSURL *zipUrl = [NSURL URLWithString:[comps objectAtIndex:0]];
            ZipFile *zipFile = [[ZipFile alloc] initWithFileName:zipUrl.path mode:ZipFileModeUnzip];
            [zipFile locateFileInZip:[comps objectAtIndex:1]];
            FileInZipInfo *fileInfo = [zipFile getCurrentFileInZipInfo];
            ZipReadStream *stream = [zipFile readCurrentFileInZip];
            NSData *fileData = [stream readDataOfLength:fileInfo.length];
            _content = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
            [zipFile close];

            NSLog(@"Unzip time: %.3f", -[date timeIntervalSinceNow]);
        } else {
            NSError *error = nil;
            _content = [NSString stringWithContentsOfURL:[NSURL URLWithString:self.uri]
                                                encoding:NSUTF8StringEncoding
                                                   error:&error];
            if (error) {
                NSLog(@"Cannot load document with URL: %@\nError: %@", self.uri, error.description);
            }
        }
    }

    return _content;
}

- (NSDate *)date
{
    if (!_date) {
        if (self.content) {
            NSRegularExpression *regex =
            [NSRegularExpression regularExpressionWithPattern:@"Date: (.+\\d{4})( \\(.*\\))?"
                                                      options:NSRegularExpressionCaseInsensitive
                                                        error:NULL];
            NSTextCheckingResult *match = [regex firstMatchInString:self.content options:0 range:NSMakeRange(0, self.content.length)];
            if (match && match.range.location != NSNotFound) {
                NSRange range = [match rangeAtIndex:1];

                NSDateFormatter *dateFormatter = [NSDateFormatter new];
                dateFormatter.dateFormat = @"EEE, dd MMM yyyy hh:mm:ss ZZZ";
                dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];

                NSDate *parsedDate = [dateFormatter dateFromString:[self.content substringWithRange:range]];
                if (!parsedDate) {
                    NSLog(@"Cannot parse date: %@",  [self.content substringWithRange:range]);
                } else {
                    return (_date = parsedDate);
                }
            }
        } else {
            NSLog(@"Warning no content for URL: %@", self.uri);
        }

        NSLog(@"Warning, no Date header found for URL: %@", self.uri);
        return (_date = [NSDate dateWithTimeIntervalSince1970:0]);
    }

    return _date;
}

- (NSArray *)tokens
{
    if (!_tokens) {
        NSArray *components = [self.content componentsSeparatedByCharactersInSet:
                               [[NSCharacterSet letterCharacterSet] invertedSet]];
        _tokens = MAP(SELECT(components, [obj length] > 0), [obj lowercaseString]);
    }

    return _tokens;
}

- (NSDictionary *)terms
{
    if (!_terms) {
        NSMutableDictionary *terms = [NSMutableDictionary dictionary];
        for (NSString *token in self.tokens) {
            NSNumber *currentNumber = [terms objectForKey:token];
            if (!currentNumber) {
                currentNumber = [NSNumber numberWithInt:1];
            } else {
                currentNumber = [NSNumber numberWithInt:[currentNumber intValue] + 1];
            }
            [terms setObject:currentNumber forKey:token];
        }

        _terms = terms;
    }

    return _terms;
}

- (NSString *)title
{
    if (!_title) {
        if (self.content) {
            NSRegularExpression *regex =
            [NSRegularExpression regularExpressionWithPattern:@"Subject: (.+)"
                                                      options:NSRegularExpressionCaseInsensitive
                                                        error:NULL];
            NSTextCheckingResult *match = [regex firstMatchInString:self.content options:0 range:NSMakeRange(0, self.content.length)];
            if (match && match.range.location != NSNotFound) {
                NSRange range = [match rangeAtIndex:1];

                return (_title = [self.content substringWithRange:range]);
            }
        } else {
            NSLog(@"Warning no content for URL: %@", self.uri);
        }

        NSLog(@"Warning, no Subject header found for URL: %@", self.uri);
        return (_title = @"< No Subject >");
    }

    return _title;
}

@end
