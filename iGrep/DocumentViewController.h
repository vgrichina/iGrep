//
//  DocumentViewController.h
//  iGrep
//
//  Created by Vladimir Grichina on 05.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CXDocument.h"

@interface DocumentViewController : UIViewController

@property(weak) IBOutlet UITextView *textView;

@property(strong) CXDocument *document;

@end
