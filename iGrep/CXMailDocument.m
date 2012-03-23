//
//  CXMailDocument.m
//  iGrep
//
//  Created by Vladimir Grichina on 23.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import "CXMailDocument.h"

@implementation CXMailDocument


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
