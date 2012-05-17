//
//  CXHtmlDocument.m
//  iGrep
//
//  Created by Vladimir Grichina on 24.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import "CXHtmlDocument.h"

#import "tidy.h"
#import "buffio.h"

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
            // HTML may be malformed and needs to be run through Tidy

            TidyBuffer output = {0};
            TidyBuffer errbuf = {0};

            TidyDoc tdoc = tidyCreate();

            // Setup Tidy to convert into XML
            if (!tidyOptSetBool(tdoc, TidyXmlOut, yes)) {
                return nil;
            }
            // Setup Tidy to use numeric entities (e.g. instead of &nbsp; unsupported in XML).
            if (!tidyOptSetBool(tdoc, TidyNumEntities, yes)) {
                return nil;
            }
            // Setup Tidy to use UTF-8
            if (!tidyOptSetValue(tdoc, TidyCharEncoding, "utf8")) {
                return nil;
            }
            // Capture diagnostics
            if (tidySetErrorBuffer(tdoc, &errbuf) < 0) {
                return nil;
            }
            // Parse the input
            if (tidyParseString(tdoc, [self.content UTF8String]) < 0) {
                return nil;
            }
            // Tidy it up!
            if (tidyCleanAndRepair(tdoc) < 0) {
                return nil;
            }
            // Pretty Print
            if (tidySaveBuffer(tdoc, &output) < 0) {
                return nil;
            }

            NSString *html = [NSString stringWithUTF8String:(char *)output.bp];

            // Parse clean-up HTML using XML parser
            NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[html dataUsingEncoding:NSUTF8StringEncoding]];
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
