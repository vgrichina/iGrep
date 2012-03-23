//
//  Document.h
//  DocumentSearch
//
//  Created by Vladimir Grichina on 04.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Document : NSObject {
    NSString *_uri;

    NSString *_content;
    NSDate *_date;
    NSArray *_tokens;
    NSDictionary *_terms;
    NSString *_title;
}

@property(readonly) NSString *uri;

@property(readonly) NSString *content;
@property(readonly) NSDate *date;
@property(readonly) NSArray *tokens;
@property(readonly) NSDictionary *terms;
@property(readonly) NSString *title;

- (id)initWithURI:(NSString *)uri;
- (id)initWithURI:(NSString *)uri data:(NSData *)data;
- (id)initWithURI:(NSString *)uri title:(NSString *)title date:(NSDate *)date;

@end
