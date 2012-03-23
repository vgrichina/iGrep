//
//  CXRawFileIndex.h
//  iGrep
//
//  Created by Vladimir Grichina on 08.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import "CXDocumentsIndex.h"

@interface CXRawFileIndex : CXDocumentsIndex {
    int fd;
    void *data;
    void *writePosition;
    int fileSize;

    NSMutableOrderedSet *documents;
    NSMutableArray *documentTitles;
    NSMutableArray *documentDates;
    NSMutableDictionary *termsCache;
}

- (id)initWithFile:(NSString *)file;

@end
