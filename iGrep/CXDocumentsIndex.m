//
//  CXDocumentsIndex.m
//  iGrep
//
//  Created by Vladimir Grichina on 04.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import "CXDocumentsIndex.h"

#import "MACollectionUtilities.h"

@implementation CXDocumentsIndex

- (BOOL)addDocument:(CXDocument *)document
{
    // Override in child classes
    return NO;
}

- (NSArray *)searchDocuments:(NSString *)query order:(CXDocumentsIndexSearchOrder)order
{
    // Parse query
    NSArray *queryTerms = MAP([query componentsSeparatedByCharactersInSet:
                               [[NSCharacterSet letterCharacterSet] invertedSet]], [obj lowercaseString]);
    queryTerms = SELECT(queryTerms, [obj length] > 0);
    if (queryTerms.count == 0) {
        return [NSArray array];
    }

    return [self searchDocumentsWithTerms:queryTerms order:order];
}

- (NSArray *)searchDocumentsWithTerms:(NSArray *)queryTerms order:(CXDocumentsIndexSearchOrder)order
{
    // Override in child classes
    return [NSArray array];
}

@end
