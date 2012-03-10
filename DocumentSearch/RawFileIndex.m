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

#define MAX_TERM_LEN 20

#define DOCS_PER_CHUNK 1000

struct term {
    int docs_offset;
    int docs_count;
    char value[MAX_TERM_LEN];
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
        documentTitles = [NSMutableArray array];
        documentDates = [NSMutableArray array];

        if ((fd = open(file.UTF8String, O_RDWR | O_CREAT, 600)) < 0) {
            NSLog(@"Cannot open: %@", file);
            return nil;
        }

        struct stat stat;
        if (fstat(fd, &stat) < 0) {
            NSLog(@"fstat error for: %@", file);
            return nil;
        }

        fileSize = stat.st_size;

        if (fileSize > 0) {
            if ((data = mmap(0, fileSize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)) == (caddr_t) -1) {
                NSLog(@"mmap error for: %@", file);
                NSLog(@"%s", strerror(errno));
                return nil;
            }

            writePosition = data;
        }
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

- (BOOL)writeToFile
{
    // Calculate space needed
    int spaceNeeded = 2 * sizeof(int);
    spaceNeeded += termsCache.count * sizeof(struct term);
    for (NSString *term in termsCache.allKeys) {
        spaceNeeded += [[termsCache objectForKey:term] count] * sizeof(struct term_doc);
    }

    // Ensure there is enough space
    int newSize = fileSize + spaceNeeded;
    if (lseek(fd, newSize - 1, SEEK_SET) < 0) {
        NSLog(@"lseek error: %s", strerror(errno));
        return NO;
    }
    if (write(fd, "", 1) < 0) {
        NSLog(@"write error: %s", strerror(errno));
        return NO;
    }
    if (data && munmap(data, fileSize) < 0) {
        NSLog(@"munmap error: %s", strerror(errno));
        return NO;
    }
    fileSize = newSize;
    void *newData = NULL;
    if ((newData = mmap(0, fileSize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)) == (caddr_t) -1) {
        NSLog(@"mmap error: %s", strerror(errno));
        return NO;
    }
    writePosition = newData + (writePosition - data);
    data = newData;

    NSArray *sortedTerms = [termsCache.allKeys sortedArrayUsingSelector:@selector(compare:)];

    // Record terms count
    ((int *) writePosition)[1] = [sortedTerms count];
    struct term *terms = writePosition + sizeof(int) * 2;

    // Record term names
    int i = 0;
    for (NSString *term in sortedTerms) {
        [term getBytes:terms[i].value maxLength:MAX_TERM_LEN - 1 usedLength:NULL
              encoding:NSUTF8StringEncoding options:0
                 range:NSMakeRange(0, term.length) remainingRange:NULL];
        i++;
    }

    void *lastPosition = &terms[[sortedTerms count]];

    // Record term documents
    i = 0;
    for (NSString *term in sortedTerms) {
        terms[i].docs_count = [[termsCache objectForKey:term] count];
        terms[i].docs_offset = (void *)lastPosition - (void *)&terms[i];
        struct term_doc *docs = lastPosition;

        int j = 0;
        for (NSNumber *docId in [termsCache objectForKey:term]) {
            docs[j++].idx = [docId intValue];
        }

        lastPosition = &docs[terms[i].docs_count];
        i++;
    }

    // Record length of written data
    ((int *) writePosition)[0] = lastPosition - (void *) writePosition;
    writePosition = lastPosition;
    ((int *) writePosition)[0] = 0;

    // Clear cache
    [termsCache removeAllObjects];

    return YES;
}

- (BOOL)addDocument:(Document *)document
{
    @synchronized(documents) {
        if ([documents containsObject:document.uri]) {
            return NO;
        }

        [documents addObject:document.uri];
        [documentTitles addObject:document.title];
        [documentDates addObject:document.date];

        for (NSString *term in document.terms) {
            NSMutableOrderedSet *docIds = [termsCache objectForKey:term];
            if (!docIds) {
                [termsCache setObject:(docIds = [NSMutableOrderedSet orderedSet]) forKey:term];
            }
            [docIds addObject:[NSNumber numberWithInt:documents.count - 1]];
        }

        if (documents.count % DOCS_PER_CHUNK == 0) {
            [self writeToFile];
        }

        return YES;
    }
}

- (NSArray *)mergeDocs:(struct term_doc **)docs numDocs:(int *)numDocs count:(int)count limit:(int)limit
{
    NSMutableArray *results = [NSMutableArray array];
    do {
        int max = docs[0][numDocs[0] - 1].idx;
        int max_i = 0;
        BOOL eq = YES;
        for (int i = 1; i < count; i++) {
            int idx = docs[i][numDocs[i] - 1].idx;
            eq = eq && idx == max;
            max = MAX(max, idx);
            max_i = i;
        }
        if (eq) {
            [results addObject:[NSNumber numberWithInt:max]];
            for (int i = 0; i < count; i++) {
                numDocs[i]--;
                if (numDocs[i] == 0) {
                    return results;
                }
            }
        } else {
            numDocs[max_i]--;
            if (numDocs[max_i] == 0) {
                return results;
            }
        }

        if (results.count >= limit) {
            return results;
        }
    } while (YES);
}

- (Document *)documentWithId:(int)docId
{
    return [[Document alloc] initWithURI:[documents objectAtIndex:docId]
                                   title:[documentTitles objectAtIndex:docId]
                                    date:[documentDates objectAtIndex:docId]];
}

- (NSArray *)searchDocumentsWithTerms:(NSArray *)queryTerms order:(DocumentsIndexSearchOrder)order
{
    int limit = 30;

    @synchronized(documents) {
        // Search in cached terms
        NSMutableArray *results = [NSMutableArray array];
        NSMutableOrderedSet *set = [termsCache objectForKey:[queryTerms lastObject]];

        for (int i = 0; i < [queryTerms count] - 1; i++) {
            NSString *term = [queryTerms objectAtIndex:i];
            [set intersectOrderedSet:[termsCache objectForKey:term]];
        }

        [results addObjectsFromArray:MAP([set array],
                                         [self documentWithId:[obj intValue]])];

        if (!data || results.count >= limit) {
            return [results subarrayWithRange:NSMakeRange(0, MIN(limit, results.count))];
        }

        // Search in index file
        int *chunk = data;
        while (chunk[0] != 0 && (void *)chunk < data + fileSize) {
            int numTerms = chunk[1];
            struct term *terms = (void *)(chunk + 2);

            struct term_doc **docs = malloc(sizeof(void *) * [queryTerms count]);
            int *numDocs = malloc(sizeof(int) * [queryTerms count]);
            int i = 0;
            BOOL allFound = YES;
            for (NSString *term in queryTerms) {
                void *matched = bsearch_b(term.UTF8String, &terms[0].value, numTerms, sizeof(struct term),
                                                     ^int(const void *value1, const void *value2) {
                    return strcmp(value1, value2);
                });

                if (!matched) {
                    allFound = NO;
                    break;
                } else {
                    struct term *matchedTerm = matched - ((void *)&terms[0].value - (void *)terms);

                    numDocs[i] = matchedTerm->docs_count;
                    docs[i++] = (void *) matchedTerm + matchedTerm->docs_offset;
                }
            }

            if (allFound) {
                [results addObjectsFromArray:
                 MAP([self mergeDocs:docs numDocs:numDocs count:[queryTerms count] limit:limit],
                     [self documentWithId:[obj intValue]])];
            }

            free(numDocs);
            free(docs);

            chunk = (void *)chunk + *chunk;

            if (results.count >= limit) {
                return results;
            }
        }

        return results;
    }
}

@end
