//
//  ViewController.h
//  Autocomplete
//
//  Created by Владимир Гричина on 02.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CXDocumentsIndex.h"
#import "DocumentViewController.h"

@interface ViewController : UITableViewController <UISearchDisplayDelegate, UISearchBarDelegate>

@property (nonatomic, strong) CXDocumentsIndex *index;

@property (nonatomic, strong) NSArray *filteredListContent;

@property (nonatomic, copy) NSString *savedSearchTerm;
@property (nonatomic) NSInteger savedScopeButtonIndex;
@property (nonatomic) BOOL searchWasActive;

@property (strong) IBOutlet DocumentViewController *documentViewController;

@end
