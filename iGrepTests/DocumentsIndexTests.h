//
//  DocumentsIndexTests.h
//  iGrep
//
//  Created by Vladimir Grichina on 04.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "CXDocumentsIndex.h"

@interface DocumentsIndexTests : SenTestCase

@property(strong) CXDocumentsIndex *index;

- (void)doTestAddDocument;
- (void)doTestAddDocumentFromZip;
- (void)doTestSearchDocuments;
- (void)doTestPerformance;


@end
