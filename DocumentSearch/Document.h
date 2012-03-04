//
//  Document.h
//  DocumentSearch
//
//  Created by Vladimir Grichina on 04.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Document : NSObject {
    NSURL *_uri;

    NSString *_content;
    NSDate *_date;
    NSArray *_tokens;
    NSDictionary *_terms;
}

@property(readonly) NSURL *uri;

@property(readonly) NSString *content;
@property(readonly) NSDate *date;
@property(readonly) NSArray *tokens;
@property(readonly) NSDictionary *terms;

- (id)initWithURI:(NSURL *)uri;

@end
