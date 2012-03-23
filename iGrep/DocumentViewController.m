//
//  DocumentViewController.m
//  iGrep
//
//  Created by Vladimir Grichina on 05.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import "DocumentViewController.h"


@implementation DocumentViewController

@synthesize document, textView;

- (void)viewWillAppear:(BOOL)animated
{
    self.title = self.document.title;
    self.textView.text = self.document.content;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
