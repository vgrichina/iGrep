//
//  DocumentsIndex.m
//  DocumentSearch
//
//  Created by Vladimir Grichina on 04.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DocumentsIndex.h"

#import "MACollectionUtilities.h"

@implementation DocumentsIndex

- (NSArray *)searchDocuments:(NSString *)query order:(DocumentsIndexSearchOrder)order
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

- (NSArray *)searchDocumentsWithTerms:(NSArray *)queryTerms order:(DocumentsIndexSearchOrder)order
{
    return [NSArray array];
}

@end
