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
    int writePosition;
    int fileSize;
    
    NSMutableOrderedSet *documents;
    NSMutableDictionary *termsCache;
    int documentsInCache;
}

- (id)initWithFile:(NSString *)file;

@end
