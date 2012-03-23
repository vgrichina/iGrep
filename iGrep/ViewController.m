//
//  ViewController.m
//  Autocomplete
//
//  Created by Владимир Гричина on 02.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import "ViewController.h"

#import "CXMailDocument.h"
#import "CXRawFileIndex.h"

#import "ZipFile.h"
#import "FileInZipInfo.h"
#import "ZipReadStream.h"

@implementation ViewController

@synthesize index, filteredListContent, searchWasActive, savedSearchTerm, savedScopeButtonIndex;
@synthesize documentViewController;

- (void)startIndexing
{
    NSString *indexPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"index.bin"];
    [[NSFileManager defaultManager] removeItemAtPath:indexPath error:NULL];
    NSLog(@"Index path: %@", indexPath);

    self.index = [[CXRawFileIndex alloc] initWithFile:indexPath];

    NSString *mailPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"maildir.zip"];
    ZipFile *zipFile = [[ZipFile alloc] initWithFileName:mailPath mode:ZipFileModeUnzip];

    int totalIndexed = 0;
    do {
        @autoreleasepool {
            NSDate *date = [NSDate new];

            FileInZipInfo *fileInfo = [zipFile getCurrentFileInZipInfo];
            NSString *uri = [NSString stringWithFormat:@"zip:%@!%@",
                             [[NSURL fileURLWithPath:mailPath] absoluteString], fileInfo.name];

            ZipReadStream *stream = [zipFile readCurrentFileInZip];
            NSData *fileData = [stream readDataOfLength:fileInfo.length];

            CXMailDocument *doc = [[CXMailDocument alloc] initWithURI:uri data:fileData];

            //NSLog(@"Unzip time: %.3f", -[date timeIntervalSinceNow]);

            if ([self.index addDocument:doc]) {
                totalIndexed++;
            } else {
                NSLog(@"Failed to index: %@", uri);
            }

            NSLog(@"Total time: %.3f", -[date timeIntervalSinceNow]);
        }

        dispatch_sync(dispatch_get_main_queue(), ^{
            self.title = [NSString stringWithFormat:@"%d files indexed", totalIndexed];
        });
    } while ([zipFile goToNextFileInZip]);

    [zipFile close];

    dispatch_sync(dispatch_get_main_queue(), ^{
        self.title = @"Indexing complete";
    });
}

#pragma mark -
#pragma mark Lifecycle methods

- (void)viewDidLoad
{
    self.filteredListContent = nil;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self startIndexing];
    });

    // restore search settings if they were saved in didReceiveMemoryWarning.
    if (self.savedSearchTerm) {
        [self.searchDisplayController setActive:self.searchWasActive];
        [self.searchDisplayController.searchBar setSelectedScopeButtonIndex:self.savedScopeButtonIndex];
        [self.searchDisplayController.searchBar setText:self.savedSearchTerm];

        self.savedSearchTerm = nil;
    }

    [self.tableView reloadData];
    self.tableView.scrollEnabled = YES;
}

- (void)viewDidUnload
{
    self.filteredListContent = nil;
    self.index = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
    // save the state of the search UI so that it can be restored if the view is re-created
    self.searchWasActive = [self.searchDisplayController isActive];
    self.savedSearchTerm = [self.searchDisplayController.searchBar text];
    self.savedScopeButtonIndex = [self.searchDisplayController.searchBar selectedScopeButtonIndex];
}

#pragma mark -
#pragma mark Other methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark UITableView data source and delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.filteredListContent count];
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kCellID = @"cellID";

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellID];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

	CXDocument *document;
	if (tableView == self.searchDisplayController.searchResultsTableView) {
        document = [self.filteredListContent objectAtIndex:indexPath.row];
    }

    cell.textLabel.text = document.title;
	cell.detailTextLabel.text = [document.date description];

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CXDocument *document = [self.filteredListContent objectAtIndex:indexPath.row];
    self.documentViewController.document = document;
    [self.navigationController pushViewController:self.documentViewController animated:YES];
}

#pragma mark -
#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(CXDocumentsIndexSearchOrder)scope
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"Start filtering: %@", searchText);

        NSArray *documents = [self.index searchDocuments:searchText order:scope];

        dispatch_sync(dispatch_get_main_queue(), ^{
            self.filteredListContent = documents;
            [self.searchDisplayController.searchResultsTableView reloadData];
        });

        NSLog(@"Finish filtering: %@", searchText);
    });
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
                               scope:[self.searchDisplayController.searchBar selectedScopeButtonIndex]];

    return YES;
}

@end
