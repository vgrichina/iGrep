//
//  DocumentViewController.h
//  DocumentSearch
//
//  Created by Vladimir Grichina on 05.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Document.h"

@interface DocumentViewController : UIViewController

@property(weak) IBOutlet UITextView *textView;

@property(strong) Document *document;

@end
