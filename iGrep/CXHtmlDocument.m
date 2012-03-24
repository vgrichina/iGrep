//
//  CXHtmlDocument.m
//  iGrep
//
//  Created by Vladimir Grichina on 24.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import "CXHtmlDocument.h"

@implementation CXHtmlDocument

- (NSString *)title
{
    if (!_title) {
        if (self.content) {
            NSRegularExpression *regex =
            [NSRegularExpression regularExpressionWithPattern:@"<title>(.+)</title>"
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

        NSLog(@"Warning, no <title> tag found for URL: %@", self.uri);
        return (_title = @"< No Title >");
    }

    return _title;
}

- (NSString *)textContent
{
    if (!_textContent) {
        if (self.content) {
            NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[self.content dataUsingEncoding:NSUTF8StringEncoding]];
            parser.delegate = self;
            _textContent = [NSMutableString string];
            if ([parser parse]) {
                return _textContent;
            }
        } else {
            NSLog(@"Warning no content for URL: %@", self.uri);
        }
    }

    return _textContent;
}

#pragma mark NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"script"] || [elementName isEqualToString:@"style"]) {
        ignoreText = YES;
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"script"] || [elementName isEqualToString:@"style"]) {
        ignoreText = NO;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (!ignoreText) {
        [_textContent appendString:string];
    }
}

@end
