//
//  CXHtmlDocument.h
//  iGrep
//
//  Created by Vladimir Grichina on 24.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import "CXDocument.h"

// TODO: use Tidy so that not only XHTML is supported
@interface CXHtmlDocument : CXDocument<NSXMLParserDelegate>  {
    NSMutableString *_textContent;
    BOOL ignoreText;
}

@end
