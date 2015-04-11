//
//  XCActionBarSearchDataSource.m
//  XCActionBar
//
//  Created by Pedro Gomes on 09/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCSearchService.h"
#import "XCActionBarSearchDataSource.h"

#import "XCActionInterface.h"
#import "XCActionPresetSource.h"
#import "XCSearchMatchEntry.h"
#import "XCSearchResultCell.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCActionBarSearchDataSource ()

@property (nonatomic, weak) id<XCSearchService> searchService;

@property (nonatomic, assign) NSInteger selectedObjectIndex;
@property (nonatomic,   copy) NSString  *searchQuery;
@property (nonatomic        ) NSArray   *searchResults;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCActionBarSearchDataSource

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithSearchService:(id<XCSearchService>)searchService
{
    if((self = [super init])) {
        self.selectedObjectIndex = -1;
        self.searchResults       = @[];
        self.searchService       = searchService;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)updateSelectedObjectIndex:(NSUInteger)index
{
    self.selectedObjectIndex = index;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)updateSearchQuery:(NSString *)query
{
    XCDeclareWeakSelf(weakSelf);

    self.searchQuery = query;
    [self.searchService performSearchWithQuery:query
                             completionHandler:^(NSArray *results) {
                                 weakSelf.searchResults = results;
                             }];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSUInteger)numberOfObjects
{
    return self.searchResults.count;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSUInteger)numberOfResults
{
    return self.searchResults.count;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)clearResults
{
    [self clearSearchResults];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)clearSearchResults
{
    self.searchQuery         = nil;
    self.searchResults       = @[];
    self.selectedObjectIndex = -1;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id<XCSearchMatchEntry>)objectAtIndex:(NSUInteger)index
{
    return self.searchResults[index];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id<XCSearchMatchEntry>)selectedObject
{
    if(self.selectedObjectIndex < 0 ) return nil;
    
    return self.searchResults[self.selectedObjectIndex];
}

#pragma mark - NSTableViewDataSource

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
{
    return self.searchResults.count;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return self.searchResults[rowIndex];
}

#pragma mark - NSTableViewDelegate

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    XCSearchResultCell *cell = [tableView makeViewWithIdentifier:NSStringFromClass([XCSearchResultCell class]) owner:self];
    
    id<XCSearchMatchEntry> searchMatch = self.searchResults[row];
    id<XCActionInterface > action      = searchMatch.action;
    
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:TRSafeString(action.title)];
    
    [title addAttribute:NSForegroundColorAttributeName
                  value:(action.enabled ? [NSColor blackColor] : [NSColor darkGrayColor])
                  range:NSMakeRange(0, title.length)];
    
    for(NSValue *rangeValue in searchMatch.rangesForMatch) {
        [title addAttributes:@{NSBackgroundColorAttributeName:[NSColor colorWithCalibratedRed:1.000 green:1.000 blue:0.519 alpha:0.250],
                               NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                               NSUnderlineColorAttributeName: [NSColor yellowColor]}
                       range:rangeValue.rangeValue];
    }
    
    cell.textField.allowsEditingTextAttributes = YES;
    
    cell.textField.attributedStringValue = title;
    cell.hintTextField.stringValue       = TRSafeString(action.hint);
    
    if([action acceptsArguments] == YES ||
       [action conformsToProtocol:@protocol(XCActionPresetSource)]) {
        //        NSString *summaryWithMarker = [NSString stringWithFormat:@"%@ %@", @"\uf11c", TRSafeString(action.subtitle)];
        //        NSMutableAttributedString *summary = [[NSMutableAttributedString alloc] initWithString:summaryWithMarker];
        //        [summary addAttributes:@{NSFontAttributeName: XCFontAwesomeWithSize(12.0)}
        //                         range:NSMakeRange(0, 1)];
        //        cell.subtitleTextField.allowsEditingTextAttributes = YES;
        //        cell.subtitleTextField.attributedStringValue       = summary;
        
        cell.subtitleTextField.stringValue = [NSString stringWithFormat:@"%@ %@", @"\u21e5", TRSafeString(action.subtitle)];
    }
    else cell.subtitleTextField.stringValue   = TRSafeString(action.subtitle);
    
    
    return cell;
}

@end
