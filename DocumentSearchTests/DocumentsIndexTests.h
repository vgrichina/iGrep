//
//  DocumentsIndexTests.h
//  DocumentSearch
//
//  Created by Vladimir Grichina on 04.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "DocumentsIndex.h"

@interface DocumentsIndexTests : SenTestCase

@property(strong) DocumentsIndex *index;

- (void)doTestAddDocument;
- (void)doTestSearchDocuments;
- (void)doTestPerformance;


@end
