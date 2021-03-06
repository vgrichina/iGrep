//
//  CXDocument.h
//  iGrep
//
//  Created by Vladimir Grichina on 04.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CXDocument <NSObject>

@property(readonly) NSString *uri;

@property(readonly) NSString *content;
@property(readonly) NSString *textContent;
@property(readonly) NSDate *date;
@property(readonly) NSArray *tokens;
@property(readonly) NSDictionary *terms;
@property(readonly) NSString *title;

- (id)initWithURI:(NSString *)uri;
- (id)initWithURI:(NSString *)uri data:(NSData *)data;
- (id)initWithURI:(NSString *)uri title:(NSString *)title date:(NSDate *)date;

@end

@interface CXDocument : NSObject<CXDocument> {
    NSString *_uri;

    NSDate *_date;
    NSString *_title;
    NSString *_content;
    NSArray *_tokens;
    NSDictionary *_terms;
}

@end
