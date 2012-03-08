//
//  RawFileIndex.h
//  DocumentSearch
//
//  Created by Vladimir Grichina on 08.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DocumentsIndex.h"

@interface RawFileIndex : DocumentsIndex {
    int fd;
    void *data;
    void *writePosition;
    int fileSize;

    NSMutableOrderedSet *documents;
    NSMutableDictionary *termsCache;
}

- (id)initWithFile:(NSString *)file;

@end
