//
//  XCQuicksilverFuzzySearchStrategy.m
//  XCActionBar
//
//  Created by Pedro Gomes on 06/04/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "QSStringRanker.h"
#import "XCFuzzySearchStrategy.h"

#import "XCActionInterface.h"
#import "XCSearchMatchEntry.h"

const CGFloat XCFuzzySearchStrategyMinimumScore = 0.65;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCFuzzySearchStrategy ()

@property (nonatomic) NSArray *sortDescriptors;

@end
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCFuzzySearchStrategy

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    if((self = [super init])) {
        self.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"score" ascending:NO]];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)performSearchWithQuery:(NSString *)expression dataSet:(id<NSFastEnumeration>)dataSet completionHandler:(XCSearchServiceCompletionHandler)completionHandler
{
    NSMutableArray *matches = [NSMutableArray array];
    
    for(id<XCActionInterface> action in dataSet) { @autoreleasepool {
        if(action.title.length == 0) continue;
        
        QSDefaultStringRanker *ranker = [[QSDefaultStringRanker alloc] initWithString:action.title];
        CGFloat score = [ranker scoreForAbbreviation:expression];
        
        if(score >= XCFuzzySearchStrategyMinimumScore) {
            NSIndexSet      *mask   = [ranker maskForAbbreviation:expression];
            NSMutableArray  *ranges = [NSMutableArray array];
            
            [mask enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
                [ranges addObject:[NSValue valueWithRange:range]];
            }];
            [matches addObject:[[XCSearchMatchEntry alloc] initWithAction:action rangesForMatch:ranges matchScore:@(score)]];
        }
    }}
    
    [matches sortUsingDescriptors:self.sortDescriptors];
    completionHandler(matches);
}

@end
