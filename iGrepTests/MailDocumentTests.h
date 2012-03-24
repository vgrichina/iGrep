//
//  DocumentTests.h
//  iGrep
//
//  Created by Vladimir Grichina on 04.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "CXDocument.h"
#import "CXMailDocument.h"

@interface MailDocumentTests : SenTestCase

@property(strong) CXMailDocument *document;

@end
