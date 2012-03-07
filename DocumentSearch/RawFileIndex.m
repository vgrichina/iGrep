//
//  RawFileIndex.m
//  DocumentSearch
//
//  Created by Vladimir Grichina on 08.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RawFileIndex.h"

#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#import "MACollectionUtilities.h"

struct term {
    int offset;
    char value[];
};

struct term_doc {
    int idx;
    int occurences;
};

@implementation RawFileIndex

- (id)initWithFile:(NSString *)file
{
    if ((self = [super init])) {
        termsCache = [NSMutableDictionary dictionary];
        documents = [NSMutableOrderedSet orderedSet];
        
        if ((fd = open(file.UTF8String, O_RDWR | O_CREAT)) < 0) {
            NSLog(@"Cannot open: %@", file);
            return nil;
        }

        struct stat stat;
        if (fstat(fd, &stat) < 0) {
            NSLog(@"fstat error for: %@", file);
            return nil;
        }

        fileSize = stat.st_size;

        /*if ((data = mmap(0, fileSize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)) == (caddr_t) -1) {
            NSLog(@"mmap error for: %@", file);
            return nil;
        }*/
    }

    return self;
}

- (void)dealloc
{
    if (munmap(data, fileSize) == -1) {
        NSLog(@"munmap error");
    }
    
    if (close(fd) < 0) {
        NSLog(@"close error");
    }
}

- (BOOL)addDocument:(Document *)document
{
    if ([documents containsObject:document.uri]) {
        return NO;
    }

    [documents addObject:document.uri];

    for (NSString *term in document.terms) {
        NSMutableOrderedSet *docIds = [termsCache objectForKey:term];
        if (!docIds) {
            [termsCache setObject:(docIds = [NSMutableOrderedSet orderedSet]) forKey:term];
        }
        [docIds addObject:[NSNumber numberWithInt:documents.count - 1]];
    }

    return YES;
}

- (NSArray *)searchDocumentsWithTerms:(NSArray *)queryTerms order:(DocumentsIndexSearchOrder)order
{    
    NSMutableOrderedSet *set = [termsCache objectForKey:[queryTerms lastObject]];

    for (int i = 0; i < [queryTerms count] - 1; i++) {
        NSString *term = [queryTerms objectAtIndex:i];
        [set intersectOrderedSet:[termsCache objectForKey:term]];
    }

    return MAP([set array], [documents objectAtIndex:[obj intValue]]);
}

@end
