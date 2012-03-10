//
//  ViewController.m
//  Autocomplete
//
//  Created by Владимир Гричина on 02.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

#import "RawFileIndex.h"

#import "ZipFile.h"
#import "FileInZipInfo.h"

@implementation ViewController

@synthesize index, filteredListContent, searchWasActive, savedSearchTerm, savedScopeButtonIndex;
@synthesize documentViewController;

- (void)startIndexing:(id)ignored
{
    NSString *indexPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"index.bin"];
    [[NSFileManager defaultManager] removeItemAtPath:indexPath error:NULL];
    NSLog(@"Index path: %@", indexPath);

    self.index = [[RawFileIndex alloc] initWithFile:indexPath];

    NSString *mailPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"maildir.zip"];
    ZipFile *zipFile = [[ZipFile alloc] initWithFileName:mailPath mode:ZipFileModeUnzip];
    NSArray *files = [zipFile listFileInZipInfos];
    [zipFile close];

    int totalIndexed = 0;
    for  (FileInZipInfo *fileInfo in files) {
        NSString *uri = [NSString stringWithFormat:@"zip:%@!%@",
                         [[NSURL fileURLWithPath:mailPath] absoluteString], fileInfo.name];

        @autoreleasepool {
            Document *doc = [[Document alloc] initWithURI:uri];
            if ([self.index addDocument:doc]) {
                totalIndexed++;
            } else {
                NSLog(@"Failed to index: %@", uri);
            }
        }

        [self performSelectorOnMainThread:@selector(setTitle:)
                               withObject:[NSString stringWithFormat:@"%d files indexed", totalIndexed]
                            waitUntilDone:NO];
    }

    [self performSelectorOnMainThread:@selector(setTitle:)
                           withObject:[NSString stringWithFormat:@"Indexing complete", totalIndexed]
                        waitUntilDone:NO];

}

#pragma mark -
#pragma mark Lifecycle methods

- (void)viewDidLoad
{
    self.filteredListContent = nil;

    [self performSelectorInBackground:@selector(startIndexing:) withObject:nil];

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

	Document *document;
	if (tableView == self.searchDisplayController.searchResultsTableView) {
        document = [self.filteredListContent objectAtIndex:indexPath.row];
    }

    cell.textLabel.text = document.title;
	cell.detailTextLabel.text = [document.date description];

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Document *document = [self.filteredListContent objectAtIndex:indexPath.row];
    self.documentViewController.document = document;
    [self.navigationController pushViewController:self.documentViewController animated:YES];
}

#pragma mark -
#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(DocumentsIndexSearchOrder)scope
{
    NSLog(@"Start filtering: %@", searchText);

    self.filteredListContent = [self.index searchDocuments:searchText order:scope];

    NSLog(@"Finish filtering: %@", searchText);
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
