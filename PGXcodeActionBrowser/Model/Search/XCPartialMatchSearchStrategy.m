//
//  XCPartialMatchSearchStrategy.m
//  XCActionBar
//
//  Created by Pedro Gomes on 06/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCActionInterface.h"
#import "XCSearchMatchEntry.h"

#import "XCPartialMatchSearchStrategy.h"

#import "NSString+XCExtensions.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCPartialMatchSearchStrategy ()

@end

////////////////////////////////////////////////////////////////////////////////
// Default XCActionBar search strategy - not really fuzzy, just flexible in
// terms of partial matching
////////////////////////////////////////////////////////////////////////////////
@implementation XCPartialMatchSearchStrategy

#pragma mark - Public Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)performSearchWithQuery:(NSString *)query dataSet:(id<NSFastEnumeration>)dataSet completionHandler:(XCSearchServiceCompletionHandler)completionHandler
{
    NSParameterAssert(completionHandler != nil);
    
    NSArray *queryComponents = [query componentsSeparatedByString:@" "];
    if(queryComponents.count == 1) {
        queryComponents = [query characterComponents];
    }
    NSUInteger queryComponentCount = queryComponents.count;
    
    ////////////////////////////////////////////////////////////////////////////////
    // this is highly inefficient - obviously just a first pass to get the core feature working
    ////////////////////////////////////////////////////////////////////////////////
    NSMutableArray *matches = [NSMutableArray array];
    
    for(id<XCActionInterface> action in dataSet) {
        
        NSString *stringToMatch = action.title;
        
        ////////////////////////////////////////////////////////////////////////////////
        // Search Title and Title's subwords
        ////////////////////////////////////////////////////////////////////////////////
        BOOL        foundMatch    = NO;
        NSUInteger  matchLocation = 0;
        
        while(query.length <= stringToMatch.length) {
            NSRange range = [stringToMatch rangeOfString:query
                                                 options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)
                                                   range:NSMakeRange(0, query.length)];
            if(range.location != NSNotFound) {
                [matches addObject:[[XCSearchMatchEntry alloc] initWithAction:action
                                                               rangesForMatch:@[[NSValue valueWithRange:NSMakeRange(matchLocation, query.length)]]]];
                foundMatch = YES;
                break;
            }
            NSRange rangeForNextMatch = [stringToMatch rangeOfString:@" "];
            if(rangeForNextMatch.location == NSNotFound) break;
            if(rangeForNextMatch.location + 1 > stringToMatch.length) break;
            
            matchLocation += rangeForNextMatch.location + 1;
            stringToMatch = [stringToMatch substringFromIndex:rangeForNextMatch.location + 1];
        }
        
        if(foundMatch == YES) continue;
        if(queryComponentCount < 2) continue;
        
        ////////////////////////////////////////////////////////////////////////////////
        // Run additional sub-word prefix search
        // This allows us to match partial prefixes matches such as:
        // "Sur wi d q" would match "Surround with double quotes"
        ////////////////////////////////////////////////////////////////////////////////
        NSMutableArray *ranges  = [NSMutableArray array];
        
        NSArray *candidateComponents = [action.title componentsSeparatedByString:@" "];
        if(queryComponentCount > candidateComponents.count) continue;
        
        matchLocation = 0;
        
        BOOL foundPartialMatch = NO;
        for(int i = 0; i < queryComponentCount; i++) {
            foundPartialMatch = NO;
            
            NSString *subQuery = queryComponents[i];
            NSString *subMatch = candidateComponents[i];
            
            if(subQuery.length > subMatch.length) break;
            
            NSRange range = [subMatch rangeOfString:subQuery
                                            options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)
                                              range:NSMakeRange(0, subQuery.length)];
            foundPartialMatch = (range.location != NSNotFound);
            if(foundPartialMatch == NO) break;
            
            [ranges addObject:[NSValue valueWithRange:NSMakeRange(matchLocation, subQuery.length)]];
            matchLocation += (subMatch.length + 1);
        }
        
        if(foundPartialMatch == YES) {
            [matches addObject:[[XCSearchMatchEntry alloc] initWithAction:action rangesForMatch:ranges]];
            continue;
        }
        
        ////////////////////////////////////////////////////////////////////////////////
        // No matches ...
        // lets try the action's group instead
        ////////////////////////////////////////////////////////////////////////////////
        //        if(foundMatch == NO) {
        //            if(str.length > action.group.length) continue;
        //
        //            NSRange range = [action.group rangeOfString:str
        //                                                options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)
        //                                                  range:NSMakeRange(0, str.length)];
        //            if(range.location != NSNotFound) {
        //                [matches addObject:action];
        //            }
        //        }
    }
    
    completionHandler([NSArray arrayWithArray:matches]);
}

@end
